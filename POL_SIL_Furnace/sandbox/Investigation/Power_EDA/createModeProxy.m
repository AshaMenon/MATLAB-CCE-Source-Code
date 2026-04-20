function dataTbl = createModeProxy(dataTbl)
    %CREATEMODEPROXY Creates a proxy signal to determine the mode of the furnace
    %   Detailed explanation goes here


    % Define thresholds
    normalThreshold = 68;
    offThreshold = 0.1;
    timeThreshold = 5; % minutes
    lostCapThreshold = 66;

    % Define the category order
    categoryOrder = {'Off', 'Lost Capacity', 'Ramp', 'Normal', };
    % Ramp is a type of lost capacity but lost capacity is not always ramp-up
    % Ramp, Normal and Lost Capacity are considered ON

    dataTbl.mode = categorical(cellstr(strings(height(dataTbl), 1)), categoryOrder, 'Ordinal', true);
    dataTbl.mode(dataTbl.FurnacePowerSP >= normalThreshold) = "Normal";
    dataTbl.mode(dataTbl.TotalElectrodePower < offThreshold) = "Off";

    
    for i = 2:height(dataTbl)
         prevMode = string(dataTbl.mode(i-1));
         currMode = string(dataTbl.mode(i));
         if (prevMode == "Off" || prevMode == "Ramp") && currMode ~= "Normal" && currMode ~= "Off"
             dataTbl.mode(i) = "Ramp";
         end
    end
    
    dataTbl.mode(dataTbl.FurnacePowerSP < 68 & dataTbl.mode ~= "Ramp" & dataTbl.mode ~= "Off") = "Lost Capacity";
    
    
      % Time threshold rule for Lost Capacity for values between 66 and 68
    for i = 1:height(dataTbl)
        if i >= 6 % Assuming minutely data, so 5 rows before i
            timeWindow = dataTbl.FurnacePowerSP(i-5:i);
            
            if dataTbl.FurnacePowerSP(i) < normalThreshold && dataTbl.FurnacePowerSP(i) >= lostCapThreshold
                % Check value just before timeWindow
                if dataTbl.FurnacePowerSP(i-timeThreshold+1) >= normalThreshold && all(timeWindow < normalThreshold)
                    dataTbl.mode(i-timeThreshold:i) = "Lost Capacity";
                else
                    dataTbl.mode(i) = "Normal";
                end
            end
        end
    end
end