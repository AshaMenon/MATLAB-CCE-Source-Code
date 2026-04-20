# -*- coding: utf-8 -*-
"""
Created on Wed Jul 13 09:21:11 2022

@author: antonio.peters
"""

from Shared.DSModel.Model import Model
from sklearn.model_selection import train_test_split, KFold, cross_val_score
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import RobustScaler
from sklearn.preprocessing import PolynomialFeatures
from sklearn.linear_model import PoissonRegressor
from sklearn.metrics import mean_squared_error, r2_score
import numpy as np
from skopt import BayesSearchCV
from math import sqrt   
import pandas as pd 

class SPO2Model(Model):
    
    def __init__(self, fullDF, predictorTags, responseTags, origSmoothedResponses, logger):
        super().__init__(fullDF, predictorTags, responseTags, origSmoothedResponses, outputLogger=logger)
        
                     
        
    def train(self,path,modelName, thermoDF):
        thermoMdl, thermoMdlStats, X_test, y_test = self._trainThermoModel(thermoDF)
        self.model = thermoMdl
        if (self.outputLogger is not None):
            self.outputLogger.log_debug('Thermo Model Trained')
            
        fullpath = self._saveTrainedModel(path, modelName)
        
        return fullpath, thermoMdlStats
        
    def evaluate(self,modelPath,NiSlagTarget,
                 thresholdParam,subtractionParam,multiplierParam,
                 setFeMatteTarget,PSO2_const,deadBand):
        
        if NiSlagTarget > 0:
            thermoMdl = NiSlagTarget
            self.outputLogger.log_debug('Target Ni slag provided, thermo model not loaded')
            
        else:
            self.loadTrainedModel(modelPath)
            thermoMdl = self.model
            self.outputLogger.log_debug('Thermo model loaded')
            self._calculateCorrNiSlag(thresholdParam,subtractionParam,multiplierParam)
            self.outputLogger.log_debug('Ni Slag corrected')
          
        requiredChangeInSpO2, theoreticalNiSlagPredictions, corrNiSlag = self._applySpO2Model(thermoMdl,setFeMatteTarget,PSO2_const,deadBand)
        self.outputLogger.log_debug('SPO2 calculated')
        
        return requiredChangeInSpO2, theoreticalNiSlagPredictions, corrNiSlag
    
    def test(self):
        pass
    
    #%% Private Functions
    def _trainThermoModel(self, thermoDF):            
        '''
        -   Trains thermodynamic model using ideal thermodynamic data
        -   to write the terms of the final equation to a speadsheet, 
            set writeTermsToSpreadsheet = True
        -   for deployment
        '''
        
        thermoDF = thermoDF.drop_duplicates()
        predictorTags = ['Fe Matte','Basicity','Matte temperatures', 'PSO2']
        responseTag = ['Ni Slag']
    
        # Test-train split
        X = thermoDF[predictorTags]
        Y = thermoDF[responseTag]
        X_train, X_test, y_train, y_test = train_test_split(X, Y, test_size=0.3, random_state=42)
        if (self.outputLogger is not None):
            self.outputLogger.log_debug('Data split into test and train')
    
        # Build pipeline
        tscv = KFold(n_splits = 10, shuffle = True)
    
        pipe = Pipeline(
                [
                     ('scaler',RobustScaler()),
                     ('preprocessor', PolynomialFeatures()),
                     ('regressor', PoissonRegressor())
                 ]
        )
    
        param = {
                    'preprocessor__degree': np.linspace(1, 2, 2, dtype = 'int'),
                    'regressor__alpha': np.logspace(-7, 1, num = 1000)
        }
        
        if (self.outputLogger is not None):
            self.outputLogger.log_debug('Pipeline defined')
            
        # Refit the model
        randomSearch = BayesSearchCV(estimator = pipe, search_spaces = param, 
                                         n_iter = 50, cv = tscv,verbose = 5, 
                                         scoring = 'neg_root_mean_squared_error', 
                                         refit = True)
        
        searchResults = randomSearch.fit(X_train, np.ravel(y_train.values))

        pipe_updated = searchResults.best_estimator_
    
        # Fit model
        thermoMdl = pipe_updated.fit(X_train,np.ravel(y_train.values))
             
        # Get predictions using model
        # No need to use cross_val_score - we are not training/cross validating anything
        ytest_hat = thermoMdl.predict(X_test) 
    
        # Calculate metrics and terms of equation
        scaler = RobustScaler()
        scaledPredictors = scaler.fit_transform(X_train)
        degree = searchResults.best_params_.get('preprocessor__degree')
        poly = PolynomialFeatures(degree=degree, include_bias=True)
        scaledPredictors = poly.fit_transform(scaledPredictors)
        alpha = searchResults.best_params_.get('regressor__alpha')
        thermoMdl_forTerms = PoissonRegressor(alpha = alpha)
        thermoMdl_forTerms = thermoMdl_forTerms.fit(scaledPredictors, y_train.values.ravel())
    
        rmse = sqrt(mean_squared_error(y_test.values, ytest_hat))
        r2_outOfSample = r2_score(y_test.values, ytest_hat)
        crossValScore = cross_val_score(pipe_updated, X_test, np.ravel(y_test.values), cv = tscv)
        r2_crossVal = np.mean(crossValScore)
        
        if (self.outputLogger is not None):
             self.outputLogger.log_debug('Thermo metric and terms calculated')
    
        # Terms
        terms = PolynomialFeatures.get_feature_names(poly)
        terms = [w.replace('x0', ' ⋅ FeMatte') for w in terms]
        terms = [w.replace('x1', ' ⋅ B') for w in terms]
        terms = [w.replace('x2', ' ⋅ T') for w in terms]
        terms = [w.replace('x3', ' ⋅ PSO2') for w in terms]
    
        # Get metrics
        thermoMdlStats = {
            'RMSE' : rmse,
            'R2 test' : r2_outOfSample,
            'R2 cross-val' : r2_crossVal,
            'Polynomial degree' : degree,
            'Poisson alpha' : alpha,
            'Number of terms' : len(terms)
            }
        
        return thermoMdl, thermoMdlStats, X_test, y_test
    
    def _calculateCorrNiSlag(self,thresholdParam,subtractionParam,multiplierParam):
        
        '''
        -   Using format of existing Ni Slag correction, apply an updated correction
            using three parameters (subtraction, multiplier, threshold)
        -   for deployment
        '''
        
        if self.fullDF['S Slag'] > thresholdParam: 
            self.fullDF['S Slag'] = thresholdParam
            
        self.fullDF['Corrected Ni Slag'] = self.fullDF['Ni Slag'] - (self.fullDF['S Slag'] - subtractionParam) * multiplierParam
    
    def _applySpO2Model(self, thermoMdl,setFeMatteTarget,PSO2_const,deadBand):
        
        corrNiSlag = self.fullDF['Corrected Ni Slag']
        
        if isinstance(thermoMdl, float):
            theoreticalNiSlagPredictions = thermoMdl
        else:
            theoreticalNiSlagPredictions, _ = self._takeNewValuesAndPredictNi(thermoMdl, 1, setFeMatteTarget,PSO2_const)

        
        lowRange, highRange, f = self._getSpO2(theoreticalNiSlagPredictions,deadBand)
        
        if corrNiSlag < theoreticalNiSlagPredictions:
            requiredChangeInSpO2 = f(corrNiSlag, lowRange['coeffs'])
        else:
            requiredChangeInSpO2 = f(corrNiSlag, highRange['coeffs'])
            
        return requiredChangeInSpO2, theoreticalNiSlagPredictions, corrNiSlag
    
    def _takeNewValuesAndPredictNi(self, thermoMdl, newArrayLength, setFeMatteTarget,PSO2_const):
        
        '''
        -   Predict new predictions for theoretical Ni Slag using thermo model
        '''
        
        if (setFeMatteTarget == True):
            FeMatte = np.ones((newArrayLength)) * 3
        else:
            FeMatte = np.linspace(0,10,newArrayLength)
            
        PSO2 = np.ones((newArrayLength)) * PSO2_const
       
        temperatures = np.ones((newArrayLength)) * self.fullDF['Matte temperatures']
        basicity = np.ones((newArrayLength)) * self.fullDF['Basicity']
            
        arr = np.column_stack((FeMatte, 
                               basicity,
                               temperatures,
                               PSO2
                               ))
        newDF = pd.DataFrame(arr,columns=['Fe Matte','Basicity','Matte temperatures', 'PSO2'])
        
        theoreticalNiSlagPredictions = thermoMdl.predict(newDF)
    
        return theoreticalNiSlagPredictions, newDF    
    
    def _getSpO2(self, NiSlagTarget,deadBand):
        
        '''
        -   the SpO2 model outputs different results depending on which part
            of the SpO2 curve you are on (below/above the Ni Slag target).
            Shown here as low range vs high range
        -   for deployment
        '''
        
        lowRangeCorrNi = np.linspace(0, NiSlagTarget, 10)
        highRangeCorrNi = np.linspace(NiSlagTarget, 10, 10)
        
        # Low range
        baseData = np.array([0, 2, 3])
        Ni = baseData + NiSlagTarget - deadBand/2 - np.max(baseData)
        oxy = np.array([14, 6, 0])
        lowRangeCoeffs = np.polyfit(Ni, oxy, 2)
        f = lambda x, coeffs : coeffs[0] * x**2 + coeffs[1] * x + coeffs[2]
        lowRangeOxy = f(lowRangeCorrNi, lowRangeCoeffs)

        # High range
        baseData = np.array([4, 5.53, 10])
        Ni = baseData + NiSlagTarget - deadBand/2 - np.min(baseData)
        oxy = np.array([0, -4.7, -12])
        highRangeCoeffs = np.polyfit(Ni, oxy, 2)
        highRangeOxy = f(highRangeCorrNi, highRangeCoeffs)
        
        
        lowRange = {'corrNi' : lowRangeCorrNi,
                    'oxy' : lowRangeOxy,
                    'coeffs' : lowRangeCoeffs,
            }
        
        highRange = {'corrNi' : highRangeCorrNi,
                    'oxy' : highRangeOxy,
                    'coeffs' : highRangeCoeffs,
            }
        
        return lowRange, highRange, f
