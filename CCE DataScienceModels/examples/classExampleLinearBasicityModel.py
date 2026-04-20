# -*- coding: utf-8 -*-
"""
Created on Thu Apr 21 10:46:31 2022

@author: antonio.peters
"""
# Universal packages
<<<<<<< Updated upstream
import Shared.DSModel.src.preprocessingFunctions as prep
from CCEScripts.TrainLinearBasicity import TrainLinearBasicity
from CCEScripts.EvaluateLinearBasicity import EvaluateLinearBasicity
from Shared.DSModel.Config import Config

#%% Setup (to come from the config file)
inputs = prep.readAndFormatData('Chemistry')

configFile = "../config/basicity/linearModelConfigFile.yaml"
=======
from src.ModelClasses.LinearBasicityModel import LinearBasicityModel
import src.preprocessingFunctions as prep
import numpy as np
# Visualisation packages
import src.dataExploration as visualise
import matplotlib.pyplot as plt

#%% Setup (to come from the config file)
highFreqPredictors = ["Specific Oxygen Actual PV",
                      "Specific Silica Actual PV", "Matte feed PV(filtered)",
                      "Lance oxygen flow rate PV", "Lance air flow rate PV",
                      "Lance feed PV", "Silica PV", "Lump Coal PV",
                      "Matte transfer air flow", "Fuel coal feed rate PV"]

lowFreqPredictors = ["Fe Slag", "MgO Slag", "CaO Slag", "SiO2 Slag", "Al2O3 Slag",
                     "Ni Slag", "S Slag", "S Matte", "Slag temperatures",
                     "Matte temperatures", "Fe Feedblend", "S Feedblend",
                     "SiO2 Feedblend", "Al2O3 Feedblend", "CaO Feedblend",
                     "MgO Feedblend", "Cr2O3 Feedblend", "Corrected Ni Slag",
                     "Fe Matte"]

predictorTags = highFreqPredictors + lowFreqPredictors

responseTags = ["Basicity"]

fullDFOrig = prep.readAndFormatData('Chemistry', responseTags=responseTags,
        predictorTags=predictorTags)

# Training Specific Parameters
trainFrac = 0.85
maxTrainSize = int(47*24*60)
testSize = int(7*24*60)
numIters = 10;
>>>>>>> Stashed changes

configModel = Config(configFile)

<<<<<<< Updated upstream
#%% Model excution stuff
parameters = configModel.getParameters("Training")
parameters.update(configModel.getParameters("preprocessingAndFeatureEngineering"))

[trainOut, trainErrCode] = TrainLinearBasicity(parameters, inputs)

#Evaluate Model
parameters["ModelPath"] = trainOut["ModelPath"]
[evalOut, evalErrCode] = EvaluateLinearBasicity(parameters, inputs)
=======
# Setup the Model
LBModel = LinearBasicityModel(fullDFOrig)

# Train the Model
LBModel.train(trainFrac, maxTrainSize, testSize, numIters)

#%% Visualise Results

visualise.plotActualVsPredicted(LBModel.trainResults, LBModel.testResults, (1, 3), "Linear Model - Basicity")

visualise.plotTimeSeriesResults(LBModel.testResults, LBModel.origResponsesTest, "Linear Model - Basicity (Test Results)")

visualise.plotTimeSeriesResults(LBModel.trainResults, LBModel.origResponsesTrain, "Linear Model - Basicity (Train Results)")

visualise.plotResidualsAndErrors(LBModel.trainResults, LBModel.testResults)

convergenceIndicator, convergingPeriod, divergingPeriod = \
    LBModel.getDirectionalPerformance(LBModel.origResponsesTest, LBModel.testResults)

visualise.plotDirectionalPerformance(LBModel.origResponsesTest, LBModel.testResults, convergenceIndicator, "Linear Model - Basicity (Test Results)")

convergingPeriod/(convergingPeriod + divergingPeriod)

#%% Feature Importance
# modelling.getFeatureImportance(linearMdl, xTest, predictorsTest.columns, 'Linear')

comps = LBModel.pca.components_
coefs = LBModel.model.coef_
predictorWeights = np.sum(coefs[:, np.newaxis]*comps, axis = 0)

importantIndicators = np.flip(np.argsort(np.abs(predictorWeights)))
top20Columns = np.flip(LBModel.predictorsTest.columns[importantIndicators[0:20]])
top20Weights = np.flip(predictorWeights[importantIndicators[0:20]])

plt.figure()
plt.barh(top20Columns, top20Weights, align = 'center')
plt.title('Linear Model Top 20 Features')
>>>>>>> Stashed changes
