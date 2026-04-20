import src.preprocessingFunctions as prep
import src.modellingFunctions as mdlFun
import src.dataExploration as visualise
from examples import exampleBasicityModellingLinearModelPipeline as linear
import pandas as pd
import matplotlib.pyplot as plt

predictorTagsNew = linear.predictorTagsNew
predictorTags = linear.predictorTags
responseTags = linear.responseTags
referenceTags = linear.referenceTags
highFreqPredictors = linear.highFreqPredictors
lowFreqPredictors = linear.lowFreqPredictors

simFunc = lambda predictors: linear.pipe.predict(predictors)

# Define the data to be tested
# This would come free from CCE
fullDFOrig = prep.readData("Chemistry")
fullDFOrig = fullDFOrig[(len(fullDFOrig)-12*60):-1]


# This is where the streaming start
fullDFOrig = prep.formatData(fullDFOrig)


length = 6*60 # The window size of the dataframe passed into the streaming functionality
responseStream = []
timestampStream = []
# Emulate streaming version
for ind in range(length, fullDFOrig.shape[0], 1):
    try:
        fullDF, origSmoothedResponses, predictorTagsNew = \
            prep.preprocessingAndFeatureEngineering(
                fullDFOrig,
                removeTransientData=True,
                smoothBasicityResponse=True,
                addRollingSumPredictors={'add': True, 'window': 19},
                # NOTE: functionality exists to process an 'on' key
                addRollingMeanPredictors={'add': True, 'window': 5},
                addMeasureIndicatorsAsPredictors={'add': True,
                                                  'on': ['Basicity', 'Fe Feedblend', 'Matte temperatures']},
                # NOTE: functionality exists to process an 'on' key
                addShiftsToPredictors={'add': True, 'nLags': 5, 'on': highFreqPredictors},
                addResponsesAsPredictors={'add': True, 'nLags': 3},
                resampleTime='1min',
                resampleMethod='linear',
                responseTags=responseTags,
                predictorTags=predictorTags,
                referenceTags=referenceTags,
                highFrequencyPredictorTags=highFreqPredictors,
                lowFrequencyPredictorTags=lowFreqPredictors)

        predictorsStream = fullDF[predictorTagsNew]
        ts = fullDFOrig[(ind-length):ind].index[-1]
        if ts not in predictorsStream.index:
            continue
        else:
            idx = predictorsStream.index.get_loc(ts)
            responseStream.append(simFunc(predictorsStream)[idx])
            timestampStream.append(ts)
    except:
        continue

# Emulate offline version
fullDF, origSmoothedResponses, predictorTagsNew = \
            prep.preprocessingAndFeatureEngineering(
                fullDFOrig,
                removeTransientData=True,
                smoothBasicityResponse=True,
                addRollingSumPredictors={'add': True, 'window': 19},
                # NOTE: functionality exists to process an 'on' key
                addRollingMeanPredictors={'add': True, 'window': 5},
                addMeasureIndicatorsAsPredictors={'add': True,
                                                  'on': ['Basicity', 'Fe Feedblend', 'Matte temperatures']},
                # NOTE: functionality exists to process an 'on' key
                addShiftsToPredictors={'add': True, 'nLags': 5, 'on': highFreqPredictors},
                addResponsesAsPredictors={'add': True, 'nLags': 3},
                resampleTime='1min',
                resampleMethod='linear',
                responseTags=responseTags,
                predictorTags=predictorTags,
                referenceTags=referenceTags,
                highFrequencyPredictorTags=highFreqPredictors,
                lowFrequencyPredictorTags=lowFreqPredictors)
predictorsOffline = fullDF[predictorTagsNew]
responseOffline = simFunc(predictorsOffline)
timestampOffline = fullDF.index

plt.figure()
plt.plot(timestampOffline, responseOffline, 'b.-')
plt.plot(timestampStream, responseStream, 'r.-')
plt.legend(['Offline','Stream'])
plt.title('Offline vs Stream test')
plt.ylabel('Basicity')
plt.xlabel('Time')
plt.show()









