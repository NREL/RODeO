# -*- coding: utf-8 -*-
"""
Created on Fri Dec 02 10:28:58 2016

@author: pgagnon
"""

support_repo_path = 'C:/Users/jeichman/Documents/Tariff_analysis/support_functions/python'
Analysis_path = 'C:/Users/jeichman/Documents/Tariff_analysis'
Output_files = Analysis_path + '/Output'
Input_files = Analysis_path + '/Input'


import numpy as np
import pandas as pd
import sys
import csv
sys.path.append(support_repo_path)
import tariff_functions as tFuncs
import time
from pathlib import Path

# Import a reference load profile
load_profile = np.genfromtxt(Input_files + '/ref_profile.csv')

# Load all tariff ids
#load_ids = np.loadtxt('C:/Users/jeichman/Documents/Tariff_analysis/support_functions/python/Tariffs_com_ind_20161202_ids.csv', dtype=str, delimiter=",")
load_ids = np.genfromtxt(Input_files + '/Tariffs_com_ind_20161202_ids.csv', dtype=str, delimiter=",")

load_ids_size = load_ids.shape

n_months = 12
n_timesteps = 8760

id_length = load_ids_size[0]
e_tou_8760_write = np.zeros([n_timesteps,id_length],dtype=np.int)
e_tou_8760_write = np.concatenate((np.arange(0,id_length,1)[:, None].transpose()+1,e_tou_8760_write),axis=0)
e_prices_write = np.zeros([20,id_length])
e_prices_write = np.concatenate((np.arange(0,id_length,1)[:, None].transpose()+1,e_prices_write),axis=0)
d_tou_8760_write = np.zeros([n_timesteps,id_length],dtype=np.int)
d_tou_8760_write = np.concatenate((np.arange(0,id_length,1)[:, None].transpose()+1,d_tou_8760_write),axis=0)
d_flat_prices_write = np.zeros([n_months,id_length])
d_flat_prices_write = np.concatenate((np.arange(0,id_length,1)[:, None].transpose()+1,d_flat_prices_write),axis=0)
d_tou_prices_write = np.zeros([20,id_length])
d_tou_prices_write = np.concatenate((np.arange(0,id_length,1)[:, None].transpose()+1,d_tou_prices_write),axis=0)
fixed_charge_write = np.zeros([1,id_length])
fixed_charge_write = np.concatenate((np.arange(0,id_length,1)[:, None].transpose()+1,fixed_charge_write),axis=0)
property_list = list()
for t_id in range(id_length):        #range(0,300,1):    #e_max_diff error with 243, 635, 703, 828, 1684, 2772    ?2268, 3803
    # Designate which tariff you want to import from the URDB   
    tariff_id = load_ids[t_id]
    #           http://en.openei.org/apps/USURDB/rate/view/539fb87aec4f024bc1dc1799
    
    # Create a class instance of the Tariff object
    # TODO: Please be sure to get your own API key and modify the Tariff class function
    json_file = (Output_files + '/json_files/%s.json' % tariff_id)
     
    # Check if the json filesize is >100bytes and if so use it, otherwise populate the json file then use it
    try:
        file1 = Path(json_file) 
        size1 = file1.stat().st_size 
    except:
        size1 = 101
        # If file is empty, this code will draw from the URDB and creates a JSON file
        try:
            tariff = tFuncs.Tariff(urdb_id = tariff_id, json_file_name = json_file)
            tariff = tFuncs.Tariff.write_json(tariff, json_file_name = json_file)        
        except: 
            print('Error loading tariff for ', t_id)
            continue
        print('Current Scenario: ', t_id)
        if (t_id % 20)== 0:
            time.sleep(4)
        else:
            time.sleep(0) 
            
    if (size1<=100):
        print('No JSON file available for scenario: ', t_id)
        try:
            tariff = tFuncs.Tariff(urdb_id = tariff_id, json_file_name = json_file)
            tariff = tFuncs.Tariff.write_json(tariff, json_file_name = json_file)        
        except: 
            print('Error loading tariff for ', t_id)
            continue       
        
    try:    
        tariff = tFuncs.Tariff(json_file_name = json_file)    
    except:
        tariff = tFuncs.Tariff(urdb_id = tariff_id, json_file_name = json_file)
        print('JSON file did not load correctly for scenario: ', t_id)          
        
    #tFuncs.Tariff.wrote_json(urdb_id = tariff_id, json_filename = json_file)    
    #write_json(tariff, json_file_name)
    
    # Change the class instance into a dictionary (just for easier viewing, here)
    tariff_dict = tariff.__dict__        
    
    # Create an Export_Tariff object that defines compensation for exported
    # electricity. Default is full retail net metering.
    export_tariff = tFuncs.Export_Tariff()        
 
    if t_id==0:       # Create header for tariff information
        property_list_header = ('Scenario','label','uri','eia_id','name','utility','sector','description','comments','voltage_category',
                                'size flat demand tier (kW)','max flat demand tier (kW)','min flat demand tier (kW)',
                                'size TOU demand tier (kW)','max TOU demand tier (kW)','min TOU demand tier (kW)',
                                'size energy rate tier (kW)','max energy rate tier (kW)','min energy rate tier (kW)',
                                'max energy usage (kWh)','min energy usage (kWh)',
                                'max peak capacity (kW)','min peak capacity (kW)',
                                'approved','start date','end date','supercedes','parent source','min monthly charge ($)','annual minimum charge ($)',
                                'minimum voltage','maximum voltage','phase wiring','demand window (min)','demand attributes','additional energy comments','revisions')        
        property_list.insert(t_id,property_list_header)
    property_list.insert(t_id+1,(t_id+1,
                                 tariff.urdb_id,
                                 tariff.uri.replace(',',',"'),
                                 tariff.eia_id,
                                 tariff.name.replace(',',',"'),
                                 tariff.utility.replace(',',',"'),
                                 tariff.sector.replace(',',',"'),
                                 tariff.description.replace('\n',' ').replace('\r',' ').replace(',',',"').replace('-','*'),
                                 tariff.comments.replace('\n',' ').replace('\r',' ').replace(',',',"'),
                                 tariff.voltage_category.replace(',',',"'),
                                 max(tariff.d_flat_levels.shape),np.amax(tariff.d_flat_levels),np.amin(tariff.d_flat_levels),
                                 max(tariff.d_tou_levels.shape), np.amax(tariff.d_tou_levels), np.amin(tariff.d_tou_levels),
                                 max(tariff.e_levels.shape),     np.amax(tariff.e_levels),     np.amin(tariff.e_levels),
                                 tariff.kWh_useage_max,tariff.kWh_useage_min,
                                 tariff.peak_kW_capacity_max,tariff.peak_kW_capacity_min,
                                 tariff.approved,tariff.startdate,tariff.enddate,tariff.supercedes,tariff.sourceparent,
                                 tariff.minmonthlycharge,tariff.annualmincharge,tariff.voltageminimum,tariff.voltagemaximum,
                                 tariff.phasewiring,tariff.demandwindow,tariff.demandattrs,tariff.energycomments,tariff.revisions
                                 ))
        
    if (1==1):        # Turn on and off data writing
        try:            
            e_tou_8760_write[range(1,n_timesteps+1),t_id] = np.transpose(tariff.e_tou_8760)
            d_tou_8760_write[range(1,n_timesteps+1),t_id] = np.transpose(tariff.d_tou_8760)
            # Select the last level for all tariffs
            d_flat_prices_write[range(1,n_months+1),t_id] = np.transpose(tariff.d_flat_prices[tariff.d_flat_prices.shape[0]-1][range(tariff.d_flat_prices.shape[1])])
            # Create d_tou_prices_write
            d_tou_prices_write[range(1,len(np.transpose(tariff.d_tou_prices))+1),t_id] = np.transpose(tariff.d_tou_prices[tariff.d_tou_prices.shape[0]-1][range(tariff.d_tou_prices.shape[1])])    
            e_prices_write[range(1,len(tariff.e_prices_no_tier)+1),t_id] = tariff.e_prices_no_tier
            fixed_charge_write[1,t_id] = tariff.fixed_charge        
        except: 
            print('Error converting data for ', t_id,' try increasing length of price arrays price (>20)')                    
            continue
     
    # Calculate the electricity bill for the given profile under the given tariff
    #    bill, bill_results_dict = tFuncs.bill_calculator(load_profile, tariff, export_tariff)
    if (t_id % 100)== 0:
        print('Current Scenario: ', t_id)
            
with open(Output_files + '/CSV_data/tariff_property_list.csv', 'w', newline='') as csvfile:
    spamwriter = csv.writer(csvfile, delimiter=',',quotechar='"', quoting=csv.QUOTE_MINIMAL)
    spamwriter.writerows(property_list)   
    
if (1==1):        # Turn on and off data writing
    with open(Output_files + '/CSV_data/e_tou_8760.csv', 'w', newline='') as csvfile:
        spamwriter = csv.writer(csvfile, delimiter=',',quotechar='|', quoting=csv.QUOTE_MINIMAL)
        spamwriter.writerows(e_tou_8760_write)
    with open(Output_files + '/CSV_data/d_tou_8760.csv', 'w', newline='') as csvfile:
        spamwriter = csv.writer(csvfile, delimiter=',',quotechar='|', quoting=csv.QUOTE_MINIMAL)
        spamwriter.writerows(d_tou_8760_write)
    with open(Output_files + '/CSV_data/d_flat_prices.csv', 'w', newline='') as csvfile:
        spamwriter = csv.writer(csvfile, delimiter=',',quotechar='|', quoting=csv.QUOTE_MINIMAL)
        spamwriter.writerows(d_flat_prices_write)    
    with open(Output_files + '/CSV_data/d_tou_prices.csv', 'w', newline='') as csvfile:
        spamwriter = csv.writer(csvfile, delimiter=',',quotechar='|', quoting=csv.QUOTE_MINIMAL)
        spamwriter.writerows(d_tou_prices_write)
    with open(Output_files + '/CSV_data/e_prices.csv', 'w', newline='') as csvfile:
        spamwriter = csv.writer(csvfile, delimiter=',',quotechar='|', quoting=csv.QUOTE_MINIMAL)
        spamwriter.writerows(e_prices_write)    
    with open(Output_files + '/CSV_data/fixed_charge.csv', 'w', newline='') as csvfile:
        spamwriter = csv.writer(csvfile, delimiter=',',quotechar='|', quoting=csv.QUOTE_MINIMAL)
        spamwriter.writerows(fixed_charge_write)    
        
