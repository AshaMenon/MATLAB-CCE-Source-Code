function callTrainModel(x,y,fileName)
    pe = pyenv;
    if pe.Status ~= 'Loaded'
        pyenv('Version','3.8');
    end
    
    % Get absolute path of the deployment folder
    filePath = which('testModule.py');
    filePath = erase(filePath,'\testModule.py');
    
    idcs   = strfind(filePath,'\');
    newDir = [filePath(1:idcs(end-6)), 'Data'];
    
    % Add location to Python search path
    if count(py.sys.path,newDir) == 0
        insert(py.sys.path,int32(0),newDir);
    end
    
    fileLocation = [newDir '\' fileName];
    py.testModule.trainModel(x,y,fileLocation);
    
end