# -*- coding: utf-8 -*-
"""
Created on Thu Nov  4 13:19:02 2021

@author: john.atherfold
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.linear_model import LinearRegression
from sklearn.linear_model import PoissonRegressor
from sklearn.linear_model import Ridge
from sklearn.linear_model import Lasso
from sklearn.svm import SVR
from sklearn.tree import DecisionTreeRegressor
from sklearn.ensemble import RandomForestRegressor
from sklearn.decomposition import PCA
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import cross_val_score
from skopt import BayesSearchCV
from sklearn.model_selection import TimeSeriesSplit
from sklearn.pipeline import Pipeline
from sklearn.model_selection import RandomizedSearchCV


import src.preprocessingFunctions as prep
import src.modellingFunctions as modelling
import src.dataExploration as visualise
# from gekko import GEKKO
import random

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
        addResponsesAsPredictors=False,
        addMeasureIndicatorsAsPredictors={'add': False}
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
nSplits = int(np.ceil((len(predictorsTrain) - maxTrainSize)/testSize))
tscv = TimeSeriesSplit(n_splits = nSplits, max_train_size = maxTrainSize,
                       test_size = testSize)

pipe = Pipeline([('scaler', StandardScaler()), ('pca', PCA()),
                  ('lasso', Lasso())])

param = {
    'lasso__alpha': np.logspace(-10, -1, num = 1000),
    }

randomSearch = BayesSearchCV(estimator = pipe, search_spaces = param,
                             n_iter = 50, cv = tscv, verbose = 5, n_jobs = -1,
                             scoring = 'r2')
# searchResults = randomSearch.fit(predictorsTrain, responsesTrain)

#%% Fitting Final Model

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

    # alpha = searchResults.best_params_.get('lasso__alpha')

    # To run script quickly, comment out when doing Hyperparameter tuning
    alpha = 0.0004977023564332114

    linearMdl = Lasso(alpha = alpha)

    pca = PCA()

    pcaPredictorsTrain = pca.fit_transform(scaledPredictorsTrain)
    pcaPredictorsTest = pca.transform(scaledPredictorsTest)

    xTrain = pcaPredictorsTrain
    yTrain = y_train.values

    xTest = pcaPredictorsTest
    yTest = y_test.values

    [linearMdl, latestTestResults] = modelling.trainAndTestModel(linearMdl, xTrain, yTrain.ravel(),
                                                        xTest, yTest.ravel(), y_test.index)

    latestTrainResults = modelling.testModel(linearMdl, xTrain, yTrain.ravel(), y_train.index)

    testResults = pd.concat((testResults, latestTestResults))
    trainResults = pd.concat((trainResults, latestTrainResults))

# print('--------------------------------------------------------------')
# print('Overall Results - Test')    
# modelling.regression_results(testResults.yActual, testResults.yHat)

# #%% Visualise Results

# visualise.plotActualVsPredicted(trainResults, testResults, (1, 3), "Linear Model - Corrected Ni Slag")

# visualise.plotTimeSeriesResults(testResults, origResponsesTest, "Linear Model - Corrected Ni Slag (Test Results)")

# visualise.plotTimeSeriesResults(trainResults, origResponsesTrain, "Linear Model - Corrected Ni Slag (Train Results)")

# visualise.plotResidualsAndErrors(trainResults, testResults)

# #%% Feature Importance
# modelling.getFeatureImportance(linearMdl, xTest, predictorsTest.columns, 'Linear')

# comps = pca.components_
# coefs = linearMdl.coef_
# predictorWeights = np.sum(coefs[:, np.newaxis]*comps, axis = 0)

# importantIndicators = np.flip(np.argsort(np.abs(predictorWeights)))
# top20Columns = np.flip(predictorsTest.columns[importantIndicators[0:20]])
# top20Weights = np.flip(np.abs(predictorWeights[importantIndicators[0:20]]))

# plt.figure()
# plt.barh(top20Columns, top20Weights, align = 'center')
# plt.title('Linear Model Top 20 Features')