# -*- coding: utf-8 -*-

import pandas as pd
import numpy as np
import datetime
import matplotlib.pyplot as plt
from sklearn.ensemble import RandomForestRegressor
from sklearn.decomposition import PCA
from sklearn.preprocessing import RobustScaler
from sklearn.model_selection import TimeSeriesSplit
from sklearn.pipeline import Pipeline
import src.preprocessingFunctions as prep
import src.modellingFunctions as modelling
import src.simulationFunctions as sim
from skopt import BayesSearchCV
import src.dataExploration as visualise
from sklearn.decomposition import KernelPCA
import shap
import src.featureEngineeringHelpers as featEng
from sklearn.neural_network import MLPRegressor
from sklearn.base import BaseEstimator, RegressorMixin
import xgboost as xgb
from sklearn import ensemble

#%% Read and Format Data

highFreqPredictors = ["Matte feed PV", "Fuel coal feed rate PV", "Specific Oxygen Actual PV",
                      "Reverts feed rate PV",
                      "Lump coal PV",
                      "Lance oxygen flow rate PV", "Lance air flow rate PV",
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

lowFreqPredictors = ["Slag temperatures"]#, "Cr2O3 Slag", "Basicity", "MgO Slag", ]

feedblendPredictors = ["Cu Feedblend", "Ni Feedblend",
                       "Co Feedblend", "Fe Feedblend", "S Feedblend",
                       "SiO2 Feedblend", "Al2O3 Feedblend", "CaO Feedblend",
                       "MgO Feedblend", "Cr2O3 Feedblend"]
referenceTags = ["Converter mode", "Lance air & oxygen control"]
# lowFreqPredictors = lowFreqPredictors + feedblendPredictors

predictorTags = highFreqPredictors + lowFreqPredictors

responseTags = ['Matte temperatures']

fullDFOrig = prep.readAndFormatData('Temperature')

#%% Data Cleaning and Specific Latent Feature Generation
def processingFunc(fullDFOrig, predictorTags, highFreqPredictors, lowFreqPredictors):
    # Preprocess Heat Transfer features (specific to Temperature Model)
    fullDFOrig = prep.fillMissingHXPoints(fullDFOrig)

    # Add latent features (Specific to Temperature Model)
    fullDFOrig, predictorTags, highFreqPredictors, lowFreqPredictors = \
        prep.addLatentTemperatureFeatures(fullDFOrig, predictorTags,
                                          highFreqPredictors, lowFreqPredictors)


    fullDF, origSmoothedResponses, predictorTagsNew = \
        prep.preprocessingAndFeatureEngineering(
            fullDFOrig,
            removeTransientData=True,
            smoothBasicityResponse=False,
            addRollingSumPredictors={'add': True, 'window': '15min', 'on': highFreqPredictors}, #NOTE: functionality exists to process an 'on' key
            addRollingMeanPredictors={'add': True, 'window': '15min', 'on': highFreqPredictors},
            addRollingMeanResponse={'add': True, 'window': '450min'},
            addDifferenceResponse = {'add': True},
            addMeasureIndicatorsAsPredictors={'add': False, 'on': ['Matte temperatures']}, #NOTE: functionality exists to process an 'on' key
            addShiftsToPredictors={'add': True, 'nLags': 3, 'on': ['Fuel coal feed rate PV 15min-rollingmean', 'Fuel coal feed rate PV 15min-rollingsum',
                                                                   'Matte feed PV 15min-rollingmean', 'Matte feed PV 15min-rollingsum',
                                                                   'Roof matte feed rate PV 15min-rollingmean', 'Roof matte feed rate PV 15min-rollingsum']},
            addResponsesAsPredictors={'add': True, 'nLags': 1},
            resampleTime = '15min',
            resampleMethod = 'linear',
            responseTags = responseTags,
            predictorTags = predictorTags,
            highFrequencyPredictorTags = highFreqPredictors,
            lowFrequencyPredictorTags = [],
            referenceTags=referenceTags)
    return fullDF, origSmoothedResponses, predictorTagsNew

fullDF, origSmoothedResponses, predictorTagsNew = processingFunc(fullDFOrig, predictorTags, highFreqPredictors, lowFreqPredictors)

predictorTagsNew = list(set(predictorTagsNew) - set(predictorTags) - set(['Heat flux']))
fullDF = fullDF[predictorTagsNew + responseTags]

# startTime = pd.Timestamp('2021-01-01 00:00')
# endTime = pd.Timestamp('2021-12-01 00:00')
# mask = (fullDF.index >= startTime) & (fullDF.index < endTime)
# fullDF = fullDF.loc[mask]
#%% Split Data

predictorsTrain, responsesTrain, origResponsesTrain, predictorsTest, responsesTest, origResponsesTest = \
    prep.splitIntoTestAndTrain(
    fullDF,
    origSmoothedResponses,
    trainFrac=0.90,
    predictorTags=predictorTagsNew,
    responseTags=responseTags)

#%% Define TS Cross Validation Object
maxTrainSize = int(70*24*60/15)
testSize = int(1*24*60/15)
nSplits = int(np.ceil((len(predictorsTrain) - maxTrainSize)/testSize))
tscv = TimeSeriesSplit(n_splits = nSplits, max_train_size = maxTrainSize,
                       test_size = testSize)


pipe = Pipeline([('scaler', RobustScaler()),
                 # ('pca', PCA()),
                 ('estimator',  xgb.XGBRegressor(objective ='reg:squarederror'))])

param = {
    "estimator__n_estimators": np.arange(10, 701),
    "estimator__max_depth": np.arange(1, 21),
    "estimator__alpha": np.logspace(-7, 4, num = 1000),
    'estimator__reg_lambda': np.logspace(-7, 4, num = 1000),
    "estimator__learning_rate": np.logspace(-4, 0, num = 500),
    # 'pca__n_components': np.arange(10, len(predictorTagsNew)),
    # 'pca__gamma': np.logspace(-7, 2, num = 100)
    }

opt = BayesSearchCV(pipe, param, n_iter=50, cv = tscv, 
                    scoring = 'neg_root_mean_squared_error',
                    n_jobs =-1, verbose = 10)


# executes bayesian optimization
searchResults = opt.fit(predictorsTrain, responsesTrain)

#%% Train model with optimised parameters

# nEstimators = searchResults.best_params_.get('estimator__n_estimators')
# maxDepth = searchResults.best_params_.get('estimator__max_depth')
# alpha = searchResults.best_params_.get('estimator__alpha')
# learningRate = searchResults.best_params_.get('estimator__learning_rate')
# reg_lambda = searchResults.best_params_.get('estimator__reg_lambda')
# subsample = searchResults.best_params_.get('estimator__subsample')

# To run script quickly, comment out when doing Hyperparameter tuning
# nEstimators = 691
# maxDepth = 17
# alpha = 7.616641716552891e-07
# learningRate = 0.3683537200788066
# reg_lambda = 0.0053636313167392344

# pipe.set_params(estimator__n_estimators = nEstimators,
#                 estimator__max_depth = maxDepth,
#                 estimator__alpha = alpha,
#                 estimator__reg_lambda = reg_lambda,
#                 estimator__learning_rate = learningRate)

pipe = searchResults.best_estimator_

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

    [pipe, latestTestResults] = modelling.trainAndTestModel(pipe, xTrain, yTrain.ravel(),
                                                        xTest, yTest.ravel(), yTestDS.index)

    latestTrainResults = modelling.testModel(pipe, xTrain, yTrain.ravel(), yTrainDS.index)

    testResults = pd.concat((testResults, latestTestResults))
    trainResults = pd.concat((trainResults, latestTrainResults))

print('--------------------------------------------------------------')
print('--------------------------------------------------------------')
print(pipe.steps)
print(predictorsTestPrepended.columns.to_list())
print('Overall Results - Test')    
print('Training Data Points: ' + str(maxTrainSize))
print('Testing Data Points: ' + str(testSize))
k = predictorsTestPrepended.shape[1]
modelling.regression_results(testResults.yActual, testResults.yHat, k)

#%% Results Visualisation

visualise.plotActualVsPredicted(trainResults, testResults, (1175, 1325), "XGBoost Model - Matte Temperatures")

visualise.plotTimeSeriesResults(testResults, origResponsesTest, "XGBoost Model - Matte Temperatures (Test Results)")

visualise.plotTimeSeriesResults(trainResults, origResponsesTrain, "XGBoost Model - Matte Temperatures (Train Results)")

visualise.plotResidualsAndErrors(trainResults, testResults)

convergenceIndicator, convergingPeriod, divergingPeriod = \
    modelling.getDirectionalPerformance(origResponsesTest, testResults)
visualise.plotDirectionalPerformance(origResponsesTest, testResults, convergenceIndicator, "XGBoost Model - Basicity (Test Results)")

convergingPeriod/(convergingPeriod + divergingPeriod)

#%% Feature Importance
# Forest Model built in feature importance

# modelling.getFeatureImportance(mdl, predictorsTest, predictorsTest.columns, 'Forest')

# explainer = shap.KernelExplainer(mdl.predict, predictorsTest)
# shap_values = explainer.shap_values(predictorsTest,nsamples=10)
