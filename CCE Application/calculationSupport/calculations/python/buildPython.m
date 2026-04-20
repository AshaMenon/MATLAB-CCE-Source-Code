function buildPython(moduleName,functionName,componentName)
    %BUILDPYTHON Automatically builds Python calculations
    %   Inputs:
    %       functionName: Name of the function in a cell array, eg: {'oscillationDetection'}
    %       componentName: Name of the component. eg: 'oscillationDetection'
    %       moduleName: Name of the Python file to be deployed eg.
    %       'BPFstatsFCnCCE.py'
    
    % Create MATLAB wrapper for Python calc
    createPythonCalcWrapper(moduleName, functionName);
    
    % Temporarily move common python files to calc folder
    pythonFolder = fileparts(mfilename("fullpath"));
    calcFolder = fileparts(which(moduleName));    
    commonFiles = fullfile(pythonFolder, 'common', '*.py');
    copyfile(commonFiles, calcFolder);

    % Build CTF
    % Python additional files are not automatically added
    commonFileList = {'calculation_error_state.py', 'cce_logger.py', 'logger.py',...
        'log_message_level.py'};
    additionalFiles = fullfile(calcFolder, commonFileList);
    buildCalc(componentName, {functionName},...
        [moduleName, additionalFiles]);
    
    % Delete common python functions from calc folder
    for iFile = 1:numel(commonFileList)
        delete(fullfile(calcFolder, commonFileList{iFile}));
    end
end

