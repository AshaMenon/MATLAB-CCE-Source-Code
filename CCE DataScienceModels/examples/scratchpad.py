from math import ceil
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import scipy.stats as stats
import datetime

import src.preprocessingFunctions as prep
import src.modellingFunctions as modelling
import src.dataExploration as visualise
import src.featureEngineeringHelpers as featEng 

#%% Read and Format Data

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
#%%  
fullDF, origSmoothedResponses, predictorTagsNew = \
    prep.preprocessingAndFeatureEngineering(
        fullDFOrig,
        removeTransientData=True,
        smoothBasicityResponse=False,
        addRollingSumPredictors={'add': True, 'window': 30, 'on': ['Fuel coal feed rate PV']}, #NOTE: functionality exists to process an 'on' key
        addRollingMeanPredictors={'add': False, 'window': 5, 'on': highFreqPredictors},
        addMeasureIndicatorsAsPredictors={'add': True, 'on': ['Matte temperatures']}, #NOTE: functionality exists to process an 'on' key
        addShiftsToPredictors={'add': True, 'nLags': 10, 'on': ['Fuel coal feed rate PV']},
        addResponsesAsPredictors={'add': True, 'nLags': 3},
        resampleTime = '30min',
        resampleMethod = 'linear',
        responseTags = responseTags,  
        predictorTags = predictorTags,
        highFrequencyPredictorTags = highFreqPredictors,
        lowFrequencyPredictorTags = lowFreqPredictors)

# %% add rolling sums
alt_DF, _ = featEng.addRollingSumPredictors(fullDFOrig, ['Fuel coal feed rate PV'], 30)
# %% add rolling means
alt_DF, _ = featEng.addRollingSumPredictors(alt_DF, highFreqPredictors, 5)

# %% add lags
alt_DF, _ = featEng.addLagsAsPredictors(alt_DF, ['Fuel coal feed rate PV'], 10)

#%% function to collect unique measurements

def uniqueSamples(DF, varname):
    
    DF[f'{varname}_new_measure'] = np.append(True, np.diff(DF[varname].values.ravel()) != 0)
    
    MeasureTimes = DF[DF[f'{varname}_new_measure']]
    MeasureTimes['time_since_measure'] = MeasureTimes.index
    MeasureTimes = MeasureTimes['time_since_measure']
    
    DF = DF.join(MeasureTimes, how = 'left')
    DF.fillna(method = "ffill", inplace=True)
    
    DF = DF.assign(time_since_measure = DF.index - DF['time_since_measure'])
    DF['time_since_measure'] = DF['time_since_measure'].apply(lambda x : x/datetime.timedelta(minutes=1))
    DF.rename(columns = {'time_since_measure' : f'{varname}_time_since_measure'}, inplace=True)
    
    return DF
# %%
myDF = uniqueSamples(DF = alt_DF, varname = responseTags[0])
myDF = myDF[myDF['Matte temperatures_new_measure']]
myDF.dropna(inplace=True)
myDF = myDF.drop(columns = ['Matte temperatures_new_measure', 'Matte temperatures_time_since_measure'])
# %%
myDF["batch"] = np.arange(len(myDF))
# %%
BATCH_SIZE = 128
myDF["batch"] = np.floor(myDF['batch']/BATCH_SIZE)
# %%
feat_names = myDF.drop(columns = ['batch']).columns
feat_names = feat_names[feat_names != "Matte temperatures"]
#feat_names = feat_names[0:94]

all_df = pd.DataFrame()

for feature in feat_names:
    
    feat_DF = myDF[['Matte temperatures', feature, 'batch']]
    batches =np.unique(feat_DF['batch'].values)
    
    coefs = []
    
    for batch_num in batches:
        
        df = feat_DF[feat_DF['batch'] == batch_num]
        
        x = df['Matte temperatures'].values.ravel()
        y = df[feature].values.ravel()
        
        r = stats.pearsonr(x, y)[0]
        coefs.append(r)
    
    featRes = pd.DataFrame({"feature" : feature,
                  "batch_num" : batches,
                  "correlation_coef" : coefs})
    
    all_df = pd.concat([all_df, featRes])
    
    all_df = all_df.reset_index(drop=True)
        
# %%
all_df = all_df.groupby(by = ['feature']).aggregate({'correlation_coef' : 'median'})
# %%
all_df['correlation_coef'] = np.abs(all_df['correlation_coef'])
all_df.dropna(inplace=True)
all_df = all_df.sort_values('correlation_coef', ascending=False)
all_df = all_df.head(30)
# %%
fig, ax = plt.subplots(figsize=(10, 6))

ax.barh(all_df.index, all_df['correlation_coef'].values)
ax.set_xlabel('Correlation coefficient')
ax.set_ylabel('Features')
ax.yaxis.set_tick_params(labelsize=8)

plt.show()
# %%
myDF["matte_temp_diff"] = np.append(0, np.diff(myDF["Matte temperatures"].values.ravel()))
# %%
feat_names = myDF.drop(columns = ['batch', "Matte temperatures", "matte_temp_diff"]).columns

all_df = pd.DataFrame()

for feature in feat_names:
    
    feat_DF = myDF[["matte_temp_diff", feature, 'batch']]
    batches =np.unique(feat_DF['batch'].values)
    
    coefs = []
    
    for batch_num in batches:
        
        df = feat_DF[feat_DF['batch'] == batch_num]
        
        x = df["matte_temp_diff"].values.ravel()
        y = df[feature].values.ravel()
        
        r = stats.pearsonr(x, y)[0]
        coefs.append(r)
    
    featRes = pd.DataFrame({"feature" : feature,
                  "batch_num" : batches,
                  "correlation_coef" : coefs})
    
    all_df = pd.concat([all_df, featRes])
    
    all_df = all_df.reset_index(drop=True)

all_df.dropna(inplace=True)

#%%
all_df = all_df.groupby(by = ['feature']).aggregate({'correlation_coef' : 'mean'})
all_df['correlation_coef'] = np.abs(all_df['correlation_coef'])
all_df = all_df.sort_values('correlation_coef', ascending=False)
all_df = all_df.head(30)

fig, ax = plt.subplots(figsize=(10, 6))

ax.barh(all_df.index, all_df['correlation_coef'].values)
ax.set_xlabel('Correlation coefficient')
ax.set_ylabel('Features')
ax.yaxis.set_tick_params(labelsize=8)

plt.show()
# %%
