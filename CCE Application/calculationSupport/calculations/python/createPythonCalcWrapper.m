function createPythonCalcWrapper(moduleName,functionName)
    %CREATEPYTHONWRAPPER Creates MATLAB function to wrap Python modules to
    %enable deployment to the MATLAB Production Server
    %   inputs:
    %       moduleName: Name of Python module
    %       functionName: Name of Python function being called
    
    % Get Python deployment folder
    rootFolder = fileparts(mfilename("fullpath"));
    pythonDeploymentFolder = fullfile(rootFolder, 'convertedCalculations', moduleName);
    if ~exist(pythonDeploymentFolder, 'dir')
        mkdir(pythonDeploymentFolder)
    end
    
    % Read wrapper template
    fid = fopen('pythonFunctionTemplate.m','r');
    tline = fgetl(fid);
    tlines = cell(0,1);
    while ischar(tline)
        tlines{end+1,1} = tline;
        tline = fgetl(fid);
    end
    fclose(fid);
    
    % Make updates to template
    newFunctionName = [functionName, '.m'];
    tlines = replaceString(tlines, 'function [outputs, errorCode] = pythonFunctionTemplate(parameters,inputs)',...
        ['function [outputs, errorCode] = ',functionName, '(parameters,inputs)']);
    
    tlines = replaceString(tlines, '    %PYTHONFUNCTIONTEMPLATE Function to call the Python *functionName function',...
        ['    %',upper(functionName),' Function to call the Python ',...
        functionName, 'function']);
    
    tlines = replaceString(tlines, '    filePath = which(''moduleName'');',...
        ['    filePath = which(','''',moduleName,'''',');']);
    
    tlines = replaceString(tlines, '    filePath = erase(filePath,''\moduleName'');',...
        ['    filePath = erase(filePath,', '''','\', moduleName, ''');']);
    
    moduleNameStripped = erase(moduleName,'.py');
    tlines = replaceString(tlines, '    mod = py.importlib.import_module(''moduleName'');',...
        ['    mod = py.importlib.import_module(''', moduleNameStripped,''');']);
    
     tlines = replaceString(tlines, '    outputPy = eval(''py.moduleName.functionName(parameters, inputs)'');',...
        ['    outputPy = eval(''py.', moduleNameStripped,'.', functionName,'(parameters, inputs)'');']);
    
    % Write to new function
    numOfLines = length(tlines);
    fid = fopen([pythonDeploymentFolder,'\',newFunctionName],'w');
    for i = 1:numOfLines
        fprintf(fid,'%s\n', tlines{i});
    end
    fclose(fid);
    
    % Update reloadPythonModule
    fid = fopen('reloadPythonModuleTemplate.m','r');
    tline = fgetl(fid);
    tlines = cell(0,1);
    while ischar(tline)
        tlines{end+1,1} = tline;
        tline = fgetl(fid);
    end
    fclose(fid);
    
    tlines = replaceString(tlines, '    mod = py.importlib.import_module(''ModuleName'');',...
        ['    mod = py.importlib.import_module(''',moduleNameStripped, ''');']);
    
    % Write to new function
    numOfLines = length(tlines);
    fid = fopen([pythonDeploymentFolder,'\','reloadPythonModule.m'],'w');
    for i = 1:numOfLines
        fprintf(fid,'%s\n', tlines{i});
    end
    fclose(fid); 
    
end

