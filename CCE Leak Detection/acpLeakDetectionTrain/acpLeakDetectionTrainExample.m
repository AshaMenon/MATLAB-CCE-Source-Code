% Example script for executing R Calculation via MATLAB

%% Parameters
parameters = struct;
parameters.OutputTime = "2023-09-02T06:00:00.000Z";
parameters.LogName = "ContRampTo2Total.log";
parameters.CalculationName = "ACEContRampTo2Total";
parameters.CalculationID = "ACEContRampTo2Total";
parameters.LogLevel = 4;

%% Inputs

inputs = struct;

data = readtable('LDTrain.xlsx','VariableNamingRule', 'preserve', 'Sheet',5);

varNames = string(data.Properties.VariableNames);

for n = 2:length(varNames)
    inputs.(varNames(n)) = data{:,varNames(n)};
    inputs.(varNames(n) + "Timestamps") = data.Var1;
end

%% Evaluate R Calc
[outputs, errorCode] = acpLeakDetectionTrain(parameters,inputs);
