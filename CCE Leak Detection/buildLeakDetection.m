% Build leak detection
addpath("acpLeakDetection")
buildCalc("acpLeakDetection", {'acpLeakDetection'}, {''})
rmpath("acpLeakDetection")

% Build leak detection train
addpath("acpLeakDetectionTrain")
buildCalc("acpLeakDetectionTrain", {'acpLeakDetectionTrain'}, {''})
rmpath("acpLeakDetectionTrain")