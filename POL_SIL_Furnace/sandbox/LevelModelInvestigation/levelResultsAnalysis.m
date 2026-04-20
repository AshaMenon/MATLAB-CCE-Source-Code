startTime = datetime('01-Aug-2024 15:34:00');
endTime = datetime('8-Aug-2024 18:00:00');
%%
[simOut, simInTT] = runMassBalanceTest(startTime=startTime, endTime=endTime, showPlots=true);
%% Constants for result analysis
parameters.offgas_fraction = 0.0015;
%%
figure
tiledlayout(6, 1)
ax1 = nexttile;
plot(simInTT.Timestamp, slInputs.mdot_feed_ton_per_hr.Var1 .* (1 - parameters.offgas_fraction - slInputs.matte_fall_fraction.Var1));
title("Slag in from feed (ton/hr)")
ax2 = nexttile;
plot(simInTT.Timestamp, slInputs.mdot_slag_tap_ton_per_hr.Var1)
title("Slag taphole flow (ton/hr)")
ax3 = nexttile;
plot(simInTT.Timestamp, simInTT.SlagTap1ThermalCameraTemp)
title("Slag tap 1 thermal camera temp")
ax4 = nexttile;
plot(simInTT.Timestamp, simInTT.SlagTap2ThermalCameraTemp)
title("Slag tap 2 thermal camera temp")
ax5 = nexttile;
plot(simInTT.Timestamp, simInTT.SlagTap3ThermalCameraTemp)
title("Slag tap 3 thermal camera temp")
ax6 = nexttile;
plot(simInTT.Timestamp, simInTT.SlagConveyorMass * 0.8);
title("Slag conveyor mass (ton/hr) (assuming 20% moisture)")
linkaxes([ax1 ax2 ax3 ax4 ax5 ax6], 'x');
%%
% find rate of decrease of slag
slagGradModelTonPerH = mean(diff(simOut.m_slag.Data(12*60:end))) * 60;

allDivertersOn = all([simInTT.DiverterIsToConveyorEast == "On", simInTT.DiverterIsToConveyorCenter == "On", simInTT.DiverterIsToConveyorWest == "On"], 2);

slagConveyorMean = mean(simInTT.SlagConveyorMass(allDivertersOn));
slagConveyorMean20Moisture = 0.8 * slagConveyorMean;

slagInFeedMean = mean(slInputs.mdot_feed_ton_per_hr.Var1 .* (1 - parameters.offgas_fraction - slInputs.matte_fall_fraction.Var1));
moistureEstimate = 1 - slagInFeedMean/slagConveyorMean;
%%
steamEvapPercentage = 0.09;
cpWater = 4.184; %MJ/ton
hEvapWater =2260; %MJ/ton
cpDeltaTSlag = 2379;	%MJ/ton slag
% Water flows and temperature differences
waterFlows = [simInTT.Flow_412_FT_201, simInTT.Flow_412_FT_301,...
    simInTT.Flow_412_FT_401]; % ton/hr % East, Center, West

tempDif = [simInTT.Temp_412_TT_007 - simInTT.Temp_412_TT_002, ...
    simInTT.Temp_412_TT_008 - simInTT.Temp_412_TT_002, ...
    simInTT.Temp_412_TT_009 - simInTT.Temp_412_TT_002];


% Convert diverter 'on'/'off' values to logical (0 for 'off', 1 for 'on') in one step
diverters = strcmp([simInTT.DiverterIsToConveyorEast, ...
                    simInTT.DiverterIsToConveyorCenter, ...
                    simInTT.DiverterIsToConveyorWest], 'On');

% Initialize the tap rates for each direction
tapRates = zeros(size(diverters, 1), 3);

% Iterate over each region (East, Center, West). The 
% waterFlows(i) * cpWater * tempDif(i) term is the energy transfered to
% the liquid water. The waterFlows(i) * (steamEvapFraction / 100) * hEvapWater)
% component is the energy transfered from the slag in order to generate
% steam from the cooling water. 
for i = 1 : 3
    
    % Find rows where the diverter is off (i.e., false)
    % divertersOff = ~diverters(:, i);
    % Perform the energy balance only for those rows
    tapRates(:, i) = (waterFlows(:, i) * cpWater .*...
        tempDif(:, i) + waterFlows(:, i) *...
        (steamEvapPercentage / 100) * hEvapWater) / cpDeltaTSlag;
end
%%
TAPPING_THRESHOLD = 1200; % deg C
allSlagTapholesClosed = simInTT.SlagTap1ThermalCameraTemp < TAPPING_THRESHOLD & ... 
    simInTT.SlagTap2ThermalCameraTemp < TAPPING_THRESHOLD & simInTT.SlagTap3ThermalCameraTemp < TAPPING_THRESHOLD;
slagTapEnergyRaw = sum(tapRates,2);
slagTappingFromEnergyBalanceZeroedWhenTapholesClosed = slagTapEnergyRaw;
slagTappingFromEnergyBalanceZeroedWhenTapholesClosed(allSlagTapholesClosed) = 0;
meanSlagTapEnergyBal = mean(slagTappingFromEnergyBalanceZeroedWhenTapholesClosed);

meanSlagTapEnergyBalDiverterOff = mean(slagTappingFromEnergyBalanceZeroedWhenTapholesClosed(~allDivertersOn));
ratioInOutEB = slagInFeedMean/meanSlagTapEnergyBal;
%% Plot slag results along with tapping inputs
figure
tiledlayout(1, 2)

% slag results
ax1 = nexttile;
plot(simInTT.Timestamp, simInTT.SlagThickness)
hold on
plot(simInTT.Timestamp(1:length(simOut.tout)), simOut.height_slag.Data * 100)
hold off
title("Slag height (cm)")
legend(["Measured", "Model"])

ax2 = nexttile;
plot(simInTT.Timestamp, slagTappingFromEnergyBalanceZeroedWhenTapholesClosed)
hold on
slagEnergyDivertersOff = slagTappingFromEnergyBalanceZeroedWhenTapholesClosed;
slagEnergyDivertersOff(allDivertersOn) = nan;
plot(simInTT.Timestamp, slagEnergyDivertersOff)
title("Slag tapped from energy balance")
legend(["Diverters on", "Diverters off"])
linkaxes([ax1 ax2], 'x')
%% Plot differences in slag level (soundings and model) with tapping inputs

tolCm = 0.1;
[slagSoundingsCm, slagSoundingTimestamps, slagSoundingsIndices] = extractChanges(simInTT.SlagThickness, simInTT.Timestamp, tolCm);
% incorporate first value
slagSoundingsCm = [simInTT.SlagThickness(1); slagSoundingsCm];
slagSoundingDiffsCm = diff(slagSoundingsCm);
slagModelAtSoundingsCm = [simOut.height_slag.Data(1); simOut.height_slag.Data(slagSoundingsIndices)]  * 100;
slagModelAtSoundingsDiffCm = diff(slagModelAtSoundingsCm);

figure
tiledlayout(2, 2)

% slag results
ax1 = nexttile;
plot(simInTT.Timestamp, simInTT.SlagThickness)
hold on
plot(simInTT.Timestamp(1:length(simOut.tout)), simOut.height_slag.Data * 100)
hold off
title("Slag height (cm)")
legend(["Measured", "Model"])

% slag differences
ax2 = nexttile;
plot(slagSoundingTimestamps, slagSoundingDiffsCm, 'o')
hold on
plot(slagSoundingTimestamps,  slagModelAtSoundingsDiffCm, 'o')
hold off
title("Change in slag height (cm)")
legend(["Measured", "Model"])

ax3 = nexttile;
hold on
nPatches = shadePatch(simInTT.Timestamp, simInTT.SlagTap1ThermalCameraTemp < TAPPING_THRESHOLD & simInTT.SlagTap2ThermalCameraTemp < TAPPING_THRESHOLD & simInTT.SlagTap3ThermalCameraTemp < TAPPING_THRESHOLD, ...
    250, [0.9 0.9 0.9]);
slagTappingDivertersOn = slInputs.mdot_slag_tap_ton_per_hr.mdot_slag_tap_ton_per_hr;
slagTappingDivertersOn(~allDivertersOn) = nan;
slagTappingDivertersOff = slInputs.mdot_slag_tap_ton_per_hr.mdot_slag_tap_ton_per_hr;
slagTappingDivertersOff(allDivertersOn) = nan;
plot(simInTT.Timestamp, slagTappingDivertersOn);

plot(simInTT.Timestamp, slagTappingDivertersOff)
hold off
title("Slag tapped values used by model (ton/hr)")
legend([repmat("", 1, nPatches - 1),  "All taps closed", "Diverters on (using conveyor)", "Diverters off (using energy balance)"]);

% power
ax4 = nexttile;
plot(simInTT.Timestamp, simInTT.PowerMw)
title("Power (MW)")

linkaxes([ax1 ax2 ax3 ax4], 'x')
%%
figure
nPatches = shadePatch(simInTT.Timestamp, simInTT.SlagTap1ThermalCameraTemp < TAPPING_THRESHOLD & simInTT.SlagTap2ThermalCameraTemp < TAPPING_THRESHOLD & simInTT.SlagTap3ThermalCameraTemp < TAPPING_THRESHOLD, ...
    250, [0.9 0.9 0.9]);
hold on
nPatchesDiverters = shadePatch(simInTT.Timestamp, ~allDivertersOn, 200, [0.8 0.8 1]);
plot(simInTT.Timestamp, slInputs.mdot_feed_ton_per_hr.mdot_feed_ton_per_hr .* (1 - parameters.offgas_fraction - slInputs.matte_fall_fraction.matte_fall_fraction));
plot(simInTT.Timestamp, simInTT.SlagConveyorMass * 0.8)
plot(simInTT.Timestamp, slagTappingFromEnergyBalanceZeroedWhenTapholesClosed)
TAPPING_THRESHOLD = 1400; 
hold off
legend([repmat("", 1, nPatches), repmat("", 1, nPatchesDiverters), "Slag in from feed (ton/hr)", "Slag conveyor mass (assuming 20% moisture) (ton/hr)", "Slag tapped from energy balance (ton/hr)"]);
title("Slag in vs slag out (energy balance zeroed when tapholes closed)")

linkaxes([ax1 ax2], 'x')
%%
figure
hold on
nPatches = shadePatch(simInTT.Timestamp, simInTT.SlagTap1ThermalCameraTemp < TAPPING_THRESHOLD & simInTT.SlagTap2ThermalCameraTemp < TAPPING_THRESHOLD & simInTT.SlagTap3ThermalCameraTemp < TAPPING_THRESHOLD, ...
    250, [0.9 0.9 0.9]);
nPatchesDiverters = shadePatch(simInTT.Timestamp, ~allDivertersOn, 200, [0.8 0.8 1]);
% plot(inputs.Timestamp, slInputs.mdot_feed_ton_per_hr.mdot_feed_ton_per_hr .* (1 - parameters.offgas_fraction - slInputs.matte_fall_fraction.matte_fall_fraction));
plot(simInTT.Timestamp, simInTT.SlagConveyorMass * 0.8)
plot(simInTT.Timestamp, slagTapEnergyRaw)
TAPPING_THRESHOLD = 1200; 
hold off
legend([repmat("", 1, nPatches), repmat("", 1, nPatchesDiverters), "Slag conveyor mass (assuming 20% moisture) (ton/hr)", "Slag tapped from energy balance (ton/hr)"]);
title("Slag out: conveyor vs energy balance")
%%
slagInFeedMean = mean(slInputs.mdot_feed_ton_per_hr.mdot_feed_ton_per_hr .* (1 - parameters.offgas_fraction - slInputs.matte_fall_fraction.matte_fall_fraction));
slagInFeedSum = sum(slInputs.mdot_feed_ton_per_hr.mdot_feed_ton_per_hr .* (1 - parameters.offgas_fraction - slInputs.matte_fall_fraction.matte_fall_fraction));

slagTapMean = mean(slInputs.mdot_slag_tap_ton_per_hr.mdot_slag_tap_ton_per_hr);
slagTapSum = sum(slInputs.mdot_slag_tap_ton_per_hr.mdot_slag_tap_ton_per_hr);
%% Plot differences in total material level 

tolCm = 0.1;
[totalMassSoundingDiscreteTon, totalMassSoundingTimestamps, totalMassSoundingsIndices] = extractChanges(totalMassSoundingsTon, simInTT.Timestamp, tolCm);
% incorporate first value
totalMassSoundingDiscreteTon = [totalMassSoundingsTon(1); totalMassSoundingDiscreteTon];
totalMassSoundingDiffsTon = diff(totalMassSoundingDiscreteTon);
totalMassModelAtSoundingsTon = [totalMassModelTon(1); totalMassModelTon(totalMassSoundingsIndices)];
totalMassModelAtSoundingsDiffTon = diff(totalMassModelAtSoundingsTon);

figure
tiledlayout(2, 2)

% total mass results
ax1 = nexttile;
plot(simInTT.Timestamp, totalMassSoundingsTon)
hold on
plot(simInTT.Timestamp(1:length(simOut.tout)), totalMassModelTon)
hold off
title("Total mass (ton)")
legend(["Measured", "Model"])

% total mass differences
ax2 = nexttile;
plot(totalMassSoundingTimestamps, totalMassSoundingDiffsTon, 'o')
hold on
plot(totalMassSoundingTimestamps,  totalMassModelAtSoundingsDiffTon, 'o')
hold off
title("Change in total mass (ton)")
legend(["Measured", "Model"])

ax3 = nexttile;
hold on
nPatches = shadePatch(simInTT.Timestamp, simInTT.SlagTap1ThermalCameraTemp < TAPPING_THRESHOLD & simInTT.SlagTap2ThermalCameraTemp < TAPPING_THRESHOLD & simInTT.SlagTap3ThermalCameraTemp < TAPPING_THRESHOLD, ...
    250, [0.9 0.9 0.9]);
slagTappingDivertersOn = slInputs.mdot_slag_tap_ton_per_hr.mdot_slag_tap_ton_per_hr;
slagTappingDivertersOn(~allDivertersOn) = nan;
slagTappingDivertersOff = slInputs.mdot_slag_tap_ton_per_hr.mdot_slag_tap_ton_per_hr;
slagTappingDivertersOff(allDivertersOn) = nan;
plot(simInTT.Timestamp, slagTappingDivertersOn);

plot(simInTT.Timestamp, slagTappingDivertersOff)
hold off
title("Slag tapped values used by model (ton/hr)")
legend([repmat("", 1, nPatches - 1),  "All taps closed", "Diverters on (using conveyor)", "Diverters off (using energy balance)"]);

linkaxes([ax1 ax2 ax3], 'x')
%% Moisture Parameter Fitting

% for 3 days of data it looks like the diverters are to conveyor whenever
%   tap holes are open
%   using week from 8 Aug 16:16, this is 4 days (i.e. 12 Aug 16:16)
%   around 4pm)
slagInTonPerHr = slInputs.mdot_feed_ton_per_hr.mdot_feed_ton_per_hr .* (1 - parameters.offgas_fraction - slInputs.matte_fall_fraction.matte_fall_fraction);
endIndex = 4 * 24 * 60; % 4 days
slagIn4DaysTonPerHr = slagInTonPerHr(1:endIndex);
slagConveyor4Days = simInTT.SlagConveyorMass(1:endIndex);
slagInOutRatioConveyor = sum(slagIn4DaysTonPerHr) ./ sum(slagConveyor4Days);
fittedMoisture = 1 - slagInOutRatioConveyor;
%% Slag conveyor vs energy balance
mean(simInTT.SlagConveyorMass(allDivertersOn) * 0.8)
%% Energy balance vs plant energy balance tags vs conveyor slag
figure
plot(simInTT.Timestamp, simInTT.SlagConveyorMass * 0.8)
hold on
plot(simInTT.Timestamp, slagTappingFromEnergyBalanceZeroedWhenTapholesClosed)
plot(simInTT.Timestamp, simInTT.SlagMassFromEnergyBalanceEast + simInTT.SlagMassFromEnergyBalanceCenter + simInTT.SlagMassFromEnergyBalanceWest)
hold off
title("Slag tapping comparison")
xlabel("Timestamp")
ylabel("Slag tap rate (ton/hr)")
legend(["Conveyor (20% moisture)", "Energy balance", "Original energy balance"])

%%
function nPatches = shadePatch(x, shade, patchHeight, rgb)
    % Shade the background grey where shade is true
    nPatches = 0;
    i = 1;
    while i < length(x)-1
        if shade(i)
            nPatches = nPatches + 1;
            % count length of consecutive shade values
            shadeXLength = 1;
            while i + shadeXLength < length(x) - 1 && shade(i + shadeXLength)
                shadeXLength = shadeXLength + 1;
            end
            % Define the x and y vertices for the shaded region
            xPatch = [x(i), x(i+shadeXLength), x(i+shadeXLength), x(i)];
            yPatch = patchHeight * [-1, -1, 1, 1];  % Full plot height (adjust if needed)
            
            % Create a grey patch
            patch(xPatch, yPatch, rgb, 'EdgeColor', 'none');
            i = i + shadeXLength;
        else
            i = i + 1;
        end
    end
end

