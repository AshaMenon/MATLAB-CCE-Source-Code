# -*- coding: utf-8 -*-
"""
Created on Tue Apr 19 14:23:41 2022

@author: antonio.peters
"""

# Model Specific packages
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import RobustScaler
from sklearn.decomposition import PCA
from xgboost import XGBRegressor
import numpy as np
import pandas as pd
import math
from Shared.DSModel.Model import Model
from statsmodels.tsa.api import SimpleExpSmoothing

class XGEBoostBasicityModel(Model):

    def __init__(self, fullDF, predictorTags, responseTags, origSmoothedResponses, logger=None):

        super().__init__(fullDF, predictorTags, responseTags, origSmoothedResponses, outputLogger=logger)

        self.pipe =  Pipeline([('scaler', RobustScaler()),
                         ('pca', PCA()),
                         ('xgb_reg', XGBRegressor(objective='reg:squarederror', booster='gbtree'))])
        
        self.outputLogger.log_trace('Model PipeLine Defined')
            
        self.param = {
            'pca__n_components': np.arange(50, len(predictorTags)-1, 1),
            'xgb_reg__n_estimators': np.arange(100, 250),
            'xgb_reg__reg_lambda': np.logspace(-7, 0, num = 250),
            'xgb_reg__max_depth': np.arange(1, 20),
            'xgb_reg__learning_rate': np.logspace(-3, 0, num = 100),
            'xgb_reg__reg_alpha': np.logspace(-7, 0, num = 250),
            'xgb_reg__subsample': np.arange(0.1, 1.05, 0.05),
            'xgb_reg__colsample_bytree': np.arange(0,1,0.05),
            'xgb_reg__colsample_bylevel': np.arange(0,1,0.05),
            'xgb_reg__colsample_bynode': np.arange(0,1,0.05)
            }
        self.outputLogger.log_trace('Model Parameters Defined')
    
    def train(self, trainFrac, maxTrainSize, testSize, numIter, path, modelName):
        
        self._splitIntoTestAndTrain(trainFrac)
        self.outputLogger.log_trace('Data Split into train and test')
            
        searchResults = self._defineCrossValProperties(maxTrainSize, testSize, numIter, self.pipe, self.param)
        self.outputLogger.log_debug('Cross Validation Properties Defined')
            
        # To run script quickly, comment out when doing Hyperparameter tuning
        # nEstimators = 159
        # xgbLambda = 0.11070741414515996
        # maxDepth = 2
        # learnRate = 0.093260334688322
        # alpha = 0.006013349774031784
        # subsample = 0.55
            
        n_components = searchResults.best_params_.get('pca__n_components')
        nEstimators = searchResults.best_params_.get('xgb_reg__n_estimators')
        xgbLambda = searchResults.best_params_.get('xgb_reg__reg_lambda')
        maxDepth = searchResults.best_params_.get('xgb_reg__max_depth')
        learnRate = searchResults.best_params_.get('xgb_reg__learning_rate')
        alpha = searchResults.best_params_.get('xgb_reg__reg_alpha')
        subsample = searchResults.best_params_.get('xgb_reg__subsample')
        colsample_bytree = searchResults.best_params_.get('xgb_reg__colsample_bytree')
        colsample_bylevel = searchResults.best_params_.get('xgb_reg__colsample_bylevel')
        colsample_bynode = searchResults.best_params_.get('xgb_reg__colsample_bynode')

        self.pipe.set_params(pca__n_components = n_components, 
                             xgb_reg__n_estimators = nEstimators,
                             xgb_reg__reg_lambda = xgbLambda,
                             xgb_reg__max_depth = maxDepth,
                             xgb_reg__learning_rate = learnRate,
                             xgb_reg__reg_alpha = alpha,
                             xgb_reg__subsample = subsample,
                             xgb_reg__colsample_bytree = colsample_bytree,
                             xgb_reg__colsample_bylevel = colsample_bylevel,
                             xgb_reg__colsample_bynode = colsample_bynode)
    
        explained_variance, mean_absolute_error, mse, r2, intervalRange = self._fitModel(maxTrainSize, 
                       testSize, 
                       self.pipe)
        self.outputLogger.log_debug('Model Sucessfully Fitted')
            
        fullpath = self._saveTrainedModel(path, 
                               modelName,
                               intervalRange)
        self.outputLogger.log_debug('Model Sucessfully Saved')

        return explained_variance, mean_absolute_error, mse, r2, fullpath
        
    def evaluate(self, basicityTarget, deadBand, silica_high, scilica_low, basicityMax, basicityMid, basicityDelta, modelPath=None):
        #TODO: Add functionality to cater when a modelPath isn't passed
        #Load model
        self.loadTrainedModel(modelPath)

        # Evaluate model
        #TODO: do something if model/fullDF is empty?
        predictions = {}
        rawBasicityPredictions = self.model.predict(self.fullDF[self.model.feature_names_in_])
        if len(rawBasicityPredictions) > 10: # Or some more meaningful value
            smoothBasicityPredictions = SimpleExpSmoothing(rawBasicityPredictions, initialization_method="heuristic").fit(
                smoothing_level=0.1, optimized=False)
            predictions['XGBoost Predicted Basicity'] = [smoothBasicityPredictions.fittedvalues[-1]]
            self.outputLogger.log_trace('Basicity calculated: {0}'.format(smoothBasicityPredictions.fittedvalues[-1]))
        else:
            predictions['XGBoost Predicted Basicity'] = [rawBasicityPredictions[-1]]
            self.outputLogger.log_trace('Few data points. Writing out raw Basicity values.')
           
        predictions = self._checkBasicity(predictions, basicityMax, basicityMid, basicityDelta)
        
        self.outputLogger.log_debug('Applying Silica Model')
        predictions['XGBoost Predicted Silica Support'] = self._applySilicaModel(predictions['XGBoost Predicted Basicity'], basicityTarget, deadBand, silica_high, scilica_low)

        
        # Generate model upper and lower bounds
        self.outputLogger.log_debug('Calculating lower and upper bounds of response')
        predictions['XGBoost Upper Predicted Basicity'] = predictions['XGBoost Predicted Basicity'] + self.intervalRange
        predictions['XGBoost Lower Predicted Basicity'] = predictions['XGBoost Predicted Basicity'] - self.intervalRange

        return predictions

    def test(self):
        pass
    
    def _checkBasicity(self, predictions, basicityMax, basicityMid, basicityDelta):
        predictions['BasicityDelta'] = [0]
        
        if math.isnan(basicityDelta) or self.fullDF.Basicity.iloc[-1] != self.fullDF.Basicity.iloc[-2]:
            basicityDelta = 0.0
        
        actualDelta = self.fullDF.Basicity.iloc[-1] - predictions['XGBoost Predicted Basicity'][-1]
        
        if all(self.fullDF.Basicity.iloc[-int(basicityMax['BasicityTimeMax']):] < basicityMax['BasicityLowMax']) or all(self.fullDF.Basicity.iloc[-int(basicityMax['BasicityTimeMax']):] > basicityMax['BasicityHighMax']):
            if abs(actualDelta) > basicityMax['BasicityThresholdMax']:
                self.outputLogger.log_warning('Predicted Basicity of {0} not meeting mid threshold, setting to measured value.'.format(predictions['XGBoost Predicted Basicity'][-1]))
                if abs(actualDelta) < abs(basicityDelta*2/3) or abs(actualDelta) > abs(basicityDelta*4/3):
                    self.outputLogger.log_warning('Basicity Delta changed to {0} from {1} due to the value approaching the measured value, resetting base value too'.format(actualDelta, basicityDelta))
                    predictions['XGBoost Predicted Basicity'][-1] = self.fullDF.Basicity.iloc[-1]
                    predictions['BasicityDelta'] = [actualDelta]
                else:
                    predictions['XGBoost Predicted Basicity'][-1] = predictions['XGBoost Predicted Basicity'][-1] + basicityDelta
                    predictions['BasicityDelta'] = [basicityDelta]
        elif all(self.fullDF.Basicity.iloc[-int(basicityMid['BasicityTimeMid']):] < basicityMid['BasicityLowMid']) or all(self.fullDF.Basicity.iloc[-int(basicityMid['BasicityTimeMid']):] > basicityMid['BasicityHighMid']):
            if abs(actualDelta) > basicityMid['BasicityThresholdMid']:
                self.outputLogger.log_warning('Predicted Basicity of {0} not meeting max threshold, setting to measured value.'.format(predictions['XGBoost Predicted Basicity'][-1]))
                if abs(actualDelta) < abs(basicityDelta*2/3) or abs(actualDelta) > abs(basicityDelta*4/3):
                    self.outputLogger.log_warning('Basicity Delta changed to {0} from {1} due to the value approaching the measured value, resetting base value too'.format(actualDelta, basicityDelta))
                    predictions['XGBoost Predicted Basicity'][-1] = self.fullDF.Basicity.iloc[-1]
                    predictions['BasicityDelta'] = [actualDelta]
                else:
                    predictions['XGBoost Predicted Basicity'][-1] = predictions['XGBoost Predicted Basicity'][-1] + basicityDelta
                    predictions['BasicityDelta'] = [basicityDelta]
        
        return predictions
    
    @staticmethod
    def getSpSiValues(parameters, predictions, outputs, smoothedBasicity, rawBasicity, log):
        
        if parameters['SpSiCountParam'] == 0:
            parameters['CumulativeSpSiParam'] = 0.0
        
        if parameters['SpSiCountParam'] < parameters['SpSiCountThreshold']:
            outputs['SpSiCount'] = [float(parameters['SpSiCountParam'] + 2.0)] # model runs every 2 minutes
            outputs['CumulativeSpSi'] = [float(parameters['CumulativeSpSiParam'] + outputs['DiffInSpSi'][-1])]
            outputs['SpSiSetpoint'] =  [float("nan")]
        else:
            outputs['SpSiCount'] = [0.0]
            outputs['CumulativeSpSi'] = [float(parameters['CumulativeSpSiParam'] + outputs['DiffInSpSi'][-1])]
            changeInRawBasicity = rawBasicity.diff()
            if changeInRawBasicity[-1] != 0:
                log.log_info('SpSi: New Basicity measurement')
                measuredDifferences = smoothedBasicity['Basicity'].diff()
                latestMeasurement = smoothedBasicity.iloc[-1].values[-1]
                timeDiff = smoothedBasicity.index.to_series().diff().dt.total_seconds()
                basicityGradient = measuredDifferences/timeDiff # Basicity/second
                
                if abs(basicityGradient.values[-1]) < parameters['basicityGradientThreshold'] and (latestMeasurement > 1.8 or latestMeasurement < 1.7): # Gradient defined more precisely - basicity change over expected sampling rate
                    log.log_info('SpSi: Gradient threshold failed - Aggressive control')
                    outputs['SpSiSetpoint'] = [float(parameters['SpSiSetpointParam']) + predictions['XGBoost Predicted Silica Support'][-1]]
                else:
                    log.log_info('SpSi: Gradient threshold met - Cumulative control')
                    outputs['SpSiSetpoint'] = [float(parameters['SpSiSetpointParam'] + outputs['CumulativeSpSi'][-1])]
            else:
                log.log_info('SpSi: No new Basicity measurements - Cumulative control')
                outputs['SpSiSetpoint'] = [float(parameters['SpSiSetpointParam'] + outputs['CumulativeSpSi'][-1])]
        return outputs