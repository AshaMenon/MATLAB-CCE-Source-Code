# -*- coding: utf-8 -*-
"""
Created on Fri Jul 15 13:20:29 2022

@author: darshan.makan
"""
#Sandbox for implementing exponential smoothing

#%%

import pandas as pd
import numpy as np
import datetime
import matplotlib.pyplot as plt
from statsmodels.tsa.api import SimpleExpSmoothing
from sklearn.linear_model import Lasso
from sklearn.decomposition import PCA
from sklearn.preprocessing import RobustScaler
from skopt import BayesSearchCV
from sklearn.model_selection import TimeSeriesSplit
from sklearn.pipeline import Pipeline
import pickle
import os


import src.preprocessingFunctions as prep
import src.modellingFunctions as modelling
import src.dataExploration as visualise
import src.simulationFunctions as sim
from xgboost import XGBRegressor
from sklearn.model_selection import cross_val_score

#%% Read and Format Data
highFreqPredictors = ["Specific Oxygen Actual PV",
                      "Specific Silica Actual PV", "Matte feed PV filtered",
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
referenceTags = ["Converter mode", "Lance air and oxygen control", "SumOfSpecies"]

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
            addMeasureIndicatorsAsPredictors={'add': True, 'on': ['Basicity', 'Fe Feedblend', 'Matte temperatures']}, #NOTE: functionality exists to process an 'on' key
            addShiftsToPredictors={'add': True, 'nLags': 5, 'on': highFreqPredictors},
            addResponsesAsPredictors={'add': True, 'nLags': 1},
            resampleTime = '1min',
            resampleMethod = 'linear',
            responseTags=responseTags,
            predictorTags=predictorTags,
            referenceTags=referenceTags,
            highFrequencyPredictorTags = highFreqPredictors,
            lowFrequencyPredictorTags = lowFreqPredictors)
    return fullDF, origSmoothedResponses, predictorTagsNew

# start = datetime.datetime(2022,4,1,0,0)
# end = datetime.datetime(2022,4,30,2,0)

fullDF, origSmoothedResponses, predictorTagsNew = processingFunc(fullDFOrig) #[start:end])

predictorsTrain, responsesTrain, origResponsesTrain, predictorsTest, responsesTest, origResponsesTest = \
    prep.splitIntoTestAndTrain(
    fullDF,
    origSmoothedResponses,
    trainFrac=0.85,
    predictorTags=predictorTagsNew,
    responseTags=responseTags)

#%% Define TS Cross Validation Object
maxTrainSize = int(90*24*60)
testSize = int(0.5*24*60)
nSplits = int(np.ceil((len(predictorsTrain) - maxTrainSize)/testSize))
tscv = TimeSeriesSplit(n_splits = nSplits, max_train_size = maxTrainSize,
                       test_size = testSize)

pipe = Pipeline([('scaler', RobustScaler()),
                 ('pca', PCA()),
                 ('xgb_reg', XGBRegressor(objective='reg:squarederror',
                                          booster='gbtree'))])

param = {
    'pca__n_components': np.arange(50, len(predictorTagsNew)-1, 1),
    'xgb_reg__n_estimators': np.arange(100, 250),
    'xgb_reg__reg_lambda': np.logspace(-7, 0, num = 250),
    'xgb_reg__max_depth': np.arange(1, 20),
    'xgb_reg__learning_rate': np.logspace(-3, 0, num = 100),
    'xgb_reg__reg_alpha': np.logspace(-7, 0, num = 250),
    'xgb_reg__subsample': np.arange(0.1, 1.05, 0.05),
    'xgb_reg__colsample_bytree': np.arange(0,1,0.05),
    'xgb_reg__colsample_bylevel': np.arange(0,1,0.05),
    'xgb_reg__colsample_bynode': np.arange(0,1,0.05)
    }

randomSearch = BayesSearchCV(estimator = pipe, search_spaces = param,
                             n_iter = 30, cv = tscv, verbose = 5, n_jobs = -1,
                             scoring = 'neg_root_mean_squared_error')
# searchResults = randomSearch.fit(predictorsTrain, responsesTrain)

#%% Fitting Final Model

# To run script quickly, comment out when doing Hyperparameter tuning
# n_components = 77
# nEstimators = 157
# xgbLambda = 1.474601593214192e-07
# maxDepth = 7
# learnRate = 0.1
# alpha = 3.5171001812327933e-06
# subsample = 0.8500000000000002
# colsample_bytree = 0.35000000000000003
# colsample_bylevel = 0.9500000000000001
# colsample_bynode = 0.8500000000000001

n_components = searchResults.best_params_.get('pca__n_components')
nEstimators = searchResults.best_params_.get('xgb_reg__n_estimators')
xgbLambda = searchResults.best_params_.get('xgb_reg__reg_lambda')
maxDepth = searchResults.best_params_.get('xgb_reg__max_depth')
learnRate = searchResults.best_params_.get('xgb_reg__learning_rate')
alpha = searchResults.best_params_.get('xgb_reg__reg_alpha')
subsample = searchResults.best_params_.get('xgb_reg__subsample')
colsample_bytree = searchResults.best_params_.get('xgb_reg__colsample_bytree')
colsample_bylevel = searchResults.best_params_.get('xgb_reg__colsample_bylevel')
colsample_bynode = searchResults.best_params_.get('xgb_reg__colsample_bynode')

# pca__n_components = n_components,
pipe.set_params(pca__n_components = n_components ,xgb_reg__n_estimators = nEstimators, xgb_reg__reg_lambda = xgbLambda,
                xgb_reg__max_depth = maxDepth, xgb_reg__learning_rate = learnRate,
                xgb_reg__reg_alpha = alpha, xgb_reg__subsample = subsample, 
                xgb_reg__colsample_bytree = colsample_bytree, xgb_reg__colsample_bylevel = colsample_bylevel,
                xgb_reg__colsample_bynode = colsample_bynode)

predictorsTestPrepended = pd.concat((predictorsTrain[-maxTrainSize:], predictorsTest))
responsesTestPrepended = pd.concat((responsesTrain[-maxTrainSize:], responsesTest))
# predictorsTestPrepended = pd.concat((predictorsTrain, predictorsTest))
# responsesTestPrepended = pd.concat((responsesTrain, responsesTest))
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
k = pipe.named_steps.get('pca').n_components # k is number of predictors that the ML model sees
modelling.regression_results(testResults.yActual, testResults.yHat,k)
xValScores = cross_val_score(pipe, predictorsTrain, responsesTrain, cv = tscv,
                              scoring = 'neg_root_mean_squared_error')
intervalRange = -1*np.mean(xValScores)
testResults['ciUpper'] = testResults.yHat + intervalRange
testResults['ciLower'] = testResults.yHat - intervalRange

#%% Real-time application for training and predicting

# To run script quickly, comment out when doing Hyperparameter tuning
n_components = 77
nEstimators = 157
xgbLambda = 1.474601593214192e-07
maxDepth = 7
learnRate = 0.1
alpha = 3.5171001812327933e-06
subsample = 0.8500000000000002
colsample_bytree = 0.35000000000000003
colsample_bylevel = 0.9500000000000001
colsample_bynode = 0.8500000000000001

# n_components = searchResults.best_params_.get('pca__n_components')
# nEstimators = searchResults.best_params_.get('xgb_reg__n_estimators')
# xgbLambda = searchResults.best_params_.get('xgb_reg__reg_lambda')
# maxDepth = searchResults.best_params_.get('xgb_reg__max_depth')
# learnRate = searchResults.best_params_.get('xgb_reg__learning_rate')
# alpha = searchResults.best_params_.get('xgb_reg__reg_alpha')
# subsample = searchResults.best_params_.get('xgb_reg__subsample')
# colsample_bytree = searchResults.best_params_.get('xgb_reg__colsample_bytree')
# colsample_bylevel = searchResults.best_params_.get('xgb_reg__colsample_bylevel')
# colsample_bynode = searchResults.best_params_.get('xgb_reg__colsample_bynode')

# pca__n_components = n_components,
pipe.set_params(pca__n_components = n_components ,xgb_reg__n_estimators = nEstimators, xgb_reg__reg_lambda = xgbLambda,
                xgb_reg__max_depth = maxDepth, xgb_reg__learning_rate = learnRate,
                xgb_reg__reg_alpha = alpha, xgb_reg__subsample = subsample, 
                xgb_reg__colsample_bytree = colsample_bytree, xgb_reg__colsample_bylevel = colsample_bylevel,
                xgb_reg__colsample_bynode = colsample_bynode)

predictors = pd.concat((predictorsTrain, predictorsTest))
responses = pd.concat((responsesTrain, responsesTest))


end_Date = datetime.datetime(2022,2,28,0,0)

initialize = True

while end_Date < predictors.index[len(predictors)-1]:
    
    if initialize == True:
        start_Date = datetime.datetime(2022,1,1,0,0)
        end_Date = datetime.datetime(2022,2,28,0,0)
        test_End_Date = end_Date + datetime.timedelta(days = 14)
        yHatTestDF = np.array([])
    else:
        end_Date = test_End_Date
        if end_Date > predictors.index[len(predictors)-1]:
            break
        start_Date = end_Date - datetime.timedelta(days = 60)
        test_End_Date = test_End_Date + datetime.timedelta(days = 7)
                
    print(end_Date,' to ', test_End_Date)
    
    xTrain = predictors[start_Date:end_Date]
    yTrain =responses[start_Date:end_Date]
    print(len(yTrain))
    
    xTest = predictors[end_Date + datetime.timedelta(minutes = 1):test_End_Date]
    while xTest.shape[0] == 0:
        test_End_Date = test_End_Date + datetime.timedelta(days = 7)
        # print(test_End_Date)
        xTest = predictors[end_Date:test_End_Date]
    
    pipe.fit(xTrain,yTrain)
    
    yHatTest = pipe.predict(xTest)
    
    # plt.figure()
    # plt.plot(yTrain, color = 'r', label = 'Training Data')
    # plt.plot(responses[end_Date + datetime.timedelta(minutes = 1):test_End_Date], color = 'b', marker = '.', label = 'Testing Data')
    
    yHatTestDF = np.append(yHatTestDF, yHatTest)
    yTest = responses[end_Date + datetime.timedelta(minutes = 1):test_End_Date]
    
    print(len(yHatTest))
    print(len(yTest))
    
    k = pipe.named_steps.get('pca').n_components # k is number of predictors that the ML model sees
    print('--------------------------------------------------------------')
    print('Model Results - Test')
    modelling.regression_results(yTest, yHatTest, k)
    
    initialize = False

yTest = responses[datetime.datetime(2022,2,28,0,0) + datetime.timedelta(minutes = 1):test_End_Date]

k = pipe.named_steps.get('pca').n_components # k is number of predictors that the ML model sees
print('--------------------------------------------------------------')
print('Model Results - Test')
modelling.regression_results(yTest, yHatTestDF, k)

yHatTestDF = pd.DataFrame(yHatTestDF, index = yTest.index)

smoothTestResults = SimpleExpSmoothing(yHatTestDF, initialization_method="heuristic").fit(
    smoothing_level=0.1, optimized=False)

plt.plot(yTest, label = 'Actual Data', color = 'r')
plt.plot(smoothTestResults.fittedvalues, label = 'Predicted Data', color = 'b', marker = '.')
plt.legend()

#%% Real-Time Test: Same model no refit varying testing size
n_components = 77
nEstimators = 157
xgbLambda = 1.474601593214192e-07
maxDepth = 7
learnRate = 0.1
alpha = 3.5171001812327933e-06
subsample = 0.8500000000000002
colsample_bytree = 0.35000000000000003
colsample_bylevel = 0.9500000000000001
colsample_bynode = 0.8500000000000001

# pca__n_components = n_components,
pipe.set_params(pca__n_components = n_components ,xgb_reg__n_estimators = nEstimators, xgb_reg__reg_lambda = xgbLambda,
                xgb_reg__max_depth = maxDepth, xgb_reg__learning_rate = learnRate,
                xgb_reg__reg_alpha = alpha, xgb_reg__subsample = subsample, 
                xgb_reg__colsample_bytree = colsample_bytree, xgb_reg__colsample_bylevel = colsample_bylevel,
                xgb_reg__colsample_bynode = colsample_bynode)

predictors = pd.concat((predictorsTrain, predictorsTest))
responses = pd.concat((responsesTrain, responsesTest))

start_Date = datetime.datetime(2022,2,19,0,0)
end_Date = datetime.datetime(2022,3,19,0,0)

xTrain = predictors[start_Date:end_Date]
yTrain = responses[start_Date:end_Date]

#Fit model to 1 month of data
pipe.fit(xTrain,yTrain)

#Create testing data
test_End_Date = end_Date + datetime.timedelta(days = 7)

xTest = predictors[end_Date:test_End_Date]
yTest = responses[end_Date:test_End_Date]

#Test the data on varying time period of unseen data
yHatTest = pipe.predict(xTest)

#Performance results
k = pipe.named_steps.get('pca').n_components # k is number of predictors that the ML model sees
print('--------------------------------------------------------------')
print('Model Results - Test (10 week testing data)')
modelling.regression_results(yTest, yHatTest, k)

yHatTest = pd.DataFrame(yHatTest, index = yTest.index)

smoothTestResults = SimpleExpSmoothing(yHatTest, initialization_method="heuristic").fit(
    smoothing_level=0.1, optimized=False)

# plt.plot(latestTestResults)
# plt.plot(yTrain, label = 'Training Data', color = 'g')
plt.plot(yTest, label = 'Actual Data', color = 'r')
plt.plot(smoothTestResults.fittedvalues, label = 'Predicted Data', color = 'b', marker = '.')
plt.legend()

#%% Visualise Results
plt.plot(testResults['yActual'][end_Date:test_End_Date], color = 'r', label = 'Actual Data')
plt.plot(testResults['yHat'][end_Date:test_End_Date], color = 'b', marker = '.', label = 'Predicted Data')
plt.legend()

#%% Visualise differences
plt.plot(testResults['yActual'][end_Date:test_End_Date], color = 'r', label = 'Actual Data')
plt.plot(testResults['yHat'][end_Date:test_End_Date], color = 'b', marker = '.', label = 'Predicted Data on full data set')
plt.plot(smoothTestResults.fittedvalues, label = 'Predicted Data on partial dataset', color = 'm', marker = '.')
plt.legend()

#%% Real-Time Test: Same model no refit varying training size

n_components = 77
nEstimators = 157
xgbLambda = 1.474601593214192e-07
maxDepth = 7
learnRate = 0.1
alpha = 3.5171001812327933e-06
subsample = 0.8500000000000002
colsample_bytree = 0.35000000000000003
colsample_bylevel = 0.9500000000000001
colsample_bynode = 0.8500000000000001

# pca__n_components = n_components,
pipe.set_params(pca__n_components = n_components ,xgb_reg__n_estimators = nEstimators, xgb_reg__reg_lambda = xgbLambda,
                xgb_reg__max_depth = maxDepth, xgb_reg__learning_rate = learnRate,
                xgb_reg__reg_alpha = alpha, xgb_reg__subsample = subsample, 
                xgb_reg__colsample_bytree = colsample_bytree, xgb_reg__colsample_bylevel = colsample_bylevel,
                xgb_reg__colsample_bynode = colsample_bynode)

predictors = pd.concat((predictorsTrain, predictorsTest))
responses = pd.concat((responsesTrain, responsesTest))

end_Date = datetime.datetime(2022,6,16,0,0)
test_End_Date = datetime.datetime(2022,6,23,0,0)

start_Date = end_Date - datetime.timedelta(days = 150)

xTrain = predictors[start_Date:end_Date]
yTrain = responses[start_Date:end_Date]

#Fit model to varying month of data
pipe.fit(xTrain,yTrain)

xTest = predictors[end_Date:test_End_Date]
yTest = responses[end_Date:test_End_Date]

#Test the data on varying time period of unseen data
yHatTest = pipe.predict(xTest)

#Performance results
k = pipe.named_steps.get('pca').n_components # k is number of predictors that the ML model sees
print('--------------------------------------------------------------')
print('Model Results - Test (5 month training data)')
modelling.regression_results(yTest, yHatTest, k)

yHatTest = pd.DataFrame(yHatTest, index = yTest.index)

smoothTestResults = SimpleExpSmoothing(yHatTest, initialization_method="heuristic").fit(
    smoothing_level=0.1, optimized=False)

# plt.plot(latestTestResults)
plt.plot(yTrain, label = 'Training Data', color = 'g')
plt.plot(yTest, label = 'Actual Data', color = 'r')
plt.plot(smoothTestResults.fittedvalues, label = 'Predicted Data', color = 'b', marker = '.')
plt.legend()

#%% Visualise differences
plt.plot(testResults['yActual'][end_Date:test_End_Date], color = 'r', label = 'Actual Data')
plt.plot(testResults['yHat'][end_Date:test_End_Date], color = 'b', marker = '.', label = 'Predicted Data on full data set')
plt.plot(smoothTestResults.fittedvalues, label = 'Predicted Data on partial dataset', color = 'm', marker = '.')
plt.legend()

#%% Training the 2022 model

n_components = 69
nEstimators = 212
xgbLambda = 0.013950131878249618
maxDepth = 8
learnRate = 0.07564633275546291
alpha = 0.2568257435970688
subsample = 0.8500000000000002
colsample_bytree = 0.45
colsample_bylevel = 0.4
colsample_bynode = 0.8500000000000001

pipe.set_params(pca__n_components = n_components ,xgb_reg__n_estimators = nEstimators, xgb_reg__reg_lambda = xgbLambda,
                xgb_reg__max_depth = maxDepth, xgb_reg__learning_rate = learnRate,
                xgb_reg__reg_alpha = alpha, xgb_reg__subsample = subsample, 
                xgb_reg__colsample_bytree = colsample_bytree, xgb_reg__colsample_bylevel = colsample_bylevel,
                xgb_reg__colsample_bynode = colsample_bynode)

predictors = pd.concat((predictorsTrain, predictorsTest))
responses = pd.concat((responsesTrain, responsesTest))

#Fit the model on 7 months of data (from 1 Jan 2022 to 1 Aug 2022) and test on 1 month of data (1 Aug 2022 to 1 Sept 2022)
start_Date = datetime.datetime(2022,1,1,0,0)
end_Date = datetime.datetime(2022,8,1,0,0)
test_End_Date = datetime.datetime(2022,9,1,0,0)

xTrain = predictors[start_Date:end_Date]
yTrain = responses[start_Date:end_Date]

xTest = predictors[end_Date:test_End_Date]
yTest = responses[end_Date:test_End_Date]

pipe.fit(xTrain,yTrain)

yHatTest = pipe.predict(xTest)

k = pipe.named_steps.get('pca').n_components # k is number of predictors that the ML model sees
print('--------------------------------------------------------------')
print('Model Results - Test')
modelling.regression_results(yTest, yHatTest, k)

yHatTest = pd.DataFrame(yHatTest, index = yTest.index)

smoothTestResults = SimpleExpSmoothing(yHatTest, initialization_method="heuristic").fit(
    smoothing_level=0.1, optimized=False)

plt.plot(yTrain, label = 'Training Data', color = 'g')
plt.plot(yTest, label = 'Actual Data', color = 'r', marker = '.')
plt.plot(smoothTestResults.fittedvalues, label = 'Predicted Data', color = 'b', marker = '*')
plt.legend()

xValScores = cross_val_score(pipe, xTrain, yTrain, cv = tscv,
                              scoring = 'neg_root_mean_squared_error')
intervalRange = -1*np.mean(xValScores)

#%% Pickle file generation

pipe.fit(predictors,responses)

def _saveTrainedModel(model, path, modelName, intervalRange):
                           
    trainedModel = model
    
    # file name based on data start and end date.

    fullDataFrame = fullDF

    startDate = str(fullDataFrame.index[0])
    endDate = str(fullDataFrame.index[-1])


    formatString = modelName + " {}" + " to {}"

    fileName = formatString.format(startDate, endDate)

    fileName = fileName.replace(" ", "_")
    fileName = fileName.replace(":", ".")
    fileDir = os.path.join(path, fileName)

    if not os.path.isdir(path):
        os.mkdir(path)
    pickle.dump([trainedModel, intervalRange], open(fileDir, 'wb'))
    return fileDir

fileDirectory = _saveTrainedModel(pipe, 'D:\Projects\AmplatsDS_personal\XGBoost Basicity Real Time Performance' , '2022 XGBoost Basicity Model', intervalRange)
#%% Visualise Results

# visualise.plotActualVsPredicted(trainResults, testResults, (1, 3), "XGB Model - Basicity")

# visualise.plotTimeSeriesResults(testResults, origResponsesTest, "XGB Model - Basicity (Test Results)")

# visualise.plotTimeSeriesResults(trainResults, origResponsesTrain, "XGB Model - Basicity (Train Results)")

# visualise.plotResidualsAndErrors(trainResults, testResults)

smoothTestResults = SimpleExpSmoothing(testResults[testResults.columns[[1]]], initialization_method="heuristic").fit(
    smoothing_level=0.1, optimized=False)
[fig, ax] = plt.subplots()
testResults.plot(y='yActual', use_index=True, style = 'b-', ax = ax, marker = '.')
ax.plot(testResults[testResults.columns[1]], marker = '*', color = 'green', label = 'XGBoost')
ax.plot(smoothTestResults.fittedvalues, marker = 'o', color = 'red', label = 'Smoothed')
plt.legend()

smoothTestResults = pd.DataFrame(smoothTestResults.fittedvalues)
testResults["yHat"].update(smoothTestResults[0])

convergenceIndicator, convergingPeriod, divergingPeriod = \
    modelling.getDirectionalPerformance(origResponsesTest, testResults)

visualise.plotDirectionalPerformance(origResponsesTest, testResults, convergenceIndicator, "XGB Model - Basicity (Test Results)")

convergingPeriod/(convergingPeriod + divergingPeriod)
