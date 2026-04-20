# -*- coding: utf-8 -*-
"""
Created on Thu Oct 13 10:28:39 2022

@author: antonio.peters
"""

# Universal packages
import Shared.DSModel.src.preprocessingFunctions as prep
from CCEScripts.EvaluateSPO2 import EvaluateSPO2
from Shared.DSModel.Config import Config
import pandas as pd
import matplotlib.pyplot as plt
from Shared.DSModel.src import featureEngineeringHelpers as feh
#%% Setup (to come from the config file)
origInputs = prep.readAndFormatData('Chemistry')
livePredictions = pd.DataFrame(columns = ['Timestamp',
                                          'SpO2Change',
                                          'CalcCorrNiSlag',
                                          'CalcNiTarget'])

runRange = 100
# origInputs =  origInputs.iloc[len(origInputs)-(runRange+1):].copy() # run once
origInputs =  origInputs.iloc[len(origInputs)-(runRange+1000):].copy() # run trend
for endPoint in range(runRange,len(origInputs)):
    inputs = origInputs.iloc[endPoint-runRange:endPoint].copy()

    configFile = "../config/basicity/SPO2ConfigFile.yaml"

    configModel = Config(configFile)
    
    #Evaluate Model
    parameters = configModel.getParameters("Evaluate")
    parameters.update(configModel.getParameters("Logging"))
    parameters.update(configModel.getParameters("preprocessingAndFeatureEngineering"))
    [evalOut, evalErrCode] = EvaluateSPO2(parameters, inputs)
    
    evalDF = pd.DataFrame(evalOut)
    livePredictions = pd.concat((livePredictions, evalDF))

#%% Formatting

livePredictions['Timestamp'] = [feh.matlab_to_datetime(t) for t in livePredictions['Timestamp']] 
livePredictions = livePredictions.set_index('Timestamp')

#%% Plotting

origInputs['Ni Slag'].plot(color = 'r', marker = '.')
livePredictions['SpO2Change'].plot(color = 'b', marker = '*')
