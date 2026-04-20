# -*- coding: utf-8 -*-
"""
Created on Wed Jun  1 07:34:14 2022

@author: john.atherfold
"""

import pandas as pd
import numpy as np
import datetime
import matplotlib.pyplot as plt
from sklearn.ensemble import RandomForestRegressor
from sklearn.decomposition import PCA
from sklearn.preprocessing import RobustScaler
from sklearn.model_selection import TimeSeriesSplit
from sklearn.pipeline import Pipeline
import src.preprocessingFunctions as prep
import src.modellingFunctions as modelling
import src.simulationFunctions as sim
from skopt import BayesSearchCV
import src.dataExploration as visualise
from sklearn.decomposition import KernelPCA
import shap
import src.featureEngineeringHelpers as featEng
from sklearn.neural_network import MLPRegressor
from sklearn.base import BaseEstimator, RegressorMixin
import xgboost as xgb
from sklearn import ensemble

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

lowFreqPredictors = ["Slag temperatures"]#, "Cr2O3 Slag", "Basicity", "MgO Slag"]#, ]

feedblendPredictors = ["Cu Feedblend", "Ni Feedblend",
                       "Co Feedblend", "Fe Feedblend", "S Feedblend",
                       "SiO2 Feedblend", "Al2O3 Feedblend", "CaO Feedblend",
                       "MgO Feedblend", "Cr2O3 Feedblend"]

lowFreqPredictors = lowFreqPredictors + feedblendPredictors

predictorTags = highFreqPredictors + lowFreqPredictors

responseTags = ['Matte temperatures']
referenceTags = ["Converter mode", "Lance air & oxygen control"]
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
            addRollingMeanPredictors={'add': True, 'window': '100min', 'on': highFreqPredictors},
            addRollingMeanResponse={'add': True, 'window': '450min'},
            addMeasureIndicatorsAsPredictors={'add': False, 'on': ['Matte temperatures']}, #NOTE: functionality exists to process an 'on' key
            addShiftsToPredictors={'add': False, 'nLags': 3, 'on': ['Fuel coal feed rate PV 15min-rollingmean', 'Fuel coal feed rate PV 15min-rollingsum',
                                                                   'Matte feed PV 15min-rollingmean', 'Matte feed PV 15min-rollingsum',
                                                                   'Roof matte feed rate PV 15min-rollingmean', 'Roof matte feed rate PV 15min-rollingsum']},
            addResponsesAsPredictors={'add': False, 'nLags': 1},
            resampleTime = '1min',
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

#%% Close look at lance height

timeSmoothing = '10min'
ax = fullDF["Lance height"].rolling(timeSmoothing).mean().plot()
ax2 = ax.twinx()
fullDF["Lance height"].rolling(timeSmoothing).mean().diff().plot(ax = ax2, style = 'k-o')
plt.axhline(y = 0, color = 'r', linewidth = 2)

#%%
fullDF["Steadystate int"] = fullDF["Steadystate"].replace({True: 1, False: 0})
axs = fullDF[["Matte temperatures", "Converter mode", "Lance height",
              "Lance air & oxygen control","Steadystate int"]].plot(subplots = True)
origSmoothedResponses["Matte temperatures"].plot(ax = axs[0], style = 'r*')
fullDF["Matte temperatures"][fullDF["Steadystate"]].plot(ax = axs[0], style = 'g-x')

#%%

axs = fullDFOrig[["Matte temperatures", "Converter mode", "Lance height",
                  "Lance air & oxygen control"]].plot(subplots = True)
fullDF["Matte temperatures"][fullDF["Steadystate"]].plot(ax = axs[0], style = 'g-x')

#%% Considering Slag and Matte temps

origMatteTemps, _ = featEng.getUniqueDataPoints(fullDFOrig["Matte temperatures"].dropna())
origSlagTemps, irregularIdx = featEng.getUniqueDataPoints(fullDFOrig["Slag temperatures"].dropna())

fig, axs = plt.subplots(3, 1, sharex = True)
origMatteTemps.plot(ax = axs[0], style = 'b-o')
origSlagTemps.plot(ax = axs[1], style = 'r-x')
fullDFOrig["Lance height"].plot(ax = axs[2], style = 'k-^')

plt.figure()
plt.scatter(origMatteTemps[irregularIdx], origSlagTemps)

tempDF = pd.concat([origMatteTemps, origSlagTemps], join = 'outer', axis = 1)