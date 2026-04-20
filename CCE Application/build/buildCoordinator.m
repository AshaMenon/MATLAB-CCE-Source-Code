function buildCoordinator(verStr, logFID, outFolder)
%buildCoordinator  Build CCE Coordinator executable
%   buildCoordinator(logFID, outFolder) builds the coordinator and places the resulting
%   cceCoordinator executable in the folder outFolder.

% Copyright 2021 Opti-Num Solutions (Pty) Ltd
% developed as background IP for Anglo American Platinum

arguments
    verStr (1,1) string = "1.0.0"
    logFID (1,1) double = 1
    outFolder (1,1) string = fullfile(fileparts(fileparts(mfilename("fullpath"))),"deploy","bin")
end
% Note that the coordinator is placed in the bin folder, as it's not a human-executable application.

%% Define files to build and include
fileToBuild = "cceCoordinator.m";
fileToCopy = "cceCoordinator.exe";
% Add paths to required DLLs
additionalFiles = [which("DataPipeObserver.dll", "-all"), ...
    which("OSIsoft.AFSDK.dll", "-all")];

%% Build
% Because the compilation process adds a bunch of text files, deploy to a temporary location and
% copy the executable to the deployment folder
fprintf(logFID, "\tBuilding %s to temporary folder...", fileToBuild);
mccFolder = tempname;
mkdir(mccFolder);
cuFolder = onCleanup(@()rmdir(mccFolder, "s"));

compiler.build.standaloneApplication(which(fileToBuild), ...
    "OutputDir", mccFolder, ...
    "AdditionalFiles", additionalFiles, ...
    "ExecutableIcon", fullfile(fileparts(mfilename("fullpath")), "splashIcons", "CCE-Icon.png"), ...
    "ExecutableVersion", verStr);

%% Copy the resulting executable to the deployment folder.
fprintf(logFID, "moving %s to deployment folder %s...", fileToCopy, outFolder);
if ~exist(outFolder, "dir")
    mkdir(outFolder);
end
copyfile(fullfile(mccFolder, fileToCopy), outFolder);
fprintf(logFID, "done.\n");