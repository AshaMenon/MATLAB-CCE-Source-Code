# -*- coding: utf-8 -*-
"""
Created on Thu Oct 26 16:20:10 2023

@author: antonio.peters
"""

import json
import pandas as pd
from seeq import spy
import datetime

def loadConfig(configFilePath):
    
    # Load in config
    with open(configFilePath, 'r') as file:
        allConfig = json.load(file)

    displayDataFrame = pd.DataFrame(columns=['Name', 'Tag List'])

    displayDataFrame['Name'] = [item['Label'] for item in allConfig]
    displayDataFrame = displayDataFrame.set_index('Name')

    keysToInclude = ['Name', 'Path']
    seeqTagsList = [{key: item[key] for key in keysToInclude if key in item} for item in allConfig]
    displayDataFrame['Tag List'] = [item for item in seeqTagsList if item]
    
    return displayDataFrame

def loadParameters(paramFilePath):
    
    with open(paramFilePath, 'r') as file:
        parameters = json.load(file)
        
        return parameters

def getDataLink(configDF):
    search = spy.search(query = pd.DataFrame(configDF['Tag List']),
                        order_by = 'Name')
        
    return search

def setupTimes(paramStruct, outputSignal):
    
    #Initial backfill range in days 
    initialBackfill = paramStruct['BackfillDay']
    
    #Pull range in hours 
    pullRange = paramStruct['PullRangeHours']
    
    pullStart = datetime.datetime.utcnow() - datetime.timedelta(hours = pullRange) # Date must be set relatively
    pullStart = pullStart.strftime('%m/%d/%Y %H:%M:%S')+"Z"
    pullEnd = datetime.datetime.utcnow()
    pullEnd = pullEnd.strftime('%m/%d/%Y %H:%M:%S')+"Z"
    
    ## Check if there is data in the pipeline already
    
    if len(outputSignal)<1: # If there is no data in the output, start from the backfill time
        pullStart = datetime.datetime.utcnow() - datetime.timedelta(days = initialBackfill)
        pullStart = pullStart.strftime('%m/%d/%Y %H:%M:%S')+"Z"
    else: # Otherwise only pull the shorter timespan that needs updating
        existingData = spy.pull(outputSignal,start=pullStart,end=pullEnd,grid=None)
        lastExistingTimestamp = existingData.index.max()
        pullStart = lastExistingTimestamp
        
    paramStruct['PullStart'] = pullStart
    paramStruct['PullEnd'] = pullEnd
    return paramStruct
    
def getData(configDF, paramStruct):
    rawDF = spy.pull(items = configDF['Tag List'], start=paramStruct['PullStart'],
                           end=paramStruct['PullEnd'], grid=paramStruct['Grid'])
    
    return rawDF

def returnOutput(output, inputDF, paramStruct):
    myCalculation = inputDF # to give it the regular data structure
    myCalculation[output['Name']] = output # super basic as an example
    myCalculation = myCalculation.drop(myCalculation.columns[0:len(inputDF['Name'])-1], axis=1) # drop the input data from our intended output
    
    ## Push the resulting data 
    spy.push(myCalculation)
    
    ## Check the output has been updated
    outputSignal = spy.search(
        {'Name': output['Name']})
    outputSignal
    
    return 0