# -*- coding: utf-8 -*-
"""
Created on Tue Apr 19 14:23:41 2022

@author: antonio.peters
"""

import sys
# Model Specific packages
from sklearn.pipeline import Pipeline
from sklearn.decomposition import PCA
from sklearn.preprocessing import RobustScaler
from sklearn.linear_model import LinearRegression
import numpy as np
from Shared.DSModel.Model import Model

class LinearBasicityModel(Model):

    def __init__(self, fullDF, predictorTags, responseTags, origSmoothedResponses, logger=None):

        super().__init__(fullDF, predictorTags, responseTags, origSmoothedResponses, outputLogger=logger)

        self.pipe = Pipeline([('scaler', RobustScaler()),
                         ('pca', PCA()),
                         ('regression', LinearRegression())])

        self.param = {
            'pca__n_components': np.arange(1, len(predictorTags)+1, 1),
            # 'regression__alpha': np.logspace(-10, 2, 5000),
            }
        
        
    
    def train(self, trainFrac, maxTrainSize, testSize, numIter, path, modelName):
        
        self._splitIntoTestAndTrain(trainFrac)
        if (self.outputLogger is not None):
            self.outputLogger.log_trace('Data Split into train and test')

        searchResults = self._defineCrossValProperties(maxTrainSize, testSize, numIter, self.pipe, self.param)
        if (self.outputLogger is not None):
            self.outputLogger.log_debug('Cross Validation Properties Defined')
            self.outputLogger.log_debug('Best Estimator Found')

        self.pipe = searchResults.best_estimator_

        explained_variance, mean_absolute_error, mse, r2 = self._fitModel(maxTrainSize,
                                                                          testSize,
                                                                          self.pipe)
        if (self.outputLogger is not None):
            self.outputLogger.log_debug('Model Sucessfully Fitted')

        fullpath = self._saveTrainedModel(path,
                                          modelName,
                                          explained_variance,
                                          mean_absolute_error,
                                          mse,
                                          r2)
        if (self.outputLogger is not None):
            self.outputLogger.log_debug('Model Sucessfully Saved')

        return explained_variance, mean_absolute_error, mse, r2, fullpath
        
    def evaluate(self, modelPath=None):
        #TODO: Add functionality to cater when a modelPath isn't passed
        #Load model
        self.loadTrainedModel(modelPath)

        # Evaluate model
        #TODO: do something if model/fullDF is empty?
        predictions = self.model.predict(self.fullDF[self.predictorTags])

        return predictions



    def test(self):
        pass