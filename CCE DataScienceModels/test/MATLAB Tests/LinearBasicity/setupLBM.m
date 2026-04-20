% Run this in CCE env for building
createPythonCalcWrapper('../Converter-Slag-Splash/CCEScripts/TrainLinearBasicity.py', 'LinearBasicityModel');
setupPythonCalcs;

% Run this as soon as MATLAB starts up
setenv('PATH', ['C:\Users\AntonioPeters\Anaconda3\envs\slag-splash-env\Library\bin', pathsep, getenv('PATH')])
addpath(genpath('D:/Opti-Num/Projects/Anglo/Converter-Slag-Splash'));
pyversion 'C:\Users\AntonioPeters\Anaconda3\envs\slag-splash-env\pythonw.exe'
pyenv("ExecutionMode","OutOfProcess");

[v, exe] = pyversion;
py.multiprocessing.spawn.set_executable(exe)

LinearBasicityTest

% Run this to build the ctf
commonFileList = {'calculation_error_state.py', 'cce_logger.py', 'logger.py',...
    'log_message_level.py', 'Model.py', 'Config.py', 'Data.py', ...
    'featureEngineeringHelpers.py'};
commonFileList = [commonFileList, 'TrainLiearBasicity.py', 'LinearBasicityModel.py']; %PUT SPECIFIC MODEL CLASS HERE
componentName = 'LinearBasicityModel';
functionName = 'LinearBasicityModel';
buildCalc(componentName, {functionName}, commonFileList);