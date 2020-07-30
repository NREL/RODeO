# -*- coding: utf-8 -*-
"""
Created on Mon Oct 24 14:14:45 2016

@author: pgagnon
"""

import numpy as np

batt_charge_limit = 10
batt_discharge_limit = 10
batt_charge_limits_len = batt_charge_limit + batt_discharge_limit +1

adjuster = np.zeros(batt_charge_limits_len, float)
base_adjustment = 1.0 #0.0000001

adjuster[np.arange(batt_discharge_limit,-1,-1)] = base_adjustment * np.array(range(batt_discharge_limit+1))*np.array(range(batt_discharge_limit+1)) / (batt_discharge_limit*batt_discharge_limit)
adjuster[batt_discharge_limit:] = base_adjustment * np.array(range(batt_charge_limit+1))*np.array(range(batt_charge_limit+1)) / (batt_charge_limit*batt_charge_limit)

