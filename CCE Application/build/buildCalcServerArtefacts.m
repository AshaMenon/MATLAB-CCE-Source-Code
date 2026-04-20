function buildCalcServerArtefacts(logFID, deployFolder)
%buildCalcServerArtefacts  Build CCE Calculation Server Artefacts
%   buildCalcServerArtefacts(logFID, deployFolder) builds the Calcualtion Server artefacts and deploys them to the
%   deployment folder given by deployFolder.

% Copyright 2021 Opti-Num Solutions (Pty) Ltd
% developed as background IP for Anglo American Platinum

arguments
    logFID (1,1) double = 1;
    deployFolder (1,1) string = fullfile(fileparts(fileparts(mfilename("fullpath"))), "deploy");
end

%% Build CCELogger DLL
myDir = fileparts(mfilename("fullpath"));
[status,msDevEnvCmd]=system("""C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe"" -property productPath");
if (status~=0)
    error("ons:buildCalcServerSrtefacts:VSNotFound", "Could not find Visual Studio installed on machine. Message is: %s", msDevEnvCmd);
end
msDevEnvCmd = """" + strtrim(msDevEnvCmd) + """";
slnFilePath = fullfile(myDir, "SharedLogger.NET", "source", "SharedLogger.NET.sln");
loggerProjPath = fullfile(myDir, "SharedLogger.NET", "source", "SharedLogger.NET", "SharedLogger.NET.csproj");
installerProjPath = fullfile(myDir, "SharedLogger.NET", "source", "SetupCCELogger", "SetupCCELogger.vdproj");

fprintf(logFID, "Building CCELogger shared library...");
sysCmd = sprintf("%s %s /project %s /build Release", msDevEnvCmd, slnFilePath, loggerProjPath);
[res,msg] = system(sysCmd);
if (res == 0)
    fprintf(logFID, "done.\n");
else
    fprintf(logFID, "failed:\n%s", msg);
end

fprintf(logFID, "Building CCELogger Installer ...");
sysCmd = sprintf("%s %s /project %s /build Release", msDevEnvCmd, slnFilePath, installerProjPath);
[res,msg] = system(sysCmd);
if (res == 0)
    fprintf(logFID, "done.\n");
else
    fprintf(logFID, "failed:\n%s", msg);
end

% Clean up the folders created by these build processes
fprintf(logFID, "Cleaning up CCELogger build process folders...");
fprintf(logFID, "obj...");
objDir = fullfile(myDir, "SharedLogger.NET", "source", "SharedLogger.Net", "obj");
if exist(objDir, "dir")
    rmdir(objDir, "s");
end
fprintf(logFID, "build...");
bldDir = fullfile(myDir, "SharedLogger.NET", "source", "SharedLogger.Net", "build");
if exist(bldDir, "dir")
    rmdir(bldDir, "s");
end
fprintf("done.\n");

%% Copy files to deployment folder
destDir = fullfile(deployFolder, "bin");
fprintf(logFID, "\n");
fprintf(logFID, "Copying Installer to deployment folder %s...", destDir);
copyfile(fullfile(myDir, "SharedLogger.NET", "SetupCCELogger.msi"), destDir);
fprintf("done.\n\n")

%% Copy AF Calcualtion Template XML to deploy folder
afTemplateSrcDir = fullfile(fileparts(myDir), "calculationSupport", "AFtemplates");
afTemplateDestDir = fullfile(deployFolder, "calculations", "AFTemplates");
fprintf(logFID, "\n");
fprintf(logFID, "Copying AF Calculation Template files to deployment folder %s...", afTemplateDestDir);
copyfile(afTemplateSrcDir, afTemplateDestDir);
fprintf("done.\n\n")

%% Copy MATLAB Production Server config file
mlProdServerConfigDir = fullfile(deployFolder, "calculations");
fprintf(logFID, "Copying MATLAB Production Server config template to deployment folder %s...", mlProdServerConfigDir);
mlpsConfigFile = fullfile(fileparts(myDir), "configFiles", "prod", "config", "MLProdServer_config");
copyfile(mlpsConfigFile, mlProdServerConfigDir);
fprintf("done.\n\n")
