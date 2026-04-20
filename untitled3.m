%% CCE OFFLINE DATA INSPECTOR
% Use this to see exactly what the Coordinator is pulling from AF
clc; clear;

% 1. ESTABLISH THE CONNECTION (Admin Guide Page 32)
% Use the Server and Database names from your AF Attribute screenshot
afServer = 'ACPMES'; 
afDatabase = 'WACP';
dataConnector = cce.AFDataConnector(afServer, afDatabase);

% 2. FIND YOUR SPECIFIC CALCULATION ELEMENT
% Use the name of the element you showed in your screenshot
calcName = 'ccePyFatigueMonitoring'; 
records = dataConnector.findRecords('ElementSearch', sprintf("Name:='%s'", calcName));
targetCalc = records{1};

% 3. RETRIEVE THE PACKAGED DATA
% This command imitates the Coordinator's internal "packaging" logic.
% It identifies CCEInput vs CCEParameter and builds the structs.
[inputs, parameters] = dataConnector.getCalculationData(targetCalc);

% 4. PRINT AND INSPECT
fprintf('--- DATA RECEIVED FROM PI AF ---\n');

% Inspect Parameters (The constants like 'DaysBack', 'CorrosionOn')
fprintf('\nPARAMETERS RECEIVED:\n');
disp(parameters);

% Inspect Inputs (The timeseries data like 'Tag')
fprintf('\nINPUT FIELDS DETECTED:\n');
disp(fieldnames(inputs));

if isfield(inputs, 'Tag')
    fprintf('\nTAG DATA (First 5 rows):\n');
    % Create a table to easily see Values vs Timestamps
    T = table(inputs.TagTimestamps(1:5), inputs.Tag(1:5), ...
        'VariableNames', {'Timestamp', 'Value'});
    disp(T);
end