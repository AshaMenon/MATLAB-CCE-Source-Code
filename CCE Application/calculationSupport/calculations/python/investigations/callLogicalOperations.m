function result = callLogicalOperations(x,y,operation)
    %CALLLOGICALOPERATIONS Calls Python function to test logical i/o
    %   x, y = double
    %   operation = logical
    
    pe = pyenv;
    if pe.Status ~= 'Loaded'
        pyenv('Version','3.8');
    end
    
    if length(x) > 1 && length(y) > 1
        result = py.testModule.logicalOperationsArray(x,y,operation);
        result = cell2mat(cell(result));
    else
        result = py.testModule.logicalOperations(x,y,operation);
    end
end

