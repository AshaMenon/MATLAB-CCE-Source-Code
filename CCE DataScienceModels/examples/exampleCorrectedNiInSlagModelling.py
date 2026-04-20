# -*- coding: utf-8 -*-
"""
Created on Thu Nov 11 13:51:02 2021

@author: verushen.coopoo
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.linear_model import LinearRegression

import src.preprocessingFunctions as prep
import src.modellingFunctions as modelling
import src.dataExploration as cf

#%% Read and Format Data

fullDF = prep.readAndFormatData('Chemistry')

#%% Set Predictor and Response Tags from Data, and Resample

responseColumnIdx = modelling.getResponseIdx(fullDF, 'Chemistry')

responseTags = fullDF['Corrected Ni Slag']
predictorTags = fullDF.iloc[:, np.logical_not(responseColumnIdx)]

#%% Create Model Predictors and Responses

predictors = predictorTags
responses = responseTags

#%% Create Model Predictors and Responses - Baseline Model

predictors = predictorTags.copy()
responses = responseTags.copy()

# Linear Model - Baseline.
#   Can we predict at the same time period that's sampled?

predictorsTrain = predictors.iloc[:round(0.75*len(predictorTags)),:].resample('20min').mean().dropna()
responsesTrain = responses[:round(0.75*len(predictorTags))].resample('20min').first().dropna()

predictorsTest = predictors.iloc[round(0.75*len(predictorTags)):,:].resample('20min').mean().dropna()
responsesTest = responses[round(0.75*len(predictorTags)):].resample('20min').first().dropna()

baselineMdl = LinearRegression()

xTrain = predictorsTrain.values
yTrain = responsesTrain.values
xTest = predictorsTest.values
yTest = responsesTest.values

[baselineMdl, results] = modelling.trainAndTestModel(baselineMdl, xTrain, yTrain,
                                                     xTest, yTest, responsesTest)

resampledTestData = responsesTest.resample('20min').first().dropna()
plt.figure(figsize=(60, 30))
plt.plot((1, 3), (1, 3), 'k-')
plt.plot(results.yTest, results.yHat, 'b.')
plt.xlabel('Actual Response')
plt.ylabel('Predicted Response')
plt.xlim((1, 3))
plt.ylim((1, 3))
plt.title("Baseline Model - Corrected Ni Slag", fontsize=40)
plt.show()

plt.figure()
ax = resampledTestData.plot(use_index=True, figsize=(30,15))
results.plot(y='yTest', use_index=True, ax=ax)
results.plot(y='yHat', use_index=True, ax=ax)
plt.title("Baseline Model - Corrected Ni Slag", fontsize=40)
plt.show()

#%% Create Model Predictors and Responses - Irregular Sample Time Model

predictors = predictorTags.copy()
responses = responseTags.copy()

valueChangeIdx = np.append(True, np.diff(responses.values) != 0)
valueChangeIdx[-1] = True
irregularIdx = responses.index[valueChangeIdx]

predictors = predictors.groupby(irregularIdx[irregularIdx.searchsorted(predictors.index)]).mean()
predictors = predictors[0:-1]
responses = responses.iloc[valueChangeIdx]
responses = responses[0:-1]

# Linear Model - Keeping irregular sample time, but resampling at every
#   value change (irregularly)

predictorsTrain = predictors.iloc[:round(0.75*len(predictors)),:]
responsesTrain = responses[:round(0.75*len(predictors))]

predictorsTest = predictors.iloc[round(0.75*len(predictors)):,:]
responsesTest = responses[round(0.75*len(predictors)):]

baselineMdl = LinearRegression()

xTrain = predictorsTrain.values
yTrain = responsesTrain.values
xTest = predictorsTest.values
yTest = responsesTest.values

[baselineMdl, results] = modelling.trainAndTestModel(baselineMdl, xTrain, yTrain,
                                                     xTest, yTest, responsesTest)

plt.figure(figsize=(60, 30))
plt.plot((1, 3), (1, 3), 'k-')
plt.plot(results.yTest, results.yHat, 'b.')
plt.xlabel('Actual Response')
plt.ylabel('Predicted Response')
plt.xlim((1, 3))
plt.ylim((1, 3))
plt.title("Irregular Linear Model - Corrected Ni Slag", fontsize=40)
plt.show()

ax = results.plot(y='yTest', use_index=True, figsize=(30,15))
results.plot(y='yHat', use_index=True, ax=ax)
plt.title("Baseline Model - Corrected Ni Slag", fontsize=40)
plt.show()

# Visualising resampled data

resampledTestData = responsesTest.resample('19min').last().dropna()
ax = results.plot(y='yTest', use_index=True)
resampledTestData.plot(use_index=True, ax=ax)
plt.legend(('Actual Test Data','Resampled Test Data'))

#%% Create Model Predictors and Responses - Regular Sample Time Model

predictors = predictorTags.copy()
responses = responseTags.copy()

predictors = predictors.resample('19min').mean().dropna()
responses = responses.resample('19min').last().dropna()

# Linear Model - Both Training and Testing data sampled regularly

predictorsTrain = predictors.iloc[:round(0.75*len(predictors)),:]
responsesTrain = responses[:round(0.75*len(predictors))]

predictorsTest = predictors.iloc[round(0.75*len(predictors)):,:]
responsesTest = responses[round(0.75*len(predictors)):]

baselineMdl = LinearRegression()

xTrain = predictorsTrain.values
yTrain = responsesTrain.values
xTest = predictorsTest.values
yTest = responsesTest.values

[baselineMdl, results] = modelling.trainAndTestModel(baselineMdl, xTrain, yTrain,
                                                     xTest, yTest, responsesTest)

plt.figure(figsize=(60, 30))
plt.plot((1, 3), (1, 3), 'k-')
plt.plot(results.yTest, results.yHat, 'b.')
plt.xlabel('Actual Response')
plt.ylabel('Predicted Response')
plt.xlim((1, 3))
plt.ylim((1, 3))
plt.title("Regular Linear Model (19 min) - Corrected Ni Slag", fontsize=40)
plt.show()

ax = results.plot(y='yTest', use_index=True, figsize=(30,15))
results.plot(y='yHat', use_index=True, ax=ax)
plt.title("Regular Linear Model (19 min) - Corrected Ni Slag", fontsize=40)
plt.show()

#%% Linear Model - Only Training data sampled regularly; Testing data sampled
#    minutely

predictors = predictorTags.copy()
responses = responseTags.copy()

# Linear Model - Both Training and Testing data sampled regularly

# predictors = predictors[['Specific Oxygen Actual PV',
#        'Specific Oxygen Operator SP (SP1)', 'Specific Silica Actual PV',
#        'Specific Silica Calculated SP (SP2)',
#        'Specific Silica Operator SP (SP1)', 'Matte feed SP',
#        'Matte feed PV(filtered)', 'Lance oxygen flow rate SP',
#        'Lance oxygen flow rate PV', 'Lance air flow rate SP',
#        'Lance air flow rate PV', 'Lance feed SP', 'Lance feed PV', 'Silica SP',
#        'Silica PV', 'Lump Coal SP', 'Lump Coal PV', 'Slag temperatures',
#        'Matte temperatures', 'Matte transfer air flow',
#        'Fe Feedblend', 'S Feedblend', 'SiO2 Feedblend', 'Al2O3 Feedblend',
#        'CaO Feedblend', 'MgO Feedblend', 'Cr2O3 Feedblend',
#        'Specific Oxygen Calculated SP (SP2)']]


predictorsTrain = predictors.iloc[:round(0.75*len(predictors)),:].resample('19min').mean().dropna()
# predictorsTrain = (predictorsTrain - np.min(predictorsTrain))/(np.max(predictorsTrain) - np.min(predictorsTrain))
responsesTrain = responses[:round(0.75*len(predictors))].resample('19min').last().dropna()

predictorsTest = predictors.iloc[round(0.75*len(predictors)):,:]
# predictorsTest = (predictorsTest - np.min(predictorsTest))/(np.max(predictorsTest) - np.min(predictorsTest))
responsesTest = responses[round(0.75*len(predictors)):]

valueChangeIdx = np.append(True, np.diff(responsesTest.values) != 0)
valueChangeIdx[-1] = True
resampledResponsesTest = responsesTest.iloc[valueChangeIdx]
resampledResponsesTest = resampledResponsesTest[0:-1]
resampledResponsesTest = resampledResponsesTest.resample('1min').last()
resampledResponsesTest = resampledResponsesTest.interpolate()

# pca = PCA()
# principalComponentsTrain = pca.fit_transform(predictorsTrain.values)
# principalComponentsTest = pca.transform(predictorsTest.values)

# principalDfTrain = pd.DataFrame(data = principalComponentsTrain[:,0:13],
#                            columns = ['PC1', 'PC2', 'PC3', 'PC4', 'PC5',
#                                       'PC6', 'PC7', 'PC8', 'PC9', 'PC10',
#                                       'PC11', 'PC12', 'PC13'], index=predictorsTrain.index)
# principalDfTest = pd.DataFrame(data = principalComponentsTest[:,0:13],
#                            columns = ['PC1', 'PC2', 'PC3', 'PC4', 'PC5',
#                                       'PC6', 'PC7', 'PC8', 'PC9', 'PC10',
#                                       'PC11', 'PC12', 'PC13'])

baselineMdl = LinearRegression()

xTrain = predictorsTrain.values
yTrain = responsesTrain.values

xTest = predictorsTest.values
yTest = responsesTest.values

[baselineMdl, results] = modelling.trainAndTestModel(baselineMdl, xTrain, yTrain,
                                                     xTest, yTest, responsesTest)

plt.figure(figsize=(60, 30))
plt.plot((1, 3), (1, 3), 'k-')
plt.plot(results.yTest, results.yHat, 'b.')
plt.xlabel('Actual Response')
plt.ylabel('Predicted Response')
plt.xlim((1, 3))
plt.ylim((1, 3))
plt.title("Regular Linear Model (1 min) - Corrected Ni Slag", fontsize=40)
plt.show()

plt.figure()
ax = resampledResponsesTest.plot(use_index=True, figsize=(30,15))
results.plot(y='yHat', use_index=True, ax=ax)
plt.title("Regular Linear Model (1 min) - Basicity", fontsize=40)
plt.legend(('yTest Resampled', 'yHat'))
plt.show()

correlations = cf.calculateCorrelationCoeff(pd.concat((predictorsTrain, responsesTrain), axis=1))

# Get correlation heatmap for a highlevel view

fig = plt.figure(figsize=(30,15))
cf.plotCorrelationHeatMap(correlations)

#%% Train ML Model(s)

#%% Validate models on Out-of-sample Data

#%% Cross-Validate Models

