function deployCalcs(logFID)
    %DEPLOYCALCS Deploys CCE calculations to the folder specified in the CalcServerHostName
    %server, in the CalcServerAutoDeployFolder.
    
    %Calculations are copied from the build folder
    
    arguments
        logFID (1,1) double = 1;
    end
    
    hostName = cce.System.CalcServerHostName;
    deployFolderName = cce.System.CalcServerAutoDeployFolder;
    deployFolderPath =  ['\\', hostName, '\', deployFolderName];
    if ~exist(deployFolderPath, 'dir')
        mkdir(deployFolderPath)
    end
    
    outDir = getpref('CCECalcDev', 'OutputFolder');
    
    fprintf(logFID, "Deploying calcs from build folder to server...\n");
    
    [status, msg] = copyfile([outDir '\*.ctf'], deployFolderPath);
    if status
        fprintf(logFID, 'CTFs deployed to %s: Successful\n', deployFolderPath);
    else
        fprintf(logFID, 'CTFs deployed to %s: Unsuccessful\n', deployFolderPath);
        fprintf(logFID, msg);
    end
    
end