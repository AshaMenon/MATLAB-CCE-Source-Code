# converter-slag-splash

This project is part of "Amplats Data Science Support". This project encompasses all the work done on the ACP, including Chemistry, Thermal, and Draught Models, all contributing towards a single
Slag Splash Model.

21/12/2021: The work done in the project currently only models the Basicity and Matte Temperature using both Linear Models and Regression Forests.

## Folder Structure

As can be seen from the repository, the folder structure of this study is as follows:
```
converter-slag-splash/
|- data
|- docs
|- env
|- examples
|- sandbox
|- src
|- test
| .gitignore
| README.md
```

The intended contents of each of these folders will now be briefly discussed:
- data - Contains the raw data files for the project. Due to the size of the data files, these are not comitted to the repository
- docs - Contains supporting files that add to the documentation (README.md)
- env - Contains the environment set-up file (`environment.yml`) and is also the intended installation directory of the environment
- examples - Contains example scripts for each of the machine learning (ML) models developed so far
- sandbox - Prototyping environment containing prototyping scripts and functions. Everything in the examples folder started off in a scratch script
- src - Contains all main functionality used in the project in the form of Python modules. Given the exploratory nature of this project, it was decided that a functional format would be
sufficient for the project, and that if a class-based code-base is required, this could be implemented at a later stage using the modules that exist in the src folder
- test - Should contain unit testing frameworks, but is currently a placeholder
- .gitignore - GIT Ignore file
- README.md - This file

## Environment Setup

The environment file is located in `/env/environment.yml`. It is recommended to install the environment within a sub-directory `/env/slag-splash-env/`, in the same folder as the environment file.
The `.gitignore` file is already set up to ignore this directory.

### Anaconda Setup
1. open Anaconda Prompt
2. cd /d [path to your project code]\env
3. conda env create environment.yml
4. conda activate slag-splash-env

## Model Design

The ML Models were designed using a process detailed in the following flow chart:

![Overall Design Process](./docs/mlWorkflow.png)

Both the Basicity and Temperature modelling processes followed the same overall procedure. It is worth noting that multiple model types are trained for each respective response. In this particular
project, a Linear Model and Regression Forest were traine for the Basicity Model and Temperature Model respectively. These models are then later combines using a Kalman Filter, as illustrated in the
workflow doagram. Each part of the workflow will now be discussed in detail.

### Required Input: Raw Data

The raw data is taken directly from the Anglo servers, by accessing the ICS Desktop through the Citrix VPN. All data is queried from the database on a minutely basis (with held values in the case of
data with a lower sampling rate). The date range of the data in this project was taken from 1 January 2021 to 1 October 2021. The following raw data files are used in the analysis, and should exist
in the `data` folder:
- chemistryData_Jan-Mar-21_v4.csv
- chemistryData_Apr-Jun-21_v4.csv
- chemistryData_Jul-Sep-21_v4.csv
- temperatureData_Jan-Mar-21_v3.csv
- temperatureData_Apr-Jun-21_v3.csv
- temperatureData_Jul-Sep-21_v3.csv

### Data Preprocessing

The preprocessing and feature engineering workflow can be seen in the figure below. Functionality has been written such that all preprocessing steps highlighted in blue are Optional, and have keyword
arguments associated with them. These arguments would be passed to the `readAndFormatData` function in the `preprocessingFunctions` module.

![Preprocessing](./docs/preprocessingWorkflow.png)

The steps in the preprocessing pipeline are detailed as follows:
1. **Drop Duplicates** - Duplicate time stamps are dropped from the data.
2. **Replace Bad and Missing values** - Values marked with known bad labels, such as 'Bad', 'No Data', or 'Tag not found' are replaced with NaN values for later consideration.
3. **Select Necessary Tags Only** - Only a specified subset of tags are selected from the full dataframe. The other tags are ignored.
4. **Restrict Data to Within Operating Range** - Each tag has a known operating range. All values outside of this pre-defined range are replaced with NaN.
5. **Forward-fill Missing Data** - All missing data is filled forward by the previously known value. This is fundamentally less risky than performing interpolation.
6. **Remove Transient Data** (Optional) - The data is filtered for steady-state operation only.
7. **Smooth Response** (Optional) - This feature is only applicable to the Basicity model. The raw measured values of basicity are smoothed with a weighted average according to the sum of species in 
the sample and the time between samples.
8. **Add Prior Responses as Predictors** (Optional) - Adding previously measured responses as predictors gives the models the flexibility to be autoregressive in nature.
9. **Add Rolling Sum of Predictors** (Optional) - Adds a rolling sum of a specified length to the predictor matrix. This gives a sense of accumulation in the furnace over a specified period of time.
10. **Add Measure Indicator** (Optional) - Indicates the number of minutes elapsed since a new physical measurement of the response was recorded.
11. **Add Time Shifts** (Optional) - Adds a specified number of lagged predictors to the predictor matrix in an effort to add more time series features to the dataset.

### Train/Test Split

After data pre-processing has been completed, the full augmented data set is split into Training and Testing sets:
- Training Data - Used for training and cross-validation of the respective models. Consists of the first 85% of the multivariate time series
- Testing Data - Used for out-of-sample performance estimation. Consists of the last 15% of the data, and is completely withheld from the models up until the end. No modelling decisions are made
using this data

Illustrated below is the Train/Test split of the data. Please note that the data is of a time series nature, and it it therefore best practices to withhold future data for testing.

![Train Test Split](./docs/trainTestSplit.png)

### Time Series Cross-Validation Procedure

Cross-validation is an important exercise when choosing optimal hyper-parameters for ML models. In the case of time series data, it should be kept in mind that for each fold of the cross-validation,
the training portion of the data should precede the validation portion of the data. The exercise of partitioning the data is made easy by using the `TimeSeriesSplit` class from the `sklearn` 
Python library. The partitioning performed for both models (Basicity and Matte Temperature) is illustrated in the following figure:

![Cross Validation Split](./docs/crossvalSplit.png)

The `max_train_size` and `test_size` are required inputs, and were chosen to be 30 days' worth of data and 7 days' worth of data respectively. The number of splits (`n_splits`) is inferred using the
size of the full Training set and the train and test size parameters.

### Modelling Workflow

The modelling workflows/pipelines consist of a number of feature pre-processing steps before the models are trained and cross-validated. The figure below shows a zoomed-in version of the model
workflow shown earlier in the overall project workflow diagram:

![Pipeline](./docs/pipeline.png)

To ensure that there is no information leakage between the training and validation data sets, the `Pipeline` object is used from Python's `sklearn` library. The steps in the pipeline are detailed
as follows:
1. `StandardScaler` - Centres and scales the data by subtracting the mean and dividing by the standard deviation. The purpose of scaling the data is to ensure that none of the features dominate the
predictive capability of the model based on their respective variances. The underlying assumption regarding this method of scaling is that the data being scaled is normally distributed. This is not
necessarily the case, but it's considered good enough for a first-pass.
2. `PCA/KernelPCA` - Performs either standard Principal Component Analysis (PCA) or Kernel PCA with the Radial Basis Function kernel on the predictors. The purpose of standard PCA is to linearly 
project the predictor data to a space where the projected values are linearly independent of each other, and the features in the projected space are in descending order of variance. Kernel PCA
performs a non-linear mapping of the original predictors to a high-dimensional space in an effort to allow the models to exploit these non-linearities. The hyper-parameter associated with both
standard and Kernel PCA is the number of components used - `n_components`.
3. Fit Model (`RandomForestRegressor/Lasso/Ridge`) - Fits the model to the training data using the `fit` method, and makes a prediction on the validation partition using the model's `predict` method.
Lasso and Ridge regression are variations of ordinary least squares regression with regularisation. Lasso uses the L1-norm as the regularisation penalty (resulting in sparse solutions for the
parameter vector), and Ridge uses the L2-norm (resulting in parameter vectors whose individual entries are of similar order). The hyper-parameters associated with both Lasso and Ridge regression
is the degree of regularisation, `gamma`. The Random Forest is a non-linear method for regression, and involves training individual trees in a bootstrapped manor, and the results are subsequently
aggregated. The hyper-parameters associated with the regression forest are `n_estimators, min_samples_split, min_samples_leaf, max_depth`.

The pipeline is run for a number of hyper-parameter sets. The cross-validation performance of these models is used to determine the optimal set of hyper-parameters. There are a number of potential
methods that could be used for selecting subsequent hyper-parameter sets. In this project, Bayesian optimisation was chosen (`BayesSearchCV`). The features used for each model type are consistent with
each other, i.e. the same input features are used in both the Linear and Forest Models.

### Testing Procedure

In an effort to stay consistent with how the model was trained and its intended use, the testing dataset is run through the models in a similar manor to the cross-validation procedure. The exact
way this is done is illustrated in the figure below:

![Testing Procedure](./docs/testingProcedure.png)

During the testing procedure, a part of the Training data set is prepended to the Testing set for the purposes of training the first of the final models. The training and testing sizes are consistent
with those used during the cross-validation procedure. The purpose of using the models in this way is ultimately to ensure that the models are always trained on the latest data, and so the parameters
within each of the models are always kept up to date.

The entirety of the workflow to this point can be found in the following example scripts for each of the models and modelled responses:
- exampleBasicityModellingForestPipeline.py
- exampleBasicityModellingLinearModelPipeline.py
- exampleMatteTempModellingForestPipeline.py
- exampleMatteTempModellingLinearModelPipeline.py

### Combining Models with the Kalman Filter

One of the applications of a Kalman Filter is sensor fusion. The purpose of each of the models as they currently stand is to predict the state of the furnace between physical measurements. The models
therefore act as data-driven "soft sensors". As such, if the two models (Linear and Forest) make different predictions for the same set of predictors, these two different predictions can be combined
with a Kalman Filter such that the fused reading has a lower uncertainty compared with each of the two individual predictions.

![Kalman](./docs/sensorFusion.png)

The entirety of the workflow (including the Kalman Filter sensor fusion) can be found in the following example scripts:
- exampleBasicityKalmanFilterSensorFusion.py
- exampleMatteTempKalmanFilterSensorFusion.py

## Results

### Model Performance Summary

The table below summarises the latest model Testing results obtained from the final workflow:

| Model                  | r_squared   | MAE         | MSE         | RMSE        | Error Mean  | Error Std   |
| ---------------------- | ----------- | ----------- | ----------- | ----------- | ----------- | ----------- |
| Basicity - Linear      | 0.4761      | 10.038      | 186.894     | 13.6709     | -0.2521     | 13.6686     |
| Basicity - Forest      | 0.6184      | 8.1768      | 135.524     | 11.6415     | -1.5911     | 11.5266     |
| Basicity - Kalman      | 0.6393      | 7.696       | 128.0898    | 11.3177     | -1.732      | 11.2626     |
| Temperature - Linear   | 0.7057      | 0.0528      | 0.0056      | 0.0746      | -0.012      | 0.0735      |
| Temperature - Forest   | 0.7103      | 0.0535      | 0.0055      | 0.074       | -0.0019     | 0.074       |
| Temperature - Kalman   | 0.7922      | 0.0442      | 0.0039      | 0.0628      | -0.0067     | 0.0623      |

### Feature Importance Analysis

The feature importance analysis of each of the models is done in a number of ways, depending on the model type. For Linear Models, the relative values of the coefficients are considered by projecting
the coefficients in the principal component space back on to the original space. For both Forest and Linear Models, the SHAP values are considered. This is done for both model sets in order to directly
compare the values.

**Basicity**

The feature importance for the basicity Linear Model is illustrated in the figures below:

![BasicityLinearShap1](./docs/basicityLinearMdlShapPlot2.png)

![BasicityLinearShap2](./docs/basicityLinearMdlShapPlot1.png)

![BasicityLinear](./docs/basicityLinearMdlFeatureImportance.png)

The feature importance for the basicity Forest Model is illustrated in the figures below:

![BasicityForestShap1](./docs/basicityForestMdlShapPlot2.png)

![BasicityForestShap2](./docs/basicityForestMdlShapPlot1.png)

**Matte Temperature**

The feature importance for the matte temperature Linear Model is illustrated in the figures below:

![TempLinearShap1](./docs/tempLinearMdlShapPlot2.png)

![TempLinearShap2](./docs/tempLinearMdlShapPlot1.png)

![TempLinear](./docs/tempLinearMdlFeatureImportance.png)

The feature importance for the matte temperature Forest Model is illustrated in the figures below:

![TempForestShap1](./docs/tempForestMdlShapPlot2.png)

![TempForestShap2](./docs/tempForestMdlShapPlot1.png)

## Recommendations

The following recommendations for future work are made:
- Run a series of experiments in an effort to improve results and model interpretability (especially for the Temperature model). This includes a combination of different feature engineering techniques
as well as different modelling techniques.
- Incorporate more fundamental features into the Temperature model in an effort to improve the predictive ability of the models.
- Refactor architecture as Object Oriented instead of functional for ease of use and ease of training a variety of models.
- Experiment with different Training/Validation lengths - these lengths were chosen to be something reaonable, but ultimately the models could benefit by investigating this further.
- Implement and test new model types (e.g. neural networks, ARX)
- Perform smoothing on predictors to support a smoothed response (to support the practical use of the model).
- Develop a basicity model that is a function of other (more simplistic) models – e.g. Fe, corrected Ni etc.


