function rollingTimeOnline = rollingCumulativeTimeOnline(dataTbl,windowSize)
    %ROLLINGCUMULATIVETIMEONLINE Calculates a metric for rolling cumulative time
    %online

     % Convert modes to numeric values
    numericModes = zeros(height(dataTbl), 1);
    numericModes(dataTbl.mode == "Normal") = 1;
    numericModes(dataTbl.mode == "Off") = 0;
    numericModes(dataTbl.mode == "Ramp") = 0.5;
    numericModes(dataTbl.mode == "Lost Capacity") = 0.5;
    
    % Calculate rolling cumulative metric
    rollingTimeOnline = movmean(numericModes, windowSize);
end