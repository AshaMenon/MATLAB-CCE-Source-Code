# -*- coding: utf-8 -*-
"""
Created on Wed Mar 16 13:16:07 2022

@author: john.atherfold
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from sklearn.linear_model import Lasso
from sklearn.decomposition import PCA
from sklearn.preprocessing import RobustScaler
from skopt import BayesSearchCV
from sklearn.model_selection import TimeSeriesSplit
from sklearn.pipeline import Pipeline
from sklearn.linear_model import LinearRegression

import src.preprocessingFunctions as prep
import src.modellingFunctions as modelling
import src.dataExploration as visualise
from xgboost import XGBRegressor

#%% Read and Format Data
predictorTags = ["Fe Slag", "MgO Slag", "CaO Slag", "SiO2 Slag", "Al2O3 Slag",
                 "Ni Slag", "S Slag", "S Matte", "Specific Oxygen Actual PV",
                 "Specific Silica Actual PV", "Matte feed PV(filtered)",
                 "Lance oxygen flow rate PV", "Lance air flow rate PV",
                 "Lance feed PV", "Silica PV", "Lump Coal PV",
                 "Slag temperatures", "Matte temperatures",
                 "Matte transfer air flow", "Fe Feedblend", "S Feedblend",
                 "SiO2 Feedblend", "Al2O3 Feedblend", "CaO Feedblend",
                 "MgO Feedblend", "Cr2O3 Feedblend", "Corrected Ni Slag", "Fe Matte"]
responseTags = ['Basicity']

fullDFOrig = prep.readAndFormatData('Chemistry', responseTags=responseTags,
        predictorTags=predictorTags)
  
fullDF, origSmoothedResponses, predictorTagsNew = \
    prep.preprocessingAndFeatureEngineering(
        fullDFOrig,
        removeTransientData=True,
        smoothBasicityResponse=True,
        addRollingSumPredictors={'add': False, 'window': 19}, #NOTE: functionality exists to process an 'on' key
        addRollingMeanPredictors={'add': True, 'window': 5},
        addMeasureIndicatorsAsPredictors={'add': False}, #NOTE: functionality exists to process an 'on' key
        addShiftsToPredictors={'add': True, 'nLags': 10},
        addResponsesAsPredictors={'add': False, 'nLags': 10},
        resampleTime = '19min',
        resampleMethod = 'linear',
        responseTags=responseTags,
        predictorTags=predictorTags)

predictorsTrain, responsesTrain, origResponsesTrain, predictorsTest, responsesTest, origResponsesTest = \
    prep.splitIntoTestAndTrain(
    fullDF,
    origSmoothedResponses,
    trainFrac=0.85,
    predictorTags=predictorTagsNew,
    responseTags=responseTags)
    
#%% Exploring Relationships between Predictors and Responses

tag = "Silica PV 5-shifted"
visualise.plotExploratoryVisualisations(predictorsTrain[tag],
                                        responsesTrain['Basicity'])

tag = "Silica PV 4-shifted"
visualise.plotExploratoryVisualisations(predictorsTrain[tag],
                                        responsesTrain['Basicity'])

#%% Regress Basicity on first lag of Silica - expecting strong positive correlation
xTrain = predictorsTrain[tag].iloc[0:304].shift(periods = 4).dropna().values.reshape(-1, 1)
yTrain = responsesTrain.iloc[0:300].values.ravel()

xTest = predictorsTrain[tag].iloc[300:404].shift(periods = 4).dropna().values.reshape(-1, 1)
yTest = responsesTrain.iloc[300:400].values.ravel()

scaler = RobustScaler()
xTrain = scaler.fit_transform(xTrain)
xTest = scaler.transform(xTest)

linearMdl = LinearRegression()
[linearMdl, testResults] = modelling.trainAndTestModel(linearMdl, xTrain, yTrain,
                                                   xTest, yTest,
                                                   responsesTrain.iloc[300:400].index)

trainResults = modelling.testModel(linearMdl, xTrain, yTrain, responsesTrain.iloc[0:300].index)

visualise.plotActualVsPredicted(trainResults, testResults, (1, 3), "Linear Model - Basicity")

visualise.plotTimeSeriesResults(testResults, origResponsesTest, "Linear Model - Basicity (Test Results)")