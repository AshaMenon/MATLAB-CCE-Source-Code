from turtle import color
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import scipy.stats as stats
import xgboost as xgb
import datetime
from itertools import islice
import tensorflow as tf
import tensorflow_probability as tfp

from tqdm.notebook import tqdm
import bokeh
import bokeh.io
import bokeh.plotting
import bokeh.models
from IPython.display import display, HTML

bokeh.io.output_notebook(hide_banner=True)

tfb = tfp.bijectors
tfd = tfp.distributions
tfk = tfp.math.psd_kernels


from sklearn.preprocessing import RobustScaler
from sklearn.decomposition import PCA
from sklearn.preprocessing import PolynomialFeatures
from skopt import BayesSearchCV
from sklearn.model_selection import RepeatedKFold, TimeSeriesSplit
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
from sklearn.gaussian_process import GaussianProcessRegressor
from sklearn.gaussian_process.kernels import ConstantKernel, RBF, WhiteKernel

import Shared.DSModel.src.preprocessingFunctions as prep
import src.modellingFunctions as modelling
import src.dataExploration as visualise
import Shared.DSModel.src.featureEngineeringHelpers as featEng 

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

# %%
predictorsTrain, responsesTrain, origResponsesTrain, predictorsTest, responsesTest, origResponsesTest = \
    prep.splitIntoTestAndTrain(
    fullDF,
    origSmoothedResponses,
    trainFrac=0.85,
    predictorTags=predictorTagsNew,
    responseTags=responseTags)
    
trainDF = pd.concat([predictorsTrain,responsesTrain], axis = 1)
testDF = pd.concat([predictorsTest,responsesTest], axis = 1)

# %%
select_features = ["Specific Oxygen Actual PV",
                      "Specific Silica Actual PV", "Matte feed PV filtered",
                      "Lance oxygen flow rate PV", "Lance air flow rate PV",
                      "Silica PV",
                      "Matte transfer air flow", "Fuel coal feed rate PV"]
select_response = ["Basicity"]

trainPredictors = trainDF[select_features]
responsesTrain = trainDF[select_response]
testPredictors = testDF[select_features]
responseTest = testDF[select_response]
# %%
# Define mean function which is the means of observations
observations_mean = tf.constant(
    [np.mean(responsesTrain.values)], dtype=tf.float64)
mean_fn = lambda _: observations_mean
#
# %%
# Define the kernel with trainable parameters. 
# Note we transform some of the trainable variables to ensure
#  they stay positive.

# Use float64 because this means that the kernel matrix will have 
#  less numerical issues when computing the Cholesky decomposition

# Constrain to make sure certain parameters are strictly positive
constrain_positive = tfb.Shift(np.finfo(np.float64).tiny)(tfb.Exp())

# Smooth kernel hyperparameters
smooth_amplitude = tfp.util.TransformedVariable(
    initial_value=10., bijector=constrain_positive, dtype=np.float64,
    name='smooth_amplitude')
smooth_length_scale = tfp.util.TransformedVariable(
    initial_value=10., bijector=constrain_positive, dtype=np.float64,
    name='smooth_length_scale')
# Smooth kernel
smooth_kernel = tfk.ExponentiatedQuadratic(
    amplitude=smooth_amplitude, 
    length_scale=smooth_length_scale)

# Short-medium term irregularities kernel hyperparameters
irregular_amplitude = tfp.util.TransformedVariable(
    initial_value=1., bijector=constrain_positive, dtype=np.float64,
    name='irregular_amplitude')
irregular_length_scale = tfp.util.TransformedVariable(
    initial_value=1., bijector=constrain_positive, dtype=np.float64,
    name='irregular_length_scale')
irregular_scale_mixture = tfp.util.TransformedVariable(
    initial_value=1., bijector=constrain_positive, dtype=np.float64,
    name='irregular_scale_mixture')
# Short-medium term irregularities kernel
irregular_kernel = tfk.RationalQuadratic(
    amplitude=irregular_amplitude,
    length_scale=irregular_length_scale,
    scale_mixture_rate=irregular_scale_mixture)

#Short term irregularities kernel hyperparameters
short_term_amplitude = tfp.util.TransformedVariable(
    initial_value=0.1, bijector=constrain_positive, dtype=np.float64,
    name='short_term_amplitude'
)
short_term_length_scale = tfp.util.TransformedVariable(
    initial_value=0.1, bijector=constrain_positive, dtype=np.float64,
    name = 'short_term_length_scale'
)
#Short term irregularities kernel
short_term_kernel = tfk.MaternOneHalf(
    amplitude=short_term_amplitude,
    length_scale=short_term_length_scale
)

# Noise variance of observations
# Start out with a medium-to high noise
observation_noise_variance = tfp.util.TransformedVariable(
    initial_value=1, bijector=constrain_positive, dtype=np.float64,
    name='observation_noise_variance')

trainable_variables = [v.variables[0] for v in [        #is there a differnce in performance if we use v.trainable_variables instead?
    smooth_amplitude,
    smooth_length_scale,
    irregular_amplitude,
    irregular_length_scale,
    irregular_scale_mixture,
    short_term_amplitude,
    short_term_length_scale,
    observation_noise_variance
]]

# %%
# Sum all kernels to single kernel containing all characteristics
kernel = (smooth_kernel + short_term_kernel + irregular_kernel)
# %%
# Define mini-batch data iterator
batch_size = 128

batched_dataset = (
    tf.data.Dataset.from_tensor_slices(
        (trainPredictors.values, responsesTrain.values.ravel()))
    .shuffle(buffer_size=len(trainPredictors))
    .repeat(count=None)
    .batch(batch_size)
)
#

# %%
# Use tf.function for more efficient function evaluation
@tf.function(autograph=False, experimental_compile=False)
def gp_loss_fn(index_points, observations):
    """Gaussian process negative-log-likelihood loss function."""
    gp = tfd.GaussianProcess(
        mean_fn=mean_fn,
        kernel=kernel,
        index_points=index_points,
        observation_noise_variance=observation_noise_variance
    )
    
    negative_log_likelihood = -gp.log_prob(observations)
    return negative_log_likelihood
# %% draw samples from prior

index_Points = trainPredictors.values
index_Points = index_Points[:128]
gp = tfd.GaussianProcess(
        mean_fn=mean_fn,
        kernel=kernel,
        index_points= index_Points,
        observation_noise_variance=observation_noise_variance 
)

samples = gp.sample(10).numpy()
#%%
plt.subplots(figsize=(10, 6))

for i in range(samples.shape[0]):
    plt.scatter(np.arange(samples.shape[1]), samples[i,:])
    
plt.show()

# %%
# Fit hyperparameters
optimizer = tf.keras.optimizers.Adam(learning_rate=0.001)

# Training loop
batch_nlls = []  # Batch NLL for plotting
full_ll = []  # Full data NLL for plotting
nb_iterations = 10001
for i, (index_points_batch, observations_batch) in tqdm(
        enumerate(islice(batched_dataset, nb_iterations)), total=nb_iterations):
    print(i)
    # print(observations_batch)
    # Run optimization for single batch
    with tf.GradientTape() as tape:
        loss = gp_loss_fn(index_points_batch, observations_batch)
    grads = tape.gradient(loss, trainable_variables)
    optimizer.apply_gradients(zip(grads, trainable_variables))
    batch_nlls.append((i, loss.numpy()))
    # Evaluate on all observations
    # if i % 100 == 0:
        # Evaluate on all observed data
        # print(i)
        # ll = gp_loss_fn(
        #     index_points=trainPredictors.values,
        #     observations=responsesTrain.values.ravel())
        # full_ll.append((i, ll.numpy()))


#%% Plot training progress
fig, ax1 = plt.subplots(figsize=(10,6))

batch_vec = [item[0] for item in batch_nlls]
batch_loss = [item[1] for item in batch_nlls]
# full_vec = [item[0] for item in full_ll]
# full_loss = [item[1] for item in full_ll]

ax1.plot(batch_vec, batch_loss)
ax1.set_xlabel("Batch")
ax1.set_ylabel("Batch NLL")

# ax2 = ax1.twinx()
# ax2.set_ylabel("Full NLL")
# ax2.plot(full_vec, full_loss, color='red')

fig.tight_layout()
plt.show()

# %%
# Show values of parameters found
variables = [
    smooth_amplitude,
    smooth_length_scale,
    irregular_amplitude,
    irregular_length_scale,
    irregular_scale_mixture,
    short_term_amplitude,
    short_term_length_scale,
    observation_noise_variance
]

data = list([(var.variables[0].name[:-2], var.numpy()) for var in variables])
df_variables = pd.DataFrame(
    data, columns=['Hyperparameters', 'Value'])
display(HTML(df_variables.to_html(
    index=False, float_format=lambda x: f'{x:.4f}')))
#
# %%
# Posterior GP using fitted kernel and observed data
gp_posterior_predict = tfd.GaussianProcessRegressionModel(
    mean_fn=mean_fn,
    kernel=kernel,
    index_points=testPredictors[:1000].values,
    observation_index_points=trainPredictors[:1000].values,
    observations=responsesTrain[:1000].values.ravel(),
    observation_noise_variance=observation_noise_variance)

# Posterior mean and standard deviation
posterior_mean_predict = gp_posterior_predict.mean()
posterior_std_predict = gp_posterior_predict.stddev()
# %%
plt.figure(figsize=(10, 6))
plt.scatter(responseTest[:1000].values, posterior_mean_predict.numpy())
plt.plot(responseTest[:1000].values, responseTest[:1000].values)
plt.show()
# %%
Testresults = responseTest[:1000]
Testresults['Mean_pred'] = posterior_mean_predict.numpy()
Testresults['sd'] = posterior_std_predict.numpy()

Testresults['Month'] = [x.strftime('%b') for x in Testresults[:1000].index]

Testresults = Testresults.assign(pred_upper = Testresults['Mean_pred'] + 1.96*Testresults['sd'],
                   pred_lower = Testresults['Mean_pred'] - 1.96*Testresults['sd'])

# %% Time series plots
plot_month = Testresults['Month'].unique()

for mnth in plot_month:
    
    curr_data = Testresults[Testresults['Month'] == mnth]
    
    fig, ax = plt.subplots()
    plt.plot(curr_data.index, curr_data["Basicity"], marker = 'o', color = 'green', label = 'actual')
    plt.plot(curr_data.index, curr_data.Mean_pred, marker = 's', color = 'blue', label = 'mean prediction')
    plt.fill_between(curr_data.index, curr_data.pred_lower, curr_data.pred_upper, alpha=0.2)
    plt.xlabel("Time")
    plt.ylabel("Basicity")
    plt.title(f"Actuals vs predictions {mnth}")
    ax.xaxis.set_tick_params(rotation=30, labelsize=9)
    plt.legend()
    plt.show()
# %% Print regression results
for mnth in plot_month:
    print(f'Regression results for {mnth} \n')
    
    curr_data = Testresults[Testresults['Month'] == mnth]
    modelling.regression_results(curr_data['matte_temp_delta'].values.ravel(),
                                 curr_data.Mean_pred)


print('Total test data regression result')
modelling.regression_results(Testresults['matte_temp_delta'].values.ravel(),
                             Testresults.Mean_pred)

#%% Simple method

# kernel = 1.0 * ExpSineSquared(1.0, 5.0, periodicity_bounds=(1e-2, 1e1)) + WhiteKernel(
#     1e-1
# )

gpr = GaussianProcessRegressor()
gpr.fit(xTrain.values,yTrain)

print(gpr.kernel_)
    
mean_predictions_gpr, std_predictions_gpr = gpr.predict(
    xTest,
    return_std=True,
)

plt.plot(mean_predictions_gpr)
# plt.fill_between(
#     mean_predictions_gpr - std_predictions_gpr,
#     mean_predictions_gpr + std_predictions_gpr,
#     color="tab:green",
#     alpha=0.2,
# )
    
    
#%% Detailed Gaussian method

kernel = 1**2 * RBF(length_scale=1)

observations_mean = tf.constant(
    [np.mean(yTrain)], dtype=tf.float64)
mean_fn = lambda _: observations_mean

index_Points = xTrain.values
# index_Points = index_Points[:128]

observation_noise_variance = tfp.util.TransformedVariable(
    initial_value=1, bijector=constrain_positive, dtype=np.float64,
    name='observation_noise_variance')

gp = tfd.GaussianProcess(
        mean_fn=mean_fn,
        kernel=kernel,
        index_points= index_Points,
        observation_noise_variance=observation_noise_variance 
        
        
#%% New Gaussian Model Implementation

# import all packages and set plots to be embedded inline
import numpy as np
import matplotlib.pyplot as plt
from scipy.optimize import minimize
from scipy.optimize import Bounds
from pyDOE import lhs
from sklearn.preprocessing import MinMaxScaler
from sklearn.pipeline import Pipeline

#%% Initializing a GP model

