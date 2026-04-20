function buildCalc(componentName, functionNames, additionalFiles)
    %BUILDCALC Builds a calculation CTF
    %   buildCalc(componentName, functionNames, additionalFiles)
    %   Inputs:
    %       componentName: Name of the component. eg: 'oscillationDetection'
    %       functionName: Name of the function in a cell array, eg: {'oscillationDetection'}
    %       additionalFiles: list of extra files that must be included. These must exist as full paths or on the MATLAB path
    
    arguments
        componentName (1,1) string {mustBeNonzeroLengthText}
        functionNames (1,:) cell {mustBeText}
        additionalFiles string = ""
    end
    %Setup tempfolder
    tempFolder = tempname();
    mkdir(tempFolder);
    cleanup = onCleanup(@()rmdir(tempFolder,"s"));
    
    %Compile
    functionNames = cellfun(@(x)which(x), functionNames, 'UniformOutput', false);
    additionalFilesCell = cellfun(@(x) which(x), additionalFiles, 'UniformOutput', false);
    if numel(additionalFiles) < 2 && isempty(additionalFiles{:})
        compiler.build.productionServerArchive(functionNames,...
            'ArchiveName', componentName,...
            'OutputDir', tempFolder);
    else
        compiler.build.productionServerArchive(functionNames,...
            'ArchiveName', componentName,...
            'OutputDir', tempFolder,...
            'AdditionalFiles', additionalFilesCell);
    end
    
    %Move file to output folder
    outDir = getpref('CCECalcDev', 'OutputFolder');
    if ~exist(outDir, 'dir')
        mkdir(outDir)
    end
    copyfile(fullfile(tempFolder, componentName + ".ctf"), outDir);
end