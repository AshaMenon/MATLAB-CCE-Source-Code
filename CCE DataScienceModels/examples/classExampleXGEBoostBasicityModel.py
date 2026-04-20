# -*- coding: utf-8 -*-
"""
Created on Thu Apr 21 10:46:31 2022

@author: antonio.peters
"""
# Universal packages
import Shared.DSModel.src.preprocessingFunctions as prep
from CCEScripts.TrainXGEBoostBasicity import TrainXGEBoostBasicity
from CCEScripts.EvaluateXGEBoostBasicity import EvaluateXGEBoostBasicity
from Shared.DSModel.Config import Config

#%% Setup (to come from the config file)
inputs = prep.readAndFormatData('Chemistry')
inputs = inputs.iloc[-720:]

configFile = "../config/basicity/xgbModelConfigFile.yaml"

configModel = Config(configFile)

#%% Model excution stuff
# parameters = configModel.getParameters("Training")
# parameters.update(configModel.getParameters("preprocessingAndFeatureEngineering"))

# [trainOut, trainErrCode] = TrainXGEBoostBasicity(parameters, inputs)

#Evaluate Model
# parameters["ModelPath"] = trainOut["ModelPath"]
parameters = configModel.getParameters("Evaluate")
parameters.update(configModel.getParameters("Logging"))
parameters.update(configModel.getParameters("preprocessingAndFeatureEngineering"))
[evalOut, evalErrCode] = EvaluateXGEBoostBasicity(parameters, inputs)
