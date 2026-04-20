# Import relevant modules
import datetime as dt
import numpy as np
import pandas as pd
import CCEScripts.common.cce_logger as cce_logger
import CCEScripts.common.calculation_error_state as ces

from modelClasses.LinearBasicityModel import LinearBasicityModel
from Shared.DSModel.Data import Data
from Shared.DSModel.Config import Config


# This is a function to convert MATLAB datetimes to Python datetimes
def matlab_to_datetime(matlab_datenum):
    """Convert matlab time to python time."""
    if matlab_datenum is None or np.isnan(matlab_datenum):
        return np.nan
    python_datetime = dt.datetime.fromordinal(int(matlab_datenum)) \
                      + dt.timedelta(days=matlab_datenum % 1) - dt.timedelta(days=366)
    return python_datetime


def EvaluateLinearBasicity(parameters, inputs):
    outputs = {}

    # Create Log
    log_file = parameters['LogName']
    calculation_id = parameters['CalculationID']
    log_level = parameters['LogLevel']
    calculation_name = parameters['CalculationName']
    log = cce_logger.CCELogger(log_file, calculation_name, calculation_id, log_level)
    error_code = ces.CalculationErrorState.GOOD.value

    try:

        if isinstance(inputs, dict):
            # Assign Inputs
            inputTimestamps = inputs['Timestamp']
            # Convert timestamps
            inputs['Timestamp'] = [matlab_to_datetime(t) for t in inputTimestamps]
            newNames = [i.replace('_', ' ') for i in inputs.keys()]
            inputs.columns = newNames
            inputs = pd.DataFrame.from_dict(inputs)

        num_ts = len(inputs['CaO Slag'])
        if num_ts == 0:
            error_code = ces.CalculationErrorState.NODATA.value
            raise Exception('Not enough data to perform EvaluateLinearBasicity')

        # Setup the Config
        configModel = Config(parameters)

        # Setup the Data
        dataModel = Data(inputs)
        dataConf = configModel.getParameters(["highFrequencyPredictorTags", "lowFrequencyPredictorTags", "responseTags",
                                              "referenceTags", "removeTransientData", "smoothBasicityResponse",
                                              "addRollingSumPredictors", "addRollingMeanPredictors",
                                              "addMeasureIndicatorsAsPredictors", "addShiftsToPredictors",
                                              "addResponsesAsPredictors", "resampleTime", "resampleMethod"])
        fullDF, origSmoothedResponses, predictorTagsNew = dataModel.preprocessingAndFeatureEngineering(**dataConf)

        # Setup the Model
        responseTag = configModel.getParameters("responseTags")
        LBModel = LinearBasicityModel(fullDF, predictorTagsNew, responseTag, origSmoothedResponses, logger=log)

        # Evaluate the Model
        modelPath = configModel.getParameters("ModelPath")
        predictions = LBModel.evaluate(modelPath)

        outputs = {}
        outputs['Timestamp'] = dt.datetime.now()
        outputs['predictions'] = predictions

    except Exception as e:
        outputs = {}
        outputs['Timestamp'] = []
        outputs['predictions'] = []

        log.log_error(str(e))
        if error_code == ces.CalculationErrorState.GOOD.value or (
                isinstance(error_code, list) and len(error_code) == 0):
            error_code = ces.CalculationErrorState.CALCFAILED.value

    return [outputs, error_code]


