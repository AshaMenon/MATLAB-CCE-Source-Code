# Import relevant modules
import warnings
import Shared.DSModel.common.cce_logger as cce_logger
import Shared.DSModel.common.calculation_error_state as ces

from modelClasses.XGEBoostBasicityModel import XGEBoostBasicityModel
from Shared.DSModel.src import featureEngineeringHelpers as feh
from Shared.DSModel.Data import Data
from Shared.DSModel.Config import Config
import pandas as pd


def EvaluateXGEBoostBasicity(parameters, inputs):
    outputs = {}

    # Create Log
    log_file = parameters['LogName']
    calculation_id = parameters['CalculationID']
    log_level = parameters['LogLevel']
    calculation_name = parameters['CalculationName']
    log = cce_logger.CCELogger(log_file, calculation_name, calculation_id, log_level)
    error_code = ces.CalculationErrorState.GOOD.value

    log.log_info('--------------------------------------------------------------')
    log.log_info('Beginning Evaluating XGEBoost Basicity Model')
    
    if parameters['isOnline']:
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
            
        #Select necessary tags only
        inputsDF = feh.getSumOfSpecies(inputsDF)
        log.log_trace('Got Sum of Species')
        
            
        log.log_info('Running for current time: {0}'.format(inputsDF.index[-1].to_pydatetime()))
        log.log_info('Current Converter mode: {0}'.format(inputsDF['Converter mode'].iloc[-1]))
        if inputsDF['Converter mode'].iloc[-1] != 8:
            outputs = {}
            outputs['Timestamp'] = [feh.datenum(inputsDF.index[-1].to_pydatetime())]
            outputs['XGBoostPredictedBasicity'] = [float("nan")]
            outputs['XGBoostUpperPredictedBasicity'] = [float("nan")]
            outputs['XGBoostLowerPredictedBasicity'] = [float("nan")]
            outputs['RequiredChangeInSpSi'] = [float("nan")]
            outputs['DiffInSpSi'] = [float("nan")] 
            outputs['ProcessSteadyState'] = [False]
            outputs['BasicityDelta'] = [0.0]
            outputs['SpSiCount'] = [0.0]
            outputs['CumulativeSpSi'] = [float("nan")]
            outputs['SpSiSetpoint'] = [float("nan")]
            
            hoursOffIdx = int(60*parameters['hoursOff'])
            if (inputsDF['Converter mode'].iloc[-hoursOffIdx:] == 8).any():
                outputs['BlowCount'] = [float(parameters['BlowCountParams'])]
            else:
                outputs['BlowCount'] = [0.0]
                
            log.log_info('Out of Mode 8, unable to calculate, exiting')
            # outputs['OutputLog'] = '{0}, Out of Mode 8, unable to calculate, exiting'.format(inputsDF.index[-1].to_pydatetime())
            log.log_info('--------------------------------------------------------------')
        else:              
            num_ts = len(inputsDF['CaO Slag'])
            if num_ts == 0:
                error_code = ces.CalculationErrorState.NODATA.value
                raise Exception('Not enough data to perform EvaluateXGEBoostBasicity')
            else:
                log.log_info('Input data set height: {0}'.format(num_ts))
    
            # Setup the Config
            log.log_debug('Creating Config Object')
            parameters['highFrequencyPredictorTags'] = ["Specific Oxygen Actual PV", "Specific Silica Actual PV", 
                                                        "Matte feed PV filtered", "Lance oxygen flow rate PV", 
                                                        "Lance air flow rate PV", "Silica PV", 
                                                        "Matte transfer air flow", "Fuel coal feed rate PV"]
            
            parameters['lowFrequencyPredictorTags'] = ["Fe Slag", "MgO Slag", "CaO Slag", "SiO2 Slag", 
                                                       "Al2O3 Slag", "Ni Slag", "S Slag", "S Matte", 
                                                       "Slag temperatures", "Matte temperatures", "Fe Feedblend", 
                                                       "S Feedblend", "SiO2 Feedblend", "Al2O3 Feedblend", 
                                                       "CaO Feedblend", "MgO Feedblend", "Cr2O3 Feedblend", 
                                                       "Corrected Ni Slag", "Fe Matte"]
            
            parameters['referenceTags'] = ["Converter mode", "Lance air and oxygen control", "SumOfSpecies"]
            
            
            parameters['addRollingSumPredictors'] = {'add': True, 'window': '19min'}
            parameters['addRollingMeanPredictors'] = {'add': False, 'window': '5min'}
            parameters['addRollingMeanResponse'] = {'add':True, 'window': '60min'}
            parameters['addDifferenceResponse'] = {'add': True}
            parameters['addMeasureIndicatorsAsPredictors'] = {'add': True, 'on': [ 'Basicity', 'Fe Feedblend', 
                                                                                  'Matte temperatures']}
            parameters['addShiftsToPredictors'] = {'add': True, 'nLags': 3, 'on': parameters['highFrequencyPredictorTags']}
            parameters['addResponsesAsPredictors'] = {'add': True, 'nLags': 1}
            parameters['smoothTagsOnChange'] = {'add': True, 'on': ['Specific Silica Actual PV'], 'threshold': [70]}
            parameters['responseTags'] = ["Basicity"]
            
            configModel = Config(parameters, log)
            
            if parameters['BlowCountParams'] < parameters['nPeaksOff']:
                try:
                    returnedPeaks = Data.checkSteadyStateSignal(inputsDF, int(parameters['hoursOff']), int(parameters['nPeaksOff']), parameters['responseTags'], log)
                
                    if returnedPeaks < parameters['nPeaksOff']:
                        raise Exception('Not enough blows for Steady state, unable to calculate, exiting')
                        
                except Exception as e:
                    outputs = {}
                    outputs['Timestamp'] = [feh.datenum(inputsDF.index[-1].to_pydatetime())]
                    outputs['XGBoostPredictedBasicity'] = [float("nan")]
                    outputs['XGBoostUpperPredictedBasicity'] = [float("nan")]
                    outputs['XGBoostLowerPredictedBasicity'] = [float("nan")]
                    outputs['RequiredChangeInSpSi'] =[float("nan")]
                    outputs['DiffInSpSi'] = [float("nan")] 
                    outputs['ProcessSteadyState'] = [False]
                    outputs['BlowCount'] = [0.0]
                    outputs['BasicityDelta'] = [0.0]
                    outputs['SpSiCount'] = [0.0]
                    outputs['CumulativeSpSi'] = [float("nan")]
                    outputs['SpSiSetpoint'] = [float("nan")]
                    
                    log.log_error(str(e))
                    log.log_info('--------------------------------------------------------------')
                    return [outputs, error_code]                
    
            # Setup the Data
            log.log_debug('Creating Data Object')
            
            try:
                dataModel = Data(inputsDF, log)
                dataConf = configModel.getParameters(["highFrequencyPredictorTags", "lowFrequencyPredictorTags",
                                                      "responseTags", "referenceTags", "removeTransientData",
                                                      "smoothBasicityResponse", "addRollingSumPredictors",
                                                      "addRollingMeanPredictors", "addMeasureIndicatorsAsPredictors",
                                                      "addShiftsToPredictors", "addResponsesAsPredictors",
                                                      "smoothTagsOnChange", "resampleTime", "resampleMethod", 
                                                      "addDifferenceResponse", "addRollingMeanResponse",
                                                      "isOnline", "hoursOff", "nPeaksOff", "cleanResponseTags"])
                fullDF, origSmoothedResponses, predictorTagsNew = dataModel.preprocessingAndFeatureEngineering(**dataConf)
                log.log_info('Data preprocessing completed, final date set size: {0}'.format((fullDF.shape)))
            except Exception as e:
                outputs = {}
                outputs['Timestamp'] = [feh.datenum(inputsDF.index[-1].to_pydatetime())]
                outputs['XGBoostPredictedBasicity'] = [float("nan")]
                outputs['XGBoostUpperPredictedBasicity'] = [float("nan")]
                outputs['XGBoostLowerPredictedBasicity'] = [float("nan")]
                outputs['RequiredChangeInSpSi'] =[float("nan")]
                outputs['DiffInSpSi'] = [float("nan")]
                outputs['ProcessSteadyState'] = [False]
                outputs['BlowCount'] = [float(parameters['nPeaksOff'])]
                outputs['BasicityDelta'] = [float(parameters['BasicityDeltaParam'])]
                outputs['SpSiCount'] = [0.0]
                outputs['CumulativeSpSi'] = [float("nan")]
                outputs['SpSiSetpoint'] = [float("nan")]
                
                log.log_error(str(e))
                # outputs['OutputLog'] = '{0}, {1}'.format(inputsDF.index[-1].to_pydatetime(), str(e))
                log.log_info('Not enough stable data to effectively preprocess')
                log.log_info('--------------------------------------------------------------')
                return [outputs, error_code]
    
            # Setup the Model
            responseTag = configModel.getParameters("responseTags")
            log.log_debug('Creating Basicity Model Object')
    
            XGEBModel = XGEBoostBasicityModel(fullDF, predictorTagsNew, responseTag, origSmoothedResponses, logger=log)
    
            # Evaluate the Model
            log.log_debug('Evaluating Basicity Model')
            try:
                modelPath = configModel.getParameters("ModelPath")
                basicityTarget = configModel.getParameters("basicityTarget")
                deadBand = configModel.getParameters("deadBand")
                silica_high = configModel.getParameters(["silicaHighMin", "silicaHighMax"])
                scilica_low = configModel.getParameters(["silicaLowMin", "silicaLowMax"])
                
                basicityMax = configModel.getParameters(['BasicityTimeMax', 'BasicityLowMax', 'BasicityHighMax', 'BasicityThresholdMax'])
                basicityMid = configModel.getParameters(['BasicityTimeMid', 'BasicityLowMid', 'BasicityHighMid', 'BasicityThresholdMid'])
                basicityDelta = configModel.getParameters("BasicityDeltaParam")
            
                predictions = XGEBModel.evaluate(basicityTarget, deadBand, silica_high, scilica_low, basicityMax, basicityMid, basicityDelta, modelPath)
                
            except Exception as e:
                outputs = {}
                outputs['Timestamp'] = [feh.datenum(inputsDF.index[-1].to_pydatetime())]
                outputs['XGBoostPredictedBasicity'] = [float("nan")]
                outputs['XGBoostUpperPredictedBasicity'] = [float("nan")]
                outputs['XGBoostLowerPredictedBasicity'] = [float("nan")]
                outputs['RequiredChangeInSpSi'] =[float("nan")]
                outputs['DiffInSpSi'] = [float("nan")]
                outputs['ProcessSteadyState'] = [False]
                outputs['BlowCount'] = [float(parameters['nPeaksOff'])]
                outputs['BasicityDelta'] = [float(parameters['BasicityDeltaParam'])]
                outputs['SpSiCount'] = [0.0]
                outputs['CumulativeSpSi'] = [float("nan")]
                outputs['SpSiSetpoint'] = [float("nan")]

                log.log_error(str(e))
                log.log_info('Evaluation error, no output available')
                log.log_info('--------------------------------------------------------------')
                return [outputs, error_code]
                
            log.log_debug('Outputting XGEBoost Basicity Data to Pi AF')
            outputs = {}
            outputs['Timestamp'] = [feh.datenum(inputsDF.index[-1].to_pydatetime())] # Needs to be updated
            outputs['XGBoostPredictedBasicity'] = [predictions['XGBoost Predicted Basicity'][-1]]
            outputs['XGBoostUpperPredictedBasicity'] = [predictions['XGBoost Upper Predicted Basicity'][-1]]
            outputs['XGBoostLowerPredictedBasicity'] = [predictions['XGBoost Lower Predicted Basicity'][-1]]
            outputs['RequiredChangeInSpSi'] =[predictions['XGBoost Predicted Silica Support'][-1]]
            outputs['BasicityDelta'] = [float(predictions['BasicityDelta'][-1])]
            
            outputs['DiffInSpSi'] = [float(outputs['RequiredChangeInSpSi'][-1] - parameters['RequiredChangeInSpSiParam'])]
            outputs['ProcessSteadyState'] = [True]
            outputs['BlowCount'] = [float(parameters['nPeaksOff'])]
            
            outputs = XGEBoostBasicityModel.getSpSiValues(parameters, predictions,
                                                          outputs, origSmoothedResponses,
                                                          fullDF['rawBasicity'], log)
            
            log.log_info('Output data set height: {0}'.format(len(outputs['Timestamp'])))
            log.log_info('--------------------------------------------------------------')
            log.log_info('Successfully Completed Evaluating XGEBoost Basicity Model: {0}'.format(predictions['XGBoost Predicted Basicity'][-1]))
            log.log_info('--------------------------------------------------------------')
    except Exception as e:
        outputs = {}
        outputs['Timestamp'] = []
        outputs['XGBoostPredictedBasicity'] = []
        outputs['XGBoostUpperPredictedBasicity'] = []
        outputs['XGBoostLowerPredictedBasicity'] = []
        outputs['RequiredChangeInSpSi'] = []
        outputs['DiffInSpSi'] = []
        outputs['ProcessSteadyState'] = []
        outputs['BlowCount'] = []
        outputs['BasicityDelta'] = []
        outputs['SpSiCount'] = []
        outputs['CumulativeSpSi'] = []
        outputs['SpSiSetpoint'] = []


        log.log_error(str(e))
        # outputs['OutputLog'] = '{0}, {1}'.format(dt.datetime.now(), str(e))
        if error_code == ces.CalculationErrorState.GOOD.value or (
                isinstance(error_code, list) and len(error_code) == 0):
            error_code = ces.CalculationErrorState.CALCFAILED.value

    return [outputs, error_code]


