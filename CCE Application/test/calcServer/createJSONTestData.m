%% Create Test Data
% Create test for JSON serialisation & deserialisation

inputCell = {{[1 2 3 4], [4, 3, 2, 1], 'FileName'};{3,'2'};{}};
numOfOutputsArray = [0;2;1];

for i = 1:3
    inputs = inputCell{i};
    numOfOutputs = numOfOutputsArray(i);
    jsonString = mps.json.encoderequest(inputs, 'nargout', numOfOutputs);
    structOutput = jsondecode(jsonString);
    matName = sprintf('jsonCase%d',i);
    save(matName, 'inputs', 'numOfOutputs', 'jsonString', 'structOutput'); 
end
