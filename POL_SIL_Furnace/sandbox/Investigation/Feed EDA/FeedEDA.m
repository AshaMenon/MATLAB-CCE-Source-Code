%% Load in that chem data
feedData = readtable("Data\Feed Data\Polokwane_SIL_Feeding_data_Jan_Aug23_v1.csv");
feedData.Timestamp.Year = feedData.Timestamp.Year + 2000;
feedData = table2timetable(feedData);
nanVals = feedData{:,:} <= 0;
for x = 1:width(feedData)
    feedData{nanVals(:,x),x} = 0; 
end

westData = feedData(:,1:7);
eastData = feedData(:,8:end);

%% Plot it all as a start
plot(westData, "Timestamp", {'W1_TotalFeed', 'W2_TotalFeed', 'W3_TotalFeed', ...
    'W4_TotalFeed', 'W5_TotalFeed', 'W6_TotalFeed', 'W7_TotalFeed'});
legend;
figure;
plot(eastData, "Timestamp", {'E1_TotalFeed', 'E2_TotalFeed', 'E3_TotalFeed', ...
    'E4_TotalFeed', 'E5_TotalFeed', 'E6_TotalFeed', 'E7_TotalFeed'});
legend;

%% Calculate total feed for East and West
WTotalFeed = sum(westData{:,:},2);
ETotalFeed = sum(eastData{:,:},2);

%% Calculate % per bin in each feed
WperBin = westData./WTotalFeed;
ePerBin = eastData./ETotalFeed;

plot(WperBin, "Timestamp", {'W1_TotalFeed', 'W2_TotalFeed', 'W3_TotalFeed', ...
    'W4_TotalFeed', 'W5_TotalFeed', 'W6_TotalFeed', 'W7_TotalFeed'});
legend;
figure;
plot(ePerBin, "Timestamp", {'E1_TotalFeed', 'E2_TotalFeed', 'E3_TotalFeed', ...
    'E4_TotalFeed', 'E5_TotalFeed', 'E6_TotalFeed', 'E7_TotalFeed'});
legend;

