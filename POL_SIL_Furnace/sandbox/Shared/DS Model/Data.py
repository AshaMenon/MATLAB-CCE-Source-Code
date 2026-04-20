import numpy as np
import datetime
import pandas as pd
import scipy.signal as sp
import os
import sys
import pathlib
import pickle
# from statsmodels.tsa.api import SimpleExpSmoothing
from scipy import signal


class Data:
	# Version 1.1
	# 30 Sept 2022
    # %% Constructor
    def __init__(self, fullDFOrig, outputLogger=None):
        self.outputLogger = outputLogger
        self.fullDF = fullDFOrig
        
    @staticmethod
    def checkSteadyStateSignal(fullDF, offPeriod, nPeaksOff, responseTags, outputLogger):
        # Specifically for running online. 

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
       
       # How many blows are there after the LAST off period?
       lastOffIdx = processOffIdx[0][-1]
       if sum(filteredDF['Peaks'].iloc[lastOffIdx:-1]) < nPeaksOff:
           nPeaksOff = sum(filteredDF['Peaks'].iloc[lastOffIdx:-1])
           outputLogger.log_trace('nPeaksOff value changed to {0}'.format(nPeaksOff))
           raise Exception('There are only {0} blows in the time series, exiting'.format(nPeaksOff))
           
       # Find the peak that follow processOff data points
       nextPeakIdx = []
       for x in processOffIdx[0]:
           tempPeak = np.where(filteredDF['Peaks'][x:])[0]
           if (len(tempPeak) >= nPeaksOff):
               nextPeakIdx.append(tempPeak[nPeaksOff - 1] + x)
           else:
               raise Exception('Not enough blows {0} after process was off, unable to calculate, exiting'.format(nPeaksOff))
       
       # Checks that the furnace does not experience downtime/transient conditions greater than 1 hour between related processOffIdx and nextPeakIdx points and removes false peaks from nextPeakIdx when it occurs 
       erroneousPeak = processOffIdx[0][1:] >= nextPeakIdx[:len(nextPeakIdx)-1]
       erroneousPeakIdx = np.where(erroneousPeak)
       resetNextPeakIdx = [nextPeakIdx[x] for x in erroneousPeakIdx[0]]
       resetNextPeakIdx.append(nextPeakIdx[len(nextPeakIdx)-1])
       nextPeakIdx = resetNextPeakIdx
       
       # Create a Steadystate series and populate with True and False, then forward-fill
       filteredDF['Steadystate'] = np.nan
       filteredDF['Steadystate'][nextPeakIdx] = True
       filteredDF['Steadystate'][processOff] = False
       filteredDF['Steadystate'].ffill(inplace=True)
           
       if sum(filteredDF['Steadystate']) < 4:
           nPeaksOff = sum(filteredDF['Steadystate'])
           outputLogger.log_trace('Only {0} Steady State data points after 3 Blows, not enough to calculate.'.format(nPeaksOff))
       
       if not filteredDF['Steadystate'][-1]:
           Exception('Latest data point not in Steady state, exiting.')
        
       return nPeaksOff

    @staticmethod
    def _addSteadyStateSignal(fullDF, offPeriod, nPeaksOff, responseTags):
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
       nextPeakIdx = []
       for x in processOffIdx[0]:
           tempPeak = np.where(filteredDF['Peaks'][x:])[0]
           if (len(tempPeak) >= nPeaksOff):
               nextPeakIdx.append(tempPeak[nPeaksOff - 1] + x)
           else:
               raise Exception('Not enough blows {0} after process was off, unable to calculate, exiting'.format(nPeaksOff))

       
       # Checks that the furnace does not experience downtime/transient conditions greater than 1 hour between related processOffIdx and nextPeakIdx points and removes false peaks from nextPeakIdx when it occurs 
       erroneousPeak = processOffIdx[0][1:] >= nextPeakIdx[:len(nextPeakIdx)-1]
       erroneousPeakIdx = np.where(erroneousPeak)
       resetNextPeakIdx = [nextPeakIdx[x] for x in erroneousPeakIdx[0]]
       resetNextPeakIdx.append(nextPeakIdx[len(nextPeakIdx)-1])
       nextPeakIdx = resetNextPeakIdx
       
       # Create a Steadystate series and populate with True and False, then forward-fill
       filteredDF['Steadystate'] = np.nan
       filteredDF['Steadystate'][nextPeakIdx] = True
       filteredDF['Steadystate'][processOff] = False
       filteredDF['Steadystate'].ffill(inplace=True)

       fullDF = fullDF.join(filteredDF['Steadystate'], how='outer')
       fullDF = fullDF.join(filteredDF['Peaks'], how='outer')
       
       fullDF['Steadystate'] = fullDF['Steadystate'].fillna(False)
       fullDF['Peaks'] = fullDF['Peaks'].fillna(False)
       
       # Accounting for large time diffs in response
       # Get original responses
       origSmoothedResponses, _ = Data._getUniqueDataPoints(fullDF[responseTags].dropna())
       
       # Get median sample time - some multiple of this will be the threshold
       timeBetweenMeasurements = np.diff(origSmoothedResponses.index).astype(float)/1e9/60
       medianSampleTime = np.median(timeBetweenMeasurements) #minutes
       noMeasurementThreshold = 2*medianSampleTime
       
       # Get index of Large time differences between readings
       noMeasurementIdx = timeBetweenMeasurements > noMeasurementThreshold
       noMeasurementIdx = np.insert(noMeasurementIdx, 0, False)
       
       # Creating the mask
       noMeasurementSeries = pd.Series(index = origSmoothedResponses.index, data = noMeasurementIdx)
       measurementTimeMask = pd.Series(index = fullDF.index)
       measurementTimeMask[measurementTimeMask == False].index - np.timedelta64(1, 'm')
       
       measurementTimeMask[noMeasurementSeries.index] = ~noMeasurementSeries
       
       measurementTimeMask[origSmoothedResponses.index[noMeasurementIdx]] = True
       
       return fullDF

    @staticmethod
    def _removeTransientData(fullDF):
        # Remove transient data
        fullDF = fullDF[fullDF['Steadystate']]
        return fullDF

    @staticmethod
    def _smoothBasicity(responses, speciesWeight):
        timeWeight = np.insert(np.exp(-0.05 * np.diff(responses.index).astype(float)[:, np.newaxis] / 1e9 / 60), 0, 0)
        if len(timeWeight[timeWeight != 0]) == 0:
            raise Exception('Insufficient number of Basicity data points to perform smoothBasicity.')
        timeWeight[timeWeight == 0] = min(timeWeight[timeWeight != 0])
        speciesWeight = speciesWeight.values
        smoothFactor = (timeWeight * (speciesWeight / 100)) ** (0.5)
        smoothFactor[0] = 1

        weightMatrix = np.zeros((smoothFactor.size, smoothFactor.size))

        for nCol in np.arange(1, smoothFactor.size):
            weightMatrix[nCol - 1:, nCol - 1] = np.cumprod(np.insert(1 - smoothFactor[nCol:],
                                                                     0, smoothFactor[nCol - 1]))
        weightMatrix[-1, -1] = smoothFactor[-1]

        smoothedResp = np.matmul(weightMatrix, responses.values[:, np.newaxis])
        smoothedResp = pd.Series(data=smoothedResp.flatten(), index=responses.index)
        return smoothedResp

    @staticmethod
    def _smoothBasicityResponse(fullDF):
        responses, irregularIdx = Data._getUniqueDataPoints(fullDF['Basicity'])
        responses = responses.fillna(method='ffill')
        fullDF['rawBasicity'] = fullDF['Basicity'].copy()
        fullDF['Basicity'] = Data._smoothBasicity(responses, fullDF['SumOfSpecies'][irregularIdx])
        return fullDF

    @staticmethod
    def _addMeasureIndicatorsAsPredictors(fullDF, predictorTags, on=None):

        predictorsIrregularIdx = {}
        measureIndicatorKeys = []

        if on is not None:
            for tag in on:
                _, predictorIrregularIdx = Data._getUniqueDataPoints(fullDF[tag])
                measureIndicatorKeys.append(f'{tag} Measure Indicator')
                predictorsIrregularIdx[measureIndicatorKeys[-1]] = predictorIrregularIdx
        else:
            for tag in predictorTags:
                _, predictorIrregularIdx = Data._getUniqueDataPoints(fullDF[tag])
                if len(predictorIrregularIdx) / len(fullDF) < 0.05 and tag.find('rollingsum') == -1:
                    measureIndicatorKeys.append(f'{tag} Measure Indicator')
                    predictorsIrregularIdx[measureIndicatorKeys[-1]] = predictorIrregularIdx

        fullDF[measureIndicatorKeys] = np.ones([len(fullDF), len(measureIndicatorKeys)])

        for key in measureIndicatorKeys:
            irregularIdx = predictorsIrregularIdx[key]
            fullDF[key] = fullDF[key].groupby(
                irregularIdx.searchsorted(fullDF.index)).cumsum()
            fullDF[key].loc[irregularIdx] = 0

        return fullDF, measureIndicatorKeys

    @staticmethod
    def _addRollingSumPredictors(fullDF, predictorTags, window):
        # Add rolling sum columns on all variables
        predictorTagsSums = [x +' ' + str(window) + '-rollingsum' for x in predictorTags]
        zeroCentredData = fullDF[predictorTags] - fullDF[predictorTags].rolling(window).median()
        fullDF[predictorTagsSums] = zeroCentredData.rolling(window).sum()
        return fullDF, predictorTagsSums

    @staticmethod
    def _addRollingMeanPredictors(fullDF, predictorTags, window):
        # Add rolling mean columns on all variables
        predictorTagsMeans = [x + ' ' + str(window) + '-rollingmean' for x in predictorTags]
        fullDF[predictorTagsMeans] = fullDF[predictorTags].rolling(window).mean()
        return fullDF, predictorTagsMeans

    @staticmethod
    def _getUniqueDataPoints(dataSeries):
        valueChangeIdx = np.append(True, np.diff(dataSeries.values.ravel()) != 0)
        irregularIdx = dataSeries.index[valueChangeIdx]
        uniqueDataSeries = dataSeries.iloc[valueChangeIdx]

        return uniqueDataSeries, irregularIdx

    @staticmethod
    def _addRollingMeanResponse(fullDF, responseSeries, responseTags, window):
        # Add rolling mean columns on response variables
        responseMovingAverageTag = [x + ' ' + str(window) + '-rollingmean' for x in responseTags]
        fullDF[responseMovingAverageTag] = responseSeries.rolling(window).mean()
        fullDF[responseMovingAverageTag] = fullDF[responseMovingAverageTag].fillna(method = 'ffill')
        return fullDF, responseMovingAverageTag

    @staticmethod
    def _addLagsAsPredictors(fullDF, inputTags, totalLags):
        dfCopy = fullDF.copy()
        laggedDataframe = pd.DataFrame(index = dfCopy.index)
        for column in inputTags:
            dfCopy[column], _ = Data._getUniqueDataPoints(dfCopy[column])
            actualMeasurements = dfCopy[column].dropna()
            actualMeasurements = pd.concat((actualMeasurements, pd.Series(data=0, index=dfCopy.index[-1:])))
            actualMeasurements = actualMeasurements[~actualMeasurements.index.duplicated(keep='first')]
            if len(actualMeasurements) < totalLags + 1:
                raise Exception(f'Not enough data in "{column}" to create sufficient lags')
            for nLag in np.arange(1, totalLags + 1):
                laggedResponse = actualMeasurements.shift(periods = nLag)
                laggedResponse = laggedResponse.resample('1min').asfreq()
                dropRange = laggedResponse.index[laggedResponse.index <= actualMeasurements.index[nLag - 1]]
                laggedResponse = laggedResponse.drop(dropRange).fillna(method='bfill')
                laggedDataframe = pd.concat([laggedDataframe, laggedResponse], axis = 1)
        newPredictorNames = [str(nLag) + '-Lag ' + tag for tag in inputTags for nLag in np.arange(1, totalLags + 1)]
        laggedDataframe.columns = newPredictorNames
        fullDF[laggedDataframe.columns] = laggedDataframe
        return fullDF, newPredictorNames
    
    @staticmethod
    def _addDifferenceAsPredictors(fullDF, tagList):
        predictorTagsDifferenced = []
        for tag in tagList:
            origUniqueData, _ = Data._getUniqueDataPoints(fullDF[tag].dropna())
            diffTag = tag + ' differenced'
            fullDF[diffTag] = origUniqueData.diff()
            fullDF[diffTag] = fullDF[diffTag].fillna(method = 'ffill')
            predictorTagsDifferenced += [diffTag]
        return fullDF, predictorTagsDifferenced

    @staticmethod
    def _restrictData(columnNames):
        operatingRangeDict = dict.fromkeys(columnNames, (-1000000, 1000000))
        operatingRangeDict["Cu Slag"] = (0.1, 25)
        operatingRangeDict["Ni Slag"] = (0.2, 30)
        operatingRangeDict["Corrected Ni Slag"] = (0.5, 10)
        operatingRangeDict["Co Slag"] = (0, 10)
        operatingRangeDict["Fe Slag"] = (20, 60)
        operatingRangeDict["S Slag"] = (0.1, 20)
        operatingRangeDict["Al2O3 Slag"] = (0.5, 6)
        operatingRangeDict["CaO Slag"] = (0.2, 3)
        operatingRangeDict["MgO Slag"] = (0.1, 2)
        operatingRangeDict["Cr2O3 Slag"] = (0.1, 10)
        operatingRangeDict["SiO2 Slag"] = (0.1, 60)  # check
        operatingRangeDict["Basicity"] = (1.1, 2.5)
        operatingRangeDict["Cu Matte"] = (20, 40)
        operatingRangeDict["Ni Matte"] = (30, 50)
        operatingRangeDict["Co Matte"] = (0.05, 1.0)
        operatingRangeDict["Fe Matte"] = (0, 20)
        operatingRangeDict["S Matte"] = (5, 35)
        operatingRangeDict['Specific Oxygen Actual PV'] = (0, 10000)
        operatingRangeDict['Specific Silica Actual PV'] = (0, 300)
        operatingRangeDict["Matte feed PV(unfiltered)"] = (0, 150)
        operatingRangeDict["Lance air flow rate PV"] = (0, 30000)
        operatingRangeDict["Lance air flow rate SP"] = (0, 30000)
        operatingRangeDict["Lance oxygen flow rate PV"] = (0, 10000)
        operatingRangeDict["Lance oxygen flow rate SP"] = (0, 10000)
        operatingRangeDict["Shroud air flow rate PV"] = (0, 14000)
        operatingRangeDict["Shroud air flow rate SP"] = (0, 14000)
        operatingRangeDict["Shroud oxygen flow rate PV"] = (0, 3000)
        operatingRangeDict["Shroud oxygen flow rate SP"] = (0, 3000)
        operatingRangeDict["Standby system coal transfer air pressure"] = (0, 30)
        operatingRangeDict["Motion"] = (0, 10)
        operatingRangeDict["Lance foam potential"] = (-20, 20)
        operatingRangeDict["Trolley foam potential"] = (-5, 5)
        operatingRangeDict["Slag mass flow"] = (0, 10)
        operatingRangeDict["Matte temperatures"] = (1100, 1600)
        operatingRangeDict["Slag temperatures"] = (1000, 1600)
        operatingRangeDict["Lance height"] = (0, 4000)
        operatingRangeDict["Fe in mould (per blow)"] = (0, 20)
        operatingRangeDict["Ni Feedblend"] = (1, 30)
        operatingRangeDict["Cu Feedblend"] = (6, 15)
        operatingRangeDict["Co Feedblend"] = (0, 10)
        operatingRangeDict["MgO Feedblend"] = (0, 10)
        operatingRangeDict["CaO Feedblend"] = (0, 10)
        operatingRangeDict["Al2O3 Feedblend"] = (0, 10)
        operatingRangeDict["Fe Feedblend"] = (20, 50)
        operatingRangeDict["S Feedblend"] = (5, 40)
        operatingRangeDict["SiO2 Feedblend"] = (0.5, 40)
        operatingRangeDict["Cr2O3 Feedblend"] = (0, 10)
        operatingRangeDict["Percent Vapour"] = (0.1, 20)
        operatingRangeDict["Lance feed PV"] = (0, 20)
        operatingRangeDict["Lump Coal SP"] = (0, 25)
        operatingRangeDict["Matte feed SP"] = (0, 60)
        operatingRangeDict["Matte feed PV filtered"] = (0, 60)
        operatingRangeDict["Roof feed PV"] = (0, 20)
        operatingRangeDict["Roof coal transfer air pressure"] = (0, 500)
        operatingRangeDict["Acid plant damper position"] = (0,50)
        operatingRangeDict["Blower 222"] = (50,100)
        operatingRangeDict["Blower 221"] = (50,100)
        operatingRangeDict["Lance Oxy Enrich % PV"] = (-1000,1000)
        operatingRangeDict["O2_SO2 Ratio 1"] = (0,45)
        operatingRangeDict["O2_SO2 Ratio 2"] = (0,45)
        operatingRangeDict["Roof Coal feed PV"] = (0,100)
        operatingRangeDict["Fuel coal feed rate PV"] = (0,100)
        operatingRangeDict["Lower waffle 19"] = (-20, 150)
        operatingRangeDict["Lower waffle 20"] = (-20, 150)
        operatingRangeDict["Lower waffle 21"] = (-20, 150)
        operatingRangeDict["Lower waffle 22"] = (-20, 150)
        operatingRangeDict["Lower waffle 23"] = (-20, 150)
        operatingRangeDict["Lower waffle 24"] = (-20, 150)
        operatingRangeDict["Lower waffle 25"] = (-20, 150)
        operatingRangeDict["Lower waffle 26"] = (-20, 150)
        operatingRangeDict["Lower waffle 27"] = (-20, 150)
        operatingRangeDict["Lower waffle 28"] = (-20, 150)
        operatingRangeDict["Lower waffle 29"] = (-20, 150)
        operatingRangeDict["Lower waffle 30"] = (-20, 150)
        operatingRangeDict["Lower waffle 31"] = (-20, 150)
        operatingRangeDict["Lower waffle 32"] = (-20, 150)
        operatingRangeDict["Lower waffle 33"] = (-20, 150)
        operatingRangeDict["Lower waffle 34"] = (-20, 150)
        operatingRangeDict["Upper waffle 3"] = (-20, 150)
        operatingRangeDict["Upper waffle 4"] = (-20, 150)
        operatingRangeDict["Upper waffle 5"] = (-20, 150)
        operatingRangeDict["Upper waffle 6"] = (-20, 150)
        operatingRangeDict["Upper waffle 7"] = (-20, 150)
        operatingRangeDict["Upper waffle 8"] = (-20, 150)
        operatingRangeDict["Upper waffle 9"] = (-20, 150)
        operatingRangeDict["Upper waffle 10"] = (-20, 150)
        operatingRangeDict["Upper waffle 11"] = (-20, 150)
        operatingRangeDict["Upper waffle 12"] = (-20, 150)
        operatingRangeDict["Upper waffle 13"] = (-20, 150)
        operatingRangeDict["Upper waffle 14"] = (-20, 150)
        operatingRangeDict["Upper waffle 15"] = (-20, 150)
        operatingRangeDict["Upper waffle 16"] = (-20, 150)
        operatingRangeDict["Upper waffle 17"] = (-20, 150)
        operatingRangeDict["Upper waffle 18"] = (-20, 150)
        operatingRangeDict["SpO2 PV"] = (0, 400)
        return operatingRangeDict

    @staticmethod
    def _filterExpectedDataRange(data, low, high):
        filteredData = np.where(~data.between(low, high), np.nan, data)
        return filteredData
    
    @staticmethod
    def _filterMultipleFurnaceModes(data, modes):
        modeIdx = data["Converter mode"] == modes[0]
        for nMode in np.arange(1, len(modes)):
            modeIdx = np.logical_or(modeIdx, data["Converter mode"] == modes[nMode])
        filteredData = data.loc[modeIdx]
        return filteredData
    
    @staticmethod
    def _smoothTagsOnChange(fullDF, smoothedTags, percentageAllowed):
        if len(smoothedTags) != len(percentageAllowed):
            raise Exception('For every tag to be smoothed, a corresponding allowed percentage change is required.')
        for nTag in np.arange(len(smoothedTags)):
            tag = smoothedTags[nTag]
            allowableChange = percentageAllowed[nTag]
            actualPercentagChange = fullDF[tag].diff()/fullDF[tag]*100
            violatingIdx = np.abs(actualPercentagChange) > allowableChange
            filteredTag = fullDF[tag].copy()
            filteredTag.loc[violatingIdx] = np.nan
            filteredTag = filteredTag.fillna(method = 'ffill')
            fullDF[tag] = filteredTag
        return fullDF
    
    @staticmethod
    def _smoothFuelCoal(coalFeedRate):
        upperCoalFeedThreshold = 2.5
        lowerCoalFeedThreshold = 0.5
        threshold = 0.5     #units fuelCoalFeedRate/min

        for i in range(10,len(coalFeedRate)-1):
            gradient = coalFeedRate[i] - coalFeedRate[i-1]      #calculates the change in fuel coal feed rate between sucessive measurements
            if ((gradient > threshold) and (coalFeedRate[i] > upperCoalFeedThreshold)):   #if the change in successive feed rates is large and the next measurement is out of an acceptable bound then reset it
                coalFeedRate[i] = coalFeedRate[i-1]
            elif ((gradient < -threshold) and (coalFeedRate[i] < lowerCoalFeedThreshold)): #if the change in successive feed rates is large (in the negative direction) and the next measurement is out of an acceptable bound then reset it   
                coalFeedRate[i] = coalFeedRate[i-1]
            elif ((gradient > 1) or (gradient < -1)):   #if the change in fuel coal rate is [excessively] large then reset the next measurement
                coalFeedRate[i] = coalFeedRate[i-1]
        
        # #The code below smoothes out the response of the coalFeedRate, it has been implemented below to decrease runtime. For a real time application it needs to be included in the for loop so that it updates every minute.
        # smoothCoalFeedRate = SimpleExpSmoothing(coalFeedRate[:i], initialization_method="heuristic").fit(
        #     smoothing_level=0.1, optimized=False)
        # coalFeedRate = smoothCoalFeedRate.fittedvalues
                
        return coalFeedRate
    
    @staticmethod
    def _tappingClassification(fullDF, tag, startingPoint, increaseThreshold):
       
       tappingData = fullDF.loc[:,["Phase A Matte tap block 1 DT_water", "Phase A Matte tap block  DT_water",
       "Phase A Slag tap block DT_water"]]
       
       #Create a new coloumn in the dataframe to store classification data
       tappingData["Tapping Classification for " + tag] = 0
       
       #Apply a low pass filter on the the noisy slag tap block temp data (this is not applied in a real time format to save computing power - yields the same results when applied in a real-time format)
       if (tag == "Phase A Slag tap block DT_water"):
           b, a = signal.iirfilter(2, Wn=2.5, fs=30, btype="low", ftype="butter")
           tappingData["Phase A Slag tap block DT_water"] = signal.lfilter(b, a, tappingData["Phase A Slag tap block DT_water"])
        
       #Iterate through the data in a real-time approach to find definite increases in temperature between successive points
       difference2 = tappingData[tag].diff(periods = 2)
       difference3 = tappingData[tag].diff(periods = 3)
       difference4 = tappingData[tag].diff(periods = 4)
       difference5 = tappingData[tag].diff(periods = 5)
       
       tapIdx = np.logical_and.reduce((difference2 > 0, difference3 > 0, difference4 > 0, difference5 > increaseThreshold))
       
       tappingData["Tapping Classification for " + tag][tapIdx] = 1  
              
       fullDF["Tapping Classification for " + tag] = tappingData["Tapping Classification for " + tag]
             
       return fullDF

    def preprocessingAndFeatureEngineering(self,
                                           removeTransientData=True,
                                           filterFurnaceModes={'add': False, 'modes':[8]},
                                           smoothBasicityResponse=False,
                                           addRollingSumPredictors={'add': False, 'window': 30},
                                           addRollingMeanPredictors={'add': False, 'window': 5},
                                           addRollingMeanResponse = {'add': False, 'window':10},
                                           addDifferenceResponse = {'add': False},
                                           addMeasureIndicatorsAsPredictors={'add': False},
                                           addShiftsToPredictors={'add': False, 'nLags': 3},
                                           addResponsesAsPredictors={'add': False, 'nLags': 1},
                                           tapClassification={'add': False},
                                           smoothFuelCoal={'add': False},
                                           resampleTime='1min',
                                           resampleMethod='linear',
                                           addSteadyState=False,
                                           isOnline = True,
                                           smoothTagsOnChange = {'add': False},
                                           hoursOff = 1,
                                           nPeaksOff = 3,
                                           responseTags=None,
                                           cleanResponseTags=False,
                                           referenceTags=[],
                                           highFrequencyPredictorTags=[],
                                           lowFrequencyPredictorTags=[],
                                           writeToExcel=False):
        
        neededRows = 1 # how many rows do we need with no nans/issues at the end of the data set to effectively predict
        
        fullDF = self.fullDF
        mainTime = self.fullDF.index[-1]
        
        predictorTags = highFrequencyPredictorTags + lowFrequencyPredictorTags
        fullDF = fullDF[
            set(predictorTags + responseTags + referenceTags + highFrequencyPredictorTags + lowFrequencyPredictorTags)]
        self.outputLogger.log_trace('Full Dataset set, dataset size: {0}'.format(fullDF.shape))
        
        # Smooth Tags on Change - Smooths tags based on % change instead of absolte threshold
        if smoothTagsOnChange['add']:
            if 'on' in addMeasureIndicatorsAsPredictors.keys():
                fullDF = Data._smoothTagsOnChange(fullDF, smoothTagsOnChange['on'],
                                                  smoothTagsOnChange['threshold'])
                self.outputLogger.log_trace('Data smoothed on rates of change, dataset size: {0}'.format(fullDF.shape))
            else:
                raise Exception('Specify which tags to filter on change.')
        
        # Replace data outside operating range
        operatingRangeDict = Data._restrictData(fullDF.columns)
        for column in fullDF.columns:
            fullDF[column] = Data._filterExpectedDataRange(fullDF[column],
                                                     operatingRangeDict[column][0],
                                                     operatingRangeDict[column][1])
            if fullDF[column].isnull().any():
                fullDF[column] = fullDF[column].fillna(method='ffill')
                self.outputLogger.log_info('Out of bounds data forward filled for input: {0}'.format(column))
                if fullDF[column][-neededRows:].isnull().any():
                    raise Exception('Unable to preprocess, unable to sufficiently feed forward out of bound values on input: {0}'.format(column))
            
        self.outputLogger.log_trace('Data set within operating Range, dataset size: {0}'.format(fullDF.shape))

        predictorTagsNew = predictorTags.copy()
        
        # Add steady-state signal
        if addSteadyState:
            fullDF = Data._addSteadyStateSignal(fullDF, int(hoursOff), int(nPeaksOff),responseTags)  # mode8 inactive for >1 hour = offPeriod
            self.outputLogger.log_trace('Steady State Signal Added, dataset size: {0}'.format(fullDF.shape))
                
            # Remove transient data
            if removeTransientData:
                fullDF = Data._removeTransientData(fullDF)
                self.outputLogger.log_trace('Transient Data Removed, dataset size: {0}'.format(fullDF.shape))
                
        # Filter furnace modes
        if filterFurnaceModes['add']:
            fullDF = Data._filterMultipleFurnaceModes(fullDF, filterFurnaceModes['modes'])
            self.outputLogger.log_trace('Furnace Modes Filtered, dataset size: {0}'.format(fullDF.shape))    

        # Add indicator to indicate when last measurement was taken. The units are minutes
        if addMeasureIndicatorsAsPredictors['add']:
            if 'on' in addMeasureIndicatorsAsPredictors.keys():
                fullDF, measureIndicatorTags = \
                    Data._addMeasureIndicatorsAsPredictors(fullDF, predictorTags,
                                                         on=addMeasureIndicatorsAsPredictors['on'])
                for column in addMeasureIndicatorsAsPredictors['on']:
                    if fullDF[column][-neededRows:].isnull().any() and column != 'Basicity':
                        raise Exception('Unable to preprocess, unable to add measure indicators on input: {0}'.format(column))
                self.outputLogger.log_trace('Measure Key added as Predictor, dataset size: {0}'.format(fullDF.shape))
            else:
                fullDF, measureIndicatorTags = \
                    Data._addMeasureIndicatorsAsPredictors(fullDF, predictorTags)
                for column in predictorTags:
                    if fullDF[column][-neededRows:].isnull().any() and column != 'Basicity':
                        raise Exception('Unable to preprocess, unable to add measure indicators on input: {0}'.format(column))
                self.outputLogger.log_trace('Measure Key not added as Predictor, dataset size: {0}'.format(fullDF.shape))
            predictorTagsNew = predictorTagsNew + measureIndicatorTags
            self.outputLogger.log_trace('Measure Indicator added as Predictor, dataset size: {0}'.format(fullDF.shape))
            
        # Smooth Basicity according to last measurement and sum of species
        if smoothBasicityResponse:
            fullDF = Data._smoothBasicityResponse(fullDF)
            self.outputLogger.log_trace('Smooth Basicity Response Added, dataset size: {0}'.format(fullDF.shape))

        # Add rolling sum columns as additional predictors. The units of "window" is minutes.
        if addRollingSumPredictors['add']:
            if 'on' in addRollingSumPredictors.keys():
                # Adds a rolling sum on the specified predictors
                fullDF, predictorTagsSums = Data._addRollingSumPredictors(
                    fullDF, addRollingSumPredictors['on'], addRollingSumPredictors['window'])
                for column in addRollingSumPredictors['on']:
                    if fullDF[column][-neededRows:].isnull().any():
                        raise Exception('Unable to preprocess, unable to add rolling sum predictors on input: {0}'.format(column))
                self.outputLogger.log_trace('Added on Rolling Sum Predictor Key, dataset size: {0}'.format(fullDF.shape))
            else:
                # Adds a rolling sum on all predictors
                fullDF, predictorTagsSums = Data._addRollingSumPredictors(
                    fullDF, predictorTags, addRollingSumPredictors['window'])
                for column in predictorTags:
                    if fullDF[column][-neededRows:].isnull().any():
                        raise Exception('Unable to preprocess, unable to add rolling sum predictors on input: {0}'.format(column))
                self.outputLogger.log_trace('Rolling Sum Predictor added on all, dataset size: {0}'.format(fullDF.shape))
            predictorTagsNew = predictorTagsNew + predictorTagsSums

        # Add rolling mean columns as additional predictors. The units of "window" is minutes.
        if addRollingMeanPredictors['add']:
            if 'on' in addRollingMeanPredictors.keys():
                # Adds a rolling mean on the specified predictors
                fullDF, predictorTagsMeans = Data._addRollingMeanPredictors(
                    fullDF, addRollingMeanPredictors['on'], addRollingMeanPredictors['window'])
                for column in addRollingMeanPredictors['on']:
                    if fullDF[column][-neededRows:].isnull().any():
                        raise Exception('Unable to preprocess, unable to add rolling mean predictors on input: {0}'.format(column))
                self.outputLogger.log_trace('Rolling Mean Predictor Key added on, dataset size: {0}'.format(fullDF.shape))
            else:
                # Adds a rolling mean on all predictors
                fullDF, predictorTagsMeans = Data._addRollingMeanPredictors(
                    fullDF, predictorTags, addRollingMeanPredictors['window'])
                for column in predictorTags:
                    if fullDF[column][-neededRows:].isnull().any():
                        raise Exception('Unable to preprocess, unable to add rolling mean predictors on input: {0}'.format(column))
                self.outputLogger.log_trace('Rolling Mean Predictor Key not added on, dataset size: {0}'.format(fullDF.shape))
            predictorTagsNew = predictorTagsNew + predictorTagsMeans

        # Store original responses (no resampling)
        if responseTags:
            origSmoothedResponses, _ = Data._getUniqueDataPoints(fullDF[responseTags].dropna())
            self.outputLogger.log_trace('Original Smooth Response Found, dataset size: {0}'.format(fullDF.shape))
        else:
            origSmoothedResponses = []
            
        # Add rolling mean of response as an additional predictor
        if addRollingMeanResponse['add']:
            fullDF, responseMovingAverageTag = Data._addRollingMeanResponse(
                fullDF, origSmoothedResponses, responseTags, addRollingMeanResponse['window'])
            predictorTagsNew = predictorTagsNew + responseMovingAverageTag
            self.outputLogger.log_trace('Rolling Means of Response Added, dataset size: {0}'.format(fullDF.shape))
        
        # Resample to required Sample Time and with required Sample Method
        fullDF[highFrequencyPredictorTags] = fullDF[highFrequencyPredictorTags].resample(resampleTime, label='right', closed='right').last()
        self.outputLogger.log_trace('High Frequency Predictors Resampled, dataset size: {0}'.format(fullDF.shape))
            
        if lowFrequencyPredictorTags is not None:
            fullDF[lowFrequencyPredictorTags] = fullDF[lowFrequencyPredictorTags].resample(resampleTime, label='right', closed='right').last()
        fullDF[responseTags] = fullDF[responseTags].resample(resampleTime, label='right', closed='right').last()
        self.outputLogger.log_trace('Low Frequency Predictors Resampled, dataset size: {0}'.format(fullDF.shape))
            
        # Remaining tags get sampled on the spot
        remainingTags = fullDF.columns
        remainingTags = [tag for tag in remainingTags if tag not in \
                         highFrequencyPredictorTags + lowFrequencyPredictorTags + \
                         responseTags]
        fullDF[remainingTags] = fullDF[remainingTags].resample(resampleTime, label='right', closed='right').last()
        self.outputLogger.log_trace('Remaining Tags Resampled, dataset size: {0}'.format(fullDF.shape))
            
        # Eliminate repeated values from responses
        if cleanResponseTags:
            responses, _ = Data._getUniqueDataPoints(fullDF[responseTags].dropna())
            fullDF[responseTags] = responses
            if not fullDF.index[-1] ==mainTime:
                raise Exception('Unable to preprocess, not enough unique responses on Basicity')
            self.outputLogger.log_trace('Repeated Values Removed, dataset size: {0}'.format(fullDF.shape))
            
        # Add Lagged response as predictor
        if addResponsesAsPredictors['add']:
            fullDF, predictorTagsLaggedResponse = \
                Data._addLagsAsPredictors(fullDF, responseTags, addResponsesAsPredictors['nLags'])
            predictorTagsNew = predictorTagsNew + predictorTagsLaggedResponse
            for column in predictorTagsNew:
                if fullDF[column][-neededRows:].isnull().any():
                    raise Exception('Unable to preprocess, unable to add lagged responses as predictors on input: {0}'.format(column))
            self.outputLogger.log_trace('Lagged Responses Added, dataset size: {0}'.format(fullDF.shape))
                
        # Add differenced response as predictor
        if addDifferenceResponse['add']:
            fullDF, predictorTagsDifferencedResponse = \
                Data._addDifferenceAsPredictors(fullDF, responseTags)
            predictorTagsNew = predictorTagsNew + predictorTagsDifferencedResponse
            for column in predictorTagsNew:
                if fullDF[column][-neededRows:].isnull().any():
                    raise Exception('Unable to preprocess, unable to add difference responses as predictors on input: {0}'.format(column))
            self.outputLogger.log_trace('Differenced Responses added, dataset size: {0}'.format(fullDF.shape))

        # Interpolate response for regression purposes
        fullDF[responseTags] = fullDF[responseTags].resample(resampleTime).interpolate(resampleMethod)
        fullDF[responseTags] = fullDF[responseTags].fillna(method = 'ffill')
        self.outputLogger.log_trace('Responses Interpolated, dataset size: {0}'.format(fullDF.shape))
            
        # Add lags of predictor columns as additional predictors
        if addShiftsToPredictors['add']:
            if 'on' in addShiftsToPredictors.keys():
                fullDF, predictorTagsShifted = Data._addLagsAsPredictors(fullDF, addShiftsToPredictors['on'],
                                                                       addShiftsToPredictors['nLags'])
            else:
                fullDF, predictorTagsShifted = Data._addLagsAsPredictors(fullDF, predictorTags,
                                                                       addShiftsToPredictors['nLags'])
            predictorTagsNew = predictorTagsNew + predictorTagsShifted
            for column in predictorTagsShifted:
                if fullDF[column][-neededRows:].isnull().any():
                    raise Exception('Unable to preprocess, unable to add shifts predictors on input: {0}'.format(column))
            self.outputLogger.log_trace('Lag Added to Predictors, dataset size: {0}'.format(fullDF.shape))
        
        # Add tapping indication signals
        if tapClassification['add']:
            fullDF = Data._tappingClassification(fullDF, "Phase A Matte tap block 1 DT_water", 5, 0.2)
            fullDF = Data._tappingClassification(fullDF, "Phase A Matte tap block  DT_water", 5, 0.2)
            fullDF = Data._tappingClassification(fullDF, "Phase A Slag tap block DT_water", 5, 0.05)
        
        # Smooth Fuel Coal Feed Rate
        if smoothFuelCoal['add']:
            smoothedFuelCoal = Data._smoothFuelCoal(fullDF["Fuel coal feed rate PV"])
            fullDF["Fuel coal feed rate PV"] = smoothedFuelCoal
			
        if not os.path.exists('D:\output.pickle'):
            pickle.dump([fullDF], open('D:\output.pickle', 'wb'))
        
        if writeToExcel:
            fileName = 'processedAndEngineeredData.xlsx'
            thisFile = sys.argv[0]
            filePath = os.path.join(pathlib.Path(os.path.dirname(thisFile)).parent, 'data', fileName)
            fullDF.to_excel(filePath)
        
        # Check for all NaN columns and blame them
        for col in fullDF.columns:
            if fullDF[col].isnull().all():
                raise Exception('All NaNs in column {0}'.format(col))
                    
        fullDF = fullDF.dropna()
        
        if not fullDF.index[-1] ==mainTime:
            raise Exception('Main calculation time has been filtered out of the process, cannot calculate')
        
        return fullDF, origSmoothedResponses, predictorTagsNew
