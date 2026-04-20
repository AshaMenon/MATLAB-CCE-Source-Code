%% Inputs
contData = readtable("FeedProfileSixInLine_WSMLData.xlsx", "Sheet", 2);
variables = string(contData.Properties.VariableNames);

for n = 1:2:length(variables)
    variables(n) = variables(n+1) + "Timestamps";
end

contData.Properties.VariableNames = variables;
variables(1:14) = [];

inputs = struct;

for varName = variables
    inputs.(varName) = contData{:, varName};
end


%% Parameters

parameters = struct;
parameters.OutputTime = "2023-05-23T05:41:00.000Z";
parameters.LogName = "FeedProfileSixInLine_WSML.log";
parameters.CalculationName = "ACEFeedProfileSixInLine_WSML";
parameters.CalculationID = "ACEFeedProfileSixInLine_WSML";
parameters.LogLevel = 4;

%%

expectedOutputs = contData(:,1:14);

%%

[outputs,errorCode] = cceACEFeedProfileSixInLine_WSML(parameters, inputs);