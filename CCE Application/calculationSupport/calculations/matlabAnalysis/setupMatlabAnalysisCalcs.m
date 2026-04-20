%Setup dev environment for Matlab Analysis calcs
convertedCalcsRootFolder = fileparts(mfilename("fullpath"));
addpath(fullfile(convertedCalcsRootFolder));
addpath(fullfile(convertedCalcsRootFolder, 'convertedCalculations'));
% addpath(fullfile(getpref('CCECalcDev', 'DataFolder'), 'matlabAnalysis'));

%Add specific calc folders here as desired:
addpath(fullfile(convertedCalcsRootFolder, 'convertedCalculations', 'controllerPlotFcn'));