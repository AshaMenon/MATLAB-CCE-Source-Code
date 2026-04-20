addInputs = readtable("CalculatedLevelData2.xlsx", Sheet="Add2");
subInputs = readtable("CalculatedLevelData2.xlsx", Sheet="Subtract2");
survInputs = readtable("CalculatedLevelData2.xlsx", Sheet="Surveyed2");
measInputs = readtable("CalculatedLevelData2.xlsx", Sheet="Measured2");
outputData = readtable("CalculatedLevelData2.xlsx", Sheet="Outputs2");

inputs = struct;

% Add
addInputs = formatInputs(addInputs, "Add");
variables = string(addInputs.Properties.VariableNames);

for var = variables
    inputs.(var) = addInputs.(var);
end

% Sub
subInputs = formatInputs(subInputs, "Subtract");
variables = string(subInputs.Properties.VariableNames);

for var = variables
    inputs.(var) = subInputs.(var);
end

% Surveyed
survInputs = formatInputs(survInputs, "Surveyed");
variables = string(survInputs.Properties.VariableNames);

for var = variables
    inputs.(var) = survInputs.(var);
end

% Measured
measInputs = formatInputs(measInputs, "Measured");
variables = string(measInputs.Properties.VariableNames);

for var = variables
    inputs.(var) = measInputs.(var);
end

% Outputs
outputData = formatInputs(outputData, "");

inputs.TheoreticalStockLevelIn = outputData.TheoreticalStockLevel;
inputs.TheoreticalStockLevelInTimestamps = outputData.TheoreticalStockLevelTimestamps;

%% Parameters

parameters = struct;
parameters.OutputTime = "2023-05-01T06:52:00.000Z";
parameters.LogName = "CalculatedLevel.log";
parameters.CalculationName = "ACEUSMLCalculatedLevel";
parameters.CalculationID = "ACEUSMLCalculatedLevel";
parameters.LogLevel = 4;
parameters.DaysBack = 10;

[outputs, errorcode] = cceACECalculatedLevel(parameters, inputs);

%%

function formatedInput = formatInputs(inTbl, prefix)
    variables = string(inTbl.Properties.VariableNames);

    for n = 2:2:length(variables)
        variables(n) = prefix + variables(n);
        variables(n-1) = variables(n) + "Timestamps";
    end

    inTbl.Properties.VariableNames = variables;
    formatedInput = inTbl;
end