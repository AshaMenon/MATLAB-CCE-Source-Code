%% FeMatte Model Evaluation

runRange = 1440;
rawInputs = readAndFormatData('sept22Chemistry');
rawInputs = rawInputs(end-(runRange+1000):end,:);
% rawInputs.("Converter mode")(end-120:end) = 1;

% make it safe to pass to Python
rawInputs.Properties.VariableNames = strrep(rawInputs.Properties.VariableNames, " ", "_");

outStruct = struct('Timestamp', [],'AlignedFeMatte', []);

% setup the parameters
parameters = AlignFeMatteParams;

%% Matlab Example
for endPoint = runRange+1:height(rawInputs)
    tempIn = rawInputs(endPoint-runRange:endPoint,:);
    inputs = table2struct(tempIn, "ToScalar",true);
    inputs.Timestamp = tempIn.Timestamp;

    [outputs, errorCode] = EvaluateFeMatteModel(parameters, inputs);

    outStruct = [outStruct, outputs];
end