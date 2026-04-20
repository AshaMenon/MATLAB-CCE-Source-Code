# -*- coding: utf-8 -*-

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.linear_model import LinearRegression
from sklearn.linear_model import PoissonRegressor
from sklearn.linear_model import Ridge
from sklearn.svm import SVR
from sklearn.tree import DecisionTreeRegressor
from sklearn.ensemble import RandomForestRegressor
from sklearn.decomposition import PCA
from sklearn.preprocessing import RobustScaler
from sklearn.model_selection import cross_val_score
from sklearn.model_selection import RandomizedSearchCV
from skopt import BayesSearchCV
from sklearn.model_selection import TimeSeriesSplit
from sklearn.pipeline import Pipeline
from datetime import datetime
import shap
import src.preprocessingFunctions as prep
import src.modellingFunctions as modelling
import src.dataExploration as visualise

#%% Read and Format Data
predictorTags = ["Fe Slag", "MgO Slag", "CaO Slag", "SiO2 Slag", "Al2O3 Slag",
                  "Ni Slag", "S Slag", "S Matte", "Specific Oxygen Actual PV",
                  "Specific Silica Actual PV", "Matte feed PV(filtered)",
                  "Lance oxygen flow rate PV", "Lance air flow rate PV",
                  "Lance feed PV", "Silica PV", "Lump Coal PV",
                  "Slag temperatures", "Matte temperatures",
                  "Matte transfer air flow", "Fe Feedblend", "S Feedblend",
                  "SiO2 Feedblend", "Al2O3 Feedblend", "CaO Feedblend",
                  "MgO Feedblend", "Cr2O3 Feedblend", "Corrected Ni Slag",
                  "Fe Matte", "Fuel coal feed rate PV"]
responseTags = ["Basicity"]

fullDFOrig = prep.readAndFormatData('Chemistry', responseTags=responseTags,
        predictorTags=predictorTags)

#%%  
fullDF, origSmoothedResponses, predictorTagsNew = \
    prep.preprocessingAndFeatureEngineering(
        fullDFOrig,
        removeTransientData=True,
        smoothBasicityResponse=True,
        addRollingSumPredictors={'add': True, 'window': 19}, #NOTE: functionality exists to process an 'on' key
        addRollingMeanPredictors={'add': True, 'window': 5},
        addMeasureIndicatorsAsPredictors={'add': True}, #NOTE: functionality exists to process an 'on' key
        addShiftsToPredictors={'add': True, 'nLags': 3},
        addResponsesAsPredictors={'add': True, 'nLags': 5},
        resampleTime = '1min',
        resampleMethod = 'cubic',
        responseTags=responseTags,
        predictorTags=predictorTags)

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
                 ('pca', PCA()),
                 ('randomForest', RandomForestRegressor())])

param = {
    'randomForest__n_estimators': np.arange(40, 151), 
    'randomForest__min_samples_split': np.arange(2, 101),
    'randomForest__min_samples_leaf': np.arange(1, 101),
    'randomForest__max_depth': np.arange(1, 101)}

randomSearch = BayesSearchCV(estimator = pipe, search_spaces = param,
                              n_iter = 20, cv = tscv, verbose = 5, n_jobs = -1,
                              scoring = 'r2')
searchResults = randomSearch.fit(predictorsTrain, responsesTrain)

#%% Testing Algorithm on Out of Sample Data

# Append training data for final model to the testing data set - THIS DATA IS
#   ONLY USED FOR TRAINING THE FIRST FINAL MODEL

predictorsTestPrepended = pd.concat((predictorsTrain[-maxTrainSize:], predictorsTest))
responsesTestPrepended = pd.concat((responsesTrain[-maxTrainSize:], responsesTest))
nSplits = int(np.ceil((len(predictorsTestPrepended) - maxTrainSize)/testSize))
tscv = TimeSeriesSplit(n_splits = nSplits, max_train_size = maxTrainSize,
                       test_size = testSize)

testResults = pd.DataFrame()
trainResults = pd.DataFrame()
for train_index, test_index in tscv.split(predictorsTestPrepended):
    xTrain, xTest = predictorsTestPrepended.iloc[train_index], \
        predictorsTestPrepended.iloc[test_index]
    yTrainDS, yTestDS = responsesTestPrepended.iloc[train_index], \
        responsesTestPrepended.iloc[test_index]

    scaler = RobustScaler()
    xTrain = scaler.fit_transform(xTrain)
    xTest = scaler.transform(xTest)
    
    nEstimators = searchResults.best_params_.get('randomForest__n_estimators')
    minSamplesSplit = searchResults.best_params_.get('randomForest__min_samples_split')
    minSamplesLeaf = searchResults.best_params_.get('randomForest__min_samples_leaf')
    maxDepth = searchResults.best_params_.get('randomForest__max_depth')
    nComponents = searchResults.best_params_.get('pca__n_components')
    
    # To run script quickly, comment out when doing Hyperparameter tuning
    # nEstimators = 41
    # minSamplesSplit = 41
    # minSamplesLeaf = 65
    # maxDepth = 57
    
    forestMdl = RandomForestRegressor(n_estimators = nEstimators,
                                    min_samples_split = minSamplesSplit,
                                    min_samples_leaf = minSamplesLeaf,
                                    max_depth=maxDepth)
    
    pca = PCA()
    
    xTrain = pca.fit_transform(xTrain)
    xTest = pca.transform(xTest)

    yTrain = yTrainDS.values
    yTest = yTestDS.values
    
    [forestMdl, latestTestResults] = modelling.trainAndTestModel(forestMdl, xTrain, yTrain.ravel(),
                                                        xTest, yTest.ravel(), yTestDS.index)
    
    latestTrainResults = modelling.testModel(forestMdl, xTrain, yTrain.ravel(), yTrainDS.index)
    
    testResults = pd.concat((testResults, latestTestResults))
    trainResults = pd.concat((trainResults, latestTrainResults))
    
print('--------------------------------------------------------------')
print('Overall Results - Test')    
modelling.regression_results(testResults.yActual, testResults.yHat)

#%% Results Visualisation

visualise.plotActualVsPredicted(trainResults, testResults, (1, 3), "Forest Model - Basicity")

visualise.plotTimeSeriesResults(testResults, origResponsesTest, "Forest Model - Basicity (Test Results)")

visualise.plotTimeSeriesResults(trainResults, origResponsesTrain, "Forest Model - Basicity (Train Results)")

visualise.plotResidualsAndErrors(trainResults, testResults)

convergenceIndicator, convergingPeriod, divergingPeriod = \
    modelling.getDirectionalPerformance(origResponsesTest, testResults)

visualise.plotDirectionalPerformance(origResponsesTest, testResults, convergenceIndicator, "Forest Model - Basicity (Test Results)")

convergingPeriod/(convergingPeriod + divergingPeriod)

#%% Feature Importance
# Forest Model built in feature importance
# modelling.getFeatureImportance(forestMdl, predictorsTest.values, predictorsTest.columns, 'Random Forest')
