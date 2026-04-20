# -*- coding: utf-8 -*-
"""
Created on Thu Apr 14 15:43:32 2022

@author: antonio.peters
"""

from abc import ABC, abstractmethod
import scipy.signal as sp
import numpy as np
import datetime
# from datetime import datetime
import pickle
# import hickle as hkl
import os
import pandas as pd
from sklearn.model_selection import TimeSeriesSplit
from skopt import BayesSearchCV
import sklearn.metrics as metrics
from sklearn.model_selection import cross_val_score

class Model(ABC):
    
    #%% Constructor

    def __init__(self, fullDF, predictorTags, responseTags, origSmoothedResponses, outputLogger=None):
        self.fullDF = fullDF
        self.predictorTags = predictorTags
        self.responseTags = responseTags
        self.origSmoothedResponses = origSmoothedResponses
        self.outputLogger = outputLogger
        
        return True
       
    #%% Abstract Functions for Child Classes
   
    @abstractmethod
    def train(self):
        pass
    
    @abstractmethod
    def evaluate(self, fileName):
        pass
    
    @abstractmethod
    def test(self):
        pass


    def loadTrainedModel(self, modelPath):
        #Load trained model and print overall model performance results

        model = pickle.load(open(modelPath, 'rb'))

        #TODO: Work on validation
        self._validateModel(model[0])

        self.model = model[0]
        self.intervalRange = model[1]

        pass

    def _saveTrainedModel(self, path, modelName, intervalRange=0):
                               
        trainedModel = self.model
        
        # file name based on data start and end date.

        fullDataFrame = self.fullDF

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

    
    #%% Private Class Functions
    
    def _splitIntoTestAndTrain(self, trainFrac=None):

        trainDates = self.fullDF.index[:round(trainFrac * len(self.fullDF))]
        testDates = self.fullDF.index[round(trainFrac * len(self.fullDF)):]

        self.origResponsesTrain = self.origSmoothedResponses[
            (self.origSmoothedResponses.index >= trainDates[0]) &
            (self.origSmoothedResponses.index <= trainDates[-1])]
        self.origResponsesTest = self.origSmoothedResponses[
            (self.origSmoothedResponses.index >= testDates[0]) &
            (self.origSmoothedResponses.index <= testDates[-1])]

        trainDF = self.fullDF[
            (self.fullDF.index >= trainDates[0]) &
            (self.fullDF.index <= trainDates[-1])]
        testDF = self.fullDF[
            (self.fullDF.index >= testDates[0]) &
            (self.fullDF.index <= testDates[-1])]

        trainDF = trainDF[~trainDF[self.predictorTags+self.responseTags].isna().any(axis=1)]
        testDF = testDF[~testDF[self.predictorTags+self.responseTags].isna().any(axis=1)]

        self.responsesTest = testDF[self.responseTags]
        self.predictorsTest = testDF[self.predictorTags]

        self.responsesTrain = trainDF[self.responseTags]
        self.predictorsTrain = trainDF[self.predictorTags]

    def _defineCrossValProperties(self, maxTrainSize, testSize, numIter, pipe, param):
        nSplits = int(np.ceil((len(self.predictorsTrain) - maxTrainSize)/testSize))
        tscv = TimeSeriesSplit(n_splits = nSplits, max_train_size = maxTrainSize,
                               test_size = testSize)
        self.outputLogger.log_trace('Time Series Split Complete')

        randomSearch = BayesSearchCV(estimator = pipe, search_spaces = param,
                                     n_iter = numIter, cv = tscv, verbose = 5,
                                     scoring = 'neg_root_mean_squared_error')
        self.outputLogger.log_trace('Bayes Search Complete')

        searchResults = randomSearch.fit(self.predictorsTrain, self.responsesTrain)
        self.outputLogger.log_trace('Random Search Complete')
        # searchResults = [];

        return searchResults
    
    def _fitModel(self, maxTrainSize, testSize, model):
        predictorsTestPrepended = pd.concat((self.predictorsTrain[-maxTrainSize:], self.predictorsTest))
        responsesTestPrepended = pd.concat((self.responsesTrain[-maxTrainSize:], self.responsesTest))
        nSplits = int(np.ceil((len(predictorsTestPrepended) - maxTrainSize) / testSize))
        tscv = TimeSeriesSplit(n_splits=nSplits, max_train_size=maxTrainSize,
                               test_size=testSize)

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

            [model, latestTestResults] = self._trainAndTestModel(model, xTrain, yTrain.ravel(),
                                                                xTest, yTest.ravel(), yTestDS.index)

            latestTrainResults = self._testModel(model, xTrain, yTrain.ravel(), yTrainDS.index)

            testResults = pd.concat((testResults, latestTestResults))
            trainResults = pd.concat((trainResults, latestTrainResults))
 
        self.outputLogger.log_info('--------------------------------------------------------------')
        self.outputLogger.log_info('Overall Results - Test')
            
        explained_variance, mean_absolute_error, mse, r2 = self._regression_results(testResults.yActual, testResults.yHat)
        
        xValScores = cross_val_score(model, self.predictorsTrain, self.responsesTrain, cv = tscv,
                                     scoring = 'neg_root_mean_squared_error')
        intervalRange = -1*np.mean(xValScores)

        
        self.testResults = testResults
        self.trainResults = trainResults
        self.model = model

        return explained_variance, mean_absolute_error, mse, r2, intervalRange

    def _trainAndTestModel(self, mdl, xTrain, yTrain, xTest, yTest, index):
        mdl.fit(xTrain, yTrain)
        yHatTest = mdl.predict(xTest)
        self.outputLogger.log_info('--------------------------------------------------------------')
        self.outputLogger.log_info('Model Results - Test')
        
        self._regression_results(yTest, yHatTest)
        
        # Visualising Results
        
        results = pd.DataFrame(data = np.concatenate((yTest[:, np.newaxis],
                                                      yHatTest[:, np.newaxis]), axis=1),
                               index=index, columns=('yActual','yHat'))
        return mdl, results
    
    def _testModel(self, mdl, xData, yData, index):
        yHat = mdl.predict(xData)
        self.outputLogger.log_info('--------------------------------------------------------------')
        self.outputLogger.log_info('Model Results')
        
        self._regression_results(yData, yHat)

        results = pd.DataFrame(data=np.concatenate((yData[:, np.newaxis],
                                                    yHat[:, np.newaxis]), axis=1),
                               index=index, columns=('yActual', 'yHat'))
        return results
    
    def _regression_results(self, y_true, y_pred):

        # Regression metrics
        explained_variance=metrics.explained_variance_score(y_true, y_pred)
        mean_absolute_error=metrics.mean_absolute_error(y_true, y_pred) 
        mse=metrics.mean_squared_error(y_true, y_pred) 
        r2=metrics.r2_score(y_true, y_pred)

        self.outputLogger.log_info(f'explained_variance: {round(explained_variance,4)}')
        self.outputLogger.log_info(f'r2: {round(r2,4)}')
        self.outputLogger.log_info(f'MAE: {round(mean_absolute_error,4)}')
        self.outputLogger.log_info(f'MSE: {round(mse,4)}')
        self.outputLogger.log_info(f'RMSE: {round(np.sqrt(mse),4)}')
        
        return explained_variance, mean_absolute_error, mse, r2

    def _applySilicaModel(self, predBasicity, basicityTarget, deadBand, silica_high, scilica_low):
        
        '''
        -   predBasicity is a Dataframe with the results from running one of the basicity models
            must contain the columns 'yhat'. The output Silica change is written to the same DF
        '''
        
        # Calculate the low range and high range coefficients
        [lowRange, highRange, f] = self._getSilica(basicityTarget, deadBand, silica_high, scilica_low)
        
        # # Calculate change in silica compared to predicted basicity value
        # f = lambda x, coeffs : coeffs[0] * x**2 + coeffs[1] * x + coeffs[2]
        
        if isinstance(predBasicity, list):
            basicityVal = predBasicity[-1]
        else:
            basicityVal =predBasicity
        if basicityVal < basicityTarget:
            changeSilica = f(basicityVal, lowRange['coeffs'])
        else:
            changeSilica = f(basicityVal, highRange['coeffs'])
        
        return [changeSilica]

#%% Public Static Functions

    @staticmethod
    def _validateModel(model):

        return 
    
    @staticmethod
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
        
    #%% Private Static Functions
    
    @staticmethod
    def _getSilica(basicityTarget, deadBand, silica_high, scilica_low):
        
        '''
        -   the basicity regression model outputs different results depending on which part
            of the silica curve you within range (below/above the basicity target).
            Shown here as low range vs high range
        -   for deployment
        '''
        
        lowRangeBasicity = np.linspace(1.25, basicityTarget, 7)
        highRangeBasicity = np.linspace(basicityTarget, 2.25, 7)
        
        # Low range
        baseData = np.array([1.2, 1.5, 1.7])
        basicity = baseData + basicityTarget - deadBand/2 - np.max(baseData)
        silica = np.array([scilica_low['silicaLowMin'], scilica_low['silicaLowMax'], 0])
        lowRangeCoeffs = np.polyfit(basicity, silica, 2)
        f = lambda x, coeffs : coeffs[0] * x**2 + coeffs[1] * x + coeffs[2]
        lowRangeSilica = f(lowRangeBasicity, lowRangeCoeffs)

        # High range
        baseData = np.array([1.7, 1.9, 2.2])
        basicity = baseData + basicityTarget - deadBand/2 - np.min(baseData)
        silica = np.array([0, silica_high['silicaHighMin'], silica_high['silicaHighMax']])
        highRangeCoeffs = np.polyfit(basicity, silica, 2)
        highRangeSilica = f(highRangeBasicity, highRangeCoeffs)
        
        
        lowRange = {'basicity' : lowRangeBasicity,
                    'silica' : lowRangeSilica,
                    'coeffs' : lowRangeCoeffs,
            }
        
        highRange = {'basicity' : highRangeBasicity,
                    'silica' : highRangeSilica,
                    'coeffs' : highRangeCoeffs,
            }
        
        return lowRange, highRange, f
    
    @staticmethod
    def _addSteadyStateSignal(fullDF, offPeriod):

        # Filter for mode 8
        filteredDF = fullDF.loc[(fullDF["Converter mode"] == 8)]

        # Find peaks in blows

        n = 5
        filteredDF['Peaks'] = filteredDF.iloc[sp.argrelextrema(filteredDF['Lance air and oxygen control'].values,
                                                       np.greater_equal, order=n)[0]]['Lance air and oxygen control'] > 0
        filteredDF['Peaks'] = filteredDF['Peaks'].fillna(False)
        filteredDF.Peaks[(filteredDF.Peaks != False)] = True

        # Define number of hours process needs to operate out of mode 8
        offTimeAllowed = datetime.timedelta(hours=offPeriod)

        # Find diff difference between Timestamps
        timeDiff = filteredDF.index.to_series().diff()
        # Set the first timeDiff to a high value (conservative)
        timeDiff[0] = datetime.timedelta(hours=9999)
        # Find where the process is off (i.e. not mode 8)
        processOff = timeDiff >= offTimeAllowed
        processOffIdx = np.where(processOff)
        # Find the peak that follow processOff data points
        nextPeakIdx = [np.argmax(filteredDF['Peaks'][x:]) + x for x in processOffIdx[0]]
        # Create a Steadystate series and populate with True and False, then forward-fill
        filteredDF['Steadystate'] = np.nan
        filteredDF['Steadystate'][nextPeakIdx] = True
        filteredDF['Steadystate'][processOff] = False
        filteredDF['Steadystate'].ffill(inplace=True)

        fullDF = fullDF.join(filteredDF['Steadystate'], how='outer')
        fullDF = fullDF.join(filteredDF['Peaks'], how='outer')

        fullDF['Steadystate'] = fullDF['Steadystate'].fillna(False)
        fullDF['Peaks'] = fullDF['Peaks'].fillna(False)

        return fullDF
    
    @staticmethod
    def _removeTransientData(fullDF):
        # Remove transient data
        fullDF = fullDF[fullDF['Steadystate']]
        return fullDF

    @staticmethod
    def _smoothBasicityResponse(fullDF):
        responses, irregularIdx = Model._getUniqueDataPoints(fullDF['Basicity'])
        responses = responses.fillna(method = 'ffill')
        fullDF['Basicity'] = Model._smoothBasicity(responses, fullDF['SumOfSpecies'][irregularIdx])
        return fullDF
    
    @staticmethod
    def _getUniqueDataPoints(dataSeries):
        valueChangeIdx = np.append(True, np.diff(dataSeries.values.ravel()) != 0)
        valueChangeIdx[-1] = True
        irregularIdx = dataSeries.index[valueChangeIdx]
        uniqueDataSeries = dataSeries.iloc[valueChangeIdx]
        uniqueDataSeries = uniqueDataSeries[0:-1]
        return uniqueDataSeries, irregularIdx
    
    @staticmethod
    def _smoothBasicity(responses, speciesWeight):
        timeWeight = np.insert(np.exp(-0.05 * np.diff(responses.index).astype(float)[:, np.newaxis] / 1e9 / 60), 0, 0)
        timeWeight[timeWeight == 0] = min(timeWeight[timeWeight != 0])
        speciesWeight = speciesWeight[0:-1].values
        smoothFactor = (timeWeight * (speciesWeight / 100)) ** (0.5)
        smoothFactor[0] = 1

        weightMatrix = np.zeros((smoothFactor.size, smoothFactor.size))

        for nCol in np.arange(1, smoothFactor.size - 1):
            weightMatrix[nCol - 1:, nCol - 1] = np.cumprod(np.insert(1 - smoothFactor[nCol:],
                                                                     0, smoothFactor[nCol - 1]))
        weightMatrix[-1, -1] = smoothFactor[-1]

        smoothedResp = np.matmul(weightMatrix, responses.values[:, np.newaxis])
        smoothedResp = pd.Series(data=smoothedResp.flatten(), index=responses.index)
        return smoothedResp

    @staticmethod 
    def _addMeasureIndicatorsAsPredictors(fullDF, predictorTags, on=None):

        predictorsIrregularIdx = {}
        measureIndicatorKeys = []

        if on is not None:
            for tag in on:
                _, predictorIrregularIdx = Model._getUniqueDataPoints(fullDF[tag])
                measureIndicatorKeys.append(f'{tag} Measure Indicator')
                predictorsIrregularIdx[measureIndicatorKeys[-1]] = predictorIrregularIdx
        else:
            for tag in predictorTags:
                _, predictorIrregularIdx = Model._getUniqueDataPoints(fullDF[tag])
                if len(predictorIrregularIdx ) /len(fullDF) < 0.05 and tag.find('rollingsum') == -1:
                    measureIndicatorKeys.append(f'{tag} Measure Indicator')
                    predictorsIrregularIdx[measureIndicatorKeys[-1]] = predictorIrregularIdx

        fullDF[measureIndicatorKeys] = np.ones([len(fullDF), len(measureIndicatorKeys)])

        for key in measureIndicatorKeys:
            irregularIdx = predictorsIrregularIdx[key]
            fullDF[key] = fullDF[key].groupby(
                irregularIdx[irregularIdx.searchsorted(fullDF.index)]).cumsum()
            fullDF[key].loc[irregularIdx] = 0

        return fullDF, measureIndicatorKeys

    @staticmethod 
    def _addRollingMeanPredictors(fullDF, predictorTags, window):
        # Add rolling sum columns on all variables
        predictorTagsMeans = [x + ' rollingmean' for x in predictorTags]
        fullDF[predictorTagsMeans] = fullDF[predictorTags].rolling(window).mean()
        return fullDF, predictorTagsMeans
        
    @staticmethod 
    def _addRollingSumPredictors(fullDF, predictorTags, window):
        # Add rolling sum columns on all variables
        predictorTagsSums = [x + ' rollingsum' for x in predictorTags]
        zeroCentredData = fullDF[predictorTags] - fullDF[predictorTags].rolling(window).median()
        fullDF[predictorTagsSums] = zeroCentredData.rolling(window).sum()
        return fullDF, predictorTagsSums
    
    @staticmethod 
    def _addLagsAsPredictors(fullDF, inputTags, totalLags):
        actualMeasurements = fullDF[inputTags].dropna()
        laggedDataframe = pd.DataFrame(index = fullDF.index)
        for nLag in np.arange(1, totalLags+1):
            laggedResponse = actualMeasurements.shift(periods = nLag)
            laggedResponse = laggedResponse.resample('1min').asfreq()
            dropRange = laggedResponse.index[laggedResponse.index <= actualMeasurements.index[nLag-1]]
            laggedResponse = laggedResponse.drop(dropRange).fillna(method = 'bfill')
            laggedDataframe = pd.concat([laggedDataframe, laggedResponse], axis = 1)
        newPredictorNames = [str(nLag) + '-Lag ' + tag for nLag in np.arange(1, totalLags + 1) for tag in inputTags]
        laggedDataframe.columns = newPredictorNames
        fullDF[laggedDataframe.columns] = laggedDataframe
        return fullDF, newPredictorNames
