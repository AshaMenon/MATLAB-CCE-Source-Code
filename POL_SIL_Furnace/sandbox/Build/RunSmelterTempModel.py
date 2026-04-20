# -*- coding: utf-8 -*-
"""
Created on Thu Oct 25 11:35:45 2023

@author: antonio.peters
"""

## Initialise

from seeq import spy
import SeeqHelpers as sh
from EvaluateXGBoostSlagTemp import evaluate_XGBoost_slag_temp_model

## Load data config and parameters
configFile = 'SmelterTempModelConfig.json'
paramFile = 'STMParameters.json'
configDF = sh.loadConfig(configFile)
paramStruct = sh.loadParameters(paramFile)

## Get input signals
inSearch = sh.getDataLink(configDF)

## Setup Output Signals
outputSignalName = 'TestSTMOut'

outputSignal = spy.search(
    {'Name': outputSignalName})

## Setup Time Span
paramStruct = sh.setupTimes(paramStruct, outputSignal)

## Pull the necessary data

inputDF = sh.getData(configDF, paramStruct)

output = evaluate_XGBoost_slag_temp_model(parameters, inputs)

returnCode = sh.returnOutput(output, inputDF, paramStruct)

## set up the next run
updateFrequency = paramStruct['UpdateInterval']
spy.jobs.schedule(updateFrequency)