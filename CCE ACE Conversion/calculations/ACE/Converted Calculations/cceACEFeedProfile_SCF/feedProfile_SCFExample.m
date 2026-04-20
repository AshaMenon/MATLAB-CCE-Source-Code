%% Inputs
contData = readtable("FeedProfile_SCFData.xlsx", "Sheet", 4);
variables = string(contData.Properties.VariableNames);

for n = 1:2:length(variables)
    variables(n) = variables(n+1) + "Timestamps";
end

contData.Properties.VariableNames = variables;
variables(1:24) = [];

inputs = struct;

for varName = variables
    inputs.(varName) = contData{:, varName};
end


%% Parameters

parameters = struct;
parameters.OutputTime = "2021-07-29T05:45:00.000Z";
parameters.LogName = "FeedProfile_SCF.log";
parameters.CalculationName = "ACEFeedProfile_SCF";
parameters.CalculationID = "ACEFeedProfile_SCF";
parameters.LogLevel = 4;

%%

expectedOutputs = contData(:,1:24);

%%

[outputs,errorCode] = cceACEFeedProfile_SCF(parameters, inputs);