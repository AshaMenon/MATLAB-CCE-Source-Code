function [changedValues, changeTimestamps, changeIndices] = extractChanges(values, timestamps, tolerance)
    %EXTRACTCHANGES finds values that are different to the previous one
    %  The function returns those changed values and their corresponding timesteps
    %  It is used to extract discrete samples such as sounding
    %  measurements, where the previous value is held until a new sample is
    %  taken
    changedValues = [];
    changeTimestamps = [];
    changeIndices = [];
    for idx = 2 : numel(values)
        if abs(values(idx) - values(idx-1)) > tolerance
            changedValues = [changedValues; values(idx)];
            changeTimestamps = [changeTimestamps; timestamps(idx)];
            changeIndices = [changeIndices; idx];
        end
    end
end