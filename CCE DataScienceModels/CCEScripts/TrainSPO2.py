# -*- coding: utf-8 -*-
"""
Created on Wed Jul 13 10:39:09 2022

@author: antonio.peters
"""

# Import relevant modules
import datetime as dt
import pandas as pd
import CCEScripts.common.cce_logger as cce_logger
import CCEScripts.common.calculation_error_state as ces

from Shared.DSModel.src import featureEngineeringHelpers as feh

from modelClasses.SPO2Model import SPO2Model
from modelClasses.SPO2Data import SPO2Data
from Shared.DSModel.Config import Config

def TrainSPO2(parameters, inputs):
    
    outputs = {}
    
    # Create Log
    log_file = parameters['LogName']
    calculation_id = parameters['CalculationID']
    log_level = parameters['LogLevel']
    calculation_name = parameters['CalculationName']
    log = cce_logger.CCELogger(log_file, calculation_name, calculation_id, log_level)
    error_code = ces.CalculationErrorState.GOOD.value
    log.log_info('--------------------------------------------------------------')
    log.log_info('Beginning Training SPO2 Model')
    
    try:
        
        if type(inputs) is dict:
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
                
        num_ts = len(inputsDF['Ni Slag'])
        if num_ts == 0:
            error_code = ces.CalculationErrorState.NODATA.value
            raise Exception('Not enough data to perform TrainSPO2')
            
        log.log_debug('Creating Config Object')
        parameters['highFrequencyPredictorTags'] = ["Specific Oxygen Actual PV"]

        parameters['lowFrequencyPredictorTags'] = ['Matte temperatures','Ni Slag',
                                                   'Fe Matte', 'S Slag', 'Corrected Ni Slag',
                                                   'Specific Oxygen Operator SP SP1',
                                                   'Specific Oxygen Calculated SP SP2']

        parameters['referenceTags'] = ["Specific Silica Actual PV", "Matte feed PV filtered",
                                        "Lance oxygen flow rate PV", "Lance air flow rate PV",
                                        "Lance feed PV", "Silica PV", "Lump Coal PV",
                                        "Matte transfer air flow", "Fuel coal feed rate PV",
                                        'Converter mode', 'Lance air and oxygen control',
                                        'SumOfSpecies']

        parameters['addMeasureIndicatorsAsPredictors'] = {'add': True, 'on': ['Fe Matte', 
                                                                              'Specific Oxygen Operator SP SP1',
                                                                              'Ni Slag',
                                                                              'Corrected Ni Slag',
                                                                              'S Slag']}

        parameters['addShiftsToPredictors'] = {'add': False, 'nLags':3}
        parameters['responseTags'] = ["Basicity"]

        configModel = Config(parameters, log)

    # Setup the Data
        log.log_debug('Creating Data Object')
        dataModel = SPO2Data(inputsDF, log)
        measDF, groundTruthCorrNiSlag, FeMatte, origSmoothedResponses, predictorTagsNew = dataModel.preprocessSPO2(configModel)
    
        thermoDF = pd.read_table(parameters['pathToThermo'],delimiter=';')
    
        # Setup the Model
        responseTag = configModel.getParameters("responseTags")
        log.log_debug('Creating SPO2 Model Object')
        model = SPO2Model(measDF, thermoDF, predictorTagsNew, responseTag, origSmoothedResponses, logger=log)

    # Train the Model
        path = configModel.getParameters('Path')
        modelName = configModel.getParameters('CalculationName')
        fullpath, thermoMdlStats = model.train(path, modelName)
        
        log.log_debug('Outputting Basicity Model to Pi AF')
        outputs = {}
        outputs['Timestamp'] = feh.datenum(dt.datetime.now())
        outputs['RMSE'] = thermoMdlStats['RMSE']
        outputs['R2Test'] = thermoMdlStats['R2 test']
        outputs['R2CrossVal'] = thermoMdlStats['R2 cross-val']
        outputs['PolynomialDegree'] = thermoMdlStats['Polynomial degree']
        outputs['PoissonAlpha'] = thermoMdlStats['Poisson alpha']
        outputs['NumTerms'] = thermoMdlStats['Number of terms']
        outputs['modelPath'] = fullpath
        
        log.log_info('--------------------------------------------------------------')
        log.log_info('Sucessfully Completed Training SPO2 Model')
        log.log_info('--------------------------------------------------------------')
    except Exception as e:
        outputs = {}
        outputs['Timestamp'] = []
        outputs['RMSE'] = []
        outputs['R2Test'] = []
        outputs['R2CrossVal'] = []
        outputs['PolynomialDegree'] = []
        outputs['PoissonAlpha'] = []
        outputs['NumTerms'] = []
        outputs['modelPath'] = []
        
        log.log_error(str(e))
        if error_code == ces.CalculationErrorState.GOOD.value or (isinstance(error_code, list) and len(error_code) == 0):
            error_code = ces.CalculationErrorState.CALCFAILED.value
    
    return [outputs, error_code]
