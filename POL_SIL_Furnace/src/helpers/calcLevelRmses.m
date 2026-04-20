function [matteRmseCm, slagRmseCm, concRmseCm, totalMassRmseTon] = calcLevelRmses(inputsTT, simOut)
    %CALCLEVELRMSES calculates the RMSEs of the level model outputs
    % compared to actual sounding data
    % Only predictions that correspond to the time at which a sounding was
    % taken are considered: the rest of the data are ignored

    [validMatteSoundingsCm, isValidationMatteSounding, validSlagSoundingsCm, isValidationSlagSounding, validConcSoundingsCm, isValidationConcSounding] = extractValidationSoundings(inputsTT);
    
    % total material mass (TODO: use data dictionary)
    MATTE_DENSITY_TON_PER_M3 = 4.5;
    SLAG_DENSITY_TON_PER_M3 = 2.8;
    CONC_DENSITY_TON_PER_M3 = 1.2;
    BATH_AREA_M2 = 31.75 * 9.49;

    isValidationCombinedSounding = isValidationMatteSounding & isValidationSlagSounding & isValidationConcSounding;
    validCombinedSoundingsInputs = inputsTT(isValidationCombinedSounding, :);
    validTotalMassSoundingsTon = BATH_AREA_M2 * (((validCombinedSoundingsInputs.MatteThickness + validCombinedSoundingsInputs.BuildUpThickness)/100) * MATTE_DENSITY_TON_PER_M3 + ...
    (validCombinedSoundingsInputs.SlagThickness / 100) * SLAG_DENSITY_TON_PER_M3 + (validCombinedSoundingsInputs.ConcThickness / 100) * CONC_DENSITY_TON_PER_M3);
    validTotalMassSoundingsTon(isnan(validTotalMassSoundingsTon)) = validTotalMassSoundingsTon(find(isnan(validTotalMassSoundingsTon)) - 1);
    totalMassModelTon = BATH_AREA_M2 * (simOut.height_matte.Data(isValidationCombinedSounding) * MATTE_DENSITY_TON_PER_M3 + ... 
    simOut.height_slag.Data(isValidationCombinedSounding) * SLAG_DENSITY_TON_PER_M3 + simOut.height_concentrate.Data(isValidationCombinedSounding) * CONC_DENSITY_TON_PER_M3);

    
    matteRmseCm = rmse(simOut.height_matte.Data(isValidationMatteSounding) * 100, validMatteSoundingsCm);
    slagRmseCm = rmse(simOut.height_slag.Data(isValidationSlagSounding) * 100, validSlagSoundingsCm);
    concRmseCm = rmse(simOut.height_concentrate.Data(isValidationConcSounding) * 100, validConcSoundingsCm);
    totalMassRmseTon = rmse(totalMassModelTon, validTotalMassSoundingsTon);
end

