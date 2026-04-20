function readData = readRData(path)
files = getFiles(path);
readData = [];
for f = 1:size(files,1)
    currData = readtable(fullfile(path, string(files(f))));
    readData = [readData;currData];
end
readData.Properties.VariableNames = {'Tag','Timestamp','Value'};
end