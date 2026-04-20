# -*- coding: utf-8 -*-
"""
Created on Wed Oct 18 14:46:47 2023

@author: john.atherfold
"""

import numpy as np
import pandas as pd
import datetime as dt
from Code import Preprocessing as prep
from Code import SeeqFormatting as sf

def loadConfig(configFilePath):
    allConfig = sf.readConfig(configFilePath)
    keysToInclude = ['Name', 'Path', 'ID', 'Datasource Name']
    kilkenSeeqQuery = [{key: item[key] for key in keysToInclude if key in item} for item in allConfig]
    kilkenSeeqQuery = [item for item in kilkenSeeqQuery if item]
    
    # Format for Column Mapping
    keysToInclude = ['Name', 'Path', 'ID', 'Label', 'Datasource Name']
    seeqTagsWithLabels = [{key: item[key] for key in keysToInclude if key in item} for item in allConfig]
    seeqTagsWithLabels = [item for item in seeqTagsWithLabels if 'Path' in item or 'Datasource Name' in item]
    
    return kilkenSeeqQuery, seeqTagsWithLabels

def preprocessData(fullDF, seeqTagsWithLabels):
    keysToJoin = ['Path', 'Name']
    pathToTag = []
    tagLabelsWithPaths = []
    # Set up full tag paths and corresponding labels
    for thisDict in seeqTagsWithLabels:
        if 'Path' in thisDict:
            path = ' >> '.join([thisDict[key] for key in keysToJoin])
        elif 'Datasource Name' in thisDict:
            path = thisDict['Name']
        pathToTag.append(path)
        tagLabelsWithPaths.append(thisDict['Label'])

    columnMap = dict(zip(pathToTag, tagLabelsWithPaths))

    fullDF = fullDF.rename(columns = columnMap)
    return fullDF

def filterLinearOutliers(fullDF, feature):
    processedFeature = fullDF[feature].copy()
    processedFeature = prep.removeLinearOutliers(processedFeature, [0, 6000])
    
    fullDF[feature] = np.nan
    fullDF[feature] = processedFeature
    fullDF[feature] = fullDF[feature].ffill()
    return fullDF

def getDataFrames(fullDF):
    hourlyWeights = fullDF[['U1ScaleCombined', 'U2ScaleCoarse', 'U2ScaleFine']].diff()
    dailyTonnesMilled = hourlyWeights.groupby(pd.Grouper(freq='D')).agg('sum')

    dispatchedColumns = [col for col in fullDF.columns if "Dispatched" in col]
    dailyTonnesDispatched = pd.DataFrame(index=dailyTonnesMilled.index,
                                         columns = dispatchedColumns)

    for feature in dispatchedColumns:
        fullDF.loc[fullDF[feature] > 1000][feature] = np.nan
        fullDF.loc[fullDF[feature] < 0][feature] = np.nan
        fullDF = fullDF.fillna(0)
        truckTonnes = fullDF[feature].drop_duplicates().groupby(pd.Grouper(freq='D')).agg('sum')
        dailyTonnesDispatched[feature] = truckTonnes
    
    tailsFeatures = ['U1TailsGrade', 'U2TailsGrade']
    for feature in tailsFeatures:
        validIdx = fullDF[feature] < 2.5
        fullDF[feature] = fullDF.loc[validIdx, feature]

    tonnesToKilken = dailyTonnesMilled.sum(axis = 1) - dailyTonnesDispatched.sum(axis = 1)
    #TODO: Check this date range - is this still relevant?
    tonnesToKilkenMTD = pd.concat([tonnesToKilken, pd.Series(data=0.0, index=pd.date_range('2023-10-17', '2023-10-31'))])
    monthlyTonnesToKilken = tonnesToKilkenMTD.groupby(pd.Grouper(freq='M', closed='right',
                                                                 label='right')).sum()

    kilkenHeadGrades = fullDF[['U1TailsGrade', 'U2TailsGrade']].resample('D').apply(lambda x: prep.mode_with_nan(x))
    kilkenConcMass = fullDF['KilkenConcMass'].resample('D').apply(lambda x: prep.mode_with_nan(x))

    dailyKilkenDF = pd.DataFrame(columns=['DryTonnesToKilken', 'KilkenHeadGrade',
                                          'KilkenConcMass', 
                                          'KilkenDailyRecovery'], index = tonnesToKilken.index)
    dailyKilkenDF['DryTonnesToKilken'] = tonnesToKilken
    dailyKilkenDF.loc[dailyKilkenDF['DryTonnesToKilken'] < 2000, 'DryTonnesToKilken'] = 0.0

    dailyKilkenDF['KilkenHeadGrade'] = (kilkenHeadGrades['U1TailsGrade']*dailyTonnesMilled['U1ScaleCombined'] +
                                          kilkenHeadGrades['U2TailsGrade']*(dailyTonnesMilled['U2ScaleCoarse'] +
                                                                    dailyTonnesMilled['U2ScaleFine']))/(dailyTonnesMilled.sum(axis=1))
    dailyKilkenDF['KilkenConcMass'] = kilkenConcMass
    dailyKilkenDF['KilkenDailyRecovery'] = 29*dailyKilkenDF['KilkenConcMass']/(dailyKilkenDF['KilkenHeadGrade']*dailyKilkenDF['DryTonnesToKilken'])*100 # Assumed Conc Grade is 29g/tonne

    dailyKilkenDF.loc[dailyKilkenDF['KilkenDailyRecovery'] > 20, 'KilkenDailyRecovery'] = np.nan

    dailyKilkenDF['TonnesxGrade'] = dailyKilkenDF['DryTonnesToKilken']*dailyKilkenDF['KilkenHeadGrade']*30 # Convert to Monthly
    dfDict = {
        'fullDF':fullDF,
        'dailyDF':dailyKilkenDF,
        'monthlyDF': monthlyTonnesToKilken,
        'tonnesToKilken': tonnesToKilken}
    return dfDict

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