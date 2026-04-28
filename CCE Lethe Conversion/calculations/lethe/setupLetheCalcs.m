%Setup dev environment for Lethe calcs

convertedCalcsRootFolder = fileparts(mfilename("fullpath"));

addpath(fullfile(convertedCalcsRootFolder, 'convertedCalculations'));
if exist(fullfile(getpref('CCECalcDev', 'DataFolder'), 'LetheCalcs'), 'dir')
    addpath(genpath(fullfile(getpref('CCECalcDev', 'DataFolder'), 'LetheCalcs')));
end

%Add specific calc folders here as desired:
addpath(fullfile(convertedCalcsRootFolder, 'convertedCalculations', 'cceLetheAverage'));
addpath(fullfile(convertedCalcsRootFolder, 'convertedCalculations', 'cceLetheSum'));
addpath(fullfile(convertedCalcsRootFolder, 'convertedCalculations', 'cceLetheTails'));
addpath(fullfile(convertedCalcsRootFolder, 'convertedCalculations', 'cceLetheComponentArray'));
addpath(fullfile(convertedCalcsRootFolder, 'convertedCalculations', 'cceLetheAccountability'));
addpath(fullfile(convertedCalcsRootFolder, 'convertedCalculations', 'cceLetheAssay'));
addpath(fullfile(convertedCalcsRootFolder, 'convertedCalculations', 'cceLetheRecovery'));
addpath(fullfile(convertedCalcsRootFolder, 'convertedCalculations', 'cceLetheBUH'));
addpath(fullfile(convertedCalcsRootFolder, 'convertedCalculations', 'cceLetheEstimate'));
addpath(fullfile(convertedCalcsRootFolder, 'convertedCalculations', 'cceLetheSubstitute'));
addpath(fullfile(convertedCalcsRootFolder, 'convertedCalculations', 'cceLetheComponent'));
addpath(fullfile(convertedCalcsRootFolder, 'convertedCalculations', 'cceLetheMassPull'));
addpath(fullfile(convertedCalcsRootFolder, 'convertedCalculations', 'cceLethePeriodSum'));
addpath(fullfile(convertedCalcsRootFolder, 'convertedCalculations', 'cceLetheDryMass'));
addpath(fullfile(convertedCalcsRootFolder, 'convertedCalculations', 'cceLetheMapReduce'));
addpath(fullfile(convertedCalcsRootFolder, 'convertedCalculations', 'cceLethePeriodAverage'));
addpath(fullfile(convertedCalcsRootFolder, 'convertedCalculations', 'cceLethePebblesAndSpillagesMer'));
addpath(fullfile(convertedCalcsRootFolder, 'convertedCalculations', 'cceLethePebblesAndSpillagesUG'));
addpath(fullfile(convertedCalcsRootFolder, 'convertedCalculations', 'cceLethePeriodWeighting'));
addpath(fullfile(convertedCalcsRootFolder, 'convertedCalculations', 'cceACExDaysTotals'));
addpath(fullfile(convertedCalcsRootFolder, 'convertedCalculations', 'cceLetheTheoreticalRecovery'));