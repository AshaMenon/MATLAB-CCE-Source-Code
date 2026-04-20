%% Offline Simulation - Temperature Model
% load("fundamental.mat")

idx = 1445;
dataLength = 240;

% set up outputs for plotting
columns = {'Timestamp', 'Simulated Matte Temperature', 'Simulated Slag Temperature',...
            'Smoothed Matte Temperature','Smoothed Slag Temperature',...
            'Simulated Matte Height', 'Simulated Slag Height',...
            'Simulated Total Bath Height', 'Matte Tapping', 'Slag Tapping',...
            'Slag Tapping Tap Block','Thermo Slag Tapping',...
            'Recommended Fuel Coal SP', 'Heat Conducted from Slag to Matte',...
            'Heat Mass Flow from Slag to Matte', 'Heat Conducted from Matte to Waffle Cooler',...
            'Heat Mass Flow Matte Tapped Matte Bath', 'Heat Generated Slag',...
            'Heat Mass Flow from Slag to Inflow', 'Heat Mass Flow Matte Tapped Full Bath',...
            'Heat Mass Flow Slag Tapped', 'Heat Conducted from Full Bath to Waffle Cooler',...
            'Heat Radiated from Slag to Furnace', 'Heat Mass Flow from Offgas to Furnace',...
            'Heat Mass Flow from Accrued Slag and Dust to Furnace', 'Total Heat In Matte',...
            'Total Heat Out Matte', 'Total Heat In Bath', 'Total Heat Out Bath',...
            'Slag Tapping Rate','Matte Tapping Rate'}; % , 'Close on Slag'
        
livePredictions = table('Size', [idx - dataLength, length(columns)],...
    'VariableTypes', ['datetime', repmat({'double'}, [1, length(columns) - 1])],...
    'VariableNames', columns);
livePredictions{:, 2:end} = nan;

% Get Data
origData = readAndFormatData('Temperature2023');
origData = timetable2table(origData);
% origData = table2struct(origData);
origData.Properties.VariableNames = strrep(origData.Properties.VariableNames, " ", "");
origData.Properties.VariableNames = strrep(origData.Properties.VariableNames, "&", "and");
origData.Properties.VariableNames = strrep(origData.Properties.VariableNames, "%", "Percentage");
initialPoint = find(origData.Timestamp == {'15-Feb-0023 00:00:00'}); %TODO: Generalise. Basically the first entry where there aren't a whole bunch of nans in 2 of the columns and where there's a working converter mode.
origData.Al2O3FeedblendTimestamp = origData.Timestamp;
origData.Timestamp = [];

optParamFileName = 'optParams12July2023.xml';
simMode = 'production'; % or 'simulation'

% Get Parameters
parameters = initialMatteTemperatureParams(optParamFileName, simMode); %TODO: More complex types (arrays, structs, etc) need to loaded in after the calc is called
initialOffset = 220000;

for endPoint = initialOffset:100:height(origData)
    startPoint = endPoint - dataLength;
    idxi = startPoint:endPoint;
    inputData = table2struct(origData(idxi, :));
%     inputData = table2struct(origData);
    
    % Call Evaluate Temperature Model
    [evalOut, evalErrCode] = EvaluateTemperatureModel(parameters, inputData);
    
    % Write out predictions to Live Predictions Table
    evalTable = struct2table(evalOut);
    livePredictions(endPoint-initialOffset+1, :) = evalTable(end, :);
end