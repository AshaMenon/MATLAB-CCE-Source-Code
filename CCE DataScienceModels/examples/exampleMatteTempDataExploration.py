# -*- coding: utf-8 -*-
"""
Created on Fri Mar 25 12:09:43 2022

@author: john.atherfold
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from sklearn.linear_model import Lasso
from sklearn.decomposition import PCA
from sklearn.preprocessing import RobustScaler
from sklearn.preprocessing import PolynomialFeatures
from skopt import BayesSearchCV
from sklearn.model_selection import TimeSeriesSplit
from sklearn.pipeline import Pipeline
from sklearn.linear_model import LinearRegression

import src.preprocessingFunctions as prep
import src.modellingFunctions as modelling
import src.dataExploration as visualise
from xgboost import XGBRegressor

#%% Read and Format Data

highFreqPredictors = ["Matte feed PV", "Fuel coal feed rate PV", "Specific Oxygen Actual PV",
                      "Lump coal PV", "Lance oxygen flow rate PV", "Lance air flow rate PV",
                      "Matte transfer air flow", "Lance coal carrier air", "Silica PV",
                      "Lower waffle 19", "Lower waffle 20", "Lower waffle 21",
                      "Lower waffle 22", "Lower waffle 23", "Lower waffle 24",
                      "Lower waffle 25", "Lower waffle 26", "Lower waffle 27",
                      "Lower waffle 28", "Lower waffle 29", "Lower waffle 30",
                      "Lower waffle 31", "Lower waffle 32", "Lower waffle 33",
                      "Lower waffle 34", "Upper hearth 90", "Upper hearth 91",
                      "Upper hearth 92", "Upper hearth 93", "Upper hearth 94",
                      "Upper hearth 95", "Upper hearth 96", "Upper hearth 97",
                      "Upper hearth 98", "Fuel coal feed rate SP", "Lance height",
                      "Lance motion"]

lowFreqPredictors = ["Corrected Ni Slag", "Ni Slag", "S Slag", "Cr2O3 Slag", "Basicity",
                     "Cu Feedblend", "Ni Feedblend", "Co Feedblend", "Fe Feedblend",
                     "S Feedblend", "SiO2 Feedblend", "Al2O3 Feedblend", "CaO Feedblend",
                     "MgO Feedblend", "Cr2O3 Feedblend", "MgO Slag",
                     "Slag temperatures"]

predictorTags = highFreqPredictors + lowFreqPredictors

responseTags = ['Matte temperatures']

fullDFOrig = prep.readAndFormatData('Temperature', responseTags=responseTags,
        predictorTags=predictorTags)

#%%  
  
fullDF, origSmoothedResponses, predictorTagsNew = \
    prep.preprocessingAndFeatureEngineering(
        fullDFOrig,
        removeTransientData=True,
        smoothBasicityResponse=False,
        addRollingSumPredictors={'add': True, 'window': 5, 'on': highFreqPredictors}, #NOTE: functionality exists to process an 'on' key
        addRollingMeanPredictors={'add': True, 'window': 5, 'on': highFreqPredictors},
        addMeasureIndicatorsAsPredictors={'add': True, 'on': ['Matte temperatures']}, #NOTE: functionality exists to process an 'on' key
        addShiftsToPredictors={'add': True, 'nLags': 2},
        addResponsesAsPredictors={'add': True, 'nLags': 3},
        resampleTime = '30min',
        resampleMethod = 'linear',
        responseTags=responseTags,  
        predictorTags=predictorTags,
        highFrequencyPredictorTags = highFreqPredictors,
        lowFrequencyPredictorTags = lowFreqPredictors)

#%% Split Data

predictorsTrain, responsesTrain, origResponsesTrain, predictorsTest, responsesTest, origResponsesTest = \
    prep.splitIntoTestAndTrain(
    fullDF,
    origSmoothedResponses,
    trainFrac=0.85,
    predictorTags=predictorTagsNew,
    responseTags=responseTags)
    
#%% Compare Original Data to Processed Data for ALL TAGS

tag = "S Slag"
relevantTags = [string for string in fullDF.columns if tag in string]
ax = fullDFOrig[tag].plot(use_index = True, label = tag + ' Raw')
for modifiedTag in relevantTags:
    fullDF[modifiedTag].plot(use_index = True, ax = ax, label = modifiedTag)
ax.legend()

    
#%% Exploring Relationships between Predictors and Responses

for tag in predictorTags + responseTags:
    visualise.plotExploratoryVisualisations(predictorsTrain[tag],
                                            responsesTrain['Matte temperatures'])
                                        # 'D:/John/Projects/AngloAmerican/converter-slag-splash/data/figures/dataExploration/ScaledData/Matte Temp/')