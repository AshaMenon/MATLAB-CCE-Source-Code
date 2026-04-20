function matteTapRatesTonPerHr = calcMatteTapRatesHybrid(dataTT, defaultLadleWeightTon, minimumTapDurationMins)
    %CALCMATTETAPRATESHYBRID calculates matte tapping rates using a combination of ladle
    % measurements and thermal camera data
    % Ladle weight measurements are used where available. 
    % For tapping events that
    % occur after the last recorded ladle weight measurement, a constant
    % ladle weight is assumed. Thermal camera data is used to detect and determine the duration of these tapping events. 
    
    matteTapRatesTonPerHr = calcMatteTapRatesFromLadleWeights(dataTT);

    lastTappingIndex = find(matteTapRatesTonPerHr > 0, 1, 'last');
    if isempty(lastTappingIndex)
        thermalCameraStartIndex = 1;
    else
        bufferMins = 5; % add a buffer to prevent matte that was part of the last recorded ladle from being double counted
        thermalCameraStartIndex = lastTappingIndex + bufferMins;
        if thermalCameraStartIndex > height(dataTT)
            return
        end
    end

    matteTapRatesTonPerHr(thermalCameraStartIndex:end) = calcMatteTapRatesFromThermalCamera(dataTT(thermalCameraStartIndex:end, :), defaultLadleWeightTon, minimumTapDurationMins);
end

