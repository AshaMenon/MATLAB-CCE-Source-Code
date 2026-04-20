function slagFall = calculateSlagFall(campaignData, furnaceArea)

% Calculate finite differences for time and tank level change
deltaTime = seconds(diff(campaignData.timeInterval));  
campaignTimeInterval = [deltaTime(:, 1); deltaTime(end, 2)];


% Calculate dh/dt using finite differences: dh/dt = delta_level / delta_time
dh_dt = campaignData.levelChange ./ (campaignTimeInterval) * 60; % centimeters/min
dh_dt = dh_dt / 100; %meters/min

tappedSlag = campaignData.totalSlagTapped ./ (campaignTimeInterval / 60); %ton/min
% Calculate Min for each timestamp using the formula dh/dt = (Min -
% Mout)/Rho * A
slagFall = dh_dt * furnaceArea + tappedSlag; %ton/min