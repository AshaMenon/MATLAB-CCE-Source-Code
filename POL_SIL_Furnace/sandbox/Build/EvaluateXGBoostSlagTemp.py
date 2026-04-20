# Import relevant modules

import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_squared_error, r2_score 
from sklearn.model_selection import TimeSeriesSplit
from sklearn.pipeline import Pipeline
import data_preprocessing as dp
import datetime as dt
import pickle

def evaluate_XGBoost_slag_temp_model(parameters, inputs):
    # Create Log
   # log_file = parameters['LogName']
   # calculation_id = parameters['CalculationID']
   # log_level = parameters['LogLevel']
   # calculation_name = parameters['CalculationName']
   # log = cce_logger.CCELogger(log_file, calculation_name, calculation_id, log_level)
   # error_code = ces.CalculationErrorState.GOOD.value
    
    #log.log_info('--------------------------------------------------------------')
    #log.log_info('Evaluating Slag Temperature Model')

    [ _, feature_df_smoothed] = dp.model_data_preprocessing(inputs)
    model_path = parameters['Model Path']

    # Load Model
    model = pickle.load(open(model_path, 'rb'))

    # Prediction
    slag_temperature = model.predict(feature_df_smoothed)


    outputs = {}
    outputs['Timestamp'] = dt.datetime.now()
    outputs['Slag Temperature'] = slag_temperature


    return outputs
        
    #log.log_info('--------------------------------------------------------------')
    #log.log_info('Sucessfully Completed Evaluating XGBoost Slag Temperature Model')
    #log.log_info('--------------------------------------------------------------')
