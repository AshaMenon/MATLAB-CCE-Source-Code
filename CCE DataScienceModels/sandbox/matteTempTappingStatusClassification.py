# -*- coding: utf-8 -*-
"""
Created on Wed Aug  3 13:33:43 2022

@author: darshan.makan
"""

#%% Load libraries
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from statsmodels.tsa.api import SimpleExpSmoothing
from scipy import signal
from scipy.signal import find_peaks
from sklearn import preprocessing
from itertools import groupby
import time

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


# Setup the Data
inputsDF = prep.readAndFormatData('Temperature')
inputsDF = prep.fillMissingHXPoints(inputsDF)

# Add latent features (Specific to Temperature Model)
inputsDF, _, parameters['highFrequencyPredictorTags'], parameters['lowFrequencyPredictorTags'] = \
    prep.addLatentTemperatureFeatures(inputsDF, parameters['highFrequencyPredictorTags']+parameters['lowFrequencyPredictorTags'],
                                      parameters['highFrequencyPredictorTags'], parameters['lowFrequencyPredictorTags'], 'A')

dataModel = Data(inputsDF)

fullDF, origSmoothedResponses, predictorTagsNew = dataModel.preprocessingAndFeatureEngineering(**parameters)

#%% Extracting and visualising Tapping data

tappingData = fullDF.loc[:,["Phase A Matte tap block 1 DT_water", "Phase A Matte tap block  DT_water",
"Phase A Slag tap block DT_water"]]

lowerBound = 0
upperBound = 5700

# tappingData["Phase A Matte tap block  DT_water"][lowerBound:upperBound].plot()
tappingData[lowerBound:upperBound].plot()

#%% Identifying tapping regions

'''
Identifying tapping regions for Phase A Slag tap block 1DT_water using a sliding window approach
A window (with a user specified size) will slide over the data and calculate the mean gradient of
the data. If the gradient is positive it means that tapping is occuring. This method should eliminate 
noise from small troughs in the data
'''
test = tappingData.copy()
test = test[lowerBound:upperBound]

windowSize = 20    #Takes 100 samples at a time
windowMean = np.array([])
# windowMean = pd.DataFrame([], columns= ['Mean window difference'], index=[])

for i in range(0,len(test),windowSize): #might need the step size to be 1 for more precise logging 
    window = test["Phase A Slag tap block DT_water"][i:i+windowSize]
    windowMean = np.append(windowMean, window.diff().mean())
    # windowMean = np.append(windowMean, window.diff())
    
windowMean = np.repeat(windowMean, windowSize)
onOff = ((windowMean>0)*1) + 2
# windowMean = pd.DataFrame(windowMean, columns = ['Slag mean window difference'])
test['Slag mean window difference'] = windowMean
test['On/Off'] = onOff

test["Phase A Slag tap block DT_water"].plot(marker = '*')
test['On/Off'].plot()
# test["Slag mean window difference"].plot(marker = 's')
    
#%% Identifying Tapping Regions method 

test2 = tappingData.copy()
test2 = test2[lowerBound:upperBound]

smoothTest2 = SimpleExpSmoothing(test2['Phase A Slag tap block DT_water'], initialization_method="heuristic").fit(
    smoothing_level=0.1, optimized=False)

peaks1, _ = find_peaks(test2['Phase A Slag tap block DT_water'], distance = 100)
peaks2, _ = find_peaks(-smoothTest2.fittedvalues, distance = 100, prominence = (0.01,3))
peaks3, _ = find_peaks(smoothTest2.fittedvalues, distance = 100, prominence = (0.01,3))

# windowSize = 20
# onOff = np.array([])
# windowTrack = np.array([])

# for i in range(0, len(test2), 1):
#     window = smoothTest2.fittedvalues[i:i+windowSize]
#     windowDelta = np.array(window.diff())
#     windowDelta = (windowDelta > 0)*1
    
#     if sum(windowDelta) >= 10:
#         onOff = np.append(onOff,1)
#     elif sum(windowDelta) < 10:
#         onOff =np.append(onOff,0)

# test2['onOff'] = onOff
test2['smooth'] = smoothTest2.fittedvalues
test2['diff'] = smoothTest2.fittedvalues.diff()
test2['onOff'] = (test2['diff'] > 0.004)*smoothTest2.fittedvalues #0.004 is a good choice - it picks up all the increases and no flat spots


# # plt.plot(test2['Phase A Slag tap block DT_water'], label = 'Original Data', marker = 's')
plt.plot(smoothTest2.fittedvalues, label = 'Smooth results', marker = '.')
# # plt.plot(test2["Phase A Slag tap block DT_water"].iloc[peaks1], label = "Orig peaks", color = 'red', marker = '*')
# plt.plot(smoothTest2.fittedvalues.iloc[peaks2], label = 'Smooth peaks', marker = 'd')
plt.plot(test2['onOff'])
plt.legend()

#%% Identifying tapping regions

tappingData = fullDF.loc[:,["Phase A Matte tap block 1 DT_water", "Phase A Matte tap block  DT_water",
"Phase A Slag tap block DT_water"]]

lowerBound = 100000
upperBound = 102000

test3 = tappingData.copy()
test3 = test3[lowerBound:upperBound]

smoothTest3 = SimpleExpSmoothing(test3['Phase A Slag tap block DT_water'], initialization_method="heuristic").fit(
    smoothing_level=0.1, optimized=False)

windowSize = 10
onOff = np.array([])
test3['diff'] = smoothTest3.fittedvalues.diff()
test3['onOff'] = ((test3['diff'] > 0.004)*1)
test3['onOff2'] = test3['onOff']

for i in range(windowSize, len(test3), 1):
    historical = sum(test3['onOff'][i-windowSize:i])
    future = sum(test3['onOff'][i+1:i+windowSize])
    
    if (test3['onOff'][i] == 0) and (historical > 1) and (future > 0):
        test3['onOff'][i] = 1
    
        
test3['onOff'] = test3['onOff'] +2.5
test3['onOff2'] = test3['onOff2'] +2.5
# plt.plot(test3["Phase A Slag tap block DT_water"], label = "Original Data")
plt.plot(smoothTest3.fittedvalues, label = 'Smooth results', marker = '.')
plt.plot(test3['onOff'], label = 'Tapping Classification Refined', marker = 's')
# plt.plot(((test3['diff']*5)+2.5), label = 'Gradient Data', marker = '.')
# plt.plot(test3['onOff2'], label = 'Tapping Classification', marker = '.')
plt.legend()

#%% Extract specific data

startTime = datetime.datetime(2021,1,1,5,37,0)
endTime = datetime.datetime(2021,1,1,6,17,0)

a = test3[startTime:endTime]
b = a['onOff']

for i in range(10,len(a), 1):
    window = a['onOff'][i-windowSize:i]
    
    if (sum(window[i-windowSize:i]) > 2):
        print(a['onOff'][i])
        a['onOff'][i] = 1
        print(a['onOff'][i])
        print('*******')
        
#%%  Matte tapping classification - data extraction and classification
start_time = time.time()

matteTap1 = tappingData.copy()

lowerBound = 0
upperBound = 1000

matteTap1 = matteTap1[lowerBound:upperBound]
# matteTap1Smooth = SimpleExpSmoothing(slagTap["Phase A Matte tap block  DT_water"], initialization_method="heuristic").fit(
#     smoothing_level=0.2, optimized=False)
# matteTap1["Smooth"] = matteTap1Smooth.fittedvalues
# Minvalue = abs(min(matteTap1["Phase A Matte tap block  DT_water"]))
# matteTap1["Normalized"] = matteTap1["Phase A Matte tap block  DT_water"]/Minvalue
matteTap1["Gradients"] = (((matteTap1["Phase A Matte tap block 1 DT_water"].diff())))
matteTap1["onOff"] = ((matteTap1["Gradients"] > 0)*1)
# matteTap1["onOff2"] = ((matteTap1["Gradients"] > 0.004)*matteTap1["Phase A Matte tap block  DT_water"])
checkpoint1 = time.time()

i = 0
length = np.array([])
lengthLarge = np.array([])
index = np.array([])
indexLarge = np.array([])

checkpoint2 = time.time()

for k, g in groupby(matteTap1["onOff"]):
    g = list(g)
    i = i + len(g)
    
    if (k == 1) and (len(g) < 3):
        length = np.append(length, len(g))
        index = np.append(index, i)
    elif (k == 1) and (len(g) >= 3):
        lengthLarge = np.append(lengthLarge, len(g))
        indexLarge = np.append(indexLarge, i)

checkpoint3 = time.time()

lengthLarge = lengthLarge.astype(int)
indexLarge = indexLarge.astype(int)
increases = np.array([])

checkpoint4 = time.time()
for i in range(0, len(lengthLarge), 1):
    increase = matteTap1["Phase A Matte tap block 1 DT_water"][indexLarge[i]] - matteTap1["Phase A Matte tap block 1 DT_water"][indexLarge[i]-lengthLarge[i]]
    increases = np.append(increases, increase)
    
    if (increase < 0.2):
        length = np.append(length, lengthLarge[i])
        index = np.append(index, indexLarge[i])

checkpoint5 = time.time()

# x = np.array([])
length = length.astype(int)     #Removing small increases
index = index.astype(int)

# Fast implementation method
alist = np.vstack(((index-length),index)).T
a = [np.arange(start,stop) for start,stop in alist]
indexList = np.array([])
for i in range(0,len(a)):
    indexList = np.append(indexList, a[i])
indexList = [int(x) for x in indexList]
matteTap1["onOff"].iloc[indexList] = 0

#slow implementation method - left in the code for reference purposes
# for i in range(0, len(length),1):
#     matteTap1["onOff"][index[i]-length[i]:index[i]] = 0
    
checkpoint6 = time.time()

print(" start-checkpoint1 = %s" % (checkpoint1 - start_time))
print(" checkpoint1-checkpoint2 = %s" % (checkpoint2 - checkpoint1))
print(" checkpoint2-checkpoint3 = %s" % (checkpoint3 - checkpoint2))
print(" checkpoint3-checkpoint4 = %s" % (checkpoint4 - checkpoint3))
print(" checkpoint4-checkpoint5 = %s" % (checkpoint5 - checkpoint4))
print(" checkpoint5-checkpoint6 = %s" % (checkpoint6 - checkpoint5))
print(" Total time = %s" % (checkpoint6-start_time))

plt.plot(matteTap1["Phase A Matte tap block 1 DT_water"], label = "Original Data")
# plt.plot(matteTap1["Smooth"], label = "Smooth")
# plt.plot(matteTap1["Normalized"], label = "Normalized")
# plt.plot(matteTap1["Gradients"], label = "Gradients Normalized")
plt.plot(matteTap1["onOff"], label = 'Tapping Classification', marker = '.')
# plt.plot(matteTap1["onOff2"], label = 'Tapping Classification 2', marker = '.')
plt.legend()

#%%  Slag tapping classification - data extraction and classification
start_time = time.time()
slagTap = tappingData.copy()

lowerBound = 0
upperBound = 2000

slagTap = tappingData.copy()
slagTap = slagTap[lowerBound:upperBound]

#exponential smoothing method
# slagTapSmooth = SimpleExpSmoothing(slagTap["Phase A Slag tap block DT_water"], initialization_method="heuristic").fit(
#     smoothing_level=0.3, optimized=False)
# slagTap["Smooth"] = slagTapSmooth.fittedvalues

checkpoint1 = time.time()
#Gustafsson method of filtering
# b, a = signal.ellip(4, 0.01, 120, 0.125)
# b, a = signal.butter(8, 0.125)
# slagTap["Smooth"] = signal.filtfilt(b, a, slagTap["Phase A Slag tap block DT_water"], method="gust")

checkpoint2 = time.time()
slagTap["Smooth"] = slagTap["Phase A Slag tap block DT_water"]
slagTap["Gradients"] = (((slagTap["Smooth"].diff())))
slagTap["onOff"] = ((slagTap["Gradients"] > 0)*1)

i = 0
length = np.array([])
lengthLarge = np.array([])
lengthSmall = np.array([])
index = np.array([])
indexLarge = np.array([])
indexSmall = np.array([])

checkpoint3 = time.time()
for k, g in groupby(slagTap["onOff"]):
    g = list(g)
    i = i + len(g)
    
    if (k == 1) and (len(g) < 2):
        length = np.append(length, len(g))
        index = np.append(index, i)
    elif (k == 1) and (len(g) >= 2):
        lengthLarge = np.append(lengthLarge, len(g))
        indexLarge = np.append(indexLarge, i)

checkpoint4 = time.time()        
lengthLarge = lengthLarge.astype(int)
indexLarge = indexLarge.astype(int)
increases = np.array([])
for i in range(0, len(lengthLarge), 1):
    increase = slagTap["Smooth"][indexLarge[i]-1] - slagTap["Smooth"][(indexLarge[i]-1)-(lengthLarge[i]-1)]
    increases = np.append(increases, increase)
    
    if (increase < 0.1):
        length = np.append(length, lengthLarge[i])
        index = np.append(index, indexLarge[i])

checkpoint5 = time.time()
length = length.astype(int)     #Removing small increases
index = index.astype(int)
for i in range(0, len(length),1):
    slagTap["onOff"][index[i]-length[i]:index[i]] = 0

checkpoint6 = time.time()
# for k, g in groupby(slagTap["onOff"]):
#     g = list(g)
#     i = i + len(g)
    
#     if (k == 0) and (len(g) <= 8):
#         lengthSmall = np.append(lengthSmall, len(g))
#         indexSmall = np.append(indexSmall, i)
    
# lengthSmall = lengthSmall.astype(int)
# indexSmall = indexSmall.astype(int)
# increases = np.array([])
# for i in range(0, len(lengthSmall), 1):
#     slagTap["onOff"][indexSmall[i]-lengthSmall[i]:indexSmall[i]] = 1

# print(" start-checkpoint1 = %s" % (checkpoint1 - start_time))
# print(" checkpoint1-checkpoint2 = %s" % (checkpoint2 - checkpoint1))
# print(" checkpoint2-checkpoint3 = %s" % (checkpoint3 - checkpoint2))
# print(" checkpoint3-checkpoint4 = %s" % (checkpoint4 - checkpoint3))
# print(" checkpoint4-checkpoint5 = %s" % (checkpoint5 - checkpoint4))
# print(" checkpoint5-checkpoint6 = %s" % (checkpoint6 - checkpoint5))
# print(" Total time = %s" % (checkpoint6-start_time))

slagTap["onOff"] = slagTap["onOff"] +2.5

plt.plot(slagTap["Phase A Slag tap block DT_water"], label = "Original Data", color = 'k', marker = ".")
# plt.plot(slagTap["Smooth"], label = "Original Data", color = 'b')
# plt.plot((slagTap["Gradients"])+2.5, marker = '.', label = "Gradient Data")
plt.plot(slagTap["onOff"], marker = ".", label = "Classification Data", color = 'r')
# plt.legend()

#%% Real Time implementation of slag tapping classification

slagTap = tappingData.copy()

lowerBound = 0
upperBound = 5700
currentStep = 5

slagTap = slagTap[lowerBound:upperBound]
slagTap["onOff"] = 0
slagTap["onOffFiltering"] = 0
slagTap["Smooth"] = 0
plt.plot(slagTap["Phase A Slag tap block DT_water"], label = "Original Data", color = 'k', marker = ".")

'''
Option 1 - determines if there is an increase between the current data point and data from 10 minutes in the past, 
if there is an increase in temp and the average trend of the data in the 10 minute window is positive then we classify 
as tapping 
'''

# for currentStep in range(lowerBound,upperBound):
    
#     difference = slagTap["Phase A Slag tap block DT_water"][currentStep] - slagTap["Phase A Slag tap block DT_water"][currentStep-15]
    
#     if difference > 0.1:
#         avgTrend = slagTap["Phase A Slag tap block DT_water"][currentStep-10:currentStep].diff().mean()
        
#         if avgTrend > 0:
#             slagTap["onOff"][currentStep] = 3

# plt.plot(slagTap["onOff"], marker = ".", label = "Classification Data", color = 'r')

'''
Option 2 - compares the current datapoint with the previous 3 data points. If the current temp is higher than the
last 3 points we classify as tapping. This algorithm is extremely sensitive
'''
# for currentStep in range(currentStep,upperBound):
#     difference2 = slagTap["Phase A Slag tap block DT_water"][currentStep] - slagTap["Phase A Slag tap block DT_water"][currentStep-2]
#     difference3 = slagTap["Phase A Slag tap block DT_water"][currentStep] - slagTap["Phase A Slag tap block DT_water"][currentStep-3]
#     difference4 = slagTap["Phase A Slag tap block DT_water"][currentStep] - slagTap["Phase A Slag tap block DT_water"][currentStep-4]
#     difference5 = slagTap["Phase A Slag tap block DT_water"][currentStep] - slagTap["Phase A Slag tap block DT_water"][currentStep-5]
    
#     if (difference2>0) and (difference3>0) and (difference4>0) and (difference5>0.05):
#         slagTap["onOff"][currentStep] = 3
        
# plt.plot(slagTap["onOff"], marker = ".", label = "Classification Data") #, color = 'g')

'''
Option 3 - This is the same as option 2 with the inclusion of a low pass filter
'''
currentStep = 5

for currentStep in range(currentStep,upperBound):
    b, a = signal.iirfilter(2, Wn=2.5, fs=30, btype="low", ftype="butter")
    slagTap["Smooth"][:currentStep+1] = signal.lfilter(b, a, slagTap["Phase A Slag tap block DT_water"][:currentStep+1])
    
    difference2 = slagTap["Smooth"][currentStep] - slagTap["Smooth"][currentStep-2]
    difference3 = slagTap["Smooth"][currentStep] - slagTap["Smooth"][currentStep-3]
    difference4 = slagTap["Smooth"][currentStep] - slagTap["Smooth"][currentStep-4]
    difference5 = slagTap["Smooth"][currentStep] - slagTap["Smooth"][currentStep-5]
    
    if (difference2>0) and (difference3>0.02) and (difference4>0.04) and (difference5>0.05):
        slagTap["onOffFiltering"][currentStep] = 3
        
plt.plot(slagTap["onOffFiltering"], marker = ".", label = "Classification Data with filtering", color = "m")
plt.plot(slagTap["Smooth"], marker = ".", label = "Filtered Data", color = 'b')
plt.legend()

'''
Option 4 - This is the algorithm that we originally implemented in the data class. It looks at historic data to smooth
out the classifications. In real-time it does not perform well, it successfully identifies tapping with a delay in time.
'''
# start_time = time.time()
# slagTap = tappingData.copy()

# lowerBound = 0
# upperBound = 80

# plt.plot(slagTap["Phase A Slag tap block DT_water"][0:2000], label = "Original Data", color = 'k', marker = ".")

# for upperBound in range(upperBound, 2000):
#     slagTap = tappingData.copy()
#     slagTap = slagTap[lowerBound:upperBound]
    
#     #exponential smoothing method
#     # slagTapSmooth = SimpleExpSmoothing(slagTap["Phase A Slag tap block DT_water"], initialization_method="heuristic").fit(
#     #     smoothing_level=0.3, optimized=False)
#     # slagTap["Smooth"] = slagTapSmooth.fittedvalues
    
#     checkpoint1 = time.time()
#     #Gustafsson method of filtering
#     # b, a = signal.ellip(4, 0.01, 120, 0.125)
#     # b, a = signal.butter(8, 0.125)
#     # slagTap["Smooth"] = signal.filtfilt(b, a, slagTap["Phase A Slag tap block DT_water"], method="gust")
    
#     checkpoint2 = time.time()
#     slagTap["Smooth"] = slagTap["Phase A Slag tap block DT_water"]
#     slagTap["Gradients"] = (((slagTap["Smooth"].diff())))
#     slagTap["onOff"] = ((slagTap["Gradients"] > 0)*1)
    
#     i = 0
#     length = np.array([])
#     lengthLarge = np.array([])
#     lengthSmall = np.array([])
#     index = np.array([])
#     indexLarge = np.array([])
#     indexSmall = np.array([])
    
#     checkpoint3 = time.time()
#     for k, g in groupby(slagTap["onOff"]):
#         g = list(g)
#         i = i + len(g)
        
#         if (k == 1) and (len(g) < 2):
#             length = np.append(length, len(g))
#             index = np.append(index, i)
#         elif (k == 1) and (len(g) >= 2):
#             lengthLarge = np.append(lengthLarge, len(g))
#             indexLarge = np.append(indexLarge, i)
    
#     checkpoint4 = time.time()        
#     lengthLarge = lengthLarge.astype(int)
#     indexLarge = indexLarge.astype(int)
#     increases = np.array([])
#     for i in range(0, len(lengthLarge), 1):
#         increase = slagTap["Smooth"][indexLarge[i]-1] - slagTap["Smooth"][(indexLarge[i]-1)-(lengthLarge[i]-1)]
#         increases = np.append(increases, increase)
        
#         if (increase < 0.1):
#             length = np.append(length, lengthLarge[i])
#             index = np.append(index, indexLarge[i])
    
#     checkpoint5 = time.time()
#     length = length.astype(int)     #Removing small increases
#     index = index.astype(int)
#     for i in range(0, len(length),1):
#         slagTap["onOff"][index[i]-length[i]:index[i]] = 0
    
#     checkpoint6 = time.time()
#     # for k, g in groupby(slagTap["onOff"]):
#     #     g = list(g)
#     #     i = i + len(g)
        
#     #     if (k == 0) and (len(g) <= 8):
#     #         lengthSmall = np.append(lengthSmall, len(g))
#     #         indexSmall = np.append(indexSmall, i)
        
#     # lengthSmall = lengthSmall.astype(int)
#     # indexSmall = indexSmall.astype(int)
#     # increases = np.array([])
#     # for i in range(0, len(lengthSmall), 1):
#     #     slagTap["onOff"][indexSmall[i]-lengthSmall[i]:indexSmall[i]] = 1
    
#     # print(" start-checkpoint1 = %s" % (checkpoint1 - start_time))
#     # print(" checkpoint1-checkpoint2 = %s" % (checkpoint2 - checkpoint1))
#     # print(" checkpoint2-checkpoint3 = %s" % (checkpoint3 - checkpoint2))
#     # print(" checkpoint3-checkpoint4 = %s" % (checkpoint4 - checkpoint3))
#     # print(" checkpoint4-checkpoint5 = %s" % (checkpoint5 - checkpoint4))
#     # print(" checkpoint5-checkpoint6 = %s" % (checkpoint6 - checkpoint5))
#     # print(" Total time = %s" % (checkpoint6-start_time))
    
#     slagTap["onOff"] = slagTap["onOff"] +2.5
    
#     # plt.plot(slagTap["Phase A Slag tap block DT_water"], label = "Original Data", color = 'k', marker = ".")
#     # plt.plot(slagTap["Smooth"], label = "Original Data", color = 'b')
#     # plt.plot((slagTap["Gradients"])+2.5, marker = '.', label = "Gradient Data")
#     plt.plot(slagTap["onOff"], marker = ".", label = "Classification Data", color = 'r')
# # plt.legend()

#%% Real Time implementation of matte tapping classification

matteTap = tappingData.copy()

lowerBound = 0
upperBound = 3000
currentStep = 5

matteTap = matteTap[lowerBound:upperBound]
matteTap["onOff Phase A Matte tap block 1 DT_water"] = 0
matteTap["onOff Phase A Matte tap block  DT_water"] = 0

figure, axis = plt.subplots(2,1)
axis[0].set_title("Matte tap block 1")
axis[0].plot(matteTap["Phase A Matte tap block 1 DT_water"], label = "Original Data", color = 'k', marker = ".")

for currentStep in range(currentStep,upperBound):
    difference2 = matteTap["Phase A Matte tap block 1 DT_water"][currentStep] - matteTap["Phase A Matte tap block 1 DT_water"][currentStep-2]
    difference3 = matteTap["Phase A Matte tap block 1 DT_water"][currentStep] - matteTap["Phase A Matte tap block 1 DT_water"][currentStep-3]
    difference4 = matteTap["Phase A Matte tap block 1 DT_water"][currentStep] - matteTap["Phase A Matte tap block 1 DT_water"][currentStep-4]
    difference5 = matteTap["Phase A Matte tap block 1 DT_water"][currentStep] - matteTap["Phase A Matte tap block 1 DT_water"][currentStep-5]
    
    if (difference2>0) and (difference3>0) and (difference4>0) and (difference5>0.1):
        matteTap["onOff Phase A Matte tap block 1 DT_water"][currentStep] = 3
        
axis[0].plot(matteTap["onOff Phase A Matte tap block 1 DT_water"], marker = ".", label = "Classification Data", color = 'g')


currentStep = 5
axis[1].set_title("Matte tap block 2")
axis[1].plot(matteTap["Phase A Matte tap block  DT_water"], label = "Original Data", color = 'k', marker = ".")

for currentStep in range(currentStep,upperBound):
    difference2 = matteTap["Phase A Matte tap block  DT_water"][currentStep] - matteTap["Phase A Matte tap block  DT_water"][currentStep-2]
    difference3 = matteTap["Phase A Matte tap block  DT_water"][currentStep] - matteTap["Phase A Matte tap block  DT_water"][currentStep-3]
    difference4 = matteTap["Phase A Matte tap block  DT_water"][currentStep] - matteTap["Phase A Matte tap block  DT_water"][currentStep-4]
    difference5 = matteTap["Phase A Matte tap block  DT_water"][currentStep] - matteTap["Phase A Matte tap block  DT_water"][currentStep-5]
    
    if (difference2>0) and (difference3>0) and (difference4>0) and (difference5>0.1):
        matteTap["onOff Phase A Matte tap block  DT_water"][currentStep] = 3
        
axis[1].plot(matteTap["onOff Phase A Matte tap block  DT_water"], marker = ".", label = "Classification Data", color = 'g')