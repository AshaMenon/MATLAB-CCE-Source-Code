function reloadPythonModule()
    
    pe = pyenv;
    if pe.Status ~= 'Loaded'
        pyenv('Version','3.8');
    end
    
    clear classes
    mod = py.importlib.import_module('testModule');
    py.importlib.reload(mod);
end

