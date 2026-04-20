# -*- coding: utf-8 -*-
"""
Mock Calculation
"""

import datetime as dt
import cce_logger as cce_logger
import calculation_error_state as ces

def EvalMockModel(parameters, inputs):
    outputs = {}
    
     # Create Log
    log_file = parameters['LogName']
    calculation_id = parameters['CalculationID']
    log_level = parameters['LogLevel']
    calculation_name = parameters['CalculationName']
    log = cce_logger.CCELogger(log_file, calculation_name, calculation_id, log_level)
    error_code = ces.CalculationErrorState.GOOD.value

    
    log.log_info('--------------------------------------------------------------')
    log.log_info('Beginning Calculation')
    
    try:
        value = inputs['Value1'] + inputs['Value2']
        outputs['Value'] = value
        outputs['Timestamp'] = datenum(dt.datetime.now())
    except Exception as e:
        outputs['Value'] = [float("nan")]
        log.log_error(str(e))
        
        if error_code == ces.CalculationErrorState.GOOD.value or (
                isinstance(error_code, list) and len(error_code) == 0):
            error_code = ces.CalculationErrorState.CALCFAILED.value
    return [outputs, error_code]
    
def datenum(d):
    return float(366 + d.toordinal() + (d - dt.datetime.fromordinal(d.toordinal())).total_seconds()/(24*60*60))