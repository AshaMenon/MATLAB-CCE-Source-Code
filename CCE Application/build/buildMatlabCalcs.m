function buildMatlabCalcs(logFID)
    %BUILDMATLABCALCS Builds and deploys all MATLAB Calcs
    %   This function does not automatically pull the calculation configuration
    %   from PI AF
    %TODO: Pull calc configurations from PI AF and use that to automatically
    %build and deploy
    
    arguments
        logFID (1,1) double = 1;
    end
    %% Setup
    oldPath = path;
    buildFolder = fileparts(mfilename("fullpath"));
    addpath(fullfile(fileparts(buildFolder),'calculationSupport'));
    setupCalcDev;
    addpath(fullfile(fileparts(buildFolder),'calculationSupport', 'calculations', 'aceCalculations'));
    setupAceCalcs;
    addpath(fullfile(fileparts(buildFolder),'calculationSupport', 'calculations', 'derivedCalculations'));
    setupDerivedCalcs;
    addpath(fullfile(fileparts(buildFolder),'calculationSupport', 'calculations', 'matlabAnalysis'));
    setupMatlabAnalysisCalcs;
    addpath(fullfile(fileparts(buildFolder),'calculationSupport', 'calculations', 'dependentCalculations'));
    addpath(fullfile(fileparts(buildFolder),'calculationSupport', 'calculations', 'testCalculations'));
    setupTestCalcs;
    cuPathRestore = onCleanup(@()path(oldPath));
    
    %% Build
    % controllerAnalysis
    fprintf(logFID, "Building Controller Analysis.\n");
    buildCalc('controllerAnalysis', {'controllerAnalysis'})
    
    % Derived calculations
    fprintf(logFID, "Building Derived Calcs.\n");
    buildCalc('derivedCalcs', {'reconstructDensity', 'apcQuantExpression'})
    
    % Dependent calculations
    fprintf(logFID, "Building Dependent Calcs.\n");
    buildCalc('dependentCalcs', {'sensorAdd', 'dependentAdd'})
    
    % Ace calculations
    fprintf(logFID, "Building Ace Calcs.\n");
    buildCalc('calculatedLevel', {'calculatedLevel'})
    buildCalc('electrodeCalculations', {'electrodeCalculations'})

    % Test Calculations
    fprintf(logFID, "Building Test Calcs.\n");
    buildCalc('testCalcs', {'nanCalc', 'emptyOutputCalc'});
        
    %% Clean Up
    % This is handled by the cuPathRestore variable.
    
end

