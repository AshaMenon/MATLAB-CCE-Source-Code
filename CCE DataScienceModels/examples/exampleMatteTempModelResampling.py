import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.base import BaseEstimator
from sklearn.utils.validation import check_X_y, check_array, check_is_fitted
from sklearn.metrics import euclidean_distances
from sklearn.datasets import load_diabetes
from sklearn.model_selection import TimeSeriesSplit

import src.preprocessingFunctions as prep
import src.modellingFunctions as modelling
import src.dataExploration as visualise
import src.featureEngineeringHelpers as featEng

#%%
class BootstrapEstimator(BaseEstimator):
    
    def __init__(self, distance_fun = euclidean_distances, upper_bound = 0.75, lower_bound = 0.25, n_samples = 100) :
        
        self.distance_fun = distance_fun
        self.upper_bound = upper_bound
        self.lower_bound = lower_bound
        self.n_samples = n_samples
        
    
    def fit(self, X, y) :
        
        X, y = check_X_y(X, y)
        self.X_ = X
        self.y_ = y
        
        return self
    
    def predict(self, X) :
        
        if not callable(self.distance_fun):
            raise Exception("Specified distance function not callable")
        
        dist_matrix = self.distance_fun(X, self.X_)
        y_pred = np.zeros(X.shape[0])
        y_lower = np.zeros(X.shape[0])
        y_upper = np.zeros(X.shape[0])
        
        for i in range(X.shape[0]):
            
            dist_vec = dist_matrix[i, :]
            dist_vec[dist_vec < 0.01] = 0.01
            dist_vec = 1/dist_vec
            probs_vec = dist_vec/sum(dist_vec)
            
            sample_vec = np.random.choice(a = self.y_, size = self.n_samples, p = probs_vec)
            
            y_pred[i] = np.mean(sample_vec)
            y_lower[i] = np.quantile(sample_vec, self.lower_bound)
            y_upper[i] = np.quantile(sample_vec, self.upper_bound)
            
        return y_pred
            
            
             
# %%
diabetes_X, diabetes_Y = load_diabetes(return_X_y=True)
# %%
diabetes_X_train, diabetes_Y_train, diabetes_X_test, diabetes_Y_test = diabetes_X[:420, ], diabetes_Y[:420], diabetes_X[421:, ], diabetes_Y[421:]
# %%

bst_estimator = BootstrapEstimator()
# %%
bst_estimator.fit(X = diabetes_X_train, y = diabetes_Y_train)
# %%
y_low, y_mean, y_upp = bst_estimator.predict(diabetes_X_test)
# %%
ax =plt.plot(diabetes_Y_test, color='blue', marker='o')
plt.plot(y_mean, color='green', marker='o')
plt.plot(y_low, linestyle='none', color='yellow', marker='o')
plt.plot(y_upp, linestyle='none', color='red', marker='o')
plt.fill_between(range(21),y_low, y_upp, alpha=0.2)

plt.show()


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

#%% Split Data

predictorsTrain, responsesTrain, origResponsesTrain, predictorsTest, responsesTest, origResponsesTest = \
    prep.splitIntoTestAndTrain(
    fullDF,
    origSmoothedResponses,
    trainFrac=0.85,
    predictorTags=predictorTagsNew,
    responseTags=responseTags)

#%% Testing Algorithm on Out of Sample Data

# Append training data for final model to the testing data set - THIS DATA IS
#   ONLY USED FOR TRAINING THE FIRST FINAL MODEL

bst_estimator = BootstrapEstimator()

maxTrainSize = predictorsTrain.shape[0]
testSize = int(7*24*60/30)

predictorsTestPrepended = pd.concat((predictorsTrain[-maxTrainSize:], predictorsTest))
responsesTestPrepended = pd.concat((responsesTrain[-maxTrainSize:], responsesTest))
nSplits = int(np.ceil((len(predictorsTestPrepended) - maxTrainSize)/testSize))
tscv = TimeSeriesSplit(n_splits = nSplits, max_train_size = maxTrainSize,
                       test_size = testSize)

testResults = pd.DataFrame()
trainResults = pd.DataFrame()

for train_index, test_index in tscv.split(predictorsTestPrepended):
    xTrain, xTest = \
        predictorsTestPrepended.iloc[train_index], \
        predictorsTestPrepended.iloc[test_index]
    yTrainDS, yTestDS = responsesTestPrepended.iloc[train_index], \
        responsesTestPrepended.iloc[test_index]

    yTrain = yTrainDS.values
    yTest = yTestDS.values
    
    bst_estimator.fit(X = xTrain, y = yTrain.ravel())
    
    yHatTest = bst_estimator.predict(X = xTest)
    
    latestTestResults = pd.DataFrame(data = np.concatenate((yTest,
                                                  yHatTest[:, np.newaxis]), axis=1),
                           index=yTestDS.index, columns=('yActual','yHat'))
    
    latestTestResults["pred_start"] = yTestDS.index.min()

    testResults = pd.concat((testResults, latestTestResults))

print('--------------------------------------------------------------')
print('Overall Results - Test')    
modelling.regression_results(testResults.yActual, testResults.yHat)
#%% Results Visualisation
g = sns.FacetGrid(testResults, row = 'pred_start')
g.map(sns.scatterplot, 'yActual', 'yHat')


# %%
