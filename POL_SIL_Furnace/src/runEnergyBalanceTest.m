%% Load data and run simulation
% read inputs from file
inputs = readtable("POL_SIL_Data_20241107_2024AugData.xlsx", "Sheet", "Sheet1");

% filter for 1 week of data
startTime = datetime('01-Aug-2024 18:00:00'); % start when sounding reading has just been taken
endTime = datetime('31-Aug-2024 18:00:00');
inputs = filterByDateTime(inputs, startTime, endTime);

% preprocess
slInputs = preprocessTemperatureData(inputs);

% run test harness
open('energyBalance.slx');
sltest.harness.open('energyBalance', 'energyBalance_HarnessFromWorkspace');
set_param('energyBalance_HarnessFromWorkspace', 'StopTime', ...
    string(seconds(slInputs.T_matte.Timestamp(end) - ...
    slInputs.T_matte.Timestamp(1))));  % Set the stop time
set_param('energyBalance_HarnessFromWorkspace', 'StartTime', ...
    string(seconds(slInputs.T_matte.Timestamp(1))));  % Set the stop time
simOut = sim('energyBalance_HarnessFromWorkspace');

function filteredTbl = filterByDateTime(tbl, startTime, endTime)
   filteredTbl = tbl(and(tbl.Timestamp >= startTime, tbl.Timestamp <= endTime), :);
end

%% Compare simulation results with subplots
figure

% First subplot: Slag temperature
subplot(3, 1, 1)
stairs(slInputs.T_slag.Timestamp + inputs.Timestamp(1), slInputs.T_slag.SlagTemp)
hold on
plot(seconds(simOut.tout) + inputs.Timestamp(1), simOut.T_slag.Data)
hold off
title("Slag Temperature (^oC)")
legend(["Actual", "Predicted"])
xlabel("Time")
ylabel("Temperature (^oC)")

% Second subplot: Matte temperature
subplot(3, 1, 2)
stairs(slInputs.T_matte.Timestamp + inputs.Timestamp(1), slInputs.T_matte.MatteTemp)
hold on
plot(seconds(simOut.tout) + inputs.Timestamp(1), simOut.T_matte.Data)
hold off
title("Matte Temperature (^oC)")
legend(["Actual", "Predicted"])
xlabel("Time")
ylabel("Temperature (^oC)")

% Third subplot: Power
subplot(3, 1, 3)
stairs(slInputs.Wdot_electrode_MW.Timestamp + inputs.Timestamp(1), slInputs.Wdot_electrode_MW.PowerMw)
title("Power")
xlabel("Time")
ylabel("Electrode Power (MW)")

