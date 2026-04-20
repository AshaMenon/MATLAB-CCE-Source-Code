# -*- coding: utf-8 -*-
"""
Created on Wed Sep 28 15:37:24 2022

@author: john.atherfold
"""

import pickle
import pandas as pd
import pandas as pd
import numpy as np
import datetime
import matplotlib.pyplot as plt
from statsmodels.tsa.api import SimpleExpSmoothing
from sklearn.linear_model import Lasso
from sklearn.decomposition import PCA
from sklearn.preprocessing import RobustScaler
from skopt import BayesSearchCV
from sklearn.model_selection import TimeSeriesSplit
from sklearn.pipeline import Pipeline
import pickle
import os


import Shared.DSModel.src.preprocessingFunctions as prep
import src.modellingFunctions as modelling
import src.dataExploration as visualise
from xgboost import XGBRegressor
from sklearn.model_selection import cross_val_score

#%% Read and Format Data
highFreqPredictors = ["Specific Oxygen Actual PV",
                      "Specific Silica Actual PV", "Matte feed PV filtered",
                      "Lance oxygen flow rate PV", "Lance air flow rate PV",
                      "Lance feed PV", "Silica PV", "Lump Coal PV",
                      "Matte transfer air flow", "Fuel coal feed rate PV"]

lowFreqPredictors = ["Fe Slag", "MgO Slag", "CaO Slag", "SiO2 Slag", "Al2O3 Slag",
                     "Ni Slag", "S Slag", "S Matte", "Slag temperatures",
                     "Matte temperatures", "Fe Feedblend", "S Feedblend",
                     "SiO2 Feedblend", "Al2O3 Feedblend", "CaO Feedblend",
                     "MgO Feedblend", "Cr2O3 Feedblend", "Corrected Ni Slag",
                     "Fe Matte"]

predictorTags = lowFreqPredictors + highFreqPredictors

responseTags = ["Basicity"]
referenceTags = ["Converter mode", "Lance air and oxygen control", "SumOfSpecies"]

fullDFOrig = prep.readAndFormatData('sept22Chemistry')

#%%
def processingFunc(fullDFOrig):
    fullDF, origSmoothedResponses, predictorTagsNew = \
        prep.preprocessingAndFeatureEngineering(
            fullDFOrig,
            removeTransientData=True,
            smoothBasicityResponse=True,
            addRollingSumPredictors={'add': False, 'window': '19min'}, #NOTE: functionality exists to process an 'on' key
            addRollingMeanPredictors={'add': False, 'window': '5min'},
            addRollingMeanResponse={'add': True, 'window': '60min'},
            addDifferenceResponse = {'add': True},
            addMeasureIndicatorsAsPredictors={'add': True, 'on': ['Basicity', 'Fe Feedblend', 'Matte temperatures']}, #NOTE: functionality exists to process an 'on' key
            addShiftsToPredictors={'add': True, 'nLags': 5, 'on': highFreqPredictors},
            addResponsesAsPredictors={'add': True, 'nLags': 1},
            resampleTime = '1min',
            resampleMethod = 'linear',
            responseTags=responseTags,
            predictorTags=predictorTags,
            referenceTags=referenceTags,
            highFrequencyPredictorTags = highFreqPredictors,
            lowFrequencyPredictorTags = lowFreqPredictors)
    return fullDF, origSmoothedResponses, predictorTagsNew

fullDF, origSmoothedResponses, predictorTagsNew = processingFunc(fullDFOrig)

predictorsTrain, responsesTrain, origResponsesTrain, predictorsTest, responsesTest, origResponsesTest = \
    prep.splitIntoTestAndTrain(
    fullDF,
    origSmoothedResponses,
    trainFrac=0.85,
    predictorTags=predictorTagsNew,
    responseTags=responseTags)

output = pickle.load(open("../data/BasicityModel/2022_XGBoost_Basicity_Model_2022-01-01_09.46.00_to_2022-09-01_00.00.00", "rb"))
pipe = output[0]
intervalRange = output[1]

#%% Testing Model on Out-of-sample Data

predictors = pd.concat((predictorsTrain, predictorsTest))
responses = pd.concat((origResponsesTrain, origResponsesTest)).resample('1min').ffill()

xTest = predictors#[end_Date:test_End_Date]
yTest = responses#[end_Date:test_End_Date]

yHatTest = pipe.predict(xTest)

k = pipe.named_steps.get('pca').n_components # k is number of predictors that the ML model sees
print('--------------------------------------------------------------')
print('Model Results - Test')
modelling.regression_results(yTest, yHatTest, k)

yHatTest = pd.DataFrame(yHatTest, index = yTest.index)

# smoothTestResults = SimpleExpSmoothing(yHatTest, initialization_method="heuristic").fit(
#     smoothing_level=0.1, optimized=False)

# plt.plot(yTrain, label = 'Training Data', color = 'g')
plt.plot(yTest, label = 'Actual Data', color = 'r', marker = '.')
plt.plot(yHatTest, label = 'Predicted Data', color = 'b', marker = '*')
plt.legend()