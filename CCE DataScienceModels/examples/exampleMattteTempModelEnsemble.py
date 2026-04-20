import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import scipy.stats as stats
import xgboost as xgb

from sklearn.preprocessing import RobustScaler
from sklearn.decomposition import PCA
from sklearn.preprocessing import PolynomialFeatures
from skopt import BayesSearchCV
from sklearn.model_selection import TimeSeriesSplit
from sklearn.pipeline import Pipeline
from sklearn.linear_model import Lasso
from sklearn.linear_model import Ridge
from sklearn.linear_model import PoissonRegressor
from sklearn.feature_selection import SelectKBest
from sklearn.feature_selection import mutual_info_regression
from sklearn.feature_selection import SelectFromModel
from sklearn.ensemble import RandomForestRegressor
from sklearn.covariance import EmpiricalCovariance
from sklearn.base import BaseEstimator


import src.preprocessingFunctions as prep
import src.modellingFunctions as modelling
import src.dataExploration as visualise
import src.featureEngineeringHelpers as featEng

# %% Define ensemble estimator
class VarianceEnsembleEstimator(BaseEstimator):
    
    def __init__(self, estimators):
        
        self._estimator_type = "regressor"
        self.estimators = estimators
    
    def fit(self, X, y):
        
        residue_matrix = np.zeros(shape=(X.shape[0], len(self.estimators)))
        
        for i in range(len(self.estimators)):
            
            y_pred = self.estimators[i].predict(X)
            residue = y - y_pred
            
            residue_matrix[:, i] = residue.ravel()
            
        cov = EmpiricalCovariance().fit(residue_matrix)
        
        var = cov.covariance_.diagonal()
        
        self.coef_ = var/sum(var)
        self.var = np.matmul((self.coef_)**2, np.sqrt(var))
        
        return self
        
    
    def predict(self, X, confidence_interval = 0.75):
        
        z_score = stats.norm.ppf((1 + confidence_interval)/2)
        
        pred_matrix = np.zeros(shape=(X.shape[0], len(self.estimators)))
        
        for i in range(len(self.estimators)):
            
            y_pred = self.estimators[i].predict(X)
            
            pred_matrix[:, i] = y_pred.ravel()
        
        y_pred = np.matmul(pred_matrix, self.coef_)
        y_lower = y_pred - z_score*self.var
        y_upper = y_pred + z_score*self.var
        
        return y_lower, y_pred, y_upper

#%% Read and format data

highFreqPredictors = ["Matte feed PV", "Fuel coal feed rate PV", "Specific Oxygen Actual PV",
                      "Reverts feed rate PV",
                      "Lump coal PV", "Lance oxygen flow rate PV", "Lance air flow rate PV",
                      "Matte transfer air flow", "Lance coal carrier air",
                      "Silica PV",
                      "Lower waffle 19", "Lower waffle 20", "Lower waffle 21",
                      "Lower waffle 22", "Lower waffle 23", "Lower waffle 24",
                      "Lower waffle 25", "Lower waffle 26", "Lower waffle 27",
                      "Lower waffle 28", "Lower waffle 29", "Lower waffle 30",
                      "Lower waffle 31", "Lower waffle 32", "Lower waffle 33",
                      "Lower waffle 34", "Outer long 1", "Middle long 1",
                      "Outer long 2", "Middle long 2", "Outer long 3",
                      "Middle long 3", "Outer long 4", "Middle long 4",
                      "Centre long", "Lance Oxy Enrich % PV", "Roof matte feed rate PV",
                      "Lance height", "Lance motion"]

lowFreqPredictors = ["Cr2O3 Slag", "Basicity", "MgO Slag", "Slag temperatures"]

feedblendPredictors = ["Cu Feedblend", "Ni Feedblend",
                       "Co Feedblend", "Fe Feedblend", "S Feedblend",
                       "SiO2 Feedblend", "Al2O3 Feedblend", "CaO Feedblend",
                       "MgO Feedblend", "Cr2O3 Feedblend"]

# lowFreqPredictors = lowFreqPredictors + feedblendPredictors

predictorTags = highFreqPredictors + lowFreqPredictors

responseTags = ['Matte temperatures']

fullDFOrig = prep.readAndFormatData('Temperature', responseTags=responseTags,
        predictorTags=predictorTags)

#%% Data Cleaning and Specific Latent Feature Generation 

# Preprocess Heat Transfer features (specific to Temperature Model)
fullDFOrig = prep.fillMissingHXPoints(fullDFOrig)

# Add latent features (Specific to Temperature Model)
fullDFOrig, predictorTags, highFreqPredictors, lowFreqPredictors = \
    prep.addLatentTemperatureFeatures(fullDFOrig, predictorTags,
                                      highFreqPredictors, lowFreqPredictors)
# %%
fullDF, origSmoothedResponses, predictorTagsNew = \
    prep.preprocessingAndFeatureEngineering(
        fullDFOrig,
        removeTransientData=True,
        smoothBasicityResponse=False,
        addRollingSumPredictors={'add': True, 'window': 30, 'on': ['Fuel coal feed rate PV']}, #NOTE: functionality exists to process an 'on' key
        addRollingMeanPredictors={'add': False, 'window': 5, 'on': highFreqPredictors},
        addMeasureIndicatorsAsPredictors={'add': False, 'on': ['Matte temperatures']}, #NOTE: functionality exists to process an 'on' key
        addShiftsToPredictors={'add': True, 'nLags': 10, 'on': ['Fuel coal feed rate PV']},
        addResponsesAsPredictors={'add': True, 'nLags': 3},
        resampleTime = '30min',
        resampleMethod = 'linear',
        responseTags = responseTags,  
        predictorTags = predictorTags,
        highFrequencyPredictorTags = highFreqPredictors,
        lowFrequencyPredictorTags = lowFreqPredictors)
# %%
predictorsTrain, responsesTrain, origResponsesTrain, predictorsTest, responsesTest, origResponsesTest = \
    prep.splitIntoTestAndTrain(
    fullDF,
    origSmoothedResponses,
    trainFrac=0.85,
    predictorTags=predictorTagsNew,
    responseTags=responseTags)
# %% Define temporal cross validation
maxTrainSize = int(70*24*60/30)
testSize = int(7*24*60/30)
nSplits = int(np.ceil((len(predictorsTrain) - maxTrainSize)/testSize))
tscv = TimeSeriesSplit(n_splits = nSplits, max_train_size = maxTrainSize,
                       test_size = testSize)

# %% xgboost pipeline

xgb_pipe = Pipeline(
    [
        ('scaler', RobustScaler()),
        ('feature_select', SelectFromModel(estimator=Lasso(), threshold="median", max_features=len(predictorTagsNew))),
        ('estimator', xgb.XGBRegressor(objective ='reg:squarederror', learning_rate = 0.1)),
    ]
)

xgb_param = {
     'estimator__colsample_bytree' : np.arange(0.1, 0.9),
     'estimator__n_estimators' : np.arange(20,500, 10),
     'estimator__max_depth' : np.arange(3,10),
     'estimator__reg_alpha' : np.arange(0.001, 10),
     'estimator__reg_lambda' : np.arange(0.001, 10),
     'estimator__learning_rate' : np.arange(0.1, 1, 0.1),
     'estimator__min_split_loss' : np.logspace(-2, 1, 100),
     'estimator__subsample' : np.arange(0.3, 1, 0.1)
    }

xgb_search = BayesSearchCV(estimator = xgb_pipe, search_spaces = xgb_param,
                             n_iter = 100, cv = tscv, verbose = 5, n_jobs = -1,
                             scoring = 'r2')

xgb_result = xgb_search.fit(predictorsTrain, responsesTrain)

xgb_estimator = xgb_result.best_estimator_

#%% random forest pipeline
rf_pipe = Pipeline([('scaler', RobustScaler()),
                 ('estimator', RandomForestRegressor(criterion="squared_error", n_jobs=-1))])

rf_param = {
    'estimator__n_estimators' : np.arange(50, 100, 5),
    'estimator__max_depth' : np.arange(3, 5),
    'estimator__max_samples' : np.arange(0.4, 1, 0.1),
    'estimator__max_features' : np.arange(0.1, 1, 0.1)
}

rf_search = BayesSearchCV(estimator = rf_pipe, search_spaces = xgb_param,
                             n_iter = 100, cv = tscv, verbose = 5, n_jobs = -1,
                             scoring = 'r2')

rf_result = xgb_search.fit(predictorsTrain, responsesTrain)

rf_estimator = rf_result.best_estimator_

# %% simple lm pipeline
lm_pipe = Pipeline(
    [
        ('scaler', RobustScaler()),
        ('reduction', PCA()),
        ('regression', Lasso(max_iter = 3000))
    ]
)

lm_param = {
    'reduction__n_components' : np.arange(5, 25, 5),
    'regression__alpha' : np.logspace(-9, 4, num = 1000)
}

lm_search = BayesSearchCV(estimator = lm_pipe, search_spaces = lm_param,
                             n_iter = 100, cv = tscv, verbose = 5, n_jobs = -1,
                             scoring = 'r2')

lm_result = lm_search.fit(predictorsTrain, responsesTrain)

lm_estimator = lm_result.best_estimator_
# %%
combiner = VarianceEnsembleEstimator(estimators=[xgb_estimator, rf_estimator, lm_estimator])
# %% Out of sample testing

maxTrainSize = min(int(140*24*60/30), predictorsTrain.shape[0])
predictorsTestPrepended = pd.concat((predictorsTrain[-maxTrainSize:], predictorsTest))
responsesTestPrepended = pd.concat((responsesTrain[-maxTrainSize:], responsesTest))
nSplits = int(np.ceil((len(predictorsTestPrepended) - maxTrainSize)/testSize))
tscv = TimeSeriesSplit(n_splits = nSplits, max_train_size = maxTrainSize,
                       test_size = testSize)

# %%
testResults = pd.DataFrame()
trainResults = pd.DataFrame()

batch_num = 1

for train_index, test_index in tscv.split(predictorsTestPrepended):
    xTrain, xTest = \
        predictorsTestPrepended.iloc[train_index], \
        predictorsTestPrepended.iloc[test_index]
    yTrainDS, yTestDS = responsesTestPrepended.iloc[train_index], \
        responsesTestPrepended.iloc[test_index]

    yTrain = yTrainDS.values
    yTest = yTestDS.values
    
    combiner.fit(X=xTrain, y=yTrain.ravel())
    ytrain_pred_lower, ytrain_pred, ytrain_pred_upper = combiner.predict(xTrain)
    ytest_pred_lower, ytest_pred, ytest_pred_upper = combiner.predict(xTest)
    
    
    print('----------------Batch train results--------------------------------')
    modelling.regression_results(yTrain.ravel(), ytrain_pred)
    
    print('----------------Batch test results--------------------------------')
    modelling.regression_results(yTest.ravel(), ytest_pred)
    
    latestTrainResults = pd.DataFrame({"Actuals" : yTrain.ravel(), "mean_pred" : ytrain_pred,
                                        "lower_pred" : ytrain_pred_lower, "upper_pred" : ytrain_pred_upper,
                                        "batch" : f'batch_num_{batch_num}', "time" : yTrainDS.index})
    latestTestResults = pd.DataFrame({"Actuals" : yTest.ravel(), "mean_pred" : ytest_pred,
                                      "lower_pred" : ytest_pred_lower, "upper_pred" : ytest_pred_upper,
                                      "batch" : f'batch_num_{batch_num}', "time" : yTestDS.index})


    testResults = pd.concat((testResults, latestTestResults))
    trainResults = pd.concat((trainResults, latestTrainResults))
    
    batch_num += 1

print('--------------------------------------------------------------')
print('Overall Results - Test') 
modelling.regression_results(testResults.Actuals, testResults.mean_pred)   
# %% Visualisation train data
g = sns.FacetGrid(trainResults,col = 'batch', col_wrap = 2)
g.map(sns.scatterplot, "Actuals", "mean_pred")

x_min = trainResults.Actuals.min() - 100
x_max = trainResults.Actuals.max() + 100
y_min = trainResults.mean_pred.min() - 100
y_max = trainResults.mean_pred.max() + 100
for ax in g.axes_dict.values():
    ax.axline((0,0),slope = 1, ls = "--",color = 'black')
    
g.set(xlim = (x_min, x_max), ylim = (y_min, y_max))

#%% Visualisation test results

g = sns.FacetGrid(testResults,col = 'batch', col_wrap = 2)
g.map(sns.scatterplot, "Actuals", "mean_pred")

x_min = testResults.Actuals.min() - 100
x_max = testResults.Actuals.max() + 100
y_min = testResults.mean_pred.min() - 100
y_max = testResults.mean_pred.max() + 100

for ax in g.axes_dict.values():
    ax.axline((0,0),slope = 1, ls = "--")
    
g.set(xlim = (x_min, x_max), ylim = (y_min, y_max))

#%% TimeSeriesResults
plot_df = trainResults.drop(columns = ['lower_pred', 'upper_pred']).melt(id_vars = ['time', 'batch'])
g = sns.FacetGrid(plot_df,col = 'batch', col_wrap = 3, sharex=False, sharey=False, despine=True, legend_out=True)
g.map(sns.scatterplot, "time", "value", 'variable')
g.map(sns.lineplot, "time", "value", 'variable')

for ax in g.axes_dict.values():
    ax.set_xticklabels(ax.get_xticklabels(),rotation = 30, fontsize=8)
    
#%%
plot_df = testResults.drop(columns = ['lower_pred', 'upper_pred']).melt(id_vars = ['time', 'batch'])
g = sns.FacetGrid(plot_df,col = 'batch', col_wrap = 3, sharex=False, sharey=False)
g.map(sns.scatterplot, "time", "value", 'variable')
g.map(sns.lineplot, "time", "value", 'variable')

for ax in g.axes_dict.values():
    ax.set_xticklabels(ax.get_xticklabels(),rotation = 30, fontsize=8)
