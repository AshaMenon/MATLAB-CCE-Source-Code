function result = callCheckString(x)

    pe = pyenv;
    if pe.Status ~= 'Loaded'
        pyenv('Version','3.8');
    end
    
    if isa(x, 'string') ||isa(x, 'cell') && length(x) > 1
        
        result = py.testModule.checkStringArray(x);
        result = cell(result);
        
        for i = 1:length(result)
            if isa(result{i}, 'py.str')
                newResult(i) = string(result{i});
            else
                newResult(i) = result{i};
            end
        end
        result = newResult;
    else
        result = py.testModule.checkString(x);
        if isa(result, 'py.str')
            result = string(result);
        end
        
    end
end