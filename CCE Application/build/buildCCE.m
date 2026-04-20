function success = buildCCE(buildOption, logFID)
%buildCCE  Build process for CCE artefacts
%   buildCCE builds all artefacts for the CCE infrastructure, including calculations (at this point). This function does
%   not include any actual build processes, but instead sets up the environment and then leverages the build functions
%   for each of the components.
%
%   buildCCE(BuildOption) controls the build process to build only the "server" artefacts, the "calc" artefacts, or
%   "all".
%
%   buildCCE(BuildOption, LogFID) controls the output display. Set LogFID to 1 for stdout, or a file for recorded
%   builds.
%
%   See also: buildConfigurator, buildCoordinator, buildServerArtefacts, buildAndDeployMatlabCalcs

% Copyright 2021 Opti-Num Solutions (Pty) Ltd
% developed as background IP for Anglo American Platinum

arguments
    buildOption (1,1) string {mustBeMember(buildOption, ["all","server","calc"])} = "all"
    logFID (1,1) double = 1;
end

%% Setup environment
% The environment needs to have no preferences or startup files. Rename them prior to the build and rename back again.
if isempty(getenv('CCE_Root'))
    % CCE_Root environment variable has no tbeen specified. Attempt to recover
    error("CCE:buildCCE:EnvNotSet", "CCE Environment variable CCE_Root not configured. Build will error.")
end
deployFolder = fullfile(fileparts(fileparts(mfilename("fullpath"))),"deploy");
cleanUps = prepEnvironmentForCompiler(); %#ok<NASGU> 

%% Clean up the deployment folder
% If this is a complete build, we destroy everything in the deployment folder
if matches(buildOption, "all")
    fprintf(logFID, "Removing everything in the deploy folder...");
    rmdir(deployFolder, "s");
    mkdir(deployFolder);
    fprintf(logFID, "done.\n");
end
%% Version file
% Generate a version based on the tag + commit (for now)
fprintf(logFID, "Writing version information...");
verStr = "1.2.34"; % Numeric only, so have to hard-code here.
versionInfo = "PI-" + verStr;
fprintf(logFID, "%s (exe version %s)", versionInfo, verStr);
fid = fopen(fullfile(deployFolder,"Version.txt"), "wt");
fprintf(fid, "%s (executable version %s)", versionInfo, verStr);
fclose(fid);
fprintf(logFID, "\n");

if matches(buildOption, ["all", "server"])
    %% CCEServer artefacts
    % The server artefacts include the Configurator and Coordinator executables.
    fprintf(logFID, "CCE Server Artefacts\n");
    fprintf(logFID, "--------------------\n");
    
    %% Configurator
    fprintf(logFID, "Building Configurator...\n");
    buildConfigurator(verStr, logFID);
    fprintf(logFID, "\n");
    
    %% Coordinator
    fprintf(logFID, "Building Coordinator...\n");
    buildCoordinator(verStr, logFID);
    fprintf(logFID, "\n");
    %% Server Artefacts
    fprintf(logFID, "Building Other Server Artefacts...\n");
    buildServerArtefacts(verStr, logFID);
    fprintf(logFID, "\n");
end

%% Configuration files
% We will be putting a default configuration for production into the repo. This step simply copies
% that to the config folder in deploy, so that we can archive Deploy and submit it to AP as part of
% the process.
fprintf(logFID, "Building Config Files...");
buildConfigFiles(logFID);
fprintf(logFID, "done\n");

if matches(buildOption, ["all", "calc"])
    %% Calculation Server artefacts
    fprintf(logFID, "CCE Calculation Server Artefacts\n");
    fprintf(logFID, "--------------------------------\n");
    buildCalcServerArtefacts(logFID);
    fprintf(logFID, "\n");
    
    %% Calculation artefacts
    % Build all CTFs and deploy them to the CCE server
    fprintf(logFID, "CCE Calculation Artefacts\n");
    fprintf(logFID, "-------------------------\n");
    buildMatlabCalcs(logFID);
    buildPythonCalcs(logFID);
    buildLetheCalcs(logFID);
    fprintf(logFID, "\n");
end

%% Zip up the files to a version-labelled file
% We put this file into the root of the CCE project, so that we can nuke the deploy folder between
% runs.
archiveName = "CCE-"+versionInfo+".zip";
fprintf(logFID, "Creating archive %s...", archiveName);
fileNames = dir(deployFolder);
% Remove the ZIP files that were made before.
fileNames(cellfun(@(x)~isempty(regexp(x,'CCE\-.*\.zip','once')),{fileNames.name}))=[];
zip(fullfile(fileparts(deployFolder), archiveName), {fileNames(3:end).name}, deployFolder);
fprintf(logFID, "All Done.\n");

success = true;
end

% Change Log
%1.2.34: Update to include configurator monitoring using a configurator
%element in PI.
%1.2.33: Update to handle invalid coordinator and calculation attributes
%when being read in
%1.2.32: Update coordinator health check to also include disabled and for
%deletion coordinators
%1.2.31: Fixed issue where network issues showed up as configuration errors
%and also updated error logging when reading coordinator and calculation
%attributes
%1.2.30: Added coordinator health check that checks and deletes misconfigured coordinators when the
%configurator runs.
%1.2.29: Fixed bug were manually deleted coordinators crashed the configurator. Added functionality
%to have ignorable exceptions that won't disable a calculation when encountered.
%1.2.28: Load balancer quick fix to use AF table for coordinator loads based on frequency.
%1.2.27: Fixed issue where formula data reference inputs caused AFData retrieval errors when one of 
% the formula inputs had missing data.
%1.2.26: Added functionality to skip auto backfill for calculations that are lagging and whose
%SkipBackfill attribute is set to true.
%1.2.25: Fixed issues encountered when writeDependenciesReadyFailedTime and
%writeNetworkErrorFailedTime errored meaning that the sqlite connection is closed three times (once
%in each catch block and again after the try-catch) this would result in a "Invalid or deleted
%object" exception.
%1.2.24: Fixed bug in coordinator where the successIdx was not being updated causing the wrong
%calculations to set to a configuration error when some calcs had a network error. Also removed
%inputs and parameters that weren't pulled in.
%1.2.23: Fixed bug in calcServer, where calculation states from production
%server are not pulled, causing calculations not to run
%1.2.22: Optimised coordinator overhead runtime by only refreshing necessary calculation attributes
%once, calculation and coordinator db records were also updated to use local values and not always
%query the AF DB. getNextOutputtime optimised for speed
%1.2.21: Increased logging and added try-catches to cceStop and cceRestart.
%1.2.20: Fixed short dependency allocation bug where if multiple
%coordinators have the same calctree errors would occur (this assumed a
%single coordinator per short dep calc-tree)
%1.2.19: Network failed functionality improvements - now uses AF table,
%fixed bug with time pull.
%1.2.18: Network failed functionality - calcs no longer set to systemDisabled if the
%network has failed. 
%1.2.17.1: Fixed bug with runEventBasedCoordinator
%1.2.17: Fullfile logging fixed, coordinator execution optimised
%1.2.16.2: -runConfigurator option now waits for configurator to finish
%running before continuing restart process
%1.2.16.1: Added informative logging in CCERestart for -runConfigurator option 
%1.2.16: Changed dependencies to make use of LastCalculation time, instead
%of using individual inputs time. 
%1.2.15.1: Fixed bug in readDependentInputs - uses .datenum now
%1.2.15: Improved dependent inputs handling - now the dependentInputs.csv file isn't read unless its changed.
% Dependent inputs are only written to CSV file by coordinator.
% If no inputs are correctly pulled, runCalculations is exited, with a warning produced.
%1.2.14: Fixed dependentMap csv read (enforced comma delim),
% informative error message for when output size is inconsistent. 
% Fixed bug with error logging in removeRecordedHistory - converted to string with .Net method
% 1.2.13: Fixed bug in parseAFValue in data connector where [] was passed
% out if type was not recognised. 
% 1.2.12: Fixed bug in getCheckFailedTime where Matlab version changed
% function output from cell to table
% 1.2.11: Fixed bug in coordinator where error would occur with missing
% dependent inputs. 
% 1.2.10: Calculations with any outputs empty are set to system disabled,
% and calculation error state set to NoResult
% 1.2.9: "Write NaN values as" user specified attribute enumeration feature implemented
% 1.2.8.1: Coordinator no longer exits after wait period if calculation is
% SystemDisabled/Disabled
% 1.2.8: Coordinator now exits after wait period if calculation is SystemDisabled.
% pauseWhileCheckingForDisabled now also checks for non-NaT next output times. 
% Coordinator Logname now specifically uses the log folder unless
% path specified.
% Rolling logger functionality now added - logfile size and backup limits
% in config. 
% 1.2.7: Logname, loglevel, reenable systemdisabledcalcs, maxcalculation
% load now controllable from within coordinator attributes in PIAF system
% explorer
% 1.2.6: Made input pulling and ouput writing more robust - coordinator no
% longer fails if data retrieval is unsuccessful
% 1.2.5.1: Fixed bug with 12 hour clock datetime
% 1.2.5: System disabled state added, updated for Matlab 2023a. Datetime
% bug present - *dont use this version*
% testable without coordinator. 
% 1.2.4: Configurator robust improvements - REMOVED due to issues with
% specific integration
% 1.2.3: Calc server can handle empty calc outputs, isfatal, isquestionable
% BOD(*) support
% 1.2.2: Improve backfilling behaviour, avoid calcualtions in future times
% 1.2.1: Add OutputTime parameter as a UTC string of output time being calculated
% 1.2.0: Values are now written in Replace mode rather than InsertNoCompression mode
% 1.1.1: Support CCEOutput attributes that are not PI Points.
% 1.1.0: Support Compressed data retrieval on inputs.
% 1.0.7: First delivered version for AngloPlat.