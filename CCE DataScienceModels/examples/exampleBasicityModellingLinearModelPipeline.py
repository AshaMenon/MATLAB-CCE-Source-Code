# -*- coding: utf-8 -*-
"""
Created on Thu Nov  4 13:19:02 2021

@author: john.atherfold
"""

import pandas as pd
import numpy as np
import datetime
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.linear_model import LinearRegression
from sklearn.linear_model import PoissonRegressor
from sklearn.linear_model import Ridge
from sklearn.linear_model import Lasso
from sklearn.linear_model import HuberRegressor
from sklearn.svm import SVR
from sklearn.tree import DecisionTreeRegressor
from sklearn.ensemble import RandomForestRegressor
from sklearn.decomposition import PCA
from sklearn.preprocessing import RobustScaler
from sklearn.preprocessing import PolynomialFeatures
from sklearn.model_selection import cross_val_score
from skopt import BayesSearchCV
from sklearn.model_selection import TimeSeriesSplit
from sklearn.pipeline import Pipeline
from sklearn.model_selection import RandomizedSearchCV


import Shared.DSModel.src.preprocessingFunctions as prep
import src.simulationFunctions as sim
import src.modellingFunctions as modelling
import src.dataExploration as visualise
# from gekko import GEKKO
import random

#%% Read and Format Data

highFreqPredictors = ["Specific Oxygen Actual PV",
                      "Specific Silica Actual PV", "Matte feed PV(filtered)",
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
referenceTags = ["Converter mode", "Lance air & oxygen control", "SumOfSpecies"]
fullDFOrig = prep.readAndFormatData('Chemistry')

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
            addMeasureIndicatorsAsPredictors={'add': False, 'on': ['Basicity', 'Fe Feedblend', 'Matte temperatures']}, #NOTE: functionality exists to process an 'on' key
            addShiftsToPredictors={'add': False, 'nLags': 5, 'on': highFreqPredictors},
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

# More useful for temp model - attenuates noise
# predictorTagsNew = list(set(predictorTagsNew) - set(predictorTags) - set(['Heat flux']))
# fullDF = fullDF[predictorTagsNew + responseTags]

# times
startTime = pd.Timestamp('2021-01-01 00:00')
endTime = pd.Timestamp('2021-09-08 08:00')
mask = (fullDF.index >= startTime) & (fullDF.index <= endTime)
fullDF = fullDF.loc[mask]

predictorsTrain, responsesTrain, origResponsesTrain, predictorsTest, responsesTest, origResponsesTest = \
    prep.splitIntoTestAndTrain(
    fullDF,
    origSmoothedResponses,
    trainFrac=0.85,
    predictorTags=predictorTagsNew,
    responseTags=responseTags)

#%% Define TS Cross Validation Object
maxTrainSize = int(70*24*60)
testSize = int(7*24*60)
nSplits = int(np.ceil((len(predictorsTrain) - maxTrainSize)/testSize))
tscv = TimeSeriesSplit(n_splits = nSplits, max_train_size = maxTrainSize,
                       test_size = testSize)

pipe = Pipeline([('scaler', RobustScaler()),
                 ('pca', PCA()),
                 ('regression', LinearRegression())])

param = {
    'pca__n_components': np.arange(1, len(predictorTagsNew)+1, 1),
    # 'regression__alpha': np.logspace(-10, 2, 5000),
    }

randomSearch = BayesSearchCV(estimator = pipe, search_spaces = param,
                             n_iter = 20, cv = tscv, verbose = 5, n_jobs = -1,
                             scoring = 'neg_root_mean_squared_error')
searchResults = randomSearch.fit(predictorsTrain, responsesTrain.values.ravel())

#%% Fitting Final Model

# alpha = searchResults.best_params_.get('regression__alpha')
# n_components = searchResults.best_params_.get('pca__n_components')
# alpha = 2.909998590008051e-07
# n_components = 113

# pipe.set_params(regression__alpha = searchResults.best_params_.get('regression__alpha'))
# pipe.set_params(regression__alpha = alpha, pca__n_components = n_components)

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
k = pipe.named_steps.get('pca').n_components # k is number of predictors that the ML model sees
modelling.regression_results(testResults.yActual, testResults.yHat, k)

#%% Visualise Results

visualise.plotActualVsPredicted(trainResults, testResults, (1, 3), "Linear Model - Basicity")

visualise.plotTimeSeriesResults(testResults, origResponsesTest, "Linear Model - Basicity (Test Results)")

visualise.plotTimeSeriesResults(trainResults, origResponsesTrain, "Linear Model - Basicity (Train Results)")

visualise.plotResidualsAndErrors(trainResults, testResults)

convergenceIndicator, convergingPeriod, divergingPeriod = \
    modelling.getDirectionalPerformance(origResponsesTest, testResults)

visualise.plotDirectionalPerformance(origResponsesTest, testResults, convergenceIndicator, "Linear Model - Basicity (Test Results)")

convergingPeriod/(convergingPeriod + divergingPeriod)

#%% Feature Importance

linearMdl = pipe.named_steps['regression']
# modelling.getShapFeatureImportance(linearMdl, xTest, predictorsTest.columns, 'Linear')

pca = pipe.named_steps['pca']

pcaComps = pca.components_
regressionCoefs = linearMdl.coef_
predictorWeights = np.matmul(regressionCoefs, pcaComps)

importantIndicators = np.flip(np.argsort(np.abs(predictorWeights)))
top20Columns = np.flip(predictorsTest.columns[importantIndicators[0:20]])
top20Weights = np.flip(predictorWeights[importantIndicators[0:20]])

plt.figure()
plt.barh(top20Columns, top20Weights, align = 'center')
plt.title('Linear Model Top 20 Features')

#%% Feature Importance
# modelling.getFeatureImportance(linearMdl, xTest, predictorsTest.columns, 'Linear')

# for idx in np.arange(0, 1000, 50):
#     xTestPointDS = predictorsTestPrepended.iloc[idx]
#     modelling.plotLinearFeatureImportance(pipe, xTestPointDS)

# linearMdl = pipe.named_steps['regression']
# pca = pipe.named_steps['pca']

# pcaComps = pca.components_
# regressionCoefs = linearMdl.coef_
# predictorWeights = np.matmul(regressionCoefs, pcaComps)
# # predictorWeights = regressionCoefs

# importantIndicators = np.flip(np.argsort(np.abs(predictorWeights)))
# topColumns = np.flip(predictorsTest.columns[importantIndicators[0:30]])
# topWeights = np.flip(predictorWeights[importantIndicators[0:30]])

# plt.figure()
# plt.barh(topColumns, topWeights, align = 'center')
# plt.title('Linear Model Top 20 Features')

# #%% Step test
# heading = 'Step Tests - Linear Model'
# mvTag = "Specific Silica Actual PV"

# # Start and end date and step fraction of test
# start_date = datetime.datetime(2021, 9, 7, 0, 0)
# end_date = datetime.datetime(2021, 9, 8, 0, 0)
# stepSize = np.array(0.2)

# testDFOrig = fullDFOrig[(fullDFOrig.index > start_date) & (fullDFOrig.index <= end_date)]
# simFunc = lambda predictors: pipe.predict(predictors)

# sim_run = sim.prepareStepTest(testDFOrig, stepSize, predictorTagsNew, mvTag, processingFunc)
# sim_run = sim.performStepTest(simFunc, sim_run)
# sim.createStepTestPlots(sim_run, responseTags, mvTag, heading)
