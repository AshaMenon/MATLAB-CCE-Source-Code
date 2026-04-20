function cceSetup
    %% CCE Setup
    % Startup file for AngloPlat CCE Project
    %
    %   Do not put any code in here except path additions.
    
    % Copyright 2021 Opti-Num Solutions (Pty) Ltd.
    % Version: $Format:%ci$ ($Format:%h$)
    
    rootPath = fullfile(fileparts(mfilename("fullpath")),"cce");
    addpath(fullfile(rootPath));
    addpath(genpath(fullfile(rootPath, "util")));
    addpath(genpath(fullfile(rootPath, "dataConnector")));
    addpath(genpath(fullfile(rootPath, "coordinator")));
    addpath(genpath(fullfile(rootPath, "configurator")));
    addpath(genpath(fullfile(rootPath, "calcServer")));
    addpath(genpath(fullfile(rootPath, "windowsScheduler")));
    addpath(genpath(fullfile(fileparts(rootPath), "calculationSupport", "common")));
    addpath(fullfile(fileparts(rootPath), "build"));
    addpath(fullfile(fileparts(rootPath), "afCommunication"));

end