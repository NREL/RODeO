# -*- coding: utf-8 -*-
"""
Created on Wed Jul 13 00:03:41 2016

@author: pgagnon
"""

'''
Function that determines the optimal dispatch of the battery, and in the
process determines the resulting first year bill with the system.

INPUTS:
estimate_toggle: Boolean. False means run DP to get accurate energy savings
                 and dispatch trajectory. True means estimate the energy
                 savings, and don't get the dispatch trajectory.
                 
load_profile: Original load profile prior to modification by the battery
              (It includes PV's contribution, if there is any)

t: tariff class object
b: battery class object

NOTES:
-in the battery level matrices, 0 index corresponds to an empty battery, and 
 the highest index corresponds to a full battery
-Battery levels are represented as int * 1e10

To Do:
-Make it evaluate the bill for the net profile when batt.cap == 0
-Having cost-to-go equal cost of filling the battery at the end may not be
 working.
-have warnings for classes of errors. Same for bill calculator, such as when
 net load in a given period is negative

'''

import numpy as np
import os
import storage_functions_pieter as storFuncP
import matplotlib as mpl
mpl.use('agg')
import matplotlib.pyplot as plt, mpld3
import storage_functions_pieter as sFuncs


t = storFuncP.import_tariff('MGS_tariff_delmarva.csv')
class NEM_tariff:
    style = 0 # style: 0 = full retail, 1 = TOU schedule
    e_credits = t.e_prices_no_tier #Intended to replicate the normal tariff e charges per period, but I could change this to an 8760 as well
class batt:
    eta = 0.90 # battery half-trip efficiency
    power = 100.0
    cap = power*4

profile = np.genfromtxt('input_profile_lg_office_delaware.csv', delimiter=",", skip_header=1)
load_profile = profile[:,0]
pv_cf_profile = profile[:,1]

pv_size = 250.0
load_and_pv_profile = load_profile - pv_size*pv_cf_profile
pv_profile = pv_size*pv_cf_profile
aep = np.sum(pv_profile)
aec = np.sum(load_profile)
energy_penetration = aep / aec
print "annual energy penetration:", energy_penetration



# ======================================================================= #
# Determine cheapest possible demand states for the entire year
# ======================================================================= #
d_inc_n = 40 # Number of demand levels between original and lowest possible that will be explored
month_hours = np.array([0, 744, 1416, 2160, 2880, 3624, 4344, 5088, 5832, 6552, 7296, 8016, 8760]);
cheapest_possible_demands = np.zeros((12,t.d_n+1), float)
demand_max_profile = np.zeros(len(load_profile), float)

# Determine the cheapest possible set of demands for each month, and create an annual profile of those demands
for month in range(12):
    # Extract the load profile for only the month under consideration
    load_profile_month = load_profile[month_hours[month]:month_hours[month+1]]
    d_periods_month = t.d_periods[month_hours[month]:month_hours[month+1]]
    
    # columns [:-1] of cheapest_possible_demands are the achievable demand levels, column [-1] is the cost
    # d_max_vector is an hourly vector of the demand level of that period (to become a max constraint in the DP), which is cast into an 8760 for the year.
    cheapest_possible_demands[month,:], d_max_vector = sFuncs.calc_min_possible_demands(d_inc_n, load_profile_month, d_periods_month, batt, t, month)
    demand_max_profile[month_hours[month]:month_hours[month+1]] = d_max_vector
    

# =================================================================== #
# Dynamic programming dispatch for energy trajectory      
# =================================================================== #
DP_inc = 401
DP_res = batt.cap / (DP_inc-1)


batt_actions_to_achieve_demand_max = demand_max_profile - load_profile
batt_actions_to_achieve_demand_max = np.clip(batt_actions_to_achieve_demand_max, -batt.power, batt.power)
batt_act_normal = batt_actions_to_achieve_demand_max / batt.cap
batt_act_normal_mod = np.mod(batt_act_normal,1/(DP_inc-1.0))
batt_act_normal_cumsum_mod = np.mod(np.cumsum(batt_act_normal[np.arange(8759,-1,-1)]), 1/(DP_inc-1.0))
batt_act_normal_cumsum_mod = batt_act_normal_cumsum_mod[np.arange(8759,-1,-1)]

batt_act_mod = np.mod(batt_actions_to_achieve_demand_max,batt.cap/(DP_inc-1.0))
batt_act_cumsum_mod = np.mod(np.cumsum(batt_actions_to_achieve_demand_max[np.arange(8759,-1,-1)]), batt.cap/(DP_inc-1.0))
batt_act_cumsum_mod = batt_act_cumsum_mod[np.arange(8759,-1,-1)]


# Casting a wide net, and doing a pass/fail test later on with cost-to-go. May later evaluate the limits up front.
batt_charge_limit = int(batt.power*batt.eta/DP_res) + 1
batt_discharge_limit = int(batt.power/batt.eta/DP_res) + 1
batt_charge_limits_len = batt_charge_limit + batt_discharge_limit + 1
# the fact the battery row levels aren't anchored anymore hasn't been thought through. How will I make sure my net is aligned?

# normalized battery charge level. 
# First version, without ensuring that 0 and 1 are options
batt_levels_n = DP_inc + batt_discharge_limit + batt_charge_limit # probably the same as expected_values_n
batt_levels_base = np.zeros([batt_levels_n,8760])
batt_levels_base[:,:] = np.linspace(0-float(batt_discharge_limit)/(DP_inc-1),1+float(batt_charge_limit)/(DP_inc-1),batt_levels_n).reshape(batt_levels_n,1)
batt_levels = batt_levels_base.copy()
batt_levels[:,:-1] = batt_levels_base[:,:-1] - batt_act_normal_cumsum_mod[1:].reshape(1,8759)

batt_levels_n = DP_inc # probably the same as expected_values_n
batt_levels_temp = np.zeros([batt_levels_n,8760])
batt_levels_temp[:,:] = np.linspace(0,1,batt_levels_n).reshape(batt_levels_n,1)

batt_levels_shift = batt_levels_temp.copy()
batt_levels_shift[:,:-1] = batt_levels_temp[:,:-1] - batt_act_normal_cumsum_mod[1:].reshape(1,8759)

batt_levels = np.zeros([batt_levels_n+1,8760])
batt_levels[:-1,:] = batt_levels_shift
batt_levels[0,:] = 0.0
batt_levels[-1,:] = 1.0


batt_levels_buffered = np.zeros([np.shape(batt_levels)[0]+batt_charge_limit+batt_discharge_limit, np.shape(batt_levels)[1]])
batt_levels_buffered[:batt_discharge_limit,:] = 99999999999
batt_levels_buffered[-batt_charge_limit:,:] = 99999999999
batt_levels_buffered[batt_discharge_limit:-batt_charge_limit,:] = batt_levels

################################################
# Is lower index number (higher visually) correspond to lower battery level? I think so, but I need to confirm and document.
####################################################

base_change_in_batt_level_vector = np.zeros(batt_discharge_limit+batt_charge_limit+1)
base_change_in_batt_level_vector[:batt_discharge_limit+1] = np.linspace(-batt_discharge_limit*DP_res,0,batt_discharge_limit+1)
base_change_in_batt_level_vector[batt_discharge_limit:] = np.linspace(0,batt_charge_limit*DP_res,batt_charge_limit+1)

# Each row corresponds to a battery level, each column is the change in batt level associated with that movement.
# The first row corresponds to an empty batt. So it shouldn't be able to discharge. 
# So maybe filter by resulting_batt_level, and exclude ones that are negative or exceed cap?
base_change_in_batt_level_matrix = np.zeros((batt_levels_n+1, len(base_change_in_batt_level_vector)), float)
change_in_batt_level_matrix = np.zeros((batt_levels_n+1, len(base_change_in_batt_level_vector)), float)
base_change_in_batt_level_matrix[:,:] = base_change_in_batt_level_vector

#base_influence_on_net_load = np.array([s/batt.eta if s >= 0 else s*batt.eta for s in base_change_in_batt_level_vector], float)

###############################################################################
# Bring the adjuster back later
###############################################################################
## Slightly adjust the cost/benefits of movement with higher penalities
## for higher power action, such that the DP will prefer constant low
## power charge/discharge over high power discharge
#adjuster = np.zeros(len(base_influence_on_net_load))
#for n in range(batt_discharge_limit): adjuster[n] = 0.00001 * (1.0-(n)/float(batt_discharge_limit))**2.0
#for n in range(batt_charge_limit): adjuster[n+1+batt_discharge_limit] = 0.00001 * ((n+1)/float(batt_charge_limit))**2.0
#base_influence_on_net_load = base_influence_on_net_load + adjuster - 0.00001
#base_influence_on_net_load[batt_discharge_limit] = 0

adjuster = np.zeros(batt_charge_limits_len)
for n in range(batt_discharge_limit): adjuster[n] = 0.00001 * (1.0-(n)/float(batt_discharge_limit))**2.0
for n in range(batt_charge_limit): adjuster[n+1+batt_discharge_limit] = 0.00001 * ((n+1)/float(batt_charge_limit))**2.0


# Initialize some objects for later use in the DP
expected_value_n = DP_inc+1
expected_values = np.zeros((expected_value_n, np.size(load_profile)+1), float) #+1 to add the initial zero column, not sure if necessary
DP_choices = np.zeros((DP_inc+1, np.size(load_profile)+1), float)
influence_on_load = np.zeros(np.shape(base_change_in_batt_level_matrix))

# Expected value of final states is the energy required to fill the battery up
# at the most expensive electricity rate. This encourages ending with a full
# battery, but solves a problem of demand levels being determined by a late-hour
# peak that the battery cannot recharge from before the month ends
# This would be too strict under a CPP rate.
# I should change this to evaluating the required charge based on the batt_level matrix, to keep self-consistent
expected_values[:,-1] = np.linspace(batt.cap,0,DP_inc+1)/batt.eta*np.max(t.e_prices_no_tier) #this should be checked, after removal of buffer rows
#expected_values[batt_discharge_limit+DP_inc-1,-1] = 0 # this should just be setting the full battery end state to zero

# Each row is the set of options for a single battery state
# Each column is an index corresponding to the possible points within the expected_value matrix that that state can reach
option_indicies = np.zeros((DP_inc+1, batt_charge_limits_len), int)
option_indicies[:,:] = range(batt_charge_limits_len)
for n in range(DP_inc+1):
    option_indicies[n,:] += n - batt_discharge_limit
option_indicies = (option_indicies>0) * option_indicies # have not checked this default of pointing towards zero
option_indicies = (option_indicies<DP_inc+1) * option_indicies

net_loads = np.zeros((DP_inc+1, batt_charge_limits_len), float)
costs_to_go = np.zeros((DP_inc+1, batt_charge_limits_len), float) # should clean up the DP_inc+1 at some point...

# Adding in a zero because it needs to decide what to do in the first hour
# Also added +1 to expected_value and DP_Options
# This should be improved
load_profile = np.insert(load_profile,0,0)
t.e_periods = np.insert(t.e_periods,0,0)
t.d_periods = np.insert(t.d_periods,0,0)
demand_max_profile = np.insert(demand_max_profile, 0, 0)
batt_act_cumsum_mod = np.insert(batt_act_cumsum_mod,0,0)
batt_levels = np.insert(batt_levels,0,0, axis=1)
batt_levels_buffered = np.insert(batt_levels_buffered,0,0, axis=1)

demand_max_profile = demand_max_profile# + DP_res # placeholder addition until mapping is fixed

#%%
# Dynamic Programming Energy Trajectory
for hour in np.arange(np.size(load_profile)-2, -1, -1):
    # Rows correspond to each possible battery state
    # Columns are options for where this particular battery state could go to
    # Index is hour+1 because the DP decisions are on a given hour, looking ahead to the next hour. 

    change_in_batt_level_matrix = base_change_in_batt_level_matrix + batt_act_cumsum_mod[hour+1] - batt_act_cumsum_mod[hour]
    
    # this is just an inefficient but obvious way to assembled this matrix. It should be possible in a few quicker operations.
    for row in range(batt_levels_n+1):
        change_in_batt_level_matrix[row,:] = (-batt_levels[row,hour] + batt_levels_buffered[row:row+batt_charge_limits_len,hour+1]) * batt.cap

    # this is not complete - discrepencies with 0 and 1.0 level are not captured
    # it also only currently is working off of the base change, not the shifted change
    resulting_batt_level = change_in_batt_level_matrix + batt_levels[:,hour].reshape(DP_inc+1,1)*batt.cap
    neg_batt_bool = resulting_batt_level<0
    overfilled_batt_bool = resulting_batt_level>batt.cap #this seems to be misbehaving due to float imprecision
    
    charging_bool = change_in_batt_level_matrix>0
    discharging_bool = change_in_batt_level_matrix<0
    
    influence_on_load = np.zeros(np.shape(change_in_batt_level_matrix))
    influence_on_load += change_in_batt_level_matrix*batt.eta * discharging_bool
    influence_on_load += change_in_batt_level_matrix/batt.eta * charging_bool
    
    net_loads = load_profile[hour+1] + influence_on_load

    # I may also need to filter for moves the battery can't actually make
    
    # Determine the incremental cost-to-go for each option
    costs_to_go[:,:] = 0 # reset costs to go
    importing_bool = net_loads>=0 # If consuming, standard price
    costs_to_go += net_loads*t.e_prices_no_tier[t.e_periods[hour+1]]*importing_bool
    exporting_bool = net_loads<0 # If exporting, NEM price
    costs_to_go += net_loads*NEM_tariff.e_credits[t.e_periods[hour+1]]*exporting_bool     
    
    # Make the incremental cost of impossible/illegal movements very high
    costs_to_go += neg_batt_bool * 99999999
    costs_to_go += overfilled_batt_bool * 99999999
    demand_limit_exceeded_bool = net_loads>demand_max_profile[hour+1]
    costs_to_go += demand_limit_exceeded_bool * 99999999
    
    # add very small cost as a function of battery motion, to discourage unnecessary motion
    costs_to_go += adjuster*100
        
    total_option_costs = costs_to_go + expected_values[option_indicies, hour+1]
    
    # something is wrong - in the final step I see an optimal choice of having
    # a partially discharged battery, instead of having a full battery. 
    # It should be nearly identical, but nonetheless not preferrable to have an empty
    # I think it may have something to do with the mapping    
    
    expected_values[:, hour] = np.min(total_option_costs,1)     
         
    
    #Each row corresponds to a row of the battery in DP_states. So the 0th row are the options of the empty battery state.
    #The indicies of the results correspond to the battery's movement. So the (approximate) middle option is the do-nothing option   
    #Subtract the negative half of the charge vector, to get the movement relative to the row under consideration        
    DP_choices[:,hour] = np.argmin(total_option_costs,1) - batt_discharge_limit # adjust by discharge?
    if hour == 7480:
        calvin = True
    
# Determine what the optimal trajectory was
# Start at the 0th hour, imposing a full battery    
# traj_i is the battery's trajectory.
traj_i = np.zeros(len(load_profile), int)
traj_i[0] = DP_inc-1
for n in range(len(load_profile)-1):
    traj_i[n+1] = traj_i[n] + DP_choices[int(traj_i[n]), n]
    #traj_i[n+1] = traj_i[n]

    
opt_batt_traj = np.zeros(len(load_profile))
opt_batt_traj_f = np.zeros(len(load_profile))
for n in range(len(load_profile)-1):
    opt_batt_traj_f[n] = batt_levels[traj_i[n], n]
    opt_batt_traj[n] = opt_batt_traj_f[n] * batt.cap
    
batt_movement = np.zeros(len(load_profile))
for n in np.arange(1,len(load_profile)-1,1):
    batt_movement[n] = opt_batt_traj[n] - opt_batt_traj[n-1]
    
batt_influence_on_load = np.array([s/batt.eta if s >= 0 else s*batt.eta for s in batt_movement], float)

opt_net_profile = load_profile + batt_influence_on_load

# Remove the initial zero column
load_profile = load_profile[1:]
opt_net_profile = opt_net_profile[1:]
t.e_periods = t.e_periods[1:]
t.d_periods = t.d_periods[1:]
demand_max_profile = demand_max_profile[1:]

t = range(8760)
plt.figure(figsize=(20,8))
plt.plot(t, load_profile, t, opt_net_profile, t, demand_max_profile)
plt.grid(True)
mpld3.show()

#action_DP = np.zeros((3,len(load_profile)))
#for n in np.arange(1,len(load_profile)):
#    action_DP[0,n] = traj_i[n] - traj_i[n-1] # Discrete movements of battery level index
#    action_DP[1,n] = charge_range_DP[int(action_DP[0,n]+batt_charge_limits[0]),0] # Battery level energy movement
#    action_DP[2,n] = charge_range_DP[int(action_DP[0,n]+batt_charge_limits[0]),1] # Influence on load
#
#net_profile = load_profile + action_DP[2,:]
#
## Remove the initial zero column
#load_profile = load_profile[1:]
#net_profile = net_profile[1:]
#t.e_periods = t.e_periods[1:]
#t.d_periods = t.d_periods[1:]
#demand_max_profile_DP = demand_max_profile_DP[1:]
#
## Determine what the energy consumption for each period was
## Each row is a month, each column is a period
#energy_consumpt = np.zeros([12,t.e_n])
#for month in range(12):
#    net_profile_month = net_profile[month_hours[month]:month_hours[month+1]]
#    energy_periods_month = t.e_periods[month_hours[month]:month_hours[month+1]]
#    for period in range(t.e_n):
#        net_periods = net_profile_month[energy_periods_month==period]
#        #imported = net_periods[net_periods>0]
#        #just assuming full retail NEM for now...
#        energy_consumpt[month,period] = sum(net_periods)
#
#energy_charges = tiered_calc_vec(energy_consumpt, t.e_levels[:,:t.e_n], t.e_prices[:,:t.e_n])
#
#final_bill = sum(cheapest_possible_demands[:,-1]) + np.sum(energy_charges) + 12*t.fixed_charge
            
            
            
            
            
            
#neg_batt_bool = option_indicies<batt_discharge_limit
#overfilled_batt_bool = option_indicies>expected_value_n - batt_charge_limit #check this...    

## This is an artificial way to avoid the problem created by having the DP battery
## levels not line up exactly with the determined dMax levels. This buffer relaxes
## the demand limit enough so that it will always solve, and then I clean it up
## at the end when constructing the trajectory. This is technically incorrect,
## but % error is low and it is fast.
##demand_max_profile_DP = demand_max_profile + DP_res
#demand_max_profile_DP = demand_max_profile
    
# Negative and overcharged battery levels are prohibitively expensive
#expected_values[:batt_discharge_limit,:] = 99999999    
#expected_values[-batt_charge_limit:,:] = 99999999
    
#expected_value_of_max_demand = np.zeros(len(load_profile)+1)
#expected_value_of_max_demand[-1] = demand_max_profile[-1]*t.e_prices_no_tier[t.e_periods[-1]]    
## Not sure if these are the right step sizes.
## Just in general, haven't checked that these are correct.
#possible_discharges = np.clip(-np.linspace(DP_inc,0, DP_inc)*batt.eta, -batt.power, 0)
#possible_charges = np.clip(np.linspace(0,DP_inc, DP_inc)/batt.eta, 0, batt.power)
# old script for max demand approach
#    ###############################################################
#    # Evaluate the expected values of achieving the max demand level of h+1, given a starting battery level in h
#    max_demand = demand_max_profile_DP[hour+1]
#    action_required_to_move_to_max = max_demand - load_profile[hour+1] 
#    
#    # The price of achieving max demand doesn't matter where it came from, but points outside of bounds cannot achieve it.
#    cost_to_go_to_max_demand = max_demand * t.e_prices_no_tier[t.e_periods[hour+1]]
#    if action_required_to_move_to_max >= 0.0: unable_to_achieve_max_bool = possible_charges <= action_required_to_move_to_max
#    if action_required_to_move_to_max < 0.0: unable_to_achieve_max_bool = possible_discharges >= action_required_to_move_to_max
#    cost_to_go_to_max_demand += unable_to_achieve_max_bool * 999999999999
#    
#    
#    total_max_demand_cost = cost_to_go_to_max_demand + expected_value_of_max_demand[hour+1]
#
#    # Evaluate the cost-to-go from the max-demand levels.
#    # Similiar to cost-to-go from standard levels, except achieving
#    # the max demand in h+1 would set battery to non-standard level,
#    # 
#    
#    # Expected value of the max-demand option
#    expected_value_of_max_demand[hour] =      0         