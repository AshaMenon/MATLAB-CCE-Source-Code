%% Matte Temperature Model Test
% Load and convert data as if it were passed from CCE
origData =  prepareDataSource(); 

rawData = readAndFormatData('test');
rawData = timetable2table(rawData);

rawData.Properties.VariableNames = strrep(rawData.Properties.VariableNames, " ", "");
rawData.Properties.VariableNames = strrep(rawData.Properties.VariableNames, "%", "Percentage");
rawData.Properties.VariableNames = strrep(rawData.Properties.VariableNames, "&", "and");

% Setup parameters
parameters = initialMatteTemperatureParams("optParams12July2023.xml");

%% Choose Index for Data to be Simulated
idx = 1:9000;
data = rawData(idx,:);
% data = timetable2table(data);
% data.Timestamp = string(data.Timestamp);
inputs = table2struct(data);

%% MATLAB Example
[outputs, errorCode] = MatteTemperatureModel(parameters, inputs);

%Date range on data
startDate = string(origData.Timestamp(idx(1)));
endDate = string(origData.Timestamp(idx(end)));
dates = sprintf('This is data ranging from %s to %s',startDate,endDate);
disp(dates);

