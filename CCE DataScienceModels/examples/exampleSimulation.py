from examples import exampleBasicityModellingLinearModelPipeline as linear
import src.modellingFunctions as modelling
import src.simulationFunctions as simulation

testDF = linear.testDF[1:100]
responseTags = linear.responseTags
predictorTags = linear.predictorTags
refTags = ["Specific Silica Actual PV"]

simFunc = lambda xData: modelling.simModel(linear.linearMdl, xData)
simulation.simulate(simFunc, testDF, predictorTags, responseTags, refTags)
