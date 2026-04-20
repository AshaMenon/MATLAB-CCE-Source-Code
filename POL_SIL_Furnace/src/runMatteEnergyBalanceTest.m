%% Load data and run simulation
% read inputs from file
inputs = readtable("POL_SIL_Data_20241107_2024OctData.xlsx", "Sheet", "Sheet1");

% filter for 1 week of data
startTime = datetime('03-Oct-2024 14:00:00'); % start when sounding reading has just been taken
endTime = datetime('08-Oct-2024 18:00:00');
inputs = filterByDateTime(inputs, startTime, endTime);

% preprocess
slInputs = preprocessTemperatureData(inputs);

% run test harness on matte energy balance
open('matteEnergyBalance.slx');
sltest.harness.open('matteEnergyBalance', 'matteEnergyBalance_HarnessFromWorkspace');
set_param('matteEnergyBalance_HarnessFromWorkspace', 'StopTime', ...
    string(seconds(slInputs.T_slag.Timestamp(end) - ...
    slInputs.T_slag.Timestamp(1))));  % Set the stop time
set_param('matteEnergyBalance_HarnessFromWorkspace', 'StartTime', ...
    string(seconds(slInputs.T_slag.Timestamp(1))));  % Set the start time
simOut = sim('matteEnergyBalance_HarnessFromWorkspace');

function filteredTbl = filterByDateTime(tbl, startTime, endTime)
   filteredTbl = tbl(and(tbl.Timestamp >= startTime, tbl.Timestamp <= endTime), :);
end

%% Compare simulation results
figure
plot(slInputs.T_slag.Timestamp+inputs.Timestamp(1), ...
    slInputs.T_slag.MatteTemp)
hold on
plot(seconds(simOut.tout)+inputs.Timestamp(1), simOut.T_slag.Data)
hold off
title("Matte temperature (^oC)")
legend(["Measured", "Model"])

