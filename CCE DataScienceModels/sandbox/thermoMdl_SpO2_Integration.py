# -*- coding: utf-8 -*-
"""
Created on Thu May  5 10:33:35 2022

@author: verushen.coopoo
"""

import preprocessingFunctions as prep
import NiSlagModellingHelpers as helpNiSlag
import pandas as pd
import numpy as np

#%% Build thermo model

# Read and format thermo Data
dataDir = prep.getDataPreferences()
thermoDF = pd.read_table(dataDir + "\\thermoDataNewCombinations_v2.csv",delimiter=';')

# Get model
thermoMdl, thermoMdlStats, _ , _ = helpNiSlag.trainThermoModel(thermoDF, False)

#%% Read in measurements
responseTags = ['Ni Slag']
highFrequencyPredictorTags = []
lowFrequencyPredictorTags = ['Matte temperatures','Basicity', 'Fe Matte']
predictorTags = lowFrequencyPredictorTags + highFrequencyPredictorTags

measDF_original = \
    prep.readAndFormatData(
        'Chemistry',
        responseTags=responseTags,
        predictorTags=predictorTags
    )
    
measDF_original = prep.preprocessingAndFeatureEngineering(measDF_original,
                                       removeTransientData = True,
                                       smoothBasicityResponse = True,
                                       addRollingSumPredictors = {'add': False, 'window': 30}, 
                                       addRollingMeanPredictors = {'add': False, 'window': 5},
                                       addMeasureIndicatorsAsPredictors = {'add': True, 'on': ['Fe Matte']}, 
                                       addShiftsToPredictors = {'add': False, 'nLags':3},
                                       addResponsesAsPredictors = {'add': False, 'nLags': 1},
                                       resampleTime = '1min',
                                       resampleMethod = 'cubic',
                                       predictorTags = predictorTags,
                                       responseTags = responseTags,
                                       highFrequencyPredictorTags = highFrequencyPredictorTags,
                                       lowFrequencyPredictorTags = lowFrequencyPredictorTags) 

measDF = measDF_original[0]
idx = measDF['Fe Matte Measure Indicator'] == 0
measDF = measDF[idx]

#%% Get Theoretical Ni

# Prepare input data
FeMatteTarget = 3.2
PSO2_const = 0.15
deadBand = 0
FeMatte = np.ones((len(measDF),1)) * FeMatteTarget
PSO2 = np.ones((len(measDF),1)) * PSO2_const

g = lambda x : np.expand_dims(x, axis = 1)
arr = np.column_stack((FeMatte, 
                       g(measDF['Basicity'].values), 
                       g(measDF['Matte temperatures'].values),
                       PSO2
                       ))

inputDF = pd.DataFrame(arr,columns=['Fe Matte','Basicity','Matte temperatures', 'PSO2'])

# Calculate corr Ni
predictedTheoreticalNiSlag = thermoMdl.predict(inputDF)

#%% Get SpO2 and generate curve

NiSlagTarget = 3

lowRangeCorrNi = predictedTheoreticalNiSlag[(predictedTheoreticalNiSlag <= NiSlagTarget)]
highRangeCorrNi = predictedTheoreticalNiSlag[(predictedTheoreticalNiSlag >= NiSlagTarget)]

# Get SpO2
lowRangeOxy, highRangeOxy = helpNiSlag.getSpO2(NiSlagTarget, deadBand,
                                               lowRangeCorrNi, highRangeCorrNi)

# Plot figure
helpNiSlag.plotSpO2Curve(lowRangeCorrNi, lowRangeOxy, highRangeCorrNi, highRangeOxy)