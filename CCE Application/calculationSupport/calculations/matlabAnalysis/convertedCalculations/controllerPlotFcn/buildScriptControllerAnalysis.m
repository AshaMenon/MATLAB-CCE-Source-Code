%% Build Script: controllerAnalysis
% Builds CTF for controllerAnalysis calculation

run(fullfile('..','..','..','..','..','cceSetup.m'))
run(fullfile('..','..','setupMatlabAnalysisCalcs.m'))

buildCTF('controllerAnalysis', 'controllerAnalysis')