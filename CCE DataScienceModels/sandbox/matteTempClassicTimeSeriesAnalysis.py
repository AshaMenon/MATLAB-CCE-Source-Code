# -*- coding: utf-8 -*-
"""
Created on Tue Jun  7 15:54:00 2022

@author: john.atherfold
"""

import pandas as pd
import numpy as np
import datetime
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
from sklearn.cross_decomposition import PLSRegression

import src.preprocessingFunctions as prep
import src.modellingFunctions as modelling
import src.dataExploration as visualise
import src.simulationFunctions as sim
import src.featureEngineeringHelpers as featEng
from statsmodels.graphics.tsaplots import plot_pacf, plot_acf

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

lowFreqPredictors = ["Cr2O3 Slag", "Basicity", "MgO Slag"]#, "Slag temperatures"]

feedblendPredictors = ["Cu Feedblend", "Ni Feedblend",
                       "Co Feedblend", "Fe Feedblend", "S Feedblend",
                       "SiO2 Feedblend", "Al2O3 Feedblend", "CaO Feedblend",
                       "MgO Feedblend", "Cr2O3 Feedblend"]
referenceTags = ["Converter mode", "Lance air & oxygen control"]
# lowFreqPredictors = lowFreqPredictors + feedblendPredictors

predictorTags = highFreqPredictors# + lowFreqPredictors

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
            addRollingSumPredictors={'add': False, 'window': '15min', 'on': highFreqPredictors}, #NOTE: functionality exists to process an 'on' key
            addRollingMeanPredictors={'add': True, 'window': '15min', 'on': highFreqPredictors},
            addRollingMeanResponse={'add': True, 'window': '450min'},
            addMeasureIndicatorsAsPredictors={'add': False, 'on': ['Matte temperatures']}, #NOTE: functionality exists to process an 'on' key
            addShiftsToPredictors={'add': True, 'nLags': 3, 'on': highFreqPredictors},
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

# predictorTagsNew = list(set(predictorTagsNew) - set(predictorTags))
# fullDF = fullDF[predictorTagsNew + responseTags]

# startTime = pd.Timestamp('2021-01-01 00:00')
# endTime = pd.Timestamp('2021-12-01 00:00')
# mask = (fullDF.index >= startTime) & (fullDF.index < endTime)
# fullDF = fullDF.loc[mask]

#%% Time series plots

# matteTempDF = fullDF[["Matte temperatures"]]
# matteTempDF['Trend'] = matteTempDF['Matte temperatures'].rolling(7).mean()
# matteTempDF['Detrended'] = matteTempDF["Matte temperatures"] - matteTempDF['Trend']

# origMatteTempDF = pd.DataFrame()
# origMatteTempDF['Orig Response'] = origSmoothedResponses
# origMatteTempDF['Orig Trend'] = origMatteTempDF['Orig Response'].rolling('450min').mean()
# origMatteTempDF['Orig Detrended'] = origMatteTempDF['Orig Response'] - origMatteTempDF['Orig Trend']
# origMatteTempDF['First Lag'] = origMatteTempDF['Orig Detrended'].shift()
# origMatteTempDF['First Lag Removed'] = origMatteTempDF['Orig Detrended'] - origMatteTempDF['First Lag']

# # axs = matteTempDF[['Matte temperatures', 'Trend', 'Detrended']].plot(subplots = True)

# # plot_acf(origMatteTempDF['Orig Detrended'].dropna(), lags = 10)
# # plot_acf(matteTempDF['Detrended'].dropna(), lags = 10)
# plot_acf(origMatteTempDF['First Lag Removed'].dropna(), lags = 10)

# # plot_pacf(origMatteTempDF['Orig Detrended'].dropna(), lags = 10)
# # plot_pacf(matteTempDF['Detrended'].dropna(), lags = 10)
# plot_pacf(origMatteTempDF['First Lag Removed'].dropna(), lags = 10)
# origMatteTempDF[['Orig Response', 'Orig Trend', 'Orig Detrended', 'First Lag',  'First Lag Removed']].plot(subplots = True)

#%% Split Data

predictorsTrainOrig, responsesTrain, origResponsesTrain,\
    predictorsTestOrig, responsesTest, origResponsesTest = \
    prep.splitIntoTestAndTrain(
    fullDF,
    origSmoothedResponses,
    trainFrac=0.90,
    predictorTags=predictorTagsNew,
    responseTags=responseTags)

#%% Pipeline 1: Removing effects of MA and Lags (Autocorrelation effects)
predictorsTrain = predictorsTrainOrig[['Matte temperatures 450min-rollingmean',
                                       '1-Lag Matte temperatures',]]
predictorsTest = predictorsTestOrig[['Matte temperatures 450min-rollingmean',
                                     '1-Lag Matte temperatures',]]
pipe = Pipeline([('scaler', RobustScaler()),
                 #('pca', PCA()),
                 #('poly', PolynomialFeatures()),
                 ('regression', LinearRegression())])

# param = {
#     'regression__alpha': np.logspace(-5, 3, num = 10000),
#     # 'poly__degree': np.arange(1, 6, 1),
#     # 'pca__n_components': np.arange(10, len(predictorTagsNew), 1),
#     # 'pca__gamma': np.logspace(-7, 0, num = 500),
#     }

# randomSearch = BayesSearchCV(estimator = pipe, search_spaces = param,
#                               n_iter = 100, cv = tscv, verbose = 5, n_jobs = -1,
#                               scoring = 'neg_root_mean_squared_error')
# searchResults = randomSearch.fit(predictorsTrain, responsesTrain)

#%% Testing Algorithm on Out of Sample Data

# Append training data for final model to the testing data set - THIS DATA IS
#   ONLY USED FOR TRAINING THE FIRST FINAL MODEL

xTrain = predictorsTrain
xTest = predictorsTest

yTrain = responsesTrain.values
yTest = responsesTest.values

[pipe, testResults] = modelling.trainAndTestModel(pipe, xTrain, yTrain.ravel(),
                                                    xTest, yTest.ravel(), responsesTest.index)

trainResults = modelling.testModel(pipe, xTrain, yTrain.ravel(), responsesTrain.index)

print('--------------------------------------------------------------')
print('--------------------------------------------------------------')
print(pipe.steps)
print(predictorsTest.columns.to_list())
print('Overall Results - Test')    
print('Training Data Points: ' + str(xTrain.shape[0]))
print('Testing Data Points: ' + str(xTest.shape[0]))
k = predictorsTest.shape[1]
modelling.regression_results(testResults.yActual, testResults.yHat, k)

#%% Results Visualisation - Autoregressive Step

visualise.plotActualVsPredicted(trainResults, testResults, (1150, 1325), "Linear Model - Matte Temperature")

visualise.plotTimeSeriesResults(testResults, origResponsesTest, "Linear Model - Matte Temperature (Test Results)")

visualise.plotTimeSeriesResults(trainResults, origResponsesTrain, "Linear Model - Matte Temperature (Train Results)")

visualise.plotResidualsAndErrors(trainResults, testResults)

convergenceIndicator, convergingPeriod, divergingPeriod = \
    modelling.getDirectionalPerformance(origResponsesTest, testResults)

visualise.plotDirectionalPerformance(origResponsesTest, testResults, convergenceIndicator, "Linear Model - Temperature (Test Results)")

convergingPeriod/(convergingPeriod + divergingPeriod)

#%% Define TS Cross Validation Object
maxTrainSize = int(70*24*60/15)
testSize = int(1*24*60/15)
nSplits = int(np.ceil((len(predictorsTrainOrig) - maxTrainSize)/testSize))

print('Training Data Points: ' + str(maxTrainSize))
print('Validation Data Points: ' + str(testSize))
print('Number of Splits: ' + str(nSplits))

tscv = TimeSeriesSplit(n_splits = nSplits, max_train_size = maxTrainSize,
                       test_size = testSize)

# Pipeline 1: Removing effects of MA and Lags (Autocorrelation effects)
predictorsTrain = predictorsTrainOrig[['Heat flux 15min-rollingmean',
                                       'Matte feed PV 15min-rollingmean']]
predictorsTest = predictorsTestOrig[['Heat flux 15min-rollingmean',
                                     'Matte feed PV 15min-rollingmean']]
responsesTrain = trainResults['yActual'] - trainResults['yHat']
responsesTest = testResults['yActual'] - testResults['yHat']

pipe = Pipeline([('scaler', RobustScaler()),
                  ('pca', PCA()),
                 #('poly', PolynomialFeatures()),
                 ('regression', LinearRegression())])

param = {
    'regression__alpha': np.logspace(-5, 3, num = 10000),
    # 'poly__degree': np.arange(1, 6, 1),
    'pca__n_components': np.arange(2, len(predictorsTrain.columns) + 1, 1),
    # 'pca__gamma': np.logspace(-7, 0, num = 500),
    }

randomSearch = BayesSearchCV(estimator = pipe, search_spaces = param,
                              n_iter = 100, cv = tscv, verbose = 5, n_jobs = -1,
                              scoring = 'neg_root_mean_squared_error')
# searchResults = randomSearch.fit(predictorsTrain, responsesTrain)

#%% Testing Algorithm on Out of Sample Data

# Append training data for final model to the testing data set - THIS DATA IS
#   ONLY USED FOR TRAINING THE FIRST FINAL MODEL
# pipe = searchResults.best_estimator_

xTrain = predictorsTrain
xTest = predictorsTest

yTrain = responsesTrain.values
yTest = responsesTest.values

[pipe, testResults] = modelling.trainAndTestModel(pipe, xTrain, yTrain.ravel(),
                                                    xTest, yTest.ravel(), responsesTest.index)

trainResults = modelling.testModel(pipe, xTrain, yTrain.ravel(), responsesTrain.index)

print('--------------------------------------------------------------')
print('--------------------------------------------------------------')
print(pipe.steps)
print(predictorsTest.columns.to_list())
print('Overall Results - Test')    
print('Training Data Points: ' + str(xTrain.shape[0]))
print('Testing Data Points: ' + str(xTest.shape[0]))
k = predictorsTest.shape[1]
modelling.regression_results(testResults.yActual, testResults.yHat, k)

#%% Results Visualisation - Regressing on Autoreg residuals

visualise.plotActualVsPredicted(trainResults, testResults, (-60, 60), "Linear Model - Matte Temperature")

visualise.plotTimeSeriesResults(testResults, origResponsesTest, "Linear Model - Matte Temperature (Test Results)")

visualise.plotTimeSeriesResults(trainResults, origResponsesTrain, "Linear Model - Matte Temperature (Train Results)")

visualise.plotResidualsAndErrors(trainResults, testResults)

convergenceIndicator, convergingPeriod, divergingPeriod = \
    modelling.getDirectionalPerformance(origResponsesTest, testResults)

visualise.plotDirectionalPerformance(origResponsesTest, testResults, convergenceIndicator, "Linear Model - Temperature (Test Results)")

convergingPeriod/(convergingPeriod + divergingPeriod)

#%% Feature Importance
# modelling.getFeatureImportance(linearMdl, xTest, predictorsTest.columns, 'Linear')

# for idx in np.arange(0, 1000, 50):
#     xTestPointDS = predictorsTestPrepended.iloc[idx]
#     modelling.plotLinearFeatureImportance(pipe, xTestPointDS)


linearMdl = pipe.named_steps['regression']

# pca = pipe.named_steps['pca']

# pcaComps = pca.components_
regressionCoefs = linearMdl.coef_
# predictorWeights = np.matmul(regressionCoefs, pcaComps)
predictorWeights = regressionCoefs

importantIndicators = np.flip(np.argsort(np.abs(predictorWeights)))
topColumns = np.flip(predictorsTest.columns[importantIndicators[0:30]])
topWeights = np.flip(predictorWeights[importantIndicators[0:30]])

plt.figure()
plt.barh(topColumns, topWeights, align = 'center')
plt.title('Linear Model Top 20 Features')