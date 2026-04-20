function reloadPythonModuleTemplate()
    % RELOADPYTHONMODULE Reloads a Python Module so that any changes are
    % reflected
    
    %Setup
    pe = pyenv;
    if pe.Status ~= 'Loaded'
        pyenv('Version','3.8');
    end
    
    % Clear classes may have to keep some in memory and will complain, so wrap
    warnState = warning("off");
    clear classes
    warning(warnState);
    mod = py.importlib.import_module('ModuleName');
    py.importlib.reload(mod);
end