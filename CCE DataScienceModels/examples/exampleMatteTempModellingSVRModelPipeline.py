# -*- coding: utf-8 -*-
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
from sklearn.svm import SVR

import src.preprocessingFunctions as prep
import src.modellingFunctions as modelling
import src.dataExploration as visualise
import src.simulationFunctions as sim
import src.featureEngineeringHelpers as featEng

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
            addRollingSumPredictors={'add': True, 'window': '15min', 'on': highFreqPredictors}, #NOTE: functionality exists to process an 'on' key
            addRollingMeanPredictors={'add': True, 'window': '15min', 'on': highFreqPredictors},
            addRollingMeanResponse={'add': True, 'window': '450min'},
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

predictorTagsNew = list(set(predictorTagsNew) - set(predictorTags))
fullDF = fullDF[predictorTagsNew + responseTags]

# startTime = pd.Timestamp('2021-01-01 00:00')
# endTime = pd.Timestamp('2021-12-01 00:00')
# mask = (fullDF.index >= startTime) & (fullDF.index < endTime)
# fullDF = fullDF.loc[mask]
#%% Split Data

predictorsTrain, responsesTrain, origResponsesTrain,\
    predictorsTest, responsesTest, origResponsesTest = \
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

print('Training Data Points: ' + str(maxTrainSize))
print('Validation Data Points: ' + str(testSize))
print('Number of Splits: ' + str(nSplits))

tscv = TimeSeriesSplit(n_splits = nSplits, max_train_size = maxTrainSize,
                       test_size = testSize)

pipe = Pipeline([('scaler', RobustScaler()),
                 # ('pca', PCA()),
                 # ('poly', PolynomialFeatures()),
                 ('regression', SVR())])

param = {
    'regression__epsilon': np.logspace(-5, 2, num = 10000),
    # 'poly__degree': np.arange(1, 6, 1),
    'regression__C': np.logspace(-1, 5, num = 10000),
    'regression__gamma': np.logspace(-7, 0, num = 500),
    }

randomSearch = BayesSearchCV(estimator = pipe, search_spaces = param,
                              n_iter = 100, cv = tscv, verbose = 5, n_jobs = -1,
                              scoring = 'neg_root_mean_squared_error')
searchResults = randomSearch.fit(predictorsTrain, responsesTrain.values.ravel())

#%% Testing Algorithm on Out of Sample Data

# Append training data for final model to the testing data set - THIS DATA IS
#   ONLY USED FOR TRAINING THE FIRST FINAL MODEL

# n_components = searchResults.best_params_.get('pca__n_components')
# gamma = searchResults.best_params_.get('pca__gamma')
# alpha = searchResults.best_params_.get('regression__alpha')
# alpha = 0.12136237983442417
# alpha = searchResults.best_params_.get('regression__alpha')
# n_components = searchResults.best_params_.get('pca__n_components')
# n_components = 45

# pipe.set_params(regression__alpha = searchResults.best_params_.get('regression__alpha'))
# pipe.set_params(regression__alpha = alpha)
# pipe = searchResults.best_estimator_

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

visualise.plotActualVsPredicted(trainResults, testResults, (1150, 1325), "Linear Model - Matte Temperature")

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

pca = pipe.named_steps['pca']

pcaComps = pca.components_
regressionCoefs = linearMdl.coef_
predictorWeights = np.matmul(regressionCoefs, pcaComps)
# predictorWeights = regressionCoefs

importantIndicators = np.flip(np.argsort(np.abs(predictorWeights)))
topColumns = np.flip(predictorsTest.columns[importantIndicators[0:30]])
topWeights = np.flip(predictorWeights[importantIndicators[0:30]])

plt.figure()
plt.barh(topColumns, topWeights, align = 'center')
plt.title('Linear Model Top 20 Features')

#%% Step test
# heading = 'Step Tests - Linear Model'
# mvTag = "Fuel coal feed rate PV"

# # Start and end date and step fraction of test
# start_date = datetime.datetime(2021, 9, 7, 0, 0)
# end_date = datetime.datetime(2021, 9, 8, 0, 0)
# stepSize = np.array(0.2)

# testDFOrig = fullDFOrig[(fullDFOrig.index > start_date) & (fullDFOrig.index <= end_date)]
# simFunc = lambda predictors: pipe.predict(predictors)
# processingFuncAdapted = lambda fullDFOrig: processingFunc(fullDFOrig, predictorTags, highFreqPredictors, lowFreqPredictors)

# sim_run = sim.prepareStepTest(testDFOrig, stepSize, predictorTagsNew, mvTag, processingFuncAdapted)
# sim_run = sim.performStepTest(simFunc, sim_run)
# sim.createStepTestPlots(sim_run, responseTags, mvTag + ' rollingsum', heading)
