# -*- coding: utf-8 -*-
"""
Created on Thu Oct 14 11:05:08 2021

@author: john.atherfold
"""

import numpy as np
import pandas as pd
import sklearn.metrics as metrics
import matplotlib.pyplot as plt
import shap
from scipy.special import huber

def regression_results(y_true, y_pred, k):
    
    n = len(y_true)
    # Regression metrics
    explained_variance = metrics.explained_variance_score(y_true, y_pred)
    mean_absolute_error = metrics.mean_absolute_error(y_true, y_pred) 
    mse = metrics.mean_squared_error(y_true, y_pred) 
    # mean_squared_log_error=metrics.mean_squared_log_error(y_true, y_pred)
    # median_absolute_error = metrics.median_absolute_error(y_true, y_pred)
    r2 = metrics.r2_score(y_true, y_pred)
    adjustedR2 = 1 - ((1 - r2)*(n - 1)/(n - k - 1))
    standardError = np.sqrt(n/(n - k - 1)*mse)

    print('explained_variance: ', round(explained_variance, 4))    
    # print('mean_squared_log_error: ', round(mean_squared_log_error,4))
    print('r2: ', round(r2, 4))
    print('Adjusted r2: ', round(adjustedR2, 4))
    print('MAE: ', round(mean_absolute_error, 4))
    print('MSE: ', round(mse, 4))
    print('RMSE: ', round(np.sqrt(mse), 4))
    print('Standard error: ', round(standardError, 4))
    return

def getResponseIdx(fullDF, subModel):
    if subModel == "Chemistry":
        responseColumnIdx = fullDF.columns == 'Basicity'
    elif subModel == "Temperature":
        responseColumnIdx = fullDF.columns == 'Matte temperatures'
    return responseColumnIdx

def trainAndTestModel(mdl, xTrain, yTrain, xTest, yTest, index):
    mdl.fit(xTrain, yTrain)
    yHatTest = mdl.predict(xTest)
    k = xTrain.shape[1]
    print('--------------------------------------------------------------')
    print('Model Results - Test')
    regression_results(yTest, yHatTest, k)
    
    # Visualising Results
    if len(yHatTest.shape) == 2: #If yHatTest is already a column, no need to add the new axis
        results = pd.DataFrame(data = np.concatenate((yTest[:, np.newaxis],
                                                      yHatTest), axis=1),
                           index=index, columns=('yActual','yHat'))
    else:
        results = pd.DataFrame(data = np.concatenate((yTest[:, np.newaxis],
                                                      yHatTest[:, np.newaxis]), axis=1),
                           index=index, columns=('yActual','yHat'))
    return mdl, results


def simModel(mdl, xData):
    yHat = mdl.predict(xData.reshape(1, -1))
    return yHat


def testModel(mdl, xData, yData, index):
    yHat = mdl.predict(xData)
    print('--------------------------------------------------------------')
    print('Model Results')
    k = xData.shape[1]
    regression_results(yData, yHat, k)
    
    if len(yHat.shape) == 2: #If yHatTest is already a column, no need to add the new axis
        results = pd.DataFrame(data=np.concatenate((yData[:, np.newaxis],
                                                    yHat), axis=1),
                               index=index, columns=('yActual', 'yHat'))
    else:
        results = pd.DataFrame(data=np.concatenate((yData[:, np.newaxis],
                                                    yHat[:, np.newaxis]), axis=1),
                               index=index, columns=('yActual', 'yHat'))
    return results

def timeSeriesCrossValPredict(x, y, mdl, tscv):
    yPredictions = np.empty((len(x),))
    yPredictions[:] = np.NaN

    for train_index, test_index in tscv.split(x):
        xTrain = x[train_index]
        yTrain = y[train_index]
        xTest = x[test_index]
        mdl.fit(xTrain, yTrain)
        yHatTest = mdl.predict(xTest)
        yPredictions[test_index] = yHatTest
    return yPredictions

def getShapFeatureImportance(mdl, featureValues, featureNames, modelType):
    plt.figure()
    if modelType == 'Random Forest':
        explainer = shap.TreeExplainer(mdl)
    elif modelType == 'Linear':
        explainer = shap.Explainer(mdl.predict, featureValues, 
                                   feature_names = featureNames)
    
    shap_values = explainer.shap_values(featureValues)
    shap.summary_plot(shap_values,features = featureValues, 
                      feature_names = featureNames, plot_type=('bar'))
    plt.figure()
    shap.summary_plot(shap_values,features = featureValues, 
                      feature_names = featureNames)

def getDirectionalPerformance(origResponsesTest, testResults):
    origResponses = origResponsesTest.dropna()
    relevantTestResults = testResults.yHat
    responseVariable = origResponsesTest.columns[0]
    convergenceIndicator = pd.DataFrame(data=np.zeros((len(origResponses) - 1, 4)),
                                        index = origResponses.index[1:],
                                        columns = ["Average Predicted Gradient",
                                                   "Actual Gradient", "Convergence",
                                                   "Duration"])
    convergenceIndicator = convergenceIndicator.astype({'Convergence': 'bool'})
    convergenceIndicator = convergenceIndicator.astype({'Duration': 'timedelta64[ns]'})
    
    for nPoint in np.arange(len(origResponses) - 1):
        convergenceIndicator.at[convergenceIndicator.index[nPoint], "Average Predicted Gradient"] = \
            np.sum(np.diff(relevantTestResults.loc[origResponses.index[nPoint]:origResponses.index[nPoint + 1]  - np.timedelta64(1, 'm')]))
    
    convergenceIndicator["Actual Gradient"] = np.diff(origResponses[responseVariable])
    convergenceIndicator.Convergence = np.sign(convergenceIndicator["Actual Gradient"]) == np.sign(convergenceIndicator["Average Predicted Gradient"])
    convergenceIndicator.Duration = np.diff(origResponses.index)
    
    validDurations = convergenceIndicator.Duration < np.timedelta64(2, 'h')
    convergingPeriod = np.sum(convergenceIndicator.Duration[np.logical_and(validDurations, convergenceIndicator.Convergence)])
    divergingPeriod = np.sum(convergenceIndicator.Duration[np.logical_and(validDurations, ~convergenceIndicator.Convergence)])
    return convergenceIndicator, convergingPeriod, divergingPeriod

def getBaselineResults(y_true, y_pred):
    print('--------------------------------------------------------------')
    print('Baseline Model Results - Naive Prediction')
    fullTable = pd.concat([y_true, y_pred], axis = 1)
    fullTable = fullTable.dropna()
    regression_results(fullTable[fullTable.columns[0]],
                       fullTable[fullTable.columns[1]], 1)

def plotLinearFeatureImportance(pipe, xTestPointDS):
    
    pca = pipe.named_steps['pca']
    linearMdl = pipe.named_steps['regression']

    pcaComps = pca.components_
    regressionCoefs = linearMdl.coef_
    predictorWeights = np.matmul(regressionCoefs, pcaComps)

    xTestPoint = xTestPointDS.values.reshape(1, -1)
    xTestPointScaled = pipe.named_steps['scaler'].transform(xTestPoint) - pca.mean_
    individualTerms = predictorWeights*xTestPointScaled
    
    contributions = getFeatureContributionsStep(individualTerms, xTestPointDS, predictorWeights)
    [allFeatures, predictorWeights] =  getLinearFeatureImportance(pca, linearMdl, contributions)
                                                           
    rankedIndicators = np.flip(np.argsort(np.abs(predictorWeights)))
    top20Features = np.flip(contributions.index[rankedIndicators[0:20]])
    modelWeightings = np.flip(predictorWeights[rankedIndicators[0:20]])
    top20Terms = np.flip(contributions.values[rankedIndicators[0:20]])
    
    data = np.concatenate((
        modelWeightings.reshape(-1,1),
        top20Terms.reshape(-1,1)),axis=1)
    df2 = pd.DataFrame.transpose(
        pd.DataFrame(
            data.T, 
            columns = np.ndarray.tolist(top20Features.values)))
    df2.columns = ['Model weightings','Top 20 terms']

    df2.plot.barh()
    plt.title('Linear Model Top 20 Features')
    
def getLinearFeatureImportance(pca, linearMdl, contributions):
    '''
    Get weighting vector that maps inputs in the ORIGINAL feature space to the 
    target value.
    '''
    pcaComps = pca.components_
    regressionCoefs = linearMdl.coef_
    predictorWeights = np.matmul(regressionCoefs, pcaComps)

    allFeatures = np.flip(contributions.index)
    return allFeatures, predictorWeights
    
def getFeatureContributionsStep(individualTerms, xTestPointDS, predictorWeights):
    contributions = pd.Series(data = individualTerms.flatten(),
                              index = xTestPointDS.index)

    return contributions
