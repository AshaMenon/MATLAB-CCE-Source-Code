%% Oscillation Detection Example
%% Setup
addpath(fullfile('..','common'));
%% Load Data & Parameters
dataTbl = readtimetable(fullfile('..','..','mockData','oscillationDetectionSample.csv'));
inputs.PV = dataTbl.PV;
inputs.PVTimestamps = dataTbl.Date;
inputs.RRCount = dataTbl.reversalCount(end);
inputs.OscCount = dataTbl.oscillationCount(end);
parameters.TSample = 10;
parameters.Fs = 850;
parameters.RRWsize = 100;
parameters.PVThreshold = 10000;
parameters.TIntegral = 500;
parameters.Rmax = 10;
% parameters.LogName = fullfile(pwd,'oscillationDetection');
parameters.LogName = 'oscillationDetection';
parameters.CalculationID = 'osc001';
parameters.LogLevel = 'Info';
parameters.CalculationName = 'Oscillation Detection';
%% MATLAB Example
outputs = oscillationDetection(parameters,inputs);

%% MLProdServer Example
hostName = 'ons-mps:9920';
%hostName = 'localhost:9910';

archive = 'oscillationDetection';
functionName = 'oscillationDetection';
functionInputs = {parameters,inputs};
numOfOutputs = 1;

output = callMLProdServer(hostName,archive,...
        functionName, functionInputs, numOfOutputs);

