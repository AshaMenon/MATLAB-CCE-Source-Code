# -*- coding: utf-8 -*-
"""
Created on Thu Sep 29 10:17:33 2022

@author: john.atherfold
"""

# Universal packages
import Shared.DSModel.src.preprocessingFunctions as prep
from CCEScripts.TrainXGEBoostBasicity import TrainXGEBoostBasicity
from CCEScripts.EvaluateXGEBoostBasicity import EvaluateXGEBoostBasicity
from Shared.DSModel.Config import Config
import pandas as pd
import matplotlib.pyplot as plt

#%% Setup (to come from the config file)
origInputs = prep.readAndFormatData('Chemistry2023')
livePredictions = pd.DataFrame(columns = ['Timestamp', 'ProcessSteadyState',
                                          'BlowCount', 'XGBoostPredictedBasicity',
                                          'RequiredChangeInSpSi', 'DiffInSpSi',
                                          'XGBoostLowerPredictedBasicity',
                                          'XGBoostUpperPredictedBasicity',
                                          'BasicityDelta'])

configFile = "../config/basicity/xgbModelConfigFile.yaml"

configModel = Config(configFile)

parameters = configModel.getParameters("Evaluate")
parameters.update(configModel.getParameters("Logging"))
parameters.update(configModel.getParameters("preprocessingAndFeatureEngineering"))
parameters['RequiredChangeInSpSiParam'] = float('nan')
parameters['BasicityDeltaParam'] = float('nan')

parameters['CumulativeSpSiParam'] = float('nan')
parameters['SpSiSetpointParam'] = float('nan')
parameters['SpSiCountParam'] = 0

runRange = 1440
# origInputs =  origInputs.iloc[len(origInputs)-(runRange+1):].copy() # run once
# origInputs =  origInputs.iloc[len(origInputs)-(runRange+100):].copy() # run trend
for endPoint in range(runRange,len(origInputs)):
    inputs = origInputs.iloc[endPoint-runRange:endPoint].copy()
    
    #Evaluate Model
    # parameters["ModelPath"] = trainOut["ModelPath"]
    [evalOut, evalErrCode] = EvaluateXGEBoostBasicity(parameters, inputs)
    
    evalOut['Timestamp'] = [inputs.index[-1]]
    evalDF = pd.DataFrame(evalOut)
    livePredictions = pd.concat((livePredictions, evalDF))
    
    parameters['RequiredChangeInSpSiParam'] = evalOut['RequiredChangeInSpSi']
    parameters['BasicityDeltaParam'] = evalOut['BasicityDelta'][-1]
    
    parameters['CumulativeSpSiParam'] = evalOut['CumulativeSpSi'][-1]
    parameters['SpSiSetpointParam'] = evalOut['SpSiSetpoint'][-1]
    parameters['SpSiCountParam'] = evalOut['SpSiCount'][-1]

#%% Formatting

livePredictions = livePredictions.set_index('Timestamp')
livePredictions.index = pd.to_datetime(livePredictions.index)

#%% Plotting

origInputs['Basicity'].plot(color = 'r', marker = '.')
livePredictions['XGBoostPredictedBasicity'].plot(color = 'b', marker = '*')
origInputs[['Matte temperatures', 'Converter mode',
            'Lance air and oxygen control', 'Specific Oxygen Actual PV']].plot(subplots = True)

livePredictions[['RequiredChangeInSpSi', 'DiffInSpSi']].plot(subplots = True)
livePredictions['BasicityDelta'].plot()
