% Run models
dataSim = offlineLevelTestingScript();
%load('offlineModelResults.mat')
[simOut, simInTT] = runMassBalanceTest();
%% Plot comparison
figure
tiledlayout(3, 2)
% Plot heights
ax1 = nexttile();
plot(seconds(simOut.height_matte.Time) + datetime('01-Aug-2024 23:56:00'), simOut.height_matte.Data)
hold on
plot(dataSim.Timestamp, dataSim.SimulatedMatteLevel)
legend({'runMassBalanceTest', 'offlineLevelTestingScript'})
subtitle("Matte Height")
hold off

ax2 = nexttile();
plot(seconds(simOut.height_slag.Time)+ datetime('01-Aug-2024 23:56:00'), simOut.height_slag.Data)
hold on
plot(dataSim.Timestamp, dataSim.SimulatedSlagLevel)
legend({'runMassBalanceTest', 'offlineLevelTestingScript'})
subtitle("Slag Height")
hold off

ax3 = nexttile();
plot(seconds(simOut.height_concentrate.Time)+datetime('01-Aug-2024 23:56:00'), simOut.height_concentrate.Data)
hold on
plot(dataSim.Timestamp, dataSim.SimulatedBlackTopLevel)
legend({'runMassBalanceTest', 'offlineLevelTestingScript'})
subtitle("Concentrate Height")
hold off


% Plot other
ax4 = nexttile();
plot(seconds(simOut.matte_fall_fraction.Time)+ datetime('01-Aug-2024 23:56:00'), simOut.matte_fall_fraction.Data)
hold on
plot(dataSim.Timestamp, dataSim.matte_fall_fraction)
legend({'runMassBalanceTest', 'offlineLevelTestingScript'})
subtitle("matte fall fraction")
hold off

ax5 = nexttile();
plot(seconds(simOut.mdot_slag_tap_ton_per_hr.Time)+ datetime('01-Aug-2024 23:56:00'), simOut.mdot_slag_tap_ton_per_hr.Data)
hold on
plot(dataSim.Timestamp, dataSim.mdot_slag_tap_ton_per_hr)
legend({'runMassBalanceTest', 'offlineLevelTestingScript'})
subtitle("mdot slag tap ton per hr")
hold off

ax6 = nexttile();
plot(seconds(simOut.mdot_matte_tap_ton_per_hr.Time)+ datetime('01-Aug-2024 23:56:00'), simOut.mdot_matte_tap_ton_per_hr.Data)
hold on
plot(dataSim.Timestamp, dataSim.mdot_matte_tap_ton_per_hr)
legend({'runMassBalanceTest', 'offlineLevelTestingScript'})
subtitle("mdot matte tap ton per hr")
hold off

linkaxes([ax1 ax2 ax3 ax4 ax5 ax6], 'x')