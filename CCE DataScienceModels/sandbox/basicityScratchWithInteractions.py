# -*- coding: utf-8 -*-
"""
Created on Thu Feb 17 14:01:36 2022

@author: john.atherfold
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from sklearn.linear_model import Lasso
from sklearn.preprocessing import StandardScaler
from sklearn.preprocessing import PolynomialFeatures
from sklearn.preprocessing import FunctionTransformer
from sklearn.decomposition import PCA
from skopt import BayesSearchCV
from sklearn.model_selection import TimeSeriesSplit
from sklearn.pipeline import Pipeline
from src import featureEngineeringHelpers as feh

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
                 "Reverts feed rate PV",
                 "Matte transfer air flow", "Fe Feedblend", "S Feedblend",
                 "SiO2 Feedblend", "Al2O3 Feedblend", "CaO Feedblend",
                 "MgO Feedblend", "Cr2O3 Feedblend", "Corrected Ni Slag",
                 "Fe Matte", "Fuel coal feed rate"]
responseTags = ['Basicity']

fullDF, predictorTags, responseTags = \
    prep.readAndFormatData(
        'Chemistry',
        responseTags=responseTags,
        predictorTags=predictorTags,
        removeTransientData=True,
        addRollingSumPredictors={'add': False, 'window': 30},
        addRollingMeanPredictors={'add': True, 'window': 5},
        smoothBasicityResponse=True,
        addResponsesAsPredictors=True,
        addMeasureIndicatorsAsPredictors={'add': False},
        addShiftsToPredictors={'add': True, 'numberOfShifts': 5}
    )

predictorsTrain, responsesTrain, origResponsesTrain, predictorsTest, responsesTest, origResponsesTest = \
    prep.splitIntoTestAndTrain(
    fullDF,
    trainFrac=0.85,
    predictorTags=predictorTags,
    responseTags=responseTags
)
    
rollingMeanColumns = [col for col in fullDF.columns if 'rollingmean' in col]

#%% Visualise Raw Predictors

[u, irregularIdx] =feh.getUniqueDataPoints(origResponsesTrain.dropna())
predictorsToUse = predictorsTrain.loc[:u.index[-1]]
p = predictorsToUse.groupby(irregularIdx[irregularIdx.searchsorted(predictorsToUse.index)]).mean()

for tag in predictorTags:
    visualise.plotExploratoryVisualisations(p[tag], u["Basicity"])

#%% Define TS Cross Validation Object
maxTrainSize = 30*24*60
testSize = 7*24*60
nSplits = int(np.ceil((len(predictorsTrain) - maxTrainSize)/testSize))
tscv = TimeSeriesSplit(n_splits = nSplits, max_train_size = maxTrainSize,
                       test_size = testSize)

pipe = Pipeline([('interactions', PolynomialFeatures(interaction_only = True)),
                 ('lasso', Lasso())])

param = {
    'lasso__alpha': np.logspace(-9, 1, num = 2000),
    }

randomSearch = BayesSearchCV(estimator = pipe, search_spaces = param,
                             n_iter = 50, cv = tscv, verbose = 5, n_jobs = 5,
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

    interactionMdl = PolynomialFeatures(interaction_only = True)
    interactionPredictorsTrain = interactionMdl.fit_transform(X_train)
    interactionPredictorsTest = interactionMdl.transform(X_test)
    
    # logLink = FunctionTransformer(np.log1p)
    # loggedTrain = logLink.fit_transform(interactionPredictorsTrain)
    # loggedTest = logLink.transform(interactionPredictorsTest)
    
    # scaler = StandardScaler()
    # scaledDataTrain = scaler.fit_transform(interactionPredictorsTrain)
    # scaledDataTest = scaler.transform(interactionPredictorsTest)
    
    # pca = PCA()
    # pcaPredictorsTrain = pca.fit_transform(scaledDataTrain)
    # pcaPredictorsTest = pca.transform(scaledDataTest)

    # alpha = searchResults.best_params_.get('lasso__alpha')

    # To run script quickly, comment out when doing Hyperparameter tuning
    alpha = 2.2918178099236434e-09

    linearMdl = Lasso(alpha = alpha)
    xTrain = interactionPredictorsTrain
    yTrain = y_train.values

    xTest = interactionPredictorsTest
    yTest = y_test.values

    [linearMdl, latestTestResults] = modelling.trainAndTestModel(linearMdl, xTrain, yTrain.ravel(),
                                                        xTest, yTest.ravel(), y_test.index)

    latestTrainResults = modelling.testModel(linearMdl, xTrain, yTrain.ravel(), y_train.index)

    testResults = pd.concat((testResults, latestTestResults))
    trainResults = pd.concat((trainResults, latestTrainResults))

print('--------------------------------------------------------------')
print('Overall Results - Test')    
modelling.regression_results(testResults.yActual, testResults.yHat)

#%% Visualise Results

visualise.plotActualVsPredicted(trainResults, testResults, (1, 3), "Interaction Model - Basicity")

visualise.plotTimeSeriesResults(testResults, origResponsesTest, "Interaction Model - Basicity (Test Results)")

visualise.plotTimeSeriesResults(trainResults, origResponsesTrain, "Interaction Model - Basicity (Train Results)")

visualise.plotResidualsAndErrors(trainResults, testResults)

convergenceIndicator, convergingPeriod, divergingPeriod = \
    modelling.getDirectionalPerformance(origResponsesTest, testResults)

visualise.plotDirectionalPerformance(origResponsesTest, testResults, convergenceIndicator, "Interaction Model - Basicity (Test Results)")

convergingPeriod/(convergingPeriod + divergingPeriod)

#%% Feature Importance

# modelling.getFeatureImportance(linearMdl, xTest, predictorsTest.columns, 'Linear')

# comps = pca.components_
# coefs = linearMdl.coef_
# predictorWeights = np.sum(coefs[:, np.newaxis]*comps, axis = 0)

# fullFeatureNames = np.array(interactionMdl.get_feature_names(predictorsTest.columns))
# importantIndicators = np.flip(np.argsort(np.abs(predictorWeights)))
# top20Columns = np.flip(fullFeatureNames[importantIndicators[0:50]])
# top20Weights = np.flip(np.abs(predictorWeights[importantIndicators[0:50]]))

# plt.figure()
# plt.barh(top20Columns, top20Weights, align = 'center')
# plt.title('Linear Model Top 20 Features')