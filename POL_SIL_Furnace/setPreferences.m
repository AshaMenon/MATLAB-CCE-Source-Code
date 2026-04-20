%Set preferences script
function setPreferences()
    %SETBRANCHPROFPREFERENCES Sets preferences for running Polokwane SIL
    %Furnace models
    groupName = 'PolokwaneSIL';
    
    rootFolder = fileparts(mfilename('fullpath'));
    srcFolder = fullfile(fileparts(mfilename('fullpath')), 'src');
    dataFolder = fullfile(rootFolder, 'data');

    setpref(groupName, 'RootFolder', rootFolder);
    setpref(groupName, 'DataFolder', dataFolder);
    setpref(groupName, 'SrcFolder', srcFolder);


    setpref('CCECalcDev', 'OutputFolder', 'ModelOut\');
    setenv('CCE_Root', 'CCEHelp\');

end
