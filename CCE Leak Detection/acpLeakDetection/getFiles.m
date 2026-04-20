function fileNames = getFiles(outputPath)
%GETLASTOUTPUT Retrieves the last output file in a output folder (outputPath).

%   The filenames of interest have a name format like: 'pi_data_*.csv' 

folderInformation = dir(outputPath);
fileInfo = folderInformation([folderInformation.isdir] == 0);
fileNames = {fileInfo.name}';
fileNames = fileNames(contains(fileNames, "pi_data"));
% fileNamesSortIdx = sort(folderInformation);
% fileNameLast = fileNames(end);
end