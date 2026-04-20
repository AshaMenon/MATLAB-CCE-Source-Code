function buildCalcs(logFID)
    %BUILDCALCS Calls the build functions for all the CCE calculation
    %types, namely MATLAB(includes derived, dependent, Ace, controllerAnalysis),
    %Python and Lethe
    arguments
        logFID (1,1) double = 1;
    end
    
    buildMatlabCalcs(logFID);
    buildPythonCalcs(logFID);
    buildLetheCalcs(logFID);
end