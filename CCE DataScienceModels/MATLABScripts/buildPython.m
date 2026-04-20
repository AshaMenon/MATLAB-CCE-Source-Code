function buildPython(moduleName,functionName,componentName)
    %BUILDPYTHON Automatically builds Python calculations
    %   Inputs:
    %       functionName: Name of the function in a cell array, eg: {'oscillationDetection'}
    %       componentName: Name of the component. eg: 'oscillationDetection'
    %       moduleName: Name of the Python file to be deployed eg.
    %       'BPFstatsFCnCCE.py'
    
    % Create MATLAB wrapper for Python calc
    %createPythonCalcWrapper(moduleName, functionName);
    
    % Temporarily move common python files to calc folder
    pythonFolder = fileparts(mfilename("fullpath"));
    calcFolder = fileparts(which(moduleName));   
    commonFiles = fullfile(pythonFolder, 'common', '*.py');
%     copyfile(commonFiles, fullfile(calcFolder,'CCEScripts','common'));
    

    % Build CTF
    % Python additional files are not automatically added
    commonFileList = {'calculation_error_state.py', 'cce_logger.py', 'logger.py',...
        'log_message_level.py'};
    for file = 1:numel(commonFileList)
        commonFilePath{file} = which(commonFileList{file});
    end

    % Get the same folder structure - Find a better way to do this
    filePath = fileparts(pwd);
    %copyfile(fullfile(filePath,'helpers'), fullfile(calcFolder));
    copyfile(fullfile(filePath,'modelClasses'), fullfile(calcFolder,'modelClasses'));
    copyfile(fullfile(filePath,'Shared'), fullfile(calcFolder,'Shared'));
    copyfile(fullfile(filePath,'src'), fullfile(calcFolder,'src'));
    pythonFiles = {'featureEngineeringHelpers.py','Data.py', 'Config.py', 'Model.py'};

    pythonFiles = [pythonFiles, {'XGEBoostBasicityModel.py', 'EvaluateXGEBoostBasicity.py'}]; % Basicity files
%     pythonFiles = [pythonFiles, {'RunPySPO2Dynamic.py', 'EvaluateSPO2.py', 'SPO2Model.py'}]; % SPO2 files

    for file = 1:numel(pythonFiles)
        pythonFilePath{file} = which(pythonFiles{file});
    end
    addpath(genpath(calcFolder));
    additionalFiles = [commonFilePath, pythonFilePath];
    buildCalc(componentName, functionName,...
        [moduleName, additionalFiles]);
    
%     remdir(fullfile(calcFolder,'modelClasses'));
%     delete(fullfile(calcFolder,'Shared'));
%     delete(fullfile(calcFolder,'src'));
   
end

