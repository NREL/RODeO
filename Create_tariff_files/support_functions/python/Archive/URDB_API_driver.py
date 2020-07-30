# -*- coding: utf-8 -*-
"""
Created on Wed Sep 07 16:48:13 2016

@author: pgagnon

Purpose: Experimenting with URDB API and formatting the resulting tariffs

To Do:
# Keep as a dict for now, but recast as a class for actual handling?
# Write the dicts and csvs? Make it digest a list later - for now just get one working
# rewrite with the variables expected by the calculator
- Have it filter or keep track of energy tier units
- I have not checked the 12x24 to 8760 conversion
"""

import requests as req
import numpy as np



input_params = {'version':3,
                'format':'json',
                'detail':'full',
                'getpage':'57bcd2b65457a3a67e540154', # not real: 57d0b2315457a3120ec5b286 real: 57bcd2b65457a3a67e540154
                'api_key':'bg51RuoT2OD733xqu0ehRRZWUzBGvOJuN5xyRtB4'}

r = req.get('http://api.openei.org/utility_rates?', params=input_params)

tariff_original = r.json()['items'][0]

name_mapping = {
        'name':'name',        
        'utility':'utility',
        'fixed_charge':'fixedmonthlycharge',
        'peak_kW_capacity_max':'peakkwcapacitymax',
        'peak_kW_capacity_min':'peakkwcapacitymin',
        'kWh_useage_max':'peakkwhusagemax',
        'kWh_useage_min':'peakkwhusagemin',
        'sector':'sector',
        'comments':'basicinformationcomments',
        'description':'description',
        'source':'source',
        'uri':'uri',
        'voltage_category':'voltagecategory'}
        
defaults = {
        'name':'No name specified',        
        'utility':'No utility specified',
        'fixed_charge':0,
        'peak_kW_capacity_max':1e99,
        'peak_kW_capacity_min':0,
        'kWh_useage_max':1e99,
        'kWh_useage_min':0,
        'sector':'No sector specified',
        'comments':'No comments given',
        'description':'No description given',
        'source':'No source given',
        'uri':'No uri given',
        'voltage_category':'No voltage category given'}

entries = ['name', 'utility','fixed_charge', 'peak_kW_capacity_max',
        'peak_kW_capacity_min','kWh_useage_max','kWh_useage_min','sector',
        'comments','description','source','uri','voltage_category']

tariff_result = {'urdb_label':tariff_original['label']}

for entry in entries:
    if name_mapping[entry] in tariff_original: tariff_result[entry] = tariff_original[name_mapping[entry]]
    else: tariff_result[entry] = defaults[entry]


###################### Repackage Flat Demand Structure ########################
if 'flatdemandstructure' in tariff_original:
    d_flat_exists = True
    d_flat_structure = tariff_original['flatdemandstructure']
    d_flat_n = len(np.unique(tariff_original['flatdemandmonths']))
    
    # Determine the maximum number of tiers in the demand structure
    max_tiers = 1
    for period in range(d_flat_n):
        n_tiers = len(d_flat_structure[period])
        if n_tiers > max_tiers: max_tiers = n_tiers
    
    # Repackage Energy TOU Structure   
    d_flat_prices = np.zeros([max_tiers, d_flat_n])     
    d_flat_levels = np.zeros([max_tiers, d_flat_n])
    d_flat_levels[:,:] = 1e9
    for period in range(d_flat_n):
        for tier in range(len(d_flat_structure[period])):
            d_flat_levels[tier, period] = d_flat_structure[period][tier].get('max', 1e9)
            d_flat_prices[tier, period] = d_flat_structure[period][tier].get('rate', 0) + d_flat_structure[period][tier].get('adj', 0)
else:
    d_flat_exists = False
    d_flat_n = 0
    d_flat_prices = np.zeros([1, 1])     
    d_flat_levels = np.zeros([1, 1])

#################### Repackage Demand TOU Structure ###########################
if 'demandratestructure' in tariff_original:
    demand_structure = tariff_original['demandratestructure']
    d_n = len(demand_structure)
    if d_n > 1: d_tou_exists = True
    else: 
        d_tou_exists = False
        d_flat_exists = True
    
    # Determine the maximum number of tiers in the demand structure
    max_tiers = 1
    for period in range(d_n):
        n_tiers = len(demand_structure[period])
        if n_tiers > max_tiers: max_tiers = n_tiers
    
    # Repackage Demand TOU Structure   
    d_tou_prices = np.zeros([max_tiers, d_n])     
    d_tou_levels = np.zeros([max_tiers, d_n])
    d_tou_levels[:,:] = 1e9
    for period in range(d_n):
        for tier in range(len(demand_structure[period])):
            d_tou_levels[tier, period] = demand_structure[period][tier].get('max', 1e9)
            d_tou_prices[tier, period] = demand_structure[period][tier].get('rate', 0) + demand_structure[period][tier].get('adj', 0)
else:
    d_tou_exists = False
    d_n = 0
    d_tou_prices = np.zeros([1, 1])     
    d_tou_levels = np.zeros([1, 1])


######################## Repackage Energy Structure ###########################
if 'energyratestructure' in tariff_original:
    e_exists = True
    energy_structure = tariff_original['energyratestructure']
    e_n = len(energy_structure)
    if e_n > 1: e_tou_exists = True
    else: e_tou_exists = False
    
    # Determine the maximum number of tiers in the demand structure
    max_tiers = 1
    for period in range(e_n):
        n_tiers = len(energy_structure[period])
        if n_tiers > max_tiers: max_tiers = n_tiers
    
    # Repackage Energy TOU Structure   
    e_prices = np.zeros([max_tiers, e_n])     
    e_levels = np.zeros([max_tiers, e_n])
    e_levels[:,:] = 1e9
    for period in range(e_n):
        for tier in range(len(energy_structure[period])):
            e_levels[tier, period] = energy_structure[period][tier].get('max', 1e9)
            e_prices[tier, period] = energy_structure[period][tier].get('rate', 0) + energy_structure[period][tier].get('adj', 0)
else:
    e_exists = False
    e_tou_exists = False
    e_n = 0
    e_prices = np.zeros([1, 1])     
    e_levels = np.zeros([1, 1])
    
######################## Repackage Energy Schedule ###########################
e_wkday_12by24 = np.zeros([12,24])
e_wkend_12by24 = np.zeros([12,24])

if 'energyweekdayschedule' in tariff_original:
    for month in range(12):
        e_wkday_12by24[month, :] = tariff_original['energyweekdayschedule'][month]
        e_wkend_12by24[month, :] = tariff_original['energyweekendschedule'][month]

######################## Repackage Demand Schedule ###########################
d_wkday_12by24 = np.zeros([12,24])
d_wkend_12by24 = np.zeros([12,24])

if 'demandweekdayschedule' in tariff_original:
    for month in range(12):
        d_wkday_12by24[month, :] = tariff_original['demandweekdayschedule'][month]
        d_wkend_12by24[month, :] = tariff_original['demandweekendschedule'][month]

################### Repackage 12x24s as 8760s Schedule ########################
month_hours =  [744, 1416, 2160, 2880, 3624, 4344, 5088, 5832, 6552, 7296, 8016, 8760]
d_tou_8760 = np.zeros(8760)
e_tou_8760 = np.zeros(8760)
month = 0
hour = 0
day = 0
for h in range(8760):
    if day < 5:
        d_tou_8760[h] = d_wkday_12by24[month, hour]
        e_tou_8760[h] = e_wkday_12by24[month, hour]
    else:
        d_tou_8760[h] = d_wkend_12by24[month, hour]
        e_tou_8760[h] = e_wkend_12by24[month, hour]
    hour += 1
    if hour == 24: hour = 0; day += 1
    if day == 7: day = 0
    if h > month_hours[month]: month += 1

######################## Precalculations ######################################
e_prices_no_tier = np.max(e_prices, 0) # simplification until something better is implemented
e_max_difference = np.max(e_prices) - np.min(e_prices)

