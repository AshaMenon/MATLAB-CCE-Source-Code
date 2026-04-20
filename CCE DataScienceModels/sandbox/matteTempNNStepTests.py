# -*- coding: utf-8 -*-
"""
Step Tests - NN Model
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
start_date = datetime.datetime(2021, 1, 1, 2, 26)
end_date = datetime.datetime(2021, 1, 1, 5, 21)
stepDataDates = (fullDF.index > start_date) & (fullDF.index <= end_date)
stepData = fullDF.loc[stepDataDates]

# Find difference in Fuel Coal Rate and actual Matte Temperatures
fuelCoalRateDiff = stepData["Fuel coal feed rate"].diff()
actualMatteTempDiff = stepData["Matte temperatures"].diff()

# Use step data to get predictions
predictors = stepData[predictorTags]

from sandbox import matteTempNN as NN

predictedMatteTemp = NN.mdl.predict(predictors)

# Find difference in predicted matte temperatures
predictedMatteTempDiff = np.diff(predictedMatteTemp)

fuelCoalGrad = fuelCoalRateDiff > 0
fuelCoalGrad = fuelCoalGrad.astype(int)

predictedMatteGrad = predictedMatteTempDiff > 0
predictedMatteGrad = predictedMatteGrad.astype(int)

actualMatteGrad = actualMatteTempDiff > 0
actualMatteGrad = actualMatteGrad.astype(int)

fig, axs = plt.subplots(2,sharex=True)
axs[0].title.set_text('Step Tests (Actual Data) - NN Model')
axs[0].step(range(1,len(fuelCoalGrad)),fuelCoalGrad[1:len(fuelCoalGrad)])
axs[0].set_ylabel('Fuel Coal Change')
axs[1].step(range(1,len(fuelCoalGrad)),predictedMatteGrad)
axs[1].set_ylabel('Predicted Matte Temp Change')

fig, axs = plt.subplots(2,sharex=True)
axs[0].title.set_text('Step Tests - NN Model')
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
predictedMatteTemp2 = NN.mdl.predict(predictors)

# Find difference in predicted matte temperatures
predictedMatteTempDiff2 = np.diff(predictedMatteTemp)

fuelCoalGrad2 = fuelCoalRateDiff > 0
fuelCoalGrad2 = fuelCoalGrad2.astype(int)

predictedMatteGrad2 = predictedMatteTempDiff2 > 0
predictedMatteGrad2 = predictedMatteGrad2.astype(int)

fig, axs = plt.subplots(2,sharex=True)
axs[0].title.set_text('Step Tests - NN Model')
axs[0].step(range(1,len(fuelCoalGrad2)),fuelCoalGrad2[1:len(fuelCoalGrad2)])
axs[0].set_ylabel('Fuel Coal Change')
axs[1].step(range(1,len(fuelCoalGrad2)),predictedMatteGrad2)
axs[1].set_ylabel('Predicted Matte Temp Change')

fig, axs = plt.subplots(2,sharex=True)
axs[0].title.set_text('Step Tests - NN Model')
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
predictedMatteTemp3 = NN.mdl.predict(predictors)

fig, axs = plt.subplots(2,sharex=True)
axs[0].title.set_text('Step Tests - NN Model')
axs[0].plot(range(0,dataLen),stepData3['Fuel coal feed rate'][0:dataLen])
axs[0].set_ylabel('Fuel Coal Rate')
axs[1].plot(range(0,dataLen),predictedMatteTemp3[0:dataLen])
axs[1].set_ylabel('Predicted Matte Temp')

#%%
start_date = datetime.datetime(2021, 10 ,29 , 5, 0)
end_date = datetime.datetime(2021, 11, 2, 17, 0)
stepDataDates = (fullDF.index > start_date) & (fullDF.index <= end_date)
stepData4 = fullDF.loc[stepDataDates]


[origData, irregularIdx] = featEng.getUniqueDataPoints(stepData4['Fuel coal feed rate'])   
stepData4 = stepData4.resample('1min').ffill()
# idx = irregularIdx[0:-5] + datetime.timedelta(minutes=3)
idx = irregularIdx
stepData4 = stepData4.loc[idx]
stepData4 = stepData4.resample('1min').ffill()

changeVals = np.array([0.3, -0.2])

stepChange1 = stepData4.copy()
stepChange2 = stepData4.copy()

stepChange1["Fuel coal feed rate"] = stepChange1["Fuel coal feed rate"] + (stepChange1["Fuel coal feed rate"] * 0.3)
stepChange2["Fuel coal feed rate"] = stepChange2["Fuel coal feed rate"] + (stepChange2["Fuel coal feed rate"] * -0.2)


# Fuel Coal Calc
lanceAir = stepData4['Lance air flow rate PV']
fuelCoalAir1 = (stepChange1['Fuel coal feed rate'] * 1425)/0.42*(0.99-0.42)/(0.99-0.21)
fuelCoalAir2 = (stepChange2['Fuel coal feed rate'] * 1425)/0.42*(0.99-0.42)/(0.99-0.21)

stepChange1['Lance O2'] = (stepChange1['Fuel coal feed rate'] * 1425)/0.42*(0.21-0.42)/(0.99-0.21)*-1
stepChange1['Lance air flow rate PV'] = lanceAir + (fuelCoalAir1 - stepChange1['Lance coal carrier air'])
stepChange2['Lance O2'] = (stepChange2['Fuel coal feed rate'] * 1425)/0.42*(0.21-0.42)/(0.99-0.21)*-1
stepChange2['Lance air flow rate PV'] = lanceAir + (fuelCoalAir2 - stepChange2['Lance coal carrier air'])

# Use step data to get predictions
predictors1 = stepData4[predictorTags]
# predictors1 = predictors1.loc[idx]
# predictors1 = predictors1.resample('1min').ffill()
predictedMatteTempBaseline = NN.mdl.predict(predictors1)

predictors2 = stepChange1[predictorTags]
# predictors2 = predictors2.loc[idx]
# predictors2 = predictors2.resample('1min').ffill()
predictedMatteTemp1 = NN.mdl.predict(predictors2)

predictors3 = stepChange2[predictorTags]
# predictors3 = predictors3.loc[idx]
# predictors3 = predictors3.resample('1min').ffill()
predictedMatteTemp2 = NN.mdl.predict(predictors3)

fig, axs = plt.subplots(2,sharex=True)
axs[0].title.set_text('Step Tests - XGBoost Model')
axs[0].plot(stepData4.index,stepData4['Fuel coal feed rate'], color = 'b')
axs[0].plot(stepData4.index,stepChange1['Fuel coal feed rate'], color = 'g')
axs[0].plot(stepData4.index,stepChange2['Fuel coal feed rate'], color = 'r')
axs[0].legend(['Baseline', '30% Step Up', '20% Step Down'])
axs[0].set_ylabel('Fuel Coal Rate')
axs[1].plot(stepData4.index,stepData4["Matte temperatures"], color = 'c')
axs[1].plot(stepData4.index,predictedMatteTempBaseline, color = 'b')
axs[1].plot(stepData4.index,predictedMatteTemp1, color = 'g')
axs[1].plot(stepData4.index,predictedMatteTemp2, color = 'r')
axs[1].legend(['Actual Matte Temp','Baseline', '30% Step Up', '20% Step Down'])
axs[1].set_ylabel('Predicted Matte Temp')