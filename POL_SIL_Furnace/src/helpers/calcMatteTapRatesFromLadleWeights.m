function [matteTapRatesTonPerHr, nTappings, matteTapRatesEast, matteTapRatesCentre, matteTapRatesWest] = calcMatteTapRatesFromLadleWeights(dataTT)
    %CALCMATTETAPRATESFROMLADLEWEIGHTS Calculates the matte tapping rate for
    % each simulation timestep based on ladle weight data
    %   Inputs:
    %   - dataTT.Timestamp: simulation timestamps
    %   - dataTT.MatteTappedLadleEastTon,  dataTT.MatteTappedLadleCenterTon,
    %       dataTT.MatteTappedLadleWestTon: ladle weights as CONTINUOUS variable.
    %       Each of these must be the same length as timestamps.
    %       A change in one of these variables corresponds to the opening
    %       of the corresponding taphole
    %   - dataTT.MatteTapDurationEastSecs, dataTT.MatteTapDurationCenterSecs,
    %       dataTT.MatteTapDurationWestSecs: tapping durations as a CONTINUOUS
    %       variable. Each of these must be the same length as timestamps.
    %       A change in one of these variables corresponds to the opening
    %       of the corresponding taphole (as with the corresponding ladle
    %       weights)
          
    ladlesEast = [];
    timestampsEast = [];
    durationsEastSecs = [];
    
    ladlesCenter = [];
    timestampsCenter = [];
    durationsCenterSecs = [];
    
    ladlesWest = [];
    timestampsWest = [];
    durationsWestSecs = [];
    
    % extract info of each tapping event
    for idx = 2 : height(dataTT)
        if dataTT.MatteTappedLadleEastTon(idx) ~= dataTT.MatteTappedLadleEastTon(idx-1)
            ladlesEast = [ladlesEast; dataTT.MatteTappedLadleEastTon(idx)];
            timestampsEast = [timestampsEast; dataTT.Timestamp(idx)];
            durationsEastSecs = [durationsEastSecs; dataTT.MatteTapDurationEastSecs(idx)];
        end
    
        if dataTT.MatteTappedLadleCenterTon(idx) ~= dataTT.MatteTappedLadleCenterTon(idx-1)
            ladlesCenter = [ladlesCenter; dataTT.MatteTappedLadleCenterTon(idx)];
            timestampsCenter = [timestampsCenter; dataTT.Timestamp(idx)];
            durationsCenterSecs = [durationsCenterSecs; dataTT.MatteTapDurationCenterSecs(idx)];
        end
    
        if dataTT.MatteTappedLadleWestTon(idx) ~= dataTT.MatteTappedLadleWestTon(idx-1)
            ladlesWest = [ladlesWest; dataTT.MatteTappedLadleWestTon(idx)];
            timestampsWest = [timestampsWest; dataTT.Timestamp(idx)];
            durationsWestSecs = [durationsWestSecs; dataTT.MatteTapDurationWestSecs(idx)];
        end
    end
    
    matteTapRatesEast = calcMatteTapRatesFromLadleData(dataTT.Timestamp, ladlesEast, timestampsEast, durationsEastSecs);
    matteTapRatesCentre = calcMatteTapRatesFromLadleData(dataTT.Timestamp, ladlesCenter, timestampsCenter, durationsCenterSecs);
    matteTapRatesWest = calcMatteTapRatesFromLadleData(dataTT.Timestamp, ladlesWest, timestampsWest, durationsWestSecs);
    matteTapRatesTonPerHr = matteTapRatesEast + matteTapRatesCentre + matteTapRatesWest;
    nTappings = length(ladlesEast) + length(ladlesCenter) + length(ladlesWest);
end

function tapRatesTonPerHr = calcMatteTapRatesFromLadleData(timestamps, ladlesTon, tapStartTimestamps, tapDurationsSecs)
    assert(numel(ladlesTon) == numel(tapStartTimestamps) && numel(tapStartTimestamps) == numel(tapDurationsSecs))
    tapDurationsMins = ceil(tapDurationsSecs/60);
    tapRatesTonPerHr = zeros(size(timestamps));

    for ladleIdx = 1 : length(ladlesTon)
        tapRateTonPerHr = (ladlesTon(ladleIdx)/tapDurationsMins(ladleIdx)) * 60;
        % find correct indices
        tapStartIdx = find(timestamps == tapStartTimestamps(ladleIdx), 1);
        tapEndIdx = tapStartIdx + tapDurationsMins(ladleIdx) - 1;
        if tapEndIdx > numel(timestamps)
            tapEndIdx = numel(timestamps);
        end
        tapRatesTonPerHr(tapStartIdx : tapEndIdx) = tapRatesTonPerHr(tapStartIdx : tapEndIdx) + tapRateTonPerHr;
    end
end

