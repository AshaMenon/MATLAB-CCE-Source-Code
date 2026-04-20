# -*- coding: utf-8 -*-
"""
Created on Thu Oct  7 11:31:38 2021

@author: john.atherfold
"""

import pandas as pd
import numpy as np
import scipy.signal as sp
import datetime
from Shared.DSModel.src import featureEngineeringHelpers as feh
import os
from sklearn.decomposition import PCA

def filterExpectedDataRange(data, low, high):
    filteredData = np.where(~data.between(low, high), np.nan, data)
    return filteredData

def restrictData(columnNames):
    operatingRangeDict = dict.fromkeys(columnNames,(-1000000, 1000000))
    operatingRangeDict["Cu Slag"] = (0.1, 25)
    operatingRangeDict["Ni Slag"] = (0.2, 30)
    operatingRangeDict["Corrected Ni Slag"] = (0.5, 10)
    operatingRangeDict["Co Slag"] = (0, 10)
    operatingRangeDict["Fe Slag"] = (20, 60)
    operatingRangeDict["S Slag"] = (0.1, 20)
    operatingRangeDict["Al2O3 Slag"] = (0.5, 6)
    operatingRangeDict["CaO Slag"] = (0.2, 3)
    operatingRangeDict["MgO Slag"] = (0.1, 2)
    operatingRangeDict["Cr2O3 Slag"] = (0.1, 10)
    operatingRangeDict["SiO2 Slag"] = (0.1, 60) # check 
    operatingRangeDict["Basicity"] = (1.1, 2.5)
    operatingRangeDict["Cu Matte"] = (20, 40)
    operatingRangeDict["Ni Matte"] = (30, 50)
    operatingRangeDict["Co Matte"] = (0.05, 1.0)
    operatingRangeDict["Fe Matte"] = (0, 20)
    operatingRangeDict["S Matte"] = (5, 35)
    operatingRangeDict['Specific Oxygen Actual PV'] = (0, 10000)
    operatingRangeDict['Specific Silica Actual PV'] = (0, 300)
    operatingRangeDict["Matte feed PV(unfiltered)"] = (0, 150)
    operatingRangeDict["Lance air flow rate PV"] = (0, 30000)
    operatingRangeDict["Lance air flow rate SP"] = (0, 30000)
    operatingRangeDict["Lance oxygen flow rate PV"] = (0, 10000)
    operatingRangeDict["Lance oxygen flow rate SP"] = (0, 10000)
    operatingRangeDict["Shroud air flow rate PV"] = (0, 14000)
    operatingRangeDict["Shroud air flow rate SP"] = (0, 14000)
    operatingRangeDict["Shroud oxygen flow rate PV"] = (0, 3000)
    operatingRangeDict["Shroud oxygen flow rate SP"] = (0, 3000)
    operatingRangeDict["Standby system coal transfer air pressure"] = (0, 30)
    operatingRangeDict["Motion"] = (0, 10)
    operatingRangeDict["Lance foam potential"] = (-20, 20)
    operatingRangeDict["Trolley foam potential"] = (-5, 5)
    operatingRangeDict["Slag mass flow"] = (0, 10)
    operatingRangeDict["Matte temperatures"] = (1175, 1300)
    operatingRangeDict["Slag temperatures"] = (1000, 1600)
    operatingRangeDict["Lance height"] = (0, 4000)
    operatingRangeDict["Fe in mould (per blow)"] = (0, 20)
    operatingRangeDict["Ni Feedblend"] = (1, 30)
    operatingRangeDict["Cu Feedblend"] = (6, 15)
    operatingRangeDict["Co Feedblend"] = (0, 10)
    operatingRangeDict["MgO Feedblend"] = (0, 10)
    operatingRangeDict["CaO Feedblend"] = (0, 10)
    operatingRangeDict["Al2O3 Feedblend"] = (0, 10)
    operatingRangeDict["Fe Feedblend"] = (20, 50)
    operatingRangeDict["S Feedblend"] = (5, 40)
    operatingRangeDict["SiO2 Feedblend"] = (0.5, 40)
    operatingRangeDict["Cr2O3 Feedblend"] = (0, 10)
    operatingRangeDict["% Vapour"] = (0.1, 20)
    operatingRangeDict["Lance feed PV"] = (0, 20)
    operatingRangeDict["Lump Coal SP"] = (0, 25)
    operatingRangeDict["Matte feed SP"] = (0, 60)
    operatingRangeDict["Matte feed PV filtered"] = (0, 60)
    operatingRangeDict["Roof feed PV"] = (0, 20)
    operatingRangeDict["Roof coal transfer air pressure"] = (0, 500)
    operatingRangeDict["Acid plant damper position"] = (0,50)
    operatingRangeDict["Blower 222"] = (50,100)
    operatingRangeDict["Blower 221"] = (50,100)
    operatingRangeDict["Lance Oxy Enrich % PV"] = (-1000,1000)
    operatingRangeDict["O2_SO2 Ratio 1"] = (0,45)
    operatingRangeDict["O2_SO2 Ratio 2"] = (0,45)
    operatingRangeDict["Roof Coal feed PV"] = (0,100)
    operatingRangeDict["Fuel coal feed rate PV"] = (0,100)
    operatingRangeDict["Lower waffle 19"] = (-20, 150)
    operatingRangeDict["Lower waffle 20"] = (-20, 150)
    operatingRangeDict["Lower waffle 21"] = (-20, 150)
    operatingRangeDict["Lower waffle 22"] = (-20, 150)
    operatingRangeDict["Lower waffle 23"] = (-20, 150)
    operatingRangeDict["Lower waffle 24"] = (-20, 150)
    operatingRangeDict["Lower waffle 25"] = (-20, 150)
    operatingRangeDict["Lower waffle 26"] = (-20, 150)
    operatingRangeDict["Lower waffle 27"] = (-20, 150)
    operatingRangeDict["Lower waffle 28"] = (-20, 150)
    operatingRangeDict["Lower waffle 29"] = (-20, 150)
    operatingRangeDict["Lower waffle 30"] = (-20, 150)
    operatingRangeDict["Lower waffle 31"] = (-20, 150)
    operatingRangeDict["Lower waffle 32"] = (-20, 150)
    operatingRangeDict["Lower waffle 33"] = (-20, 150)
    operatingRangeDict["Lower waffle 34"] = (-20, 150)
    operatingRangeDict["SpO2 PV"] = (0, 400)
    return operatingRangeDict

def readAndFormatData(subModel):
    # Performs the entire reading and filtering workflow - neater than calling
    #   same block of code over and over
    fullDF = readData(subModel)
    fullDF = formatData(fullDF)

    return fullDF

def readData(subModel):
    dataDir = getDataPreferences()

    # Read in Raw Data
    if subModel == "Chemistry":
        janMarDF = pd.read_csv(dataDir + '\\ChemistryModel\\chemistryData_Jan-Mar-21_v9.csv')
        aprJunDF = pd.read_csv(dataDir + '\\ChemistryModel\\chemistryData_Apr-Jun-21_v9.csv')
        julSepDF = pd.read_csv(dataDir + '\\/ChemistryModel\\chemistryData_Jul-Sep-21_v9.csv')
        octDecDF = pd.read_csv(dataDir + '\\ChemistryModel\\chemistryData_Oct-Dec-21_v9.csv')
        fullDF = pd.concat([janMarDF, aprJunDF, julSepDF, octDecDF])
    elif subModel == "Temperature":
        janMarDF = pd.read_csv(dataDir + '\\TemperatureModel\\temperatureData_Jan-Mar-21_v9.csv')
        aprJunDF = pd.read_csv(dataDir + '\\TemperatureModel\\temperatureData_Apr-Jun-21_v9.csv')
        julSepDF = pd.read_csv(dataDir + '\\TemperatureModel\\temperatureData_Jul-Sep-21_v9.csv')
        octDecDF = pd.read_csv(dataDir + '\\TemperatureModel\\temperatureData_Oct-Dec-21_v9.csv')
        fullDF = pd.concat([janMarDF, aprJunDF, julSepDF, octDecDF])
    elif subModel == "Chemistry2022":
        janMarDF = pd.read_csv(dataDir + '\\ChemistryModel\\chemistryData_Jan-Mar-22_v1.csv', sep = ';')
        aprJunDF = pd.read_csv(dataDir + '\\ChemistryModel\\chemistryData_Apr-Jun-22_v1.csv', sep = ';')
        julSepDF = pd.read_csv(dataDir + '\\/ChemistryModel\\chemistryData_Jul-Aug-22_v1.csv', sep = ';')
        octNovDF = pd.read_csv(dataDir + '\\/ChemistryModel\\chemistryData_Oct-Nov-22_v1.csv')
        fullDF = pd.concat([janMarDF, aprJunDF, julSepDF, octNovDF])
    elif subModel == "Chemistry2023":
        janMarDF = pd.read_csv(dataDir + '\\ChemistryModel\\chemistryData_Jan-Mar-23_v2.csv')
        aprJunDF = pd.read_csv(dataDir + '\\ChemistryModel\\chemistryData_Apr-Jun-23_v1.csv')
        fullDF = pd.concat([janMarDF, aprJunDF])
    elif subModel == "sept22Chemistry":
        fullDF = pd.read_csv(dataDir + '\\ChemistryModel\\chemistryData_Sep-Oct-22.csv')
    elif subModel == "oct22Chemistry":
        fullDF = pd.read_csv(dataDir + '\\ChemistryModel\\chemistryData_Oct_22.csv')
    elif subModel == "Chemistry2020":
        janMarDF = pd.read_csv(dataDir + '\\ChemistryModel\\chemistryData_Jan-Mar-20_v8.csv')
        aprJunDF = pd.read_csv(dataDir + '\\ChemistryModel\\chemistryData_Apr-Jun-20_v8.csv')
        julSepDF = pd.read_csv(dataDir + '\\/ChemistryModel\\chemistryData_Jul-Sep-20_v8.csv')
        octDecDF = pd.read_csv(dataDir + '\\ChemistryModel\\chemistryData_Oct-Dec-20_v8.csv')
        fullDF = pd.concat([janMarDF, aprJunDF, julSepDF, octDecDF])
    return fullDF

def formatData(fullDF):
    fullDF = fullDF.drop_duplicates()
    fullDF = fullDF.set_index('Timestamp')
    fullDF.index = pd.to_datetime(fullDF.index) #, format="%d-%b-%y  %H:%M:%S")
    fullDF = fullDF[~fullDF.index.duplicated(keep='first')]
    
    # Replace known bad and missing values
    fullDF = fullDF.replace("Bad", np.nan)
    fullDF = fullDF.replace("No Data", np.nan)
    fullDF = fullDF.replace("Tag not found", np.nan)
    fullDF = fullDF.replace("Not Connect", np.nan)
    fullDF = fullDF.replace("Resize to show all values", np.nan)
    fullDF = fullDF.replace("[-10722] PINET: Timeout on PI RPC or System Call.", np.nan)
    fullDF = fullDF.replace(" ", np.nan)
    fullDF = fullDF.replace("Configure", np.nan)
    fullDF = fullDF.replace("Pt Created", np.nan)
    fullDF = fullDF.apply(pd.to_numeric)
    
    #Select necessary tags only
    fullDF = feh.getSumOfSpecies(fullDF)
    return fullDF

def getDataPreferences():
    if 'data' in os.listdir(os.getcwd()):
        dataDir = os.getcwd() + '\\data'
    elif 'data' in os.listdir(os.path.dirname(os.getcwd())):
        dataDir = os.path.dirname(os.getcwd()) + '\\data'
    else:
        raise Exception('data folder cannot be found in ' + os.getcwd() + ' or ' + \
                        os.path.dirname(os.getcwd()))
    return dataDir

def preprocessingAndFeatureEngineering(fullDF,
                                       removeTransientData = True,
                                       smoothBasicityResponse = False,
                                       addRollingSumPredictors = {'add': False, 'window': 30}, #NOTE: functionality exists to process an 'on' key
                                       addRollingMeanPredictors = {'add': False, 'window': 5},
                                       addRollingMeanResponse = {'add': False, 'window': 5},
                                       addDifferenceResponse = {'add': False},
                                       addMeasureIndicatorsAsPredictors = {'add': False}, #NOTE: functionality exists to process an 'on' key
                                       addShiftsToPredictors = {'add': True, 'nLags':3},
                                       addResponsesAsPredictors = {'add': False, 'nLags': 1},
                                       smoothTagsOnChange = {'add': False}, #NOTE: Requires additional 2 arguments, ON: <Tag Names>, and THRESHOLD: <% allowable change>
                                       resampleTime = '1min',
                                       resampleMethod = 'linear',
                                       predictorTags = None,
                                       responseTags = None,
                                       hoursOff = 1,
                                       nPeaksOff = 3,
                                       referenceTags=[],
                                       highFrequencyPredictorTags = [],
                                       lowFrequencyPredictorTags = []):

    fullDF = fullDF[set(predictorTags + responseTags + referenceTags + highFrequencyPredictorTags + lowFrequencyPredictorTags)]
    
    # Smooth Tags on Change - Smooths tags based on % change instead of absolte threshold
    if smoothTagsOnChange['add']:
        if 'on' in addMeasureIndicatorsAsPredictors.keys():
            fullDF = feh.smoothTagsOnChange(fullDF, smoothTagsOnChange['on'],
                                            smoothTagsOnChange['threshold'])
        else:
            raise Exception('Specify which tags to filter on change.')
    
    # Replace data outside operating range
    operatingRangeDict = restrictData(fullDF.columns)
    for column in fullDF.columns:
        fullDF[column] = filterExpectedDataRange(fullDF[column],
                                                 operatingRangeDict[column][0],
                                                 operatingRangeDict[column][1])

    predictorTagsNew = predictorTags.copy()
    # Add steady-state signal
    fullDF = feh.addSteadyStateSignal(fullDF, hoursOff, nPeaksOff, responseTags)  # mode8 inactive for >1 hour = offPeriod
    
    # Remove transient data
    if removeTransientData:
        fullDF = feh.removeTransientData(fullDF)
    
    # Add indicator to indicate when last measurement was taken. The units are minutes
    if addMeasureIndicatorsAsPredictors['add']:
        if 'on' in addMeasureIndicatorsAsPredictors.keys():
            fullDF, measureIndicatorTags = \
                feh.addMeasureIndicatorsAsPredictors(fullDF, predictorTags,
                                                     on=addMeasureIndicatorsAsPredictors['on'])
        else:
            fullDF, measureIndicatorTags = \
                feh.addMeasureIndicatorsAsPredictors(fullDF, predictorTags)    
        predictorTagsNew = predictorTagsNew + measureIndicatorTags
    
    # Smooth Basicity according to last measurement and sum of species
    if smoothBasicityResponse:
        fullDF = feh.smoothBasicityResponse(fullDF)
    
    # Add rolling sum columns as additional predictors. The units of "window" is minutes.
    if addRollingSumPredictors['add']:
        if 'on' in addRollingSumPredictors.keys():
            # Adds a rolling sum on the specified predictors
            fullDF, predictorTagsSums = feh.addRollingSumPredictors(
                fullDF, addRollingSumPredictors['on'], addRollingSumPredictors['window'])
        else:
            # Adds a rolling sum on all predictors
            fullDF, predictorTagsSums = feh.addRollingSumPredictors(
                fullDF, predictorTags, addRollingSumPredictors['window'])
        predictorTagsNew = predictorTagsNew + predictorTagsSums
    
    # Add rolling mean columns as additional predictors. The units of "window" is minutes.
    if addRollingMeanPredictors['add']:
        if 'on' in addRollingMeanPredictors.keys():
            # Adds a rolling mean on the specified predictors
            fullDF, predictorTagsMeans = feh.addRollingMeanPredictors(
                fullDF, addRollingMeanPredictors['on'], addRollingMeanPredictors['window'])
        else:
            # Adds a rolling mean on all predictors
            fullDF, predictorTagsMeans = feh.addRollingMeanPredictors(
                fullDF, predictorTags, addRollingMeanPredictors['window'])
        predictorTagsNew = predictorTagsNew + predictorTagsMeans
    
    # Store original responses (no resampling)
    origSmoothedResponses, _ = feh.getUniqueDataPoints(fullDF[responseTags].dropna())
    
    # Add rolling mean of response as an additional predictor
    if addRollingMeanResponse['add']:
        fullDF, responseMovingAverageTag = feh.addRollingMeanResponse(
            fullDF, origSmoothedResponses, responseTags, addRollingMeanResponse['window'])
        predictorTagsNew = predictorTagsNew + responseMovingAverageTag
    
    # Resample to required Sample Time and with required Sample Method
    fullDF[highFrequencyPredictorTags] = fullDF[highFrequencyPredictorTags].resample(resampleTime, label='right', closed='right').last()
    if lowFrequencyPredictorTags is not None:
        fullDF[lowFrequencyPredictorTags] = fullDF[lowFrequencyPredictorTags].resample(resampleTime, label='right', closed='right').last()
    fullDF[responseTags] = fullDF[responseTags].resample(resampleTime, label='right', closed='right').last()
    
    # Remaining tags get sampled on the spot
    remainingTags = fullDF.columns
    remainingTags = [tag for tag in remainingTags if tag not in \
                     highFrequencyPredictorTags + lowFrequencyPredictorTags + \
                     responseTags]
    fullDF[remainingTags] = fullDF[remainingTags].resample(resampleTime, label='right', closed='right').last()
    
    # Eliminate repeated values from responses
    responses, _ = feh.getUniqueDataPoints(fullDF[responseTags].dropna())
    fullDF[responseTags] = responses
    
    # Add Lagged response as predictor
    if addResponsesAsPredictors['add']:
        fullDF, predictorTagsLaggedResponse = \
            feh.addLagsAsPredictors(fullDF, responseTags,addResponsesAsPredictors['nLags'], resampleTime)
        predictorTagsNew = predictorTagsNew + predictorTagsLaggedResponse
        
    # Add differenced response as predictor
    if addDifferenceResponse['add']:
        fullDF, predictorTagsDifferencedResponse = \
            feh.addDifferenceAsPredictors(fullDF, responseTags)
        predictorTagsNew = predictorTagsNew + predictorTagsDifferencedResponse

    # Interpolate response for regression purposes
    fullDF[responseTags] = fullDF[responseTags].resample(resampleTime).interpolate(resampleMethod)

    # Add lags of predictor columns as additional predictors
    if addShiftsToPredictors['add']:
        if 'on' in addShiftsToPredictors.keys():
            fullDF, predictorTagsShifted = feh.addLagsAsPredictors(fullDF, addShiftsToPredictors['on'],
                                                              addShiftsToPredictors['nLags'], resampleTime)
        else:
            fullDF, predictorTagsShifted = feh.addLagsAsPredictors(fullDF, predictorTags,
                                                              addShiftsToPredictors['nLags'], resampleTime)    
        predictorTagsNew = predictorTagsNew + predictorTagsShifted
        
    fullDF = fullDF.dropna()
    
    return fullDF, origSmoothedResponses, predictorTagsNew


def splitIntoTestAndTrain(fullDF, origSmoothedResponses, trainFrac=None, predictorTags=None, responseTags=None):

    trainDates = fullDF.index[:round(trainFrac * len(fullDF))]
    testDates = fullDF.index[round(trainFrac * len(fullDF)):]

    origResponsesTrain = origSmoothedResponses[
        (origSmoothedResponses.index >= trainDates[0]) &
        (origSmoothedResponses.index <= trainDates[-1])]
    origResponsesTest = origSmoothedResponses[
        (origSmoothedResponses.index >= testDates[0]) &
        (origSmoothedResponses.index <= testDates[-1])]

    trainDF = fullDF[
        (fullDF.index >= trainDates[0]) &
        (fullDF.index <= trainDates[-1])]
    testDF = fullDF[
        (fullDF.index >= testDates[0]) &
        (fullDF.index <= testDates[-1])]

    trainDF = trainDF[~trainDF[predictorTags+responseTags].isna().any(axis=1)]
    testDF = testDF[~testDF[predictorTags+responseTags].isna().any(axis=1)]

    responsesTest = testDF[responseTags]
    predictorsTest = testDF[predictorTags]

    responsesTrain = trainDF[responseTags]
    predictorsTrain = trainDF[predictorTags]

    return predictorsTrain, responsesTrain, origResponsesTrain, predictorsTest, responsesTest, origResponsesTest

def addLatentTemperatureFeatures(fullDFOrig, predictorTags, highFreqPredictors, lowFreqPredictors, phase):
    # Add height to motion ratio
    fullDFOrig['Lance Height to Motion Ratio'] = fullDFOrig["Lance height"]/fullDFOrig["Lance motion"]
    predictorTags = predictorTags + ['Lance Height to Motion Ratio']
    highFreqPredictors = highFreqPredictors + ['Lance Height to Motion Ratio']
    
    # Drop Lance height as a predictor - not directly useful
    # fullDFOrig = fullDFOrig.drop('Lance height', axis = 1)
    # predictorTags.remove('Lance height')
    # highFreqPredictors.remove('Lance height')
    
    # Add Heat Flux
    fullDFOrig['Heat flux'] = -0.056*fullDFOrig["Centre long"] + \
        0.25*np.nanmean(fullDFOrig[["Middle long 1", "Middle long 2", "Middle long 3", "Middle long 4"]], axis = 1) - \
            0.145*np.nanmean(fullDFOrig[["Outer long 1", "Outer long 2", "Outer long 3", "Outer long 4"]], axis = 1)
    predictorTags = predictorTags + ['Heat flux']
    highFreqPredictors = highFreqPredictors + ['Heat flux']
    
    # Define Areas
    if phase == 'A':
        upperAreas = [1.9, 1.9, 1.9, 1.5, 1.9, 1.5, 1.9, 1.9, 1.9, 1.9, 1.9, 1.5,
                      1.9, 1.9, 1.9, 1.9]
        lowerAreas = 1.9*np.ones((16,))
    elif phase == 'B':
        upperAreas = [1.827, 1.988, 1.827, 1.988, 1.827, 1.988, 1.827, 1.988, 1.827,
                      1.988, 1.827, 1.988, 1.827, 1.988, 1.827, 1.988]
        lowerAreas = [1.827, 1.988, 1.48, 1.988, 1.48, 1.988, 1.827, 1.988, 1.827,
                      1.988, 1.827, 1.988, 0.913, 1.988, 1.827, 1.988]        
    else:
        raise Exception("Invalid phase entered.")
            
    
    # Add linearly independent version of Lower Waffle HX
    waffleTags = ["Lower waffle 19", "Lower waffle 20", "Lower waffle 21",
                  "Lower waffle 22", "Lower waffle 23", "Lower waffle 24",
                  "Lower waffle 25", "Lower waffle 26", "Lower waffle 27",
                  "Lower waffle 28", "Lower waffle 29", "Lower waffle 30",
                  "Lower waffle 31", "Lower waffle 32", "Lower waffle 33",
                  "Lower waffle 34"]
    # waffleDF = fullDFOrig[waffleTags]
    # pca = PCA(n_components = 0.95)
    # wafflePCData = pca.fit_transform(waffleDF)
    # wafflePCDF = pd.DataFrame(data = wafflePCData, index = waffleDF.index,
    #                           columns = ['Waffle PC' + str(n) for n in np.arange(1, pca.n_components_ + 1)])
    # fullDFOrig = pd.concat((fullDFOrig, wafflePCDF), axis = 1)
    # predictorTags = predictorTags + list(wafflePCDF.columns)
    # highFreqPredictors = highFreqPredictors + list(wafflePCDF.columns)
    
    # Add total heat flux from Waffles
    weightedFluxes = fullDFOrig[waffleTags]*lowerAreas/np.sum(lowerAreas) 
    fullDFOrig['Lower waffle heat flux'] = weightedFluxes.sum(axis = 1)
    predictorTags = predictorTags + ['Lower waffle heat flux']
    highFreqPredictors = highFreqPredictors + ['Lower waffle heat flux']
    
    # Drop Lower Waffle Heat Exchangers - have the PCs
    fullDFOrig = fullDFOrig.drop(waffleTags, axis = 1)
    for dropTag in waffleTags:
        predictorTags.remove(dropTag)
        highFreqPredictors.remove(dropTag)
    
    # Add linearly independent version of Upper Waffle HX
    waffleTags = ["Upper Waffle 3", "Upper Waffle 4", "Upper Waffle 5",
                  "Upper Waffle 6", "Upper Waffle 7", "Upper Waffle 8",
                  "Upper Waffle 9", "Upper Waffle 10", "Upper Waffle 11",
                  "Upper Waffle 12", "Upper Waffle 13", "Upper Waffle 14",
                  "Upper Waffle 15", "Upper Waffle 16", "Upper Waffle 17",
                  "Upper Waffle 18"]
    # waffleDF = fullDFOrig[waffleTags]
    # pca = PCA(n_components = 0.95)
    # wafflePCData = pca.fit_transform(waffleDF)
    # wafflePCDF = pd.DataFrame(data = wafflePCData, index = waffleDF.index,
    #                           columns = ['Waffle PC' + str(n) for n in np.arange(1, pca.n_components_ + 1)])
    # fullDFOrig = pd.concat((fullDFOrig, wafflePCDF), axis = 1)
    # predictorTags = predictorTags + list(wafflePCDF.columns)
    # highFreqPredictors = highFreqPredictors + list(wafflePCDF.columns)
    
    # Add total heat flux from Waffles
    weightedFluxes = fullDFOrig[waffleTags]*upperAreas/np.sum(upperAreas) 
    fullDFOrig['Upper waffle heat flux'] = weightedFluxes.sum(axis = 1)
    predictorTags = predictorTags + ['Upper waffle heat flux']
    highFreqPredictors = highFreqPredictors + ['Upper waffle heat flux']
    
    # Drop Upper Waffle Heat Exchangers - have the PCs
    fullDFOrig = fullDFOrig.drop(waffleTags, axis = 1)
    for dropTag in waffleTags:
        predictorTags.remove(dropTag)
        highFreqPredictors.remove(dropTag)
    
    # Drop Hearth Heat Exchangers - only interested in Heat Flux
    tagsToDrop = ["Centre long", "Middle long 1", "Middle long 2", "Middle long 3",
                  "Middle long 4", "Outer long 1", "Outer long 2", "Outer long 3",
                  "Outer long 4"]
    fullDFOrig = fullDFOrig.drop(tagsToDrop, axis = 1)
    for dropTag in tagsToDrop:
        predictorTags.remove(dropTag)
        highFreqPredictors.remove(dropTag)
    return fullDFOrig, predictorTags, highFreqPredictors, lowFreqPredictors

def fillMissingHXPoints(fullDFOrig):
    # Replace missing Lower Waffle values with mean of others
    waffleTags = ["Lower waffle 19", "Lower waffle 20", "Lower waffle 21",
                  "Lower waffle 22", "Lower waffle 23", "Lower waffle 24",
                  "Lower waffle 25", "Lower waffle 26", "Lower waffle 27",
                  "Lower waffle 28", "Lower waffle 29", "Lower waffle 30",
                  "Lower waffle 31", "Lower waffle 32", "Lower waffle 33",
                  "Lower waffle 34"]
    fullDFOrig = replaceMissingWithMean(fullDFOrig, waffleTags)
    fullDFOrig = fillWaffleNans(fullDFOrig, waffleTags)
    
    # Replace missing Upper Waffle values with mean of others
    waffleTags = ["Upper Waffle 3", "Upper Waffle 4", "Upper Waffle 5",
                  "Upper Waffle 6", "Upper Waffle 7", "Upper Waffle 8",
                  "Upper Waffle 9", "Upper Waffle 10", "Upper Waffle 11",
                  "Upper Waffle 12", "Upper Waffle 13", "Upper Waffle 14",
                  "Upper Waffle 15", "Upper Waffle 16", "Upper Waffle 17",
                  "Upper Waffle 18"]
    fullDFOrig = replaceMissingWithMean(fullDFOrig, waffleTags)
    fullDFOrig = fillWaffleNans(fullDFOrig, waffleTags)
    
    # Replace missing outer long values with mean of others
    outerLongTags = ["Outer long 1", "Outer long 2", "Outer long 3",
                     "Outer long 4"]
    fullDFOrig = replaceMissingWithMean(fullDFOrig, outerLongTags)
    
    # Replace missing middle long values with mean of others
    middleLongTags = ["Middle long 1", "Middle long 2", "Middle long 3",
                      "Middle long 4"]
    fullDFOrig = replaceMissingWithMean(fullDFOrig, middleLongTags)
    return fullDFOrig

def replaceMissingWithMean(fullDFOrig, tagsOfInterest):
    # Replace spot nans with the mean of the other tags
    for tagToFill in tagsOfInterest:
        otherTags = [tag for tag in tagsOfInterest if tag != tagToFill]
        missingIdx = np.isnan(fullDFOrig[tagToFill])
        fullDFOrig[tagToFill].loc[missingIdx] = fullDFOrig[otherTags].loc[missingIdx].mean(axis = 1)
    return fullDFOrig

def fillWaffleNans(fullDFOrig, waffleTags):
    # In cases where all tags are nans, replace the nans with 4 hour average
    fullDFOrig[waffleTags] = fullDFOrig[waffleTags].fillna(value = fullDFOrig[waffleTags].rolling('4h').mean()) #4-hour average
    # Takes care of the rest
    fullDFOrig[waffleTags] = fullDFOrig[waffleTags].fillna(method = 'ffill')
    return fullDFOrig
