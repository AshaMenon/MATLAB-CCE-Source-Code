function maxValues = calculateLevelMax(data, columns)
    %UNTITLED3 Summary of this function goes here
    %   Detailed explanation goes here
    diffIndices = [false(1, sum(columns)); diff(data) ~= 0];

    % Replace unchanged values in the original data with NaN
    data(~diffIndices) = NaN;
    data(data == 0) = NaN;
    
    % Compute max across columns for each row
    maxValues = max(data, [], 2, 'omitnan');

    % For rows where no values changed, use the previous max value
    for i = 2:length(data)
        if isnan(maxValues(i))
            maxValues(i) = maxValues(i-1);
        end
    end
end