function [matteTapRatesTonPerHr, nTappings] = calcMatteTapRatesFromThermalCamera(dataTT, ladleWeightTon, minimumTapDurationMins)
    TAP_OPEN_TEMP_THRESHOLD = 1200; % tap hole open if temperature > threshold

    tap1Open = dataTT.MatteTap1ThermalCameraTemp > TAP_OPEN_TEMP_THRESHOLD;
    tap2Open = dataTT.MatteTap2ThermalCameraTemp > TAP_OPEN_TEMP_THRESHOLD;
    tap3Open = dataTT.MatteTap3ThermalCameraTemp > TAP_OPEN_TEMP_THRESHOLD;

    tap1Open = preProcessTapOpen(tap1Open);
    tap2Open = preProcessTapOpen(tap2Open);
    tap3Open = preProcessTapOpen(tap3Open);

   
    [tap1RateTonPerHr, tap1NTappings] = calcMatteTapRate(tap1Open, ladleWeightTon, minimumTapDurationMins);
    [tap2RateTonPerHr, tap2NTappings] = calcMatteTapRate(tap2Open, ladleWeightTon, minimumTapDurationMins);
    [tap3RateTonPerHr, tap3NTappings] = calcMatteTapRate(tap3Open, ladleWeightTon, minimumTapDurationMins);

    matteTapRatesTonPerHr = tap1RateTonPerHr + tap2RateTonPerHr + tap3RateTonPerHr;
    nTappings = tap1NTappings + tap2NTappings + tap3NTappings;
end

function tapOpen = preProcessTapOpen(tapOpen)
% flip a bit if it is different from both its neighbours
    for idx = 2 : length(tapOpen) - 1
        if tapOpen(idx) ~= tapOpen(idx - 1) && tapOpen(idx) ~= tapOpen(idx + 1)
            tapOpen(idx) = ~tapOpen(idx);
        end
    end

    % eliminate 2-bit gaps i.e. 110011 -> 111111 
    % note: sporadic 1s are ignored because of the specified minimum tap
    % duration in calcMatteTapRate. But sporadic 0s are an issue and must
    % be dealt with here
    for idx = 2 : length(tapOpen) - 2
        if tapOpen(idx) == 0 && tapOpen(idx-1) == 1 && tapOpen(idx+2) == 1
            tapOpen(idx) = 1;
        end
    end
end

function [matteTapRateTonPerHr, nTappings] = calcMatteTapRate(tapOpen, ladleWeightTon, minTapDurationSamples)
    % calculates tap rate for a single matte tap hole
    
    matteTapRateTonPerHr = zeros(size(tapOpen));
    nTappings = 0;    

    idx = 1;
    while idx <= length(tapOpen) -  minTapDurationSamples

        
        % if tap is closed, or is open for less than
        % MINIMUM_TAP_DURATION_SAMPLES, tap rate = 0 (not tapping)
        if ~tapOpen(idx) || sum(tapOpen(idx:idx + minTapDurationSamples - 1)) ~= minTapDurationSamples
            matteTapRateTonPerHr(idx) = 0;
            idx = idx + 1;
            continue;
        end

        nTappings = nTappings + 1;
        % calculate tapping duration
        tapDurationSamples = minTapDurationSamples;
        for idx2 = idx + minTapDurationSamples : length(tapOpen)
            if tapOpen(idx2)
                tapDurationSamples = tapDurationSamples + 1;
            else
                break;
            end
        end
        tapRateTonPerHr = (ladleWeightTon/tapDurationSamples) * 60;
        matteTapRateTonPerHr(idx:idx + tapDurationSamples - 1) = tapRateTonPerHr;
        idx = idx + tapDurationSamples;
    end
end
