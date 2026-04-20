function setupPythonEnvAndPath(convertedCalcsRootFolder)
    % Add common folder to the Python path
    commonPath = fullfile(convertedCalcsRootFolder, 'common');
    pe = pyenv;
    if pe.Status ~= 'Loaded'
        pyenv('Version','3.8');
    end
    
    if count(py.sys.path, commonPath) == 0
        insert(py.sys.path,int32(0), commonPath);
    end
end

