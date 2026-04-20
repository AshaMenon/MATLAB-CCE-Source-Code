function [value,quality] = replaceMissingData(value,quality, goodQualityVal)
%REPLACEMISSINGDATA Missing data replacement through sample and hold

% Copyright 2013 Anglo American Platinum

if nargin < 2
    quality = [];
end

% Replace missing data with last good value
nanInd = [0; diff(isnan(value))];
startInd = find(nanInd == 1);
stopInd = find(nanInd == -1)-1;
% For each of the start indices
for j = 1:size(startInd,1)
    boundaryIn = startInd(j);
    boundaryOut = find(stopInd >= startInd(j));
    if ~isempty(boundaryOut)
        boundaryOut = boundaryOut(1);
        tmpBoundaryOut = stopInd(boundaryOut);
        stopInd(boundaryOut) = [];
        boundaryOut = tmpBoundaryOut;
    else
        boundaryOut = size(value,1);
    end
    value(boundaryIn:boundaryOut) = value(boundaryIn-1);
    if ~isempty(quality)
        quality(boundaryIn:boundaryOut) = goodQualityVal*ones(size(quality(boundaryIn:boundaryOut)));
    end
end
% If there is a stop index at the start of the dataset
if ~isempty(stopInd)
    value(1:stopInd) = value(stopInd+1);
    if ~isempty(quality)
        quality(1:stopInd) = goodQualityVal*ones(size(quality(1:stopInd)));
    end
end