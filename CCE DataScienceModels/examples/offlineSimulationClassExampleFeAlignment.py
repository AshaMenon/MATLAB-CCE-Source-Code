# -*- coding: utf-8 -*-
"""
Created on Wed Apr 12 15:56:37 2023

@author: john.atherfold
"""

# Universal packages
import Shared.DSModel.src.preprocessingFunctions as prep
from CCEScripts.TrainXGEBoostBasicity import TrainXGEBoostBasicity
from CCEScripts.EvaluateAlignedFeMatte import EvaluateAlignedFeMatte
from Shared.DSModel.Config import Config
import pandas as pd
import matplotlib.pyplot as plt

#%% Setup (to come from the config file)
origInputs = prep.readAndFormatData('Chemistry2022')
livePredictions = pd.DataFrame(columns = ['Timestamp', 'AlignedFeMatte'])

configFile = "../config/basicity/feAlignmentConfigFile.yaml"

configModel = Config(configFile)

parameters = configModel.getParameters("Logging")
parameters.update(configModel.getParameters("preprocessingAndFeatureEngineering"))

##%% Simulation Loop

runRange = 180

for endPoint in range(runRange,len(origInputs)):
    inputs = origInputs.iloc[endPoint-runRange:endPoint].copy()
    
    #Evaluate Model
    [evalOut, evalErrCode] = EvaluateAlignedFeMatte(parameters, inputs)
    
    # evalOut['Timestamp'] = [inputs.index[-1]]
    evalDF = pd.DataFrame(evalOut)
    livePredictions = pd.concat((livePredictions, evalDF))
    

#%% Formatting

livePredictions = livePredictions.set_index('Timestamp')
livePredictions.index = pd.to_datetime(livePredictions.index)

#%% Plotting

ax = origInputs['Fe Matte'].plot(color = 'r', marker = '.')
livePredictions['AlignedFeMatte'].plot(color = 'b', marker = '*', ax = ax)
origInputs[['Matte temperatures', 'Converter mode',
            'Lance air and oxygen control', 'Specific Oxygen Actual PV']].plot(subplots = True)

livePredictions[['RequiredChangeInSpSi', 'DiffInSpSi']].plot(subplots = True)
livePredictions['BasicityDelta'].plot()
