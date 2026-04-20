%% Build Script: oscillationDetection
% Builds CTF for oscillationDetection calculation

deployFolderPath =  '\\ons-mps\cceCalcServerDeploy';
buildAndDeploy('oscillationDetection', {'oscillationDetection'},deployFolderPath)
buildAndDeploy('oscillationDetectionNoLog', {'oscillationDetectionNoLog'},deployFolderPath)