function setupPythonCalcs(varargin)
    %SETUPPYTHONCALCS Sets up the dev environment for the python calcs.
    %VARARGIN is empty normally, but during compilation, the python path
    %doesnt need to be added, and the env doesnt need to be setup, varargin
    %is 'build'
    
    %Setup dev environment for python calcs
    convertedCalcsRootFolder = fileparts(mfilename("fullpath"));
    addpath(fullfile(convertedCalcsRootFolder));
    addpath(fullfile(convertedCalcsRootFolder, 'convertedCalculations'));
    addpath(fullfile(convertedCalcsRootFolder, 'common'));
    
    %Add specific calc folders here as desired:
    addpath(genpath(fullfile(convertedCalcsRootFolder, 'convertedCalculations', 'BPFstatsFcn')));
    
    if isempty(varargin)
        setupPythonEnvAndPath(convertedCalcsRootFolder)
    end
end