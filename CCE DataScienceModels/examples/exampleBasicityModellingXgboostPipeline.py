# -*- coding: utf-8 -*-
"""
Created on Mon Feb 14 08:17:39 2022

@author: john.atherfold
"""
import pandas as pd
import numpy as np
import datetime
from sklearn.preprocessing import RobustScaler
from skopt import BayesSearchCV
from sklearn.model_selection import TimeSeriesSplit
from sklearn.pipeline import Pipeline


import src.preprocessingFunctions as prep
import src.modellingFunctions as modelling
import src.dataExploration as visualise
import src.simulationFunctions as sim
from xgboost import XGBRegressor
from sklearn.model_selection import cross_val_score

#%% Read and Format Data
highFreqPredictors = ["Specific Oxygen Actual PV", "Specific Silica Actual PV", 
                        "Matte feed PV filtered", "Lance oxygen flow rate PV", 
                        "Lance air flow rate PV", "Lance feed PV", "Silica PV", 
                        "Lump Coal PV", "Matte transfer air flow", 
                        "Fuel coal feed rate PV"]

lowFreqPredictors =  ["Fe Slag", "MgO Slag", "CaO Slag", "SiO2 Slag", 
                        "Al2O3 Slag", "Ni Slag", "S Slag", "S Matte", 
                        "Slag temperatures", "Matte temperatures", "Fe Feedblend", 
                        "S Feedblend", "SiO2 Feedblend", "Al2O3 Feedblend", 
                        "CaO Feedblend", "MgO Feedblend", "Cr2O3 Feedblend", 
                        "Corrected Ni Slag", "Fe Matte"]

predictorTags = lowFreqPredictors + highFreqPredictors

responseTags = ["Basicity"]
referenceTags = ["Converter mode", "Lance air and oxygen control", "SumOfSpecies"]

fullDFOrig = prep.readAndFormatData('Chemistry')

#%%
def processingFunc(fullDFOrig):
    fullDF, origSmoothedResponses, predictorTagsNew = \
        prep.preprocessingAndFeatureEngineering(
            fullDFOrig,
            removeTransientData=True,
            smoothBasicityResponse=True,
            addRollingSumPredictors={'add': True, 'window': 19}, #NOTE: functionality exists to process an 'on' key
            addRollingMeanPredictors={'add': True, 'window': 5},
            addMeasureIndicatorsAsPredictors={'add': True, 'on': ['Basicity', 'Fe Feedblend', 'Matte temperatures']}, #NOTE: functionality exists to process an 'on' key
            addShiftsToPredictors={'add': True, 'nLags': 5, 'on': highFreqPredictors},
            addResponsesAsPredictors={'add': True, 'nLags': 3},
            resampleTime = '1min',
            resampleMethod = 'linear',
            responseTags=responseTags,
            referenceTags=referenceTags,
            predictorTags=predictorTags,
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

#%% Define TS Cross Validation Object
maxTrainSize = int(47*24*60)
testSize = int(7*24*60)
nSplits = int(np.ceil((len(predictorsTrain) - maxTrainSize)/testSize))
tscv = TimeSeriesSplit(n_splits = nSplits, max_train_size = maxTrainSize,
                       test_size = testSize)

pipe = Pipeline([('scaler', RobustScaler()),
                 ('xgb_reg', XGBRegressor(objective='reg:squarederror',
                                          booster='gbtree'))])

param = {
    'xgb_reg__n_estimators': np.arange(100, 250),
    'xgb_reg__reg_lambda': np.logspace(-7, 0, num = 250),
    'xgb_reg__max_depth': np.arange(1, 20),
    'xgb_reg__learning_rate': np.logspace(-3, 0, num = 100),
    'xgb_reg__reg_alpha': np.logspace(-7, 0, num = 250),
    'xgb_reg__subsample': np.arange(0.1, 1.05, 0.05),
    }

randomSearch = BayesSearchCV(estimator = pipe, search_spaces = param,
                             n_iter = 30, cv = tscv, verbose = 5, n_jobs = -1,
                             scoring = 'neg_root_mean_squared_error')
searchResults = randomSearch.fit(predictorsTrain, responsesTrain)

#%% Fitting Final Model

# To run script quickly, comment out when doing Hyperparameter tuning
# nEstimators = 159
# xgbLambda = 0.11070741414515996
# maxDepth = 2
# learnRate = 0.093260334688322
# alpha = 0.006013349774031784
# subsample = 0.55

nEstimators = searchResults.best_params_.get('xgb_reg__n_estimators')
xgbLambda = searchResults.best_params_.get('xgb_reg__reg_lambda')
maxDepth = searchResults.best_params_.get('xgb_reg__max_depth')
learnRate = searchResults.best_params_.get('xgb_reg__learning_rate')
alpha = searchResults.best_params_.get('xgb_reg__reg_alpha')
subsample = searchResults.best_params_.get('xgb_reg__subsample')

pipe.set_params(xgb_reg__n_estimators = nEstimators, xgb_reg__reg_lambda = xgbLambda,
                xgb_reg__max_depth = maxDepth, xgb_reg__learning_rate = learnRate,
                xgb_reg__reg_alpha = alpha, xgb_reg__subsample = subsample)

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
print('Overall Results - Test')    
modelling.regression_results(testResults.yActual, testResults.yHat, xTrain.shape[1])
xValScores = cross_val_score(pipe, predictorsTrain, responsesTrain, cv = tscv,
                             scoring = 'neg_root_mean_squared_error')
intervalRange = -1*np.mean(xValScores)
testResults['ciUpper'] = testResults.yHat + intervalRange
testResults['ciLower'] = testResults.yHat - intervalRange

#%% Visualise Results

visualise.plotActualVsPredicted(trainResults, testResults, (1, 3), "XGB Model - Basicity")

visualise.plotTimeSeriesResults(testResults, origResponsesTest, "XGB Model - Basicity (Test Results)")

visualise.plotTimeSeriesResults(trainResults, origResponsesTrain, "XGB Model - Basicity (Train Results)")

visualise.plotResidualsAndErrors(trainResults, testResults)

convergenceIndicator, convergingPeriod, divergingPeriod = \
    modelling.getDirectionalPerformance(origResponsesTest, testResults)

visualise.plotDirectionalPerformance(origResponsesTest, testResults, convergenceIndicator, "XGB Model - Basicity (Test Results)")

convergingPeriod/(convergingPeriod + divergingPeriod)

#%% Step test
heading = 'Step Tests - XGBoost Model'
mvTag = "Specific Silica Actual PV"

# Start and end date and step fraction of test
start_date = datetime.datetime(2021, 9, 7, 0, 0)
end_date = datetime.datetime(2021, 9, 8, 0, 0)
stepSize = np.array(0.2)

testDFOrig = fullDFOrig[(fullDFOrig.index > start_date) & (fullDFOrig.index <= end_date)]
simFunc = lambda predictors: pipe.predict(predictors)

sim_run = sim.prepareStepTest(testDFOrig, stepSize, predictorTagsNew, mvTag, processingFunc)
sim_run = sim.performStepTest(simFunc, sim_run)
sim.createStepTestPlots(sim_run, responseTags, mvTag, heading)
