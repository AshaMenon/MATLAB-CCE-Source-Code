function [fullTimestamp, fullTM] = matchTimeStampsAndData(fullTimestamp, origTimestamp, fullTM)
%match output timestamps to original input timestamps

% Initialize indices and matching rows
idx = zeros(length(origTimestamp), 1);

% Find nearest timestamps
for i = 1:length(origTimestamp)
    [~, nearestIdx] = min(abs(fullTimestamp - origTimestamp(i)));
    idx(i) = nearestIdx;
end

% Extract matching rows
fullTimestamp = fullTimestamp(idx, :);
fullTM = fullTM(idx, :);
end