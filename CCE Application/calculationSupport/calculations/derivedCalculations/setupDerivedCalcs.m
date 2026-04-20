%Setup dev environment for derived calcs
convertedCalcsRootFolder = fileparts(mfilename("fullpath"));
addpath(fullfile(convertedCalcsRootFolder));
addpath(fullfile(convertedCalcsRootFolder, 'convertedCalculations'));

%Add specific calc folders here as desired:
addpath(genpath(fullfile(convertedCalcsRootFolder, 'convertedCalculations')));