# -*- coding: utf-8 -*-
"""
Created on Thu Apr  6 11:45:59 2023

@author: john.atherfold
"""

import pandas as pd
import warnings
import Shared.DSModel.common.cce_logger as cce_logger
import Shared.DSModel.common.calculation_error_state as ces
from Shared.DSModel.src import featureEngineeringHelpers as feh

from Shared.DSModel.Config import Config
from Shared.DSModel.Data import Data

def EvaluateAlignedFeMatte(parameters, inputs):   
    outputs = {}
    
    # Create Log
    log_file = parameters['LogName']
    calculation_id = parameters['CalculationID']
    log_level = parameters['LogLevel']
    calculation_name = parameters['CalculationName']
    log = cce_logger.CCELogger(log_file, calculation_name, calculation_id, log_level)
    error_code = ces.CalculationErrorState.GOOD.value
    
    log.log_info('--------------------------------------------------------------')
    log.log_info('Beginning Evaluating Aligned Fe Matte')
    
    warnings.simplefilter("ignore")
    
    try:
        if isinstance(inputs, dict):
            log.log_debug('Converting Data from MATLAB Struct input to DataFrame')
            # Convert timestamps
            newInputs = {}
            for key, value in inputs.items():
                newInputs[key.replace('_', ' ')] = value
         
            timeKey = [key for key, value in newInputs.items() if 'timestamp' in key.lower()]
            newInputs['Timestamp'] = [feh.matlab_to_datetime(t) for t in newInputs[timeKey[0]]]   
            inputsDF = pd.DataFrame.from_dict(newInputs)
            inputsDF = feh.formatMatlabData(inputsDF, log)  
        else:
            inputsDF = inputs    
         
        log.log_info('Running for current time: {0}'.format(inputsDF.index[-1].to_pydatetime()))
    
            
        log.log_debug('Creating Config Object')
        parameters['highFrequencyPredictorTags'] = []

        parameters['lowFrequencyPredictorTags'] = ['Fe Matte']

        parameters['referenceTags'] = ["Converter mode", "Lance air and oxygen control"]

        parameters['addMeasureIndicatorsAsPredictors'] = {'add': False}
        
        parameters['addSteadyState'] = [True]

        parameters['addShiftsToPredictors'] = {'add': False, 'nLags':3}
        parameters['responseTags'] = ["Basicity"]
        
        parameters['addRollingSumPredictors'] = {'add': False, 'window':30};
        parameters['addRollingMeanPredictors'] = {'add': False, 'window':5};  
        parameters['addResponsesAsPredictors'] = {'add': False, 'nLagsD':1};
        
        configModel = Config(parameters, log)

         # Setup the Data
        log.log_debug('Creating Data Object')
        
        try:
            dataModel = Data(inputsDF, log)
            dataConf = configModel.getParameters(["highFrequencyPredictorTags", "lowFrequencyPredictorTags", "responseTags",
                                                  "referenceTags", "removeTransientData", "smoothBasicityResponse",
                                                  "addMeasureIndicatorsAsPredictors", "addShiftsToPredictors",
                                                  "resampleTime", "resampleMethod", "addSteadyState", "nPeaksOff"])
            fullDF, _, _ = dataModel.preprocessingAndFeatureEngineering(**dataConf)
            log.log_info('Data preprocessing completed, final date set size: {0}'.format((fullDF.shape)))
        except Exception as e:
            outputs = {}
            outputs['Timestamp'] = [feh.datenum(inputsDF.index[-1].to_pydatetime())]
            # outputs['Timestamp'] = [inputsDF.index[-1].to_pydatetime()]
            outputs['AlignedFeMatte'] = [float("nan")]
            
            log.log_error(str(e))
            log.log_info('Not enough stable data to effectively preprocess')
            log.log_info('--------------------------------------------------------------')
            return [outputs, error_code]
    
        try:
            # Get Blow Times
            log.log_debug('Getting Blowtimes')
            blowTimes = fullDF[fullDF['Peaks']==True].index
            
            # Reassign Timestamps
            log.log_debug('Aligning Fe with Blowtimes')
            measurementChanges, _ = feh.getUniqueDataPoints(fullDF["Fe Matte"])
            newTimes, newMeasurements = feh.reassignTimestamps(blowTimes, measurementChanges)
            log.log_debug('Blowtime realigned')
            
            # Define outputs
            outputs = {}
            outputs ['Timestamp'] = [feh.datenum(newTimes[-1].to_pydatetime())]
            # outputs ['Timestamp'] = [newTimes[-1].to_pydatetime()]
            outputs['AlignedFeMatte'] = [newMeasurements[-1]]
                    
        except Exception as e:
            outputs = {}
            outputs['Timestamp'] = [feh.datenum(inputsDF.index[-1].to_pydatetime())]
            # outputs['Timestamp'] = [inputsDF.index[-1].to_pydatetime()]
            outputs['AlignedFeMatte'] = [float("nan")]
            
            log.log_error(str(e))
            log.log_info('Evaluation error, no output available')
            log.log_info('--------------------------------------------------------------')
            return [outputs, error_code]
        
        log.log_info('--------------------------------------------------------------')
        log.log_info('Sucessfully Completed Aligning Fe Matte')
        log.log_info('--------------------------------------------------------------')
    except Exception as e:
        outputs = {}
        outputs['Timestamp'] = []
        outputs['AlignedFeMatte'] = [float("nan")]
        
        log.log_error(str(e))
        if error_code == ces.CalculationErrorState.GOOD.value or (
                isinstance(error_code, list) and len(error_code) == 0):
            error_code = ces.CalculationErrorState.CALCFAILED.value
            
    return [outputs, error_code]
