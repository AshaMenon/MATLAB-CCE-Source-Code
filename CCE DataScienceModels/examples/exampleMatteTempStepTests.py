# -*- coding: utf-8 -*-
"""
Matte Temperature Step Tests
"""
import numpy as np
import src.preprocessingFunctions as prep
import src.simulationFunctions as sim
import src.modellingFunctions as mdlFun
import datetime


start_date = datetime.datetime(2021, 9, 7, 0, 0)
end_date = datetime.datetime(2021, 9, 8, 0, 0)
stepSize = np.array(0.2)
responseTags = ["Matte temperatures"]
responseTag = ["Matte temperatures"]
mvTag = "Fuel coal feed rate PV"
constantPredictors = False
disturbanceTags = ["Matte feed PV", "Silica PV", "Lance Oxy Enrich % PV"]

fullDFOrig = prep.readData("Temperature")
fullDFOrig = prep.formatData(fullDFOrig)
stepDataDates = (fullDFOrig.index > start_date) & (fullDFOrig.index <= end_date)
fullDFOrig = fullDFOrig.loc[stepDataDates]


#% Step Tests - Linear Model
heading = 'Step Tests - Linear Model'

from examples import exampleMatteTempModellingLinearModelPipeline as linear
predictorTagsNew = linear.predictorTagsNew
predictorTagsOriginal = linear.predictorTagsOriginal
highFreqPredictorsOriginal = linear.highFreqPredictorsOriginal
lowFreqPredictorsOriginal = linear.lowFreqPredictorsOriginal
referenceTags = linear.referenceTags

def processingFuncLinear(fullDFOrig):
    # Preprocess Heat Transfer features (specific to Temperature Model)
    fullDFOrig = prep.fillMissingHXPoints(fullDFOrig)
    # Add latent features (Specific to Temperature Model)
    fullDFOrig, predictorTags, highFreqPredictors, lowFreqPredictors = \
        prep.addLatentTemperatureFeatures(fullDFOrig, predictorTagsOriginal,
                                          highFreqPredictorsOriginal, lowFreqPredictorsOriginal)
    fullDF, origSmoothedResponses, predictorTagsNew = \
        prep.preprocessingAndFeatureEngineering(
            fullDFOrig,
            removeTransientData=True,
            smoothBasicityResponse=False,
            addRollingSumPredictors={'add': True, 'window': 5, 'on': highFreqPredictors},
            # NOTE: functionality exists to process an 'on' key
            addRollingMeanPredictors={'add': True, 'window': 5, 'on': highFreqPredictors},
            addMeasureIndicatorsAsPredictors={'add': False, 'on': ['Matte temperatures']},
            # NOTE: functionality exists to process an 'on' key
            addShiftsToPredictors={'add': True, 'nLags': 3,
                                   'on': ['Fuel coal feed rate PV rollingmean', 'Fuel coal feed rate PV rollingsum',
                                          'Matte feed PV rollingmean', 'Matte feed PV rollingsum',
                                          'Roof matte feed rate PV rollingmean', 'Roof matte feed rate PV rollingsum']},
            addResponsesAsPredictors={'add': True, 'nLags': 3},
            resampleTime='15min',
            resampleMethod='linear',
            responseTags=responseTag,
            predictorTags=predictorTags,
            highFrequencyPredictorTags=highFreqPredictors,
            lowFrequencyPredictorTags=[],
            referenceTags=referenceTags)

    return fullDF, origSmoothedResponses, predictorTagsNew


simFunc = lambda predictors: linear.linearMdl.predict(mdlFun.transformPredictors(predictors, scale=linear.pipe.named_steps['scaler'], pca=linear.pipe.named_steps['pca']))

sim_run = sim.prepareStepTest(fullDFOrig, stepSize, predictorTagsNew, mvTag, processingFuncLinear, constantPredictors=constantPredictors)
sim_run = sim.performStepTest(simFunc, sim_run)
sim.createStepTestPlots(sim_run, responseTag, mvTag+" rollingsum", heading, disturbanceTags=disturbanceTags)

#%% XGBoost Model
heading = 'Step Tests - XGBoost Model'

from examples import exampleMatteTempModellingXGBoostPipeline as xg
predictorTagsOriginal = xg.predictorTagsOriginal
highFreqPredictorsOriginal = xg.highFreqPredictorsOriginal
lowFreqPredictorsOriginal = xg.lowFreqPredictorsOriginal
predictorTagsNew = xg.predictorTagsNew
referenceTags = xg.referenceTags

def processingFuncXG(fullDFOrig):
    # Preprocess Heat Transfer features (specific to Temperature Model)
    fullDFOrig = prep.fillMissingHXPoints(fullDFOrig)

    # Add latent features (Specific to Temperature Model)
    fullDFOrig, predictorTags, highFreqPredictors, lowFreqPredictors = \
        prep.addLatentTemperatureFeatures(fullDFOrig, predictorTagsOriginal,
                                          highFreqPredictorsOriginal, lowFreqPredictorsOriginal)

    fullDF, origSmoothedResponses, predictorTagsNew = \
        prep.preprocessingAndFeatureEngineering(
            fullDFOrig,
            removeTransientData=True,
            smoothBasicityResponse=False,
            addRollingSumPredictors={'add': True, 'window': 5, 'on': highFreqPredictors},
            # NOTE: functionality exists to process an 'on' key
            addRollingMeanPredictors={'add': True, 'window': 5, 'on': highFreqPredictors},
            addMeasureIndicatorsAsPredictors={'add': True, 'on': ['Matte temperatures']},
            # NOTE: functionality exists to process an 'on' key
            addShiftsToPredictors={'add': True, 'nLags': 3,
                                   'on': ['Fuel coal feed rate PV rollingmean', 'Fuel coal feed rate PV rollingsum',
                                          'Matte feed PV rollingmean', 'Matte feed PV rollingsum',
                                          'Roof matte feed rate PV rollingmean', 'Roof matte feed rate PV rollingsum']},
            addResponsesAsPredictors={'add': True, 'nLags': 3},
            resampleTime='15min',
            resampleMethod='linear',
            responseTags=responseTags,
            predictorTags=predictorTags,
            referenceTags=referenceTags,
            highFrequencyPredictorTags=highFreqPredictors,
            lowFrequencyPredictorTags=[])
    return fullDF, origSmoothedResponses, predictorTagsNew

simFunc = lambda predictors: xg.pipe.predict(mdlFun.transformPredictors(predictors, pca=xg.pipe.named_steps['pca'], scale=xg.pipe.named_steps['scaler']))

sim_run = sim.prepareStepTest(fullDFOrig, stepSize, predictorTagsNew, mvTag, processingFuncXG, constantPredictors=constantPredictors)
sim_run = sim.performStepTest(simFunc, sim_run)
sim.createStepTestPlots(sim_run, responseTag, mvTag+" rollingsum", heading, disturbanceTags=disturbanceTags)