function cleanUps = prepEnvironmentForCompiler()
    %prepEnvironmentForCompiler  Attempt to make a clean environment for Compiler
    %   cu = prepEnvironmentForCompiler prepares the MATLAB environment for compiling. THis means that:
    %       + The current folder is added to the path.
    %       + MATLAB changes to a blank folder.
    %       + ALL Preferences are removed.
    %       + ALL startup files are renamed.
    %
    % If you need any of these things in your code, you're doing it wrong.

    % Start by using a blank folder
    currentFolder = pwd;
    blankFolder = tempname(pwd);
    mkdir(blankFolder);
    cd(blankFolder);
    cuFolder = onCleanup(@()restorePwd(currentFolder, blankFolder));
    % Preferences folder
    allPref = getpref;
    if isempty(allPref)
        cuPrefs = [];
    else
        cuPrefs = onCleanup(@()restorePrefs(allPref));
        clearPrefs(allPref);
    end

    % Startup files
    startupFile = which('startup', '-all');
    if isempty(startupFile)
        cuStartup = [];
    else
        % Rename them all
        for k=1:numel(startupFile)
            system(sprintf("rename %s startup.m.bld", startupFile{k}));
        end
        cuStartup = onCleanup(@()restoreStartup(startupFile));
    end
    cleanUps = [cuFolder, cuPrefs, cuStartup];
end

%====================== HELPER FUNCTIONS ======================
function clearPrefs(p)
    %clearPrefs  Clear preferences
    pGroups = fieldnames(p);
    for k = 1:numel(pGroups)
        rmpref(pGroups{k});
    end
end

function restorePrefs(p)
    %retorePrefs  Restore preferences files
    pGroups = fieldnames(p);
    for k = 1:numel(fieldnames(p))
        setpref(pGroups{k}, fieldnames(p.(pGroups{k})), struct2cell(p.(pGroups{k})));
    end
end

function restorePwd(origFolder, blankFolder)
    %restorePwd  Restore the PWD and remove the temporary folder
    cd(origFolder);
    rmdir(blankFolder, "s");
end

function restoreStartup(startupFiles)
    for k=1:numel(startupFiles)
        system(sprintf("rename %s.bld startup.m", startupFiles{k}));
    end
end