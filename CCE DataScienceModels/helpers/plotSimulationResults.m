function plotSimulationResults(actualData,simulatedData)

figure
ax1 = subplot(2,3,1);
plot(actualData.Al2O3FeedblendTimestamp, actualData.Mattetemperatures)
hold on
plot(simulatedData.Timestamp, simulatedData.SimulatedMatteTemperature)
plot(actualData.Al2O3FeedblendTimestamp, actualData.Slagtemperatures)
plot(simulatedData.Timestamp, simulatedData.SimulatedSlagTemperature)
legend('Measured Matte Temp','Simulated Matte Temp',...
    'Measured Slag Temp','Simulated Slag Temp')

ax2 = subplot(2,3,4);
plot(simulatedData.Timestamp, simulatedData.SimulatedSlagHeight)
hold on
legend('Simulated Slag Height')

ax3 = subplot(2,3,2);
plot(actualData.Al2O3FeedblendTimestamp, actualData.Lanceheight/1000+0.35)
hold on
plot(simulatedData.Timestamp, simulatedData.SimulatedTotalBathHeight)
legend('Bath Height (Proxy)','Simulated Bath Height')

ax4 = subplot(2,3,5);
plot(simulatedData.Timestamp, simulatedData.SlagTapping)
hold on
plot(simulatedData.Timestamp, simulatedData.MatteTapping)
legend('Slag Tapping', 'Matte Tapping')

ax5 = subplot(2,3,3);
plot(actualData.Al2O3FeedblendTimestamp, actualData.Convertermode)
hold on
legend('Converter Mode')

ax6 = subplot(2,3,6);
plot(simulatedData.Timestamp, simulatedData.SimulatedMatteHeight)
hold on
legend('Simulated Matte Height')
linkaxes([ax1, ax2, ax3, ax4, ax5, ax6],'x')

end