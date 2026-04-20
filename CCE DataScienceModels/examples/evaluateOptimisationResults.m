%% Evaluate Optimisation Results - Temperature Model

idx = 1445;
initialOffset = 120;

% set up outputs for plotting
columns = {'Timestamp', 'Simulated Matte Temperature', 'Simulated Slag Temperature',...
            'Simulated Matte Height', 'Simulated Slag Height',...
            'Simulated Total Bath Height', 'Matte Tapping', 'Slag Tapping',...
            'Recommended Fuel Coal SP', 'Heat Conducted from Slag to Matte',...
            'Heat Mass Flow from Slag to Matte', 'Heat Conducted from Matte to Waffle Cooler',...
            'Heat Mass Flow Matte Tapped Matte Bath', 'Heat Generated Slag',...
            'Heat Mass Flow from Slag to Inflow', 'Heat Mass Flow Matte Tapped Full Bath',...
            'Heat Mass Flow Slag Tapped', 'Heat Conducted from Full Bath to Waffle Cooler',...
            'Heat Radiated from Slag to Furnace', 'Heat Mass Flow from Offgas to Furnace',...
            'Heat Mass Flow from Accrued Slag and Dust to Furnace', 'Total Heat In Matte',...
            'Total Heat Out Matte', 'Total Heat In Bath', 'Total Heat Out Bath'}; % , 'Close on Slag'

% Get Data
origData = readAndFormatData('Temperature2023');
origData = retime(origData, unique(origData.Timestamp), 'previous');
origData = timetable2table(origData);
% origData = table2struct(origData);
origData.Properties.VariableNames = strrep(origData.Properties.VariableNames, " ", "");
origData.Properties.VariableNames = strrep(origData.Properties.VariableNames, "&", "and");
origData.Properties.VariableNames = strrep(origData.Properties.VariableNames, "%", "Percentage");
% initialPoint = find(origData.Timestamp == {'19-Feb-0022 00:00:00'}); %TODO: Generalise. Basically the first entry where there aren't a whole bunch of nans in 2 of the columns and where there's a working converter mode.

% Minor Data Preprocessing
origData.Lanceheight(origData.Lanceheight < 0) = 0;
% [~, ~, newMatteTemps] = Data.getUniqueDataPoints(table2timetable(origData(:, {'Timestamp', 'Mattetemperatures'})));
% [~, ~, newSlagTemps] = Data.getUniqueDataPoints(table2timetable(origData(:, {'Timestamp', 'Slagtemperatures'})));
% origData.Mattetemperatures = newMatteTemps.Mattetemperatures;
% origData.Slagtemperatures = newSlagTemps.Slagtemperatures;
origData.Al2O3FeedblendTimestamp = origData.Timestamp;
origData.Timestamp = [];

% origData = origData(initialPoint+5000:initialPoint+5000+50000,:);
% origData = origData(initialPoint+5000:end,:);


optParamFileName = 'optParams12July2023.xml'; % or empty char, '', 'optParams15-Sep-0022015000.xml'
simMode = 'simulation'; % or 'production'

% Get Parameters
parameters = initialMatteTemperatureParams(optParamFileName, simMode); %TODO: More complex types (arrays, structs, etc) need to loaded in after the calc is called

startIdx = 220681;
stepSize = 4421;

inputData = table2struct(origData(startIdx:end,:));

% Call Evaluate Temperature Model
[evalOut, evalErrCode] = EvaluateTemperatureModel(parameters, inputData);

% Write out predictions to Live Predictions Table
evalTable = struct2table(evalOut);
evalTable.Timestamp = datetime(evalTable.Timestamp);
evalTable = table2timetable(evalTable, 'RowTimes', 'Timestamp');
% livePredictions(dataIdx-initialPoint+1, :) = evalTable(end, :);

%%

data = origData;
simulatedData = evalTable;

plotSimulationResults(data,simulatedData)


data = unique(table2timetable(origData));
data = retime(data, simulatedData.Timestamp);