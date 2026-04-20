%% Analyse results produced by the deployed model

% resultsTbl1 = readtimetable(['temperatureData_Jan-Mar-23_v3.csv']);
resultsTbl2 = readtimetable(['temperatureData_Jul-Oct-23_v1.csv']);


% dateFilter = resultsTbl2.Timestamp > datetime(0023,06,01,0,0,0,0);
% resultsTbl2 = resultsTbl2(dateFilter, :);


% variablesToConvert = resultsTbl1.Properties.VariableNames(80:end);
% 
% for nVar = 1:length(variablesToConvert)
%     varName = variablesToConvert{nVar};
%     if ~isa(resultsTbl1.(varName), 'double')
%         resultsTbl1.(varName) = str2double(resultsTbl1.(varName));
%     end
%     resultsTbl1.(varName) = fillmissing(resultsTbl1.(varName), 'previous');
% end

% Use varfun to check column types
varTypes = varfun(@class, resultsTbl2, 'OutputFormat', 'cell');

% Find variable names with type 'cell'
variablesToConvert = resultsTbl2.Properties.VariableNames(strcmp(varTypes, 'cell'));

for nVar = 1:length(variablesToConvert)
    varName = variablesToConvert{nVar};
    if ~isa(resultsTbl2.(varName), 'double')
        resultsTbl2.(varName) = str2double(resultsTbl2.(varName));
    end
end
resultsTbl2.(varName) = fillmissing(resultsTbl2.(varName), 'previous');
resultsTbl = resultsTbl2;

% Filter on date

%%
figure
ax1 = subplot(2,2,1);
title('Heights and Simulated Heights')
hold on
plot(resultsTbl.Timestamp, (resultsTbl.LanceHeight + 350)/1000) % Bath Height Proxy
plot(resultsTbl.Timestamp, resultsTbl.SimulatedTotalBathHeight)
plot(resultsTbl.Timestamp, resultsTbl.SimulatedMatteHeight)
plot(resultsTbl.Timestamp, resultsTbl.SimulatedSlagHeight)

% legend('Online Sim Bath Height', 'Online Sim Slag Height')
legend('Bath Height (proxy)', 'Total Sim Bath Height', ...
    'Sim Matte Height', 'Sim Slag Height')

ax2 = subplot(2,2,2);
title('Matte Heights')
hold on
plot(resultsTbl.Timestamp, resultsTbl.SimulatedMatteHeight, 'o-')
legend('Online Sim Matte Height')

ax3 = subplot(2,2,3);
title('Matte Feed Rate')
hold on
plot(resultsTbl.Timestamp, resultsTbl.MatteFeedPV)

ax4 = subplot(2,2,4);
title('Tapping')
hold on
plot(resultsTbl.Timestamp, resultsTbl.MatteTapping)
plot(resultsTbl.Timestamp, resultsTbl.SlagTapping)
legend('Matte Tapping', 'Slag Tapping')
linkaxes([ax1, ax2, ax3, ax4], 'x')

%%
figure
sgtitle('Live Results')
hold on
ax1 = subplot(3,2,1);
title('Matte Temperature (Measured and Simulated)')
hold on
grid on
grid minor
plot(resultsTbl.Timestamp, resultsTbl.MatteTemperatures, '-',...
    'Color', [0, 0.4470, 0.7410])
plot(resultsTbl.Timestamp, resultsTbl.SlagTemperatures, '-',...
    'Color', [0.8500, 0.3250, 0.0980])
plot(resultsTbl.Timestamp, resultsTbl.SimulatedMatteTemperature, '--',...
    'Color', [0, 0.4470, 0.7410])
plot(resultsTbl.Timestamp, resultsTbl.SimulatedSlagTemperature, '--',...
    'Color', [0.8500, 0.3250, 0.0980])
plot(resultsTbl.Timestamp, movmedian(resultsTbl.SimulatedMatteTemperature, 75),...
    'Color', [0, 0.4470, 0.7410], 'LineWidth', 1.2)
plot(resultsTbl.Timestamp, movmedian(resultsTbl.SimulatedSlagTemperature, 75),...
    'Color', [0.8500, 0.3250, 0.0980], 'LineWidth', 1.2)
legend('Measured Matte Temp', 'Measured Slag Temp', ...
    'Simulated Matte Temp', 'Simulated Slag Temp')

ax2 = subplot(3,2,2);
title('Heights (Measured and Simulated) and Tapping')
hold on
grid on
grid minor
plot(resultsTbl.Timestamp, (resultsTbl.LanceHeight + 350)/1000)
plot(resultsTbl.Timestamp, resultsTbl.SimulatedTotalBathHeight)
plot(resultsTbl.Timestamp, resultsTbl.SimulatedMatteHeight)
plot(resultsTbl.Timestamp, resultsTbl.MatteTapping)
plot(resultsTbl.Timestamp, resultsTbl.SlagTapping)
legend('Measured Bath Height',...
    'Simulated Bath Height', 'Simulated Matte Height')

ax3 = subplot(3,2,3);
title('Full Bath Heats')
hold on
grid on
grid minor
plot(resultsTbl.Timestamp, resultsTbl.TotalHeatInBath)
plot(resultsTbl.Timestamp, resultsTbl.TotalHeatOutBath)
plot(resultsTbl.Timestamp, resultsTbl.TotalHeatInBath - resultsTbl.TotalHeatOutBath)
yline(0, 'k')
legend('Heat In','Heat Out','Net Heat')

ax4 = subplot(3,2,4);
title('Matte Feed')
hold on
grid on
grid minor
plot(resultsTbl.Timestamp, resultsTbl.MatteFeedPV)
plot(resultsTbl.Timestamp, resultsTbl.RoofMatteFeedRatePV)
legend('Matte Feed', 'Roof Matte Feed')

ax5 = subplot(3,2,5);
title('Tapping')
hold on
grid on
grid minor
plot(resultsTbl.Timestamp, resultsTbl.MatteTapping)
plot(resultsTbl.Timestamp, resultsTbl.SlagTapping)
ylim([-0.05, 1.05])
legend('Matte Tapping', 'Slag Tapping')

ax6 = subplot(3,2,6);
title('Fuel Coal Feed Rate')
hold on
grid on
grid minor
plot(resultsTbl.Timestamp, resultsTbl.FuelCoalFeedRatePV)
legend('Fuel Coal Feed Rate')

linkaxes([ax1, ax2, ax3, ax4, ax5, ax6], 'x')

%% Close look at bath heats in and out

figure
ax1 = subplot(2,2,1);
title('Matte Temperature (Measured and Simulated)')
hold on
grid on
grid minor
plot(resultsTbl.Timestamp, resultsTbl.MatteTemperatures, '-',...
    'Color', [0, 0.4470, 0.7410])
plot(resultsTbl.Timestamp, resultsTbl.SlagTemperatures, '-',...
    'Color', [0.8500, 0.3250, 0.0980])
plot(resultsTbl.Timestamp, resultsTbl.SimulatedMatteTemperature, '--',...
    'Color', [0, 0.4470, 0.7410])
plot(resultsTbl.Timestamp, resultsTbl.SimulatedSlagTemperature, '--',...
    'Color', [0.8500, 0.3250, 0.0980])
plot(resultsTbl.Timestamp, movmedian(resultsTbl.SimulatedMatteTemperature, 75),...
    'Color', [0, 0.4470, 0.7410], 'LineWidth', 1.2)
plot(resultsTbl.Timestamp, movmedian(resultsTbl.SimulatedSlagTemperature, 75),...
    'Color', [0.8500, 0.3250, 0.0980], 'LineWidth', 1.2)
legend('Measured Matte Temp', 'Measured Slag Temp', ...
    'Simulated Matte Temp', 'Simulated Slag Temp')

ax2 = subplot(2,2,2);
title('Heights (Measured and Simulated) and Tapping')
hold on
grid on
grid minor
plot(resultsTbl.Timestamp, (resultsTbl.LanceHeight + 350)/1000)
plot(resultsTbl.Timestamp, resultsTbl.SimulatedTotalBathHeight)
plot(resultsTbl.Timestamp, resultsTbl.SimulatedMatteHeight)
plot(resultsTbl.Timestamp, resultsTbl.MatteTapping)
plot(resultsTbl.Timestamp, resultsTbl.SlagTapping)
legend('Measured Bath Height',...
    'Simulated Bath Height', 'Simulated Matte Height')

ax3 = subplot(2,2,3);
title('Heat In Components')
hold on
grid on
grid minor
plot(resultsTbl.Timestamp, resultsTbl.HeatGeneratedSlag)
legend('Heat Generated')

ax4 = subplot(2,2,4);
title('Heat Out Components')
hold on
grid on
grid minor
plot(resultsTbl.Timestamp, resultsTbl.HeatMassFlowFromSlagToInflow)
plot(resultsTbl.Timestamp, resultsTbl.HeatConductedFromSlagToMatte)
plot(resultsTbl.Timestamp, resultsTbl.HeatMassFlowMatteTappedFullBath)
plot(resultsTbl.Timestamp, resultsTbl.HeatMassFlowSlagTapped)
plot(resultsTbl.Timestamp, resultsTbl.HeatConductedFromFullBathToWaffleCooler)
plot(resultsTbl.Timestamp, resultsTbl.HeatRadiatedFromSlagToFurnace)
plot(resultsTbl.Timestamp, resultsTbl.HeatMassFlowFromOffgasToFurnace)
plot(resultsTbl.Timestamp, resultsTbl.HeatMassFlowFromAccruedSlagAndDustToFurnace)
legend('Slag to Inflow', 'Heat from Slag to Matte', 'Matte Tapped',...
    'Slag Tapped', 'Waffle Cooler',...
    'Radiated to Furnace', 'Offgas', 'Accrued Dust and Slag')

% Deep Dive

ax5 = descriptivePlot(resultsTbl.Timestamp, resultsTbl.HeatMassFlowFromSlagToInflow, ...
    '-', [0, 0.4470, 0.7410], 'Heat Mass Flow (Slag to Inflow) [kW]');
ax6 = descriptivePlot(resultsTbl.Timestamp, resultsTbl.HeatConductedFromSlagToMatte, ...
    '-', [0.8500, 0.3250, 0.0980], 'Heat Conducted (Slag to Matte) [kW]');
ax7 = descriptivePlot(resultsTbl.Timestamp, resultsTbl.HeatMassFlowMatteTappedFullBath, ...
    '-', [0.9290, 0.6940, 0.1250], 'Heat Mass Flow (Matte Tapped) [kW]');
ax8 = descriptivePlot(resultsTbl.Timestamp, resultsTbl.HeatMassFlowSlagTapped, ...
    '-', [0.4940, 0.1840, 0.5560] 	 , 'Heat Mass Flow (Slag Tapped) [kW]');
ax9 = descriptivePlot(resultsTbl.Timestamp, resultsTbl.HeatConductedFromFullBathToWaffleCooler, ...
    '-', [0.4660, 0.6740, 0.1880] 	 , 'Heat Conducted (Bath to Waffle Cooler) [kW]');
ax10 = descriptivePlot(resultsTbl.Timestamp, resultsTbl.HeatRadiatedFromSlagToFurnace, ...
    '-', [0.3010, 0.7450, 0.9330] 	, 'Heat Radiated (Slag to Furnace) [kW]');
ax11 = descriptivePlot(resultsTbl.Timestamp, resultsTbl.HeatMassFlowFromOffgasToFurnace, ...
    '-', [0.6350, 0.0780, 0.1840], 'Heat Mass Flow (Offgas to Furnace) [kW]');
ax12 = descriptivePlot(resultsTbl.Timestamp, resultsTbl.HeatMassFlowFromAccruedSlagAndDustToFurnace, ...
    '-', [1, 0, 0], 'Heat Mass Flow (Accrued Slag and Dust to Furnace) [kW]');

linkaxes([ax1, ax2, ax3, ax4, ax5, ax6, ax7, ax8, ax9, ax10, ax11, ax12], 'x')

%% Comparing Tap Times and Tapping Indicators

figure
ax1 = subplot(3,1,1);
title('Matte Tapping')
hold on
plot(resultsTbl.Timestamp, resultsTbl.PhaseBMatteTapBlock1DT_water)
plot(resultsTbl.Timestamp, resultsTbl.PhaseBMatteTapBlock2DT_water)
plot(resultsTbl.Timestamp, resultsTbl.MatteTapping)
legend('Tap Block 1', 'Tap Block 2', 'Matte Tapping')

ax2 = subplot(3,1,2);
title('Slag Tap Hole Temp')
hold on
plot(resultsTbl.Timestamp, resultsTbl.PhaseBSlagTapBlockDT_water)
plot(resultsTbl.Timestamp, resultsTbl.SlagTapping)
legend('Tap Block', 'Slag Tapping')

ax3 = subplot(3,1,3);
title('Tap Rates')
hold on
plot(resultsTbl.Timestamp, resultsTbl.MatteTappingRate)
plot(resultsTbl.Timestamp, resultsTbl.SlagTappingRate)
legend('Matte Tap Rate', 'Slag Tap Rate')
linkaxes([ax1, ax2, ax3], 'x')

%% Comparing Tap Times and Heights

figure
ax1 = subplot(3,1,1);
title('Tapping Classifications')
hold on
plot(resultsTbl.Timestamp, resultsTbl.MatteTapping)
plot(resultsTbl.Timestamp, resultsTbl.SlagTapping)
legend('Matte Tapping', 'Slag Tapping')

ax2 = subplot(3,1,2);
title('Heights (Measured and Simulated) and Tapping')
hold on
grid on
grid minor
plot(resultsTbl.Timestamp, (resultsTbl.LanceHeight + 350)/1000)
plot(resultsTbl.Timestamp, resultsTbl.SimulatedTotalBathHeight)
plot(resultsTbl.Timestamp, resultsTbl.SimulatedMatteHeight)
legend('Measured Bath Height',...
    'Simulated Bath Height', 'Simulated Matte Height')

ax3 = subplot(3,1,3);
title('Tap Rates')
hold on
plot(resultsTbl.Timestamp, resultsTbl.MatteTappingRate)
plot(resultsTbl.Timestamp, resultsTbl.SlagTappingRate)
legend('Matte Tap Rate', 'Slag Tap Rate')
linkaxes([ax1, ax2, ax3], 'x')