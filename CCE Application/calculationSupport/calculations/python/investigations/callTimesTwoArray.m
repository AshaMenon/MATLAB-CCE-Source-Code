function result = callTimesTwoArray(doubleArray)
    %CALLTIMESTWOARRAY Function to call the Python timesTwoArray function
    pe = pyenv;
    if pe.Status ~= 'Loaded'
        pyenv('Version','3.8');
    end
    
    % Get absolute path of the deployment folder
    filePath = which('testModule.py');
    
    % Add this path to the Python Search Path
    if count(py.sys.path,filePath) == 0
        insert(py.sys.path,int32(0),filePath);
    end
    
    resultPy = py.testModule.timesTwoArray(doubleArray);
    result = cell2mat(cell(resultPy));
end