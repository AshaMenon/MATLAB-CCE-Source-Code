% 

function outTT = combineSoundingsExample(soundingData)

% soundingData = readtable(compressedPath);
variables = string(soundingData.Properties.VariableNames);

inputs = struct;

for idx = 2:2:length(variables)
    varName = variables(idx);
    timestamps = soundingData{:,idx-1};
    natIdx = isnat(timestamps);

    inputs.(varName) = soundingData{~natIdx, varName};
    inputs.(varName+"Timestamps") = soundingData{~natIdx,idx-1};
end

outTT = combineSoundings(inputs);

end