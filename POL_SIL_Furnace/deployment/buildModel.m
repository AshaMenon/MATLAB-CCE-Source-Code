load('init.mat') % load required variables into workspace
load('inputBusObj.mat')

wrapperNames = {'ccePolokwaneSILWrapper','cceCalcMatteFallFractionsAveWrapper','cceCalcMatteTapRatesHybridWrapper','cceCalcSlagTapRatesWrapper'};
componentNames = ["ccePolokwaneSIL", "cceMatteFallAve", "cceMatteTap","cceSlagTapRatesCalc"];
additionalFiles = {which("constants.sldd"),which("inputBusObj.mat")};

buildCalc("ccePolokwaneSIL", wrapperNames, additionalFiles)
buildCalc("cceSoundingCalculation", {'cceCalcSoundingValuesWrapper'}, {''})
