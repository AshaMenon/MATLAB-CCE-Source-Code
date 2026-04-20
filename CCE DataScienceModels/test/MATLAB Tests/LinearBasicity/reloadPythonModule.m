function reloadPythonModule()
    % RELOADPYTHONMODULE Reloads a Python Module so that any changes are
    % reflected
    
    %Setup
%     pe = pyenv;
%     if pe.Status ~= 'Loaded'
%         pyversion 'C:\Users\AntonioPeters\Anaconda3\envs\slag-splash-env\pythonw.exe'
%     end
    
    % Clear classes may have to keep some in memory and will complain, so wrap
    warnState = warning("off");
    save(fullfile(tempdir,"warnstate.mat"), "warnState")
    clear classes
    load(fullfile(tempdir,"warnstate.mat"))
    warning(warnState);
    mod = py.importlib.import_module('CCEScripts.TrainLinearBasicity', 'TrainLinearBasicity');
    py.importlib.reload(mod);
end
