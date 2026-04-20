function buildLetheConversionCalcs(logFID)
    %buildLetheConversionCalcs Builds all Lethe Calcs for Conversion project
    % buildLetheConversionCalcs builds all Lethe converted calculations as part of AngloPlat project
    % 2022CNST15.
    
    arguments
        logFID (1,1) double = 1;
    end
    %% Setup
    % When building compiled CTF files, you should remove all preferences and startup files.
    cuEnv = prepEnvironmentForCompiler; %#ok<NASGU>
    
    % We need the paths to the build infrastructure
    oldPath = path;
    buildFileFolder = fileparts(mfilename("fullpath"));
    cceFolder = fullfile(fileparts(fileparts(mfilename("fullpath"))), 'cce');
    addpath(fullfile(cceFolder, 'calculationSupport'));
    setupCalcDev;

    addpath(fullfile(buildFileFolder, 'lethe'));
    setupLetheCalcs;
    % Override the output folder for the converted calculations
    setpref("CCECalcDev","OutputFolder", fullfile(buildFileFolder, 'deploy'));
    cuPathRestore = onCleanup(@()path(oldPath));
    
    %% Build

    buildLethe('cceLetheAverage');
    buildLethe('cceLetheSum');
    buildLethe('cceLetheTails');
    buildLethe('cceLetheComponentArray');
    buildLethe('cceLetheAccountability');
    buildLethe('cceLetheAssay');
    buildLethe('cceLetheRecovery');
    buildLethe('cceLetheBUH');
    buildLethe('cceLetheEstimate');
    buildLethe('cceLetheSubstitute');
    buildLethe('cceLetheComponent');
    buildLethe('cceLetheMassPull');
    buildLethe('cceLethePeriodSum');
    buildLethe('cceLetheDryMass');
    buildLethe('cceLetheMapReduce');
    buildLethe('cceLethePeriodAverage');
    buildLethe('cceLethePebblesAndSpillagesMer');
    buildLethe('cceLethePebblesAndSpillagesUG');
    buildLethe('cceLethePeriodWeighting');

end

