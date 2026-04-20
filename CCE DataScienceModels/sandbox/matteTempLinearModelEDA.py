import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.preprocessing import RobustScaler
from sklearn.decomposition import KernelPCA
from sklearn.decomposition import PCA
from sklearn.preprocessing import PolynomialFeatures
from skopt import BayesSearchCV
from sklearn.model_selection import TimeSeriesSplit
from sklearn.pipeline import Pipeline
from sklearn.linear_model import Lasso

import src.preprocessingFunctions as prep
import src.modellingFunctions as modelling
import src.dataExploration as visualise
import src.featureEngineeringHelpers as featEng


#%% Define tags
highFreqPredictors = ["Matte feed PV", "Fuel coal feed rate PV", "Specific Oxygen Actual PV",
                      "Lump coal PV", "Lance oxygen flow rate PV", "Lance air flow rate PV",
                      "Matte transfer air flow", "Lance coal carrier air", "Silica PV",
                      "Lower waffle 19", "Lower waffle 20", "Lower waffle 21",
                      "Lower waffle 22", "Lower waffle 23", "Lower waffle 24",
                      "Lower waffle 25", "Lower waffle 26", "Lower waffle 27",
                      "Lower waffle 28", "Lower waffle 29", "Lower waffle 30",
                      "Lower waffle 31", "Lower waffle 32", "Lower waffle 33",
                      "Lower waffle 34", "Upper hearth 90", "Upper hearth 91",
                      "Upper hearth 92", "Upper hearth 93", "Upper hearth 94",
                      "Upper hearth 95", "Upper hearth 96", "Upper hearth 97",
                      "Upper hearth 98", "Fuel coal feed rate SP", "Lance height",
                      "Lance motion"]

lowFreqPredictors = ["Corrected Ni Slag", "Ni Slag", "S Slag", "Cr2O3 Slag", "Basicity",
                     "Cu Feedblend", "Ni Feedblend", "Co Feedblend", "Fe Feedblend",
                     "S Feedblend", "SiO2 Feedblend", "Al2O3 Feedblend", "CaO Feedblend",
                     "MgO Feedblend", "Cr2O3 Feedblend", "MgO Slag",
                     "Slag temperatures"]

predictorTags = highFreqPredictors + lowFreqPredictors

responseTags = ['Matte temperatures']

#%%Collect data
fullDFOrig = prep.readAndFormatData('Temperature', responseTags=responseTags,
        predictorTags=predictorTags)
# %% get unique responses

origSmoothedResponses, _ = featEng.getUniqueDataPoints(fullDFOrig[responseTags].dropna())

# %%
ax = origSmoothedResponses.plot(y = "Matte temperatures", use_index=True, style = 'b-')
plt.title("Matte Temperature")
plt.show()

# %% Plot distibuution of Matte temperatures
sns.histplot(data= origSmoothedResponses,x="Matte temperatures")

# %% isolate only the points with unique Matte temperatures
uniqueDataset = fullDFOrig.join(origSmoothedResponses, on="Timestamp", how="inner", lsuffix='left')

# %%
waffle_predictors = [x for x in predictorTags if "waffle" in x]
hearth_predictors = [x for x in predictorTags if "hearth" in x]
lance_predictors = ["Lance motion", "Lance height"]
pv_predictors = [x for x in predictorTags if "PV" in x]
air_predictors = ["Matte transfer air flow", "Lance coal carrier air"]
fuelcoal = ["Fuel coal feed rate SP"]
feed_predictors = [x for x in predictorTags if "Feedblend" in x]
slag_predictors = [x for x in predictorTags if ("Slag" in x) & (x != "Slag temperatures")]
slag_temperature = ["Slag temperatures"]
basicity = ["Basicity"]

# %% 
sns.pairplot(data=uniqueDataset[waffle_predictors + responseTags])

# %%
sns.pairplot(data=uniqueDataset[hearth_predictors + responseTags])
# %%
sns.pairplot(data=uniqueDataset[lance_predictors + responseTags])
# %%
sns.pairplot(data=uniqueDataset[pv_predictors + responseTags])
# %%
sns.pairplot(data=uniqueDataset[air_predictors + responseTags])
# %%
sns.pairplot(data=uniqueDataset[fuelcoal + responseTags])
# %%
sns.pairplot(data=uniqueDataset[feed_predictors + responseTags])
# %%
sns.pairplot(data=uniqueDataset[slag_predictors + responseTags])
# %%
sns.pairplot(data=uniqueDataset[slag_temperature + responseTags])
# %%
sns.pairplot(data=uniqueDataset[basicity + responseTags])
# %% apply current feature engineering
fullDF, origSmoothedResponses, predictorTagsNew = \
    prep.preprocessingAndFeatureEngineering(
        fullDFOrig,
        removeTransientData=True,
        smoothBasicityResponse=False,
        addRollingSumPredictors={'add': True, 'window': 5, 'on': highFreqPredictors}, #NOTE: functionality exists to process an 'on' key
        addRollingMeanPredictors={'add': True, 'window': 5, 'on': highFreqPredictors},
        addMeasureIndicatorsAsPredictors={'add': True, 'on': ['Matte temperatures']}, #NOTE: functionality exists to process an 'on' key
        addShiftsToPredictors={'add': True, 'nLags': 3, 'on': highFreqPredictors},
        addResponsesAsPredictors={'add': True, 'nLags': 3},
        resampleTime = '30min',
        resampleMethod = 'linear',
        responseTags = responseTags,  
        predictorTags = predictorTags,
        highFrequencyPredictorTags = highFreqPredictors,
        lowFrequencyPredictorTags = lowFreqPredictors)

# %%
