# -*- coding: utf-8 -*-
"""
Created on Fri Sep 30 11:26:58 2016

@author: pgagnon

To Do:
"""

import requests as req
import numpy as np
import pandas as pd
import codecs
import json
import datetime

#%%
class Tariff:
    """
    Tariff Attributes:
    -urdb_id: id for utility rate database. US, not international. 
    -eia_id: The EIA assigned ID number for the utility associated with this tariff           
    -name: tariff name
    -utility: Name of utility this tariff is associated with
    -fixed_charge: Fixed monthly charge in $/mo.
    -peak_kW_capacity_max: The annual maximum kW of demand that a customer can have and still be on this tariff
    -peak_kW_capacity_min: The annula minimum kW of demand that a customer can have and still be on this tariff
    -kWh_useage_max: The maximum kWh of average monthly consumption that a customer can have and still be on this tariff
    -kWh_useage_min: The minimum kWh of average monthly consumption that a customer can have and still be on this tariff
    -sector: residential, commercial, or industrial
    -comments: comments from the urdb
    -description: tariff description from urdb
    -source: uri for the source of the tariff
    -uri: link the the urdb page
    -voltage_category: secondary, primary, transmission       
    -d_flat_exists: Boolean of whether there is a flat (not tou) demand charge component. Flat demand is also called monthly or seasonal demand. 
    -d_flat_n: Number of unique flat demand period constructions. Does NOT correspond to width of d_flat_x constructs.
    -d_flat_prices: The prices of each tier/period combination for flat demand. Rows are tiers, columns are months. Differs from TOU, where columns are periods.
    -d_flat_levels: The limit (total kW) of each of each tier/period combination for flat demand. Rows are tiers, columns are months. Differs from TOU, where columns are periods.
    -d_tou_exists = Boolean of whether there is a tou (not flat) demand charge component
    -d_tou_n = Number of unique tou demand periods. Minimum of 1, since I'm counting no-charge periods still as a period.
    -d_tou_prices = The prices of each tier/period combination for tou demand. Rows are tiers, columns are periods.    
    -d_tou_levels = The limit (total kW) of each of each tier/period combination for tou demand. Rows are tiers, columns are periods.
    -e_exists = Boolean of whether there is a flat (not tou) demand charge component
    -e_tou_exists = Boolean of whether there is a flat (not tou) demand charge component
    -e_n = Number of unique energy periods. Minimum of 1, since I'm counting no-charge periods still as a period.
    -e_prices = The prices of each tier/period combination for flat demand. Rows are tiers, columns are periods.    
    -e_levels = The limit (total kWh) of each of each tier/period combination for energy. Rows are tiers, columns are periods.
    -e_wkday_12by24: 12 by 24 period definition for weekday energy. Rows are months, columns are hours.
    -e_wkend_12by24: 12 by 24 period definition for weekend energy. Rows are months, columns are hours.
    -d_wkday_12by24: 12 by 24 period definition for weekday energy. Rows are months, columns are hours.
    -d_wkend_12by24: 12 by 24 period definition for weekend energy. Rows are months, columns are hours.
    -d_tou_8760
    -e_tou_8760
    -e_prices_no_tier
    -e_max_difference: The maximum energy price differential within any single day
    -energy_rate_unit: kWh or kWh/day - for guiding the bill calculations later
    -demand_rate_unit: kW or kW/day - for guiding the bill calculations later
    
    
    To Do
    -peak_kW_capacity and other scalar variables may be being imported as tuples.
     this may have been solved now, but general unit check would be good.
    """
        
    def __init__(self, start_day=6, urdb_id=None, json_file_name=None, dict_obj=None):
                   
        #######################################################################
        ##### If given no urdb id or csv file name, create blank tariff #######
        #######################################################################
                   
        if urdb_id==None and json_file_name==None and dict_obj==None:
            # Default values for a blank tariff
            self.urdb_id = 'No urdb id given'               
            self.name = 'User defined tariff - no name specified'
            self.utility = 'User defined tariff - no name specified'
            self.fixed_charge = 0
            self.peak_kW_capacity_max = 1e99
            self.peak_kW_capacity_min = 0
            self.kWh_useage_max = 1e99
            self.kWh_useage_min = 0
            self.sector = 'No sector specified'
            self.comments = 'No comments given'
            self.description = 'No description given'
            self.source = 'No source given'
            self.uri = 'No uri given'
            self.voltage_category = 'No voltage category given' 
            self.eia_id = 'No eia id given' 
            self.demand_rate_unit = 'kW'
            self.energy_rate_unit = 'kWh'
            self.start_day = 6
            
            self.approved = 'No approved item given'
            self.startdate = 'No startdate given'
            self.enddate = 'No enddate given'
            self.supercedes = 'No supercedes item given'
            self.sourceparent = 'No parent source given'
            self.minmonthlycharge = 'No minimum monthly charge given'
            self.annualmincharge = 'No annual minimum charge given'
            self.voltageminimum = 'No voltage minimum given'
            self.voltagemaximum = 'No voltage maximum given'
            self.phasewiring = 'No phase wiring information given'
            self.demandwindow = 'No demand window given'
            self.demandattrs = 'No additional demand attributes given'
            self.energycomments = 'No aadditional energy comments given'
            self.revisions = 'No revision information given'

            
            ###################### Blank Flat Demand Structure ########################
            self.d_flat_exists = False
            self.d_flat_n = 0
            self.d_flat_prices = np.zeros([1, 12])     
            self.d_flat_levels = np.zeros([1, 12])
            self.d_flat_levels[:,:] = 1e9
                
            
            #################### Blank Demand TOU Structure ###########################
            self.d_tou_exists = False
            self.d_tou_n = 1
            self.d_tou_prices = np.zeros([1, 1])     
            self.d_tou_levels = np.zeros([1, 1])
            
            
            ################ Blank Coincident Peak Structure ##################
            self.coincident_peak_exists = False            

            
            ######################## Blank Energy Structure ###########################
            self.e_exists = False
            self.e_tou_exists = False
            self.e_n = 1
            self.e_prices = np.zeros([1, 1])     
            self.e_levels = np.zeros([1, 1])
            
                
            ######################## Blank Schedules ###########################
            self.e_wkday_12by24 = np.zeros([12,24], int)
            self.e_wkend_12by24 = np.zeros([12,24], int)
            self.d_wkday_12by24 = np.zeros([12,24], int)
            self.d_wkend_12by24 = np.zeros([12,24], int)
            
            
            ################### Blank 12x24s as 8760s Schedule ########################
            self.d_tou_8760 = np.zeros(8760, int)
            self.e_tou_8760 = np.zeros(8760, int)
            
            
            ######################## Precalculations ######################################
            self.e_prices_no_tier = np.zeros([1, 1])
            self.e_max_difference = np.zeros([1, 1])

        
        #######################################################################
        # If given a urdb_id input argument, obtain and reshape that tariff through the URDB API 
        #######################################################################
        elif urdb_id != None:
            input_params = {'version':3,
                        'format':'json',
                        'detail':'full',
                        'getpage':urdb_id, # not real: 57d0b2315457a3120ec5b286 real: 57bcd2b65457a3a67e540154
                        'api_key':'bg51RuoT2OD733xqu0ehRRZWUzBGvOJuN5xyRtB4'}
        
            r = req.get('http://api.openei.org/utility_rates?', params=input_params)
            
            tariff_original = r.json()['items'][0]

            if 'demandrateunit' in tariff_original: self.demand_rate_unit = tariff_original['demandrateunit']
            else: self.demand_rate_unit = 'kW'  
              
            if 'eiaid' in tariff_original: self.eia_id = tariff_original['eiaid']
            else: self.eia_id = 'No eia id given'                 
                
            if 'label' in tariff_original: self.urdb_id = tariff_original['label']
            else: self.urdb_id = 'No urdb id given'            
            
            if 'name' in tariff_original: self.name = tariff_original['name']
            else: self.name = 'No name specified'
                
            if 'utility' in tariff_original: self.utility = tariff_original['utility']
            else: self.utility = 'No utility specified'
                
            if 'fixedmonthlycharge' in tariff_original: self.fixed_charge = tariff_original['fixedmonthlycharge']
            else: self.fixed_charge = 0
                
            if 'peakkwcapacitymax' in tariff_original: self.peak_kW_capacity_max = tariff_original['peakkwcapacitymax']
            else: self.peak_kW_capacity_max = 1e99
                
            if 'peakkwcapacitymin' in tariff_original: self.peak_kW_capacity_min = tariff_original['peakkwcapacitymin']
            else: self.peak_kW_capacity_min = 0
                
            if 'peakkwhusagemax' in tariff_original: self.kWh_useage_max = tariff_original['peakkwhusagemax']
            else: self.kWh_useage_max = 1e99
                
            if 'peakkwhusagemin' in tariff_original: self.kWh_useage_min = tariff_original['peakkwhusagemin']
            else: self.kWh_useage_min = 0
                
            if 'sector' in tariff_original: self.sector = tariff_original['sector']
            else: self.sector = 'No sector given'
                
            if 'basicinformationcomments' in tariff_original: self.comments = tariff_original['basicinformationcomments']
            else: self.comments = 'No comments'

            if 'description' in tariff_original: self.description = tariff_original['description']
            else: self.description = 'No description'
                
            if 'source' in tariff_original: self.source = tariff_original['source']
            else: self.source = 'No source given'

            if 'uri' in tariff_original: self.uri = tariff_original['uri']
            else: self.uri = 'No uri given'
                
            if 'voltage_category' in tariff_original: self.voltage_category = tariff_original['voltage_category']
            else: self.voltage_category = 'No voltage category given'
                 
            if 'approved' in tariff_original: self.approved = tariff_original['approved']
            else: self.approved = 'No approved item given'
            
            if 'startdate' in tariff_original: self.startdate = tariff_original['startdate']
            else: self.startdate = 'No start date given'
            
            if 'enddate' in tariff_original: self.enddate = tariff_original['enddate']
            else: self.enddate = 'No end date given'
            
            if 'supercedes' in tariff_original: self.supercedes = tariff_original['supercedes']
            else: self.supercedes = 'No supercedes item given'
            
            if 'sourceparent' in tariff_original: self.sourceparent = tariff_original['sourceparent']
            else: self.sourceparent = 'No parent source given'
            
            if 'minmonthlycharge' in tariff_original: self.minmonthlycharge = tariff_original['minmonthlycharge']
            else: self.minmonthlycharge = 'No minimum monthly charge given'
            
            if 'annualmincharge' in tariff_original: self.annualmincharge = tariff_original['annualmincharge']
            else: self.annualmincharge = 'No annual minimum charge given'
            
            if 'voltageminimum' in tariff_original: self.voltageminimum = tariff_original['voltageminimum']
            else: self.voltageminimum = 'No voltage minimum given'
            
            if 'voltagemaximum' in tariff_original: self.voltagemaximum = tariff_original['voltagemaximum']
            else: self.voltagemaximum = 'No voltage maximum given'
            
            if 'phasewiring' in tariff_original: self.phasewiring = tariff_original['phasewiring']
            else: self.phasewiring = 'No phase wiring information given'
            
            if 'demandwindow' in tariff_original: self.demandwindow = tariff_original['demandwindow']
            else: self.demandwindow = 'No demand window given'
            
            if 'demandattrs' in tariff_original: self.demandattrs = tariff_original['demandattrs']
            else: self.demandattrs = 'No additional demand attributes given'
            
            if 'energycomments' in tariff_original: self.energycomments = tariff_original['energycomments']
            else: self.energycomments = 'No additional energy comments given'
            
            if 'revisions' in tariff_original: self.revisions = tariff_original['revisions']
            else: self.revisions = 'No revision information given'
            
            
            
            
            
            ###################### Repackage Flat Demand Structure ########################
            if 'flatdemandstructure' in tariff_original:
                self.d_flat_exists = True
                d_flat_structure = tariff_original['flatdemandstructure']
                d_flat_month_indicies = tariff_original['flatdemandmonths']
                self.d_flat_n = len(np.unique(tariff_original['flatdemandmonths']))
                
                # Determine the maximum number of tiers in the demand structure
                max_tiers = 1
                for period in range(self.d_flat_n):
                    n_tiers = len(d_flat_structure[period])
                    if n_tiers > max_tiers: max_tiers = n_tiers
                
                # Repackage Energy TOU Structure   
                self.d_flat_prices = np.zeros([max_tiers, 12])     
                self.d_flat_levels = np.zeros([max_tiers, 12])
                self.d_flat_levels[:,:] = 1e9
                for month in range(12):
                    for tier in range(len(d_flat_structure[period])):
                        self.d_flat_levels[tier, month] = d_flat_structure[d_flat_month_indicies[month]][tier].get('max', 1e9)
                        self.d_flat_prices[tier, month] = d_flat_structure[d_flat_month_indicies[month]][tier].get('rate', 0) + d_flat_structure[d_flat_month_indicies[month]][tier].get('adj', 0)
            else:
                self.d_flat_exists = False
                self.d_flat_n = 1
                self.d_flat_prices = np.zeros([1, 12])     
                self.d_flat_levels = np.zeros([1, 12])
                self.d_flat_levels[:,:] = 1e9
            
            #################### Repackage Demand TOU Structure ###########################
            if 'demandratestructure' in tariff_original:
                demand_structure = tariff_original['demandratestructure']
                self.d_tou_n = len(demand_structure)
                if self.d_tou_n > 1: self.d_tou_exists = True
                else: 
                    self.d_tou_exists = False
                    self.d_flat_exists = True
                
                # Determine the maximum number of tiers in the demand structure
                max_tiers = 1
                for period in range(self.d_tou_n):
                    n_tiers = len(demand_structure[period])
                    if n_tiers > max_tiers: max_tiers = n_tiers
                
                # Repackage Demand TOU Structure   
                self.d_tou_prices = np.zeros([max_tiers, self.d_tou_n])     
                self.d_tou_levels = np.zeros([max_tiers, self.d_tou_n])
                self.d_tou_levels[:,:] = 1e9
                for period in range(self.d_tou_n):
                    for tier in range(len(demand_structure[period])):
                        self.d_tou_levels[tier, period] = demand_structure[period][tier].get('max', 1e9)
                        self.d_tou_prices[tier, period] = demand_structure[period][tier].get('rate', 0) + demand_structure[period][tier].get('adj', 0)
            else:
                self.d_tou_exists = False
                self.d_tou_n = 1
                self.d_tou_prices = np.zeros([1, 1])     
                self.d_tou_levels = np.zeros([1, 1])
            
            ######################## No Coincident Peak from URDB #############
            self.coincident_peak_exists = False
            
            
            ######################## Repackage Energy Structure ###########################
            if 'energyratestructure' in tariff_original:
                self.e_exists = True
                energy_structure = tariff_original['energyratestructure']
                self.energy_rate_unit = energy_structure[0][0].get('unit','kWh')
                self.e_n = len(energy_structure)
                if self.e_n > 1: self.e_tou_exists = True
                else: self.e_tou_exists = False
                
                # Determine the maximum number of tiers in the demand structure
                max_tiers = 1
                for period in range(self.e_n):
                    n_tiers = len(energy_structure[period])
                    if n_tiers > max_tiers: max_tiers = n_tiers
                
                # Repackage Energy TOU Structure   
                self.e_prices = np.zeros([max_tiers, self.e_n])     
                self.e_levels = np.zeros([max_tiers, self.e_n])
                self.e_levels[:,:] = 1e9
                for period in range(self.e_n):
                    for tier in range(len(energy_structure[period])):
                        self.e_levels[tier, period] = energy_structure[period][tier].get('max', 1e9)
                        self.e_prices[tier, period] = energy_structure[period][tier].get('rate', 0) + energy_structure[period][tier].get('adj', 0)
            else:
                self.e_exists = False
                self.e_tou_exists = False
                self.e_n = 0
                self.e_prices = np.zeros([1, 1])     
                self.e_levels = np.zeros([1, 1])
                self.energy_rate_unit = 'kWh'
                
            ######################## Repackage Energy Schedule ###########################
            self.e_wkday_12by24 = np.zeros([12,24], int)
            self.e_wkend_12by24 = np.zeros([12,24], int)
            
            if 'energyweekdayschedule' in tariff_original:
                for month in range(12):
                    self.e_wkday_12by24[month, :] = tariff_original['energyweekdayschedule'][month]
                    self.e_wkend_12by24[month, :] = tariff_original['energyweekendschedule'][month]
            
            ######################## Repackage Demand Schedule ###########################
            self.d_wkday_12by24 = np.zeros([12,24], int)
            self.d_wkend_12by24 = np.zeros([12,24], int)
            
            if 'demandweekdayschedule' in tariff_original:
                for month in range(12):
                    self.d_wkday_12by24[month, :] = tariff_original['demandweekdayschedule'][month]
                    self.d_wkend_12by24[month, :] = tariff_original['demandweekendschedule'][month]
            
            ################### Repackage 12x24s as 8760s Schedule ########################
            self.start_day = start_day            
            month_hours = np.array([0, 744, 1416, 2160, 2880, 3624, 4344, 5088, 5832, 6552, 7296, 8016, 8760], int)
            
            month_index = np.zeros(8760, int)
            for month, hours in enumerate(month_hours):
                month_index[month_hours[month-1]:hours] = month-1

            self.d_tou_8760 = np.zeros(8760, int)
            self.e_tou_8760 = np.zeros(8760, int)
            hour = 0
            day = start_day # Start on 6 because the load profiles we are using start on a Sunday
            for h in range(8760):
                if day < 5:
                    self.d_tou_8760[h] = self.d_wkday_12by24[month_index[h], hour]
                    self.e_tou_8760[h] = self.e_wkday_12by24[month_index[h], hour]
                else:
                    self.d_tou_8760[h] = self.d_wkend_12by24[month_index[h], hour]
                    self.e_tou_8760[h] = self.e_wkend_12by24[month_index[h], hour]
                hour += 1
                if hour == 24: hour = 0; day += 1
                if day == 7: day = 0
            
            ######################## Precalculations ######################################
            # Collapse the tiered price matrix down to just the maximum cost
            # in each tier, to be used during dispatch.
            self.e_prices_no_tier = np.max(self.e_prices, 0)
            
            # Determine the maximum differential in energy price within a day.
            try:
                e_12by24_max_prices_wkday = self.e_prices_no_tier[self.e_wkday_12by24]
                e_12by24_max_prices_wkend = self.e_prices_no_tier[self.e_wkend_12by24]
                e_max_price_differential_wkday = np.max(e_12by24_max_prices_wkday, 1) - np.min(e_12by24_max_prices_wkday, 1)
                e_max_price_differential_wkend = np.max(e_12by24_max_prices_wkend, 1) - np.min(e_12by24_max_prices_wkend, 1)
                self.e_max_difference = np.max([e_max_price_differential_wkday, e_max_price_differential_wkend])
            except:
                print('Warning: e_max_difference not calculated')
        
        #######################################################################
        # If given a json input argument, construct a tariff from that file
        #######################################################################    
        elif json_file_name != None:
            
            obj_text = codecs.open(json_file_name, 'r', encoding='utf-8').read()
            d = json.loads(obj_text)
            for fieldname in d.keys():
                if isinstance(d[fieldname], list):
                    d[fieldname] = np.array(d[fieldname])
                
            if 'urdb_id' in d: self.urdb_id = d['urdb_id']
            if 'name' in d: self.name = d['name']
            if 'utility' in d: self.utility = d['utility']
            if 'fixed_charge' in d: self.fixed_charge = d['fixed_charge']
            if 'peak_kW_capacity_max' in d: self.peak_kW_capacity_max = d['peak_kW_capacity_max']
            if 'peak_kW_capacity_min' in d: self.peak_kW_capacity_min = d['peak_kW_capacity_min']
            if 'kWh_useage_max' in d: self.kWh_useage_max = d['kWh_useage_max']
            if 'kWh_useage_min' in d: self.kWh_useage_min = d['kWh_useage_min']
            if 'sector' in d: self.sector = d['sector']
            if 'comments' in d: self.comments = d['comments']
            if 'description' in d: self.description = d['description']
            if 'source' in d: self.source = d['source']
            if 'uri' in d: self.uri = d['uri']
            if 'source' in d: self.source = d['source']
            if 'voltage_category' in d: self.voltage_category = d['voltage_category']
            if 'eia_id' in d: self.eia_id = d['eia_id']
            if 'energy_rate_unit' in d: self.energy_rate_unit = d['energy_rate_unit']
            if 'approved' in d: self.approved = d['approved']
            if 'startdate' in d: 
                try:
                    self.startdate = datetime.datetime.fromtimestamp(d['startdate']+60*60*2).strftime('%m/%d/%Y')
                except:
                    self.startdate = d['startdate']
            if 'enddate' in d: 
                try:
                    self.enddate = datetime.datetime.fromtimestamp(d['enddate']+60*60*2).strftime('%m/%d/%Y')
                except:
                    self.enddate = d['enddate']
            if 'supercedes' in d: self.supercedes = d['supercedes']
            if 'sourceparent' in d: self.sourceparent = d['sourceparent']
            if 'minmonthlycharge' in d: self.minmonthlycharge = d['minmonthlycharge']
            if 'annualmincharge' in d: self.annualmincharge = d['annualmincharge']
            if 'voltageminimum' in d: self.voltageminimum = d['voltageminimum']
            if 'voltagemaximum' in d: self.voltagemaximum = d['voltagemaximum']
            if 'phasewiring' in d: self.phasewiring = d['phasewiring']
            if 'demandwindow' in d: self.demandwindow = d['demandwindow']
            if 'demandattrs' in d: self.demandattrs = d['demandattrs']
            if 'energycomments' in d: self.energycomments = d['energycomments']
            if 'revisions' in d: 
                revisions_date = list()
                try:
                    revisions_values = d['revisions']
                    for i0 in range(len(revisions_values)):                        
                        revisions_date.insert(i0,datetime.datetime.fromtimestamp(revisions_values[i0]+60*60*1).strftime('%m/%d/%Y %H:%M:%S'))
                    self.revisions = revisions_date
                except:
                    self.revisions = d['revisions']

            ###################### Blank Flat Demand Structure ########################
            if 'd_flat_exists' in d: self.d_flat_exists = d['d_flat_exists']
            if 'd_flat_prices' in d: self.d_flat_prices = d['d_flat_prices']
            if 'd_flat_levels' in d: self.d_flat_levels = d['d_flat_levels']
            if 'd_flat_n' in d: self.d_flat_n = d['d_flat_n']
                
            
            #################### Blank Demand TOU Structure ###########################
            if 'd_tou_exists' in d: self.d_tou_exists = d['d_tou_exists']
            if 'd_tou_n' in d: self.d_tou_n = d['d_tou_n']
            if 'd_tou_prices' in d: self.d_tou_prices = d['d_tou_prices']
            if 'd_tou_levels' in d: self.d_tou_levels = d['d_tou_levels']

            
            #################### Coincident Peak Structure ###########################            
            if 'coincident_peak_exists' in d: self.coincident_peak_exists = d['coincident_peak_exists']
            else: self.coincident_peak_exists = False
            
            if 'coincident_style' in d: self.coincident_style = d['coincident_style']
            if 'coincident_hour_def' in d: self.coincident_hour_def = d['coincident_hour_def']
            if 'coincident_prices' in d: self.coincident_prices = d['coincident_prices']
            if 'coincident_levels' in d: self.coincident_levels = d['coincident_levels']
            if 'coincident_monthly_periods' in d: self.coincident_monthly_periods = d['coincident_monthly_periods']
            
            
            ######################## Blank Energy Structure ###########################
            if 'e_exists' in d: self.e_exists = d['e_exists']
            if 'e_tou_exists' in d: self.e_tou_exists = d['e_tou_exists']
            if 'e_n' in d: self.e_n = d['e_n']
            if 'e_prices' in d: self.e_prices = d['e_prices']
            if 'e_levels' in d: self.e_levels = d['e_levels']
            
                
            ######################## Blank Schedules ###########################
            if 'e_wkday_12by24' in d: self.e_wkday_12by24 = d['e_wkday_12by24']
            if 'e_wkend_12by24' in d: self.e_wkend_12by24 = d['e_wkend_12by24']
            if 'd_wkday_12by24' in d: self.d_wkday_12by24 = d['d_wkday_12by24']
            if 'd_wkend_12by24' in d: self.d_wkend_12by24 = d['d_wkend_12by24']
            
            
            ################### Blank 12x24s as 8760s Schedule ########################
            if 'd_tou_8760' in d: self.d_tou_8760 = d['d_tou_8760']
            if 'e_tou_8760' in d: self.e_tou_8760 = d['e_tou_8760']
            
            
            ######################## Precalculations ######################################
            if 'e_prices_no_tier' in d: self.e_prices_no_tier = d['e_prices_no_tier']
            if 'e_max_difference' in d: self.e_max_difference = d['e_max_difference']
            if 'start_day' in d: self.start_day = d['start_day']

            
        #######################################################################
        # If given a dict input, construct a tariff from that object
        #######################################################################    
        elif dict_obj != None:
            if 'urdb_id' in dict_obj: self.urdb_id = dict_obj['urdb_id']
            if 'name' in dict_obj: self.name = dict_obj['name']
            if 'utility' in dict_obj: self.utility = dict_obj['utility']
            if 'sector' in dict_obj: self.sector = dict_obj['sector']
            if 'comments' in dict_obj: self.comments = dict_obj['comments']
            if 'description' in dict_obj: self.description = dict_obj['description']
            if 'source' in dict_obj: self.source = dict_obj['source']
            if 'uri' in dict_obj: self.uri = dict_obj['uri']
            if 'voltage_category' in dict_obj: self.voltage_category = dict_obj['voltage_category']
            if 'approved' in dict_obj: self.approved = dict_obj['approved']
            if 'startdate' in dict_obj: self.startdate = dict_obj['startdate']
            if 'enddate' in dict_obj: self.enddate = dict_obj['enddate']
            if 'supercedes' in dict_obj: self.supercedes = dict_obj['supercedes']
            if 'sourceparent' in dict_obj: self.sourceparent = dict_obj['sourceparent']
            if 'minmonthlycharge' in dict_obj: self.minmonthlycharge = dict_obj['minmonthlycharge']
            if 'annualmincharge' in dict_obj: self.annualmincharge = dict_obj['annualmincharge']
            if 'voltageminimum' in dict_obj: self.voltageminimum = dict_obj['voltageminimum']
            if 'voltagemaximum' in dict_obj: self.voltagemaximum = dict_obj['voltagemaximum']
            if 'phasewiring' in dict_obj: self.phasewiring = dict_obj['phasewiring']
            if 'demandwindow' in dict_obj: self.demandwindow = dict_obj['demandwindow']
            if 'demandattrs' in dict_obj: self.demandattrs = dict_obj['demandattrs']
            if 'energycomments' in dict_obj: self.energycomments = dict_obj['energycomments']
            if 'revisions' in dict_obj: self.revisions = dict_obj['revisions']
           
            self.fixed_charge = dict_obj['fixed_charge']
            self.peak_kW_capacity_max = dict_obj['peak_kW_capacity_max']
            self.peak_kW_capacity_min = dict_obj['peak_kW_capacity_min']
            self.kWh_useage_max = dict_obj['kWh_useage_max']
            self.kWh_useage_min = dict_obj['kWh_useage_min']
            self.eia_id = dict_obj['eia_id']
            if 'demand_rate_unit' in dict_obj: self.demand_rate_unit = dict_obj['demand_rate_unit']
            if 'energy_rate_unit' in dict_obj: self.energy_rate_unit = dict_obj['energy_rate_unit']
            
            
            ###################### Flat Demand Structure ########################
            self.d_flat_exists = dict_obj['d_flat_exists']
            self.d_flat_prices = np.array(dict_obj['d_flat_prices'])
            self.d_flat_levels = np.array(dict_obj['d_flat_levels'])
            self.d_flat_n = dict_obj['d_flat_n']
            
            #################### Demand TOU Structure ###########################
            self.d_tou_exists = dict_obj['d_tou_exists']
            self.d_tou_n = dict_obj['d_tou_n']
            self.d_tou_prices = np.array(dict_obj['d_tou_prices'])    
            self.d_tou_levels = np.array(dict_obj['d_tou_levels'])
            
            #################### Coincident Peak Structure ###########################            
            if 'coincident_peak_exists' in dict_obj: self.coincident_peak_exists = dict_obj['coincident_peak_exists']
            else: self.coincident_peak_exists = False
            
            if 'coincident_style' in dict_obj: self.coincident_style = dict_obj['coincident_style']
            if 'coincident_hour_def' in dict_obj: self.coincident_hour_def = dict_obj['coincident_hour_def']
            if 'coincident_prices' in dict_obj: self.coincident_prices = dict_obj['coincident_prices']
            if 'coincident_levels' in dict_obj: self.coincident_levels = dict_obj['coincident_levels']
            if 'coincident_monthly_periods' in dict_obj: self.coincident_monthly_periods = dict_obj['coincident_monthly_periods']
            
            
            ######################## Energy Structure ###########################
            self.e_exists = dict_obj['e_exists']
            self.e_tou_exists = dict_obj['e_tou_exists']
            self.e_n = dict_obj['e_n']
            self.e_prices = np.array(dict_obj['e_prices'])   
            self.e_levels = np.array(dict_obj['e_levels'])
            
                
            ######################## Schedules ###########################
            self.e_wkday_12by24 = np.array(dict_obj['e_wkday_12by24'])
            self.e_wkend_12by24 = np.array(dict_obj['e_wkend_12by24'])
            self.d_wkday_12by24 = np.array(dict_obj['d_wkday_12by24'])
            self.d_wkend_12by24 = np.array(dict_obj['d_wkend_12by24'])
            
            
            ################### 12x24s as 8760s Schedule ########################
            self.d_tou_8760 = np.array(dict_obj['d_tou_8760'])
            self.e_tou_8760 = np.array(dict_obj['e_tou_8760'])
            
            
            ######################## Precalculations ######################################
            self.e_prices_no_tier = np.array(dict_obj['e_prices_no_tier']) # simplification until something better is implemented
            self.e_max_difference = dict_obj['e_max_difference']
            if 'start_day' in dict_obj: self.start_day = dict_obj['start_day']
            else: self.start_day = 6
            
    
    #######################################################################
    # Write the current class object to a json file
    #######################################################################     
    def write_json(self, json_file_name):
        
        d = self.__dict__
                
        d_prep_for_json = d.copy()
        
        # change ndarray dtypes to lists, since json doesn't know ndarrays
        for fieldname in d_prep_for_json.keys():
            if isinstance(d_prep_for_json[fieldname], np.ndarray):
                d_prep_for_json[fieldname] = d_prep_for_json[fieldname].tolist()
        
        with open(json_file_name, 'w') as fp:
            json.dump(d_prep_for_json, fp)
            
                 
#%%     
class Export_Tariff:
    """
    Structure of compensation for exported generation. Currently only two 
    styles: full-retail NEM, and instantanous TOU energy value. 
    """
    
    def __init__(self, full_retail_nem=True, 
                 prices = np.zeros([1, 1], float),
                 levels = np.zeros([1, 1], float),
                 periods_8760 = np.zeros(8760, int),
                 period_tou_n = 1):
     
        self.full_retail_nem = full_retail_nem
        self.prices = prices     
        self.levels = levels
        self.periods_8760 = periods_8760
        self.period_tou_n = period_tou_n
        
    def set_constant_sell_price(self, price):
        self.full_retail_nem = False
        self.prices = np.array([[price]], float)
        self.levels = np.array([[9999999]], float)
        self.periods_8760 = np.zeros(8760, int)
        self.period_tou_n = 1

#%%
def tiered_calc_vec(values, levels, prices):
    # Vectorized piecewise function calculator
    values = np.asarray(values)
    levels = np.asarray(levels)
    prices = np.asarray(prices)
    y = np.zeros(values.shape)
    
    # Tier 1
    y += ((values >= 0) & (values < levels[:][:][0])) * (values*prices[:][:][0])

    # Tiers 2 and beyond    
    for tier in np.arange(1,np.size(levels,0)):
        y += ((values >= levels[:][:][tier-1]) & (values < levels[:][:][tier])) * (
            ((values-levels[:][:][tier-1])*prices[:][:][tier]) + levels[:][:][tier-1]*prices[:][:][tier-1])  
    
    return y

#%%

def bill_calculator(load_profile, tariff, export_tariff):
    """
    Not vectorized for now. Next step will be pass in multiple profiles for the same tariff
    2 styles of NEM: Full retail and fixed schedule value. 

    To-do
    -Both energy and demand calcs (anything that uses piecewise calculator) doesn't go below zero, because piecewise isn't built to.
        Therefore, credit can't be earned in one period and applied to another. 
    -My current approach sums for all periods, not just those in a month. Potentially inefficient, if it was dynamic it would be cheaper, but less clear.
    -Make this flexible for different hours increments (which will require more robust approach for power vs energy units)
    -Not sure what happens if there is no energy component in the tariff, at the moment    
    -I haven't checked the TOU export credit option yet.
    -I don't make any type of check about what day of the week this calculator assumes your load profile is starting on
    -e_period_charges wasn't being built for non-NEM
    """
    
    n_months = 12
    n_timesteps = 8760

    if len(tariff.d_tou_8760) != 8760: 
        print ('Warning: Non-8760 profiles are not yet supported by the bill calculator')
    
    # 8760 vector of month numbers
    month_hours = np.array([0, 744, 1416, 2160, 2880, 3624, 4344, 5088, 5832, 6552, 7296, 8016, 8760], int)
    month_index = np.zeros(8760, int)
    for month, hours in enumerate(month_hours):
        month_index[month_hours[month-1]:hours] = month-1
        
    
    #=========================================================================#
    ################## Calculate TOU Demand Charges ###########################
    #=========================================================================#
    if tariff.d_tou_exists == True:
        # Cast the TOU periods into a boolean matrix
        period_matrix = np.zeros([n_timesteps, tariff.d_tou_n*n_months], bool)
        period_matrix[range(n_timesteps),tariff.d_tou_8760+month_index*tariff.d_tou_n] = True
        
        # Determine the max demand in each period of each month of each year
        load_distributed = load_profile[np.newaxis, :].T*period_matrix
        period_maxs = np.max(load_distributed, axis=0)
        
        # Calculate the cost of TOU demand charges
        d_TOU_period_charges = tiered_calc_vec(period_maxs, np.tile(tariff.d_tou_levels[:,0:tariff.d_tou_n], 12), np.tile(tariff.d_tou_prices[:,0:tariff.d_tou_n], 12))
       
        d_TOU_month_total_charges = np.zeros([n_months])
        for month in range(n_months):
            d_TOU_month_total_charges[month] = np.sum(d_TOU_period_charges[(month*tariff.d_tou_n):(month*tariff.d_tou_n + tariff.d_tou_n)])
    else:
        d_TOU_month_total_charges = np.zeros([n_months])
        period_maxs = np.zeros(0)
        
    #=========================================================================#
    ################# Calculate Flat Demand Charges ###########################
    #=========================================================================#
    if tariff.d_flat_exists == True:
        # Cast the seasons into a boolean matrix
        flat_matrix = np.zeros([n_timesteps, n_months], bool)
        flat_matrix[range(n_timesteps),month_index] = True
        
        # Determine the max demand in each month of each year
        load_distributed = load_profile[np.newaxis, :].T*flat_matrix
        flat_maxs = np.max(load_distributed, axis=0)
        
        flat_charges = tiered_calc_vec(flat_maxs, tariff.d_flat_levels, tariff.d_flat_prices)  
    else:
        flat_charges = np.zeros([n_months])
        flat_maxs = np.zeros(0)
        
    #=========================================================================#
    ############# Calculate Coincident Peak Demand Charges ####################
    #=========================================================================#
    if tariff.coincident_peak_exists == True:
        if tariff.coincident_style == 0:
            # Input is a n by m array. Each row is a peak period and each set
            # of columns are the hours that define that period. For example,
            # [[100,200],[5100,5200]] would have two periods that are defined
            # by the average demand of hours [100,200] and [5100,5200]
            # respectively.
            # Coincident_monthly_periods is a 12-length array that maps the 
            # charges to the billing periods.
            coincident_demand_levels = np.average(load_profile[tariff.coincident_hour_def], 1)
            coincident_charges = tiered_calc_vec(coincident_demand_levels, tariff.coincident_levels, tariff.coincident_prices)
            coincident_monthly_charges = coincident_charges[tariff.coincident_monthly_periods]
    else:
        coincident_monthly_charges = np.zeros(12)
        coincident_demand_levels = None
    
    #=========================================================================#
    #################### Calculate Energy Charges #############################
    #=========================================================================#
    # Calculate energy charges without full retail NEM
    if tariff.e_exists and tariff.e_n!=0:
        if export_tariff.full_retail_nem == False:
            imported_profile = np.clip(load_profile, 0, 1e99)
            exported_profile = np.clip(load_profile, -1e99, 0)
    
            # Calculate fixed schedule export_tariff 
            # Cast the TOU periods into a boolean matrix
            e_period_export_matrix = np.zeros([len(export_tariff.periods_8760), export_tariff.period_tou_n*n_months], bool)
            e_period_export_matrix[range(len(export_tariff.periods_8760)),export_tariff.periods_8760+month_index*export_tariff.period_tou_n] = True
            
            # Determine the energy consumed in each period of each month of each year
            load_distributed = exported_profile[np.newaxis, :].T*e_period_export_matrix
            export_period_sums = np.sum(load_distributed, axis=0)
            
            # Calculate the cost of TOU demand charges
            export_period_credits = tiered_calc_vec(export_period_sums, np.tile(export_tariff.levels[:,0:export_tariff.period_tou_n], 12), np.tile(export_tariff.prices[:,0:export_tariff.period_tou_n], 12))
            
            export_month_total_credits = np.zeros([n_months])
            for month in range(n_months):
                export_month_total_credits[month] = np.sum(export_period_credits[(month*export_tariff.period_tou_n):(month*export_tariff.period_tou_n + export_tariff.period_tou_n)])        
                
            # Calculate imported energy charges. 
            # Cast the TOU periods into a boolean matrix
            e_period_import_matrix = np.zeros([len(tariff.e_tou_8760), tariff.e_n*n_months], bool)
            e_period_import_matrix[range(len(tariff.e_tou_8760)),tariff.e_tou_8760+month_index*tariff.e_n] = True
            
            # Determine the max demand in each period of each month of each year
            load_distributed = imported_profile[np.newaxis, :].T*e_period_import_matrix
            e_period_import_sums = np.sum(load_distributed, axis=0)
            
            # Calculate the cost of TOU demand charges
            e_period_import_charges = tiered_calc_vec(e_period_import_sums, np.tile(tariff.e_levels, 12), np.tile(tariff.e_prices, 12))
            
            e_month_import_total_charges = np.zeros([n_months])
            for month in range(n_months):
                e_month_import_total_charges[month] = np.sum(e_period_import_charges[(month*tariff.e_n):(month*tariff.e_n + tariff.e_n)])
                
            e_month_total_net_charges = e_month_import_total_charges - export_month_total_credits
    
            # placeholder        
            e_period_charges = "placeholder"
            e_period_sums = "placeholder"
         
        # Calculate energy charges with full retail NEM 
        else:
            # Calculate imported energy charges with full retail NEM
            # Cast the TOU periods into a boolean matrix
            e_period_matrix = np.zeros([len(tariff.e_tou_8760), tariff.e_n*n_months], bool)
            e_period_matrix[range(len(tariff.e_tou_8760)),tariff.e_tou_8760+month_index*tariff.e_n] = True
            
            # Determine the energy consumed in each period of each month of each year netting exported electricity
            load_distributed = load_profile[np.newaxis, :].T*e_period_matrix
            e_period_sums = np.sum(load_distributed, axis=0)
            
            # Calculate the cost of TOU energy charges netting exported electricity
            e_period_charges = tiered_calc_vec(e_period_sums, np.tile(tariff.e_levels, 12), np.tile(tariff.e_prices, 12))
            
            e_month_total_net_charges = np.zeros([n_months])
            for month in range(n_months):
                e_month_total_net_charges[month] = np.sum(e_period_charges[(month*tariff.e_n):(month*tariff.e_n + tariff.e_n)])
            
            # Determine the value of NEM
            # Calculate imported energy charges with zero exported electricity
            imported_profile = np.clip(load_profile, 0, 1e99)
    
            # Determine the energy consumed in each period of each month of each year - without exported electricity
            imported_load_distributed = imported_profile[np.newaxis, :].T*e_period_matrix
            e_period_sums_imported = np.sum(imported_load_distributed, axis=0)
            
            # Calculate the cost of TOU energy charges without exported electricity
            e_period_imported_charges = tiered_calc_vec(e_period_sums_imported, np.tile(tariff.e_levels, 12), np.tile(tariff.e_prices, 12))
            
            e_month_total_import_charges = np.zeros([n_months])
            for month in range(n_months):
                e_month_total_import_charges[month] = np.sum(e_period_imported_charges[(month*tariff.e_n):(month*tariff.e_n + tariff.e_n)])
            
            # Determine how much  the exported electricity was worth by comparing
            # bills where it was netted against those where it wasn't
            export_month_total_credits = e_month_total_net_charges - e_month_total_import_charges
            
            e_period_import_sums = 'placeholder'
    else:
        e_month_total_net_charges = np.zeros(12)
        export_month_total_credits = np.zeros(12)
        e_period_charges = np.zeros(12*tariff.e_n)
        e_period_sums = np.zeros(12*tariff.e_n)
        e_period_import_sums = np.zeros(12*tariff.e_n)
        
    total_monthly_bills = d_TOU_month_total_charges + flat_charges + coincident_monthly_charges + e_month_total_net_charges + tariff.fixed_charge
    annual_bill = sum(total_monthly_bills)
        
    results_dict = {'annual_bill':annual_bill,
                    'd_charges':np.sum(d_TOU_month_total_charges + flat_charges),
                    'e_charges':np.sum(e_month_total_net_charges),
                    'monthly_total_bills':total_monthly_bills,
                    'monthly_d_charges':d_TOU_month_total_charges + flat_charges,
                    'monthly_d_tou_charges':d_TOU_month_total_charges,
                    'monthly_d_flat_charges':flat_charges,
                    'monthly_e_total_net_charges':e_month_total_net_charges,
                    'monthly_e_total_import_charges':e_month_total_net_charges-export_month_total_credits,
                    'monthly_e_total_export_credits':export_month_total_credits,
                    'period_kW_maxs':period_maxs,
                    'monthly_kW_maxs':flat_maxs,
                    'period_e_charges':e_period_charges,
                    'period_e_sums':e_period_sums,
                    'e_period_import_sums':e_period_import_sums,
                    'coincident_monthly_charges':coincident_monthly_charges,
                    'coincident_demand_levels':coincident_demand_levels
                    }
    
    return annual_bill, results_dict

    

