%% Analysing Results

simulatedData.matteHeatIn = simulatedData.HeatConductedfromSlagtoMatte +...
    simulatedData.HeatMassFlowfromSlagtoMatte;
simulatedData.matteHeatOut = simulatedData.HeatMassFlowMatteTappedMatteBath +...
    simulatedData.HeatConductedfromMattetoWaffleCooler;
simulatedData.fullBathHeatOut = simulatedData.HeatMassFlowfromSlagtoInflow +...
    simulatedData.HeatMassFlowMatteTappedMatteBath +...
    simulatedData.HeatMassFlowSlagTapped +...
    simulatedData.HeatConductedfromFullBathtoWaffleCooler +...
    simulatedData.HeatRadiatedfromSlagtoFurnace +...
    simulatedData.HeatMassFlowfromOffgastoFurnace +...
    simulatedData.HeatMassFlowfromAccruedSlagandDusttoFurnace;

%%
figure
sgtitle('Simulated Data - New Parameter Set (12 July)')
hold on
ax1 = subplot(3,2,1);
title('Matte Temperature (Measured and Simulated)')
hold on
grid on
grid minor
plot(data.Al2O3FeedblendTimestamp, data.Mattetemperatures, '-',...
    'Color', [0, 0.4470, 0.7410])
plot(data.Al2O3FeedblendTimestamp, data.Slagtemperatures, '-',...
    'Color', [0.8500, 0.3250, 0.0980])
plot(simulatedData.Timestamp, simulatedData.SimulatedMatteTemperature, '--',...
    'Color', [0, 0.4470, 0.7410])
plot(simulatedData.Timestamp, simulatedData.SimulatedSlagTemperature, '--',...
    'Color', [0.8500, 0.3250, 0.0980])
plot(simulatedData.Timestamp, movmedian(simulatedData.SimulatedMatteTemperature, 75),...
    'Color', [0, 0.4470, 0.7410], 'LineWidth', 1.2)
plot(simulatedData.Timestamp, movmedian(simulatedData.SimulatedSlagTemperature, 75),...
    'Color', [0.8500, 0.3250, 0.0980], 'LineWidth', 1.2)
legend('Measured Matte Temp', 'Measured Slag Temp', ...
    'Simulated Matte Temp', 'Simulated Slag Temp')

ax2 = subplot(3,2,3);
title('Heights (Measured and Simulated) and Tapping')
hold on
grid on
grid minor
plot(data.Al2O3FeedblendTimestamp, (data.Lanceheight + 350)/1000)
plot(simulatedData.Timestamp, simulatedData.SimulatedTotalBathHeight)
plot(simulatedData.Timestamp, simulatedData.SimulatedMatteHeight)
plot(simulatedData.Timestamp, simulatedData.MatteTapping)
plot(simulatedData.Timestamp, simulatedData.SlagTapping)
legend('Measured Bath Height',...
    'Simulated Bath Height', 'Simulated Matte Height')

ax3 = subplot(3,2,5);
title('Full Bath Heats')
hold on
grid on
grid minor
plot(simulatedData.Timestamp, simulatedData.TotalHeatInBath)
plot(simulatedData.Timestamp, simulatedData.TotalHeatOutBath)
plot(simulatedData.Timestamp, simulatedData.TotalHeatInBath - simulatedData.TotalHeatOutBath)
yline(0, 'k')
legend('Heat In','Heat Out','Net Heat')

ax4 = subplot(3,2,4);
title('Matte Feed')
hold on
grid on
grid minor
plot(data.Al2O3FeedblendTimestamp, data.MattefeedPV)
plot(data.Al2O3FeedblendTimestamp, data.RoofmattefeedratePV)
legend('Matte Feed', 'Roof Matte Feed')

ax5 = subplot(3,2,2);
title('Tapping')
hold on
grid on
grid minor
plot(simulatedData.Timestamp, simulatedData.MatteTapping)
plot(simulatedData.Timestamp, simulatedData.SlagTapping)
ylim([-0.05, 1.05])
legend('Matte Tapping', 'Slag Tapping')

ax6 = subplot(3,2,6);
title('Fuel Coal Feed Rate')
hold on
grid on
grid minor
plot(data.Al2O3FeedblendTimestamp, data.FuelcoalfeedratePV)
legend('Fuel Coal Feed Rate')

linkaxes([ax1, ax2, ax3, ax4, ax5, ax6], 'x')

%% Heights and Tapping

figure
ax1 = subplot(3,1,1);
title('Heights (Measured and Simulated) and Tapping')
hold on
grid on
grid minor
plot(data.Al2O3FeedblendTimestamp, (data.Lanceheight + 350)/1000)
plot(simulatedData.Timestamp, simulatedData.SimulatedTotalBathHeight)
legend('Measured Bath Height', 'Simulated Bath Height')

ax2 = subplot(3,1,2);
title('Tapping Classifications')
hold on
grid on
grid minor
plot(simulatedData.Timestamp, simulatedData.SlagTappingTapBlock)
plot(simulatedData.Timestamp, simulatedData.ThermoSlagTapping)
plot(simulatedData.Timestamp, simulatedData.SlagTapping)
legend('Using Tap Block Temp','Using Thermo Model','Combination')

ax3 = subplot(3,1,3);
title('Slag Tap Hole Temperature')
hold on
grid on
grid minor
plot(data.Al2O3FeedblendTimestamp, data.PhaseBSlagtapblockDT_water)
yyaxis right
plot(data.Al2O3FeedblendTimestamp(2:end), diff(data.PhaseBSlagtapblockDT_water))
yline(0, 'Color', 'k')
linkaxes([ax1, ax2, ax3], 'x')

%% Scatter Plots
figure
title('Matte Temperatures')
hold on
scatter(data.Mattetemperatures, simulatedData.SimulatedMatteTemperature)
scatter(data.Mattetemperatures, movmedian(simulatedData.SimulatedMatteTemperature, 75))
plot([1195, 1300], [1195, 1300], 'k-', 'LineWidth', 2)
xlim([1200 1300])
ylim([1100 1400])
legend('Minutely','75 Moving Median','x = y')
xlabel('Measured')
ylabel('Simulated')

%% 
figure
title('Bath Height')
hold on
scatter(data.Lanceheight/1000 + 0.35, simulatedData.SimulatedTotalBathHeight)
plot([0.8, 4], [0.8, 4], 'k-', 'LineWidth', 2)
xlabel('Measured')
ylabel('Simulated')

%% Time Series Plots
% Height and Temp

figure
ax1 = subplot(3,1,1);
title('Temperatures - Time Series')
hold on
plot(data.Al2O3FeedblendTimestamp, data.Mattetemperatures, ...
    'Color', [0, 0.4470, 0.7410], 'LineStyle', '-')
plot(data.Al2O3FeedblendTimestamp, data.Slagtemperatures, ...
    'Color', [0.8500, 0.3250, 0.0980], 'LineStyle', '-')
plot(simulatedData.Timestamp, simulatedData.SimulatedMatteTemperature, ...
    'Color', [0, 0.4470, 0.7410], 'LineStyle', '--')
plot(simulatedData.Timestamp, simulatedData.SimulatedSlagTemperature, ...
    'Color', [0.8500, 0.3250, 0.0980], 'LineStyle', '--')
legend('Measured Tm', 'Measured Ts', 'Simulated Tm', 'Simulated Ts')
xlabel('Time')
ylabel('Temperature [C]')

ax2 = subplot(3,1,2);
title('Heights - Time Series')
hold on
plot(data.Al2O3FeedblendTimestamp, (data.Lanceheight+350)/1000, ...
    'Color', [0, 0.4470, 0.7410], 'LineStyle', '-')
plot(simulatedData.Timestamp, simulatedData.SimulatedTotalBathHeight, ...
    'Color', [0.8500, 0.3250, 0.0980], 'LineStyle', '-')
plot(simulatedData.Timestamp, simulatedData.SimulatedMatteHeight, ...
    'Color', [0.9290, 0.6940, 0.1250], 'LineStyle', '-')
plot(simulatedData.Timestamp, simulatedData.SimulatedSlagHeight, ...
    'Color', [0, 0.75, 0.75], 'LineStyle', '-')
legend('Approximate Measure Bath Height', 'Simulated Total Bath Height', ...
    'Simulated Matte Height', 'Simulated Slag Height')
xlabel('Time')
ylabel('Height [m]')

ax3 = subplot(3,1,3);
title('Matte Feed')
hold on
plot(data.Al2O3FeedblendTimestamp, data.MattefeedPV)
legend('Matte Feed PV')
linkaxes([ax1, ax2, ax3], 'x')

%% Histograms

trainEnd = 1650;
figure
title('Matte Temperatures - Error Distributions')
hold on
histogram(data.Mattetemperatures(1:trainEnd) - simulatedData.SimulatedMatteTemperature(1:trainEnd), 'FaceAlpha', 0.7)
histogram(data.Mattetemperatures(trainEnd+1:end) - simulatedData.SimulatedMatteTemperature(trainEnd+1:end), 'FaceAlpha', 0.7)
legend('Training Errors, Std = ' + string(std(data.Mattetemperatures(1:trainEnd) - simulatedData.SimulatedMatteTemperature(1:trainEnd))),...
    'Out-of-sample Errors, Std = ' +string(std(data.Mattetemperatures(trainEnd+1:end) - simulatedData.SimulatedMatteTemperature(trainEnd+1:end))))

%% Analyse Energy Balance Components

inModeIdx = data.Convertermode == 6 | data.Convertermode == 7 | data.Convertermode == 8; 
% Matte Bath
descriptivePlot(simulatedData.Timestamp(inModeIdx), simulatedData.HeatConductedfromSlagtoMatte(inModeIdx), ...
    '-', [0, 0.4470, 0.7410], 'Heat Conducted (Slag to Matte) [kW]')
descriptivePlot(simulatedData.Timestamp(inModeIdx), simulatedData.HeatMassFlowfromSlagtoMatte(inModeIdx), ...
    '-', [0.8500, 0.3250, 0.0980], 'Heat Mass flow (Slag to Matte) [kW]')
descriptivePlot(simulatedData.Timestamp(inModeIdx), simulatedData.HeatConductedfromMattetoWaffleCooler(inModeIdx), ...
    '-', [0, 0.75, 0.75], 'Heat Conducted (Matte to Waffle Cooler) [kW]')
descriptivePlot(simulatedData.Timestamp(inModeIdx), simulatedData.HeatMassFlowMatteTappedMatteBath(inModeIdx), ...
    '-', [0.75, 0, 0.75], 'Heat Mass Flow (Matte Tapped) [kW]')

% Full Bath

descriptivePlot(simulatedData.Timestamp(inModeIdx), simulatedData.HeatGeneratedSlag(inModeIdx),...
    '-', [0, 0.4470, 0.7410], 'Heat Generated (Slag) [kW]')
descriptivePlot(simulatedData.Timestamp(inModeIdx), simulatedData.HeatMassFlowfromSlagtoInflow(inModeIdx),...
    '-', [0.8500, 0.3250, 0.0980], 'Heat Mass Flow (Slag to Inflow) [kW]')
descriptivePlot(simulatedData.Timestamp(inModeIdx), simulatedData.HeatMassFlowMatteTappedMatteBath(inModeIdx),...
    '-', [0.9290, 0.6940, 0.1250], 'Heat Mass Flow (Matte Tapped) [kW]')
descriptivePlot(simulatedData.Timestamp(inModeIdx), simulatedData.HeatMassFlowSlagTapped(inModeIdx),...
    '-', [1, 0, 0], 'Heat Mass Flow (Slag Tapped) [kW]')
descriptivePlot(simulatedData.Timestamp(inModeIdx), simulatedData.HeatConductedfromFullBathtoWaffleCooler(inModeIdx),...
    '-', [0, 0.75, 0.75], 'Heat Conducted (Full Bath to Waffle Cooler) [kW]')
descriptivePlot(simulatedData.Timestamp(inModeIdx), simulatedData.HeatRadiatedfromSlagtoFurnace(inModeIdx),...
    '-', [0.75, 0, 0.75], 'Heat Radiated (Slag to Furnace) [kW]')
descriptivePlot(simulatedData.Timestamp(inModeIdx), simulatedData.HeatMassFlowfromOffgastoFurnace(inModeIdx),...
    '-', [0, 0.5, 0], 'Heat Mass Flow (Offgas to Furnace) [kW]')
descriptivePlot(simulatedData.Timestamp(inModeIdx), simulatedData.HeatMassFlowfromAccruedSlagandDusttoFurnace(inModeIdx),...
    '-', [0.6350, 0.0780, 0.1840], 'Heat Mass Flow (Accr Slag and Dust to Furnace) [kW]')

%% Plot Heat Balance Components on Same Axes

figure
sgtitle('Matte Bath Energy Components')
ax1 = subplot(3,1,1);
title('Heat Components In')
hold on
plot(simulatedData.Timestamp, simulatedData.HeatConductedfromSlagtoMatte, ...
    'Color', [0, 0.4470, 0.7410])
plot(simulatedData.Timestamp, simulatedData.HeatMassFlowfromSlagtoMatte, ...
    'Color', [0.8500, 0.3250, 0.0980])
plot(simulatedData.Timestamp, simulatedData.matteHeatIn, ...
    'Color', 'k', 'LineWidth', 1.2)
legend('Heat Conducted (Slag to Matte) [kW]','Heat Mass flow (Slag to Matte) [kW]', 'Total Heat In [kW]')

ax2 = subplot(3,1,2);
title('Heat Components Out')
hold on
plot(simulatedData.Timestamp, simulatedData.HeatMassFlowMatteTappedMatteBath, ...
    'Color', [0.75, 0, 0.75])
plot(simulatedData.Timestamp, simulatedData.HeatConductedfromMattetoWaffleCooler, ...
    'Color', [0, 0.75, 0.75])
plot(simulatedData.Timestamp, simulatedData.matteHeatOut, 'Color', 'k', 'LineWidth', 1.2)
legend('Heat Mass Flow (Matte Tapped) [kW]', 'Heat Conducted (Matte to Waffle Cooler) [kW]', 'Total Heat Out [kW]')

ax3 = subplot(3,1,3);
title('Net Heat and Matte Temperature')
hold on
plot(simulatedData.Timestamp, simulatedData.matteHeatIn - simulatedData.matteHeatOut)
yline(0, 'Color', 'k')
yyaxis right
plot(simulatedData.Timestamp, simulatedData.SimulatedMatteTemperature)
legend('Net Energy [kW]', '', 'Tm [C]')
linkaxes([ax1, ax2, ax3], 'x')

figure
sgtitle('Full Bath Energy Components')
ax1 = subplot(3,1,1);
title('Heat Components In')
hold on
plot(simulatedData.Timestamp, simulatedData.HeatGeneratedSlag, ...
    'Color', 'k', 'LineWidth', 1.2)
legend('Heat Generated in Slag (and Total Heat In) [kW]')

ax2 = subplot(3,1,2);
title('Heat Components Out')
hold on
plot(simulatedData.Timestamp, simulatedData.HeatMassFlowfromSlagtoInflow)
plot(simulatedData.Timestamp, simulatedData.HeatMassFlowMatteTappedMatteBath)
plot(simulatedData.Timestamp, simulatedData.HeatMassFlowSlagTapped)
plot(simulatedData.Timestamp, simulatedData.HeatConductedfromFullBathtoWaffleCooler)
plot(simulatedData.Timestamp, simulatedData.HeatRadiatedfromSlagtoFurnace)
plot(simulatedData.Timestamp, simulatedData.HeatMassFlowfromOffgastoFurnace)
plot(simulatedData.Timestamp, simulatedData.HeatMassFlowfromAccruedSlagandDusttoFurnace)
plot(simulatedData.Timestamp, simulatedData.fullBathHeatOut, ...
    'Color', 'k', 'LineWidth', 1.2)
legend('Heat Mass Flow (Slag to Inflow) [kW]', ...
    'Heat Mass Flow (Matte Tapped) [kW]', ...
    'Heat Mass Flow (Slag Tapped) [kW]', ...
    'Heat Conducted (Full Bath to Waffle Cooler) [kW]', ...
    'Heat Radiated (Slag to Furnace) [kW]', ...
    'Heat Mass Flow (Offgas to Furnace) [kW]', ...
    'Heat Mass Flow (Accrued Slag and Dust to Furnace) [kW]', ...
    'Total Heat Out [kW]')

ax3 = subplot(3,1,3);
title('Net Heat and Matte Temperature')
hold on
plot(simulatedData.Timestamp, simulatedData.HeatGeneratedSlag - simulatedData.fullBathHeatOut)
yline(0, 'Color', 'k')
yyaxis right
plot(simulatedData.Timestamp, simulatedData.SimulatedSlagTemperature)
legend('Net Energy [kW]', '', 'Ts [C]')
linkaxes([ax1, ax2, ax3], 'x')

%% Lance height and motion analysis

figure
ax1 = subplot(3,1,1);
plot(data.Al2O3FeedblendTimestamp, data.Lanceheight/1000)
ax2 = subplot(3,1,2);
plot(data.Al2O3FeedblendTimestamp, data.Lancemotion)
ax3 = subplot(3,1,3);
heightToMotionRatio = data.Lanceheight./data.Lancemotion/1000;
plot(data.Al2O3FeedblendTimestamp, heightToMotionRatio)
hold on
plot(data.Al2O3FeedblendTimestamp, movstd(heightToMotionRatio, 5))
linkaxes([ax1, ax2, ax3], 'x')

%% Performing Numerical Integration (per tapping cycle)

zeroHeightIndex = find(simulatedData.SimulatedMatteHeight == 1e-4);

startTapIdx = zeroHeightIndex(1);
endTapIdx = zeroHeightIndex(3)-1;

energyIn = [0; cumsum(simulatedData.matteHeatIn(startTapIdx+1:endTapIdx))*60]; %[kJ] = [kJ/s]*[s]
energyOut = [0; cumsum(simulatedData.matteHeatOut(startTapIdx+1:endTapIdx))*60]; %[kJ] = [kJ/s]*[s]

figure
ax1 = subplot(5,1,1);
plot(simulatedData.Timestamp(startTapIdx:endTapIdx), simulatedData.matteHeatIn(startTapIdx:endTapIdx))
hold on
plot(simulatedData.Timestamp(startTapIdx:endTapIdx), simulatedData.matteHeatOut(startTapIdx:endTapIdx))
legend('Total Heat In [kW]', 'Total Heat Out [kW]')
ax2 = subplot(5,1,2);
plot(simulatedData.Timestamp(startTapIdx:endTapIdx), energyIn)
hold on
plot(simulatedData.Timestamp(startTapIdx:endTapIdx), energyOut)
plot(simulatedData.Timestamp(startTapIdx:endTapIdx), energyIn - energyOut)
legend('Energy In [kJ]', 'Energy Out [kJ]', 'Net Energy [kJ]')
ax3 = subplot(5,1,3);
plot(simulatedData.Timestamp(startTapIdx:endTapIdx), simulatedData.SimulatedMatteTemperature(startTapIdx:endTapIdx))
hold on
plot(simulatedData.Timestamp(startTapIdx:endTapIdx), simulatedData.SimulatedSlagTemperature(startTapIdx:endTapIdx))
legend('Tm [C]', 'Ts [C]')
ax4 = subplot(5,1,4);
plot(simulatedData.Timestamp(startTapIdx:endTapIdx), (energyIn - energyOut)*1000/(rho_m*pi*R^2*Cp_matte)./(simulatedData.SimulatedMatteHeight(startTapIdx:endTapIdx)))
legend('Tm Numerical [K]')
ax5 = subplot(5,1,5);
plot(simulatedData.Timestamp(startTapIdx:endTapIdx), simulatedData.SimulatedMatteHeight(startTapIdx:endTapIdx))
legend('hm [m]')
linkaxes([ax1, ax2, ax3, ax4, ax5], 'x')

%% Plot Total Heat In and Out, along with Cross Term

figure
ax1 = subplot(2,1,1);
plot(simulatedData.simTime, simulatedData.matteHeatIn)
hold on
plot(simulatedData.simTime, simulatedData.matteHeatOut)
legend('Total Heat In [kW]', 'Total Heat Out [kW]')
ax2 = subplot(2,1,2);
plot(simulatedData.simTime, simulatedData.hmDeltaTm)
legend('Cross-term Value [hm(Tm - Tamb)]')
linkaxes([ax1, ax2], 'x')

%% Analyse Energy Balance Components - Full Bath

descriptivePlot(simulatedData.Timestamp, simulatedData.HeatGeneratedSlag, '-', [0.3010, 0.7450, 0.9330], 'QGen [kW]')
descriptivePlot(simulatedData.Timestamp, simulatedData.QBathInflow, '-', [0.4660, 0.6740, 0.1880], 'Qinflow [kW]')
descriptivePlot(simulatedData.Timestamp, simulatedData.QBathMOut, '-', [0.4940, 0.1840, 0.5560], 'QMout [kW]')
descriptivePlot(simulatedData.Timestamp, simulatedData.QBathSOut, '-', [0.8500, 0.3250, 0.0980], 'QSout [kW]')
descriptivePlot(simulatedData.Timestamp, simulatedData.QBathHX, '-', [0.9290, 0.6940, 0.1250], 'QHX [kW]')
descriptivePlot(simulatedData.Timestamp, simulatedData.QBathRad, '-', [0, 0.4470, 0.7410], 'QRad [kW]')
descriptivePlot(simulatedData.Timestamp, simulatedData.QBathOffgas, '-', [0.3010, 0.7450, 0.9330], 'Qoffgas [kW]')
descriptivePlot(simulatedData.Timestamp, simulatedData.QBathAccrSlagAndDust, '-', [0.4660, 0.6740, 0.1880], 'QdustAccrSlag [kW]')

%% Taking a closer look at QGen

figure
ax1 = subplot(2,1,1);
plot(simulatedData.simTime, simulatedData.QGenFeed)
hold on
plot(simulatedData.simTime, simulatedData.QGenFuelCoal)
ylabel('Heat [kW]')
legend('QGenFeed [kW]','QGenFuelCoal [kW]')
ax2 = subplot(2,1,2);
plot(simulatedData.simTime, simulatedData.simulatedSlagTemp)
ylabel('Temperature [C]')
legend('Ts [C]')
linkaxes([ax1, ax2], 'x')

descriptivePlot(simulatedData.simTime, simulatedData.QGenFeed, '-', [0.3010, 0.7450, 0.9330], 'QGenFeed [kW]')
descriptivePlot(simulatedData.simTime, simulatedData.QGenFuelCoal, '-', [0.3010, 0.7450, 0.9330], 'QGenFuelCoal [kW]')

%% Time Series Plots - Components of energy

figure
ax1 = subplot(4,1,1);
plot(simulatedData.simTime, simulatedData.HeatGeneratedSlag, 'Color', [0.3010, 0.7450, 0.9330])
ylabel('Heat [kW]')
legend('QGenTotal [kW]')
ax2 = subplot(4,1,2);
plot(simulatedData.simTime, simulatedData.QBathMOut, 'Color', [0.4940, 0.1840, 0.5560])
hold on
plot(simulatedData.simTime, simulatedData.QBathSOut, 'Color', [0.8500, 0.3250, 0.0980])
ylabel('Heat [kW]')
legend('QMatteOut [kW]', 'QSlagOut [kW]')
ax3 = subplot(4,1,3);
plot(simulatedData.simTime, simulatedData.QBathInflow, 'Color', [0.4660, 0.6740, 0.1880])
hold on
plot(simulatedData.simTime, simulatedData.QBathOffgas, 'Color', [0.3010, 0.7450, 0.9330])
plot(simulatedData.simTime, simulatedData.QBathRad, 'Color', [0, 0.4470, 0.7410])
ylabel('Heat [kW]')
legend('QInflow [kW]', 'QOffgas [kW]', 'QRadiation [kW]')
ax4 = subplot(4,1,4);
plot(simulatedData.simTime, simulatedData.QBathHX, 'Color', [0.9290, 0.6940, 0.1250])
hold on
plot(simulatedData.simTime, simulatedData.QBathAccrSlagAndDust, 'Color', [0.4660, 0.6740, 0.1880])
ylabel('Heat [kW]')
legend('QHX [kW]', 'QAccrSlagAndDust [kW]')
linkaxes([ax1, ax2, ax3, ax4], 'x')

%% Time Series Plots - Net energy and Temperature

figure
ax1 = subplot(3,1,1);
plot(simulatedData.Timestamp, simulatedData.HeatGeneratedSlag)
hold on
plot(simulatedData.Timestamp, simulatedData.fullBathHeatOut)
plot(simulatedData.Timestamp, simulatedData.HeatGeneratedSlag - simulatedData.fullBathHeatOut)
yline(0, 'k')
ylim([-5e4, 10e4])
ylabel('Heat [kW]')
yyaxis right
plot(simulatedData.Timestamp, simulatedData.SimulatedSlagTemperature)
plot(data.Al2O3FeedblendTimestamp, data.Slagtemperatures)
ylim([1100, 1400])
legend('QInTotal [kW]', 'QOutTotal [kW]', 'Net Heat [kW]')

ax2 = subplot(3,1,2);
plot(data.Al2O3FeedblendTimestamp, (data.Lanceheight + 350)/1000)
hold on
plot(simulatedData.Timestamp, simulatedData.SimulatedTotalBathHeight)
ylabel('Height [m]')
legend('Lance Proxy', 'Simulated Bath Height')

ax3 = subplot(3,1,3);
heightToMotionRatio = data.Lanceheight./data.Lancemotion/1000;
plot(data.Al2O3FeedblendTimestamp, heightToMotionRatio)
hold on
plot(data.Al2O3FeedblendTimestamp, movstd(heightToMotionRatio, 5))
ylim([0 100])
yline(1, 'k')
ylabel('Height to Motion Ratio')
legend('Ratio', 'Moving Std Dev')
linkaxes([ax1, ax2, ax3], 'x')

%% Quantifying amount of matte and slag tapped per tapping

figure
plot(rawOutputs.Time, rawOutputs.("Slag Tapping Rate [kg/s]"))
hold on
yyaxis right
plot(rawOutputs.Time, cumsum(rawOutputs.("Slag Tapping Rate [kg/s]")))

slagTappingRates = rawOutputs.('Slag Tapping Rate [kg/s]');

ix = cumsum([true; diff(slagTappingRates)~=0]);                               % index the sections
tmp = arrayfun(@(k) max(cumsum(slagTappingRates(ix==k)*60)), 1:ix(end), 'un', 0);    % cumsum each section
H = cat(1,tmp{:})