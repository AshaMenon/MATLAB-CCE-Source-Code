# -*- coding: utf-8 -*-

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from sklearn.ensemble import RandomForestRegressor
from sklearn.decomposition import PCA
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import TimeSeriesSplit
from sklearn.pipeline import Pipeline
import src.preprocessingFunctions as prep
import src.modellingFunctions as modelling
from skopt import BayesSearchCV
import src.dataExploration as visualise
from sklearn.decomposition import KernelPCA
import shap
import src.featureEngineeringHelpers as featEng
from sklearn.neural_network import MLPRegressor
from sklearn.base import BaseEstimator, RegressorMixin

#%% Read and Format Data

predictorTags = ["Fuel coal feed rate PV", "Matte feed PV",
                "Specific Oxygen Actual PV", "Lance oxygen flow rate PV",
                "Matte transfer air flow", "Lance air flow rate PV",
                "Lance coal carrier air","Silica PV",
                "Lance air & oxygen control",
                "Slag temperatures",
                 "Lower waffle 21", 
                 "Upper hearth 98"]

responseTags = ['Matte temperatures']
referenceTags = ["Lance Oxy Enrich % PV", "SumOfSpecies", "Converter mode"]

fullDFOrig = prep.readAndFormatData('Temperature', responseTags=responseTags,
                                    predictorTags=predictorTags, referenceTags=referenceTags)

fullDF, origSmoothedResponses, predictorTagsNew = prep.preprocessingAndFeatureEngineering(
        fullDFOrig,
        responseTags=responseTags,
        predictorTags=predictorTags,
        removeTransientData=True,
        resampleTime='30min',
        resampleMethod='cubic',
        addRollingSumPredictors={'add': True, 'window': 30},
        smoothBasicityResponse=False,
        addResponsesAsPredictors={'add': True, 'nLags': 1},
        addMeasureIndicatorsAsPredictors={'add': True, 'on': ["Matte temperatures"]},
        addShiftsToPredictors={'add': False, 'nLags': 2}
    )

startTime = origSmoothedResponses.index[np.argmax(np.diff(origSmoothedResponses.index))]
endTime = origSmoothedResponses.index[np.argmax(np.diff(origSmoothedResponses.index))+1]
mask = (fullDF.index <= startTime) | (fullDF.index > endTime)
fullDF = fullDF.loc[mask]

#%% Split Data

predictorsTrain, responsesTrain, origResponsesTrain, predictorsTest, responsesTest, origResponsesTest = \
    prep.splitIntoTestAndTrain(
    fullDF,
    origSmoothedResponses,
    trainFrac=0.85,
    predictorTags=predictorTagsNew,
    responseTags=responseTags
)

#%% Random Search Cross Validation

maxTrainSize = 30*24*2
testSize = 7*24*2
nSplits = int(np.ceil((len(predictorsTrain) - maxTrainSize)/testSize))
tscv = TimeSeriesSplit(n_splits = nSplits, max_train_size = maxTrainSize,
                       test_size = testSize)


class MLPWrapper(BaseEstimator, RegressorMixin):
    def __init__(self, layer1=10, layer2=10, layer3=10, batchSize = 250, 
                 epsilon = 1e-8, max_iter = 1000):
        self.layer1 = layer1
        self.layer2 = layer2
        self.layer3 = layer3
        self.batchSize = batchSize
        self.epsilon = epsilon
        self.max_iter = max_iter

    def fit(self, X, y):
        model = MLPRegressor(
            hidden_layer_sizes=[self.layer1, self.layer2, self.layer3], 
            activation="relu" ,random_state=1, max_iter=self.max_iter,
            batch_size = self.batchSize, early_stopping = True, epsilon = self.epsilon
        )
        model.fit(X, y)
        self.model = model
        return self

    def predict(self, X):
        return self.model.predict(X)

    def score(self, X, y):
        return self.model.score(X, y)

pipe = Pipeline([('scaler', StandardScaler()), ('pca', KernelPCA(kernel = 'rbf')),
                  ('estimator', MLPWrapper())])

param = {
    # 'pca__n_components': np.arange(10,30),
    # 'learning_rate_init': np.arange(0.001, 0.05),
    'estimator__layer1': np.arange(10, 200),
    'estimator__layer2': np.arange(50, 500),
    'estimator__layer3': np.arange(10, 100),
    'estimator__batchSize': np.arange(50, 1000),
    'estimator__epsilon': np.arange(1e-8, 0.1),
    'estimator__max_iter': np.arange(1000, 10000),
    'pca__n_components': np.arange(20, 4000),
    'pca__gamma': np.logspace(-7, 2, num = 100)
    }

opt = BayesSearchCV(pipe, param, n_iter=20, random_state=0, cv = tscv, 
                    scoring = 'r2',n_jobs =2, verbose = 10)

# executes bayesian optimization
# searchResults = opt.fit(predictorsTrain, responsesTrain)

#%% Train model with optimised parameters

# nEstimators = searchResults.best_params_.get('randomForest__n_estimators')
# nComponents = searchResults.best_params_.get('pca__n_components')
# gamma = searchResults.best_params_.get('pca__gamma')
# layer1 = searchResults.best_params_.get('estimator__layer1')
# layer2 = searchResults.best_params_.get('estimator__layer2')
# layer3 = searchResults.best_params_.get('estimator__layer3')
# batchSize = searchResults.best_params_.get('estimator__batchSize')
# eps = searchResults.best_params_.get('estimator__epsilon')
# maxIter = searchResults.best_params_.get('estimator__max_iter')

# To run script quickly, comment out when doing Hyperparameter tuning

layer1 = 184
layer2 = 192
layer3 = 45
layer4 = 20
nComponents = 627
gamma = 1e-05
batchSize = 271
eps = 1e-08
maxIter = 5000

pca = KernelPCA(n_components = nComponents,
                kernel = 'rbf', gamma = gamma)

mdl = MLPRegressor(hidden_layer_sizes=(layer1, layer2, layer3),activation="relu" ,
                   random_state=0, max_iter=maxIter, shuffle = False, 
                   batch_size = batchSize, early_stopping = True, epsilon = eps,
                   learning_rate_init = 0.01)

scaler = StandardScaler()
scaledPredictorsTrain = scaler.fit_transform(predictorsTrain)
scaledPredictorsTest = scaler.transform(predictorsTest)

pcaPredictorsTrain = pca.fit_transform(scaledPredictorsTrain)
pcaPredictorsTest = pca.transform(scaledPredictorsTest)

xTrain = pcaPredictorsTrain
yTrain = responsesTrain.values.ravel()

xTest = pcaPredictorsTest
yTest = responsesTest.values.ravel()

[mdl, testResults] = modelling.trainAndTestModel(mdl, xTrain, yTrain,
                                                        xTest, yTest, predictorsTest.index)
trainResults = modelling.testModel(mdl, xTrain, yTrain, predictorsTrain.index)

#%% Results Visualisation

visualise.plotActualVsPredicted(trainResults, testResults, (1125, 1400), "NN Model - Matte Temperatures")

visualise.plotTimeSeriesResults(testResults, origResponsesTest, "NN Model - Matte Temperatures (Test Results)")

visualise.plotTimeSeriesResults(trainResults, origResponsesTrain, "NN Model - Matte Temperatures (Train Results)")

visualise.plotResidualsAndErrors(trainResults, testResults)

convergenceIndicator, convergingPeriod, divergingPeriod = \
    modelling.getDirectionalPerformance(origResponsesTest, testResults)

visualise.plotDirectionalPerformance(origResponsesTest, testResults, convergenceIndicator, "Forest Model - Basicity (Test Results)")

convergingPeriod/(convergingPeriod + divergingPeriod)

#%% Feature Importance
# Forest Model built in feature importance

# modelling.getFeatureImportance(mdl, predictorsTest, predictorsTest.columns, 'NN')

# explainer = shap.KernelExplainer(mdl.predict, predictorsTest)
# shap_values = explainer.shap_values(predictorsTest,nsamples=10)
# shap.summary_plot(shap_values,features =  predictorsTest, 
#                       feature_names = predictorsTest.columns, plot_type=('bar'))