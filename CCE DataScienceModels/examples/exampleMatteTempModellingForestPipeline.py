# -*- coding: utf-8 -*-
import numpy as np
from sklearn.ensemble import RandomForestRegressor
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import TimeSeriesSplit
from sklearn.pipeline import Pipeline
import src.preprocessingFunctions as prep
import src.modellingFunctions as modelling
from skopt import BayesSearchCV
import src.dataExploration as visualise
from sklearn.decomposition import KernelPCA

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

fullDF, origSmoothedResponses, predictorTagsNew = \
    prep.preprocessingAndFeatureEngineering(
        fullDFOrig,
        responseTags=responseTags,
        predictorTags=predictorTags,
        resampleTime='30min',
        resampleMethod='cubic',
        removeTransientData=True,
        addRollingSumPredictors={'add': True, 'window': 30}, #NOTE: You can use an 'on' key to define which vars this needs to be applied to
        smoothBasicityResponse=False,
        addResponsesAsPredictors={'add': True, 'nLags': 1},
        addMeasureIndicatorsAsPredictors={'add': True, 'on': ["Matte temperatures"]},
        addShiftsToPredictors={'add': False, 'numberOfShifts': 2} #NOTE: You can use an 'on' key to define which vars this needs to be applied to
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

pipe = Pipeline([('scaler', StandardScaler()), ('pca', KernelPCA(kernel = 'rbf')),
                  ('randomForest', RandomForestRegressor())])

param = {
    # 'pca__n_components': np.arange(10,30),
    'randomForest__n_estimators': np.arange(10, 100), 
    'randomForest__min_samples_split': np.arange(10, 70),
    'randomForest__min_samples_leaf': np.arange(10, 70),
    'randomForest__max_depth': np.arange(10, 80),
    'pca__n_components': np.arange(20, 4000),
    'pca__gamma': np.logspace(-7, 2, num = 100),}

opt = BayesSearchCV(pipe, param, n_iter=20, random_state=0, cv = tscv, 
                    scoring = 'r2',n_jobs =2, verbose = 10)

# executes bayesian optimization
# searchResults = opt.fit(predictorsTrain, responsesTrain)

#%% Train model with optimised parameters

# nEstimators = searchResults.best_params_.get('randomForest__n_estimators')
# minSamplesSplit = searchResults.best_params_.get('randomForest__min_samples_split')
# minSamplesLeaf = searchResults.best_params_.get('randomForest__min_samples_leaf')
# maxDepth = searchResults.best_params_.get('randomForest__max_depth')
# nComponents = searchResults.best_params_.get('pca__n_components')
# gamma = searchResults.best_params_.get('pca__gamma')

# To run script quickly, comment out when doing Hyperparameter tuning

nEstimators = 51
minSamplesSplit = 39
minSamplesLeaf = 21
maxDepth = 39
nComponents = 1012
gamma = 0.00023101297000831605

pca = KernelPCA(n_components = nComponents,
                kernel = 'rbf', gamma = gamma)

forestMdl = RandomForestRegressor(n_estimators =nEstimators,
                                min_samples_split = minSamplesSplit,
                                min_samples_leaf = minSamplesLeaf,
                                max_depth=maxDepth, random_state = 0)

scaler = StandardScaler()
scaledPredictorsTrain = scaler.fit_transform(predictorsTrain)
scaledPredictorsTest = scaler.transform(predictorsTest)

pcaPredictorsTrain = pca.fit_transform(scaledPredictorsTrain)
pcaPredictorsTest = pca.transform(scaledPredictorsTest)

pcaPredictorsTrain = scaledPredictorsTrain
pcaPredictorsTest = scaledPredictorsTest

xTrain = pcaPredictorsTrain
yTrain = responsesTrain.values.ravel()

xTest = pcaPredictorsTest
yTest = responsesTest.values.ravel()

[forestMdl, testResults] = modelling.trainAndTestModel(forestMdl, xTrain, yTrain,
                                                        xTest, yTest, predictorsTest.index)
trainResults = modelling.testModel(forestMdl, xTrain, yTrain, predictorsTrain.index)

#%% Results Visualisation

visualise.plotActualVsPredicted(trainResults, testResults, (1125, 1400), "Forest Model - Matte Temperatures")

visualise.plotTimeSeriesResults(testResults, origResponsesTest, "Forest Model - Matte Temperatures (Test Results)")

visualise.plotTimeSeriesResults(trainResults, origResponsesTrain, "Forest Model - Matte Temperatures (Train Results)")

visualise.plotResidualsAndErrors(trainResults, testResults)

convergenceIndicator, convergingPeriod, divergingPeriod = \
    modelling.getDirectionalPerformance(origResponsesTest, testResults)

visualise.plotDirectionalPerformance(origResponsesTest, testResults, convergenceIndicator, "Forest Model - Matte Temperatures (Test Results)")

convergingPeriod/(convergingPeriod + divergingPeriod)
    
#%% Feature Importance
# Forest Model built in feature importance

# modelling.getFeatureImportance(forestMdl, predictorsTest.values, predictorsTest.columns, 'Random Forest')
