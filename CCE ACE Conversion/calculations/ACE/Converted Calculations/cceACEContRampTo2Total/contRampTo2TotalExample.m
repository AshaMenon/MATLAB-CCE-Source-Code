%% Inputs
contData = readtable("ContRampTo2TotalData.xlsx", "Sheet","Inputs");
variables = string(contData.Properties.VariableNames);

inputs = struct;

for varName = variables
    inputs.(varName) = contData{:, varName};
end

%% Parameters

parameters = struct;
parameters.OutputTime = "2023-05-05T06:00:00.000Z";
parameters.LogName = "ContRampTo2Total.log";
parameters.CalculationName = "ACEContRampTo2Total";
parameters.CalculationID = "ACEContRampTo2Total";
parameters.LogLevel = 4;
parameters.CompDev = 149.999847;
parameters.Zero = 0;

%%

expectedOutputs = readtable("ContRampTo2TotalData.xlsx", "Sheet","Outputs");

%% Run Calc
[outputs, errorCode] = cceACEContRampTo2Total(parameters, inputs);