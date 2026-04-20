# -*- coding: utf-8 -*-
"""
Created on Thu Jun 23 12:56:48 2022

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
from scipy.optimize import least_squares

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

lowFreqPredictors = ["Slag temperatures"]# "Cr2O3 Slag", "Basicity", "MgO Slag"]#, 

feedblendPredictors = ["Cu Feedblend", "Ni Feedblend",
                       "Co Feedblend", "Fe Feedblend", "S Feedblend",
                       "SiO2 Feedblend", "Al2O3 Feedblend", "CaO Feedblend",
                       "MgO Feedblend", "Cr2O3 Feedblend"]
referenceTags = ["Converter mode", "Lance air & oxygen control"]
# lowFreqPredictors = lowFreqPredictors + feedblendPredictors

predictorTags = highFreqPredictors + lowFreqPredictors

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
            addRollingSumPredictors={'add': False, 'window': '100min', 'on': highFreqPredictors}, #NOTE: functionality exists to process an 'on' key
            addRollingMeanPredictors={'add': True, 'window': '15min', 'on': ["Lance height", "Matte feed PV",
                                                                             "Waffle heat flux"]},
            addMeasureIndicatorsAsPredictors={'add': True, 'on': ['Matte temperatures']}, #NOTE: functionality exists to process an 'on' key
            addShiftsToPredictors={'add': False, 'nLags': 3, 'on': ['Fuel coal feed rate PV rollingmean', 'Fuel coal feed rate PV rollingsum',
                                                                   'Matte feed PV rollingmean', 'Matte feed PV rollingsum',
                                                                   'Roof matte feed rate PV rollingmean', 'Roof matte feed rate PV rollingsum']},
            addResponsesAsPredictors={'add': False, 'nLags': 1},
            resampleTime = '1min',
            resampleMethod = 'zero',
            responseTags = responseTags,
            predictorTags = predictorTags,
            highFrequencyPredictorTags = highFreqPredictors,
            lowFrequencyPredictorTags = [],
            referenceTags=referenceTags)
    return fullDF, origSmoothedResponses, predictorTagsNew

fullDF, origSmoothedResponses, predictorTagsNew = processingFunc(fullDFOrig, predictorTags, highFreqPredictors, lowFreqPredictors)

fullDF["Orig Matte Temperatures"] = origSmoothedResponses
fullDF["Orig Matte Temperatures"] = fullDF["Orig Matte Temperatures"].fillna(method = "ffill")
startTime = pd.Timestamp('2021-01-01 00:00')
endTime = pd.Timestamp('2021-09-08 00:00')
mask = (fullDF.index >= startTime) & (fullDF.index <= endTime)
fullDF = fullDF.loc[mask]

#Reassigning Matte Temps
blowTimes = fullDF[fullDF['Peaks']==True].index
matteTempChanges, _ = featEng.getUniqueDataPoints(fullDF["Orig Matte Temperatures"])
newTempTimes, newTemps = featEng.reassignMatteTemp(blowTimes, matteTempChanges)
alignedTemps = pd.Series(data = newTemps, index = newTempTimes)

fullDF["Matte temperatures corrected"] = np.nan
fullDF["Matte temperatures corrected"].loc[alignedTemps.index.dropna()] = alignedTemps.loc[alignedTemps.index.dropna()]
fullDF["Matte temperatures corrected"].iloc[0] = fullDF["Matte temperatures"].iloc[0]
fullDF["Matte temperatures interpolated"] = fullDF["Matte temperatures corrected"].interpolate(method = "linear")
fullDF["Matte temperatures corrected"] = fullDF["Matte temperatures corrected"].fillna(method = "ffill")

fullDF, measureIndicatorTags = featEng.addMeasureIndicatorsAsPredictors(fullDF,
                                                                        ["Matte temperatures corrected"])    
predictorTagsNew = predictorTagsNew + measureIndicatorTags

# predictorTagsNew = list(set(predictorTagsNew) - set(predictorTags))
# fullDF = fullDF[predictorTagsNew + responseTags]

#%% Exploration - Decide on sampling time and how splitting is going to work

fullDF = fullDF.resample("10min", label='right', closed='right').last().dropna()
axs = fullDF[["Matte feed PV", "Lance air & oxygen control", "Lance height 15min-rollingmean",
              "Matte temperatures", "Slag temperatures", "Matte temperatures corrected Measure Indicator"]].plot(subplots = True)
fullDF["Matte feed PV 15min-rollingmean"].plot(ax = axs[0], style = 'g-')
fullDF["Lance height"].plot(ax = axs[2], style = 'b-')
fullDF["Matte temperatures interpolated"].plot(ax = axs[3], style = 'k*')

#%% Split Data

predictorsTrain, responsesTrain, origResponsesTrain, predictorsTest, responsesTest, origResponsesTest = \
    prep.splitIntoTestAndTrain(
    fullDF,
    origSmoothedResponses,
    trainFrac=0.90,
    predictorTags=["Matte feed PV 15min-rollingmean", "Waffle heat flux",
                   "Slag temperatures", "Matte temperatures corrected Measure Indicator"],
    responseTags=["Matte temperatures interpolated"])


    
#%% Define TS Cross Validation Object
maxTrainSize = int(21*24*60/15)
testSize = int(1*24*60/15)
nSplits = int(np.ceil((len(predictorsTrain) - maxTrainSize)/testSize))
tscv = TimeSeriesSplit(n_splits = nSplits, max_train_size = maxTrainSize,
                       test_size = testSize)

def hybridModel(beta, x, t):
    # Splitting beta and redefining x
    alpha = beta[0:2]
    beta = beta[2:]
    x[:, 0:2] = np.multiply(alpha, x[:, 0:2])
    feedRate = x[:,0]
    feedRate[feedRate == 0] = np.nan
    feedRate[np.isnan(feedRate)] = np.min(feedRate)
    x[:,0] = feedRate
    # Defining the equation
    T2 = (beta[2]*beta[4] + 3*beta[4]*x[:,0] - x[:,2]*x[:,0]**2 - 4*x[:,2]*beta[2]*x[:,0] + 
          2*beta[3]*beta[1]*x[:,0]*x[:,1] + beta[2]*beta[3]*beta[1]*x[:,1])/ \
        (x[:,2]*(beta[2] + 2*x[:,0])*(beta[2] + 3*x[:,0]))
    yHat = beta[0]/((beta[1] + x[:,0]*t)**((beta[2] + 2*x[:,0])/x[:,0])) - T2 - \
        (beta[3]*x[:,0]*x[:,1])/(x[:,2]*(beta[2] + 3*x[:,0]))*t
    return yHat

def functionLoss(beta, x, t, y):
    yHat = hybridModel(beta, x, t)
    rmse = np.sqrt(np.nanmedian((y - yHat)**2))
    return rmse

# Define inputs to Model
beta0 = np.array([0.1, 0.1, 1, 0, 1, 0.01, 100])

for train_index, test_index in tscv.split(predictorsTrain):
    xTrain, xTest = \
        predictorsTrain.iloc[train_index], \
        predictorsTrain.iloc[test_index]
    yTrainDS, yTestDS = responsesTrain.iloc[train_index], \
        responsesTrain.iloc[test_index]

    yTrain = yTrainDS.values
    yTest = yTestDS.values
    
    x = xTrain[["Matte feed PV 15min-rollingmean", "Waffle heat flux", "Slag temperatures"]].values
    t = xTrain[["Matte temperatures corrected Measure Indicator"]].values.ravel()/60 # Convert minutes to hours
    t[t == 0] = 0.01 # Otherwise dividing by zero
    y = np.divide(yTrain.ravel(), xTrain["Slag temperatures"].values)
    
    bestBeta = least_squares(functionLoss, beta0, args = (x, t, y))