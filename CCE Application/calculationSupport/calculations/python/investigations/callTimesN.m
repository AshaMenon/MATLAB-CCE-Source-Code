function result = callTimesN(x,multiplier)
    %CALLTIMESN Function to call the Python timesN function
    pe = pyenv;
    if pe.Status ~= 'Loaded'
        pyenv('Version','3.8');
    end
    
    resultPy = py.testModule.timesN(x,multiplier);
    result = double(resultPy);
end

