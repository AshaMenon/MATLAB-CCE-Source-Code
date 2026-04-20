function avgValues = calculateLevelAverage(data, columns)
    %UNTITLED3 Summary of this function goes here
    %   Detailed explanation goes here
    diffIndices = [false(1, sum(columns)); diff(data) ~= 0];

    % Replace unchanged values in the original data with NaN
    data(~diffIndices) = NaN;
    data(data == 0) = NaN;
    % Compute mean across columns for each row
    avgValues = mean(data, 2, 'omitnan');

    for i = 2:length(data)
        if isnan(avgValues(i))
            avgValues(i) = avgValues(i-1);
        end
    end
end