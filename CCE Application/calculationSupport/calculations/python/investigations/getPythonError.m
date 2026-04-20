function str = getPythonError()
    %CATCHPYHONERROR simulate error of user defined Python function
    
    pe = pyenv;
    if pe.Status ~= 'Loaded'
        pyenv('Version','3.8');
    end
    str = py.testModule.pythonError();
end
