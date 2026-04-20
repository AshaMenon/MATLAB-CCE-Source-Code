%% Read data
inputsTT = readtable("POL_SIL_Data_20241023_2024AugData.xlsx", "Sheet", "Sheet1");


%% Calculate average matte tapping rate for open taphole
inputsTT.matteTapRatesLadle = calcMatteTapRatesFromLadleWeights(inputsTT);
%% Train test split
trainFraction = 0.6;
validationFraction = 0.2;
trainLength = floor(trainFraction * height(inputsTT));
validationLength = floor(validationFraction * height(inputsTT));
validationStartIdx = trainLength + 1;
testStartIdx = validationStartIdx + validationLength + 1;
trainData = inputsTT(1 : trainLength, :);
validationData = inputsTT(validationStartIdx : validationStartIdx+validationLength, :);
testData = inputsTT(testStartIdx : end, :);


%%
OUTLIER_MAX_THRESHOLD_TON_PER_HR = 200;
validTapOpen = trainData.matteTapRatesLadle > 0 & trainData.matteTapRatesLadle < OUTLIER_MAX_THRESHOLD_TON_PER_HR;
matteTapRatesOpen = trainData.matteTapRatesLadle(validTapOpen);
medianTapRateOpen = median(matteTapRatesOpen);
meanTapRateOpen = mean(matteTapRatesOpen);


%%

figure
plot(trainData.Timestamp, trainData.matteTapRatesLadle)
title("Matte tap rates")
xlabel("Timestamp")
ylabel("Tapping rate (ton/hr)")

figure
tiledlayout(4, 1)
ax1 = nexttile;
plot(trainData.Timestamp(validTapOpen), matteTapRatesOpen, '.')
title("Matte tap rates when taphole is open")
xlabel("Timestamp")
ylabel("Tapping rate (ton/hr)")

% TAPPING_THRESHOLD = 1200; % deg C
ax2 = nexttile;
plot(trainData.Timestamp, trainData.MatteTap1ThermalCameraTemp)
title("Tap 1 temp")

ax3 = nexttile;
plot(trainData.Timestamp, trainData.MatteTap2ThermalCameraTemp)
title("Tap 2 temp")

ax4 = nexttile;
plot(trainData.Timestamp, trainData.MatteTap3ThermalCameraTemp)
title("Tap 3 temp")

linkaxes([ax1 ax2 ax3 ax4], 'x')



fprintf("Median tapping rate: %f\n", medianTapRateOpen)
fprintf("Mean tapping rate: %f\n", meanTapRateOpen)


%% Calculating matte tapping rate based on amount of time tapholes open
TAPPING_THRESHOLD = 1200;

timeTapHolesOpenHr = sum((trainData.MatteTap1ThermalCameraTemp > TAPPING_THRESHOLD) ...
    + (trainData.MatteTap2ThermalCameraTemp > TAPPING_THRESHOLD) + (trainData.MatteTap3ThermalCameraTemp > TAPPING_THRESHOLD)) ...
    / 60 ;
meanTapRateOpenThermalCamera = (sum(matteTapRatesOpen)/60)/timeTapHolesOpenHr;
fprintf("Mean tapping rate based on thermal camera duration: %f\n", meanTapRateOpenThermalCamera)
%% Evaluation on validation set

validationLadleTon = sum(validationData.matteTapRatesLadle)/60;
validationIsTapping = validationData.matteTapRatesLadle > 0;

% constant tap rate
validationConstantTappingTonPerHr = calcMatteTapRatesConstantTappingRate(validationData, meanTapRateOpenThermalCamera);
validationConstantTappingTotalTon = sum(validationConstantTappingTonPerHr)/60;
constantTappingTotalErrorTon = validationConstantTappingTotalTon - validationLadleTon;

fprintf("\n")
fprintf("Constant Tapping Rate\n")
fprintf("Total error: %f tons\n", constantTappingTotalErrorTon)
fprintf("Percentage error: %f percent\n", constantTappingTotalErrorTon/validationLadleTon * 100)
fprintf("RMSE: %f tons\n", rmse(validationData.matteTapRatesLadle(validationIsTapping)/60, validationConstantTappingTonPerHr(validationIsTapping)/60))
fprintf("------------------------------------------------------\n")

% constant ladle weight
DEFAULT_LADLE_WEIGHT_TONS = 32;
MINIMUM_TAP_DURATION_MINS = 10;
validationConstantLadleWeightTonPerHr = calcMatteTapRatesFromThermalCamera(validationData, DEFAULT_LADLE_WEIGHT_TONS, MINIMUM_TAP_DURATION_MINS);
validationConstantLadleTotalTon = sum(validationConstantLadleWeightTonPerHr)/60;
constantLadleWeightTotalErrorTon = validationConstantLadleTotalTon - validationLadleTon;

fprintf("Constant Ladle Weight\n")
fprintf("Total error: %f tons\n", constantLadleWeightTotalErrorTon)
fprintf("Percentage error: %f percent\n", constantLadleWeightTotalErrorTon/validationLadleTon * 100)
fprintf("RMSE: %f tons\n", rmse(validationData.matteTapRatesLadle(validationIsTapping)/60, validationConstantLadleWeightTonPerHr(validationIsTapping)/60))
fprintf("------------------------------------------------------\n")

%% Plot ladle data in train set
ladlesEast = [];
timestampsEast = [];
durationsEastSecs = [];

ladlesCenter = [];
timestampsCenter = [];
durationsCenterSecs = [];

ladlesWest = [];
timestampsWest = [];
durationsWestSecs = [];

% extract info of each tapping event
for idx = 2 : height(trainData)
    if trainData.MatteTappedLadleEastTon(idx) ~= trainData.MatteTappedLadleEastTon(idx-1)
        ladlesEast = [ladlesEast; trainData.MatteTappedLadleEastTon(idx)];
        timestampsEast = [timestampsEast; trainData.Timestamp(idx)];
        durationsEastSecs = [durationsEastSecs; trainData.MatteTapDurationEastSecs(idx)];
    end

    if trainData.MatteTappedLadleCenterTon(idx) ~= trainData.MatteTappedLadleCenterTon(idx-1)
        ladlesCenter = [ladlesCenter; trainData.MatteTappedLadleCenterTon(idx)];
        timestampsCenter = [timestampsCenter; trainData.Timestamp(idx)];
        durationsCenterSecs = [durationsCenterSecs; trainData.MatteTapDurationCenterSecs(idx)];
    end

    if trainData.MatteTappedLadleWestTon(idx) ~= trainData.MatteTappedLadleWestTon(idx-1)
        ladlesWest = [ladlesWest; trainData.MatteTappedLadleWestTon(idx)];
        timestampsWest = [timestampsWest; trainData.Timestamp(idx)];
        durationsWestSecs = [durationsWestSecs; trainData.MatteTapDurationWestSecs(idx)];
    end
end

figure
plot(timestampsEast, ladlesEast, 'o')
hold on
plot(timestampsCenter, ladlesCenter,'o')
plot(timestampsWest, ladlesWest, 'o')
yline(32, '--', '32 ton')
aveLadleMeasurement = mean([ladlesEast; ladlesCenter; ladlesWest], 'all');
yline(aveLadleMeasurement, '--',  'Ave ' + string(aveLadleMeasurement) + ' ton', LabelVerticalAlignment='bottom');

hold off
grid on
title("Recorded ladle weights")
xlabel("Timestamp")
ylabel("Ladle weight (ton)")
legend(["East", "Center", "West"])

meanTapRate = mean([ladlesEast; ladlesCenter; ladlesWest]);

%% Ladle data timing plot

figure
tiledlayout(3, 1)
ax1 = nexttile;
plot(inputsTT.Timestamp, inputsTT.MatteTap1ThermalCameraTemp)
hold on
plot(timestampsEast, ladlesEast + 999, '.')
hold off
title("Matte Tapping East")
legend(["Taphole temp", "Ladle recordings"])
ax2 = nexttile;
plot(inputsTT.Timestamp, inputsTT.MatteTap2ThermalCameraTemp)
hold on
plot(timestampsCenter, ladlesCenter + 999, '.')
hold off
title("Matte Tapping Center")
legend(["Taphole temp", "Ladle recordings"])

ax3= nexttile;
plot(inputsTT.Timestamp, inputsTT.MatteTap3ThermalCameraTemp)
hold on
plot(timestampsWest, ladlesWest + 999, '.')
hold off
title("Matte Tapping West")
legend(["Taphole temp", "Ladle recordings"])
linkaxes([ax1 ax2 ax3], 'x')