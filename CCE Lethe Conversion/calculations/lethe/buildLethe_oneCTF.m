% Get all calc Folders
folders = dir("convertedCalculations\");
folderNames = [];

for idx = 1:size(folders, 1)
    folderNames = [folderNames; string(folders(idx).name)];
end

folderNames(~contains(folderNames, {'cceLethe','cceACE'}),:) = [];

% Get wrappers
wrapperNames = cellstr(folderNames);

% Get additional dll files
dllFiles = cell(length(folderNames),1);

myDir = fileparts(mfilename("fullpath"));

for nComponent = 1:length(wrapperNames)
    componentName = wrapperNames{nComponent};
    if componentName ~= "cceACExDaysTotals"
        dllFiles{nComponent} = fullfile(myDir, 'convertedCalculations', componentName, [componentName '.dll']);
    else
        dllFiles{nComponent} = '';
    end
end

% Build and CTF
buildCalc("cceLetheCalculations", wrapperNames, dllFiles);