# -*- coding: utf-8 -*-
"""
Created on Wed Nov 23 07:55:12 2022

@author: darshan.makan
"""


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


import Shared.DSModel.src.preprocessingFunctions as prep
import src.modellingFunctions as modelling
import src.dataExploration as visualise
from xgboost import XGBRegressor
from sklearn.model_selection import cross_val_score

#%% Read and Format Data
highFreqPredictors = ["Specific Oxygen Actual PV",
                      "Specific Silica Actual PV", "Matte feed PV filtered",
                      "Lance oxygen flow rate PV", "Lance air flow rate PV",
                      "Silica PV", "Matte transfer air flow", "Fuel coal feed rate PV"]

lowFreqPredictors = ["Fe Slag", "MgO Slag", "CaO Slag", "SiO2 Slag", "Al2O3 Slag",
                     "Ni Slag", "S Slag", "S Matte", "Slag temperatures",
                     "Matte temperatures", "Fe Feedblend", "S Feedblend",
                     "SiO2 Feedblend", "Al2O3 Feedblend", "CaO Feedblend",
                     "MgO Feedblend", "Cr2O3 Feedblend", "Corrected Ni Slag",
                     "Fe Matte"]

predictorTags = lowFreqPredictors + highFreqPredictors

responseTags = ["Basicity"]
referenceTags = ["Converter mode", "Lance air and oxygen control", "SumOfSpecies"]

fullDFOrig = prep.readAndFormatData('Chemistry2022')

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
            addShiftsToPredictors={'add': True, 'nLags': 3, 'on': highFreqPredictors},
            addResponsesAsPredictors={'add': True, 'nLags': 1},
            smoothTagsOnChange = {'add': True, 'on': ['Specific Silica Actual PV'], 'threshold': [70]},
            hoursOff = 8,
            nPeaksOff = 3,
            resampleTime = '1min',
            resampleMethod = 'linear',
            responseTags=responseTags,
            predictorTags=predictorTags,
            referenceTags=referenceTags,
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
    
#%% Capture out of normal operation data for training

# idx = np.where((fullDFOrig['Basicity'] < 1.65) | (fullDFOrig['Basicity'] > 1.85))[0]

# outOfRangeBasicity = fullDFOrig.iloc[idx]
# responses = outOfRangeBasicity['Basicity']
# predictors = outOfRangeBasicity.copy()
# del predictors['Basicity']
#fullDFOrig = outOfRangeBasicity

# fullDFOrig = pd.concat([fullDF2020,fullDF2021,fullDF2022])
# fullDFOrig = fullDFOrig.loc[fullDFOrig.index.notnull()]
# fullDFOrig = fullDFOrig.loc[~fullDFOrig.index.duplicated(keep='first')]

predictorsTrain = predictorsTrain.iloc[np.where((responsesTrain < 1.65))[0]]
responsesTrain = responsesTrain.iloc[np.where((responsesTrain < 1.65))[0]]
predictorsTest = predictorsTest.iloc[np.where((responsesTest < 1.65))[0]]
responsesTest = responsesTest.iloc[np.where((responsesTest < 1.65))[0]]  

# predictorsTrain = predictorsTrain.iloc[np.where((responsesTrain < 1.65) | (responsesTrain > 1.85))[0]]
# responsesTrain = responsesTrain.iloc[np.where((responsesTrain < 1.65) | (responsesTrain > 1.85))[0]]
# predictorsTest = predictorsTest.iloc[np.where((responsesTest < 1.65) | (responsesTest > 1.85))[0]]
# responsesTest = responsesTest.iloc[np.where((responsesTest < 1.65) | (responsesTest > 1.85))[0]]    

#%% Define TS Cross Validation Object
maxTrainSize = int(30*24*60)
testSize = int(1*24*60)
nSplits = int(np.ceil((len(predictorsTrain) - maxTrainSize)/testSize))
tscv = TimeSeriesSplit(n_splits = nSplits, max_train_size = maxTrainSize,
                       test_size = testSize)

pipe = Pipeline([('scaler', RobustScaler()),
                 ('pca', PCA()),
                 ('xgb_reg', XGBRegressor(objective='reg:squarederror',
                                          booster='gbtree'))])

param = {
    'pca__n_components': np.arange(25, len(predictorTagsNew)-1, 1),
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
searchResults = randomSearch.fit(predictorsTrain, responsesTrain)

#%% Training the 2022 model

# n_components = 57
# nEstimators = 212
# xgbLambda = 0.013950131878249618
# maxDepth = 8
# learnRate = 0.07564633275546291
# alpha = 0.2568257435970688
# subsample = 0.8500000000000002
# colsample_bytree = 0.45
# colsample_bylevel = 0.4
# colsample_bynode = 0.8500000000000001

# n_components = 53
# nEstimators = 249
# xgbLambda = 0.00023631646194831476
# maxDepth = 14
# learnRate = 0.037649358067924674
# alpha = 0.0038223400177176694
# subsample = 0.40000000000000013
# colsample_bytree = 0.8
# colsample_bylevel = 0.5
# colsample_bynode = 0.7000000000000001

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

pipe.set_params(pca__n_components = n_components ,xgb_reg__n_estimators = nEstimators, xgb_reg__reg_lambda = xgbLambda,
                xgb_reg__max_depth = maxDepth, xgb_reg__learning_rate = learnRate,
                xgb_reg__reg_alpha = alpha, xgb_reg__subsample = subsample, 
                xgb_reg__colsample_bytree = colsample_bytree, xgb_reg__colsample_bylevel = colsample_bylevel,
                xgb_reg__colsample_bynode = colsample_bynode)

predictors = pd.concat((predictorsTrain, predictorsTest))
responses = pd.concat((responsesTrain, responsesTest))

#Fit the model on 7 months of data (from 1 Jan 2022 to 1 Aug 2022) and test on 1 month of data (1 Aug 2022 to 1 Sept 2022)
start_Date = datetime.datetime(2020,1,1,0,0)
end_Date = datetime.datetime(2022,10,16,0,0)
test_End_Date = datetime.datetime(2022,11,17,0,0)

xTrain = predictors[start_Date:end_Date]
yTrain = responses[start_Date:end_Date]
pipe.fit(xTrain,yTrain)

#%% Testing Model on Out-of-sample Data

xTest = predictors[end_Date:test_End_Date]
yTest = responses[end_Date:test_End_Date]

yHatTest = pipe.predict(xTest)

k = pipe.named_steps.get('pca').n_components # k is number of predictors that the ML model sees
print('--------------------------------------------------------------')
print('Model Results - Test')
modelling.regression_results(yTest, yHatTest, k)

yHatTest = pd.DataFrame(yHatTest, index = yTest.index)

smoothTestResults = SimpleExpSmoothing(yHatTest, initialization_method="heuristic").fit(
    smoothing_level=0.1, optimized=False)

# residual = sum(abs(smoothTestResults.fittedvalues - yTest['Basicity']))

# plt.plot(yTrain, label = 'Training Data', color = 'g')
plt.plot(yTest, label = 'Actual Data', color = 'r', marker = '.')
plt.plot(smoothTestResults.fittedvalues, label = 'Predicted Data', color = 'b', marker = '*')
# plt.title('Smoothing level 0.1, residual %s' %(residual))
plt.legend()

#xValScores = cross_val_score(pipe, xTrain, yTrain, cv = tscv,
                              #scoring = 'neg_root_mean_squared_error')
#intervalRange = -1*np.median(xValScores)

#%% Statistical Error Calculation

boundaries = np.array([1.25,1.35,1.45,1.55,1.65])

#Find the error for a basicity range of 1.55-1.65 (calculated against the actual basicity values)
band1Actual = yTest.iloc[np.where((yTest <= boundaries[4]) & (yTest > boundaries[3]))[0]]
band1Predicted = smoothTestResults.fittedvalues.iloc[np.where((yTest <= boundaries[4]) & (yTest > boundaries[3]))[0]]
band1Error = sum(abs(band1Actual['Basicity'] - band1Predicted))/(len(band1Actual))

#Find the error for a basicity range of 1.45-1.55 (calculated against the actual basicity values)
band2Actual = yTest.iloc[np.where((yTest <= boundaries[3]) & (yTest > boundaries[2]))[0]]
band2Predicted = smoothTestResults.fittedvalues.iloc[np.where((yTest <= boundaries[3]) & (yTest > boundaries[2]))[0]]
band2Error = sum(abs(band2Actual['Basicity'] - band2Predicted))/(len(band2Actual))

#Find the error for a basicity range of 1.35-1.45 (calculated against the actual basicity values)
band3Actual = yTest.iloc[np.where((yTest <= boundaries[2]) & (yTest > boundaries[1]))[0]]
band3Predicted = smoothTestResults.fittedvalues.iloc[np.where((yTest <= boundaries[2]) & (yTest > boundaries[1]))[0]]
band3Error = sum(abs(band3Actual['Basicity'] - band3Predicted))/(len(band3Actual))

#Find the error for a basicity range of 1.25-1.35 (calculated against the actual basicity values)
band4Actual = yTest.iloc[np.where((yTest <= boundaries[1]) & (yTest > boundaries[0]))[0]]
band4Predicted = smoothTestResults.fittedvalues.iloc[np.where((yTest <= boundaries[1]) & (yTest > boundaries[0]))[0]]
band4Error = sum(abs(band4Actual['Basicity'] - band4Predicted))/(len(band4Actual))

barHeights = np.diff(boundaries)
bandErrors = [band4Error, band3Error, band2Error, band1Error]
totalError = sum(bandErrors)

plt.barh(boundaries[:-1], bandErrors, align = 'edge', height = barHeights, edgecolor = 'k')
plt.xlabel('Percentage Error')
plt.ylabel('Basicity')
plt.title('Total error %s' %(totalError))
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

fileDirectory = _saveTrainedModel(pipe, 'D:\John\Projects\AngloAmerican\converter-slag-splash\data\BasicityModel' , '2022 XGBoost Basicity Model', intervalRange)