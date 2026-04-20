# -*- coding: utf-8 -*-
"""
Visualisation Functions
"""

import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
import numpy as np
from scipy import stats
import scipy.signal as signal
from datetime import datetime, timedelta
from statsmodels.tsa.ar_model import AutoReg
import os
import pickle

def calculateCorrelationCoeff(df):
    correlations = df.corr()
    return correlations

def plotCorrelationHeatMap(correlations, annotations=False):
    sns.heatmap(correlations, annot=annotations)
    plt.show()
    
def selectByThreshold(df, minThreshold=0.5, maxThreshold=1):
    # Finds all variables with a correlation between a threshold

    sortedMatrix = sortCorrelations(df)
    selectedMatrix = sortedMatrix.loc[(minThreshold <= sortedMatrix.abs()) & 
                                      (sortedMatrix.abs() <= maxThreshold)]

    return selectedMatrix

def sortCorrelations(df):
    # Sorts correlations in decending order
    # Gets the upper part of the correlation matrix
    upperMatrix = df.where(np.triu(np.ones(df.shape), k=1).astype(np.bool_))
    unstackedMatrix = upperMatrix.unstack()
    sortedMatrix = unstackedMatrix.sort_values(ascending=False)
    return sortedMatrix

def plotCorrelationMatrix(df):
    g = sns.pairplot(df)
    #g.map_lower(corrfunc)
    plt.show()
    

def corrfunc(x, y, **kws):
    r, _ = stats.pearsonr(x, y)
    ax = plt.gca()
    ax.annotate("r = {:.2f}".format(r),
                xy=(.1, .9), xycoords=ax.transAxes)
    
def resampleByDates(df, customDates, variables):
    i = 0
    sampleDF = pd.DataFrame(np.zeros((len(customDates),len(variables))),columns = [variables])
    dfIndex = [datetime.strptime(date, '%d-%b-%y %H:%M:%S') for date in df.index]
    for timestamp in customDates:
        
        if i == 0:
            idx = [x <= timestamp  for x in dfIndex]
        else:
            timestamp2 = customDates[i-1]
            idx = [timestamp2 < x <= timestamp  for x in dfIndex]
        sampleDF.iloc[i]= df[variables].loc[idx].mean()
        i = i + 1    
    return sampleDF

def plotActualVsPredicted(trainResults, testResults, dataRange, title):
    plt.figure()
    plt.plot(dataRange, dataRange, 'k-')
    plt.plot(testResults.yActual, testResults.yHat, 'o', alpha = 0.07, markeredgecolor = (0, 0, 1, 0.07))
    plt.plot(trainResults.yActual, trainResults.yHat, 'o', alpha = 0.07, markeredgecolor = (1, 0, 0, 0.07))
    plt.xlabel('Actual Response')
    plt.ylabel('Predicted Response')
    plt.xlim(dataRange)
    plt.ylim(dataRange)
    plt.title(title, fontsize=15)
    plt.show()
    return

def plotTimeSeriesResults(simulatedResults, measuredData, title):
    ax = simulatedResults.plot(y='yActual', use_index=True, style = 'b-')
    measuredData.plot(use_index=True, ax=ax, style='r*')
    simulatedResults.plot(y='yHat', use_index=True, ax=ax, style = 'go-')
    plt.title(title, fontsize=15)
    if 'ciUpper' in simulatedResults:
        plt.fill_between(simulatedResults.index, simulatedResults['ciLower'],
                         simulatedResults['ciUpper'])
    plt.legend(('yActual Resampled', 'yActual Samples', 'yPredicted'))
    plt.show()
    return ax

def plotResidualsAndErrors(trainResults, testResults):
    plt.figure()
    plt.hist(trainResults["yActual"] - trainResults["yHat"], bins = 100, alpha = 0.5, density = True)
    plt.hist(testResults["yActual"] - testResults["yHat"], bins = 100, alpha = 0.5, density = True)
    plt.xlabel("yActual-yHat")
    plt.title('Mean = '+ str(round(np.mean(testResults["yActual"] - testResults["yHat"]), 4)) +
              ', Std = '+ str(round(np.std(testResults["yActual"] - testResults["yHat"]), 4)))
    plt.legend(('Training Residuals', 'Testing Errors'))
    plt.show()
    return

def plotResidualComparison(linearResiduals, forestResiduals, modelType):
    
    rollingRmseForest = forestResiduals.rolling('60min').apply(lambda residual: np.sqrt(np.square(residual).mean()))
    rollingRmseLinear = linearResiduals.resample('60min').apply(lambda residual: np.sqrt(np.square(residual).mean()))
    rollingRmse = pd.concat([rollingRmseLinear, rollingRmseForest], axis=1)
    rollingRmse.columns = ['Linear rmse', 'Forest rmse']
    rollingRmse = rollingRmse.dropna()
    
    
    fig, axes = plt.subplots(nrows=2,
                             ncols=1,
                             sharex=True)
    axes[0].set_title(modelType + " - Residual Comparison", fontsize=15)
    
    linearResiduals.plot(use_index=True, style = 'b', ax=axes[0])
    forestResiduals.plot(use_index=True, style = 'r', ax=axes[0])
    axes[0].set_ylabel('Residuals')
    axes[0].legend(('Linear', 'Tree'))
    axes[1].set_title(modelType + " - Rolling RMSE Comparison", fontsize=15)
    rollingRmse.plot(use_index=True, y = 'Linear rmse', style = 'b', ax=axes[1])
    rollingRmse.plot(use_index=True, y = 'Forest rmse', ax=axes[1], style='r')
    axes[1].legend(('Linear', 'Tree'))
    axes[1].set_ylabel('RMSE')
    plt.show()
    
def plotRMSEComparison(linearResiduals, forestResiduals, modelType):
    
    bucketRmse = getBucketRMSE(linearResiduals, forestResiduals)
    
    ax = bucketRmse.plot(use_index=True, y = 'Linear rmse', style = 'b')
    bucketRmse.plot(use_index=True,y = 'Forest rmse', ax=ax, style='r')
    plt.legend(('Linear', 'Tree'))
    plt.xlabel('Datetime')
    plt.ylabel('RMSE')
    plt.title(modelType + " - Bucket RMSE", fontsize=15)
    plt.show()
    
    ax = bucketRmse.plot.bar(rot = 0)
    plt.legend(('Linear', 'Tree'))
    plt.xlabel('Datetime')
    plt.ylabel('RMSE')
    plt.title(modelType + " - Bucket RMSE", fontsize=15)
    plt.show()

def getBucketRMSE(linearResiduals, forestResiduals):
    bucketRmseForest = forestResiduals.resample('60min').apply(lambda residual: np.sqrt(np.square(residual).mean()))
    bucketRmseLinear = linearResiduals.resample('60min').apply(lambda residual: np.sqrt(np.square(residual).mean()))
    bucketRmse = pd.concat([bucketRmseLinear, bucketRmseForest], axis=1)
    bucketRmse.columns = ['Linear rmse', 'Forest rmse']
    bucketRmse = bucketRmse.dropna()
    return bucketRmse

def plotDirectionalPerformance(origResponsesTest, testResults, convergenceIndicator, title):
    fig = plt.figure(figsize = (15, 7))
    fig.suptitle(title, fontsize = 15)
    grid = fig.add_gridspec(3, 1)
    ax1 = fig.add_subplot(grid[0:2, :])
    ax2 = fig.add_subplot(grid[2, :], sharex = ax1)
    
    origResponses = origResponsesTest.dropna()
    testResults.plot(y='yActual', use_index=True, style = 'b-', ax = ax1)
    origResponsesTest.plot(use_index=True, ax = ax1, style='r*')
    testResults.plot(y='yHat', use_index=True, ax = ax1, style = 'go-')
    plt.legend(('yActual Resampled', 'yActual Samples', 'yPredicted'))
    # plt.axvline(x = origResponses.index[nPoint], color='r')
    for nPoint in np.arange(len(origResponses) - 1): 
        backgroundColour = 'g'*convergenceIndicator.Convergence.iloc[nPoint] + \
            'r'*(convergenceIndicator.Convergence.iloc[nPoint] == False)
        ax1.axvspan(origResponses.index[nPoint], origResponses.index[nPoint + 1],
                    facecolor = backgroundColour, alpha = 0.5)
    ax2.stem(testResults.index, testResults.yActual - testResults.yHat)
    ax2.axhspan(10, 100, facecolor = 'r', alpha = 0.5)
    ax2.axhspan(-100, -10, facecolor = 'r', alpha = 0.5)
    plt.show()
    return ax1

def plotExploratoryVisualisations(predictorSeries, responseSeries, saveLoc=None):
    fig = plt.figure(figsize = (15, 7))
    fig.suptitle(predictorSeries.name, fontsize = 15)
    grid = fig.add_gridspec(2, 4)
    ax1 = fig.add_subplot(grid[0, 0:3])
    ax3 = fig.add_subplot(grid[0, 3])
    ax3.axis("off")
    sns.lineplot(data = predictorSeries, ax = ax1)
    ax2 = ax1.twinx()
    sns.lineplot(data = responseSeries, ax = ax2, color = 'r')
    sns.histplot(data = predictorSeries.to_frame().reset_index(), y = predictorSeries.name,
                 ax = ax3, color="LightBlue")
    ax4 = fig.add_subplot(grid[1, 0:2])
    sns.regplot(x = predictorSeries, y = responseSeries, ax = ax4, marker = '.',
                scatter_kws={'s':2, 'alpha':0.1}, color = "red")
    ax5 = fig.add_subplot(grid[1, 2:])
    centredPredictor = predictorSeries - np.mean(predictorSeries)
    centredPredictor = centredPredictor.fillna(method = "ffill")
    centredResponse = responseSeries - np.mean(responseSeries)
    centredResponse = centredResponse.fillna(method = "ffill")
    
    predictorResiduals = AutoReg(centredPredictor.values, lags=10, old_names=False).fit().resid
    responseResiduals = AutoReg(centredResponse.values, lags=10, old_names=False).fit().resid
    
    ax5.xcorr(predictorResiduals, responseResiduals, maxlags=30)
    if saveLoc is not None:
        fig.savefig(saveLoc + predictorSeries.name + '.png',
                    bbox_inches='tight', dpi = 600)

def plotTrainTestDistributions(predictorSeriesTrain, predictorSeriesTest,\
                               responseSeriesTrain, responseSeriesTest, saveLoc=None):
    fig = plt.figure(figsize = (15, 7))
    grid = fig.add_gridspec(2, 4)
    ax1 = fig.add_subplot(grid[0, 0:3])
    ax2 = fig.add_subplot(grid[0, 3])
    ax2.axis("off")
    sns.lineplot(data = predictorSeriesTrain, ax = ax1)
    sns.lineplot(data = predictorSeriesTest, ax = ax1, color = 'r')
    sns.histplot(data = predictorSeriesTrain.to_frame().reset_index(), y = predictorSeriesTrain.name,
                 ax = ax2, color="LightBlue", kde=True, bins = 50, stat = 'density')
    ax1.title.set_text(predictorSeriesTrain.name)
    sns.histplot(data = predictorSeriesTest.to_frame().reset_index(), y = predictorSeriesTest.name,
                 ax = ax2, color="Coral", kde=True, bins = 50, stat = 'density')
    ax3 = fig.add_subplot(grid[1, 0:3], sharex = ax1)
    sns.lineplot(data = responseSeriesTrain, ax = ax3)
    sns.lineplot(data = responseSeriesTest, ax = ax3, color = 'r')
    ax3.title.set_text(responseSeriesTest.name)
    ax4 = fig.add_subplot(grid[1, 3])
    ax4.axis("off")
    sns.histplot(data = responseSeriesTrain.to_frame().reset_index(), y = responseSeriesTrain.name,
                 ax = ax4, color="LightBlue", kde=True, bins = 50, stat = 'density')
    sns.histplot(data = responseSeriesTest.to_frame().reset_index(), y = responseSeriesTest.name,
                 ax = ax4, color="Coral", kde=True, bins = 50, stat = 'density')
    
    if saveLoc is not None:
        if not os.path.exists(saveLoc):
            os.makedirs(saveLoc)
        fig.savefig(saveLoc + predictorSeriesTrain.name + '.png',
                    bbox_inches='tight', dpi = 600)
        with open(saveLoc + predictorSeriesTrain.name + '.pickle', 'wb') as f:
            pickle.dump(fig, f)
    plt.close()