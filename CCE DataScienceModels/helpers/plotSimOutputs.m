function plotSimOutputs(time, iodata, bathHeightSignal, matteTempSignal)
%PLOTSIMOUTPUTS - Plots actual measured values and simulated outputs

figure
title('Simulated and Measured Responses Before Estimation')
hold on
ax1 = subplot(2,1,1);
plot(time, iodata{:, {'Bath Height'}}, ...
    bathHeightSignal.Values.Time,bathHeightSignal.Values.Data,'--');
legend('Measured Bath Height', 'Simulated Bath Height');

ax2 = subplot(2,1,2);
plot(time, iodata{:, {'Mattetemperatures'}}, ...
    matteTempSignal.Values.Time,matteTempSignal.Values.Data,'-.');
legend('Measured Matte Temp', 'Simulated Matte Temp');
linkaxes([ax1, ax2], 'x')
end