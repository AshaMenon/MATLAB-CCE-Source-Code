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
from sklearn.preprocessing import StandardScaler
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
                 "Reverts feed rate PV", "PGM feed rate PV",
                 "Matte transfer air flow", "Fe Feedblend", "S Feedblend",
                 "SiO2 Feedblend", "Al2O3 Feedblend", "CaO Feedblend",
                 "MgO Feedblend", "Cr2O3 Feedblend", "Fe Matte"]
responseTags = ['Corrected Ni Slag']

fullDF, predictorTags, responseTags = \
    prep.readAndFormatData(
        'Chemistry',
        responseTags=responseTags,
        predictorTags=predictorTags,
        removeTransientData=True,
        addRollingSumPredictors={'add': True, 'window': 30},
        smoothBasicityResponse=True,
        addResponsesAsPredictors=True,
        addMeasureIndicatorsAsPredictors={'add': True, 'on': ['Corrected Ni Slag']}
    )

predictorsTrain, responsesTrain, origResponsesTrain, predictorsTest, responsesTest, origResponsesTest = \
    prep.splitIntoTestAndTrain(
    fullDF,
    trainFrac=0.85,
    predictorTags=predictorTags,
    responseTags=responseTags
)

# Define TS Cross Validation Object
maxTrainSize = 30*24*60
testSize = 7*24*60
# nSplits = int(np.ceil((len(predictorsTrain) - maxTrainSize)/testSize))
# tscv = TimeSeriesSplit(n_splits = nSplits, max_train_size = maxTrainSize,
#                        test_size = testSize)

pipe = Pipeline([('scaler', StandardScaler()), ('pca', PCA()),
                  ('randomForest', RandomForestRegressor())])

param = {
    'pca__n_components': np.arange(10, 62),
    'randomForest__n_estimators': np.arange(40, 151), 
    'randomForest__min_samples_split': np.arange(2, 101),
    'randomForest__min_samples_leaf': np.arange(1, 101),
    'randomForest__max_depth': np.arange(1, 101)}

# randomSearch = BayesSearchCV(estimator = pipe, search_spaces = param,
#                              n_iter = 20, cv = tscv, verbose = 5, n_jobs = -1,
#                              scoring = 'neg_root_mean_squared_error')
# searchResults = randomSearch.fit(predictorsTrain, responsesTrain)

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
    X_train, X_test = predictorsTestPrepended.iloc[train_index], predictorsTestPrepended.iloc[test_index]
    y_train, y_test = responsesTestPrepended.iloc[train_index], responsesTestPrepended.iloc[test_index]

    scaler = StandardScaler()
    scaledPredictorsTrain = scaler.fit_transform(X_train)
    scaledPredictorsTest = scaler.transform(X_test)
    
    # nEstimators = searchResults.best_params_.get('randomForest__n_estimators')
    # minSamplesSplit = searchResults.best_params_.get('randomForest__min_samples_split')
    # minSamplesLeaf = searchResults.best_params_.get('randomForest__min_samples_leaf')
    # maxDepth = searchResults.best_params_.get('randomForest__max_depth')
    # nComponents = searchResults.best_params_.get('pca__n_components')
    
    # To run script quickly, comment out when doing Hyperparameter tuning
    nEstimators = 93
    minSamplesSplit = 26
    minSamplesLeaf = 11
    maxDepth = 18
    nComponents = 24
    
    forestMdl = RandomForestRegressor(n_estimators = nEstimators,
                                    min_samples_split = minSamplesSplit,
                                    min_samples_leaf = minSamplesLeaf,
                                    max_depth=maxDepth)
    
    pca = PCA(n_components = nComponents)
    
    pcaPredictorsTrain = pca.fit_transform(scaledPredictorsTrain)
    pcaPredictorsTest = pca.transform(scaledPredictorsTest)
    
    xTrain = pcaPredictorsTrain
    yTrain = y_train.values
    
    xTest = pcaPredictorsTest
    yTest = y_test.values
    
    [forestMdl, latestTestResults] = modelling.trainAndTestModel(forestMdl, xTrain, yTrain.ravel(),
                                                        xTest, yTest.ravel(), y_test.index)
    
    latestTrainResults = modelling.testModel(forestMdl, xTrain, yTrain.ravel(), y_train.index)
    
    testResults = pd.concat((testResults, latestTestResults))
    trainResults = pd.concat((trainResults, latestTrainResults))
    
# print('--------------------------------------------------------------')
# print('Overall Results - Test')    
# modelling.regression_results(testResults.yActual, testResults.yHat)

# #%% Results Visualisation

# visualise.plotActualVsPredicted(trainResults, testResults, (1, 3), "Forest Model - Corrected Ni Slag")

# visualise.plotTimeSeriesResults(testResults, origResponsesTest, "Forest Model - Corrected Ni Slag (Test Results)")

# visualise.plotTimeSeriesResults(trainResults, origResponsesTrain, "Forest Model - Corrected Ni Slag (Train Results)")

# visualise.plotResidualsAndErrors(trainResults, testResults)

# #%% Feature Importance
# # Forest Model built in feature importance
# modelling.getFeatureImportance(forestMdl, predictorsTest.values, predictorsTest.columns, 'Random Forest')
