# -*- coding: utf-8 -*-
"""
Created on Tue May 10 07:28:58 2022

@author: verushen.coopoo
"""

import pandas as pd
import src.NiSlagModellingHelpers as helpNiSlag
import src.SpO2ModellingHelpers as helpSpO2
import numpy as np
import numpy.matlib
import datetime
import examples.exampleMatteTempModellingLinearModelPipeline as matteTempMdl
import examples.exampleBasicityModellingLinearModelPipeline as basicityMdl
import src.preprocessingFunctions as prep

# Get temperature predictions and start-end points
tempPredict = matteTempMdl.testResults.yHat.to_frame()
tempDates_npdt64 = tempPredict.index.values
convertDate = lambda x : datetime.datetime.utcfromtimestamp(x.tolist()/1e9)
tempStart = convertDate(tempDates_npdt64[0]) 
tempEnd = convertDate(tempDates_npdt64[-1]) 

#%% Read in and preprocess measurements

measDF, groundTruthCorrNiSlag, FeMatte = helpSpO2.preprocessDataForSpO2Modelling()

#%% Poisson and polynomial feature modelling

# Read and format thermo Data
dataDir = prep.getDataPreferences()
thermoDF = pd.read_table(dataDir + "\\thermoDataNewCombinations_v2.csv",delimiter=';')

# Get model
writeTermsToSpreadsheet = False
refitModel = False # Set to true to retrain thermo model
thermoMdl, thermoMdlStats, X_test, y_test = helpNiSlag.trainThermoModel(
    thermoDF, writeTermsToSpreadsheet, refitModel)
#%% (0) Use of specific oxygen model

# Demonstrates how SpO2 model is used without generating any plots

NiSlagTarget = 3.2
deadBand = 0
measDF['required_SpO2_change'] = np.ones((len(measDF),1))
for i in range(0, len(measDF)):
    measDF['required_SpO2_change'][i] = helpSpO2.applySpO2Model(measDF['Matte temperatures'][i], 
                                          measDF['Basicity'][i], 
                                          measDF['Corrected Ni Slag'][i],
                                          deadBand, 
                                          thermoMdl)


#%% (1) Base case =======================================================================================================================================================

measDF['Corrected Ni Slag'] = groundTruthCorrNiSlag.values
NiSlagTarget = 3.2
deadBand = 0

mainTitle = '(1): Measured temperature + measured basicity + current Ni slag correction'

measDF2, timeDiffs, operatorVsDynamic, shapeTable = \
helpSpO2.applyAndValidateSpO2ModelWithMeasurements(measDF, NiSlagTarget, 
                                                   deadBand, thermoMdl)

helpSpO2.plotTimeSeriesAndDistributionsForValidation(
    measDF2.loc[tempStart : tempEnd], 
    operatorVsDynamic.loc[tempStart : tempEnd], 
    FeMatte.loc[tempStart : tempEnd], mainTitle)

#%% (2) With model temperatures ========================================================================================================================================

# Get predicted temperatures
tempPredict = matteTempMdl.testResults.yHat.to_frame()
measDF['Corrected Ni Slag'] = groundTruthCorrNiSlag.values

# Resample basicity and corr Ni Slag appropriately (to plot with temperature model)
measDF_subset = measDF.loc[tempStart : tempEnd]

newindex = tempPredict.index.union(measDF_subset.index)
tempPredict = tempPredict.reindex(newindex).dropna()
measDF_subset = measDF_subset.reindex(newindex)

kwargs = {'Basicity' : measDF_subset['Basicity'],
          'Corrected Ni Slag' : measDF_subset['Corrected Ni Slag'],
          'Specific Oxygen Operator SP (SP1)' : measDF_subset['Specific Oxygen Operator SP (SP1)'],
          'Matte temperatures' : tempPredict['yHat'],
          'S Slag' : measDF_subset['S Slag'],
          'Fe Matte' : measDF_subset['Fe Matte'].dropna()}

# Create new dataframe specifcally for this task (with predicted temperatures)
measDF_tempPred = pd.DataFrame().assign(**kwargs)
measDF_tempPred['Corrected Ni Slag'].fillna(method = 'ffill', inplace = True)
measDF_tempPred['Basicity'].fillna(method = 'ffill', inplace = True)
measDF_tempPred['S Slag'].fillna(method = 'ffill', inplace = True)
measDF_tempPred['Fe Matte'].fillna(method = 'ffill', inplace = True)
measDF_tempPred['Matte temperatures'].fillna(method = 'ffill', inplace = True)

measDF_tempPred = measDF_tempPred.dropna()
mainTitle = '(2):  Predicted temperatures + measured basicity + current Ni slag correction'
NiSlagTarget = 3.2
deadBand = 0

measDF2, _, operatorVsDynamic, _ = \
helpSpO2.applyAndValidateSpO2ModelWithMeasurements(measDF_tempPred, NiSlagTarget, 
                                                   deadBand, thermoMdl)

helpSpO2.plotTimeSeriesAndDistributionsForValidation(
    measDF2.loc[tempStart : tempEnd], 
    operatorVsDynamic.loc[tempStart : tempEnd], 
    FeMatte.loc[tempStart : tempEnd], mainTitle)

#%% (3) Model temps + new corrected Ni Slag==============================================================================================================================

subtractionParam = 0.2
multiplierParam = 1.85
thresholdParam = 0.8
measDF['Corrected Ni Slag'] = helpNiSlag.calculateCorrNiSlag(
    measDF['Ni Slag'], measDF['S Slag'], subtractionParam, multiplierParam,
    thresholdParam)
measDF_subset = measDF.loc[tempStart : tempEnd]
tempPredict = matteTempMdl.testResults.yHat.to_frame()

# Resample basicity and corr Ni Slag appropriately (to plot with temperature model)
# --> done in previous sections

newindex = tempPredict.index.union(measDF_subset.index)
tempPredict = tempPredict.reindex(newindex).dropna()
measDF_subset = measDF_subset.reindex(newindex)

kwargs = {'Basicity' : measDF_subset['Basicity'],
          'Corrected Ni Slag' : measDF_subset['Corrected Ni Slag'],
          'Specific Oxygen Operator SP (SP1)' : measDF_subset['Specific Oxygen Operator SP (SP1)'],
          'Matte temperatures' : tempPredict['yHat'],
          'S Slag' : measDF_subset['S Slag'],
          'Fe Matte' : measDF_subset['Fe Matte'].dropna()}

# Create new dataframe specifcally for this task (with predicted temperatures)
measDF_tempPred = pd.DataFrame().assign(**kwargs)
measDF_tempPred['Corrected Ni Slag'].fillna(method = 'ffill', inplace = True)
measDF_tempPred['Basicity'].fillna(method = 'ffill', inplace = True)
measDF_tempPred['S Slag'].fillna(method = 'ffill', inplace = True)
measDF_tempPred['Fe Matte'].fillna(method = 'ffill', inplace = True)
measDF_tempPred['Matte temperatures'].fillna(method = 'ffill', inplace = True)

measDF_tempPred = measDF_tempPred.dropna()

NiSlagTarget = 3.2
deadBand = 0
mainTitle = ("(3): Predicted temperatures + measured basicity + updated Ni correction")

measDF2, _, operatorVsDynamic, _ = \
helpSpO2.applyAndValidateSpO2ModelWithMeasurements(measDF_tempPred, NiSlagTarget, 
                                                   deadBand, thermoMdl)

helpSpO2.plotTimeSeriesAndDistributionsForValidation(
    measDF2.loc[tempStart : tempEnd], 
    operatorVsDynamic.loc[tempStart : tempEnd], 
    FeMatte.loc[tempStart : tempEnd], mainTitle)

#%% (4) Measured temperature + measured basicity + updated Ni correction ====================================================================================================================

subtractionParam = 0.2
multiplierParam = 1.85
thresholdParam = 0.8
measDF['Corrected Ni Slag'] = helpNiSlag.calculateCorrNiSlag(
    measDF['Ni Slag'], measDF['S Slag'], subtractionParam, multiplierParam,
    thresholdParam)

NiSlagTarget = 3.2
deadBand = 0
mainTitle = ("(4): Measured temperature + measured basicity + updated Ni correction")

measDF2, timeDiffs, operatorVsDynamic, shapeTable = \
helpSpO2.applyAndValidateSpO2ModelWithMeasurements(measDF, NiSlagTarget, 
                                                   deadBand, thermoMdl)

helpSpO2.plotTimeSeriesAndDistributionsForValidation(
    measDF2.loc[tempStart : tempEnd], 
    operatorVsDynamic.loc[tempStart : tempEnd], 
    FeMatte.loc[tempStart : tempEnd], mainTitle)

#%% (5) T (model) + B (model) + Updated Ni Slag correction ==============================================================================================================

NiSlagTarget = 3.2
deadBand = 0

subtractionParam = 0.2
multiplierParam = 1.85
thresholdParam = 0.8
measDF['Corrected Ni Slag'] = helpNiSlag.calculateCorrNiSlag(
    measDF['Ni Slag'], measDF['S Slag'], subtractionParam, multiplierParam,
    thresholdParam)

tempPredict = matteTempMdl.testResults.yHat.to_frame()
basicityPredict = basicityMdl.testResults.yHat.to_frame()

tempPredict.rename(columns = {'yHat' : 'predictedTemp'}, inplace = True)
basicityPredict.rename(columns = {'yHat' : 'predictedBasicity'}, inplace = True)

kwargs = {'Basicity' : basicityPredict['predictedBasicity'],
          'Corrected Ni Slag' : measDF['Corrected Ni Slag'],
          'Specific Oxygen Operator SP (SP1)' : measDF['Specific Oxygen Operator SP (SP1)'],
          'Matte temperatures' : tempPredict['predictedTemp'],
          'S Slag' : measDF['S Slag'],
          'Fe Matte' : measDF['Fe Matte'].dropna()}

# Create new dataframe specifcally for this task (with predicted temperatures)
finalDF = pd.DataFrame().assign(**kwargs).ffill(axis=0).dropna()

mainTitle = ("(5): Predicted temperatures + predicted basicity + updated Ni correction")

finalDF2, _, operatorVsDynamic, _ = \
helpSpO2.applyAndValidateSpO2ModelWithMeasurements(finalDF, NiSlagTarget, 
                                                   deadBand, thermoMdl)

'''
Note that there are lots of zeros in the blue distribution
This is because the oberservations are forward filled
There are many samples in the basicity model since it predicts minutely
'''

helpSpO2.plotTimeSeriesAndDistributionsForValidation(
    finalDF2.loc[tempStart : tempEnd], 
    operatorVsDynamic.loc[tempStart : tempEnd], 
    FeMatte.loc[tempStart : tempEnd], mainTitle)

#%% 2D validations with theoretical Ni Slag - with random numbers

nCurves = 12
basicityBounds = [1.55, 2.05]
temperatureBounds =[1150, 1350]
newArrayLength = len(measDF)
setFeMatteTarget = False

helpNiSlag.plot2DValidationWithRandomNumbers(nCurves, basicityBounds, temperatureBounds,
                                  thermoMdl, setFeMatteTarget, newArrayLength)

#%% 2D validations with theoretical Ni Slag - superimposed with thermo polynomials

basicityVals = [1.55, 1.75, 2.05]
tempVals = [1150, 1250, 1350]

helpNiSlag.plot2DValidationWithPolynomialModel(thermoDF, basicityVals, tempVals, 
                                      thermoMdl, setFeMatteTarget, newArrayLength)