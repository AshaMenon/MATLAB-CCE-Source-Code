# Import relevant modules
from Code import Forecast as forecast
from Code.Forecast import matlab_to_datetime, datenum, formatMatlabData, getTimePeriods
import os

import CCEUtils.common.cce_logger as cce_logger
import CCEUtils.common.calculation_error_state as ces

import pandas as pd

def EvaluateForecastModel(parameters, inputs):
    outputs = {}

    # Create Log
    log_file = parameters['LogName']
    calculation_id = parameters['CalculationID']
    log_level = parameters['LogLevel']
    calculation_name = parameters['CalculationName']
    log = cce_logger.CCELogger(log_file, calculation_name, calculation_id, log_level)
    error_code = ces.CalculationErrorState.GOOD.value

    log.log_info('--------------------------------------------------------------')
    log.log_info('Beginning Evaluating Forecast Model')
    
    try:
        ### Convert from MATLAB struct to DF
        if isinstance(inputs, dict):
            log.log_debug('Converting Data from MATLAB Struct input to DataFrame')

            # Convert timestamps
            newInputs = {}
            for key, value in inputs.items():
                newInputs[key.replace('_', ' ')] = value
         
            timeKey = [key for key, value in newInputs.items() if 'timestamp' in key.lower()]
            newInputs['Timestamp'] = [matlab_to_datetime(t) for t in newInputs[timeKey[0]]]   
            inputsDF = pd.DataFrame.from_dict(newInputs)
            inputsDF = formatMatlabData(inputsDF, log)  
        else:
            inputsDF = inputs       
        fullDF = inputsDF.copy()

        log.log_info('Running for current time: {0}'.format(fullDF.index[-1].to_pydatetime()))

        ### Extract Config Paths for all Sites
        log.log_debug('Getting Site Configurations and Setup')
        configFilePath = parameters['configFilePath']
        # featuresToForecast = parameters['featuresToForecast']
        featuresToForecast = ['TonnesMilled', 'SampleHeadGrade', 'TailsGrade']
        thisSite = parameters['siteName']

        try:
            log.log_debug(f'Running model for Site {thisSite}')
            parentDir = os.getcwd()

            # Instantiate Forecast Model
            timeRefs = getTimePeriods()
            thisForecastObj = forecast(configFilePath, thisSite, timeRefs, featuresToForecast,
                                       timePeriod='YTD', seeqRun=False)
            
            log.log_debug('Loading Model Specific Config File...')
            thisForecastObj.loadConfig(configFilePath)

            log.log_debug('Loading and Processing Raw Data...')
            thisForecastObj.rawDF = fullDF

            thisForecastObj.processData()

            log.log_debug('Fitting Models...')
            # Create Model
            thisForecastObj.fitModel(featuresToForecast)

            log.log_debug('Processing Results for Outputting.')
            # Postprocess Results
            thisForecastObj.processResults()

            thisForecastObj.deriveLatentKPIs('SampleHeadGrade', 'TailsGrade')

        except Exception as e:
            outputs = {}
            outputs['Timestamp'] = [datenum(fullDF.index[-1].to_pydatetime())]
            outputs['TonnesMilledMonthEnd'] = [float("nan")]
            outputs['TonnesMilledYearEnd'] = [float("nan")]
            outputs['SampleHeadGradeMonthEnd'] = [float("nan")] # sample head grade
            outputs['SampleHeadGradeYearEnd'] = [float("nan")] # sample head grade
            outputs['TailsGradeMonthEnd'] = [float("nan")] #tails grade
            outputs['TailsGradeYearEnd'] = [float("nan")] #tails grade
            outputs['TheoreticalRecoveryMonthEnd'] = [float("nan")]
            outputs['TheoreticalRecoveryYearEnd'] = [float("nan")]
            
            log.log_error(str(e))
            # outputs['OutputLog'] = '{0}, {1}'.format(inputsDF.index[-1].to_pydatetime(), str(e))
            log.log_info('Data Processing Error')
            log.log_info('--------------------------------------------------------------')
            return [outputs, error_code]
            
        log.log_debug('Outputting Forecast Output Data to Pi AF')
        monthEndIdx = pd.to_datetime(thisForecastObj.timeRefs['thisMonthEnd']).strftime('%Y-%m-%d')
        yearEndIdx = pd.to_datetime(thisForecastObj.timeRefs['nextYearStart']).strftime('%Y-%m-%d')

        outputs = {}
        outputs['Timestamp'] = [datenum(fullDF.index[-1].to_pydatetime())]
        outputs['TonnesMilledMonthEnd'] = [thisForecastObj.fullResultsDF.loc[monthEndIdx]['TonnesMilled']]
        outputs['TonnesMilledYearEnd'] = [thisForecastObj.fullResultsDF.loc[yearEndIdx]['TonnesMilled']]
        outputs['SampleHeadGradeMonthEnd'] = [thisForecastObj.fullResultsDF.loc[monthEndIdx]['SampleHeadGrade']] # sample head grade
        outputs['SampleHeadGradeYearEnd'] = [thisForecastObj.fullResultsDF.loc[yearEndIdx]['SampleHeadGrade']] # sample head grade
        outputs['TailsGradeMonthEnd'] = [thisForecastObj.fullResultsDF.loc[monthEndIdx]['TailsGrade']] #tails grade
        outputs['TailsGradeYearEnd'] = [thisForecastObj.fullResultsDF.loc[yearEndIdx]['TailsGrade']] #tails grade
        outputs['TheoreticalRecoveryMonthEnd'] = [thisForecastObj.fullResultsDF.loc[monthEndIdx]['TheoreticalRecovery']]
        outputs['TheoreticalRecoveryYearEnd'] = [thisForecastObj.fullResultsDF.loc[yearEndIdx]['TheoreticalRecovery']]
        
        log.log_info('Output data set height: {0}'.format(len(outputs['Timestamp'])))
        log.log_info('--------------------------------------------------------------')
        log.log_info(f'Successfully Completed Evaluating Forecast Model for {thisSite}!')
        log.log_info('--------------------------------------------------------------')
    except Exception as e:
        outputs = {}
        outputs['Timestamp'] = []
        outputs['TonnesMilledMonthEnd'] = [float("nan")]
        outputs['TonnesMilledYearEnd'] = [float("nan")]
        outputs['SampleHeadGradeMonthEnd'] = [float("nan")] # sample head grade
        outputs['SampleHeadGradeYearEnd'] = [float("nan")] # sample head grade
        outputs['TailsGradeMonthEnd'] = [float("nan")] #tails grade
        outputs['TailsGradeYearEnd'] = [float("nan")] #tails grade
        outputs['TheoreticalRecoveryMonthEnd'] = [float("nan")]
        outputs['TheoreticalRecoveryYearEnd'] = [float("nan")]

        log.log_error(str(e))
        # outputs['OutputLog'] = '{0}, {1}'.format(dt.datetime.now(), str(e))
        if error_code == ces.CalculationErrorState.GOOD.value or (
                isinstance(error_code, list) and len(error_code) == 0):
            error_code = ces.CalculationErrorState.CALCFAILED.value

    return [outputs, error_code]