function deployCalc(componentName)
    %deployCalc Deploys component ctf file to the deployment folder
    %   Inputs:
    %       componentName - char of the componentName to be copied to the
    %       server.
    %       e.g. deployCalc('apcQuantExpression')
    
    hostName = cce.System.CalcServerHostName;
    deployFolderName = cce.System.CalcServerAutoDeployFolder;
    deployFolderPath =  ['\\', hostName, '\', deployFolderName];
    outDir = getpref('CCECalcDev', 'OutputFolder');
    
    fileName = fullfile(outDir, [componentName, '.ctf']);
    
    status = copyfile(fileName, deployFolder);
    if status
        msg = sprintf('%s deployed to %s: Successful\n', fileName, deployFolderPath);
    else
        msg = sprintf('%s deployed to %s: Unsuccessful\n', fileName, deployFolderPath);
    end
    disp(msg)
end

