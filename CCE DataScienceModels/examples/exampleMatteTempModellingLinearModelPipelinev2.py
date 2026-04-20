# -*- coding: utf-8 -*-
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from sklearn.preprocessing import RobustScaler
from sklearn.decomposition import KernelPCA
from sklearn.decomposition import PCA
from sklearn.preprocessing import PolynomialFeatures
from skopt import BayesSearchCV
from sklearn.model_selection import TimeSeriesSplit
from sklearn.pipeline import Pipeline
from sklearn.linear_model import Lasso
from sklearn.linear_model import Ridge
from sklearn.linear_model import PoissonRegressor
from sklearn.linear_model import LinearRegression
from sklearn.linear_model import QuantileRegressor
from sklearn.feature_selection import SelectKBest
from sklearn.feature_selection import mutual_info_regression
from sklearn.feature_selection import SelectFromModel
from sklearn.feature_selection import SequentialFeatureSelector
from sklearn.compose import TransformedTargetRegressor
from sklearn.preprocessing import QuantileTransformer
from sklearn.ensemble import RandomForestRegressor
from sklearn.gaussian_process import GaussianProcessRegressor
from sklearn.gaussian_process.kernels import RBF, RationalQuadratic, Matern, WhiteKernel
import xgboost as xgb
from sklearn.ensemble import AdaBoostRegressor, BaggingRegressor

import src.preprocessingFunctions as prep
import src.modellingFunctions as modelling
import src.dataExploration as visualise
import src.featureEngineeringHelpers as featEng

#%% Read and Format Data

highFreqPredictors = ["Matte feed PV", "Fuel coal feed rate PV", "Specific Oxygen Actual PV",
                      "Reverts feed rate PV",
                      "Lump coal PV", "Lance oxygen flow rate PV", "Lance air flow rate PV",
                      "Matte transfer air flow", "Lance coal carrier air",
                      "Silica PV",
                      "Lower waffle 19", "Lower waffle 20", "Lower waffle 21",
                      "Lower waffle 22", "Lower waffle 23", "Lower waffle 24",
                      "Lower waffle 25", "Lower waffle 26", "Lower waffle 27",
                      "Lower waffle 28", "Lower waffle 29", "Lower waffle 30",
                      "Lower waffle 31", "Lower waffle 32", "Lower waffle 33",
                      "Lower waffle 34", "Outer long 1", "Middle long 1",
                      "Outer long 2", "Middle long 2", "Outer long 3",
                      "Middle long 3", "Outer long 4", "Middle long 4",
                      "Centre long", "Lance Oxy Enrich % PV", "Roof matte feed rate PV",
                      "Lance height", "Lance motion"]

lowFreqPredictors = ["Cr2O3 Slag", "Basicity", "MgO Slag", "Slag temperatures"]

feedblendPredictors = ["Cu Feedblend", "Ni Feedblend",
                       "Co Feedblend", "Fe Feedblend", "S Feedblend",
                       "SiO2 Feedblend", "Al2O3 Feedblend", "CaO Feedblend",
                       "MgO Feedblend", "Cr2O3 Feedblend"]

# lowFreqPredictors = lowFreqPredictors + feedblendPredictors

predictorTags = highFreqPredictors + lowFreqPredictors

responseTags = ['Matte temperatures']

fullDFOrig = prep.readAndFormatData('Temperature', responseTags=responseTags,
        predictorTags=predictorTags)

#%% Data Cleaning and Specific Latent Feature Generation 

# Preprocess Heat Transfer features (specific to Temperature Model)
fullDFOrig = prep.fillMissingHXPoints(fullDFOrig)

# Add latent features (Specific to Temperature Model)
fullDFOrig, predictorTags, highFreqPredictors, lowFreqPredictors = \
    prep.addLatentTemperatureFeatures(fullDFOrig, predictorTags,
                                      highFreqPredictors, lowFreqPredictors)

#%%  

fullDF, origSmoothedResponses, predictorTagsNew = \
    prep.preprocessingAndFeatureEngineering(
        fullDFOrig,
        removeTransientData=True,
        smoothBasicityResponse=False,
        addRollingSumPredictors={'add': True, 'window': 30, 'on': ['Fuel coal feed rate PV']}, #NOTE: functionality exists to process an 'on' key
        addRollingMeanPredictors={'add': False, 'window': 5, 'on': highFreqPredictors},
        addMeasureIndicatorsAsPredictors={'add': True, 'on': ['Matte temperatures']}, #NOTE: functionality exists to process an 'on' key
        addShiftsToPredictors={'add': True, 'nLags': 10, 'on': ['Fuel coal feed rate PV']},
        addResponsesAsPredictors={'add': True, 'nLags': 3},
        resampleTime = '30min',
        resampleMethod = 'linear',
        responseTags = responseTags,  
        predictorTags = predictorTags,
        highFrequencyPredictorTags = highFreqPredictors,
        lowFrequencyPredictorTags = lowFreqPredictors)

# startTime = pd.Timestamp('2021-01-01 00:00')
# endTime = pd.Timestamp('2021-12-01 00:00')
# mask = (fullDF.index >= startTime) & (fullDF.index < endTime)
# fullDF = fullDF.loc[mask]
#%% Split Data

predictorsTrain, responsesTrain, origResponsesTrain, predictorsTest, responsesTest, origResponsesTest = \
    prep.splitIntoTestAndTrain(
    fullDF,
    origSmoothedResponses,
    trainFrac=0.85,
    predictorTags=predictorTagsNew,
    responseTags=responseTags)

#%% Define TS Cross Validation Object
maxTrainSize = int(70*24*60/30)
testSize = int(7*24*60/30)
nSplits = int(np.floor((len(predictorsTrain) - maxTrainSize)/testSize))
tscv = TimeSeriesSplit(n_splits = nSplits, max_train_size = maxTrainSize,
                       test_size = testSize)

pipe = Pipeline([('scaler', RobustScaler()),
                 #('pca', PCA()),
                 ('estimator', BaggingRegressor(base_estimator=Lasso(), oob_score=True))])
                 # ('regression', Lasso(max_iter = 3000))])

param = {
    #'pca__n_components' : np.arange(5, 10),
    'estimator__n_estimators' : np.arange(10, 500, 10),
    'estimator__max_samples' : np.arange(0.1, 1, 10),
    'estimator__max_features' : np.arange(0.1, 1, 10)
    #'estimator__alpha' : np.logspace(0.1, 2, 10),
    #'estimator__quantile' : np.arange(0.3, 0.9, 0.1)
}

randomSearch = BayesSearchCV(estimator = pipe, search_spaces = param,
                             n_iter = 10, cv = tscv, verbose = 5, n_jobs = -1,
                             scoring = 'r2')

searchResults = randomSearch.fit(predictorsTrain, responsesTrain.values.ravel())

#%% Testing Algorithm on Out of Sample Data

# Append training data for final model to the testing data set - THIS DATA IS
#   ONLY USED FOR TRAINING THE FIRST FINAL MODEL

pipe = searchResults.best_estimator_
maxTrainSize = predictorsTrain.shape[0]

predictorsTestPrepended = pd.concat((predictorsTrain[-maxTrainSize:], predictorsTest))
responsesTestPrepended = pd.concat((responsesTrain[-maxTrainSize:], responsesTest))
nSplits = int(np.ceil((len(predictorsTestPrepended) - maxTrainSize)/testSize))
tscv = TimeSeriesSplit(n_splits = nSplits, max_train_size = maxTrainSize,
                       test_size = testSize)

testResults = pd.DataFrame()
trainResults = pd.DataFrame()

for train_index, test_index in tscv.split(predictorsTestPrepended):
    xTrain, xTest = \
        predictorsTestPrepended.iloc[train_index], \
        predictorsTestPrepended.iloc[test_index]
    yTrainDS, yTestDS = responsesTestPrepended.iloc[train_index], \
        responsesTestPrepended.iloc[test_index]

    yTrain = yTrainDS.values
    yTest = yTestDS.values

    pipe, latestTestResults = modelling.trainAndTestModel(pipe, xTrain, yTrain.ravel(),
                                                        xTest, yTest.ravel(), yTestDS.index)

    latestTrainResults = modelling.testModel(pipe, xTrain, yTrain.ravel(), yTrainDS.index)

    testResults = pd.concat((testResults, latestTestResults))
    trainResults = pd.concat((trainResults, latestTrainResults))

print('--------------------------------------------------------------')
print('Overall Results - Test')    
modelling.regression_results(testResults.yActual, testResults.yHat)

#%% Results Visualisation

visualise.plotActualVsPredicted(trainResults, testResults, (1125, 1400), "Linear Model - Matte Temperature")

visualise.plotTimeSeriesResults(testResults, origResponsesTest, "Linear Model - Matte Temperature (Test Results)")

visualise.plotTimeSeriesResults(trainResults, origResponsesTrain, "Linear Model - Matte Temperature (Train Results)")

visualise.plotResidualsAndErrors(trainResults, testResults)

convergenceIndicator, convergingPeriod, divergingPeriod = \
    modelling.getDirectionalPerformance(origResponsesTest, testResults)

visualise.plotDirectionalPerformance(origResponsesTest, testResults, convergenceIndicator, "Linear Model - Temperature (Test Results)")

convergingPeriod/(convergingPeriod + divergingPeriod)

# %%
