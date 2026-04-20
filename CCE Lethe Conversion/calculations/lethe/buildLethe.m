function buildLethe(componentName, logFID)
    %BUILDLETHE Automatically builds Lethe calculation
    %   Inputs:
    %       componentName - Char of the CTF file, (this is the same name as
    %       the matlab wrapper function)
    
    arguments
        componentName char = '';
        logFID (1,1) double = 1;
    end
    
    % Create MATLAB wrapper for Lethe calc
    % wrapperName = createLetheCalcWrapper(componentName);
    wrapperName = componentName;
    
    %Build .dll
    myDir = fileparts(mfilename("fullpath"));
    [status, msDevEnvCmd] = system("""C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe"" -property productPath");
    if (status~=0)
        error("ons:buildCalcServerSrtefacts:VSNotFound", "Could not find Visual Studio installed on machine. Message is: %s", msDevEnvCmd);
    end
    msDevEnvCmd = """" + strtrim(msDevEnvCmd) + """";
    slnFilePath = fullfile(myDir, "convertedCalculations", componentName, [componentName '.sln']);
    projPath = fullfile(myDir, "convertedCalculations", componentName, componentName, [componentName '.csproj']);
    
    fprintf(logFID, ['Building .Net Assembly for ' componentName '...' ]);
    sysCmd = sprintf("%s %s /project %s /build Release", msDevEnvCmd, slnFilePath, projPath);
    [res, msg] = system(sysCmd);
    if (res == 0)
        %Copy file to outer folder if .dll is not already in outer folder
        if ~exist(fullfile(myDir, 'convertedCalculations',componentName, [componentName '.dll']), "file")
            dllPath = fullfile(myDir, 'convertedCalculations',componentName, componentName, 'bin', 'Release', [componentName '.dll']);
            copyfile(dllPath, fullfile(myDir, 'convertedCalculations', componentName));
        end
        fprintf(logFID, "done.\n");
    else
        fprintf(logFID, "failed:\n%s", msg);
    end
       
    % Clean up the folders created by these build processes
    fprintf(logFID, "Cleaning up Lethe build process folders...");
    fprintf(logFID, "obj...");
    objDir = fullfile(myDir, 'convertedCalculations', componentName, componentName, 'obj');
    if exist(objDir, "dir")
        rmdir(objDir, "s");
    end
    
    fprintf("done.\n");
    
    % Build and CTF
    buildCalc(wrapperName, {wrapperName},...
        {fullfile(myDir, 'convertedCalculations', componentName, [componentName '.dll'])});
end

