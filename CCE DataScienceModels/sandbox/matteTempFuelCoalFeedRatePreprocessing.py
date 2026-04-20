# -*- coding: utf-8 -*-
"""
Created on Mon Aug  1 13:34:59 2022

@author: darshan.makan
"""
#%% Load libraries
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from statsmodels.tsa.api import SimpleExpSmoothing

import src.preprocessingFunctions as prep
import src.modellingFunctions as modelling
import src.dataExploration as visualise
import src.featureEngineeringHelpers as featEng
from Shared.DSModel.Data import Data

#%% Data import and preprocessing
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

phase = "A"

# Setup the Data
inputsDF = prep.readAndFormatData('Temperature')
inputsDF = prep.fillMissingHXPoints(inputsDF)

# Add latent features (Specific to Temperature Model)
inputsDF, _, parameters['highFrequencyPredictorTags'], parameters['lowFrequencyPredictorTags'] = \
    prep.addLatentTemperatureFeatures(inputsDF, parameters['highFrequencyPredictorTags']+parameters['lowFrequencyPredictorTags'],
                                      parameters['highFrequencyPredictorTags'], parameters['lowFrequencyPredictorTags'],
                                      phase)

dataModel = Data(inputsDF)

fullDF, origSmoothedResponses, predictorTagsNew = dataModel.preprocessingAndFeatureEngineering(**parameters)

#%% Data extraction

coalFeedRate = fullDF["Fuel coal feed rate PV"]     #Units: tonne/hour
maxCoalFeedRate = coalFeedRate.max()    
minCoalFeedRate = coalFeedRate.min()

print(maxCoalFeedRate)
print(minCoalFeedRate)

coalFeedRate.plot()

#%% Apply exponential smoothing method

smoothTestResults = SimpleExpSmoothing(coalFeedRate, initialization_method="heuristic").fit(
    smoothing_level=0.1, optimized=False)
smoothCoalFeedRate = smoothTestResults.fittedvalues

# [fig, ax] = plt.subplots()
coalFeedRate[:300].plot()
smoothCoalFeedRate[:300].plot()

#%% Dynamic Gradient approach

upperCoalFeedThreshold = 2.5
lowerCoalFeedThreshold = 0.5
threshold = 0.5     #units fuelCoalFeedRate/min

for i in range(len(coalFeedRate)-1):
    gradient = coalFeedRate[i+1] - coalFeedRate[i]      #calculates the change in fuel coal feed rate between sucessive measurements
    if ((gradient > threshold) and (coalFeedRate[i+1] > upperCoalFeedThreshold)):   #if the change in successive feed rates is large and the next measurement is out of an acceptable bound then reset it
        coalFeedRate[i+1] = coalFeedRate[i]
    elif ((gradient < -threshold) and (coalFeedRate[i+1] < lowerCoalFeedThreshold)): #if the change in successive feed rates is large (in the negative direction) and the next measurement is out of an acceptable bound then reset it   
        coalFeedRate[i+1] = coalFeedRate[i]
    elif ((gradient > 1) or (gradient < -1)):   #if the change in fuel coal rate is [excessively] large then reset the next measurement
        coalFeedRate[i+1] = coalFeedRate[i]

plt.plot(coalFeedRate, marker = "s", label = "Adjusted Data")
plt.xlabel('Time')
plt.ylabel("Fuel Coal Feed Rate [tonne/hour]")
plt.legend()

#%% Do not use - to be removed after discussion

# gradient = coalFeedRate.diff()
# meanGradient = []
# num_intervals = 30

# for i in range(round((len(test)-1)/num_intervals),len(test)-1, round((len(test)-1)/num_intervals)):
#     previousI = i - round((len(test)-1)/num_intervals)
#     meanGradient.append(gradient[previousI:i].mean())

# plt2.plot(meanGradient)

# lowerbound = 324457
# upperbound = 325457
# upperCoalFeedThreshold = 2.5
# lowerCoalFeedThreshold = 0.5
# threshold = 0.5     #units fuelCoalFeedRate/min

# test = coalFeedRate.copy()
# testIndex = pd.date_range('2021-01-01 04:13:00', periods=len(test) ,freq='min')


# for i in range(len(test)-1):
#     gradient = test[i+1] - test[i]
#     if ((gradient > threshold) and (test[i+1] > upperCoalFeedThreshold)):
#         test[i+1] = test[i]
#     elif ((gradient < -threshold) and (test[i+1] < lowerCoalFeedThreshold)):
#         test[i+1] = test[i]
#     elif ((gradient > 1) or (gradient < -1)):
#         test[i+1] = test[i]
        
# # test = pd.DataFrame(test)
# # test['Mean Gradient'] = meanGradient

# plt.plot(coalFeedRate[lowerbound:upperbound], marker = "s", label = "Original Data")
# plt.plot(test[lowerbound:upperbound],marker = ".", label = "Adjusted")
# # plt.hlines(y = meanGradient, xmin = testIndex[lowerbound] , xmax = testIndex[upperbound], label = 'Mean Gradient')
# plt.legend()