clear
clc

contData = readtable("dailyFeed2.xlsx", "Sheet", 2,"VariableNamingRule","modify");
% contData = contData(1,:);
variables = string(contData.Properties.VariableNames);

inputs = struct;

for idx = 2:2:length(variables)
    varName = variables(idx);
    inputs.(varName) = contData{:, varName};
    inputs.(varName+"Timestamps") = contData{:,idx-1};

    if iscell(inputs.(varName))
        inputs.(varName) = nan;
        inputs.(varName+"Timestamps") = NaT;
    end
end

%%

parameters = struct;
parameters.LogName = "DailyFeedLog";
parameters.CalculationID = "DailyFeed01";  
parameters.CalculationName = "Daily Feed";
parameters.LogLevel = 4;
parameters.OutputTime = "2024-06-18T11:00:00.000Z";



[outputs, errorCode] = cceACEDailyFeed(parameters,inputs);
