function testArr = calcMatteTapRatesHybridDeploymentTest
    testArr = functiontests(localfunctions);
end

function setupOnce(testCase)
    startDatetime = datetime(2024, 8, 1);
    endDatetime = datetime(2024, 8, 8);

    testCase.TestData.defaultInputs = table;
    testCase.TestData.defaultInputs.Timestamp =  (startDatetime:minutes(1):endDatetime)';
    
    testCase.TestData.defaultInputs.MatteTappedLadleEastTon = zeros(height(testCase.TestData.defaultInputs), 1);
    testCase.TestData.defaultInputs.MatteTappedLadleCenterTon = zeros(height(testCase.TestData.defaultInputs), 1);
    testCase.TestData.defaultInputs.MatteTappedLadleWestTon = zeros(height(testCase.TestData.defaultInputs), 1); 

    testCase.TestData.defaultInputs.MatteTapDurationEastSecs = zeros(height(testCase.TestData.defaultInputs), 1);
    testCase.TestData.defaultInputs.MatteTapDurationCenterSecs = zeros(height(testCase.TestData.defaultInputs), 1);
    testCase.TestData.defaultInputs.MatteTapDurationWestSecs = zeros(height(testCase.TestData.defaultInputs), 1);

    testCase.TestData.defaultInputs.MatteTap1ThermalCameraTemp = 999 * ones(height(testCase.TestData.defaultInputs), 1);
    testCase.TestData.defaultInputs.MatteTap2ThermalCameraTemp = 999 * ones(height(testCase.TestData.defaultInputs), 1);
    testCase.TestData.defaultInputs.MatteTap3ThermalCameraTemp = 999 * ones(height(testCase.TestData.defaultInputs), 1);

    testCase.TestData.defaultLadleWeightTon = 32;
    testCase.TestData.defaultMinimumTapDurationMins = 10;
    testCase.TestData.tapholeOpenDegC = 1400;
    testCase.TestData.tolTon = 0.01;
    testCase.TestData.executionPeriodMins = 30;
    testCase.TestData.dataWindowMins = 12 * 60;
    
end

function testZeroMatteTapping(testCase)    
    inputs = testCase.TestData.defaultInputs;
    defaultLadleWeightTon = testCase.TestData.defaultLadleWeightTon;
    minimumTapDurationMins = testCase.TestData.defaultMinimumTapDurationMins;

    matteTapRatesTonPerHr = calcMatteTapRatesHybridDeployment(inputs, defaultLadleWeightTon, minimumTapDurationMins, testCase.TestData.executionPeriodMins);
    verifyLessThan(testCase, abs(matteTapRatesTonPerHr), eps)
end

function testNoMatteTapping(testCase)
    % all tapping readings staying the same implies no tapping  
    defaultLadleWeightTon = testCase.TestData.defaultLadleWeightTon;
    minimumTapDurationMins = testCase.TestData.defaultMinimumTapDurationMins;
    inputs = testCase.TestData.defaultInputs;

    inputs.MatteTappedLadleEastTon = 32 * ones(height(inputs), 1);
    inputs.MatteTapDurationEastSecs = 3000 * ones(height(inputs), 1);
    inputs.MatteTappedLadleCenterTon = 32 * ones(height(inputs), 1);
    inputs.MatteTapDurationCenterSecs = 3000 * ones(height(inputs), 1);
    inputs.MatteTappedLadleWestTon = 32 * ones(height(inputs), 1); 
    inputs.MatteTapDurationWestSecs = 3000 * ones(height(inputs), 1);

    matteTapRatesTonPerHr = calcMatteTapRatesHybridDeployment(inputs, defaultLadleWeightTon, minimumTapDurationMins, testCase.TestData.executionPeriodMins);
    verifyLessThan(testCase, abs(matteTapRatesTonPerHr), eps)
end

function testOneLadleOnEachTaphole(testCase)
    defaultLadleWeightTon = testCase.TestData.defaultLadleWeightTon;
    minimumTapDurationMins = testCase.TestData.defaultMinimumTapDurationMins;
    tolTon = testCase.TestData.tolTon;
    inputs = testCase.TestData.defaultInputs;
    
    inputs.MatteTappedLadleEastTon = zeros(height(inputs), 1);
    inputs.MatteTapDurationEastSecs = zeros(height(inputs), 1);
    inputs.MatteTappedLadleCenterTon = zeros(height(inputs), 1);
    inputs.MatteTapDurationCenterSecs = zeros(height(inputs), 1);
    inputs.MatteTappedLadleWestTon = zeros(height(inputs), 1); 
    inputs.MatteTapDurationWestSecs = zeros(height(inputs), 1);

    tapStartIndexEast = 100;
    tapStartIndexCenter = 200;
    tapStartIndexWest = 300;
    
    ladleEastTon = 33;
    ladleCenterTon = 46;
    ladleWestTon = 50;

    
    % tap duration shouldn't affect total matte tapped
    durationEastSecs = 30*60;
    durationCenterSecs = 40*60;
    durationWestSecs = 50*60;

    inputs.MatteTappedLadleEastTon(tapStartIndexEast:end) = ladleEastTon;
    inputs.MatteTappedLadleCenterTon(tapStartIndexCenter:end) = ladleCenterTon;
    inputs.MatteTappedLadleWestTon(tapStartIndexWest:end) = ladleWestTon;

    inputs.MatteTapDurationEastSecs(tapStartIndexEast:end) = durationEastSecs;
    inputs.MatteTapDurationCenterSecs(tapStartIndexCenter:end) = durationCenterSecs;
    inputs.MatteTapDurationWestSecs(tapStartIndexWest:end) = durationWestSecs;

    matteTapRatesTonPerHr = calcMatteTapRatesHybridDeployment(inputs, defaultLadleWeightTon, minimumTapDurationMins, testCase.TestData.executionPeriodMins);
    totalTappedActualTon = sum(matteTapRatesTonPerHr)/60;
    totalTappedExpectedTon = ladleEastTon + ladleCenterTon + ladleWestTon;
    verifyLessThan(testCase, abs(totalTappedActualTon - totalTappedExpectedTon), tolTon)
end

function testThermalCamerasOnly(testCase)
    defaultLadleWeightTon = testCase.TestData.defaultLadleWeightTon;
    minimumTapDurationMins = testCase.TestData.defaultMinimumTapDurationMins;
    tapholeOpenDegC = testCase.TestData.tapholeOpenDegC;
    tolTon = testCase.TestData.tolTon;

    inputs = testCase.TestData.defaultInputs;
    
    durationEast1Mins = minimumTapDurationMins - 1; % shouldn't be counted because < minimumTapDurationMins
    durationCenter1Mins = 30;
    durationWest1Mins = 50;

    durationEast2Mins = 30;
    durationCenter2Mins = 40;
    durationWest2Mins = 11;

    tapStartIndexEast1 = 100;
    tapStartIndexCenter1 = 200;
    tapStartIndexWest1 = 300;

    tapStartIndexEast2 = 400;
    tapStartIndexCenter2 = 500;
    tapStartIndexWest2 = 600;
   

    
    
    inputs.MatteTap1ThermalCameraTemp(tapStartIndexEast1:tapStartIndexEast1+durationEast1Mins- 1) = tapholeOpenDegC;
    inputs.MatteTap2ThermalCameraTemp(tapStartIndexCenter1:tapStartIndexCenter1+durationCenter1Mins- 1) = tapholeOpenDegC;
    inputs.MatteTap3ThermalCameraTemp(tapStartIndexWest1:tapStartIndexWest1+durationWest1Mins- 1) = tapholeOpenDegC;

    inputs.MatteTap1ThermalCameraTemp(tapStartIndexEast2:tapStartIndexEast2+durationEast2Mins- 1) = tapholeOpenDegC;
    inputs.MatteTap2ThermalCameraTemp(tapStartIndexCenter2:tapStartIndexCenter2+durationCenter2Mins- 1) = tapholeOpenDegC;
    inputs.MatteTap3ThermalCameraTemp(tapStartIndexWest2:tapStartIndexWest2+durationWest2Mins- 1) = tapholeOpenDegC;


    matteTapRatesTonPerHr = calcMatteTapRatesHybridDeployment(inputs, defaultLadleWeightTon, minimumTapDurationMins, testCase.TestData.executionPeriodMins);
    totalTappedActualTon = sum(matteTapRatesTonPerHr)/60;

    nValidTappings = 5;
    totalTappedExpectedTon = defaultLadleWeightTon * nValidTappings;
    verifyLessThan(testCase, abs(totalTappedActualTon - totalTappedExpectedTon), tolTon)
   
    
end

function testLadlesAndThermalCameras(testCase)
    defaultLadleWeightTon = testCase.TestData.defaultLadleWeightTon;
    minimumTapDurationMins = testCase.TestData.defaultMinimumTapDurationMins;
    tapholeOpenDegC = testCase.TestData.tapholeOpenDegC;
    tolTon = testCase.TestData.tolTon;
    inputs = testCase.TestData.defaultInputs;

    % measured
    ladleEastMeasuredTon = 33;
    ladleCenterMeasuredTon = 46;
    ladleWestMeasuredTon = 50;

    durationEastMeasuredMins = 20;
    durationCenterMeasuredMins = 30;
    durationWestMeasuredMins = 50;

    % estimated
    durationEastEstimatedMins = 30;
    durationCenterEstimatedMins = 40;
    durationWestEstimatedMins = minimumTapDurationMins-1; % invalid
    nValidEstimatedTappings = (durationEastEstimatedMins > minimumTapDurationMins) + (durationCenterEstimatedMins > minimumTapDurationMins) + (durationWestEstimatedMins > minimumTapDurationMins);


    tapStartIndexEastMeasured = 100;
    tapStartIndexCenterMeasured = 200;
    tapStartIndexWestMeasured = 300;

    tapStartIndexEastEstimated = 400;
    tapStartIndexCenterEstimated = 500;
    tapStartIndexWestEstimated = 600;


    inputs.MatteTappedLadleEastTon(tapStartIndexEastMeasured:end) = ladleEastMeasuredTon;
    inputs.MatteTappedLadleCenterTon(tapStartIndexCenterMeasured:end) = ladleCenterMeasuredTon;
    inputs.MatteTappedLadleWestTon(tapStartIndexWestMeasured:end) = ladleWestMeasuredTon;

    inputs.MatteTapDurationEastSecs(tapStartIndexEastMeasured:end) = durationEastMeasuredMins * 60;
    inputs.MatteTapDurationCenterSecs(tapStartIndexCenterMeasured:end) = durationCenterMeasuredMins * 60;
    inputs.MatteTapDurationWestSecs(tapStartIndexWestMeasured:end) = durationWestMeasuredMins * 60;

    % set thermal cameras to register the estimated results and some
    %   measured results. Thermal camera temperatures before the last measured results
    %   should not affect the results
    
    delayMins = 2; % simulate a dealy between the end of the tapping based on measurement and the thermal camera reading going below threshold
    inputs.MatteTap3ThermalCameraTemp(tapStartIndexWestMeasured:tapStartIndexWestMeasured+durationWestMeasuredMins-1+delayMins) = tapholeOpenDegC;

    inputs.MatteTap1ThermalCameraTemp(tapStartIndexEastEstimated:tapStartIndexEastEstimated+durationEastEstimatedMins- 1) = tapholeOpenDegC;
    inputs.MatteTap2ThermalCameraTemp(tapStartIndexCenterEstimated:tapStartIndexCenterEstimated+durationCenterEstimatedMins- 1) = tapholeOpenDegC;
    inputs.MatteTap3ThermalCameraTemp(tapStartIndexWestEstimated:tapStartIndexWestEstimated+durationWestEstimatedMins- 1) = tapholeOpenDegC;

    % actual
    matteTapRatesTonPerHr = calcMatteTapRatesHybridDeployment(inputs, defaultLadleWeightTon, minimumTapDurationMins, testCase.TestData.executionPeriodMins);
    totalTappedActualTon = sum(matteTapRatesTonPerHr)/60;

    % expected
    totalTappedExpectedTon = ladleEastMeasuredTon + ladleCenterMeasuredTon + ladleWestMeasuredTon +  defaultLadleWeightTon * nValidEstimatedTappings;
    verifyLessThan(testCase, abs(totalTappedActualTon - totalTappedExpectedTon), tolTon)
end

function testThermalCamerasOnlyDeployment(testCase)
    defaultLadleWeightTon = testCase.TestData.defaultLadleWeightTon;
    minimumTapDurationMins = testCase.TestData.defaultMinimumTapDurationMins;
    tapholeOpenDegC = testCase.TestData.tapholeOpenDegC;
    tolTon = testCase.TestData.tolTon;
    executionPeriodMins = testCase.TestData.executionPeriodMins;
    dataWindowMins =  testCase.TestData.dataWindowMins;


    inputs = testCase.TestData.defaultInputs;
    % trim inputs so it has a multiple of 'executionPeriodMins' entries
    inputs = inputs(1:end-mod(height(inputs), executionPeriodMins), :);
    
    durationEast1Mins = 30;
    durationCenter1Mins = 30;
    durationWest1Mins = 50;

    durationEast2Mins = 30;
    durationCenter2Mins = 40;
    durationWest2Mins = minimumTapDurationMins;

    tapStartIndexEast1 = dataWindowMins+100;
    tapStartIndexCenter1 = dataWindowMins+200;
    tapStartIndexWest1 = dataWindowMins+300;

    tapStartIndexEast2 =  dataWindowMins+400;
    tapStartIndexCenter2 =  dataWindowMins+500;
    tapStartIndexWest2 =  dataWindowMins+600;
   

    
    
    inputs.MatteTap1ThermalCameraTemp(tapStartIndexEast1:tapStartIndexEast1+durationEast1Mins- 1) = tapholeOpenDegC;
    inputs.MatteTap2ThermalCameraTemp(tapStartIndexCenter1:tapStartIndexCenter1+durationCenter1Mins- 1) = tapholeOpenDegC;
    inputs.MatteTap3ThermalCameraTemp(tapStartIndexWest1:tapStartIndexWest1+durationWest1Mins- 1) = tapholeOpenDegC;

    inputs.MatteTap1ThermalCameraTemp(tapStartIndexEast2:tapStartIndexEast2+durationEast2Mins- 1) = tapholeOpenDegC;
    inputs.MatteTap2ThermalCameraTemp(tapStartIndexCenter2:tapStartIndexCenter2+durationCenter2Mins- 1) = tapholeOpenDegC;
    inputs.MatteTap3ThermalCameraTemp(tapStartIndexWest2:tapStartIndexWest2+durationWest2Mins- 1) = tapholeOpenDegC;    
    
    matteTapRatesTonPerHr = NaN(height(inputs), 1);
    matteTapRatesTonPerHr(1:dataWindowMins-executionPeriodMins) = 0;
    nExecutionPeriods = (height(inputs) - dataWindowMins)/executionPeriodMins;
    for i = 0 : nExecutionPeriods
        inputWindow = inputs(1+i*executionPeriodMins : dataWindowMins+i*executionPeriodMins, :);
        tapRatesTemp = calcMatteTapRatesHybridDeployment(inputWindow, defaultLadleWeightTon, minimumTapDurationMins, testCase.TestData.executionPeriodMins);
        matteTapRatesTonPerHr(1+dataWindowMins+(i-1)*executionPeriodMins : dataWindowMins+i*executionPeriodMins) = tapRatesTemp(end-(executionPeriodMins-1) : end);
    end
    totalTappedActualTon = sum(matteTapRatesTonPerHr)/60;

    nValidTappings = 6;
    totalTappedExpectedTon = defaultLadleWeightTon * nValidTappings;
    verifyLessThan(testCase, abs(totalTappedActualTon - totalTappedExpectedTon), tolTon)
end

function testThermalCamerasEdgeCaseDeployment(testCase)
    defaultLadleWeightTon = testCase.TestData.defaultLadleWeightTon;
    minimumTapDurationMins = testCase.TestData.defaultMinimumTapDurationMins;
    tapholeOpenDegC = testCase.TestData.tapholeOpenDegC;
    tolTon = testCase.TestData.tolTon;
    executionPeriodMins = testCase.TestData.executionPeriodMins;
    dataWindowMins =  testCase.TestData.dataWindowMins;


    inputs = testCase.TestData.defaultInputs;
    % trim inputs so it has a multiple of 'executionPeriodMins' entries
    inputs = inputs(1:end-mod(height(inputs), executionPeriodMins), :);
    
    durationEast1Mins = 20; 
    durationCenter1Mins = 30; 
    durationWest1Mins = 50; 

    durationEast2Mins = 30;
    durationCenter2Mins = 70; % % tapping spanning 3 windows
    durationWest2Mins = minimumTapDurationMins;

    tapStartIndexEast1 = dataWindowMins-executionPeriodMins+1; % first value in window
    tapStartIndexCenter1 = dataWindowMins + 3*executionPeriodMins;  % last value in window
    tapStartIndexWest1 = dataWindowMins+7*executionPeriodMins - 2; % 2nd last value in window

    tapStartIndexEast2 =  dataWindowMins + 11*executionPeriodMins + 2; % 2nd value in window
    tapStartIndexCenter2 =  dataWindowMins+500;
    tapStartIndexWest2 =  dataWindowMins+600;
   

    
    
    inputs.MatteTap1ThermalCameraTemp(tapStartIndexEast1:tapStartIndexEast1+durationEast1Mins- 1) = tapholeOpenDegC;
    inputs.MatteTap2ThermalCameraTemp(tapStartIndexCenter1:tapStartIndexCenter1+durationCenter1Mins- 1) = tapholeOpenDegC;
    inputs.MatteTap3ThermalCameraTemp(tapStartIndexWest1:tapStartIndexWest1+durationWest1Mins- 1) = tapholeOpenDegC;

    inputs.MatteTap1ThermalCameraTemp(tapStartIndexEast2:tapStartIndexEast2+durationEast2Mins- 1) = tapholeOpenDegC;
    inputs.MatteTap2ThermalCameraTemp(tapStartIndexCenter2:tapStartIndexCenter2+durationCenter2Mins- 1) = tapholeOpenDegC;
    inputs.MatteTap3ThermalCameraTemp(tapStartIndexWest2:tapStartIndexWest2+durationWest2Mins- 1) = tapholeOpenDegC;    
    
    matteTapRatesTonPerHr = NaN(height(inputs), 1);
    matteTapRatesTonPerHr(1:dataWindowMins-executionPeriodMins) = 0;
    nExecutionPeriods = (height(inputs) - dataWindowMins)/executionPeriodMins;
    for i = 0 : nExecutionPeriods
        inputWindow = inputs(1+i*executionPeriodMins : dataWindowMins+i*executionPeriodMins, :);
        tapRatesTemp = calcMatteTapRatesHybridDeployment(inputWindow, defaultLadleWeightTon, minimumTapDurationMins, testCase.TestData.executionPeriodMins);
        matteTapRatesTonPerHr(1+dataWindowMins+(i-1)*executionPeriodMins : dataWindowMins+i*executionPeriodMins) = tapRatesTemp(end-(executionPeriodMins-1) : end);
    end
    totalTappedActualTon = sum(matteTapRatesTonPerHr)/60;

    nValidTappings = 6;
    totalTappedExpectedTon = defaultLadleWeightTon * nValidTappings;
    verifyLessThan(testCase, abs(totalTappedActualTon - totalTappedExpectedTon), tolTon)
end



