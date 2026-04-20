% Run this in CCE env for building
% createPythonCalcWrapper('../Converter-Slag-Splash/CCEScripts/TrainXGEBoostBasicity.py', 'XGEBoostBasicityModel');
% setupPythonCalcs;

% Run this as soon as MATLAB starts up
setenv('PATH', ['C:\Users\AntonioPeters\Anaconda3\envs\slag-splash-env\Library\bin', pathsep, getenv('PATH')])
addpath(genpath('D:/Opti-Num/Projects/Anglo/Converter-Slag-Splash'));
pyversion 'C:\Users\AntonioPeters\Anaconda3\envs\slag-splash-env\pythonw.exe'
% pyenv("ExecutionMode","OutOfProcess");

[v, exe] = pyversion;
py.multiprocessing.spawn.set_executable(exe)

% XGEBoostBasicityTrain

XGEBoostBasicityEval

% Run this to build the ctf
commonFileList = {'calculation_error_state.py', 'cce_logger.py', 'logger.py',...
    'log_message_level.py', 'Model.py', 'Config.py', 'Data.py', ...
    'featureEngineeringHelpers.py'};
commonFileList = [commonFileList, 'TrainXGEBoostBasicity.py', 'EvaluateXGEBoostBasicity.py' 'XGEBoostBasicityModel.py']; %PUT SPECIFIC MODEL CLASS HERE
componentName = 'XGEBoostBasicityModel';
functionName = {'TrainXGEBoostBasicityModel', 'EvalXGEBoostBasicityModel'};
buildCalc(componentName, functionName, commonFileList);