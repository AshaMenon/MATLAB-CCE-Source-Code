function result = callTestDatetime(timestamp)
    pe = pyenv;
    if pe.Status ~= 'Loaded'
        pyenv('Version','3.8');
    end
    
    x = datenum(timestamp);
    if length(x) > 1
        x = py.list(x);
        result = py.testModule.testDatetimeArray(x);
    else
        result = py.testModule.testDatetime(x);
    end
end
