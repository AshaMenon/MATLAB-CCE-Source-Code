# -*- coding: utf-8 -*-
"""
Created on Tue Feb 15 10:22:47 2022

@author: john.atherfold
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from sklearn.linear_model import Lasso
from sklearn.decomposition import PCA
from sklearn.preprocessing import StandardScaler
from skopt import BayesSearchCV
from sklearn.model_selection import TimeSeriesSplit
from sklearn.pipeline import Pipeline


import src.preprocessingFunctions as prep
import src.modellingFunctions as modelling
import src.dataExploration as visualise
from xgboost import XGBRegressor

#%% Read and Format Data
predictorTags = ["Fe Slag", "MgO Slag", "CaO Slag", "SiO2 Slag", "Al2O3 Slag",
                 "Ni Slag", "S Slag", "S Matte", "Specific Oxygen Actual PV",
                 "Specific Silica Actual PV", "Matte feed PV(filtered)",
                 "Lance oxygen flow rate PV", "Lance air flow rate PV",
                 "Lance feed PV", "Silica PV", "Lump Coal PV",
                 "Slag temperatures", "Matte temperatures",
                 "Reverts feed rate PV", "PGM feed rate PV",
                 "Matte transfer air flow", "Fe Feedblend", "S Feedblend",
                 "SiO2 Feedblend", "Al2O3 Feedblend", "CaO Feedblend",
                 "MgO Feedblend", "Cr2O3 Feedblend", "Corrected Ni Slag", "Fe Matte"]
responseTags = ['Basicity']

fullDF, predictorTags, responseTags = \
    prep.readAndFormatData(
        'Chemistry',
        responseTags=responseTags,
        predictorTags=predictorTags,
        removeTransientData=True,
        addRollingSumPredictors={'add': True, 'window': 30},
        smoothBasicityResponse=True,
        addResponsesAsPredictors=False,
        addMeasureIndicatorsAsPredictors={'add': False}
    )

predictorsTrain, responsesTrain, origResponsesTrain, predictorsTest, responsesTest, origResponsesTest = \
    prep.splitIntoTestAndTrain(
    fullDF,
    trainFrac=0.85,
    predictorTags=predictorTags,
    responseTags=responseTags
)
    
#%% Calculating directionality and convergence

origResponses = origResponsesTest.dropna()

bFilledResponses = origResponsesTest.fillna(method='backfill').dropna()
relevantTestResults = testResults.yHat.loc[bFilledResponses.index]
absError = abs(bFilledResponses.Basicity - relevantTestResults)

convergenceIndicator = pd.DataFrame(data=np.zeros((len(origResponses) - 1, 4)),
                                    index = origResponses.index[1:],
                                    columns = ["Average Predicted Gradient",
                                               "Actual Gradient", "Convergence",
                                               "Duration"])
convergenceIndicator = convergenceIndicator.astype({'Convergence': 'bool'})
convergenceIndicator = convergenceIndicator.astype({'Duration': 'timedelta64[ns]'})

for nPoint in np.arange(len(origResponses) - 1):
    convergenceIndicator.at[convergenceIndicator.index[nPoint], "Average Predicted Gradient"] = np.mean(np.diff(relevantTestResults.loc[origResponses.index[nPoint]:origResponses.index[nPoint + 1]  - np.timedelta64(1, 'm')]))

convergenceIndicator["Actual Gradient"] = np.diff(origResponses.Basicity)
convergenceIndicator.Convergence = np.sign(convergenceIndicator["Actual Gradient"]) == np.sign(convergenceIndicator["Average Predicted Gradient"])
convergenceIndicator.Duration = np.diff(origResponses.index)

ax = testResults.plot(y='yActual', use_index=True, style = 'b-')
origResponsesTest.plot(use_index=True, ax=ax, style='r*')
testResults.plot(y='yHat', use_index=True, ax=ax, style = 'go-')
plt.title("XGB Model - Basicity (Test Results)", fontsize=15)
plt.legend(('yActual Resampled', 'yActual Samples', 'yPredicted'))
# plt.axvline(x = origResponses.index[nPoint], color='r')
for nPoint in np.arange(len(origResponses) - 1): 
    backgroundColour = 'g'*convergenceIndicator.Convergence.iloc[nPoint] + \
        'r'*(convergenceIndicator.Convergence.iloc[nPoint] == False)
    plt.axvspan(origResponses.index[nPoint], origResponses.index[nPoint + 1],
                facecolor = backgroundColour, alpha = 0.5)
plt.show()

validDurations = convergenceIndicator.Duration < np.timedelta64(2, 'h')
convergingPeriod = np.sum(convergenceIndicator.Duration[np.logical_and(validDurations, convergenceIndicator.Convergence)])
divergingPeriod = np.sum(convergenceIndicator.Duration[np.logical_and(validDurations, ~convergenceIndicator.Convergence)])