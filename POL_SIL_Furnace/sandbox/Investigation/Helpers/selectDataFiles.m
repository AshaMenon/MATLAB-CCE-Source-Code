function filename = selectDataFiles(selectFile)
    %SELECTDATAFILES  Activates the file browser to select a file for 
    % import when set to true

    if selectFile == true
        [filename,filepath] = uigetfile("*.*", "MultiSelect","on");     % Obtains the file path and fine names of the files required for EDA. Can import multiple files at once.
        addpath(filepath)   % Adds folders to file path
    end
end