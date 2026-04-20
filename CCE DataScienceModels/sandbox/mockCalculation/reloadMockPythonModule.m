function reloadMockPythonModule()
    % RELOADPYTHONMODULE Reloads a Python Module so that any changes are
    % reflected
    
    % Clear classes may have to keep some in memory and will complain, so wrap
    warnState = warning("off");
    save(fullfile(tempdir,"warnstate.mat"), "warnState")
    clear classes
    load(fullfile(tempdir,"warnstate.mat"))
    warning(warnState);
    mod = eval("py.importlib.import_module('EvalMockModel', 'EvalMockModel')");
    py.importlib.reload(mod);
end
