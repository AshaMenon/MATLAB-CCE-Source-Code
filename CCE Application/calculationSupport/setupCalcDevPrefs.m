%setupCalcDevPrefs Sets the preferences calc development
groupName = 'CCECalcDev';

rootFolder = fileparts(mfilename('fullpath'));
dataFolder = fullfile(fileparts(rootFolder), 'data');
outputFolder = fullfile(fileparts(rootFolder), 'deploy', 'calculations','CTF');

setpref(groupName, 'RootFolder', rootFolder);
setpref(groupName, 'DataFolder', dataFolder);
setpref(groupName, 'OutputFolder', outputFolder);
