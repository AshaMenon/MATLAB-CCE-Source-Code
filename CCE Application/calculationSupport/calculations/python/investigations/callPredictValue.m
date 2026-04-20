function result = callPredictValue(x,fileName)
    pe = pyenv;
    if pe.Status ~= 'Loaded'
        pyenv('Version','3.8');
    end
    
    % Get absolute path of the deployment folder
    filePath = which('testModule.py');
    filePath = erase(filePath,'\testModule.py');
    
    idcs   = strfind(filePath,'\');
    newDir = [filePath(1:idcs(end-6)), 'Data'];
    fileLocation = [newDir '\' fileName];
    
    xList = py.list(x);
    y = py.testModule.predictValue(fileLocation,xList);
    result = double(y);
end