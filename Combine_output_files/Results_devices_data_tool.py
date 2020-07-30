# -*- coding: utf-8 -*-
"""
Created on Sat Aug 17 17:07:51 2019
@author: jeichman
"""
import pandas as pd
import os
import fnmatch
dir0 = 'C:/Users/jeichman/Documents/gamsdir/projdir/RODeO/Projects/VTA_bus_project2/Output/'           # Location of files to load


c0 = 0
for files2load in os.listdir(dir0):
    if fnmatch.fnmatch(files2load, 'Storage_dispatch_resultsDevices*'):
        if c0==0:
            files2load2 = [files2load]
            c0=c0+1
        else:
            files2load2.append(files2load)
            c0=c0+1

c0 = 0
c2 = [0]
for files2load in files2load2:
        # Load files and melt into shape
        results_devices = pd.read_csv(dir0 + files2load,sep=',')
            #results_devices = results_devices.iloc[:30]
        results_devices = results_devices.iloc[:,:-3]
        results_devices_cols = list(results_devices.columns.values)
        results_devices_melt = pd.melt(results_devices, id_vars='Interval',var_name='Properties',value_vars=results_devices_cols[1:])
        results_devices_melt['Interval'] = results_devices_melt['Interval'].astype(int)
        results_devices_melt['Device'] = results_devices_melt['Properties'].str.extract(' (\d+)',expand=True)
        results_devices_melt = results_devices_melt.dropna()
        results_devices_melt['Properties'] = results_devices_melt['Properties'].str.replace(' \d+', '')
        results_devices_melt['Interval_Device'] = results_devices_melt['Interval'].map(str) + ' ' + results_devices_melt['Device'].map(str)
        
        # Reduce columns to only 'In Pwr (MW)'
        ### results_devices_melt = results_devices_melt[results_devices_melt.Properties == 'In Pwr (MW)']
        
        # Pivot files and maintain Interval and Device columns
        results_devices_pivot = results_devices_melt.pivot(index='Interval_Device',columns='Properties', values='value')
        results_devices_pivot.reset_index(inplace=True)
        results_devices_pivot[['Interval','Device']] = results_devices_pivot.Interval_Device.str.split(" ",expand=True)
        results_devices_pivot['Interval'] = pd.to_numeric(results_devices_pivot['Interval'], downcast='integer')
        results_devices_pivot['Device'] = pd.to_numeric(results_devices_pivot['Device'], downcast='integer')
        results_devices_pivot.drop(columns='Interval_Device', inplace=True)
        
        # Output to csv file if desired
        #results_devices_pivot.to_csv(dir0+files2load[:-4]+'_PIVOT.csv', sep=',', header=True,index=False)

        results_devices_pivot_cols = list(results_devices_pivot.columns.values)
          # not necessary    results_devices_pivot = results_devices_pivot[list(results_devices_pivot_cols[i] for i in [1,4,5])]
        if 1==0:
            results_devices_pivot2 = results_devices_pivot.pivot(index='Interval',columns='Device', values='In Pwr (MW)')
        else: 
            results_devices_pivot2 = results_devices_pivot.pivot(index='Interval',columns='Device', values='Storage Lvl (MW-h)')

        # Output to csv file if desired
        if 1==0:
            results_devices_pivot2.to_csv(dir0+files2load[:-4]+'_PIVOT.csv', sep=',', header=True,index=False)
        else:
            results_devices_pivot2.to_csv(dir0+files2load[:-4]+'_PIVOT_STORAGE.csv', sep=',', header=True,index=False)

        if 1==0:
            # Really slow process to calculate the number of chargers required for each scenario. Could speed up with some optimization but for now is ok.
            c1 = [0]*len(results_devices_pivot2);
            for i1 in range(len(results_devices_pivot2)):
                for i2 in range(len(list(results_devices_pivot2.columns.values))):
                    if results_devices_pivot2.loc[i1+1,i2+1]>0:
                        c1[i1] = c1[i1]+1
            if c0==0:
                c2=[max(c1)]
            else:
                c2.append(max(c1))
            print('Files completed: '+str(c0+1)+' of '+str(len(files2load2)))
            c0 = c0+1

        
Count_final = pd.DataFrame(files2load2,columns=['Scenarios']) 
Count_final['Chargers'] = c2
       
   

# Rename csv files
"""
import pandas as pd
import os
dir0 = 'C:/Users/jeichman/Documents/gamsdir/projdir/RODeO/Projects/VTA_bus_project2/Output/Results_Scorpio_8-23-2019_Dumb_charging/'           # Location of files to load
for files2load in os.listdir(dir0):
    src = dir0 + files2load 
    files2load = files2load.replace('Eonly','Eonly1')
    dst = dir0 + files2load
      
    # rename() function will 
    # rename all the files 
    os.rename(src, dst) 
"""