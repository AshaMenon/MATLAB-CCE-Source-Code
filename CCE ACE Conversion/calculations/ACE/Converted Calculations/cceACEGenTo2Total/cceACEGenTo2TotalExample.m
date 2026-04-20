%% Inputs
contData = readtable("GenTo2TotalData.xlsx", "Sheet","InputsCompressed");
variables = string(contData.Properties.VariableNames);

inputs = struct;

for n = 1:2:length(variables)
    variables(n) = variables(n+1) + "Timestamps";
end

contData.Properties.VariableNames = variables;
% inputs.PV_V_Transfer_Daily_Ave_86400_18000_eAve = contData.PV_V_Transfer_Daily_Ave_86400_18000_eAve;
% inputs.PV_V_Transfer_Daily_Ave_86400_18000_eAveTimestamps = contData.PV_V_Transfer_Daily_Ave_86400_18000_eAveTimestamps;
for varName = variables
    inputs.(varName) = contData{:, varName};
end

%% Parameters
contData = readtable("GenTo2TotalData.xlsx", "Sheet", "FormulaParam");
variables = string(contData.Properties.VariableNames);

parameters = struct;
parameters.OutputTime = "2023-04-18T05:05:00.000Z";
parameters.LogName = "GenTo2Total.log";
parameters.CalculationName = "ACEGenTo2Total";
parameters.CalculationID = "ACEGenTo2Total";
parameters.LogLevel =  4;
parameters.ElementName = "GenTo2valTotal.24.5";
parameters.Formula = "'tag'/1000 + ('x345-LI-203/PV.V'86400.18000.SInt' - 'x345-LI-203/PV.V'86400.18000.EInt')";

%% Formula Inputs

contData = readtable("GenTo2TotalData.xlsx", "Sheet","FormulaCompressed");
variables = string(contData.Properties.VariableNames);

for n = 1:2:length(variables)
    variables(n) = variables(n+1) + "Timestamps";
end

contData.Properties.VariableNames = variables;

for varName = variables
    inputs.("Formula_" + varName) = contData{:, varName};
end

%%

expectedOutputs = readtable("GenTo2TotalData.xlsx", "Sheet","OutputsCompressed");

%% Run Calc
[outputs, errorCode] = cceACEGenTo2Total(parameters, inputs);