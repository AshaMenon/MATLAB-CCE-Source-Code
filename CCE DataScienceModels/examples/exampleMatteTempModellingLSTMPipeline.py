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
from keras.models import Sequential
from keras.layers import Dense
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras.callbacks import EarlyStopping, ModelCheckpoint

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

#%% Split Data

fullDF = fullDF[fullDF.index < endTime]    
predictorsTrain, responsesTrain, origResponsesTrain, predictorsTest, responsesTest, origResponsesTest = \
    prep.splitIntoTestAndTrain(
    fullDF,
    trainFrac=0.85,
    resampleTime='30min',
    predictorTags=predictorTags,
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
    'estimator__layer1': np.arange(10, 500),
    'estimator__layer2': np.arange(50, 500),
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

# fix random seed for reproducibility
np.random.seed(7)

# nEstimators = searchResults.best_params_.get('randomForest__n_estimators')
# nComponents = searchResults.best_params_.get('pca__n_components')
# gamma = searchResults.best_params_.get('pca__gamma')
# layer1 = searchResults.best_params_.get('estimator__layer1')
# layer2 = searchResults.best_params_.get('estimator__layer2')
# batchSize = searchResults.best_params_.get('estimator__batchSize')
# eps = searchResults.best_params_.get('estimator__epsilon')
# maxIter = searchResults.best_params_.get('estimator__max_iter')

# To run script quickly, comment out when doing Hyperparameter tuning

layer1 = 500
layer2 = 100
nComponents = 627
gamma = 1e-05
# batchSize = 271
# eps = 1e-08
# maxIter = 5000

pca = KernelPCA(n_components = nComponents,
                kernel = 'rbf', gamma = gamma)

# create and fit the LSTM network

#Early stop monitoring set so that model stops training when there's no more improvement
early_stopping_monitor = EarlyStopping(monitor='loss',mode='min', patience=200, verbose = 1)
mc = ModelCheckpoint('lstm1',  monitor='loss', mode='min', verbose=1, save_best_only=True)

scaler = StandardScaler()
scaledPredictorsTrain = scaler.fit_transform(predictorsTrain)
scaledPredictorsTest = scaler.transform(predictorsTest)

pcaPredictorsTrain = pca.fit_transform(scaledPredictorsTrain)
pcaPredictorsTest = pca.transform(scaledPredictorsTest)

xTrain = pcaPredictorsTrain
yTrain = responsesTrain.values.ravel()

xTest = pcaPredictorsTest
yTest = responsesTest.values.ravel()

trainX = np.reshape(xTrain, (xTrain.shape[0], 1, xTrain.shape[1]))
testX = np.reshape(xTest, (xTest.shape[0], 1, xTest.shape[1]))

#Build Model
model = Sequential()

#get number of columns in training data
n = trainX.shape[1]
i = trainX.shape[2]
#add model layers
model = keras.Sequential([
#keras.layers.Embedding(output_dim = 20, input_dim=(i)),
keras.layers.LSTM(layer1, input_shape=(n, i), return_sequences = 'true'),
keras.layers.LSTM(layer2),
keras.layers.Dropout(0.2),   
keras.layers.Dense(1, activation = 'relu')
])

#Compile Model
opt =keras.optimizers.Adam(learning_rate = 0.001, beta_1 = 0.999, beta_2 = 0.999)
model.compile(optimizer= 'adam', loss='mean_squared_error')

# Train Model
# loss_history = mdl.fit(predictorsTrain,responsesTrain.values.ravel(), 
#                        estimator__epochs=1200, estimator__batch_size = 2)

# Load saved model to save time
model1 = tf.keras.models.load_model('lstm1')
yHatTest = model1.predict(testX)
modelling.regression_results(yTest, yHatTest)

yHatTrain = model1.predict(trainX)

testResults = pd.DataFrame(index = predictorsTest.index)
testResults['yActual'] = yTest
testResults['yHat'] = yHatTest

trainResults = pd.DataFrame(index = predictorsTrain.index)
trainResults['yActual'] = yTrain
trainResults['yHat'] = yHatTrain

#%% Results Visualisation

visualise.plotActualVsPredicted(trainResults, testResults, (1125, 1400), "LSTM Model - Matte Temperatures")

visualise.plotTimeSeriesResults(testResults, origResponsesTest, "LSTM - Matte Temperatures (Test Results)")

visualise.plotTimeSeriesResults(trainResults, origResponsesTrain, "LSTM - Matte Temperatures (Train Results)")

visualise.plotResidualsAndErrors(trainResults, testResults)

#%% Feature Importance
# Forest Model built in feature importance

# modelling.getFeatureImportance(mdl, predictorsTest, predictorsTest.columns, 'NN')

# explainer = shap.KernelExplainer(model.predict, testX)
# shap_values = explainer.shap_values(testX,nsamples=100)
# shap.summary_plot(shap_values,features =  predictorsTest, 
#                       feature_names = predictorsTest.columns, plot_type=('bar'))
