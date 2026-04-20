function [slInputs, slParameters, simStartDateTime] = prepareDataForSim(inputsTT, parameters)
%PREPAREDATAFORSIM will validate and preprocess data and calculate derived
%inputs and parameters required to run the simulation

%Set start time of dataset
lastSimValDateTime = inputsTT.Timestamp(end) - (minutes(parameters.ExecutionFrequencyParam));

% Use model values
parameters.SimulatedMatteLevelLastValue = inputsTT.SimulatedMatteLevel_In(inputsTT.Timestamp == lastSimValDateTime);
parameters.SimulatedSlagLevelLastValue =  inputsTT.SimulatedSlagLevel_In(inputsTT.Timestamp == lastSimValDateTime);
parameters.SimulatedConcentrateLevelLastValue = inputsTT.SimulatedConcentrateLevel_In(inputsTT.Timestamp == lastSimValDateTime);

if isempty(parameters.SimulatedMatteLevelLastValue)
    parameters.SimulatedMatteLevelLastValue = nan;
end

if isempty(parameters.SimulatedSlagLevelLastValue)
    parameters.SimulatedSlagLevelLastValue = nan;
end

if isempty(parameters.SimulatedConcentrateLevelLastValue)
    parameters.SimulatedConcentrateLevelLastValue = nan;
end

% correct negative power readings to be zero
inputsTT.PowerMw(inputsTT.PowerMw < 0) = 0;

availableSimValues = ~isnan(parameters.SimulatedMatteLevelLastValue) &&...
~isnan(parameters.SimulatedSlagLevelLastValue) && ...
~isnan(parameters.SimulatedConcentrateLevelLastValue);

if availableSimValues
    isBetweenResetTimes = (hour(inputsTT.Timestamp) >= 6 & hour(inputsTT.Timestamp) < 8) | (hour(inputsTT.Timestamp) >= 18 & hour(inputsTT.Timestamp) < 20);
else
    isBetweenResetTimes = (hour(inputsTT.Timestamp) <= 24); % Any reset hour will suffice if there isn't availableSimValues
end

resetConditionsIdx = find(inputsTT.CombinedValidDeltaSounding == 1 & isBetweenResetTimes, 1, 'last');
availableResetValues = ~isempty(resetConditionsIdx);

if availableSimValues && availableResetValues % There are both sim initial conditions as well as reset conditions
    if lastSimValDateTime < inputsTT.Timestamp(resetConditionsIdx(1))
        simStartDateTime = lastSimValDateTime;
    else
        simStartDateTime = inputsTT.Timestamp(resetConditionsIdx(1));
    end
    Timestamp = inputsTT.Timestamp(resetConditionsIdx) - simStartDateTime;
    heightInitialMatte = timetable(Timestamp, inputsTT.NewMeanMattePlusBuildupThickness(resetConditionsIdx)./100);
    heightInitialSlag = timetable(Timestamp, inputsTT.NewMeanSlagThickness(resetConditionsIdx)./100);
    heightInitialBlackTop = timetable(Timestamp, inputsTT.NewMeanConcThickness(resetConditionsIdx)./100);
    if simStartDateTime < inputsTT.Timestamp(resetConditionsIdx(1)) % If the reset is after the sim initial conditions, add the sim initial conditions
        heightInitialMatte(duration(0, 0, 0), :) = {parameters.SimulatedMatteLevelLastValue};
        heightInitialMatte = sortrows(heightInitialMatte, 'Timestamp');
        heightInitialSlag(duration(0, 0, 0), :) = {parameters.SimulatedSlagLevelLastValue};
        heightInitialSlag = sortrows(heightInitialSlag, 'Timestamp');
        heightInitialBlackTop(duration(0, 0, 0), :) = {parameters.SimulatedConcentrateLevelLastValue};
        heightInitialBlackTop = sortrows(heightInitialBlackTop, 'Timestamp');
    end
elseif availableSimValues && ~availableResetValues % There are only sim initial conditions
    simStartDateTime = lastSimValDateTime;
    Timestamp = simStartDateTime - simStartDateTime;
    heightInitialMatte = timetable(Timestamp, parameters.SimulatedMatteLevelLastValue);
    heightInitialSlag = timetable(Timestamp, parameters.SimulatedSlagLevelLastValue);
    heightInitialBlackTop = timetable(Timestamp, parameters.SimulatedConcentrateLevelLastValue);
elseif ~availableSimValues && availableResetValues % There are only reset conditions
    simStartDateTime = inputsTT.Timestamp(resetConditionsIdx(1));
    Timestamp = inputsTT.Timestamp(resetConditionsIdx) - simStartDateTime;
    heightInitialMatte = timetable(Timestamp, inputsTT.NewMeanMattePlusBuildupThickness(resetConditionsIdx)./100);
    heightInitialSlag = timetable(Timestamp, inputsTT.NewMeanSlagThickness(resetConditionsIdx)./100);
    heightInitialBlackTop = timetable(Timestamp, inputsTT.NewMeanConcThickness(resetConditionsIdx)./100);
else % There are no initial conditions
    error("Unable to find CombinedValidDeltaSounding or previous model state.")
end

simPeriod = simStartDateTime <= inputsTT.Timestamp;

slParameters = struct();

% Convert table variables to input struct
simTime = inputsTT.Timestamp(simPeriod) - inputsTT.Timestamp(find(simPeriod, 1));

slInputs = struct( ...
    height_matte_resets = retime(heightInitialMatte, simTime, 'previous'),...
    height_slag_resets = retime(heightInitialSlag, simTime, 'previous'),...
    height_concentrate_resets = retime(heightInitialBlackTop, simTime, 'previous'),...
    power_MW = fillmissing(timetable(simTime, inputsTT.PowerMw(simPeriod)), 'previous', 'MaxGap', minutes(5)), ...
    SER_kWh_per_ton = fillmissing(timetable(simTime, inputsTT.SEC12HrKwhPerTon(simPeriod)), 'previous', 'MaxGap', minutes(5)),...
    matte_fall_fraction = timetable(simTime, inputsTT.MatteFallFraction(simPeriod)), ...
    mdot_matte_tap_ton_per_hr = timetable(simTime, inputsTT.MatteTapRatesTonPerHr(simPeriod)), ...
    mdot_slag_tap_ton_per_hr = timetable(simTime, inputsTT.SlagTapRates(simPeriod)), ...
    mdot_feed_ton_per_hr = timetable(simTime, inputsTT.FeedTonPerHr(simPeriod))...
    );

slFields = fieldnames(slInputs);
for iField = 1:numel(slFields)
    if any(isnan(slInputs.(slFields{iField}){:, "Var1"}))
        error('NaN found in model inputs: %s', slFields{iField})
    end
end