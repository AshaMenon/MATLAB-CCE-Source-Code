# -*- coding: utf-8 -*-
"""
Created on Wed May  4 14:57:17 2022

@author: verushen.coopoo
"""

import numpy as np
import src.NiSlagModellingHelpers as helpNiSlag

#%%

# Set input parameters
deadBand = 0
NiSlagTarget = 3

# Get SpO2
lowRange, highRange, _ = helpNiSlag.getSpO2(NiSlagTarget, deadBand)

# Plot figure
helpNiSlag.plotSpO2Curve(lowRange['corrNi'], lowRange['oxy'], 
                         highRange['corrNi'], highRange['oxy'])