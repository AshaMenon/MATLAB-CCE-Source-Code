function buildServerArtefacts(verStr, logFID, outFolder)
    %buildServerArtefacts  Build CCE Server Artefacts
    
    % Copyright 2021 Opti-Num Solutions (Pty) Ltd
    % developed as background IP for Anglo American Platinum
    
    arguments
        verStr (1,1) string = "1.0.0"
        logFID (1,1) double = 1;
        outFolder (1,1) string = fullfile(fileparts(fileparts(mfilename("fullpath"))),"deploy");
    end
    
    %% Build
    % Because the compilation process adds a bunch of text files, deploy to a temporary location and
    % copy the executable to the deployment folder
    mccFolder = tempname;
    mkdir(mccFolder);
    cuFolder = onCleanup(@()rmdir(mccFolder, "s"));
    
    % Call a build helper
    aesFile = which('SimpleAES.dll', '-all');
    schedulerFile = which("Microsoft.Win32.TaskScheduler.dll", "-all");
    buildExecutable("cceBootstrap", [aesFile, schedulerFile]);
    buildExecutable("cceStop", schedulerFile);
    buildExecutable("cceRestart", [aesFile, schedulerFile]);
    buildExecutable("cceStatus", schedulerFile);
    
    function buildExecutable(fName, additionalFiles)
        codeFile = fName + ".m";
        exeFile = fName + ".exe";
        fprintf(logFID, "\tBuilding %s to temporary folder...", codeFile);
        compiler.build.standaloneApplication(which(codeFile), ...
            "OutputDir", mccFolder, ...
            "AdditionalFiles", additionalFiles, ...
            "ExecutableIcon", fullfile(fileparts(mfilename("fullpath")), "splashIcons", "CCE-Icon.png"), ...
            "ExecutableVersion", verStr);
        
        %% Copy the resulting executable to the deployment folder.
        fprintf(logFID, "moving %s to deployment folder %s ...", exeFile, outFolder);
        copyfile(fullfile(mccFolder, exeFile), outFolder);
        fprintf(logFID, "done.\n");
    end
end