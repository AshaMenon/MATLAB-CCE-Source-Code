# -*- coding: utf-8 -*-
"""
Created on Tue May 10 11:42:29 2022

@author: john.atherfold
"""

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
import os

testingErrors = testResults.yActual - testResults.yHat
bigSwingIdx = np.abs(testingErrors) > 20
laterTimes = bigSwingIdx[bigSwingIdx].index + np.timedelta64(2, 'h')
earlierTimes = bigSwingIdx[bigSwingIdx].index - np.timedelta64(2, 'h')

for nChunk in np.arange(len(earlierTimes)):
    mask = (bigSwingIdx.index > earlierTimes[nChunk]) & (bigSwingIdx.index < laterTimes[nChunk])
    bigSwingIdx[mask] = True

absDiff = np.abs(bigSwingIdx.astype(int).diff())
ranges = np.where(absDiff == 1)[0].reshape(-1, 2)

origSmoothedResponses.index = pd.to_datetime(origSmoothedResponses.index)
testResults.index = pd.to_datetime(testResults.index)

fullDF['Converter mode'] = fullDFOrig['Converter mode']
#%%

saveDir = os.getcwd() + '\\data\\figures\\matteTempSwings\\'

for nRange in np.arange(len(ranges)):
    startIdx = ranges[nRange, 0]
    endIdx = ranges[nRange, 1]
    dateIdx = testResults.iloc[startIdx:endIdx].index
    irregMask = (origSmoothedResponses.index > dateIdx[0]) & (origSmoothedResponses.index < dateIdx[-1])
    fullDFMask = (fullDFOrig.index > dateIdx[0]) & (fullDFOrig.index < dateIdx[-1])
    
    axes = fullDF[['Matte temperatures', 'Matte feed PV rollingmean',
                   'Fuel coal feed rate PV rollingmean', 'Converter mode',
                   'Lance Oxy Enrich % PV rollingmean', 'Heat flux rollingmean', 
                   'Silica PV rollingmean']].loc[dateIdx].plot(subplots = True,
                                                               marker = 'x',
                                                               figsize = (30, 15))
    testResults['yHat'].iloc[startIdx:endIdx].plot(ax = axes[0], style = 'o-',
                                                   color = [0.8500, 0.3250, 0.0980])
    fullDFOrig['Converter mode'].loc[fullDFMask].plot(ax = axes[3], marker = 'x', color = '#d62728')
    if not origSmoothedResponses[responseTags].loc[irregMask].empty:
        origSmoothedResponses[responseTags].loc[irregMask].plot(ax = axes[0], style = 'r*')
    plt.savefig(saveDir + dateIdx[0].strftime("%Y-%m-%d %Hh%M") + ' - ' + dateIdx[-1].strftime("%Y-%m-%d %Hh%M") + '.png',
                bbox_inches='tight', dpi = 100)