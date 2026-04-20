function [slagTapRate, calibrationFactor] = calcSlagTapRates(dataTT, parameters, log)

arguments
    dataTT
    parameters
    log
end

rawConveyorMass = dataTT.SlagConveyorMass;

try
    % Convert diverter 'on'/'off' values to logical (0 for 'off', 1 for 'on').
    diverters = strcmp([dataTT.DiverterIsToConveyorEast, ...
        dataTT.DiverterIsToConveyorCenter, ...
        dataTT.DiverterIsToConveyorWest], 'On');

    allDivertersOff = sum(diverters, 2) == 0;

    conveyorOffset = calculateConveyorOffset(rawConveyorMass, allDivertersOff);

    conveyorSlagMass = rawConveyorMass - conveyorOffset;

    % Find cooling water flows, ton/hr, East, Center, West
    waterFlows = [dataTT.Flow_412_FT_201, dataTT.Flow_412_FT_301,...
        dataTT.Flow_412_FT_401];

    % Find temperature differences of the cooling water , ton/hr, East, Center, West
    tempDif = [dataTT.Temp_412_TT_007 - dataTT.Temp_412_TT_002, ...
        dataTT.Temp_412_TT_008 - dataTT.Temp_412_TT_002, ...
        dataTT.Temp_412_TT_009 - dataTT.Temp_412_TT_002];

    % Initialize the tap rates from the energy balance for each taphole
    energyBalanceSlagMass = zeros(size(diverters, 1), 3);

    % Iterate over each region (East, Center, West). The
    % waterFlows(i) * cpWater * tempDif(i) term is the energy transfered to
    % the liquid water. The waterFlows(i) * (steamEvapFraction / 100) * hEvapWater)
    % component is the energy transfered from the slag in order to generate
    % steam from the cooling water.

    % find rows where at least 1 diverter is off
    someDiverterOff = sum(diverters, 2) < 3;

    for i = 1 : 3

        % Perform the energy balance only for those rows
        energyBalanceSlagMass(someDiverterOff, i) = (waterFlows(someDiverterOff, i) * parameters.water_specific_heat_capacity/1000 .*...
            tempDif(someDiverterOff, i) + waterFlows(someDiverterOff, i) *...
            (parameters.steam_evap_fraction / 100) * parameters.h_evap_water) / parameters.cp_delta_T;
    end

    energyBalanceSlagMassTotal = sum(energyBalanceSlagMass, 2);


    % When the diverter is off, set the slag mass on the conveyor to 0

    % when all slag tapholes are closed, set the slag tap rate to zero
    %   solves issue where energy balance often gives fairly high tapping rates
    %   when taphole is closed.

    tappingThreshold = parameters.ThermalTappingThreshold;
    allSlagTapholesClosed = ...
        dataTT.SlagTap1ThermalCameraTemp < tappingThreshold & ...
        dataTT.SlagTap2ThermalCameraTemp < tappingThreshold & ...
        dataTT.SlagTap3ThermalCameraTemp < tappingThreshold;

    energyBalanceSlagMassTotal(allSlagTapholesClosed) = 0;
    negativeSlagIndex = energyBalanceSlagMassTotal < 0;
    energyBalanceSlagMassTotal(negativeSlagIndex) = 0;

    % Calculate the total slag tap rate
    % -> use conveyor slag when all diverters on
    % -> use energy balance when at least 1 diverter is off
    slagTapRate = conveyorSlagMass;
    slagTapRate(someDiverterOff) = 0;

    slagTapRate = slagTapRate + energyBalanceSlagMassTotal;

    % Calculate the moisture content in the slag on the conveyor.
    calibrationFactor = calculateMoistureContent(dataTT, parameters, slagTapRate);

    % Adjust tapped slag for moisture
    slagTapRate = slagTapRate .* (1 - calibrationFactor);

catch err
    msg = [err.stack(1).name, ' Line ',...
        num2str(err.stack(1).line), '. ', err.message];
    log.logError(msg);
    slagTapRate = rawConveyorMass;
    calibrationFactor = zeros(size(slagTapRate, 1), 1);
end

end

function conveyorOffset = calculateConveyorOffset(conveyorMass, divertersOff)

% Initialise the offset variable.
conveyorOffset = zeros(size(conveyorMass, 1), 1);
offset = 0;
for i = 1 : size(conveyorMass, 1)

    % Identify groups of consecutive indices where the diverters were off.
    if ~ divertersOff(i)
        recentGroupStart = find(diff([0; divertersOff(1:i)]) == 1, 1, "last");
        recentGroupEnd = find(diff([divertersOff(1:i);0]) == -1, 1, "last");

        % Find the duration of the period where the diverters were off. Any duration
        % shorter than a threshold will not be used in the median calculation because
        % a reliable estimate of the offset can not be obtained. In that case, the
        % previous reliable offset is used.

        offPeriodDuration = recentGroupEnd - recentGroupStart;

        if offPeriodDuration > 3
            offset = median(conveyorMass(recentGroupStart:recentGroupEnd));
            conveyorOffset(i) = offset;
        else
            % Set the offset to the previous reliable offset. This offset
            % is still stored in the offset variable.
            conveyorOffset(i) = offset;
        end
    end
end
end

function moistureContent = calculateMoistureContent(inputsTT, parameters, slagTapRate)

% Calculate the calibration period in minutes
calibrationPeriod = round(parameters.MoistureCalibrationPeriod * 24 * 60);

% Initialize the start and index to start from the beginning of the input data.
startIdx = 1;
periodEndIdx = 0;
endIdx = size(inputsTT, 1);  % Length of the data table

% Initialize array to store moisture content for each calibration period.
moistureContent = zeros(endIdx, 1);

while startIdx <= endIdx && periodEndIdx ~= endIdx

    % Find the index range for the current calibration period
    periodEndIdx = startIdx + calibrationPeriod - 1;


    % If the final period of data is smaller than 1 day, it will be joined with
    % the previous calibration period. This will result in a calibration period of slightly longer
    % than the previous periods.

    if endIdx - periodEndIdx < 1 * 24 * 60
        periodEndIdx = endIdx;
    end
    %periodHolder(end+1, 1) = periodEndIdx;
    % Adjust commonValidSoundings to match the overall table indexing.
    dataForPeriod = inputsTT.CombinedValidDeltaSounding(startIdx : periodEndIdx);

    % Set Nan values in the combined valid soundings to zero. This
    % indicates that it can not be used as a combined valid sounding.
    dataForPeriod(isnan(dataForPeriod)) = 0;

    commonValidSoundings = find(dataForPeriod) + startIdx - 1;

    % Find the last common sounding of the period.
    if ~isempty(commonValidSoundings)
        firstSoundingIndex = commonValidSoundings(1);
        lastSoundingIndex = commonValidSoundings(end);

        % Calculate the flow rates and accumulation for this period.

        feedInBetweenSoundings = sum(inputsTT.FeedTonPerHr(firstSoundingIndex : lastSoundingIndex)) / 60;
        offGasOutBetweenSoundings = feedInBetweenSoundings * parameters.offgas_fraction;
        slagOutBetweenSoundings = sum(slagTapRate(firstSoundingIndex:lastSoundingIndex)) / 60;
        matteOutBetweenSoundings = sum(inputsTT.MatteTapRatesTonPerHr(firstSoundingIndex:lastSoundingIndex)) / 60;

        slagHeightChange = (inputsTT.NewMeanSlagThickness(lastSoundingIndex) -...
            inputsTT.NewMeanSlagThickness(firstSoundingIndex)) / 100;
        slagAccumulated = slagHeightChange * parameters.bath_area * parameters.slag_density;

        matteHeightChange = (inputsTT.NewMeanMattePlusBuildupThickness(lastSoundingIndex) - ...
            inputsTT.NewMeanMattePlusBuildupThickness(firstSoundingIndex)) / 100;

        matteAccumulated = matteHeightChange * parameters.bath_area * parameters.matte_density;

        concHeightChange = (inputsTT.NewMeanConcThickness(lastSoundingIndex) - inputsTT.NewMeanConcThickness(firstSoundingIndex)) / 100;
        concAccumulated = concHeightChange * parameters.bath_area * parameters.concentrate_density;

        totalAccumulation = slagAccumulated + matteAccumulated + concAccumulated;

        theoreticalSlagOut = feedInBetweenSoundings - offGasOutBetweenSoundings -...
            matteOutBetweenSoundings - totalAccumulation;

        % Calculate moisture content for this period
        moistureContentBetweenSoundings = 1 - (theoreticalSlagOut / slagOutBetweenSoundings);

        % Warn if a negative calibration factor is calculated. This
        % indicates the calculated slag tap value is far too low instead of
        % high. 
         if moistureContentBetweenSoundings < 0
             log.logInfo('Negative calibration factor has been calculated.')
         end
        if isnan(moistureContentBetweenSoundings)
            moistureContentBetweenSoundings = 0; % No calibration will be performed. 
            log.logInfo('Calibration factor set to zero.')
        end

    else % No valid soundings for this period.
        log.logInfo('No valid soundings for this period and calibration factor set to zero.')
        moistureContentBetweenSoundings = 0;
    end

    % Store moisture content for this period
    moistureContent(startIdx : periodEndIdx) = moistureContentBetweenSoundings;

    % Move to the next calibration period.
    startIdx = startIdx + calibrationPeriod;
end
end
