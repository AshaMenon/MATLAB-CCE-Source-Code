%setupCalcDev Sets up the paths required for the calculation conversion dev
rootpath = fileparts(mfilename('fullpath'));
addpath(rootpath);
addpath(fullfile(rootpath, '..'));
addpath(fullfile(rootpath, 'common'));
addpath(fullfile(rootpath, 'calculations'));
if exist(fullfile(rootpath, '..', 'data'), 'dir')
    addpath(genpath(fullfile(rootpath, '..', 'data')))
end

cceSetup;

% Run function to set preferences
setupCalcDevPrefs;