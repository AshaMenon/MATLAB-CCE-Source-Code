function result = callTestStructs(myStruct)
    %CALLTESTSTRUCTS Tests the use of nested structs in Python
    %   myStruct should have an element - S.S1.Mary  = 100;
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
    
    resultPy = py.testModule.testStructs(myStruct);
    result = struct(resultPy);
    fn = fieldnames(result);
    for k=1:numel(fn)
      result.(fn{k}) = struct(result.(fn{k}));
    end
    
end

