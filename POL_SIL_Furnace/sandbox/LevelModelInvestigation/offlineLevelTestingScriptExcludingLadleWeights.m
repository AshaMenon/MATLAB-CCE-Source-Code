%% Example to run polokwane SIL funace model and evaluate outputs

% Load data
data = readtable("data/POL_SIL_Data_20241023_2024AugData.xlsx", "Sheet", "Sheet1");
%% Remove ladle weights for testing
data.MatteTappedLadleEastTon(:) = 0;
data.MatteTappedLadleCenterTon(:) = 0;
data.MatteTappedLadleWestTon(:) = 0;
%%
nFeedSamples = 3;
feedDelayHrs = 24;
data.MatteFallFraction = calcMatteFallFractionsAve(data, nFeedSamples, feedDelayHrs);

%% Setup Parameters
parameters = struct;
parameters.SlagConveyorMoisture = 0.2;
parameters.SteamEvapPercentage = 0.09;
parameters.cpWater = 4.184; %MJ/ton
parameters.hEvapWater =2260; %MJ/ton
parameters.cpDeltaTSlag = 2379;	%MJ/ton slag
parameters.MATTE_DENSITY_TON_PER_M3 = 4.5;
parameters.SLAG_DENSITY_TON_PER_M3 = 2.8;
parameters.CONC_DENSITY_TON_PER_M3 = 1.2;
parameters.BATH_AREA_M2 = 31.75 * 9.49;
parameters.OffGasFraction = 0.0015;
parameters.MoistureCalibrationPeriod = 2.5; % Period in days over which
% to perform the slag moisture fitting.

parameters.simMode = "simulation";
parameters.LogName = fullfile(getpref('PolokwaneSIL', 'DataFolder'), "logs", "LevelModel.log");
parameters.CalculationID = 'TestLM';
parameters.LogLevel = 255;
parameters.CalculationName = 'TestLevelModel';
parameters.OutputTime = "2024-10-09T08:00:01.000Z";
parameters.SlagConveyorMoisture = 0.2;
parameters.TappingRatePerOpenTapholeTonPerHr  = 1.4*60;
parameters.ExecutionFrequencyParam = 30; % This parameter will need to be renamed (simulation window to return will be more accurate)

parameters.SoundingTimeMin = 6;
parameters.SoundingTimeMax = 7;
parameters.SimulatedMatteLevelLastValue= NaN;
parameters.SimulatedSlagLevelLastValue = NaN;
parameters.SimulatedBlackTopLevelLastValue = NaN;

parameter.lastSimTimestamp = NaN; %TODO incorporate in time - think about this


%%
windowSize = 12*60; % in minutes
calcFreq = parameters.ExecutionFrequencyParam; % in minutes
sampleRate = 1; % in minutes
dataPoints = windowSize/sampleRate;
dt = minutes(1);

dataSim = table2timetable(data);
dataSim = removevars(dataSim, ["DiverterIsToConveyorEast","DiverterIsToConveyorCenter","DiverterIsToConveyorWest"]);

%%
dataSim = retime(dataSim,'regular','linear','TimeStep',dt);
dataSim.SimulatedMatteLevel = NaN(height(dataSim),1);
dataSim.SimulatedSlagLevel = NaN(height(dataSim),1);
dataSim.SimulatedBlackTopLevel = NaN(height(dataSim),1);
dataSim.SimulatedTotalBathLevel = NaN(height(dataSim),1);
dataSim.SimulatedMatteMass = NaN(height(dataSim),1);
dataSim.SimulatedSlagMass = NaN(height(dataSim),1);
dataSim.SimulatedBlackTopMass = NaN(height(dataSim),1);
dataSim.SimulatedTotalBathLevel = NaN(height(dataSim),1);

dataTblIdx = logical('true');

for currentIdx = dataPoints:parameters.ExecutionFrequencyParam/sampleRate:height(data)
    referenceTime = data.Timestamp(currentIdx)

    parameters.SimulatedMatteLevelLastValue= dataSim.SimulatedMatteLevel(find(dataTblIdx,1, 'last'));
    parameters.SimulatedSlagLevelLastValue = dataSim.SimulatedSlagLevel(find(dataTblIdx,1, 'last'));
    parameters.SimulatedBlackTopLevelLastValue = dataSim.SimulatedBlackTopLevel(find(dataTblIdx,1, 'last'));

    startTime = referenceTime - minutes(windowSize);
    endTime = referenceTime;
    dataSet = data(and(data.Timestamp >= startTime, data.Timestamp <= endTime), :);
    dataSet.isValidMatte = findValidSounding(dataSet.MatteThickness + dataSet.BuildUpThickness, 3);
    dataSet.isValidSlag = findValidSounding(dataSet.SlagThickness, 20); 
    dataSet.isValidConc = findValidSounding(dataSet.ConcThickness, 35);
    dataSet.combinedValidSounding = dataSet.isValidMatte & dataSet.isValidSlag & dataSet.isValidConc;
    simStopDateTime = dataSet.Timestamp(end)
    simStopTime = seconds(dataSet.Timestamp(end) - dataSet.Timestamp(1));

    [slInputs, slParameters, simStartDateTime] = prepareDataForSim(dataSet, parameters);

    simConfig = Simulink.SimulationInput('polokwaneSIL');

    %fieldnames to variables
    varNames = fieldnames(slParameters);
    for v = 1:numel(varNames)
        assignin("base", varNames{v}, slParameters.(varNames{v}))
        simConfig = setVariable(simConfig, varNames{v}, slParameters.(varNames{v}));
    end

    %Set external inputs

    simInputs = Simulink.SimulationData.Dataset;
    simInputs = simInputs.addElement(slInputs,'in1_signal');
    assignin("base", "slInputs", simInputs)

    simConfig = simConfig.setModelParameter('StopTime', string(simStopTime));

    simOut = sim(simConfig);

    fullTimestamp = seconds(simOut.tout) + simStartDateTime;
    origTimestamp = dataSet.Timestamp;
    fullTM = simOut.logsout.extractTimetable;
    fullTM = retime(fullTM, 'regular','linear','TimeStep',dt);
    fullTM.Timestamp =  fullTM.Time + simStartDateTime;

    returnTimeStart = endTime - minutes(calcFreq);

    returnIdx = and(fullTM.Timestamp >= returnTimeStart, fullTM.Timestamp <= endTime);
    dataTblIdx = ismember(dataSim.Timestamp, fullTM.Timestamp(returnIdx));

    dataSim.SimulatedMatteLevel(dataTblIdx) = fullTM{returnIdx, 'height_matte'};
    dataSim.SimulatedSlagLevel(dataTblIdx)  = fullTM{returnIdx, 'height_slag'};
    dataSim.SimulatedBlackTopLevel(dataTblIdx)  = fullTM{returnIdx, 'height_black_top'};
    dataSim.SimulatedTotalBathLevel(dataTblIdx)  = fullTM{returnIdx, 'height_total'};
    dataSim.SimulatedMatteMass(dataTblIdx)  = fullTM{returnIdx, 'm_matte'};
    dataSim.SimulatedSlagMass(dataTblIdx)  = fullTM{returnIdx, 'm_slag'};
    dataSim.SimulatedBlackTopMass(dataTblIdx)  = fullTM{returnIdx, 'm_black_top'};
    dataSim.SimulatedTotalBathLevel(dataTblIdx)  = fullTM{returnIdx, 'm_total'};

end

%%
matteSounding = replaceHoldValuesWithInterp(data.MatteThickness + data.BuildUpThickness);
slagSounding = replaceHoldValuesWithInterp(data.SlagThickness);
concSounding = replaceHoldValuesWithInterp(data.ConcThickness);

totalBathSounding = matteSounding + slagSounding + concSounding;

%% Compare simulation results to levels measured by sounding
% matte

figure
subplot(2,2,1)
plot(data.Timestamp, data.MatteThickness + data.BuildUpThickness)
hold on
% plot(data.Timestamp, matteSounding)
plot(dataSim.Timestamp, dataSim.SimulatedMatteLevel * 100)
hold off
title("Matte height (cm)")
legend(["Measured", "Model"])

% slag
subplot(2,2,2)
plot(data.Timestamp, data.SlagThickness)
hold on
% plot(data.Timestamp, slagSounding)
plot(dataSim.Timestamp, dataSim.SimulatedSlagLevel * 100)
hold off
title("Slag height (cm)")
legend(["Measured", "Model"])

% concentrate
subplot(2,2,3)
plot(data.Timestamp, data.ConcThickness)
hold on
% plot(data.Timestamp, concSounding)
plot(dataSim.Timestamp, dataSim.SimulatedBlackTopLevel * 100)
hold off
title("Concentrate height (cm)")
legend(["Measured", "Model"])

% Total material level
subplot(2,2,4)
plot(data.Timestamp, data.MatteThickness + data.BuildUpThickness + data.SlagThickness + data.ConcThickness);
hold on
% plot(data.Timestamp, totalBathSounding)
plot(dataSim.Timestamp, (dataSim.SimulatedMatteLevel + dataSim.SimulatedSlagLevel + dataSim.SimulatedBlackTopLevel) * 100)
hold off
title("Total material height (cm)")
legend(["Measured", "Interpolated Measurements" "Model"])

%%
% corrplot(data)
matteCor = corr(data.MatteThickness + data.BuildUpThickness, dataSim.SimulatedMatteLevel * 100, 'rows', 'complete')
totalBathCor = corr(data.MatteThickness + data.BuildUpThickness + data.SlagThickness + data.ConcThickness,...
    (dataSim.SimulatedMatteLevel + dataSim.SimulatedSlagLevel + dataSim.SimulatedBlackTopLevel) * 100, 'rows', 'complete')
concentrateCor = corr(data.ConcThickness, dataSim.SimulatedBlackTopLevel * 100, 'rows', 'complete')


%%
matteErr = matteSounding - (dataSim.SimulatedMatteLevel * 100);
totalBathErr = (totalBathSounding)...
    - (dataSim.SimulatedMatteLevel + dataSim.SimulatedSlagLevel + dataSim.SimulatedBlackTopLevel)*100;
slagErr = slagSounding - dataSim.SimulatedSlagLevel*100;
concentrateErr = concSounding - dataSim.SimulatedBlackTopLevel*100;
%%
% matte

figure
subplot(2,2,1)
plot(data.Timestamp, matteErr)
hold off
title("Matte height (cm)")
legend(["Measured", "Model"])

% slag
subplot(2,2,2)
plot(data.Timestamp, slagErr)
title("Slag height (cm)")
legend(["Measured", "Model"])

% concentrate
subplot(2,2,3)
plot(data.Timestamp, concentrateErr)
title("Concentrate height (cm)")
legend(["Measured", "Model"])

% Total material level
subplot(2,2,4)
plot(data.Timestamp, totalBathErr);
title("Total material height (cm)")
legend(["Measured", "Model"])

%%
matteRMSE = rmse((dataSim.SimulatedMatteLevel * 100), data.MatteThickness + data.BuildUpThickness, "omitnan")
totalBathRMSE = rmse(data.MatteThickness + data.BuildUpThickness + data.SlagThickness + data.ConcThickness,...
    (dataSim.SimulatedMatteLevel + dataSim.SimulatedSlagLevel + dataSim.SimulatedBlackTopLevel)*100, "omitnan")
slagRMSE = rmse(data.SlagThickness, dataSim.SimulatedSlagLevel*100, "omitnan")
concentrateRMSE = rmse(data.ConcThickness, dataSim.SimulatedBlackTopLevel*100, "omitnan")

