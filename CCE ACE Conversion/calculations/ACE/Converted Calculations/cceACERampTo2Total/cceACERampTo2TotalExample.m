%% Inputs
contData = readtable("RampTo2TotalData.xlsx", "Sheet","Inputs");
variables = string(contData.Properties.VariableNames);

inputs = struct;

for varName = variables
    inputs.(varName) = contData{:, varName};
end

%% Parameters
contData = readtable("RampTo2TotalData.xlsx", "Sheet", "FormulaParam");
variables = string(contData.Properties.VariableNames);

parameters = struct;
parameters.OutputTime = "2023-04-16T05:00:01.000Z";
parameters.LogName = "RampTo2Total.log";
parameters.CalculationName = "ACERampTo2Total";
parameters.CalculationID = "ACERampTo2Total";
parameters.LogLevel =  4;
parameters.Formula = 0.000277778;

for varName = variables
    parameters.(varName) = contData{:, varName};
end


%%

expectedOutputs = readtable("RampTo2TotalData.xlsx", "Sheet","Outputs");

%% Run Calc
[outputs, errorCode] = cceACERampTo2Total(parameters, inputs);