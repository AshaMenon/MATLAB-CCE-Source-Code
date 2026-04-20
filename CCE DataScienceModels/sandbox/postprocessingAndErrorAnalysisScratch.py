# -*- coding: utf-8 -*-
"""
Created on Fri Feb 18 10:49:27 2022

@author: john.atherfold
"""

from statsmodels.tsa.stattools import acf, pacf
from statsmodels.graphics.tsaplots import plot_acf, plot_pacf
import matplotlib.pyplot as plt
import src.dataExploration as visualise
import numpy as np

#%%
from examples import exampleBasicityModellingForestPipeline as forest
forestErrors = forest.testResults.yActual - forest.testResults.yHat
testResultsForest = forest.testResults

from examples import exampleBasicityModellingLinearModelPipeline as linear
linearErrors = linear.testResults.yActual - linear.testResults.yHat
testResultsLinear = linear.testResults

from examples import exampleBasicityModellingXgboostPipeline as xgb
xgbErrors = xgb.testResults.yActual - xgb.testResults.yHat
testResultsXgb = xgb.testResults

# from sandbox import basicityScratchWithInteractions as lassoMdl
# lassoErrors = lassoMdl.testResults.yActual - lassoMdl.testResults.yHat
# testResultsLasso = lassoMdl.testResults

def createSubPlot(mdl, origResponses, axes, title):
    mdl.testResults.plot(y='yActual', use_index=True, ax = axes, style = 'b-')
    mdl.origResponsesTest.plot(use_index=True, ax=axes, style='r*')
    mdl.testResults.plot(y='yHat', use_index=True, ax=axes, style = 'go-')
    axes.set_title(title, fontsize=15)
    axes.legend(('yActual Resampled', 'yActual Samples', 'yPredicted'))
    for nPoint in np.arange(len(origResponses) - 1):
        if mdl.convergenceIndicator.Duration.iloc[nPoint] > np.timedelta64(60, 'm'):
            backgroundColour = 'w'
        else:
            backgroundColour = 'g'*mdl.convergenceIndicator.Convergence.iloc[nPoint] + \
                'r'*(mdl.convergenceIndicator.Convergence.iloc[nPoint] == False)
        axes.axvspan(origResponses.index[nPoint], origResponses.index[nPoint + 1],
                    facecolor = backgroundColour, alpha = 0.5)
    return None

#%%

fig, axs = plt.subplots(3, sharex=True, sharey=True)
fig.suptitle('Directional Performance', fontsize=15)
origResponses = linear.origResponsesTest.dropna()
createSubPlot(linear, origResponses, axs[0], "Linear Model - Basicity (Test Results)")
createSubPlot(forest, origResponses, axs[1], "Forest Model - Basicity (Test Results)")
createSubPlot(xgb, origResponses, axs[2], "XGBoost Model - Basicity (Test Results)")
plt.show()
