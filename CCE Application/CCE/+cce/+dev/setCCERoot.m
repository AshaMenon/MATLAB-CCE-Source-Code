function setCCERoot(rootType)
    %setCCERoot  Set the CCE_Root environment variable for development
    %   setCCERoot('dev') or setCCERoot() sets the CCE_Root environment variable to use the WACP database.
    %   setCCERoot('test') sets the CCE_Root environment variable to use the CCETest database. Only use
    %       this for unit tests, and ensure that your unit tests reset the CCETest environment when
    %       finished.
    %
    %   setCCERoot(someFolder) sets CCE_Root to the value of someFolder.
    
    % Copyright 2021 Opti-Num Solutions (Pty) Ltd.
    % Version: $Format:%ci$ ($Format:%h$)

    arguments
        rootType (1,1) string = "dev"
    end
    
    switch lower(rootType)
        case "dev"
            rootFolder = fullfile(fileparts(fileparts(fileparts(fileparts(mfilename("fullpath"))))),"configFiles", "wacpRoot");
            msgStr = "WACP";
        case "test"
            rootFolder = fullfile(fileparts(fileparts(fileparts(fileparts(mfilename("fullpath"))))),"configFiles", "configRoot");
            msgStr = "CCETEST";
        case "prod"
            rootFolder = fullfile(fileparts(fileparts(fileparts(fileparts(mfilename("fullpath"))))),"configFiles", "prod");
            msgStr = "CCEPROD";
            warning("Bad things could happen unless you're just reading configurations!");
        otherwise
            rootFolder = rootType;
            msgStr = "custom";
    end
    if ~exist(rootFolder, "dir")
        error("CCE:setCCERoot:FolderNotFound", "Folder '%s' not found.", rootFolder);
    end
    setenv("CCE_Root", rootFolder);
    fprintf("Set CCE_ROOT to %s\n", msgStr);
end

