# -*- coding: utf-8 -*-
"""
Created on Tue Jul 26 15:31:04 2022

@author: antonio.peters
"""
import pandas as pd
import warnings
import Shared.DSModel.common.cce_logger as cce_logger
import Shared.DSModel.common.calculation_error_state as ces
from Shared.DSModel.src import featureEngineeringHelpers as feh

from Shared.DSModel.Config import Config
from modelClasses.SPO2Model import SPO2Model
from Shared.DSModel.Data import Data

def EvaluateSPO2(parameters, inputs):   
    outputs = {}
    
    # Create Log
    log_file = parameters['LogName']
    calculation_id = parameters['CalculationID']
    log_level = parameters['LogLevel']
    calculation_name = parameters['CalculationName']
    log = cce_logger.CCELogger(log_file, calculation_name, calculation_id, log_level)
    error_code = ces.CalculationErrorState.GOOD.value
    
    log.log_info('--------------------------------------------------------------')
    log.log_info('Beginning Evaluating SPO2 Model')
    
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
        
        num_ts = len(inputsDF['Ni Slag'])
        if num_ts == 0:
            error_code = ces.CalculationErrorState.NODATA.value
            raise Exception('Not enough data to perform EvaluateSPO2')
            
        log.log_debug('Creating Config Object')
        parameters['highFrequencyPredictorTags'] = []

        parameters['lowFrequencyPredictorTags'] = ['Matte temperatures','Ni Slag', 'Fe Matte',
                                                   'S Slag', 'Corrected Ni Slag', 'Basicity']

        parameters['referenceTags'] = []

        parameters['addMeasureIndicatorsAsPredictors'] = {'add': False}

        parameters['addShiftsToPredictors'] = {'add': False, 'nLags':3}
        parameters['responseTags'] = []
        
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
                                                  "resampleTime", "resampleMethod"])
            measDF, origSmoothedResponses, predictorTagsNew = dataModel.preprocessingAndFeatureEngineering(**dataConf)
            log.log_info('Data preprocessing completed, final date set size: {0}'.format((measDF.shape)))
        except Exception as e:
            outputs = {}
            outputs['Timestamp'] = [feh.datenum(inputsDF.index[-1].to_pydatetime())]
            outputs['SpO2Change'] = [float("nan")]
            if parameters['NiSlagTarget'] == 0:
                outputs['CalcCorrNiSlag'] = [float("nan")]
                outputs['CalcNiTarget'] = [float("nan")]
            
            log.log_error(str(e))
            log.log_info('Not enough stable data to effectively preprocess')
            log.log_info('--------------------------------------------------------------')
            return [outputs, error_code]
    
        # Setup the Model
        responseTag = configModel.getParameters("responseTags")
        log.log_debug('Creating SPO2 Model Object')
        model = SPO2Model(measDF.iloc[-1], predictorTagsNew, responseTag, origSmoothedResponses, logger=log)

        # Evaluate the Model
        log.log_debug('Evaluating SPO2 Model')
        try:
            dataConf = configModel.getParameters(["modelPath","NiSlagTarget",
                                              "thresholdParam","subtractionParam","multiplierParam",
                                              "setFeMatteTarget","PSO2_const","deadBand"])
        
            requiredChangeInSpO2, theoreticalNiSlagPredictions, corrNiSlag = model.evaluate(**dataConf)
        except Exception as e:
            outputs = {}
            outputs['Timestamp'] = [feh.datenum(inputsDF.index[-1].to_pydatetime())]
            outputs['SpO2Change'] = [float("nan")]
            if parameters['NiSlagTarget'] == 0:
                outputs['CalcCorrNiSlag'] = [float("nan")]
                outputs['CalcNiTarget'] = [float("nan")]
            
            log.log_error(str(e))
            log.log_info('Evaluation error, no output available')
            log.log_info('--------------------------------------------------------------')
            return [outputs, error_code]
        
        log.log_debug('Outputting SPO2 Data to Pi AF')
        outputs = {}
        outputs['Timestamp'] = [feh.datenum(measDF.index[-1].to_pydatetime())]
        outputs['SpO2Change'] = [float(requiredChangeInSpO2)]
        if parameters['NiSlagTarget'] == 0:
            outputs['CalcCorrNiSlag'] = [float(corrNiSlag)]
            outputs['CalcNiTarget'] = [float(theoreticalNiSlagPredictions)]
        
        log.log_info('--------------------------------------------------------------')
        log.log_info('Sucessfully Completed Evaluating SPO2 Change: {0}'.format(outputs['SpO2Change'][-1]))
        log.log_info('--------------------------------------------------------------')
    except Exception as e:
        outputs = {}
        outputs['Timestamp'] = []
        outputs['SpO2Change'] = []
        if parameters['NiSlagTarget'] == 0:
            outputs['CalcCorrNiSlag'] = []
            outputs['CalcNiTarget'] = []
        
        log.log_error(str(e))
        if error_code == ces.CalculationErrorState.GOOD.value or (
                isinstance(error_code, list) and len(error_code) == 0):
            error_code = ces.CalculationErrorState.CALCFAILED.value
            
    return [outputs, error_code]
