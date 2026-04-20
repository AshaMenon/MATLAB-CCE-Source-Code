# Import relevant modules
import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_squared_error, r2_score 
from sklearn.model_selection import TimeSeriesSplit
from sklearn.pipeline import Pipeline
from sklearn.decomposition import PCA
from sklearn.preprocessing import RobustScaler
import data_preprocessing as dp
import datetime as dt
import pickle
from xgboost import XGBRegressor
from skopt import BayesSearchCV


def train_XGBoost_slag_temp(parameters, inputs):

# Create Log
   # log_file = parameters['LogName']
   # calculation_id = parameters['CalculationID']
   # log_level = parameters['LogLevel']
   # calculation_name = parameters['CalculationName']
   # log = cce_logger.CCELogger(log_file, calculation_name, calculation_id, log_level)
   # error_code = ces.CalculationErrorState.GOOD.value
    
    #log.log_info('--------------------------------------------------------------')
    #log.log_info('Beginning Training XGEBoost Slag Temperature Model')

    [target_df, feature_df_smoothed] = dp.model_data_preprocessing(inputs)
    [mse, r2, fullpath] = train_XGBoost_Model(feature_df_smoothed, target_df)

    outputs = {}
    outputs['Timestamp'] = dt.datetime.now()
    outputs['MSE'] = mse
    outputs['R2'] = r2
    outputs['ModelPath'] = fullpath

    return outputs
        
    #log.log_info('--------------------------------------------------------------')
    #log.log_info('Sucessfully Completed Training XGBoost Slag Temperature Model')
    #log.log_info('--------------------------------------------------------------')



def train_XGBoost_Model(feature_df_smoothed, target_df):
    # Split Data
    X_train, X_test, y_train, y_test = train_test_split(feature_df_smoothed,target_df, test_size=0.2, random_state=42, shuffle=False)

    # Define TS Cross Validation Object
    maxTrainSize = int(7*24*60)
    testSize = int(1*24*60)
    nSplits = int(np.ceil((len(X_train) - maxTrainSize)/testSize))
    tscv = TimeSeriesSplit(n_splits = nSplits, max_train_size = maxTrainSize,
                        test_size = testSize)

    pipe = Pipeline([('scaler', RobustScaler()),
                    ('pca', PCA()),
                    ('xgb_reg', XGBRegressor(objective='reg:squarederror',
                                            booster='gbtree'))])

    param = {
        'pca__n_components': np.arange(2, X_train.shape[1]-1, 1),
        'xgb_reg__n_estimators': np.arange(100, 250),
        'xgb_reg__reg_lambda': np.logspace(-7, 0, num = 250),
        'xgb_reg__max_depth': np.arange(1, 20),
        'xgb_reg__learning_rate': np.logspace(-3, 0, num = 100),
        'xgb_reg__reg_alpha': np.logspace(-7, 0, num = 250),
        'xgb_reg__subsample': np.arange(0.1, 1.05, 0.05),
        'xgb_reg__colsample_bytree': np.arange(0,1,0.05),
        'xgb_reg__colsample_bylevel': np.arange(0,1,0.05),
        'xgb_reg__colsample_bynode': np.arange(0,1,0.05)
        }

    randomSearch = BayesSearchCV(estimator = pipe, search_spaces = param,
                                n_iter = 5, cv = tscv, verbose = 5, n_jobs = -1,
                                scoring = 'neg_root_mean_squared_error')
                                
    searchResults = randomSearch.fit(X_train, y_train)
    pipe = Pipeline([('scaler', RobustScaler()),
                    ('pca', PCA()),
                    ('xgb_reg', XGBRegressor(objective='reg:squarederror',
                                            booster='gbtree'))])


    n_components = searchResults.best_params_.get('pca__n_components')
    nEstimators = searchResults.best_params_.get('xgb_reg__n_estimators')
    xgbLambda = searchResults.best_params_.get('xgb_reg__reg_lambda')
    maxDepth = searchResults.best_params_.get('xgb_reg__max_depth')
    learnRate = searchResults.best_params_.get('xgb_reg__learning_rate')
    alpha = searchResults.best_params_.get('xgb_reg__reg_alpha')
    subsample = searchResults.best_params_.get('xgb_reg__subsample')
    colsample_bytree = searchResults.best_params_.get('xgb_reg__colsample_bytree')
    colsample_bylevel = searchResults.best_params_.get('xgb_reg__colsample_bylevel')
    colsample_bynode = searchResults.best_params_.get('xgb_reg__colsample_bynode')

    pipe.set_params(pca__n_components = n_components ,xgb_reg__n_estimators = nEstimators, xgb_reg__reg_lambda = xgbLambda,
                xgb_reg__max_depth = maxDepth, xgb_reg__learning_rate = learnRate,
                xgb_reg__reg_alpha = alpha, xgb_reg__subsample = subsample, 
                xgb_reg__colsample_bytree = colsample_bytree, xgb_reg__colsample_bylevel = colsample_bylevel,
                xgb_reg__colsample_bynode = colsample_bynode)

    # Train Model
    pipe.fit(X_train,y_train)
    y_pred = pipe.predict(X_test)

    # Evaluation
    mse = mean_squared_error(y_test, y_pred)
    r2 = r2_score(y_test, y_pred)

    # Save Model
    fullpath = 'slag_temp_xgboost.pkl'
    pickle.dump(pipe, open(fullpath, 'wb'))

    return mse, r2, fullpath