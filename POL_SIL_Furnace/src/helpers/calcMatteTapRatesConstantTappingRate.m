function matteTappingRatesTonPerHr = calcMatteTapRatesConstantTappingRate(dataTT, tappingRateTonPerHr)
    TAP_OPEN_TEMP_THRESHOLD = 1200;
    tapEastOpen = dataTT.MatteTap1ThermalCameraTemp > TAP_OPEN_TEMP_THRESHOLD;
    tapCenterOpen = dataTT.MatteTap2ThermalCameraTemp > TAP_OPEN_TEMP_THRESHOLD;
    tapWestOpen = dataTT.MatteTap3ThermalCameraTemp > TAP_OPEN_TEMP_THRESHOLD;
    % note: at most 1 matte taphole should be open at a time
    tapholeOpen = tapEastOpen | tapCenterOpen | tapWestOpen;
    matteTappingRatesTonPerHr = tapholeOpen * tappingRateTonPerHr; 
end