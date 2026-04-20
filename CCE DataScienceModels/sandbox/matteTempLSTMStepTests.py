# -*- coding: utf-8 -*-
"""
Step Tests - LSTM Model
"""
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import src.preprocessingFunctions as prep
import src.featureEngineeringHelpers as featEng
import datetime

#%% Read and Format Data
predictorTags = ["Fuel coal feed rate", "Matte feed PV",
                "Specific Oxygen Actual PV", "Lance oxygen flow rate PV",
                "Matte transfer air flow", "Lance air flow rate PV",
                "Lance coal carrier air","Silica PV",
                "Lance air & oxygen control",
                "Slag temperatures",
                 "Lower waffle 21", 
                 "Upper hearth 98"]

responseTags = ['Matte temperatures']

fullDF, predictorTags, responseTags = \
    prep.readAndFormatData(
        'Temperature',
        responseTags=responseTags,
        predictorTags=predictorTags,
        removeTransientData=True,
        addRollingSumPredictors={'add': True, 'window': 30}, #NOTE: You can use an 'on' key to define which vars this needs to be applied to
        smoothBasicityResponse=False,
        addResponsesAsPredictors=True,
        # addMeasureIndicatorsAsPredictors={'add': False,},
        addMeasureIndicatorsAsPredictors={'add': True, 'on': ["Matte temperatures"]},
        addShiftsToPredictors={'add': False, 'numberOfShifts': 2} #NOTE: You can use an 'on' key to define which vars this needs to be applied to
    )
    
[origSmoothedResponses, irregularIdx] = featEng.getUniqueDataPoints(fullDF[responseTags])   
endTime = origSmoothedResponses.index[np.argmax(np.diff(origSmoothedResponses.index))]

#%% Using Actual Data
# This mimicks the changes in all variables

# Generate Step Data
# Generate Step Data
start_date = datetime.datetime(2021, 1, 1, 2, 26)
end_date = datetime.datetime(2021, 1, 1, 5, 21)
stepDataDates = (fullDF.index > start_date) & (fullDF.index <= end_date)
stepData = fullDF.loc[stepDataDates]

# Find difference in Fuel Coal Rate and actual Matte Temperatures
fuelCoalRateDiff = stepData["Fuel coal feed rate"].diff()
actualMatteTempDiff = stepData["Matte temperatures"].diff()

# Use step data to get predictions
predictors = stepData[predictorTags]

from sandbox import matteTempLSTM as lstm


scaledPredictors = lstm.scaler.transform(predictors)
pcaPredictors = lstm.pca.transform(scaledPredictors)
xData = np.reshape(pcaPredictors, (pcaPredictors.shape[0], 1, pcaPredictors.shape[1]))

predictedMatteTemp = lstm.model1.predict(xData)

# Find difference in predicted matte temperatures
predictedMatteTempDiff = np.diff(predictedMatteTemp.ravel())

fuelCoalGrad = fuelCoalRateDiff > 0
fuelCoalGrad = fuelCoalGrad.astype(int)

predictedMatteGrad = predictedMatteTempDiff > 0
predictedMatteGrad = predictedMatteGrad.astype(int)

actualMatteGrad = actualMatteTempDiff > 0
actualMatteGrad = actualMatteGrad.astype(int)

fig, axs = plt.subplots(2,sharex=True)
axs[0].title.set_text('Step Tests (Actual Data) - LSTM Model')
axs[0].step(range(1,len(fuelCoalGrad)),fuelCoalGrad[1:len(fuelCoalGrad)])
axs[0].set_ylabel('Fuel Coal Change')
axs[1].step(range(1,len(fuelCoalGrad)),predictedMatteGrad)
axs[1].set_ylabel('Predicted Matte Temp Change')

fig, axs = plt.subplots(2,sharex=True)
axs[0].title.set_text('Step Tests - LSTM Model')
axs[0].plot(range(1,len(fuelCoalGrad)),stepData['Fuel coal feed rate'][1:len(fuelCoalGrad)])
axs[0].set_ylabel('Fuel Coal Rate')
axs[1].plot(range(1,len(fuelCoalGrad)),predictedMatteTemp[1:len(fuelCoalGrad)])
axs[1].set_ylabel('Predicted Matte Temp')


#%% Changing only Fuel Coal Rate
stepData2 = pd.DataFrame()
stepData2 = stepData2.append([stepData.iloc[1,:]]* len(fuelCoalRateDiff),ignore_index=True)
vals = np.random.randint(0, high=5, size=175)
stepData2["Fuel coal feed rate"][1:len(fuelCoalRateDiff)] = vals[1:len(fuelCoalRateDiff)]

# Fuel Coal Calc
lanceAir = stepData2['Lance air flow rate PV']
fuelCoalAir = (stepData2['Fuel coal feed rate'] * 1425)/0.42*(0.99-0.42)/(0.99-0.21)
stepData2['Lance O2'] = (stepData2['Fuel coal feed rate'] * 1425)/0.42*(0.21-0.42)/(0.99-0.21)*-1
stepData2['Lance air flow rate PV'] = lanceAir + (fuelCoalAir - stepData2['Lance coal carrier air'])

# Use step data to get predictions
predictors = stepData2[predictorTags]
scaledPredictors = lstm.scaler.transform(predictors)
pcaPredictors = lstm.pca.transform(scaledPredictors)
xData = np.reshape(pcaPredictors, (pcaPredictors.shape[0], 1, pcaPredictors.shape[1]))


predictedMatteTemp2 = lstm.model1.predict(xData)

# Find difference in predicted matte temperatures
predictedMatteTempDiff2 = np.diff(predictedMatteTemp.ravel())

fuelCoalGrad2 = fuelCoalRateDiff > 0
fuelCoalGrad2 = fuelCoalGrad2.astype(int)

predictedMatteGrad2 = predictedMatteTempDiff2 > 0
predictedMatteGrad2 = predictedMatteGrad2.astype(int)

fig, axs = plt.subplots(2,sharex=True)
axs[0].title.set_text('Step Tests - LSTM Model')
axs[0].step(range(1,len(fuelCoalGrad2)),fuelCoalGrad2[1:len(fuelCoalGrad2)])
axs[0].set_ylabel('Fuel Coal Change')
axs[1].step(range(1,len(fuelCoalGrad2)),predictedMatteGrad2)
axs[1].set_ylabel('Predicted Matte Temp Change')

fig, axs = plt.subplots(2,sharex=True)
axs[0].title.set_text('Step Tests - LSTM Model')
axs[0].plot(range(1,len(fuelCoalGrad2)),stepData2['Fuel coal feed rate'][1:len(fuelCoalGrad2)])
axs[0].set_ylabel('Fuel Coal Rate')
axs[1].plot(range(1,len(fuelCoalGrad2)),predictedMatteTemp2[1:len(fuelCoalGrad2)])
axs[1].set_ylabel('Predicted Matte Temp')

#%% Percentage Change of Fuel Coal Rate

changeVals = np.array([0.1, -0.2, -0.1, 0.7, 0.2, -0.3, 0.8])
dataLen = len(changeVals)
stepData3 = pd.DataFrame()
stepData3 = stepData3.append([stepData.iloc[1,:]]*dataLen,ignore_index=True)

vals = stepData3["Fuel coal feed rate"].values + (stepData3["Fuel coal feed rate"] * changeVals)
stepData3["Fuel coal feed rate"][1:dataLen] = vals[1:dataLen]

# Fuel Coal Calc
lanceAir = stepData3['Lance air flow rate PV']
fuelCoalAir = (stepData3['Fuel coal feed rate'] * 1425)/0.42*(0.99-0.42)/(0.99-0.21)
stepData3['Lance O2'] = (stepData3['Fuel coal feed rate'] * 1425)/0.42*(0.21-0.42)/(0.99-0.21)*-1
stepData3['Lance air flow rate PV'] = lanceAir + (fuelCoalAir - stepData3['Lance coal carrier air'])

# Use step data to get predictions
predictors = stepData3[predictorTags]
xData = np.reshape(pcaPredictors, (pcaPredictors.shape[0], 1, pcaPredictors.shape[1]))
predictedMatteTemp3 = lstm.model1.predict(xData)

fig, axs = plt.subplots(2,sharex=True)
axs[0].title.set_text('Step Tests - LSTM Model')
axs[0].plot(range(0,dataLen),stepData3['Fuel coal feed rate'][0:dataLen])
axs[0].set_ylabel('Fuel Coal Rate')
axs[1].plot(range(0,dataLen),predictedMatteTemp3[0:dataLen])
axs[1].set_ylabel('Predicted Matte Temp')

for nPoint in np.arange(dataLen - 1): 
        backgroundColour = 'g'*convergenceIndicator.Convergence.iloc[nPoint] + \
            'r'*(convergenceIndicator.Convergence.iloc[nPoint] == False)
        plt.axvspan(origResponses.index[nPoint], origResponses.index[nPoint + 1],
                    facecolor = backgroundColour, alpha = 0.5)