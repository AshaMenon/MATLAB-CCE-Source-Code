# Import relevant modules
import datetime as dt
import numpy as np
import cce_logger
import calculation_error_state as ces
import Code.Forecast as forecast
from Code import SeeqFormatting as sf
import pandas as pd

# This is a function to convert MATLAB datetimes to Python datetimes
def matlab_to_datetime(matlab_datenum):
    """Convert matlab time to python time."""
    if matlab_datenum is None or np.isnan(matlab_datenum):
        return np.nan
    python_datetime = dt.datetime.fromordinal(int(matlab_datenum)) \
        + dt.timedelta(days=matlab_datenum % 1) - dt.timedelta(days=366)
    return python_datetime

def forecastKPIs(parameters, inputs):
    # Create Logger
    log_file = parameters['LogName']
    calculation_id = parameters['CalculationID']
    log_level = parameters['LogLevel']
    calculation_name = parameters['CalculationName']
    log = cce_logger.CCELogger(log_file, calculation_name, calculation_id, log_level)
    error_code = ces.CalculationErrorState.GOOD.value
    
    try:
       
        outputs = {}
        
        # Assign Parameters
        configFilePath = parameters['configFilePath']
        featuresToForecast = parameters['featuresToForecast']
        siteName = parameters['siteName']

        # Calculation logic goes here
        # Get today's date
        today = pd.Timestamp.now()
        today = today.replace(hour=6, minute=0, second=0, microsecond=0)
        today = today.strftime('%Y-%m-%d %H:%M:%S')

        firstDayOfYear = today.replace(month=1, day=1, hour=6, minute=0, second=0, microsecond=0)
        firstDayOfYear = firstDayOfYear.strftime('%Y-%m-%d %H:%M:%S')

        timeRefs = {'today':today,
                    'yearStart':firstDayOfYear}

        # Instantiate class
        thisSiteForecast = forecast(configFilePath, siteName, timeRefs, featuresToForecast, seeqRun=False)

        thisSiteForecast.loadConfig(configFilePath)

        # Format Inputs
        inputList = []
        columnList = []
        for item in thisSiteForecast.seeqTagsWithLabels:
            rawTagName = item['Name']
            columnList.append(rawTagName)
            inputList.append(inputs[rawTagName])
        rawIdx = inputs[rawTagName + 'Timestamps']
        rawIdx = [matlab_to_datetime(t) for t in rawIdx]
        formattedInputs = pd.DataFrame(index = rawIdx, data = inputList, columns=columnList)

        thisSiteForecast.rawDF = formattedInputs # Assumes inputs are a dataframe indexed by time (hourly) from the start of the year to today, with the raw tag names as columns, corresponding to those in the config

        thisSiteForecast.processData()

        thisSiteForecast.fitModel(featuresToForecast)

        thisSiteForecast.processResults()

        # Formatting Outputs Appropriately
        for feature in featuresToForecast:
            outputs[feature] = thisSiteForecast.resultsDF[feature].iloc[-1]
        outputs['Timestamp'] = today
        
    except Exception as e:
        for feature in featuresToForecast:
            outputs[feature] = []
        outputs['Timestamp'] = []
        log.log_error(str(e))
        if error_code == ces.CalculationErrorState.GOOD.value or (isinstance(error_code, list) and len(error_code) == 0):
            error_code = ces.CalculationErrorState.CALCFAILED.value
    
    return [outputs, error_code]