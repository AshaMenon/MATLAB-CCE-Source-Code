function buildPythonCalcs(logFID)
    %BUILDANDDEPLOYPYTHONCALCS Builds all Python Calcs
    %   This function does not automatically pull the calculation configuration
    %   from PI AF
    %TODO: Pull calc configurations from PI AF and use that to automatically
    
    arguments
        logFID (1,1) double = 1;
    end
    
    %% Setup
    oldPath = path;
    buildFolder = fileparts(mfilename("fullpath"));
    addpath(fullfile(fileparts(buildFolder),'calculationSupport'));
    setupCalcDev;
    addpath(fullfile(fileparts(buildFolder),'calculationSupport', 'calculations', 'python'));
    setupPythonCalcs('build');
    cuPathRestore = onCleanup(@()path(oldPath));
    
    %% Build
    % bfpStats
    fprintf(logFID, "Building bpfStats.\n");
    buildPython('BPFstatsFcnCCE.py', 'bpf_stats', 'bpf_stats')

end

