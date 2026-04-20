# -*- coding: utf-8 -*-
"""
Created on Fri Dec  3 10:25:55 2021

@author: verushen.coopoo
"""

# https://cocalc.com/share/public_paths/7557a5ac1c870f1ec8f01271959b16b49df9d087/08-Designing-Kalman-Filters.ipynb

import matplotlib.pyplot as plt
import numpy as np
from filterpy.kalman import KalmanFilter
import sklearn
import scipy
from sklearn.model_selection import TimeSeriesSplit
import src.dataExploration as visualise
import src.modellingFunctions as modelling
import pandas as pd

#%% Linear model

from examples import exampleCorrectedNiSlagModellingForestPipeline as forest
forestErrors = forest.testResults.yActual - forest.testResults.yHat
testResultsForest = forest.testResults

from examples import exampleCorrectedNiSlagModellingLinearModelPipeline as linear
linearErrors = linear.testResults.yActual - linear.testResults.yHat
testResultsLinear = linear.testResults

origSmoothedResponsesTest = forest.origResponsesTest

bucketRMSE = visualise.getBucketRMSE(linearErrors, forestErrors)
referenceIndex = testResultsForest.index - pd.Timedelta(minutes = 30)
referenceIndex = referenceIndex.round('60min')

#%% Kalman filter

# Check link at top of the script under the 'Sensor fusion' section
# x - states
# P - covariance matrix
# F - state transition matrix
# Q - process noise matrix
# H - measurement function
# R - measurement noise matrix

kf = KalmanFilter(dim_x=1, dim_z=2)

# kf.F = np.array([[1., dt], [0., 1.]]) # Original
kf.F = np.array([[1.0]])         
# Try: kf.F = np.array([[1., 0], [1., 0.]])

kf.H = np.array([[1.], [1.]])

kf.x = np.array([[1250]])

# kf.Q = np.array([[1.0]])
kf.Q = np.array([[60.0]])

xs, zs, nom = [], [], []
# testResultsForest = testResultsForest.loc[testResultsLinear.index]

testResultsLinear = testResultsLinear.loc[testResultsForest.index]
for i in range(0, len(testResultsLinear)):
    m0 = testResultsLinear['yHat'][i]
    m1 = testResultsForest['yHat'][i]
    z = np.array([[m0], [m1]])
    
    if referenceIndex[i] in bucketRMSE.index:
        kf.R[0, 0] = bucketRMSE.loc[referenceIndex[i]]['Linear rmse']
        kf.R[1, 1] = bucketRMSE.loc[referenceIndex[i]]['Forest rmse']
    else:
        kf.R[0, 0] = bucketRMSE.loc[referenceIndex[i-1]]['Linear rmse']
        kf.R[1, 1] = bucketRMSE.loc[referenceIndex[i-1]]['Forest rmse']
        
    kf.predict()
    kf.update(z)

    xs.append(kf.x.T[0])
    zs.append(z.T[0])
    nom.append(i)

xs = np.asarray(xs)
zs = np.asarray(zs)
nom = np.asarray(nom)

res = nom - xs[:, 0]
print('fusion std: {:.3f}'.format(np.std(res)))
plt.figure()
plt.plot(zs[:, 0], label='Linear')
plt.plot(zs[:, 1], linestyle='--', label='Forest')
plt.plot(xs[:, 0], label='Kalman filter')
plt.legend(loc=4)
testResultsForest['KalmanOutput'] = xs[:, 0]

#%% Visualisations
plt.close('all')
fig, axes = plt.subplots(nrows=3,
                         ncols=1,
                         sharex=True,
                         sharey=True)

# testResultsLinear.plot(ax=axes[0],y='yActual',color='turquoise')
testResultsLinear.plot(ax=axes[0],y='yHat',color='blue')
origSmoothedResponsesTest.plot(label = 'yActual',  color='turquoise', ax=axes[0])
axes[0].set_title('Linear model')

# testResultsForest.plot(ax=axes[1],y='yActual',color='coral')
testResultsForest.plot(ax=axes[1],y='yHat',color='red')
origSmoothedResponsesTest.plot(label = 'yActual',  color='turquoise',ax=axes[1])
axes[1].set_title('Forest model')

testResultsForest.plot(ax=axes[2],y='KalmanOutput',color='purple')
# testResultsLinear.plot(ax=axes[2],y='yActual',color='turquoise')
origSmoothedResponsesTest.plot(label = 'yActual',  color='turquoise',ax=axes[2])
axes[2].set_title('Kalman filter')

fig.suptitle('Basicity modelling')

plt.legend()
plt.show()

plt.figure()
plt.plot(testResultsLinear['yHat'],label='yHat (linear)',marker='o',markersize=2.5,color='turquoise')
plt.plot(testResultsForest['yHat'],color='coral',label='yHat (Forest)',marker='o',markersize=2.5)
plt.plot(testResultsForest['KalmanOutput'],color='purple',label='Kalman output',marker='.',markersize=2.5)
plt.plot(testResultsForest['yActual'],label='yActual',marker='o',markersize=2.5,color='red')
plt.title('Corrected Ni Slag modelling')
plt.legend()

visualise.plotTimeSeriesResults(testResultsLinear, origSmoothedResponsesTest, "Linear Model - Corrected Ni Slag (Test Results)")
visualise.plotTimeSeriesResults(testResultsForest, origSmoothedResponsesTest, "Forest Model - Corrected Ni Slag (Test Results)")
ax = testResultsForest.plot(y='yActual', use_index=True, style = 'b-')
origSmoothedResponsesTest.plot(use_index=True, ax=ax, style='r*')
testResultsForest.plot(y='KalmanOutput', use_index=True, ax=ax, style = 'go-')
plt.title("Kalman - Corrected Ni Slag (Test Results)", fontsize=15)
plt.legend(('yActual Resampled', 'yActual Samples', 'yPredicted'))
plt.show()

#%% Results
print('Kalman Filter')
modelling.regression_results(testResultsForest.yActual, testResultsForest.KalmanOutput)
print('Random Forest')
modelling.regression_results(testResultsForest.yActual, testResultsForest.yHat)
print('Linear')
modelling.regression_results(testResultsForest.yActual, testResultsLinear.yHat)

errMean = round(np.mean(testResultsForest["yActual"] - testResultsForest["KalmanOutput"]),4)
errStd = round(np.std(testResultsForest["yActual"] - testResultsForest["KalmanOutput"]), 4)