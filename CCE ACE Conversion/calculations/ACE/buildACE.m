function buildACE(componentName, additionalFiles)
    %BUILDLETHE Automatically builds ACE calculation
    %   Inputs:
    %       componentName - Char of the CTF file, (this is the same name as
    %       the matlab function)
    
    arguments
        componentName char = '';
        additionalFiles = {};
    end
    
    %Find all files in common functions folder
    folderInfo = dir(fullfile("Converted Calculations", componentName, "+CommonFunctions"));
    commonFunctions = {folderInfo.name};
    commonFunctions(~contains(commonFunctions, '.m')) = [];

    additionalFiles = [additionalFiles, commonFunctions];

    if ismember(componentName, "cceACExDaysTotals")
        rootdir = fullfile("Converted Calculations", componentName, "StreamMapper");
        filelist = dir(fullfile(rootdir, '**\*.*')); 
        filelist = filelist(~[filelist.isdir]);
        filelist = {filelist.name};

        additionalFiles = [additionalFiles, filelist];
    end

    if isempty(additionalFiles)
        additionalFiles = {''};
    end
    
    % Build and CTF
    buildCalc(componentName, {componentName},...
        additionalFiles');
end

