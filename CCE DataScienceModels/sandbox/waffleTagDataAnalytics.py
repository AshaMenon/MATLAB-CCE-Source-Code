# -*- coding: utf-8 -*-
"""
Created on Mon Aug 22 10:15:18 2022

@author: darshan.makan

This code was used to view the data from the upper, lower, outer, middle and center tags
at a glance to identify anomalies/errors in the data
"""
#%% Load libraries
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from statsmodels.tsa.api import SimpleExpSmoothing
import seaborn as sns

import src.preprocessingFunctions as prep
import src.modellingFunctions as modelling
import src.dataExploration as visualise
import src.featureEngineeringHelpers as featEng
from Shared.DSModel.Data import Data


#%% Data import and preprocessing

""" In order to run the data analytics on the upper, lower, outer, middle and center waffle tags
the preprocessing code used for generating InputsDF needs to be modified first.  
In prep.addLatentTemperatureFeatures comment out all of the parts of code which drop the waffle 
readings"""

parameters = dict()
parameters['writeToExcel'] = False
parameters['highFrequencyPredictorTags'] = ["Matte feed PV", "Fuel coal feed rate PV", "Specific Oxygen Actual PV",
                                            "Reverts feed rate PV", "Lump coal PV",
                                            "Lance oxygen flow rate PV", "Lance air flow rate PV",
                                            "Matte transfer air flow", "Lance coal carrier air",
                                            "Silica PV",
                                            "Upper Waffle 3", "Upper Waffle 4", "Upper Waffle 5",
                                            "Upper Waffle 6", "Upper Waffle 7", "Upper Waffle 8",
                                            "Upper Waffle 9", "Upper Waffle 10", "Upper Waffle 11",
                                            "Upper Waffle 12", "Upper Waffle 13", "Upper Waffle 14",
                                            "Upper Waffle 15", "Upper Waffle 16", "Upper Waffle 17",
                                            "Upper Waffle 18",
                                            "Lower waffle 19", "Lower waffle 20", "Lower waffle 21",
                                            "Lower waffle 22", "Lower waffle 23", "Lower waffle 24",
                                            "Lower waffle 25", "Lower waffle 26", "Lower waffle 27",
                                            "Lower waffle 28", "Lower waffle 29", "Lower waffle 30",
                                            "Lower waffle 31", "Lower waffle 32", "Lower waffle 33",
                                            "Lower waffle 34", "Outer long 1", "Middle long 1",
                                            "Outer long 2", "Middle long 2", "Outer long 3",
                                            "Middle long 3", "Outer long 4", "Middle long 4",
                                            "Centre long", "Lance Oxy Enrich % PV", "Roof matte feed rate PV",
                                            "Lance height", "Lance motion", "Phase B Matte tap block 1 DT_water",
                                            "Phase B Matte tap block 2 DT_water", "Phase B Slag tap block DT_water",
                                            "Phase A Matte tap block 1 DT_water", "Phase A Matte tap block  DT_water",
                                            "Phase A Slag tap block DT_water"]

parameters['lowFrequencyPredictorTags'] = ["Cr2O3 Slag", "Basicity", "MgO Slag", "Cu Feedblend", "Ni Feedblend",
                                           "Co Feedblend", "Fe Feedblend", "S Feedblend",
                                           "SiO2 Feedblend", "Al2O3 Feedblend", "CaO Feedblend",
                                           "MgO Feedblend", "Cr2O3 Feedblend"]

parameters['referenceTags'] = ["Converter mode", "Lance air and oxygen control"]

parameters['responseTags'] = ["Matte temperatures"]


# Setup the Data
inputsDF = prep.readAndFormatData('Temperature')
inputsDF = prep.fillMissingHXPoints(inputsDF)

# Add latent features (Specific to Temperature Model)
inputsDF, x, parameters['highFrequencyPredictorTags'], parameters['lowFrequencyPredictorTags'] = \
    prep.addLatentTemperatureFeatures(inputsDF, parameters['highFrequencyPredictorTags']+parameters['lowFrequencyPredictorTags'],
                                      parameters['highFrequencyPredictorTags'], parameters['lowFrequencyPredictorTags'])

#%% Waffle Tag Heat Flux Data Analytics

waffleTags = ["Outer long 1", "Outer long 2", "Outer long 3",
"Outer long 4"]

fig, (ax, axhist) = plt.subplots(ncols=2, sharey=True,
                                  gridspec_kw={"width_ratios" : [3,1], "wspace" : 0})
ax.plot(inputsDF[waffleTags], label = waffleTags)
ax.legend()
sns.distplot(inputsDF[waffleTags[0]], label = waffleTags[0], vertical = True)
sns.distplot(inputsDF[waffleTags[1]], label = waffleTags[1], vertical = True)
sns.distplot(inputsDF[waffleTags[2]], label = waffleTags[2], vertical = True)
sns.distplot(inputsDF[waffleTags[3]], label = waffleTags[3], vertical = True)

plt.legend()


# plt.plot(inputsDF[waffleTags], label = waffleTags)
# plt.legend()