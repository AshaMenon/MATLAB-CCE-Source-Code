function reloadPythonModuleTemplate()
    % RELOADPYTHONMODULE Reloads a Python Module so that any changes are
    % reflected
    
    %Setup
    pe = pyenv;
    if pe.Status ~= 'Loaded'
        pyenv('Version','3.8');
    end
    
    clear classes
    mod = py.importlib.import_module('BPFstatsFcnCCE');
    py.importlib.reload(mod);
end
