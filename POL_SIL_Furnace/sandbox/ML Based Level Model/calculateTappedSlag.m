function tappedSlag = calculateTappedSlag(data, conveyorFlowThreshold, moisture)

conveyorFilterIdx = data.Conveyor_Slag < conveyorFlowThreshold | data.Mode == "Off" | data.Mode == "Ramp";
tappedSlag = [data(~conveyorFilterIdx, 'Time' ), data(~conveyorFilterIdx, "Conveyor_Slag")];
nanRows = any(isnan(tappedSlag{:,2 : end}), 2);

% Use the logical index to filter the rows with NaN values
tappedSlag = tappedSlag(~nanRows, :);
tappedSlag.Conveyor_Slag = (100 - moisture)/ 100 * tappedSlag.Conveyor_Slag / 60;

