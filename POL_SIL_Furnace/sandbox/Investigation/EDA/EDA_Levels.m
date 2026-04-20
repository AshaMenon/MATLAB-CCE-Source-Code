%% Levels Exploratory Data Analysis

clear
clc
%% Select data files

selectFile = true;
filename = selectDataFiles(selectFile);

%% Import data into MATLAB and correct timestamp

data = importData(filename);
dataTbl = data{1};
opts = delimitedTextImportOptions("NumVariables", 1);
opts.Delimiter = "\t";
levelTags = readcell("levelTags.csv", opts);
levelTags = matlab.lang.makeValidName(levelTags); 
dataTbl = dataTbl(:, levelTags);

%% Basic data analysis and preprocessing
[tableMissing, dataMissing] = findMissingData(dataTbl);
%missingDataAnalysis(dataTbl, dataMissing)

%% EDA - temperature tag analysis

timestamp = dataTbl.Timestamp;
label = "Level";

% Hard Paste Levels
tags = {'Electrode1HardPasteLevel'
'Electrode2HardPasteLevel'
'Electrode3HardPasteLevel'
'Electrode4HardPasteLevel'
'Electrode5HardPasteLevel'
'Electrode6HardPasteLevel'};

data = dataTbl(:, tags);
plotTimeseries(timestamp, data, label, tags, 'Hard Paste Levels')

%% Soft Paste Levels
tags = {'Electrode1SoftPasteLevel'
'Electrode2SoftPasteLevel'
'Electrode3SoftPasteLevel'
'Electrode4SoftPasteLevel'
'Electrode5SoftPasteLevel'
'Electrode6SoftPasteLevel'};

data = dataTbl(:, tags);
plotTimeseries(timestamp, data, label, tags, 'Soft Paste Levels')

%% Build Up Levels
tags = {'Build_UpLevelsPort1'
'Build_UpLevelsPort10'
'Build_UpLevelsPort11'
'Build_UpLevelsPort2'
'Build_UpLevelsPort3'
'Build_UpLevelsPort4'
'Build_UpLevelsPort5'
'Build_UpLevelsPort6'
'Build_UpLevelsPort7'
'Build_UpLevelsPort8'
'Build_UpLevelsPort1'};

data = dataTbl(:, tags);
plotTimeseries(timestamp, data, label, tags, 'Build-Up Levels')

visualisePortCounts(data)

%% Concentrate Levels (Bonedry)
tags = {'ConcentrateLevelsPort10'
'ConcentrateLevelsPort11'
'ConcentrateLevelsPort2'
'ConcentrateLevelsPort3'
'ConcentrateLevelsPort4'
'ConcentrateLevelsPort5'
'ConcentrateLevelsPort6'
'ConcentrateLevelsPort7'
'ConcentrateLevelsPort8'};

data = dataTbl(:, tags);
plotTimeseries(timestamp, data, label, tags, 'Concentrate Levels')
visualisePortCounts(data)

%% Matte Levels
tags = {'Port1MatteLevels'
'Port10MatteLevels'
'Port11MatteLevels'
'Port2MatteLevels'
'Port3MatteLevels'
'Port4MatteLevels'
'Port5MatteLevels'
'Port6MatteLevels'
'Port7MatteLevels'
'Port8MatteLevels'};

data = dataTbl(:, tags);
plotTimeseries(timestamp, data, label, tags, 'Matte Levels')
visualisePortCounts(data)

%% Slag Levels
tags = {'Port1SlagLevels'
'Port10SlagLevels'
'Port11SlagLevels'
'Port2SlagLevels'
'Port3SlagLevels'
'Port4SlagLevels'
'Port5SlagLevels'
'Port6SlagLevels'
'Port7SlagLevels'
'Port8SlagLevels'};

data = dataTbl(:, tags);
plotTimeseries(timestamp, data, label, tags, 'Slag Levels')
visualisePortCounts(data)

%% Total Bath Levels
tags = {'Port1TotalBathLevels'
'Port10TotalBathLevels'
'Port11TotalBathLevels'
'Port2TotalBathLevels'
'Port3TotalBathLevels'
'Port4TotalBathLevels'
'Port5TotalBathLevels'
'Port6TotalBathLevels'
'Port7TotalBathLevels'
'Port8TotalBathLevels'};

data = dataTbl(:, tags);
plotTimeseries(timestamp, data, label, tags, 'Total Bath Levels')

visualisePortCounts(data)


%% Bonedry Level vs Freeboard Temps

tags = {'ConcentrateLevelsPort10'
'ConcentrateLevelsPort11'
'ConcentrateLevelsPort2'
'ConcentrateLevelsPort3'
'ConcentrateLevelsPort4'
'ConcentrateLevelsPort5'
'ConcentrateLevelsPort6'
'ConcentrateLevelsPort7'
'ConcentrateLevelsPort8'
'CentreLineThermocouples770E'
'CentreLineThermocouples770H'
'CentreLineThermocouples770K'
'CentreLineThermocouples770C'
'CentreLineThermocouples770D'
'CentreLineThermocouples770F'
'CentreLineThermocouples770G'
'CentreLineThermocouples770I'
'CentreLineThermocouples770J'
'CentreLineThermocouples770L'
'CentreLineThermocouples770A'
'CentreLineThermocouples770B'
'CentreLineThermocouples770W'
'CentreLineThermocouples770X'
'CentreLineThermocouples770M'
'CentreLineThermocouples770N'
'CentreLineThermocouples770O'
'CentreLineThermocouples770P'
'CentreLineThermocouples770Q'
'CentreLineThermocouples770R'
'CentreLineThermocouples770S'
'CentreLineThermocouples770T'
'CentreLineThermocouples770U'
'CentreLineThermocouples770V'
};

data = dataTbl(:, tags);
plotTimeseries(timestamp, data, label, tags, 'Bonedry Level vs Freeboard Temperature')
%%
tags1 = {'ConcentrateLevelsPort10'
'ConcentrateLevelsPort2'
'ConcentrateLevelsPort3'
'ConcentrateLevelsPort4'
'ConcentrateLevelsPort5'
'ConcentrateLevelsPort6'
'ConcentrateLevelsPort7'
'ConcentrateLevelsPort8'
'CentreLineThermocouples770E'
'CentreLineThermocouples770H'
'CentreLineThermocouples770K'
'CentreLineThermocouples770C'
'CentreLineThermocouples770D'
'CentreLineThermocouples770F'
'CentreLineThermocouples770G'
'CentreLineThermocouples770I'
'CentreLineThermocouples770J'
'CentreLineThermocouples770L'
'CentreLineThermocouples770A'
'CentreLineThermocouples770B'
'CentreLineThermocouples770W'
'CentreLineThermocouples770X'
'CentreLineThermocouples770M'
'CentreLineThermocouples770N'
'CentreLineThermocouples770O'
'CentreLineThermocouples770P'
'CentreLineThermocouples770Q'
'CentreLineThermocouples770R'
'CentreLineThermocouples770S'
'CentreLineThermocouples770T'
'CentreLineThermocouples770U'
'CentreLineThermocouples770V'
};

data1 = dataTbl(:, tags);
data1.MeanTemp = mean(dataTbl{:, })