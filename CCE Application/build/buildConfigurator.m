function buildConfigurator(verStr, logFID, outFolder)
%buildConfigurator  Build CCE Configurator executable
%   buildConfigurator(logFID, outFolder) builds the configurator and places the resulting
%   cceConfigurable executable in the folder outFolder.

% Copyright 2021 Opti-Num Solutions (Pty) Ltd
% developed as background IP for Anglo American Platinum

arguments
    verStr (1,1) string = "1.0.0";
    logFID (1,1) double = 1;
    outFolder (1,1) string = fullfile(fileparts(fileparts(mfilename("fullpath"))),"deploy","bin");
end
% Note that the configurator is placed in the bin folder, as it's not a human-executable application.

%% Define additional files to include
% What files need to be included that are not in the MATLAB dependency checker? This would be data
% files, etc.

%% Define files to build and include
fileToBuild = "cceConfigurator.m";
fileToCopy = "cceConfigurator.exe";
% Add the .Net libraries we are using.
additionalFiles = [which("Microsoft.Win32.TaskScheduler.dll", "-all"), ...
    which("SimpleAES.dll", "-all")];

%% Build
% Because the compilation process adds a bunch of text files, deploy to a temporary location and
% copy the executable to the deployment folder
fprintf(logFID, "\tBuilding %s to temporary folder...", fileToBuild);
mccFolder = tempname;
mkdir(mccFolder);
cuFolder = onCleanup(@()rmdir(mccFolder, "s"));

compiler.build.standaloneApplication(which("cceConfigurator.m"), ...
    "OutputDir", mccFolder, ...
    "AdditionalFiles", additionalFiles, ...
    "ExecutableIcon", fullfile(fileparts(mfilename("fullpath")), "splashIcons", "CCE-Icon.png"), ...
    "ExecutableVersion", verStr);

%% Copy the resulting executable to the deployment folder.
fprintf(logFID, "moving %s to deployment folder %s ...", fileToCopy, outFolder);
if ~exist(outFolder, "dir")
    mkdir(outFolder);
end
copyfile(fullfile(mccFolder, fileToCopy), outFolder);
fprintf(logFID, "done.\n");