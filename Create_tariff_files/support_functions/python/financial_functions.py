# -*- coding: utf-8 -*-
"""
Created on Tue Oct 11 10:27:48 2016

@author: pgagnon
"""

import numpy as np


#%%
def cashflow_constructor(bill_savings, 
                         pv_size, pv_price, inverter_price, pv_om,
                         batt_cap, batt_power, 
                         batt_cost_per_kw, batt_cost_per_kwh, 
                         batt_replace_cost_per_kw, batt_replace_cost_per_kwh,
                         batt_chg_frac,
                         batt_replacement_sch, batt_om,
                         sector, itc, deprec_sched, 
                         fed_tax_rate, state_tax_rate, real_d,  
                         analysis_years, inflation, 
                         down_payment_fraction, loan_rate, loan_term, 
                         cash_incentives=np.array([0]), ibi=np.array([0]), cbi=np.array([0]), pbi=np.array([[0]])):
    '''
    Accepts financial assumptions and returns the cash flows for the projects.
    Vectorized.
    
    Inputs:
    -bill_savings is a cash flow of the annual bill savings over the lifetime
     of the system, including changes to the price or structure of electricity, 
     in present-year dollars (i.e., excluding inflation).
     Need to construct this beforehand, to either simulate degradation or make 
     assumptions about degradation.
    -ibi is up front investment based incentive
    -cbi is up front capacity based incentive
    -batt_chg_frac is the fraction of the battery's energy that it gets from
     a co-hosted PV system. Used for ITC calculation.
    
    Things that would be nice to add:
    -Sales tax basis and rate
    -note that sales tax goes into depreciable basis
    -Propery taxes (res can deduct from income taxes, I think)
    -insurance
    -add pre-tax cash flow
    -add residential mortgage option
    -add carbon tax revenue

    To Do:
    -More exhaustive checking. I have confirmed basic formulations against SAM, but there are many permutations that haven't been checked.
    -make incentives reduce depreciable basis
    -add a flag for high incentive levels
    -battery price schedule, for replacements
    -improve inverter replacement
    -improve battery replacement
    -add inflation adjustment for replacement prices
    -improve deprec schedule handling
    -Make financing unique to each agent
    -Make battery replacements depreciation an input, with default of 7 year MACRS
    -Have a better way to deal with capacity vs effective capacity and battery costs
    -make it so it can accept different loan terms
    '''

    #################### Massage inputs ########################################
    # If given just a single value for an agent-specific variable, repeat that
    # variable for each agent. This assumes that the variable is intended to be
    # applied to each agent. 

    if np.size(np.shape(bill_savings)) == 1: shape = (1, analysis_years+1)
    else: shape = (np.shape(bill_savings)[0], analysis_years+1)
    n_agents = shape[0]

    if np.size(sector) != n_agents or n_agents==1: sector = np.repeat(sector, n_agents) 
    if np.size(fed_tax_rate) != n_agents or n_agents==1: fed_tax_rate = np.repeat(fed_tax_rate, n_agents) 
    if np.size(state_tax_rate) != n_agents or n_agents==1: state_tax_rate = np.repeat(state_tax_rate, n_agents) 
    if np.size(itc) != n_agents or n_agents==1: itc = np.repeat(itc, n_agents) 
    if np.size(pv_size) != n_agents or n_agents==1: pv_size = np.repeat(pv_size, n_agents) 
    if np.size(pv_price) != n_agents or n_agents==1: pv_price = np.repeat(pv_price, n_agents) 
    if np.size(inverter_price) != n_agents or n_agents==1: inverter_price = np.repeat(inverter_price, n_agents) 
    if np.size(pv_om) != n_agents or n_agents==1: pv_om = np.repeat(pv_om, n_agents) 
    if np.size(batt_cap) != n_agents or n_agents==1: batt_cap = np.repeat(batt_cap, n_agents) 
    if np.size(batt_power) != n_agents or n_agents==1: batt_power = np.repeat(batt_power, n_agents) 
    if np.size(batt_cost_per_kw) != n_agents or n_agents==1: batt_cost_per_kw = np.repeat(batt_cost_per_kw, n_agents) 
    if np.size(batt_cost_per_kwh) != n_agents or n_agents==1: batt_cost_per_kwh = np.repeat(batt_cost_per_kwh, n_agents) 
    if np.size(batt_replace_cost_per_kw) != n_agents or n_agents==1: batt_replace_cost_per_kw = np.repeat(batt_replace_cost_per_kw, n_agents) 
    if np.size(batt_replace_cost_per_kwh) != n_agents or n_agents==1: batt_replace_cost_per_kwh = np.repeat(batt_replace_cost_per_kwh, n_agents) 
    if np.size(batt_chg_frac) != n_agents or n_agents==1: batt_chg_frac = np.repeat(batt_chg_frac, n_agents) 
    if np.size(batt_om) != n_agents or n_agents==1: batt_om = np.repeat(batt_om, n_agents) 
    if np.size(real_d) != n_agents or n_agents==1: real_d = np.repeat(real_d, n_agents) 
    if np.size(down_payment_fraction) != n_agents or n_agents==1: down_payment_fraction = np.repeat(down_payment_fraction, n_agents) 
    if np.size(loan_rate) != n_agents or n_agents==1: loan_rate = np.repeat(loan_rate, n_agents) 
    if np.size(ibi) != n_agents or n_agents==1: ibi = np.repeat(ibi, n_agents) 
    if np.size(cbi) != n_agents or n_agents==1: cbi = np.repeat(cbi, n_agents) 
    
    
    if np.size(pbi) != n_agents or n_agents==1: pbi = np.repeat(pbi, n_agents)[:,np.newaxis]
    if deprec_sched.ndim == 1 or n_agents==1: deprec_sched = np.array([deprec_sched])
#    if len(loan_term) != n_agents: loan_term = np.repeat(loan_term, n_agents)
#    if np.size(batt_replacement_sch) != n_agents: batt_replacement_sch = np.repeat(batt_replacement_sch, n_agents)

    #################### Setup #########################################
    effective_tax_rate = fed_tax_rate * (1 - state_tax_rate) + state_tax_rate
    nom_d = (1 + real_d) * (1 + inflation) - 1
    cf = np.zeros(shape) 
    inflation_adjustment = (1+inflation)**np.arange(analysis_years+1)
    
    #################### Bill Savings #########################################
    # For C&I customers, bill savings are reduced by the effective tax rate,
    # assuming the cost of electricity could have otherwise been counted as an
    # O&M expense to reduce federal and state taxable income.
    bill_savings = bill_savings*inflation_adjustment # Adjust for inflation
    after_tax_bill_savings = np.zeros(shape)
    after_tax_bill_savings = (bill_savings.T * (1 - (sector!='res')*effective_tax_rate)).T # reduce value of savings because they could have otherwise be written off as operating expenses

    cf += bill_savings
    
    #################### Installed Costs ######################################
    # Assumes that cash incentives, IBIs, and CBIs will be monetized in year 0,
    # reducing the up front installed cost that determines debt levels. 
    pv_cost = pv_size*pv_price     # assume pv_price includes initial inverter purchase
    batt_cost = batt_power*batt_cost_per_kw + batt_cap*batt_cost_per_kwh
    installed_cost = pv_cost + batt_cost
    net_installed_cost = installed_cost - cash_incentives - ibi - cbi
    up_front_cost = net_installed_cost * down_payment_fraction
    cf[:,0] -= up_front_cost
    
    #################### Replacements #########################################
    # It would be better to inflate the replacement costs for inflation, rather
    # than adjusting it at the end.
    inv_replacement_cf = np.zeros(shape)
    batt_replacement_cf = np.zeros(shape)
    
    # Inverter replacements
    inv_replacement_cf[:,10] -= pv_size * inverter_price # assume a single inverter replacement at year 10
    
    # Battery replacements
    # Assumes battery replacements can harness 7 year MACRS depreciation
    replacement_deductions = np.zeros([n_agents,analysis_years+20]) #need a temporary larger array to hold depreciation schedules. Not that schedules may get truncated by analysis years. 
    macrs_7_yr_sch = np.zeros([n_agents, 8])
    macrs_7_yr_sch[:,:] = np.array([.1429,.2449,.1749,.1249,.0893,.0892,.0893,0.0446])    
    
    if False:
        # Actual future-value replacement cashflow analysis
        batt_replacement_cf[:,batt_replacement_sch] -= (batt_power*batt_replace_cost_per_kw + batt_cap*batt_replace_cost_per_kwh)
        replacement_deductions[:,batt_replacement_sch+1:batt_replacement_sch+9] = (batt_cost * macrs_7_yr_sch.T).T #this assumes no itc or basis-reducing incentives for batt replacements
    else:
        # Using present-value of replacement and deduction values, to avoid problems with simple payback calc in NYSERDA analysis
        batt_replacement_cf[:,0] -= (batt_power*batt_replace_cost_per_kw + batt_cap*batt_replace_cost_per_kwh  / (1 + real_d)**batt_replacement_sch) #.reshape(n_agents, 1)
        replacement_deductions[:,0]  = (batt_power*batt_replace_cost_per_kw + batt_cap*batt_replace_cost_per_kwh  / (1 + real_d)**batt_replacement_sch) * 0.766112
    
    # Adjust for inflation
    inv_replacement_cf = inv_replacement_cf*inflation_adjustment
    batt_replacement_cf = batt_replacement_cf #*inflation_adjustment - inflation temp removed because of present value adjustment
    deprec_deductions = replacement_deductions[:,:analysis_years+1] #*inflation_adjustment
    
    cf += inv_replacement_cf + batt_replacement_cf
    
    #################### Operating Expenses ###################################
    # Nominally includes O&M, fuel, insurance, and property tax - although 
    # currently only includes O&M.
    # All operating expenses increase with inflation
    operating_expenses_cf = np.zeros(shape)
    operating_expenses_cf[:,1:] = (pv_om * pv_size + batt_om * batt_cap).reshape(n_agents, 1)
    operating_expenses_cf = operating_expenses_cf*inflation_adjustment
    cf -= operating_expenses_cf
    
    #################### Federal ITC #########################################
    pv_itc_value = pv_cost * itc
    batt_itc_value = batt_cost * itc * batt_chg_frac * (batt_chg_frac>=0.75)
    itc_value = pv_itc_value + batt_itc_value
    # itc value added in fed_tax_savings_or_liability
    
    #################### Depreciation #########################################
    # Per SAM, depreciable basis is sum of total installed cost and total 
    # construction financing costs, less 50% of ITC and any incentives that
    # reduce the depreciable basis.
    deprec_basis = installed_cost - itc_value*0.5 
    deprec_deductions[:,1:np.size(deprec_sched,1)+1] = (deprec_basis * deprec_sched.T).T
    # to be used later in fed tax calcs
    
    #################### Debt cash flow #######################################
    # Deduct loan interest payments from state & federal income taxes for res 
    # mortgage and C&I. No deduction for res loan.
    # note that the debt balance in year0 is different from principal if there 
    # are any ibi or cbi. Not included here yet.
    # debt balance, interest payment, principal payment, total payment
    
    initial_debt = net_installed_cost - up_front_cost
    annual_principal_and_interest_payment = initial_debt * (loan_rate*(1+loan_rate)**loan_term) / ((1+loan_rate)**loan_term - 1)
    debt_balance = np.zeros(shape)
    interest_payments = np.zeros(shape)
    principal_and_interest_payments = np.zeros(shape)
    
    debt_balance[:,:loan_term] = (initial_debt*((1+loan_rate.reshape(n_agents,1))**np.arange(loan_term)).T).T - (annual_principal_and_interest_payment*(((1+loan_rate).reshape(n_agents,1)**np.arange(loan_term) - 1.0)/loan_rate.reshape(n_agents,1)).T).T  
    interest_payments[:,1:] = (debt_balance[:,:-1].T * loan_rate).T
    principal_and_interest_payments[:,1:loan_term+1] = annual_principal_and_interest_payment.reshape(n_agents, 1)
    
    cf -= principal_and_interest_payments
    
        
    #################### State Income Tax #########################################
    # Per SAM, taxable income is CBIs and PBIs (but not IBIs)
    # Assumes no state depreciation
    # Assumes that revenue from DG is not taxable income
    total_taxable_income = np.zeros(shape)
    total_taxable_income[:,1] = cbi
    total_taxable_income[:,:np.shape(pbi)[1]] += pbi
    
    state_deductions = np.zeros(shape)
    state_deductions += (interest_payments.T * (sector!='res')).T
    state_deductions += (operating_expenses_cf.T * (sector!='res')).T
    state_deductions -= bill_savings
    
    total_taxable_state_income_less_deductions = total_taxable_income - state_deductions
    state_income_taxes = (total_taxable_state_income_less_deductions.T * state_tax_rate).T
    
    state_tax_savings_or_liability = -state_income_taxes
    
    cf += state_tax_savings_or_liability
        
    ################## Federal Income Tax #########################################
    # Assumes all deductions are federal
    fed_deductions = np.zeros(shape)
    fed_deductions += (interest_payments.T * (sector!='res')).T
    fed_deductions += (deprec_deductions.T * (sector!='res')).T
    fed_deductions += state_income_taxes
    fed_deductions += (operating_expenses_cf.T * (sector!='res')).T
    fed_deductions -= bill_savings
    
    total_taxable_fed_income_less_deductions = total_taxable_income - fed_deductions
    fed_income_taxes = (total_taxable_fed_income_less_deductions.T * fed_tax_rate).T
    
    fed_tax_savings_or_liability_less_itc = -fed_income_taxes
    
    cf += fed_tax_savings_or_liability_less_itc
    cf[:,1] += itc_value
    
    
    ######################## Packaging tax outputs ############################
    interest_payments_tax_savings = (interest_payments.T * effective_tax_rate).T
    operating_expenses_tax_savings = (operating_expenses_cf.T * effective_tax_rate).T
    deprec_deductions_tax_savings = (deprec_deductions.T * fed_tax_rate).T    
    elec_OM_deduction_decrease_tax_liability = (bill_savings.T * effective_tax_rate).T
    
    ########################### Post Processing ###############################
    
#    dr = nom_d[:,np.newaxis]
#    tmp = np.empty(cf.shape)
#    tmp[:,0] = 1
#    tmp[:,1:] = 1/(1+dr)
#    drm = np.cumprod(tmp, axis = 1)        
#    npv = (drm * cf).sum(axis = 1)      
    powers = np.zeros(shape, int)
    powers[:,:] = np.array(range(analysis_years+1))
    discounts = np.zeros(shape, float)
    discounts[:,:] = (1/(1+nom_d)).reshape(n_agents, 1)
    cf_discounted = cf * np.power(discounts, powers)
    npv = np.sum(cf_discounted, 1)
    
    
    ########################### Package Results ###############################
    
    results = {'cf':cf,
               'cf_discounted':cf_discounted,
               'npv':npv,
               'bill_savings':bill_savings,
               'after_tax_bill_savings':after_tax_bill_savings,
               'pv_cost':pv_cost,
               'batt_cost':batt_cost,
               'installed_cost':installed_cost,
               'up_front_cost':up_front_cost,
               'inv_replacement':inv_replacement_cf,
               'batt_replacement':batt_replacement_cf,              
               'operating_expenses':operating_expenses_cf,
               'pv_itc_value':pv_itc_value,
               'batt_itc_value':batt_itc_value,
               'itc_value':itc_value,
               'deprec_basis':deprec_basis,
               'deprec_deductions':deprec_deductions,
               'initial_debt':initial_debt,
               'annual_principal_and_interest_payment':annual_principal_and_interest_payment,
               'debt_balance':debt_balance,
               'interest_payments':interest_payments,
               'principal_and_interest_payments':principal_and_interest_payments,
               'total_taxable_income':total_taxable_income,
               'state_deductions':state_deductions,
               'total_taxable_state_income_less_deductions':total_taxable_state_income_less_deductions,
               'state_income_taxes':state_income_taxes,
               'fed_deductions':fed_deductions,
               'total_taxable_fed_income_less_deductions':total_taxable_fed_income_less_deductions,
               'fed_income_taxes':fed_income_taxes,
               'interest_payments_tax_savings':interest_payments_tax_savings,
               'operating_expenses_tax_savings':operating_expenses_tax_savings,
               'deprec_deductions_tax_savings':deprec_deductions_tax_savings,
               'elec_OM_deduction_decrease_tax_liability':elec_OM_deduction_decrease_tax_liability}

    return results

#%%
#==============================================================================

def calc_npv(cfs,dr):
    ''' Vectorized NPV calculation based on (m x n) cashflows and (n x 1) 
    discount rate
    
    author: bsigrin
    
    IN: cfs - numpy array - project cash flows ($/yr)
        dr  - numpy array - annual discount rate (decimal)
        
    OUT: npv - numpy array - net present value of cash flows ($) 
    
    '''
    dr = dr[:,np.newaxis]
    tmp = np.empty(cfs.shape)
    tmp[:,0] = 1
    tmp[:,1:] = 1/(1+dr)
    drm = np.cumprod(tmp, axis = 1)        
    npv = (drm * cfs).sum(axis = 1)   
    return npv
    
    
#==============================================================================
     
def calc_payback_vectorized(cfs, tech_lifetime):
    '''payback calculator
    Can be either simple payback or discounted payback, depending on whether
     the input cash flow is discounted.    
    
    Author: Ben Sigrin    
    
    Inputs:
    -cfs - numpy array - project cash flows ($/yr)
    
    Outputs: 
    pp - numpy array - interpolated payback period (years)
    
    '''
    
    years = np.array([np.arange(0, tech_lifetime)] * cfs.shape[0])
    
    cum_cfs = cfs.cumsum(axis = 1)   
    no_payback = np.logical_or(cum_cfs[:, -1] <= 0, np.all(cum_cfs <= 0, axis = 1))
    instant_payback = np.all(cum_cfs > 0, axis = 1)
    neg_to_pos_years = np.diff(np.sign(cum_cfs)) > 0
    base_years = np.amax(np.where(neg_to_pos_years, years, -1), axis = 1)
    
    # replace values of -1 with 30
    base_years_fix = np.where(base_years == -1, tech_lifetime - 1, base_years)
    base_year_mask = years == base_years_fix[:, np.newaxis]
    
    # base year values
    base_year_values = cum_cfs[:, :-1][base_year_mask]
    next_year_values = cum_cfs[:, 1:][base_year_mask]
    frac_years = base_year_values/(base_year_values - next_year_values)
    pp_year = base_years_fix + frac_years
    pp_precise = np.where(no_payback, tech_lifetime, np.where(instant_payback, 0, pp_year))
    
    pp_final = np.array(pp_precise).round(decimals = 3)
    
    return pp_final
    
#%%
def virr(cfs, precision = 0.005, rmin = 0, rmax1 = 0.3, rmax2 = 0.5):
    ''' Vectorized IRR calculator. First calculate a 3D array of the discounted
    cash flows along cash flow series, time period, and discount rate. Sum over time to 
    collapse to a 2D array which gives the NPV along a range of discount rates 
    for each cash flow series. Next, find crossover where NPV is zero--corresponds
    to the lowest real IRR value. For performance, negative IRRs are not calculated
    -- returns "-1", and values are only calculated to an acceptable precision.
    
    IN:
        cfs - numpy 2d array - rows are cash flow series, cols are time periods
        precision - level of accuracy for the inner IRR band eg 0.005%
        rmin - lower bound of the inner IRR band eg 0%
        rmax1 - upper bound of the inner IRR band eg 30%
        rmax2 - upper bound of the outer IRR band. eg 50% Values in the outer 
                band are calculated to 1% precision, IRRs outside the upper band 
                return the rmax2 value
    OUT:
        r - numpy column array of IRRs for cash flow series
        
    M Gleason, B Sigrin - NREL 2014
    '''
    
    if cfs.ndim == 1: 
        cfs = cfs.reshape(1,len(cfs))

    # Range of time periods
    years = np.arange(0,cfs.shape[1])
    
    # Range of the discount rates
    rates_length1 = int((rmax1 - rmin)/precision) + 1
    rates_length2 = int((rmax2 - rmax1)/0.01)
    rates = np.zeros((rates_length1 + rates_length2,))
    rates[:rates_length1] = np.linspace(0,0.3,rates_length1)
    rates[rates_length1:] = np.linspace(0.31,0.5,rates_length2)

    # Discount rate multiplier rows are years, cols are rates
    drm = (1+rates)**-years[:,np.newaxis]

    # Calculate discounted cfs   
    discounted_cfs = cfs[:,:,np.newaxis] * drm
    
    # Calculate NPV array by summing over discounted cashflows
    npv = discounted_cfs.sum(axis = 1)
    
    # Convert npv into boolean for positives (0) and negatives (1)
    signs = npv < 0
    
    # Find the pairwise differences in boolean values
    # sign crosses over, the pairwise diff will be True
    crossovers = np.diff(signs,1,1)
    
    # Extract the irr from the first crossover for each row
    irr = np.min(np.ma.masked_equal(rates[1:]* crossovers,0),1)
    
    # deal with negative irrs
    negative_irrs = cfs.sum(1) < 0
    r = np.where(negative_irrs,-1,irr)
    
    # where the implied irr exceeds 0.5, simply cap it at 0.5
    r = np.where(irr.mask * (negative_irrs == False), 0.5, r)

    # where cashflows are all zero, set irr to nan
    r = np.where(np.all(cfs == 0, axis = 1), np.nan, r)
        
    return r