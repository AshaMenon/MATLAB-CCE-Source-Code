# -*- coding: utf-8 -*-
"""
Created on Mon 28 Mar 2022

@author: Verushen Coopoo
"""

import pandas as pd
import src.NiSlagModellingHelpers as helpNiSlag
import src.preprocessingFunctions as prep

#%% Read in measurements
responseTags = ['Ni Slag']
highFrequencyPredictorTags = []
lowFrequencyPredictorTags = ['Matte temperatures','Basicity','Fe Matte']
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
#%% Poisson and polynomial feature modelling

# Read and format thermo Data
dataDir = prep.getDataPreferences()
thermoDF = pd.read_table(dataDir + "\\thermoDataNewCombinations_v2.csv",delimiter=';')

# Get model
thermoMdl, thermoMdlStats, X_test, y_test = helpNiSlag.trainThermoModel(thermoDF, False)

#%% 3D surfaces

#  Basicity

const1Name = 'Matte temperatures'
matteTempVals = [1150, 1350]
const2Name = 'PSO2'
PSO2Vals = [0.15, 0.15]
colors = ['midnightblue','lightseagreen','darkcyan','dodgerblue']
inputDict = {
                "yVarName" : 'Basicity',    
                "yvarBounds": (0,3),
                "const1Name" : const1Name,
                "const1Value" : matteTempVals,
                "const2Name" : const2Name,
                "const2Value" : PSO2Vals,
                "colors" : colors
              }

# Thermo model + measurements
helpNiSlag.plotSurface(inputDict, thermoMdl, measDF)  

#%% Temperatures

const1Name = 'Basicity'
basicityVals = [1.55, 2.05]
const2Name = 'PSO2'
PSO2Vals = [0.15, 0.15]
colors = ['lightcoral','darkred','lightsalmon','tomato']
inputDict = {
                "yVarName" : 'Matte temperatures',    
                "yvarBounds": (1000,1400),
                "const1Name" : const1Name,
                "const1Value" : basicityVals,
                "const2Name" : const2Name,
                "const2Value" : PSO2Vals,
                "colors" : colors
              }

# Thermo model + measurements
helpNiSlag.plotSurface(inputDict, thermoMdl, measDF)  

#%% 2D projections

# There are certain discrete, allowable values for the test values
testValsDict = {
                "T_test_val" : 1250,
                "B_test_val" : 1.75,
                "PSO2_test_val" : 0.15
                }

helpNiSlag.plot2DProjections(testValsDict, X_test, y_test, thermoMdl)