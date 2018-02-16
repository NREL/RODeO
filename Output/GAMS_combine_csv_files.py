# -*- coding: utf-8 -*-
"""
Created on Thu Feb 23 17:51:07 2017

@author: jeichman
"""

import fnmatch
import os
import sqlite3
import numpy as np
import warnings 
warnings.simplefilter("ignore",UserWarning)

Scenario1 = 'Central_vs_distributed'
#Scenario1 = 'Example'

dir0 = 'C:/Users/jeichman/Documents/gamsdir/projdir/RODeO/Projects/'+Scenario1+'/Output/'  # Location to put database files
dir1 = dir0                                                          # Location of csv files

c0 = [0,0,0]
files2load_input={}
files2load_input_title={}
files2load_results={}
files2load_results_title={}
files2load_summary={}
files2load_summary_title={}

for files2load in os.listdir(dir1):
    if 1==0:
        if fnmatch.fnmatch(files2load, 'Storage_dispatch_input*'):
            c0[0]=c0[0]+1
            files2load_input[c0[0]] = files2load
            int1 = files2load.split("_")
            int1 = int1[3:]
            int1[4] = int1[4].replace('CF', '')
            int1[5] = int1[5].replace('RE', '')
            int1[7] = int1[7].replace('hrs.csv', '')
            files2load_input_title[c0[0]] = int1
        if fnmatch.fnmatch(files2load, 'Storage_dispatch_results*'):
            c0[1]=c0[1]+1
            files2load_results[c0[1]] = files2load
            int1 = files2load.split("_")
            int1 = int1[3:]
            int1[4] = int1[4].replace('CF', '')
            int1[5] = int1[5].replace('RE', '')
            int1[7] = int1[7].replace('hrs.csv', '')
            files2load_results_title[c0[1]] = int1
        if fnmatch.fnmatch(files2load, 'Storage_dispatch_summary*'):
            c0[2]=c0[2]+1
            files2load_summary[c0[2]] = files2load
            int1 = files2load.split("_")
            int1 = int1[3:]
            int1[4] = int1[4].replace('CF', '')
            int1[5] = int1[5].replace('RE', '')
            int1[7] = int1[7].replace('hrs.csv', '')
            files2load_summary_title[c0[2]] = int1
    elif 1==0:
        if fnmatch.fnmatch(files2load, 'Storage_dispatch_input*'):
            c0[0]=c0[0]+1
            files2load_input[c0[0]] = files2load
            int1 = files2load.split("_")
            int1 = int1[3:]
            int1[2] = int1[2].replace('hrs.csv', '')
            files2load_input_title[c0[0]] = int1
        if fnmatch.fnmatch(files2load, 'Storage_dispatch_results*'):
            c0[1]=c0[1]+1
            files2load_results[c0[1]] = files2load
            int1 = files2load.split("_")
            int1 = int1[3:]
            int1[2] = int1[2].replace('hrs.csv', '')
            files2load_results_title[c0[1]] = int1
        if fnmatch.fnmatch(files2load, 'Storage_dispatch_summary*'):
            c0[2]=c0[2]+1
            files2load_summary[c0[2]] = files2load
            int1 = files2load.split("_")
            int1 = int1[3:]
            int1[2] = int1[2].replace('hrs.csv', '')
            files2load_summary_title[c0[2]] = int1
    elif Scenario1=='Example':
        if fnmatch.fnmatch(files2load, 'Storage_dispatch_input*'):
            c0[0]=c0[0]+1
            files2load_input[c0[0]] = files2load
            int1 = files2load.split("_")
            int1 = int1[3:]
            int1[2] = int1[2].replace('CF', '')
            int1[3] = int1[3].replace('hrs.csv', '')
            files2load_input_title[c0[0]] = int1
        if fnmatch.fnmatch(files2load, 'Storage_dispatch_results*'):
            c0[1]=c0[1]+1
            files2load_results[c0[1]] = files2load
            int1 = files2load.split("_")
            int1 = int1[3:]
            int1[2] = int1[2].replace('CF', '')
            int1[3] = int1[3].replace('hrs.csv', '')
            files2load_results_title[c0[1]] = int1
        if fnmatch.fnmatch(files2load, 'Storage_dispatch_summary*'):
            c0[2]=c0[2]+1
            files2load_summary[c0[2]] = files2load
            int1 = files2load.split("_")
            int1 = int1[3:]
            int1[2] = int1[2].replace('CF', '')
            int1[3] = int1[3].replace('hrs.csv', '')
            files2load_summary_title[c0[2]] = int1
    elif Scenario1=='Central_vs_distributed':
        if fnmatch.fnmatch(files2load, 'Storage_dispatch_input*'):
            c0[0]=c0[0]+1
            files2load_input[c0[0]] = files2load
            int1 = files2load.split("_")
            int1 = int1[3:]
            int1[2] = int1[2].replace('CF', '')            
            int1[5] = int1[5].replace('hrs.csv', '')
            files2load_input_title[c0[0]] = int1
        if fnmatch.fnmatch(files2load, 'Storage_dispatch_results*'):
            c0[1]=c0[1]+1
            files2load_results[c0[1]] = files2load
            int1 = files2load.split("_")
            int1 = int1[3:]
            int1[2] = int1[2].replace('CF', '')
            int1[5] = int1[5].replace('hrs.csv', '')
            files2load_results_title[c0[1]] = int1
        if fnmatch.fnmatch(files2load, 'Storage_dispatch_summary*'):
            c0[2]=c0[2]+1
            files2load_summary[c0[2]] = files2load
            int1 = files2load.split("_")
            int1 = int1[3:]
            int1[2] = int1[2].replace('CF', '')
            int1[5] = int1[5].replace('hrs.csv', '')
            files2load_summary_title[c0[2]] = int1


# Connecting to the database file
sqlite_file = 'Default_summary.db'  # name of the sqlite database file
conn = sqlite3.connect(dir0+sqlite_file)                           # Setup connection with sqlite
c = conn.cursor()

if 1==1:            # This section captures the scenario table from summary files
    # Create Scenarios table and populate
    if 1==0:
        c.execute('''CREATE TABLE Scenarios ('Scenario Number' real,
                                             'Technology' text,
                                             'Operating Strategy' text,
                                             'Rate structure' text,
                                             'Time resoultion' text,
                                             'Capacity factor' real,
                                             'Renewable ratio to technology' real,
                                             'Renewable type' text,
                                             'Storage duration (hours)' real)''')
    
        sql = "INSERT INTO Scenarios VALUES (?,?,?,?,?,?,?,?,?)"
        params=list()
        for i0 in range(len(files2load_summary)):    
            params.insert(i0,tuple(list([str(i0+1)])+files2load_summary_title[i0+1]))
            print('Scenario data: '+str(i0+1)+' of '+str(len(files2load_summary)))
        c.executemany(sql, params)
        conn.commit()
    elif 1==0:
        c.execute('''CREATE TABLE Scenarios ('Scenario Number' real,
                                             'Market' text,                                             
                                             'Location' text,
                                             'Storage duration (hours)' real)''')
    
        sql = "INSERT INTO Scenarios VALUES (?,?,?,?)"
        params=list()
        for i0 in range(len(files2load_summary)):    
            params.insert(i0,tuple(list([str(i0+1)])+files2load_summary_title[i0+1]))
            print('Scenario data: '+str(i0+1)+' of '+str(len(files2load_summary)))
        c.executemany(sql, params)
        conn.commit()
    elif 1==0:
        c.execute('''CREATE TABLE Scenarios ('Scenario Number' real,
                                             'Market' text,                                             
                                             'Location' text,
                                             'Storage duration (hours)' real)''')
    
        sql = "INSERT INTO Scenarios VALUES (?,?,?,?)"
        params=list()
        for i0 in range(len(files2load_summary)):    
            params.insert(i0,tuple(list([str(i0+1)])+files2load_summary_title[i0+1]))
            print('Scenario data: '+str(i0+1)+' of '+str(len(files2load_summary)))
        c.executemany(sql, params)
        conn.commit()
    elif Scenario1=='Example':
        c.execute('''CREATE TABLE Scenarios ('Scenario Number' real,
                                             'Tariff' text,                                             
                                             'Operating Strategy' text,
                                             'Capacity Factor (%)' real,
                                             'Storage duration (hours)' real)''')
    
        sql = "INSERT INTO Scenarios VALUES (?,?,?,?,?)"
        params=list()
        for i0 in range(len(files2load_summary)):    
            params.insert(i0,tuple(list([str(i0+1)])+files2load_summary_title[i0+1]))
            print('Scenario data: '+str(i0+1)+' of '+str(len(files2load_summary)))
        c.executemany(sql, params)
        conn.commit()   
    elif Scenario1=='Central_vs_distributed':
        c.execute('''CREATE TABLE Scenarios ('Scenario Number' real,
                                             'Tariff' text,                                             
                                             'Operating Strategy' text,
                                             'Capacity Factor (%)' real,
                                             'Configuration' text,
                                             'Timeframe' text,
                                             'Storage duration (hours)' real)''')
    
        sql = "INSERT INTO Scenarios VALUES (?,?,?,?,?,?,?)"
        params=list()
        for i0 in range(len(files2load_summary)):    
            params.insert(i0,tuple(list([str(i0+1)])+files2load_summary_title[i0+1]))
            print('Scenario data: '+str(i0+1)+' of '+str(len(files2load_summary)))
        c.executemany(sql, params)
        conn.commit()         
        
if 1==1:            # This section captures the summary files         
    # Creating Summary Table
    c.execute('''CREATE TABLE Summary ('Scenario Number' real,
                                       'Renewable Capacity (MW)' real,
                                       'Renewable Penetration for Input (%)' real,
                                       'interval length (hours)' real,
                                       'operating period length (hours)' real,
                                       'additional look-ahead (hours)' real,
                                       'output capacity (MW)' real,
                                       'input capacity (MW)' real,
                                       'storage capacity (hours)' real,
                                       'input efficiency (%)' real,
                                       'output efficiency (%)' real,
                                       'input heat rate (MMBtu/MWh)' real,
                                       'output heat rate (MMBtu/MWh)' real,
                                       'variable O&M cost' real,
                                       'regulation cost' real,
                                       'hydrogen use' real,
                                       'input LSL limit fraction' real,
                                       'input reg up limit fraction' real,
                                       'input reg down limit fraction' real,
                                       'input spining reserve limit fraction' real,
                                       'input startup cost ($/MW-start)' real,
                                       'input minimum run intervals' real,
                                       'output LSL limit fraction' real,
                                       'output reg up limit fraction' real,
                                       'output reg down limit fraction' real,
                                       'output spining reserve limit fraction' real,
                                       'output startup cost ($/MW-start)' real,
                                       'output minimum run intervals' real,
                                       'actual operating profit ($)' real,
                                       'total electricity input (MWh)' real,
                                       'total electricity output (MWh)' real,
                                       'output to input ratio' real,
                                       'input capacity factor' real,
                                       'output capacity factor' real,
                                       'average regup (MW)' real,
                                       'average regdn (MW)' real,
                                       'average spinres (MW)' real,
                                       'average nonspinres (MW)' real,
                                       'number of input power system starts' real,
                                       'number of output power system starts' real,
                                       'arbitrage revenue ($)' real,
                                       'regup revenue ($)' real,
                                       'regdn revenue ($)' real,
                                       'spinres revenue ($)' real,
                                       'nonspinres revenue ($)' real,
                                       'hydrogen revenue ($)' real,
                                       'startup costs ($)' real,
                                       'Fixed demand charge ($)' real,
                                       'Timed demand charge 1 ($)' real,
                                       'Timed demand charge 2 ($)' real,
                                       'Timed demand charge 3 ($)' real,
                                       'Timed demand charge 4 ($)' real,
                                       'Timed demand charge 5 ($)' real,
                                       'Timed demand charge 6 ($)' real,
                                       'Meter cost ($)' real,
                                       'Input annualized capital cost ($)' real,
                                       'Output annualized capital cost ($)' real,
                                       'Input FOM cost ($)' real,
                                       'Output FOM cost ($)' real,
                                       'Input VOM cost ($)' real,
                                       'Output VOM cost ($)' real,
                                       'Renewable Sales ($)' real,
                                       'Renewable Penetration net meter (%)' real,
                                       'Curtailment (MWh)' real,
                                       'Storage Revenue ($)' real,
                                       'Renewable only revenue ($)' real,
                                       'Renewable max revenue ($)' real,
                                       'Renewable Electricity Input (MWh)' real,
                                       'Electricity Import (MWh)' real)''')
    
    # Print Summary data
    summary_data = np.zeros(shape=(68,len(files2load_summary))) 
    for i0 in range(len(files2load_summary)):
        if (i0==1):
            summary_data_headers = np.genfromtxt(dir1+files2load_summary[i0+1], dtype=(str), delimiter=",",usecols=(0),invalid_raise = False,skip_header=2)   # Other values (skip_header=3, skip_footer=49)
            summary_data_headers = np.delete(summary_data_headers, (15), axis=0)    # Remove extra row for first column
            summary_data_headers = np.delete(summary_data_headers, (21), axis=0)    # Remove extra row for first column
        summary_data[:,i0] = np.genfromtxt(dir1+files2load_summary[i0+1], dtype=(float), delimiter=",",usecols=(1),invalid_raise = False,skip_header=2)   # Other values (skip_header=3, skip_footer=49)
        print('Summary Data: '+str(i0+1)+' of '+str(len(files2load_summary)))
    interval_length = summary_data[3,0]
    
    # Committing changes and closing the connection to the database file
    sql = "INSERT INTO Summary VALUES (?,?,?,?,?,?,?,?,?,?, ?,?,?,?,?,?,?,?,?,?, ?,?,?,?,?,?,?,?,?,?, ?,?,?,?,?,?,?,?,?,?, ?,?,?,?,?,?,?,?,?,?, ?,?,?,?,?,?,?,?,?,?, ?,?,?,?,?,?,?,?,?)"
    params=list()
    for i0 in range(len(files2load_summary)):
        summary_data2 = np.transpose(summary_data[:,i0])
        params.insert(i0,tuple(list([i0+1])+summary_data2.tolist()))
    c.executemany(sql, params)
conn.commit()

   
if 1==0:            # This section captures a subset of the results files 
    # Print Results data   
    c.execute('''CREATE TABLE Results ('Scenario' integer,
                                       'Interval' integer,
                                       'In Pwr (MW)' real,
                                       'Storage Level (MW-h)' real,                                  
                                       'H2 Out (kg)' real,
                                       'Renewable Input (MW)' real)''')
    
    sql = "INSERT INTO Results VALUES (?,?,?,?,?,?)"
    for i0 in range(len(files2load_results)):
        #if (i0==1):
        #    results_data_headers = np.genfromtxt(dir1+files2load_results[i0+1], dtype=(str), delimiter=",",invalid_raise = False,skip_header=27, max_rows=1)   
        results_data0 = np.genfromtxt(dir1+files2load_results[i0+1], dtype=(float), delimiter=",",invalid_raise = False,skip_header=28)
        results_data = np.delete(results_data0, np.s_[2,4,5,6,7,8,9,10,11,14], axis=1)
        results_data_size = results_data.shape
        results_data2 = np.zeros((results_data_size[0],results_data_size[1]+1))
        results_data2[:,1:] = results_data
        results_data2[:,0] =np.ones((1,results_data_size[0]))*(i0+1)
        params = tuple(map(tuple, results_data2))
    #    results_data2 = np.transpose(results_data)
    #    params = [ results_data2.tolist()+files2load_summary_title[i0+1] ]
        print('Results Data: '+str(i0+1)+' of '+str(len(files2load_summary)))
        c.executemany(sql, params)
        conn.commit()

    
if 1==0:            # This section creates the entire results files 
    # Print Results data   
    c.execute('''CREATE TABLE Results ('Scenario' integer,
                                       'Interval' integer,
                                       'In Pwr (MW)' real,
                                       'Out Pwr (MW)' real,
                                       'Storage Level (MW-h)' real,
                                       'In Reg Up (MW)' real,
                                       'Out Reg Up (MW)' real,
                                       'In Reg Dn (MW)' real,
                                       'Out Reg Dn (MW)' real,
                                       'In Spin Res (MW)' real,
                                       'Out Spin Res (MW)' real,
                                       'In Nonspin (MW)' real,
                                       'Out Nonspin (MW)' real,
                                       'H2 Out (kg)' real,
                                       'Nonrenewable Input (MW)' real,
                                       'Renewable Input (MW)' real,
                                       'Renewable Sold (MW)' real,
                                       'Curtailment (MW)' real)''')
    
    sql = "INSERT INTO Results VALUES (?,?,?,?,?,?,?,?,?,?, ?,?,?,?,?,?,?,?)"
    for i0 in range(len(files2load_results)):
        if (i0==1):
            results_data_headers = np.genfromtxt(dir1+files2load_results[i0+1], dtype=(str), delimiter=",",invalid_raise = False,skip_header=27, max_rows=1)   
        results_data = np.genfromtxt(dir1+files2load_results[i0+1], dtype=(float), delimiter=",",invalid_raise = False,skip_header=28)
        results_data_size = results_data.shape
        results_data2 = np.zeros((results_data_size[0],results_data_size[1]+1))
        results_data2[:,1:] = results_data
        results_data2[:,0] =np.ones((1,results_data_size[0]))*(i0+1)
        params = tuple(map(tuple, results_data2))
    #    results_data2 = np.transpose(results_data)
    #    params = [ results_data2.tolist()+files2load_summary_title[i0+1] ]
        print('Results Data: '+str(i0+1)+' of '+str(len(files2load_summary)))
        c.executemany(sql, params)
        conn.commit()

    
    
conn.close()

