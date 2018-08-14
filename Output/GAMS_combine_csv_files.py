# -*- coding: utf-8 -*-
"""
Created on Thu Feb 23 17:51:07 2017

@author: jeichman
"""

import fnmatch
import os
import sqlite3
import numpy as np
import pandas as pd
import re
import warnings 
warnings.simplefilter("ignore",UserWarning)

Scenario1 = 'VTA_bus_project'
#Scenario1 = 'Central_vs_distributed'
#Scenario1 = 'Solar_Hydrogen'
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
    elif Scenario1=='Solar_Hydrogen':
        if fnmatch.fnmatch(files2load, 'Storage_dispatch_input*'):
            c0[0]=c0[0]+1
            files2load_input[c0[0]] = files2load
            int1 = files2load.split("_")
            int1 = int1[3:]
#            int1[2] = int1[2].replace('CF', '')            
            int1[1] = int1[1].replace('hrs.csv', '')
            files2load_input_title[c0[0]] = int1
        if fnmatch.fnmatch(files2load, 'Storage_dispatch_results*'):
            c0[1]=c0[1]+1
            files2load_results[c0[1]] = files2load
            int1 = files2load.split("_")
            int1 = int1[3:]
#            int1[2] = int1[2].replace('CF', '')
            int1[1] = int1[1].replace('hrs.csv', '')
            files2load_results_title[c0[1]] = int1
        if fnmatch.fnmatch(files2load, 'Storage_dispatch_summary*'):
            c0[2]=c0[2]+1
            files2load_summary[c0[2]] = files2load
            int1 = files2load.split("_")
            int1 = int1[3:]
#            int1[2] = int1[2].replace('CF', '')
            int1[1] = int1[1].replace('hrs.csv', '')
            files2load_summary_title[c0[2]] = int1
    elif Scenario1=='VTA_bus_project':
        if fnmatch.fnmatch(files2load, 'Storage_dispatch_input*'):
            c0[0]=c0[0]+1
            files2load_input[c0[0]] = files2load
            int1 = files2load.split("_")
            int1 = int1[3:]
            int1[2] = int1[2].replace('.csv', '')
            files2load_input_title[c0[0]] = int1
        if fnmatch.fnmatch(files2load, 'Storage_dispatch_results_*'):
            c0[1]=c0[1]+1
            files2load_results[c0[1]] = files2load
            int1 = files2load.split("_")
            int1 = int1[3:]
            int1[2] = int1[2].replace('.csv', '')
            files2load_results_title[c0[1]] = int1
        if fnmatch.fnmatch(files2load, 'Storage_dispatch_summary_*'):
            c0[2]=c0[2]+1
            files2load_summary[c0[2]] = files2load
            int1 = files2load.split("_")
            int1 = int1[3:]
            int1[2] = int1[2].replace('.csv', '')
            files2load_summary_title[c0[2]] = int1
        files2load_title_header = ['Utility','Block','Services']

# Connecting to the database file
### conn.close()
sqlite_file = 'Default_summary.db'  # name of the sqlite database file
if os.path.exists(dir0+'/'+sqlite_file):
    os.remove(dir0+'/'+sqlite_file)
conn = sqlite3.connect(dir0+sqlite_file)    # Setup connection with sqlite
c = conn.cursor()

if 1==0:            # This section captures the scenario table from summary files
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
    elif Scenario1=='Solar_Hydrogen':
        c.execute('''CREATE TABLE Scenarios ('Scenario Number' real,
                                             'Tariff' text,                                             
                                             'Capacity Factor (%)' real,
                                             'Storage duration (hours)' real)''')
    
        sql = "INSERT INTO Scenarios VALUES (?,?,?,?)"
        params=list()
        for i0 in range(len(files2load_summary)):    
            params.insert(i0,tuple(list([str(i0+1)])+files2load_summary_title[i0+1]))
            print('Scenario data: '+str(i0+1)+' of '+str(len(files2load_summary)))
        c.executemany(sql, params)
        conn.commit()         


        
if 1==1:            # This section captures the summary files         
    # Creating Summary Table
    for i0 in range(len(files2load_summary_title)):
        # Creating Summary Table header
        files2load_summary_data = pd.read_csv(dir0+files2load_summary[i0+1],sep=',',header=0,names=['Data'],skiprows=[0,1]).T
        if files2load_summary_data['output to input ratio'].values==['         +INF']:
            files2load_summary_data['output to input ratio'] = 0
            files2load_summary_data = files2load_summary_data.astype('float64', copy=False)
        files2load_summary_data = files2load_summary_data.drop(['input','output'],axis=1)       # Remove unnecessary rows
        for i1 in range(len(files2load_title_header)):
            files2load_summary_data[files2load_title_header[i1]] = files2load_summary_title[i0+1][i1]
        if i0==0:
            files2load_summary_data_all = files2load_summary_data
        else:
            files2load_summary_data_all = files2load_summary_data_all.append(files2load_summary_data, ignore_index=True)
        print('Combining Data: '+str(i0+1)+' of '+str(len(files2load_summary_title)))

    # Rename duplicate columns (should fix in next version)
    H1 = {'LSL limit fraction': ['Input LSL limit fraction', 'Output LSL limit fraction']}
    files2load_summary_data_all = files2load_summary_data_all.rename(columns=lambda c: H1[c].pop(0) if c in H1.keys() else c)
    H1 = {'reg up limit fraction': ['Input reg up limit fraction', 'Output reg up limit fraction']}
    files2load_summary_data_all = files2load_summary_data_all.rename(columns=lambda c: H1[c].pop(0) if c in H1.keys() else c)
    H1 = {'reg down limit fraction': ['Input reg down limit fraction', 'Output reg down limit fraction']}
    files2load_summary_data_all = files2load_summary_data_all.rename(columns=lambda c: H1[c].pop(0) if c in H1.keys() else c)
    H1 = {'spining reserve limit fraction': ['Input spining reserve limit fraction', 'Output spining reserve limit fraction']}
    files2load_summary_data_all = files2load_summary_data_all.rename(columns=lambda c: H1[c].pop(0) if c in H1.keys() else c)
    H1 = {'startup cost ($/MW-start)': ['Input startup cost ($/MW-start)', 'Output startup cost ($/MW-start)']}
    files2load_summary_data_all = files2load_summary_data_all.rename(columns=lambda c: H1[c].pop(0) if c in H1.keys() else c)
    H1 = {'minimum run intervals': ['Input minimum run intervals', 'Output minimum run intervals']}
    files2load_summary_data_all = files2load_summary_data_all.rename(columns=lambda c: H1[c].pop(0) if c in H1.keys() else c)
        
    # Create database table for each column
    files2load_summary_header = files2load_summary_data_all.columns.tolist()
    files2load_summary_data_types = files2load_summary_data_all.dtypes
    execute_text = 'CREATE TABLE Summary (\''
    sql = "INSERT INTO Summary VALUES ("
    for i0 in range(len(files2load_summary_header)):
        if i0==len(files2load_summary_header)-1:
            if files2load_summary_data_types[i0]=='object':
                execute_text = execute_text+files2load_summary_header[i0]+'\' text)'
            elif files2load_summary_data_types[i0]=='float64':
                execute_text = execute_text+files2load_summary_header[i0]+'\' real)'
            sql = sql+'?)'
        else:
            if files2load_summary_data_types[i0]=='object':
                execute_text = execute_text+files2load_summary_header[i0]+'\' text,\''
            elif files2load_summary_data_types[i0]=='float64':
                execute_text = execute_text+files2load_summary_header[i0]+'\' real,\''
            sql = sql+'?,'
    c.execute(execute_text)

    # Committing changes and closing the connection to the database file
    params=list()
    for i0 in range(len(files2load_summary_data_all)):
        params.insert(i0,tuple(files2load_summary_data_all.loc[i0,:].tolist()))
        if (i0%1000)==0:
            print('Creating Output: '+str(i0)+' of '+str(len(files2load_summary_data_all)))
    c.executemany(sql, params)
    conn.commit()
    
    
   
if 1==0:            # This section captures a subset of the results files 
    # Print Results data   
    c.execute('''CREATE TABLE Results ('Scenario' integer,
                                       'Interval' integer,
                                       'In Pwr (MW)' real,
                                       'Storage Level (MW-h)' real,                                  
                                       'H2 Out (kg)' real,
                                       'Non-Renwable Input (MW)' real)''')
    
    sql = "INSERT INTO Results VALUES (?,?,?,?,?,?)"
    for i0 in range(len(files2load_results)):
        #if (i0==1):
        #    results_data_headers = np.genfromtxt(dir1+files2load_results[i0+1], dtype=(str), delimiter=",",invalid_raise = False,skip_header=29, max_rows=1)   
        results_data0 = np.genfromtxt(dir1+files2load_results[i0+1], dtype=(float), delimiter=",",invalid_raise = False,skip_header=30)
        results_data = np.delete(results_data0, np.s_[2,4,5,6,7,8,9,10,11,14,15,16], axis=1)
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
            results_data_headers = np.genfromtxt(dir1+files2load_results[i0+1], dtype=(str), delimiter=",",invalid_raise = False,skip_header=29, max_rows=1)   
        results_data = np.genfromtxt(dir1+files2load_results[i0+1], dtype=(float), delimiter=",",invalid_raise = False,skip_header=30)
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

