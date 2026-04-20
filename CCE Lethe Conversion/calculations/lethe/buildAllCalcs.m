folders = dir("convertedCalculations\");
folderNames = [];

for idx = 1:size(folders, 1)
    folderNames = [folderNames; string(folders(idx).name)];
end

folderNames(~contains(folderNames, 'cceLethe'),:) = [];

for calcIdx = 1:length(folderNames)
    buildLethe(folderNames(calcIdx))
end