function result = callTimesTwo()
    %CALLTIMESTWO Function to call the Python timesTwo function
    pe = pyenv;
    if pe.Status ~= 'Loaded'
        pyenv('Version','3.8');
    end
    
    % Get absolute path of the deployment folder
    filePath = which('testModule.py');
    filePath = erase(filePath,'\testModule.py');
    
    % Add this path to the Python Search Path
    if count(py.sys.path,filePath) == 0
        insert(py.sys.path,int32(0),filePath);
    end
    
    resultPy = py.testModule.timesTwo();
    result = double(resultPy);
end

