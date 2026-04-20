%% Load data and run simulation
% read inputs from file

inputsTT = readtable("POL_SIL_Data_20241023_2024AugData.xlsx", "Sheet", "Sheet1");
% simulate missing ladle weights
SAMPLES_MISSING_END = height(inputsTT) - 1;
inputsTT.MatteTappedLadleEastTon(end-SAMPLES_MISSING_END+1:end) = inputsTT.MatteTappedLadleEastTon(end-SAMPLES_MISSING_END);
inputsTT.MatteTappedLadleCenterTon(end-SAMPLES_MISSING_END+1:end) = inputsTT.MatteTappedLadleCenterTon(end-SAMPLES_MISSING_END);
inputsTT.MatteTappedLadleWestTon(end-SAMPLES_MISSING_END+1:end) = inputsTT.MatteTappedLadleWestTon(end-SAMPLES_MISSING_END);
[simOutNoWeights, simInTTNoWeights, parameters] = runMassBalanceTest(inputsTT=inputsTT, showPlots=true);
