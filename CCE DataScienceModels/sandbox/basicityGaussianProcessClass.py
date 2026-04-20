# -*- coding: utf-8 -*-
"""
Created on Wed Dec  7 14:35:04 2022

@author: darshan.makan
"""

# import all packages and set plots to be embedded inline
import numpy as np
import matplotlib.pyplot as plt
from scipy.optimize import minimize
from scipy.optimize import Bounds
from pyDOE import lhs
from sklearn.preprocessing import MinMaxScaler
from sklearn.pipeline import Pipeline

#%% Initializing a Gaussian Process Model

class GaussianProcess:
    """A Gaussian Process class for creating and exploiting  
    a Gaussian Process model"""
    
    def __init__(self, n_restarts, optimizer):
        """Initialize a Gaussian Process model
        
        Input
        ------
        n_restarts: number of restarts of the local optimizer
        optimizer: algorithm of local optimization"""
        
        self.n_restarts = n_restarts
        self.optimizer = optimizer
        
    #Contstructing Correlation Matricies
    def Corr(self, X1, X2, theta):
        """Construct the correlation matrix between X1 and X2
        
        Input
        -----
        X1, X2: 2D arrays, (n_samples, n_features)
        theta: array, correlation legnths for different dimensions
        
        Output
        ------
        K: the correlation matrix
        """
        K = np.zeros((X1.shape[0],X2.shape[0]))
        for i in range(X1.shape[0]):
            K[i,:] = np.exp(-np.sum(theta*(X1[i,:]-X2)**2, axis=1))
            
        return K
    
    #Likeliood function
    def Neglikelihood(self, theta):
        """Negative likelihood function
        
        Input
        -----
        theta: array, logarithm of the correlation legnths for different dimensions
        
        Output
        ------
        LnLike: likelihood value"""
        
        theta = 10**theta    # Correlation length
        n = self.X.shape[0]  # Number of training instances
        one = np.ones((n,1))      # Vector of ones
        
        # Construct correlation matrix
        K = self.Corr(self.X, self.X, theta) + np.eye(n)*1e-10
        inv_K = np.linalg.inv(K)   # Inverse of correlation matrix
        
        # Mean estimation
        mu = (one.T @ inv_K @ self.y)/ (one.T @ inv_K @ one)
        
        # Variance estimation
        SigmaSqr = (self.y-mu*one).T @ inv_K @ (self.y-mu*one) / n
        
        # Compute log-likelihood
        DetK = np.linalg.det(K)
        LnLike = -(n/2)*np.log(SigmaSqr) - 0.5*np.log(DetK)
        
        # Update attributes
        self.K, self.inv_K , self.mu, self.SigmaSqr = K, inv_K, mu, SigmaSqr
        
        return -LnLike.flatten()
    
    def fit(self, X, y):
       """GP model training
       
       Input
       -----
       X: 2D array of shape (n_samples, n_features)
       y: 2D array of shape (n_samples, 1)
       """
       
       self.X, self.y = X, y
       lb, ub = -3, 2
       
       # Generate random starting points (Latin Hypercube)
       lhd = lhs(self.X.shape[1], samples=self.n_restarts)
       
       # Scale random samples to the given bounds 
       initial_points = (ub-lb)*lhd + lb
       
       # Create A Bounds instance for optimization
       bnds = Bounds(lb*np.ones(X.shape[1]),ub*np.ones(X.shape[1]))
       
       # Run local optimizer on all points
       opt_para = np.zeros((self.n_restarts, self.X.shape[1]))
       opt_func = np.zeros((self.n_restarts, 1))
       for i in range(self.n_restarts):
           res = minimize(self.Neglikelihood, initial_points[i,:], method=self.optimizer,
               bounds=bnds)
           opt_para[i,:] = res.x
           opt_func[i,:] = res.fun
       
       # Locate the optimum results
       self.theta = opt_para[np.argmin(opt_func)]
       
       # Update attributes
       self.NegLnlike = self.Neglikelihood(self.theta)
       
    def predict(self, X_test):
        """GP model predicting
        
        Input
        -----
        X_test: test set, array of shape (n_samples, n_features)
        
        Output
        ------
        f: GP predictions
        SSqr: Prediction variances"""
        
        n = self.X.shape[0]
        one = np.ones((n,1))
        
        # Construct correlation matrix between test and train data
        k = self.Corr(self.X, X_test, 10**self.theta)
        
        # Mean prediction
        f = self.mu + k.T @ self.inv_K @ (self.y-self.mu*one)
        
        # Variance prediction
        SSqr = self.SigmaSqr*(1 - np.diag(k.T @ self.inv_K @ k))
        
        return f.flatten(), SSqr.flatten()
       
    def score(self, X_test, y_test):
        """Calculate root mean squared error
        
        Input
        -----
        X_test: test set, array of shape (n_samples, n_features)
        y_test: test labels, array of shape (n_samples, )
        
        Output
        ------
        RMSE: the root mean square error"""
        
        y_pred, SSqr = self.predict(X_test)
        RMSE = np.sqrt(np.mean((y_pred-y_test)**2))
        
        return RMSE

#%% TEST1

def Test_1D(X):
    """1D Test Function"""
    
    y = (X*6-2)**2*np.sin(X*12-4)
    
    return y

# Training data
X_train = np.array([0.0, 0.1, 0.2, 0.4, 0.5, 0.6, 0.8, 1], ndmin=2).T
y_train = Test_1D(X_train)

# Testing data
X_test = np.linspace(0.0, 1, 100).reshape(-1,1)
y_test = Test_1D(X_test)

# GP model training
GP = GaussianProcess(n_restarts=10, optimizer='L-BFGS-B')
GP.fit(X_train, y_train)

# GP model predicting
y_pred, y_pred_SSqr = GP.predict(X_test)

#%% TEST 2

def Test_2D(X):
    """2D Test Function"""
    
    y = (1-X[:,0])**2 + 100*(X[:,1]-X[:,0]**2)**2
    
    return y

# Training data
sample_num = 25
lb, ub = np.array([-2, -1]), np.array([2, 3])
X_train = (ub-lb)*lhs(2, samples=sample_num) + lb
y_train = Test_2D(X_train).reshape(-1,1)

# Test data
X1 = np.linspace(-2, 2, 20)
X2 = np.linspace(-1, 3, 20)
X1, X2 = np.meshgrid(X1, X2)
X_test = np.hstack((X1.reshape(-1,1), X2.reshape(-1,1)))
y_test = Test_2D(X_test)

# GP model training
pipe = Pipeline([('scaler', MinMaxScaler()), 
         ('GP', GaussianProcess(n_restarts=10, optimizer='L-BFGS-B'))])
pipe.fit(X_train, y_train)

# GP model predicting
y_pred, y_pred_SSqr = pipe.predict(X_test)

# Accuracy score
pipe.score(X_test, y_test)

#%% Basicity model

import pandas as pd
import numpy as np
import datetime
import matplotlib.pyplot as plt
from statsmodels.tsa.api import SimpleExpSmoothing
from sklearn.linear_model import Lasso
from sklearn.decomposition import PCA
from sklearn.preprocessing import RobustScaler
from skopt import BayesSearchCV
from sklearn.model_selection import TimeSeriesSplit
from sklearn.pipeline import Pipeline
import pickle
import os


import Shared.DSModel.src.preprocessingFunctions as prep
import src.modellingFunctions as modelling
import src.dataExploration as visualise
from xgboost import XGBRegressor
from sklearn.model_selection import cross_val_score
import gpflow

#%% Read and Format Data
highFreqPredictors = ["Specific Oxygen Actual PV",
                      "Specific Silica Actual PV", "Matte feed PV filtered",
                      "Lance oxygen flow rate PV", "Lance air flow rate PV",
                      "Silica PV", "Matte transfer air flow", "Fuel coal feed rate PV"]

lowFreqPredictors = ["Fe Slag", "MgO Slag", "CaO Slag", "SiO2 Slag", "Al2O3 Slag",
                     "Ni Slag", "S Slag", "S Matte", "Slag temperatures",
                     "Matte temperatures", "Fe Feedblend", "S Feedblend",
                     "SiO2 Feedblend", "Al2O3 Feedblend", "CaO Feedblend",
                     "MgO Feedblend", "Cr2O3 Feedblend", "Corrected Ni Slag",
                     "Fe Matte"]

predictorTags = lowFreqPredictors + highFreqPredictors

responseTags = ["Basicity"]
referenceTags = ["Converter mode", "Lance air and oxygen control", "SumOfSpecies"]

fullDFOrig = prep.readAndFormatData('Chemistry')

#%%
def processingFunc(fullDFOrig):
    fullDF, origSmoothedResponses, predictorTagsNew = \
        prep.preprocessingAndFeatureEngineering(
            fullDFOrig,
            removeTransientData=True,
            smoothBasicityResponse=True,
            addRollingSumPredictors={'add': False, 'window': '19min'}, #NOTE: functionality exists to process an 'on' key
            addRollingMeanPredictors={'add': False, 'window': '5min'},
            addRollingMeanResponse={'add': True, 'window': '60min'},
            addDifferenceResponse = {'add': True},
            addMeasureIndicatorsAsPredictors={'add': True, 'on': ['Basicity', 'Fe Feedblend', 'Matte temperatures']}, #NOTE: functionality exists to process an 'on' key
            addShiftsToPredictors={'add': True, 'nLags': 3, 'on': highFreqPredictors},
            addResponsesAsPredictors={'add': True, 'nLags': 1},
            smoothTagsOnChange = {'add': True, 'on': ['Specific Silica Actual PV'], 'threshold': [70]},
            hoursOff = 8,
            nPeaksOff = 3,
            resampleTime = '1min',
            resampleMethod = 'linear',
            responseTags=responseTags,
            predictorTags=predictorTags,
            referenceTags=referenceTags,
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
    
#%% Split the data into training and testing data

predictors = pd.concat((predictorsTrain,predictorsTest))
responses = pd.concat((responsesTrain,responsesTest))

start_Date = datetime.datetime(2021,1,1,0,0)
end_Date = datetime.datetime(2021,1,2,0,0)
test_End_Date = datetime.datetime(2021,1,3,0,0)

X_train = predictors[start_Date:end_Date]
y_train = responses[start_Date:end_Date]

X_test = predictors[end_Date:test_End_Date]
y_test = responses[end_Date:test_End_Date]

# Feature selection

# select_features = ["Specific Oxygen Actual PV",
#                       "Specific Silica Actual PV", "Matte feed PV filtered",
#                       "Lance oxygen flow rate PV", "Lance air flow rate PV",
#                       "Silica PV",
#                       "Matte transfer air flow", "Fuel coal feed rate PV"]
select_features = ["1-Lag Basicity", "Fe Feedblend Measure Indicator", "Fe Matte", "Basicity differenced","Ni Slag", "Matte temperatures Measure Indicator", "SiO2 Slag", "1-Lag Specific Silica Actual PV"]
select_response = ["Basicity"]

trainPredictors = np.array(X_train[select_features])
responsesTrain = np.array(y_train[select_response])
testPredictors = np.array(X_test[select_features])
responseTest = np.array(y_test[select_response])

#%% gpFlow implementation of GPR

rng = np.random.default_rng(1234)
n_inducing = 750
inducing_variable = rng.choice(trainPredictors, size=n_inducing, replace=False)

model = gpflow.models.SGPR((trainPredictors,responsesTrain), kernel = gpflow.kernels.SquaredExponential(), inducing_variable=inducing_variable)
opt = gpflow.optimizers.Scipy()
opt.minimize(model.training_loss, model.trainable_variables)
    
y_mean, y_var = model.predict_y(testPredictors, full_cov=False)
y_lower = y_mean - 1.96 * np.sqrt(y_var)
y_upper = y_mean + 1.96 * np.sqrt(y_var)

#%% Visualize results

predictions = y_test.copy()
predictions['y_mean'] = np.array(y_mean)

plt.plot(predictions)