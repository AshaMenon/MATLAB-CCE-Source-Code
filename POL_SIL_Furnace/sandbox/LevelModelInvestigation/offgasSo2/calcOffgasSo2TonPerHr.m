function offgasSo2TonPerHr = calcOffgasSo2TonPerHr(offgasSO2Percent, offgasFlowRateNormalM3PerHr)
    %CALCOFFGASSO2TONPERHR Summary of this function goes here
    %   Detailed explanation goes here
    % Calculate total offgas SO2
    NORMAL_MOLAR_CONCENTRATION_MOL_PER_M3 = 44.6; % TODO: add to data dict (maybe find better name)
    % molar masses
    M_O = 15.999;
    M_S = 32.066;
    M_SO2 = M_S + M_O * 2; % g/mol
    offgasSo2MolPerHr = offgasSO2Percent .* offgasFlowRateNormalM3PerHr * NORMAL_MOLAR_CONCENTRATION_MOL_PER_M3;
    GRAMS_PER_TON = 1e6;
    offgasSo2TonPerHr = offgasSo2MolPerHr * M_SO2 / GRAMS_PER_TON;
end

