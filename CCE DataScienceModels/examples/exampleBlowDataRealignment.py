# -*- coding: utf-8 -*-
"""
Created on Fri Mar 31 11:18:26 2023

@author: john.atherfold
"""

import pandas as pd
import numpy as np
import datetime
import matplotlib.pyplot as plt

import Shared.DSModel.src.preprocessingFunctions as prep
import Shared.DSModel.src.featureEngineeringHelpers as featEng

#%% Example using realignment of data with Blows
#%% Read and Format Data

highFreqPredictors = ["Fe Matte"]

lowFreqPredictors = ["Slag temperatures"]# "Cr2O3 Slag", "Basicity", "MgO Slag"]#, 

feedblendPredictors = ["Cu Feedblend", "Ni Feedblend",
                       "Co Feedblend", "Fe Feedblend", "S Feedblend",
                       "SiO2 Feedblend", "Al2O3 Feedblend", "CaO Feedblend",
                       "MgO Feedblend", "Cr2O3 Feedblend"]
referenceTags = ["Converter mode", "Lance air and oxygen control"]
# lowFreqPredictors = lowFreqPredictors + feedblendPredictors

predictorTags = highFreqPredictors + lowFreqPredictors

responseTags = ['Basicity']

fullDFOrig = prep.readAndFormatData('Chemistry')

#%% Data Cleaning and Specific Latent Feature Generation
def processingFunc(fullDFOrig):
    fullDF, origSmoothedResponses, predictorTagsNew = \
        prep.preprocessingAndFeatureEngineering(
            fullDFOrig,
            removeTransientData=True,
            smoothBasicityResponse=False,
            addRollingSumPredictors={'add': False, 'window': '19min'}, #NOTE: functionality exists to process an 'on' key
            addRollingMeanPredictors={'add': False, 'window': '5min'},
            addRollingMeanResponse={'add': False, 'window': '60min'},
            addDifferenceResponse = {'add': False},
            addMeasureIndicatorsAsPredictors={'add': False, 'on': ['Basicity', 'Fe Feedblend', 'Matte temperatures']}, #NOTE: functionality exists to process an 'on' key
            addShiftsToPredictors={'add': False, 'nLags': 3, 'on': highFreqPredictors},
            addResponsesAsPredictors={'add': False, 'nLags': 1},
            smoothTagsOnChange = {'add': False, 'on': ['Specific Silica Actual PV'], 'threshold': [70]},
            hoursOff = 8,
            nPeaksOff = 3,
            resampleTime = '1min',
            resampleMethod = 'zero',
            responseTags=responseTags,
            predictorTags=predictorTags,
            referenceTags=referenceTags,
            highFrequencyPredictorTags = highFreqPredictors,
            lowFrequencyPredictorTags = lowFreqPredictors)
    return fullDF, origSmoothedResponses, predictorTagsNew

fullDF, origSmoothedResponses, predictorTagsNew = processingFunc(fullDFOrig)

#%% Definining Data for Realignment

startTime = pd.Timestamp('2021-01-01 00:00')
endTime = pd.Timestamp('2021-09-08 00:00')
mask = (fullDF.index >= startTime) & (fullDF.index <= endTime)
fullDF = fullDF.loc[mask]

# Reassigning Matte Temps
blowTimes = fullDF[fullDF['Peaks']==True].index
measurementChanges, _ = featEng.getUniqueDataPoints(fullDF["Fe Matte"])
newTimes, newMeasurements = featEng.reassignTimestamps(blowTimes, measurementChanges)
alignedMeasurements = pd.Series(data = newMeasurements, index = newTimes)

resampledFeMatte = featEng.resampleFeMatte(blowTimes, alignedMeasurements)

#%% Plotting

ax1 = plt.subplot(2,1,1)
fullDF["Lance air and oxygen control"].plot(ax=ax1)
ax1.set_ylabel('Lance Air and Oxygen Control')
plt.vlines(blowTimes, 0, max(fullDF["Lance air and oxygen control"]), color = 'k', lw = 0.5)

ax2 = plt.subplot(2,1,2, sharex=ax1)
measurementChanges.plot(style='o-', ax=ax2)
resampledFeMatte.plot(style='*-', ax=ax2)
ax2.set_ylabel('Fe Matte')
ax2.legend(['Original value', 'Aligned with Blow Time'])
plt.vlines(blowTimes, 0, max(measurementChanges), color = 'k', lw = 0.5)

