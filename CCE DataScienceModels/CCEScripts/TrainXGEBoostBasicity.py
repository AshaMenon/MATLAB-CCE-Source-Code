# -*- coding: utf-8 -*-
"""
Created on Tue Apr 26 14:18:24 2022

@author: antonio.peters
"""

"""
Linear Basicity Train CCE Script
This a template for CCE Python calculations. 
Replace calculationTemplate with the calculation name.
parameters is a dict that includes data that does not have a value in time and 
can be considered constants. 
inputs have one or more historical values for a particular element/attribute 
based on the output time. 
"""

# Import relevant modules
import datetime as dt
import pandas as pd
import Shared.DSModel.common.cce_logger as cce_logger
import Shared.DSModel.common.calculation_error_state as ces

from modelClasses.XGEBoostBasicityModel import XGEBoostBasicityModel
from Shared.DSModel.src import featureEngineeringHelpers as feh
from Shared.DSModel.Data import Data
from Shared.DSModel.Config import Config

def TrainXGEBoostBasicity(parameters, inputs):
    
    outputs = {}
    
    # Create Log
    log_file = parameters['LogName']
    calculation_id = parameters['CalculationID']
    log_level = parameters['LogLevel']
    calculation_name = parameters['CalculationName']
    log = cce_logger.CCELogger(log_file, calculation_name, calculation_id, log_level)
    error_code = ces.CalculationErrorState.GOOD.value
    
    log.log_info('--------------------------------------------------------------')
    log.log_info('Beginning Training XGEBoost Basicity Model')
    
    try:
        
        if isinstance(inputs, dict):
            log.log_debug('Converting Data from MATLAB Struct input to DataFrame')
            # Convert timestamps
            newInputs = {}
            for key, value in inputs.items():
                newInputs[key.replace('_', ' ')] = value
            newInputs['Timestamp'] = [feh.matlab_to_datetime(t) for t in newInputs['Timestamp']] 
            inputsDF = pd.DataFrame.from_dict(newInputs)  
            inputsDF = feh.formatMatlabData(inputsDF, log)
        else:
            inputsDF = inputs    
                
        num_ts = len(inputsDF['CaO Slag'])
        if num_ts == 0:
            error_code = ces.CalculationErrorState.NODATA.value
            raise Exception('Not enough data to perform TrainXGEBoostBasicity')

        # Setup the Config
        log.log_debug('Creating Config Object')
        parameters['highFrequencyPredictorTags'] = ["Specific Oxygen Actual PV", "Specific Silica Actual PV", 
                                                    "Matte feed PV filtered", "Lance oxygen flow rate PV", 
                                                    "Lance air flow rate PV", "Lance feed PV", "Silica PV", 
                                                    "Lump Coal PV", "Matte transfer air flow", 
                                                    "Fuel coal feed rate PV"]

        parameters['lowFrequencyPredictorTags'] = ["Fe Slag", "MgO Slag", "CaO Slag", "SiO2 Slag", 
                                                   "Al2O3 Slag", "Ni Slag", "S Slag", "S Matte", 
                                                   "Slag temperatures", "Matte temperatures", "Fe Feedblend", 
                                                   "S Feedblend", "SiO2 Feedblend", "Al2O3 Feedblend", 
                                                   "CaO Feedblend", "MgO Feedblend", "Cr2O3 Feedblend", 
                                                   "Corrected Ni Slag", "Fe Matte"]

        parameters['referenceTags'] = ["Converter mode", "Lance air and oxygen control", "SumOfSpecies"]

        parameters['addMeasureIndicatorsAsPredictors'] = {'add': True, 'on': [ 'Basicity', 'Fe Feedblend', 
                                                                              'Matte temperatures']}

        parameters['addShiftsToPredictors'] = {'add': True, 'nLags': 5, 'on': parameters['highFrequencyPredictorTags']}
        
        parameters['addRollingSumPredictors'] = {'add': True, 'window': 19};
        parameters['addRollingMeanPredictors'] = {'add': True, 'window': 5};
        parameters['addResponsesAsPredictors'] = {'add': True, 'nLags': 3};


        
        parameters['responseTags'] = ["Basicity"]

  
        configModel = Config(parameters, log)

        # Setup the Data
        log.log_debug('Creating Data Object')
        dataModel = Data(inputsDF, log)
        dataConf = configModel.getParameters(["highFrequencyPredictorTags", "lowFrequencyPredictorTags", "responseTags",
                                              "referenceTags", "removeTransientData", "smoothBasicityResponse",
                                              "addRollingSumPredictors", "addRollingMeanPredictors",
                                              "addMeasureIndicatorsAsPredictors", "addShiftsToPredictors",
                                              "addResponsesAsPredictors", "resampleTime", "resampleMethod"])
        fullDF, origSmoothedResponses, predictorTagsNew = dataModel.preprocessingAndFeatureEngineering(**dataConf)

        # Setup the Model
        responseTag = configModel.getParameters("responseTags")
        log.log_debug('Creating Basicity Model Object')
        XGEBModel = XGEBoostBasicityModel(fullDF, predictorTagsNew, responseTag, origSmoothedResponses, logger=log)

        # Train the Model
        trainFrac = configModel.getParameters('trainFrac')
        maxTrainSize = int(configModel.getParameters('maxTrainSize'))
        testSize = int(configModel.getParameters('testSize'))
        numIters = int(configModel.getParameters('numIters'))
        path = configModel.getParameters('Path')
        modelName = configModel.getParameters('CalculationName')
        
        explained_variance, mean_absolute_error, mse, r2, fullpath = XGEBModel.train(trainFrac, maxTrainSize, testSize, numIters, path, modelName)
        
        log.log_debug('Outputting Basicity Model to Pi AF')
        outputs = {}
        outputs['Timestamp'] = float(feh.datenum(dt.datetime.now()))
        outputs['ExplainedVariance'] = explained_variance
        outputs['MeanAbsError'] = mean_absolute_error
        outputs['MSE'] = mse
        outputs['R2'] = r2
        outputs['ModelPath'] = fullpath
        
        log.log_info('--------------------------------------------------------------')
        log.log_info('Sucessfully Completed Training Linear Basicity Model')
        log.log_info('--------------------------------------------------------------')
    except Exception as e:
        outputs = {}
        outputs['Timestamp'] = []
        outputs['ExplainedVariance'] = []
        outputs['MeanAbsError'] = []
        outputs['MSE'] = []
        outputs['R2'] = []
        outputs['ModelPath'] = []
        
        log.log_error(str(e))
        if error_code == ces.CalculationErrorState.GOOD.value or (isinstance(error_code, list) and len(error_code) == 0):
            error_code = ces.CalculationErrorState.CALCFAILED.value
    
    return [outputs, error_code]


