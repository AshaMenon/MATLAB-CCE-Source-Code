function buildConfigFiles(logFID, outFolder)
%buildConfigFiles  Build CCE Configuration files and folders
%   buildConfigFiles(logFID, outFolder) copies the configuration files for deployment from the repository to the
%   deployment folder, in the correct location. Currently the following files and folders are copied:
%   * Folder structure: config, config/AFTemplates, log, and db folders.
%   * Master configuration file: This file is a formatted, documented version of cce.conf. It is named cce.conf.orig
%   * PI AF Template imports: Import XML files are copied to the config folder.

% Copyright 2021 Opti-Num Solutions (Pty) Ltd
% developed as background IP for Anglo American Platinum

arguments
    logFID (1,1) double = 1;
    outFolder (1,1) string = fullfile(fileparts(mfilename("fullpath")),"..","deploy");
end

%% Define the stuff we're checking and/or creating
configFolder = fullfile(outFolder, "config");
logFolder = fullfile(outFolder, "logs");
dbFolder = fullfile(outFolder, "db");

srcConfigFile = fullfile(fileparts(mfilename("fullpath")), "cce.conf");
templatesFolder = fullfile(fileparts(fileparts(mfilename("fullpath"))), "AFInfrastructure");
templatesToCopy = ["CCECalculation.xml", "CCECoordinator.xml", "CCEAttributeCategories.xml",...
    "CalculationTemplates.xml", "CCESensorTypeThreshold.xml", "FailedConnectionCodes.xml"];
digitalStatesToCopy = "DigitalSet_*.csv";

%% Make the config and log folders
fprintf(logFID, "Checking folder structure...");
if ~exist(configFolder, "dir")
    fprintf(logFID, " making config folder...");
    mkdir(configFolder);
    fprintf(logFID, " and AFTemplates folder...");
    mkdir(fullfile(configFolder, "AFTemplates"));
end
if ~exist(logFolder, "dir")
    fprintf(logFID, " making logs folder...");
    mkdir(logFolder);
end
if ~exist(dbFolder, "dir")
    fprintf(logFID, " making db folder...");
    mkdir(logFolder);
end
fprintf(logFID, "done.\n");

%% Copy the configuration file to the right place
fprintf(logFID, "Copying default config to deployment folder...");
copyfile(srcConfigFile, fullfile(configFolder,"cce.conf.orig"));
fprintf(logFID, "done.\n");

%% Copy the CCECalculation and CCECoordinator PI AF Import files
fprintf(logFID, "Copying PI AF templates to config folder...");
afConfigFolder = fullfile(configFolder, "AFTemplates");
for k=1:numel(templatesToCopy)
    fprintf(logFID, " %s...", templatesToCopy(k));
    copyfile(fullfile(templatesFolder, templatesToCopy(k)), afConfigFolder);
end
fprintf(logFID, "done\n");
fprintf(logFID, "Copying DigitalSet configuration files...");
allDigitalStatesFiles = dir(fullfile(templatesFolder, digitalStatesToCopy));
for k=1:numel(allDigitalStatesFiles)
    fprintf(logFID, " %s...", allDigitalStatesFiles(k).name);
    copyfile(fullfile(allDigitalStatesFiles(k).folder, allDigitalStatesFiles(k).name), afConfigFolder);
end
fprintf(logFID, " done.\n");