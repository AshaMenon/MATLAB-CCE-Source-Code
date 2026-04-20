# -*- coding: utf-8 -*-
"""
Python Calculation Template
This a template for CCE Python calculations. 
Replace calculationTemplate with the calculation name.
parameters is a dict that includes data that does not have a value in time and 
can be considered constants. 
inputs have one or more historical values for a particular element/attribute 
based on the output time. 
"""

# Import relevant modules
import datetime as dt
import numpy as np
import cce_logger
import calculation_error_state as ces

# This is a function to convert MATLAB datetimes to Python datetimes
def matlab_to_datetime(matlab_datenum):
    """Convert matlab time to python time."""
    if matlab_datenum is None or np.isnan(matlab_datenum):
        return np.nan
    python_datetime = dt.datetime.fromordinal(int(matlab_datenum)) \
        + dt.timedelta(days=matlab_datenum % 1) - dt.timedelta(days=366)
    return python_datetime

def calcTemplate(parameters, inputs):
    
    # Create Log
    log_file = parameters['LogName']
    calculation_id = parameters['CalculationID']
    log_level = parameters['LogLevel']
    calculation_name = parameters['CalculationName']
    log = cce_logger.CCELogger(log_file, calculation_name, calculation_id, log_level)
    error_code = ces.CalculationErrorState.GOOD.value
    
    try:
       
        outputs = {}
        
        # Assign Parameters
        parameter1 = parameters['Parameter1']
        
        # Assign Inputs
        input1 = inputs['Input1'] 
        input1Timestamps = inputs['Input1Timestamps'] 
      
        # Convert timestamps
        input1Timestamps = [matlab_to_datetime(t) for t in input1Timestamps]
        
        # Calculation logic goes here
        outputs['Output1'] = input1 + parameter1
        outputs['Timestamp'] = input1Timestamps
		
    except Exception as e:
        outputs['Output1'] = []
		output['Timestamp'] = []
        log.log_error(str(e))
        if error_code == ces.CalculationErrorState.GOOD.value or (isinstance(error_code, list) and len(error_code) == 0):
            error_code = ces.CalculationErrorState.CALCFAILED.value
    
    return [outputs, error_code]


