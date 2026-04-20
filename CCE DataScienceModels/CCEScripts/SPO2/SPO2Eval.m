%% SPO2 Evaluation Test

runRange = 1440;
rawInputs = readAndFormatData('sept22Chemistry');
rawInputs = rawInputs(end-(runRange+1000):end,:);
% rawInputs.("Converter mode")(end-120:end) = 1;

% setup the parameters
parameters = SPO2Params;

% make it safe to pass to Python
rawInputs.Properties.VariableNames = strrep(rawInputs.Properties.VariableNames, " ", "_");


if parameters.NiSlagTarget > 0
    outStruct = struct('Timestamp', [],'SpO2Change', []);
else
    outStruct = struct('Timestamp', [],'SpO2Change', [], 'CalcCorrNiSlag', [], 'CalcNiTarget', []);
end

% make it safe to pass to Python
rawInputs.Properties.VariableNames = strrep(rawInputs.Properties.VariableNames, " ", "_");
inputs = table2struct(rawInputs, "ToScalar",true);

%% Matlab Example
for endPoint = runRange+1:height(rawInputs)
    tempIn = rawInputs(endPoint-runRange:endPoint,:);
    inputs = table2struct(tempIn, "ToScalar",true);
    inputs.Timestamp = tempIn.Timestamp;

    [outputs, errorCode] = EvaluateSPO2Model(parameters, inputs);

    outStruct = [outStruct, outputs];
end
