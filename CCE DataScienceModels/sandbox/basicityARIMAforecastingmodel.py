# -*- coding: utf-8 -*-
"""
This code focuses on attempting to forecast the basicity values
in the future using models such as ARIMA, SARIMA and LSTM.

Created on Fri Jan 13 10:37:32 2023

@author: darshan.makan
"""
#%% Load libraries

import pandas as pd
import numpy as np
import datetime
from datetime import timedelta
from sklearn.preprocessing import RobustScaler
from skopt import BayesSearchCV
from sklearn.model_selection import TimeSeriesSplit
from sklearn.pipeline import Pipeline
import matplotlib.pyplot as plt


import Shared.DSModel.src.preprocessingFunctions as prep
import Shared.DSModel.src.modellingFunctions as modelling
import Shared.DSModel.src.dataExploration as visualise
from sklearn.model_selection import cross_val_score
from statsmodels.graphics.tsaplots import plot_acf
from statsmodels.tsa.stattools import adfuller
from statsmodels.tsa.arima.model import ARIMA
from statsmodels.graphics.tsaplots import plot_pacf
from statsmodels.tsa.seasonal import seasonal_decompose
from statsmodels.tsa.statespace.sarimax import SARIMAX
from statsmodels.tsa.holtwinters import SimpleExpSmoothing
from arch import arch_model

#%% Load and format data

highFreqPredictors = ["Specific Oxygen Actual PV", "Specific Silica Actual PV", 
                        "Matte feed PV filtered", "Lance oxygen flow rate PV", 
                        "Lance air flow rate PV", "Lance feed PV", "Silica PV", 
                        "Lump Coal PV", "Matte transfer air flow", 
                        "Fuel coal feed rate PV"]

lowFreqPredictors =  ["Fe Slag", "MgO Slag", "CaO Slag", "SiO2 Slag", 
                        "Al2O3 Slag", "Ni Slag", "S Slag", "S Matte", 
                        "Slag temperatures", "Matte temperatures", "Fe Feedblend", 
                        "S Feedblend", "SiO2 Feedblend", "Al2O3 Feedblend", 
                        "CaO Feedblend", "MgO Feedblend", "Cr2O3 Feedblend", 
                        "Corrected Ni Slag", "Fe Matte"]

predictorTags = lowFreqPredictors + highFreqPredictors

responseTags = ["Basicity"]
referenceTags = ["Converter mode", "Lance air and oxygen control", "SumOfSpecies"]

fullDFOrig = prep.readAndFormatData('Chemistry')

def processingFunc(fullDFOrig):
    fullDF, origSmoothedResponses, predictorTagsNew = \
        prep.preprocessingAndFeatureEngineering(
            fullDFOrig,
            removeTransientData=True,
            smoothBasicityResponse=True,
            addRollingSumPredictors={'add': False, 'window': '19min'}, #NOTE: functionality exists to process an 'on' key
            addRollingMeanPredictors={'add': True, 'window': '95min'},
            addMeasureIndicatorsAsPredictors={'add': True, 'on': ['Basicity', 'Fe Feedblend', 'Matte temperatures']}, #NOTE: functionality exists to process an 'on' key
            addShiftsToPredictors={'add': True, 'nLags': 5, 'on': highFreqPredictors},
            addResponsesAsPredictors={'add': True, 'nLags': 3},
            resampleTime = '19min',
            resampleMethod = 'linear',
            responseTags=responseTags,
            referenceTags=referenceTags,
            predictorTags=predictorTags,
            highFrequencyPredictorTags = highFreqPredictors,
            lowFrequencyPredictorTags = lowFreqPredictors)
    return fullDF, origSmoothedResponses, predictorTagsNew

fullDF, origSmoothedResponses, predictorTagsNew = processingFunc(fullDFOrig)

predictorsTrain, responsesTrain, origResponsesTrain, predictorsTest, responsesTest, origResponsesTest = \
    prep.splitIntoTestAndTrain(
    fullDF,
    origSmoothedResponses,
    trainFrac=0.85,
    predictorTags=predictorTagsNew,
    responseTags=responseTags)
    
#responses = pd.concat((responsesTrain,responsesTest))
responses = fullDF.Basicity

#%% Data selection

start_Date = datetime.datetime(2021,1,1,0,0)
end_Date = datetime.datetime(2021,1,20,0,0)
test_End_Date = datetime.datetime(2021,1,21,0,0)

y_train = responses[start_Date:end_Date]

y_test = responses[end_Date:test_End_Date]
#y_test = y_test[1:]

plt.plot(y_train, color = 'k', label= 'Train Data')
plt.plot(y_test, color = 'r', label = 'Test Data', marker = '.')
plt.legend()

#%% ARIMA Model - data insights and parameter selection

#Testing for stationary data
#plot_acf(responses)

f = plt.figure()
ax1 = f.add_subplot(121)
ax1.set_title('1st Order Differencing')
ax1.plot(responses.diff())

ax2 = f.add_subplot(122)
plot_acf(responses.diff().dropna(), ax=ax2)
plt.show()

# f = plt.figure()
# ax1 = f.add_subplot(121)
# ax1.set_title('2nd Order Differencing')
# ax1.plot(responses.diff().diff())

# ax2 = f.add_subplot(122)
# plot_acf(responses.diff().diff().dropna(), ax=ax2)
# plt.show()

#%% Applying the Augmented Dickey-Fuller approach to test for stationary data
result = adfuller(responses.dropna())
print('p-value: ', result[1])

result = adfuller(responses.diff().dropna())
print('p-value: ', result[1])

result = adfuller(responses.diff().diff().dropna())
print('p-value: ', result[1])

#%% Determining the p value 

# f = plt.figure()
# ax1 = f.add_subplot(121)
# ax1.set_title('0 Order Differencing')
# ax1.plot(responses)

# ax2 = f.add_subplot(122)
# plot_pacf(responses.dropna(), ax=ax2, method = 'ols', lags = 20)
# plt.show()

f = plt.figure()
ax1 = f.add_subplot(121)
ax1.set_title('1st Order Differencing')
ax1.plot(responses.diff())

ax2 = f.add_subplot(122)
plot_pacf(responses.diff().dropna(), ax=ax2, method = 'ols')
plt.show()

# f = plt.figure()
# ax1 = f.add_subplot(121)
# ax1.set_title('2nd Order Differencing')
# ax1.plot(responses.diff().diff())

# ax2 = f.add_subplot(122)
# plot_pacf(responses.diff().diff().dropna(), ax=ax2, method = 'ols')
# plt.show()


#%% fitting the model

arima_model = ARIMA(y_train, order=(50,0,0))
model = arima_model.fit()
print(model.summary())

#%% predicting

y_pred = np.array(model.forecast(len(y_test)))
y_test_pred = pd.DataFrame(y_test.copy())
y_test_pred['Forecast'] = y_pred
y_pred = pd.DataFrame(y_pred, index=y_test.index)

plt.plot(y_test_pred.Basicity, label = 'Basicity measured', marker = '.')
plt.plot(y_test_pred.Forecast, label = 'Forecast AR', marker = '.')
plt.legend()

#%% Checking for seasonality

decomposition = seasonal_decompose(y_train, model = 'additive', period = 30)

trend = decomposition.trend
seasonal = decomposition.seasonal
residual = decomposition.resid

fig = decomposition.plot()
fig.set_size_inches(14, 7)
plt.show()


#%% SARIMAX model

model = SARIMAX(y_train, order = (50,0,0), seasonal_order=(50,0,0,60)).fit()
print(model.summary())

y_pred = model.get_forecast(steps = 66)
y_pred_mean = np.array(y_pred.predicted_mean)

y_test_pred = y_test.copy()
y_test_pred['Forecast'] = y_pred_mean
#y_pred = pd.DataFrame(y_pred, index=y_test.index)

# plt.plot(y_test_pred)

#%% Exponential smoothing

''' In the sections below a simple exponential smoothing algorithm
will be applied to forecast the basicity values. A simple exponential
algorithm was selected as the data does not show any trend/seasonality
'''
start_Date = datetime.datetime(2021,1,1,0,0)
end_Date = datetime.datetime(2021,1,9,0,0)
test_End_Date = datetime.datetime(2021,1,10,0,0)

y_test_pred = np.array([])

for i in range(len(y_test)-1):
     # int(((test_End_Date - end_Date).total_seconds())/60)
    if i == 0:
        y_train = responses[start_Date:end_Date]
        y_test = y_test.reindex(pd.date_range(end_Date,test_End_Date, freq='min'),method = 'backfill')
        # y_test = responses[end_Date:test_End_Date]
        # y_test = y_test[1:]
    elif i > 0:
        start_Date = start_Date + timedelta(minutes = 1)
        end_Date = end_Date + timedelta(minutes = 1)
        
        y_train = responses[start_Date:end_Date]
        #y_train.iloc[len(y_train)-1] = y_pred          #TODO: test this

        #y_test = responses[end_Date:test_End_Date]
        #y_test = y_test[1:]
       
    
    model = SimpleExpSmoothing(y_train)
    model_fitted = model.fit(smoothing_level = 0.6)
    #print('coefficients', model_fitted.params)
    
    y_pred = np.array(model_fitted.forecast(1))
    y_test_pred = np.append(y_test_pred,y_pred)
    

# y_test['Forecast'] = y_test_pred
# plt.plot(y_test)

y_joint = y_test.copy()
y_joint = y_joint[:607]
y_joint['Forecast'] = y_test_pred
plt.plot(y_joint)

#%% ARX modelling for forecasting
''' First perform feature importance to identify which
predictors hold more weighting in predicting the response
variable
'''

from sklearn.ensemble import RandomForestRegressor
featureImportanceModel = RandomForestRegressor(n_estimators=500, random_state = 1)
# featureImportanceModel.fit(predictors.values, np.ravel(responses))
featureImportanceModel.fit(x_train.values, np.ravel(y_train))

print(featureImportanceModel.feature_importances_)

feat_importances = pd.Series(featureImportanceModel.feature_importances_, index = predictors.columns)
feat_importances.nlargest(20).plot(kind = 'barh')
plt.show()

#%% ARX model
''' 
This code fits and forecasts Basicity using an ARX model
'''
predictors = pd.concat([predictorsTrain, predictorsTest])

# predictors_selected = predictors[['SiO2 Slag 5-rollingmean', '1-Lag Basicity', 'SiO2 Slag', 'Fe Slag 5-rollingmean', 'Fe Slag', 'Basicity Measure Indicator']]
predictors_selected = predictors

start_Date = datetime.datetime(2021,1,1,0,0)
end_Date = datetime.datetime(2021,1,20,0,0)
test_End_Date = datetime.datetime(2021,1,21,0,0)

y_train = responses[start_Date:end_Date]
x_train = predictors_selected[start_Date:end_Date]

y_test = responses[end_Date:test_End_Date]
y_test = y_test[1:]
x_test = predictors_selected[end_Date:test_End_Date]
x_test = x_test[1:]

arimax_model = ARIMA(y_train, exog = x_train, order=(2,0,0))
model = arimax_model.fit()
print(model.summary())

y_pred = np.array(model.forecast(len(y_test), exog = x_test))
y_test_pred = pd.DataFrame(y_test.copy())
y_test_pred['Forecast'] = y_pred

plt.plot(y_test, marker = '.', label = 'Basicity measured')
plt.plot(y_test_pred.Forecast, marker = '.', label = 'ARX(2)')
plt.legend()

#%% Feature engineering for ARX model

predictors = pd.concat([predictorsTrain, predictorsTest])

predictors_selected = predictors.drop(columns = ["Fe Feedblend","Cr2O3 Feedblend","Lance oxygen flow rate PV","CaO Feedblend","SiO2 Feedblend","Ni Slag","CaO Slag","Al2O3 Slag 19-rollingsum","Fe Feedblend 19-rollingsum","S Feedblend 19-rollingsum","Al2O3 Feedblend 19-rollingsum","SiO2 Feedblend 19-rollingsum","CaO Feedblend 19-rollingsum","Matte feed PV filtered 19-rollingsum","Lance oxygen flow rate PV 19-rollingsum","Lance feed PV 19-rollingsum","Al2O3 Feedblend 5-rollingmean","Cr2O3 Feedblend 5-rollingmean","Corrected Ni Slag 5-rollingmean","1-Lag Specific Silica Actual PV","2-Lag Specific Silica Actual PV","3-Lag Specific Silica Actual PV","4-Lag Specific Silica Actual PV","Matte feed PV filtered 5-rollingmean","Lance oxygen flow rate PV 5-rollingmean","Lance feed PV 5-rollingmean","1-Lag Lance oxygen flow rate PV","2-Lag Lance oxygen flow rate PV","3-Lag Lance oxygen flow rate PV","4-Lag Lance oxygen flow rate PV","5-Lag Lance oxygen flow rate PV"])

#%% ARX model with leading basicity
predictors = pd.concat([predictorsTrain, predictorsTest])
#predictors_selected = predictors[['SiO2 Slag 5-rollingmean', '1-Lag Basicity', 'SiO2 Slag', 'Fe Slag 5-rollingmean', 'Fe Slag', '5-Lag Specific Silica Actual PV']]
#predictors_selected = predictors[['SiO2 Slag 5-rollingmean', 'SiO2 Slag', 'Fe Slag 5-rollingmean', 'Fe Slag', '5-Lag Specific Silica Actual PV']]
predictors_selected = predictors.drop(columns = ['1-Lag Basicity', '2-Lag Basicity', '3-Lag Basicity'])
#predictors_selected = predictors

start_Date = datetime.datetime(2021,1,1,0,0)
end_Date = datetime.datetime(2021,1,20,0,0)
test_End_Date = datetime.datetime(2021,1,21,0,0)

lag_no = 1
y_test = responses[end_Date:test_End_Date]
x_test = predictors_selected[end_Date:test_End_Date]

y_train = responses[start_Date:end_Date].shift(-lag_no)
x_train = predictors_selected[start_Date:end_Date]

y_train = y_train.drop(y_train.tail(lag_no).index)
x_train = x_train.drop(x_train.tail(lag_no).index)

#y_test = responses[end_Date:test_End_Date]
#x_test = predictors_selected[end_Date:test_End_Date]

arimax_model = ARIMA(y_train, exog = x_train, order=(1,1,0))
model = arimax_model.fit()
print(model.summary())

y_pred = pd.DataFrame(np.float64((model.forecast(len(y_test), exog = x_test))),index = y_test.index)

#plt.plot(y_test, marker = '.', label = 'Basicity measured')
plt.plot(y_pred, marker = '.', label = 'Basicity predicted 1 lead - ARIMAX(1,1,0)')
plt.legend()

#%% ARCH model

squared_data = pd.Series([y**2 for y in y_train])
#plot_acf(squared_data)

model = arch_model(y_train, mean = 'Zero', vol = 'ARCH', p = 50)

model_fit = model.fit()

yhat = model_fit.forecast(horizon=len(y_test))

yhat_mean = yhat.mean.values[-1,:]
yhat_var = np.sqrt(yhat.variance.values[-1,:])

# yhat_pred = yhat_mean + yhat_var
yhat_pred = yhat_var

yhat_pred = pd.Series(yhat_pred, index = y_test.index)

plt.plot(y_test, marker = '.')
plt.plot(yhat_pred, marker ='.')

#%% ARCH model single value implementation
predictions = []
trainingData = y_train.copy()

for i in range(len(y_test)):
    
    model = arch_model(trainingData, mean = 'Zero', vol = 'ARCH', p = 50)
    model_fit = model.fit()
    
    yhat = np.sqrt(model_fit.forecast(horizon = len(y_test)-i).variance.values[-1,:])
    
    predictions = np.append(predictions,yhat[0])
    
    #trainingData.loc[y_test.index[i]] = np.float64(yhat[0])
    trainingData.loc[y_test.index[i]] = y_test[i]

predictions = pd.Series(predictions, index = y_test.index)
plt.plot(y_test, marker = '.')
plt.plot(predictions, marker ='.')

#%% GARCH model

squared_data = pd.Series([y**2 for y in y_train])
#plot_acf(squared_data)

model = arch_model(y_train, mean = 'Zero', vol = 'GARCH', p = 50, q = 50)

model_fit = model.fit()

yhat = model_fit.forecast(horizon=len(y_test))

yhat_mean = yhat.mean.values[-1,:]
yhat_var = np.sqrt(yhat.variance.values[-1,:])

# yhat_pred = yhat_mean + yhat_var
yhat_pred = yhat_var

yhat_pred = pd.Series(yhat_pred, index = y_test.index)

plt.plot(y_test, marker = '.')
plt.plot(yhat_pred, marker = '.')

#%% ARIMA model single value implementation

predictions = []
trainingData = y_train.copy()

for i in range(len(y_test)):
    
    model = ARIMA(trainingData, order=(5,0,0))
    model_fit = model.fit()
    
    y_pred = np.float64(model_fit.forecast(1))
    
    predictions = np.append(predictions,y_pred)
    
    #trainingData.loc[y_test.index[i]] = np.float64(yhat[0])
    trainingData.loc[y_test.index[i]] = y_test[i]

predictions = pd.Series(predictions, index = y_test.index)
plt.plot(y_test, marker = '.')
plt.plot(predictions, marker ='.')