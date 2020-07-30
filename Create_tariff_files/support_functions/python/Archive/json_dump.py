# -*- coding: utf-8 -*-
"""
Created on Mon Oct 10 18:02:34 2016

@author: pgagnon
"""

import json
import numpy as np
import codecs
import tariff_functions

t = tariff_functions.Tariff()
a = t.__dict__
b = a.copy()

for fieldname in b.keys():
    if isinstance(b[fieldname], np.ndarray):
        b[fieldname] = b[fieldname].tolist()

with open('result.json', 'w') as fp:
    json.dump(b, fp)
    
    
obj_text = codecs.open('result.json', 'r', encoding='utf-8').read()
b_new = json.loads(obj_text)
a_new = b_new.copy()
for fieldname in a_new.keys():
    if isinstance(a_new[fieldname], list):
        a_new[fieldname] = np.array(a_new[fieldname])
    