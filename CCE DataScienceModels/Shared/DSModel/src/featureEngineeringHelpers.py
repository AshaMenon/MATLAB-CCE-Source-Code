import numpy as np
import datetime as dt
import pandas as pd
import scipy.signal as sp

def smoothTagsOnChange(fullDF, smoothedTags, percentageAllowed):
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

def removeTransientData(fullDF):
    # Remove transient data
    fullDF = fullDF[fullDF['Steadystate']]
    return fullDF

def addRollingSumPredictors(fullDF, predictorTags, window):
    # Add rolling sum columns on all variables
    predictorTagsSums = [x +' ' + str(window) + '-rollingsum' for x in predictorTags]
    zeroCentredData = fullDF[predictorTags] - fullDF[predictorTags].rolling(window).median()
    fullDF[predictorTagsSums] = zeroCentredData.rolling(window).sum()
    return fullDF, predictorTagsSums

def addRollingMeanPredictors(fullDF, predictorTags, window):
    # Add rolling mean columns on all predictor variables
    predictorTagsMeans = [x + ' ' + str(window) + '-rollingmean' for x in predictorTags]
    fullDF[predictorTagsMeans] = fullDF[predictorTags].rolling(window).mean()
    return fullDF, predictorTagsMeans

def addRollingMeanResponse(fullDF, responseSeries, responseTags, window):
    # Add rolling mean columns on response variables
    responseMovingAverageTag = [x + ' ' + str(window) + '-rollingmean' for x in responseTags]
    fullDF[responseMovingAverageTag] = responseSeries.rolling(window).mean()
    fullDF[responseMovingAverageTag] = fullDF[responseMovingAverageTag].fillna(method = 'ffill')
    return fullDF, responseMovingAverageTag

def smoothBasicityResponse(fullDF):
    responses, irregularIdx = getUniqueDataPoints(fullDF['Basicity'])
    responses = responses.fillna(method = 'ffill')
    fullDF['Basicity'] = smoothBasicity(responses, fullDF['SumOfSpecies'][irregularIdx])
    return fullDF


def addLagsAsPredictors(fullDF, inputTags, totalLags, resampleTime):
    dfCopy = fullDF.copy()
    laggedDataframe = pd.DataFrame(index = dfCopy.index)
    for column in inputTags:
        dfCopy[column], _ = getUniqueDataPoints(dfCopy[column])
        actualMeasurements = dfCopy[column].dropna()
        actualMeasurements = pd.concat((actualMeasurements, pd.Series(data = 0, index = dfCopy.index[-1:])))
        actualMeasurements = actualMeasurements[~actualMeasurements.index.duplicated(keep = 'first')]
        for nLag in np.arange(1, totalLags+1):
            laggedResponse = actualMeasurements.shift(periods = nLag)
            laggedResponse = laggedResponse.resample(resampleTime).asfreq()
            dropRange = laggedResponse.index[laggedResponse.index <= actualMeasurements.index[nLag-1]]
            laggedResponse = laggedResponse.drop(dropRange).fillna(method = 'bfill')
            laggedDataframe = pd.concat([laggedDataframe, laggedResponse], axis = 1)
    newPredictorNames = [str(nLag) + '-Lag ' + tag for tag in inputTags for nLag in np.arange(1, totalLags + 1)]
    laggedDataframe.columns = newPredictorNames
    fullDF[laggedDataframe.columns] = laggedDataframe
    return fullDF, newPredictorNames


def addMeasureIndicatorsAsPredictors(fullDF, predictorTags, on=None):

    predictorsIrregularIdx = {}
    measureIndicatorKeys = []

    if on is not None:
        for tag in on:
            _, predictorIrregularIdx = getUniqueDataPoints(fullDF[tag])
            measureIndicatorKeys.append(f'{tag} Measure Indicator')
            predictorsIrregularIdx[measureIndicatorKeys[-1]] = predictorIrregularIdx
    else:
        for tag in predictorTags:
            _, predictorIrregularIdx = getUniqueDataPoints(fullDF[tag])
            if len(predictorIrregularIdx ) /len(fullDF) < 0.05 and tag.find('rollingsum') == -1:
                measureIndicatorKeys.append(f'{tag} Measure Indicator')
                predictorsIrregularIdx[measureIndicatorKeys[-1]] = predictorIrregularIdx

    fullDF[measureIndicatorKeys] = np.ones([len(fullDF), len(measureIndicatorKeys)])

    for key in measureIndicatorKeys:
        irregularIdx = predictorsIrregularIdx[key]
        fullDF[key] = fullDF[key].groupby(
            irregularIdx.searchsorted(fullDF.index)).cumsum()
        fullDF[key].loc[irregularIdx] = 0

    return fullDF, measureIndicatorKeys


def addShiftsToPredictors(fullDF, predictorTags, numberOfShifts):
    predictorTagsShifted = []
    for shift in range(numberOfShifts):
        currentShift = [x + f' {shift+1}-shifted' for x in predictorTags]
        for nTag in range(len(currentShift)):
            fullDF[currentShift[nTag]] = \
                fullDF[predictorTags[nTag]].dropna().shift(periods=(shift+1))
        predictorTagsShifted += currentShift

    return fullDF, predictorTagsShifted


def getUniqueDataPoints(dataSeries):
    valueChangeIdx = np.append(True, np.diff(dataSeries.values.ravel()) != 0)
    irregularIdx = dataSeries.index[valueChangeIdx]
    uniqueDataSeries = dataSeries.iloc[valueChangeIdx]

    return uniqueDataSeries, irregularIdx


def getSumOfSpecies(fullDF):
    fullDF["SumOfSpecies"] = (1.13 * fullDF['Cu Slag'] + 1.27 * fullDF['Ni Slag'] +
                              1.27 * fullDF['Co Slag'] + 1.29 * fullDF['Fe Slag'] +
                              1.04 - 0.5 * fullDF['S Slag'] + fullDF['SiO2 Slag'] +
                              fullDF['Al2O3 Slag'] + fullDF['CaO Slag'] +
                              fullDF['MgO Slag'] + fullDF['Cr2O3 Slag'])
    fullDF["SumOfSpecies"][fullDF["SumOfSpecies"] > 110] = 0  # Discuss this?
    # fullDF["SumOfSpecies"] = fullDF["SumOfSpecies"].ffill()

    return fullDF


def smoothBasicity(responses, speciesWeight):
    timeWeight = np.insert(np.exp(-0.05 * np.diff(responses.index).astype(float)[:, np.newaxis] / 1e9 / 60), 0, 0)
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

def addSteadyStateSignal(fullDF, offPeriod, nPeaksOff, responseTags):

    # Filter for mode 8
    filteredDF = fullDF.loc[(fullDF["Converter mode"] == 8)]

    # Find peaks in blows
    n = 5
    filteredDF['Peaks'] = filteredDF.iloc[sp.argrelextrema(filteredDF['Lance air and oxygen control'].values,
                                                   np.greater_equal, order=n)[0]]['Lance air and oxygen control'] > 0
    filteredDF['Peaks'] = filteredDF['Peaks'].fillna(False)
    filteredDF.Peaks[(filteredDF.Peaks != False)] = True

    # Define number of hours process needs to operate out of mode 8
    offTimeAllowed = dt.timedelta(hours=offPeriod)

    # Find diff difference between Timestamps
    timeDiff = filteredDF.index.to_series().diff()
    # Set the first timeDiff to a high value (conservative)
    timeDiff[0] = dt.timedelta(hours=9999)
    # Find where the process is off (i.e. not mode 8)
    processOff = timeDiff >= offTimeAllowed
    processOffIdx = np.where(processOff)

    # Find the peak that follow processOff data points
    nextPeakIdx = [np.where(filteredDF['Peaks'][x:])[0][nPeaksOff - 1] + x for x in processOffIdx[0]]
    
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
    origSmoothedResponses, _ = getUniqueDataPoints(fullDF[responseTags].dropna())
    
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

def reassignTimestamps(blowTimes, measuredChanges):
    # blowLength = len(blowTimes)
    # blowNum = 0;
    alignedTimes = []
    alignedValues = []
    for nMeasurement in range(len(measuredChanges)):
        latestMeasurement = measuredChanges[nMeasurement]
        latestMeasurementTime = measuredChanges.index[nMeasurement]
        # lastBlowTime = blowTimes[blowNum]
        # nextBlowTime = blowTimes[blowNum + 1]
        
        timeDiffs = latestMeasurementTime - blowTimes
        positiveTimeDiffs = timeDiffs > pd.Timedelta('0 min')
        positiveIdx = np.where(positiveTimeDiffs)[0]
        timeDiffs = timeDiffs[positiveIdx]
        if not timeDiffs.empty:
            newMeasurementIdx = positiveIdx[np.argmin(timeDiffs)]
            alignedTimes.append(blowTimes[newMeasurementIdx])
            alignedValues.append(latestMeasurement)
        
        # if (blowNum < blowLength - 1) and (lastBlowTime < latestMeasurementTime <= nextBlowTime):
        #     alignedTimes.append(blowTimes[blowNum])
        #     blowNum = blowNum + 1
        #     alignedValues.append(measuredChanges[nMeasurement])
        # elif (blowNum < blowLength):
        #     blowNumOrig = blowNum
        #     blowNum = blowNum + 1
        #     blowFlag = 0
        #     # Loop through blow times to check if matte temperature is missing
        #     for nBlow in range(blowNum, blowLength - 1):
        #         if (blowTimes[nBlow] < latestMeasurementTime <= blowTimes[nBlow + 1]):
        #             alignedTimes.append(blowTimes[nBlow])
        #             alignedValues.append(latestMeasurement)
        #             blowNum = nBlow + 1
        #             blowFlag = 1
        #             break
        #         elif nBlow == blowLength - 2:
        #             alignedTimes.append(pd.NaT)
        #             blowNum = blowNumOrig
        #             alignedValues.append(measuredChanges[nMeasurement])
        #     if not blowFlag:
        #         # Check if there are multiple temperatures
        #         if (blowTimes[blowNumOrig - 1] < measuredChanges.index[nMeasurement] <= blowTimes[blowNumOrig]):
        #             t1 = measuredChanges[nMeasurement - 1]
        #             t2 = measuredChanges[nMeasurement]
        #             flagT1 = 1230 < t1 < 1270
        #             flagT2 = 1230 < t2 < 1270
        #             if (flagT2 and not flagT1) or (flagT2 and flagT1):
        #                 alignedValues[-1] = measuredChanges[nMeasurement]
        #             elif not flagT2 and not flagT1:
        #                 diff1T1 = 1230 - t1
        #                 diff2T1 = 1270 - t1
        #                 diffT1 = min(abs(diff1T1), abs(diff2T1))
        #                 diff1T2 = 1230 - t2
        #                 diff2T2 = 1270 - t2
        #                 diffT2 = min(abs(diff1T2), abs(diff2T2))
        #                 diffList = [diffT1, diffT2]
        #                 minId = diffList.index(min(diffList))
        #                 if minId == 1:
        #                     alignedValues[-1] = measuredChanges[nMeasurement]
        # else:
        #     alignedTimes.append(pd.NaT)
    return alignedTimes, alignedValues

def addDifferenceAsPredictors(fullDF, tagList):
    predictorTagsDifferenced = []
    for tag in tagList:
        origUniqueData, _ = getUniqueDataPoints(fullDF[tag].dropna())
        diffTag = tag + ' differenced'
        fullDF[diffTag] = origUniqueData.diff()
        fullDF[diffTag] = fullDF[diffTag].fillna(method = 'ffill')
        predictorTagsDifferenced += [diffTag]
    return fullDF, predictorTagsDifferenced

# This is a function to convert MATLAB datetimes to Python datetimes
def matlab_to_datetime(matlab_datenum):
    """Convert matlab time to python time."""
    if matlab_datenum is None or np.isnan(matlab_datenum):
        return np.nan
    python_datetime = dt.datetime.fromordinal(int(matlab_datenum)) \
        + dt.timedelta(days=matlab_datenum % 1) - dt.timedelta(days=366)
    return python_datetime

def datenum(d):
    return float(366 + d.toordinal() + (d - dt.datetime.fromordinal(d.toordinal())).total_seconds()/(24*60*60))

def formatMatlabData(fullDF, log):
    fullDF = fullDF.drop_duplicates()
    fullDF.set_index('Timestamp', drop=True, inplace=True)
    fullDF.index = pd.to_datetime(fullDF.index).round('min')
    fullDF = fullDF[~fullDF.index.duplicated(keep='first')]
    log.log_trace('Dropped Duplicate Indexes')
    
    # Replace known bad and missing values
    fullDF = fullDF.replace("Bad",np.nan)
    fullDF = fullDF.replace("No Data",np.nan)
    fullDF = fullDF.replace("Tag not found",np.nan)
    fullDF = fullDF.replace("Not Connect",np.nan)
    fullDF = fullDF.replace("Resize to show all values",np.nan)
    fullDF = fullDF.apply(pd.to_numeric)
    log.log_trace('Replaced Bad and Missing Values')
    
    return fullDF

def resampleFeMatte(blowTimes, alignedMeasurements):
    # Resamples Fe Matte that's been aligned with the end of the blows
    # according to some rules
    resampledFeMatte = pd.Series(index = blowTimes, dtype = 'float64')
    for timeIdx in blowTimes:
        if timeIdx in alignedMeasurements.index:
            timestampData = alignedMeasurements[timeIdx].copy()
            if np.size(timestampData) > 1:
                isMoreThan8 = timestampData > 8
                isLessThan1 = timestampData < 1
                outOfRangeIdx = np.logical_or(isMoreThan8, isLessThan1)
                if sum(isMoreThan8) == len(isMoreThan8):
                    resampledFeMatte[timeIdx] = np.min(timestampData)
                elif sum(outOfRangeIdx) > 0:
                    timestampData[outOfRangeIdx] = np.nan
                resampledFeMatte[timeIdx] = np.nanmean(timestampData)
            else:
                resampledFeMatte[timeIdx] = timestampData
    return resampledFeMatte


