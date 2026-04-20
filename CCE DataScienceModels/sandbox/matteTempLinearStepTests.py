# -*- coding: utf-8 -*-
"""
Step Tests - Linear Model
"""
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import src.preprocessingFunctions as prep
import src.featureEngineeringHelpers as featEng
import datetime



from examples import exampleMatteTempModellingLinearModelPipeline as linear


start_date = datetime.datetime(2021, 11, 4, 16, 0)
end_date = datetime.datetime(2021, 11, 4, 18, 0)
stepDataDates = (linear.predictorsTest.index > start_date) & (linear.predictorsTest.index <= end_date)
stepData = linear.predictorsTest.loc[stepDataDates].join(linear.responsesTest.loc[stepDataDates])
# Find difference in Fuel Coal Rate and actual Matte Temperatures
fuelCoalRateDiff = stepData["Fuel coal feed rate PV"].diff()
actualMatteTempDiff = stepData["Matte temperatures"].diff()

# Use step data to get predictions
predictors = stepData[linear.predictorTagsNew]

scaledPredictors = linear.scaler.fit_transform(predictors)
pcaPredictors = linear.pca.transform(scaledPredictors)
predictedMatteTemp = linear.linearMdl.predict(pcaPredictors)

# Find difference in predicted matte temperatures
predictedMatteTempDiff = np.diff(predictedMatteTemp)

fuelCoalGrad = fuelCoalRateDiff > 0
fuelCoalGrad = fuelCoalGrad.astype(int)

predictedMatteGrad = predictedMatteTempDiff > 0
predictedMatteGrad = predictedMatteGrad.astype(int)

actualMatteGrad = actualMatteTempDiff > 0
actualMatteGrad = actualMatteGrad.astype(int)

fig, axs = plt.subplots(2,sharex=True)
axs[0].title.set_text('Step Tests (Actual Data) - Linear Model')
axs[0].step(range(1,len(fuelCoalGrad)),fuelCoalGrad[1:len(fuelCoalGrad)])
axs[0].set_ylabel('Fuel Coal Change')
axs[1].step(range(1,len(fuelCoalGrad)),predictedMatteGrad)
axs[1].set_ylabel('Predicted Matte Temp Change')
# axs[2].step(range(1,len(fuelCoalGrad)),actualMatteGrad[1:len(actualMatteGrad)])
# axs[2].set_ylabel('Actual Matte Temp Change')


fig, axs = plt.subplots(2,sharex=True)
axs[0].title.set_text('Step Tests - Linear Model')
axs[0].plot(range(1,len(fuelCoalGrad)),stepData['Fuel coal feed rate PV'][1:len(fuelCoalGrad)])
axs[0].set_ylabel('Fuel Coal Rate')
axs[1].plot(range(1,len(fuelCoalGrad)),predictedMatteTemp[1:len(fuelCoalGrad)])
axs[1].set_ylabel('Predicted Matte Temp')


#%% Changing only Fuel Coal Rate
stepData2 = pd.DataFrame()
stepData2 = stepData2.append([stepData.iloc[1,:]]* len(fuelCoalRateDiff),ignore_index=True)
# vals = stepData2["Fuel coal feed rate PV"].values + fuelCoalRateDiff.values
vals = np.random.randint(0, high=5, size=175)
stepData2["Fuel coal feed rate PV"][1:len(fuelCoalRateDiff)] = vals[1:len(fuelCoalRateDiff)]

# Fuel Coal Calc
# fullDF['fuelCoalRateEnergy'] = (fullDF['Fuel coal feed rate PV'] / 1.4) * 11.0111616933864
# stepData2['Lance coal carrier air'] = (stepData2['Fuel coal feed rate PV'] * 1425)/0.42*(0.99-0.42)/(0.99-0.21)
# stepData2['Lance O2'] = (stepData2['Fuel coal feed rate PV'] * 1425)/0.42*(0.21-0.42)/(0.99-0.21)*-1
lanceAir = stepData2['Lance air flow rate PV']
fuelCoalAir = (stepData2['Fuel coal feed rate PV'] * 1425)/0.42*(0.99-0.42)/(0.99-0.21)
stepData2['Lance O2'] = (stepData2['Fuel coal feed rate PV'] * 1425)/0.42*(0.21-0.42)/(0.99-0.21)*-1
stepData2['Lance air flow rate PV'] = lanceAir + (fuelCoalAir - stepData2['Lance coal carrier air'])

# Use step data to get predictions
predictors = stepData2[linear.predictorTagsNew]

scaledPredictors = linear.scaler.fit_transform(predictors)
pcaPredictors = linear.pca.transform(scaledPredictors)
predictedMatteTemp2 = linear.linearMdl.predict(pcaPredictors)

# Find difference in predicted matte temperatures
predictedMatteTempDiff2 = np.diff(predictedMatteTemp2)
fuelCoalRateDiff2 = stepData2["Fuel coal feed rate PV"].diff()
fuelCoalGrad2 = fuelCoalRateDiff2 > 0
fuelCoalGrad2 = fuelCoalGrad2.astype(int)

predictedMatteGrad2 = predictedMatteTempDiff2 > 0
predictedMatteGrad2 = predictedMatteGrad2.astype(int)

fig, axs = plt.subplots(2,sharex=True)
axs[0].title.set_text('Step Tests - Linear Model')
axs[0].step(range(1,len(fuelCoalGrad2)),fuelCoalGrad2[1:len(fuelCoalGrad2)])
axs[0].set_ylabel('Fuel Coal Change')
axs[1].step(range(1,len(fuelCoalGrad2)),predictedMatteGrad2)
axs[1].set_ylabel('Predicted Matte Temp Change')

fig, axs = plt.subplots(2,sharex=True)
axs[0].title.set_text('Step Tests - Linear Model')
axs[0].plot(range(1,len(fuelCoalGrad2)),stepData2['Fuel coal feed rate PV'][1:len(fuelCoalGrad2)])
axs[0].set_ylabel('Fuel Coal Rate')
axs[1].plot(range(1,len(fuelCoalGrad2)),predictedMatteTemp2[1:len(fuelCoalGrad2)])
axs[1].set_ylabel('Predicted Matte Temp')

#%%

changeVals = np.array([0.1, -0.2, -0.1, 0.7, 0.2, -0.3, 0.8])
dataLen = len(changeVals)
stepData3 = pd.DataFrame()
stepData3 = stepData3.append([stepData.iloc[1,:]]*dataLen,ignore_index=True)

# vals = stepData2["Fuel coal feed rate PV"].values + fuelCoalRateDiff.values
vals = stepData3["Fuel coal feed rate PV"].values + (stepData3["Fuel coal feed rate PV"] * changeVals)

# vals = np.random.randint(0, high=5, size=175)
stepData3["Fuel coal feed rate PV"][1:dataLen] = vals[1:dataLen]

# Fuel Coal Calc

lanceAir = stepData3['Lance air flow rate PV']
fuelCoalAir = (stepData3['Fuel coal feed rate PV'] * 1425)/0.42*(0.99-0.42)/(0.99-0.21)
stepData3['Lance O2'] = (stepData3['Fuel coal feed rate PV'] * 1425)/0.42*(0.21-0.42)/(0.99-0.21)*-1
stepData3['Lance air flow rate PV'] = lanceAir + (fuelCoalAir - stepData3['Lance coal carrier air'])

# Use step data to get predictions
predictors = stepData3[linear.predictorTagsNew]

scaledPredictors = linear.scaler.fit_transform(predictors)
pcaPredictors = linear.pca.transform(scaledPredictors)
predictedMatteTemp3 = linear.linearMdl.predict(pcaPredictors)

fig, axs = plt.subplots(2,sharex=True)
axs[0].title.set_text('Step Tests - Linear Model')
axs[0].plot(range(0,dataLen),stepData3['Fuel coal feed rate PV'][0:dataLen])
axs[0].set_ylabel('Fuel Coal Rate')
axs[1].plot(range(0,dataLen),predictedMatteTemp3[0:dataLen])
axs[1].set_ylabel('Predicted Matte Temp')

# fuelCoalRateDiff3 = stepData3["Fuel coal feed rate PV"].diff()
# predictedMatteTempDiff3 = np.diff(predictedMatteTemp3)

# fuelCoalGrad3 = fuelCoalRateDiff3 > 0
# fuelCoalGrad3 = fuelCoalGrad3.astype(int)

# predictedMatteGrad3 = predictedMatteTempDiff3 > 0
# predictedMatteGrad3 = predictedMatteGrad3.astype(int)

# fig, axs = plt.subplots(2,sharex=True)
# axs[0].title.set_text('Step Tests - Linear Model')
# axs[0].step(range(1,len(fuelCoalGrad3)),fuelCoalGrad3[1:len(fuelCoalGrad3)])
# axs[0].set_ylabel('Fuel Coal Change')
# axs[1].step(range(1,len(fuelCoalGrad3)),predictedMatteGrad3)
# axs[1].set_ylabel('Predicted Matte Temp Change')

#%%
start_date = datetime.datetime(2021, 10 ,29 , 5, 0)
end_date = datetime.datetime(2021, 11, 2, 17, 0)
stepDataDates = (linear.fullDF.index > start_date) & (linear.fullDF.index <= end_date)
stepData4 = linear.fullDF.loc[stepDataDates]

[origData, irregularIdx] = featEng.getUniqueDataPoints(stepData4['Fuel coal feed rate PV'])
stepData4 = stepData4.loc[irregularIdx]
stepData4 = stepData4.resample('1min').ffill()

changeVals = np.array([0.3, -0.2])

stepChange1 = stepData4.copy()
stepChange2 = stepData4.copy()

stepChange1["Fuel coal feed rate PV"] = stepChange1["Fuel coal feed rate PV"] + (stepChange1["Fuel coal feed rate PV"] * 0.3)
stepChange2["Fuel coal feed rate PV"] = stepChange2["Fuel coal feed rate PV"].values + (stepChange2["Fuel coal feed rate PV"] * -0.2)


# Fuel Coal Calc

lanceAir = stepData4['Lance air flow rate PV']
fuelCoalAir1 = (stepChange1['Fuel coal feed rate PV'] * 1425)/0.42*(0.99-0.42)/(0.99-0.21)
fuelCoalAir2 = (stepChange2['Fuel coal feed rate PV'] * 1425)/0.42*(0.99-0.42)/(0.99-0.21)

stepChange1['Lance O2'] = (stepChange1['Fuel coal feed rate PV'] * 1425)/0.42*(0.21-0.42)/(0.99-0.21)*-1
stepChange1['Lance air flow rate PV'] = lanceAir + (fuelCoalAir1 - stepChange1['Lance coal carrier air'])
stepChange2['Lance O2'] = (stepChange2['Fuel coal feed rate PV'] * 1425)/0.42*(0.21-0.42)/(0.99-0.21)*-1
stepChange2['Lance air flow rate PV'] = lanceAir + (fuelCoalAir2 - stepChange2['Lance coal carrier air'])


# Use step data to get predictions
predictors = stepData4[linear.predictorTagsNew]

scaledPredictors = linear.scaler.fit_transform(predictors)
pcaPredictors = linear.pca.transform(scaledPredictors)
predictedMatteTempBaseline = linear.linearMdl.predict(pcaPredictors)

predictors = stepChange1[linear.predictorTagsNew]

scaledPredictors = linear.scaler.fit_transform(predictors)
pcaPredictors = linear.pca.transform(scaledPredictors)
predictedMatteTemp1 = linear.linearMdl.predict(pcaPredictors)

predictors = stepChange2[linear.predictorTagsNew]

scaledPredictors = linear.scaler.fit_transform(predictors)
pcaPredictors = linear.pca.transform(scaledPredictors)
predictedMatteTemp2 = linear.linearMdl.predict(pcaPredictors)


# fig, axs = plt.subplots(2,sharex=True)
# axs[0].title.set_text('Step Tests - Linear Model')
# stepData4['Fuel coal feed rate PV'].plot(ax = axs[0], color = 'b')
# stepChange1['Fuel coal feed rate PV'].plot(ax = axs[0], color = 'g')
# stepChange2['Fuel coal feed rate PV'].plot(ax = axs[0], color = 'r')
# axs[0].legend(['Baseline', '30% Step Up', '20% Step Up'])
# axs[0].set_ylabel('Fuel Coal Rate')
# stepData4["Matte temperatures"].plot(ax = axs[1], color = 'c')
# axs[1].plot(stepData4.index,predictedMatteTempBaseline, color = 'b')
# axs[1].plot(stepData4.index,predictedMatteTemp1, color = 'g')
# axs[1].plot(stepData4.index,predictedMatteTemp2, color = 'r')
# axs[1].legend(['Actual Matte Temp','Baseline', '30% Step Up', '20% Step Up'])
# axs[1].set_ylabel('Predicted Matte Temp')

fig, axs = plt.subplots(2,sharex=True)
axs[0].title.set_text('Step Tests - XGBoost Model')
axs[0].plot(stepData4.index,stepData4['Fuel coal feed rate PV'], color = 'b')
axs[0].plot(stepData4.index,stepChange1['Fuel coal feed rate PV'], color = 'g')
axs[0].plot(stepData4.index,stepChange2['Fuel coal feed rate PV'], color = 'r')
axs[0].legend(['Baseline', '30% Step Up', '20% Step Up'])
axs[0].set_ylabel('Fuel Coal Rate')
axs[1].plot(stepData4.index,predictedMatteTempBaseline, color = 'b')
axs[1].plot(stepData4.index,predictedMatteTemp1, color = 'g')
axs[1].plot(stepData4.index,predictedMatteTemp2, color = 'r')
axs[1].plot(stepData4.index,stepData4["Matte temperatures"], color = 'c')
axs[1].legend(['Actual Matte Temp','Baseline', '30% Step Up', '20% Step Up'])
axs[1].set_ylabel('Predicted Matte Temp')