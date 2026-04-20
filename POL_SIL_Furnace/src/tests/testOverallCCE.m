function testOverallCCE()
%TESTOVERALLCCE will run our CCE wrappers in the exepected order and
%execution frequencies with the purpose of testing the interaction and
%validating the outputs

% Load and filter data to be used for simulation
polSILdata = readtable("/../../data/POL_SIL_CCE_Data_20250109_2024DecData.xlsx");
polSILdata = filterByDateTime(polSILdata, "01-Dec-2024 15:00:00", "30-Jan-2025 23:59:00");
polSILdataCompressed = combineSoundingsExample(readtable("/../../Compressed_POL_SIL_CCE_Data_20250109_2024DecData.xlsx")); %importfile1("/../../Compressed_Soundings_20241125_2024Aug.xlsx", "Sheet1", [2, Inf]);
polSILdataCompressed = filterByDateTime(polSILdataCompressed, "01-Dec-2024 15:00:00", "30-Jan-2025 23:59:00");

%% Run Matte Fall Fraction testing
parametersMF = loadMatteFallParameters();
dataMF = polSILdata(:, parametersMF.tags);
outputsMF = simulateCCE(parametersMF, dataMF, ...
    @(input, parameters)cceCalcMatteFallFractionsAveWrapper(input, parameters));
polSILdata = outerjoin(polSILdata, outputsMF, 'Keys', ...
    {'Timestamp'}, 'MergeKeys', true);
plot(outputsMF.Timestamp, outputsMF.MatteFallFraction, 'x')

%% Run Matte Tap Rate testing
parametersMTR = loadMatteTapRatesParameters();
dataMTR = polSILdata(:, parametersMTR.tags);
dataMTR{:, parametersMTR.ladleTags} = 0;
outputsMTR = simulateCCE(parametersMTR, dataMTR, ...
    @(input, parameters)cceCalcMatteTapRatesHybridWrapper(input, parameters));
plot(outputsMTR.Timestamp, outputsMTR.MatteTapRatesTonPerHr)
polSILdata = outerjoin(polSILdata, outputsMTR, 'Keys', ...
    {'Timestamp'}, 'MergeKeys', true);

%% Valid Sounding testing
parametersSV = loadSoundingValuesParameters();
dataSV = timetable2table(polSILdataCompressed);
dataSV = dataSV(:, parametersSV.tags);
outputsSV = simulateCCE(parametersSV, dataSV, ...
    @(input, parameters)cceCalcSoundingValuesWrapper(input, parameters));
polSILdata = outerjoin(polSILdata, outputsSV, 'Keys', ...
    {'Timestamp'}, 'MergeKeys', true);
plot(outputsSV.Timestamp, outputsSV.CombinedValidDeltaSounding, 'x')

%% Run Slag Tap Rate testing
parametersSTR = loadSlagTapRatesParameters();
dataSTR = polSILdata(:, parametersSTR.tags);
outputsSTR = simulateCCE(parametersSTR, dataSTR, ...
    @(input, parameters)cceCalcSlagTapRatesWrapper(input, parameters));
polSILdata = outerjoin(polSILdata, outputsSTR, 'Keys', ...
    {'Timestamp'}, 'MergeKeys', true);
plot(outputsSTR.Timestamp, outputsSTR.SlagTapRates)
plot(outputsSTR.Timestamp, outputsSTR.CalibrationFactor, 'x')
ylabel({'CalibrationFactor'})

%% Run Polokwane SIL testing
parametersSIL = loadPolokwaneSILParameters();
dataSIL = polSILdata(:, parametersSIL.tags);
dataSIL(:, ["SimulatedMatteLevel_In", "SimulatedSlagLevel_In", "SimulatedBlackTopLevel_In"]) = {NaN};
outputsSIL = simulateSILCCE(parametersSIL, dataSIL, ...
    @(input, parameters)ccePolokwaneSILWrapper(input, parameters));
polSILdata = outerjoin(polSILdata, outputsSIL, 'Keys', ...
    {'Timestamp'}, 'MergeKeys', true);

ax1 = subplot(3,1,1);
hold on;
plot(polSILdata.Timestamp, polSILdata.SimulatedMatteLevel*100)
plot(polSILdata.Timestamp(polSILdata.CombinedValidDeltaSounding == true), polSILdata.NewMeanMattePlusBuildupThickness(polSILdata.CombinedValidDeltaSounding == true))
xline(polSILdata.Timestamp(polSILdata.CombinedValidDeltaSounding == 1), 'Color', [0.8,0.8,0.8])
xline(polSILdata.Timestamp(polSILdata.IsReset == 1),'g')
ylabel("Matte Level (cm)")
legend({"SimulatedMatteLevel", "NewMeanMattePlusBuildupThickness"})

ax2 = subplot(3,1,2);
hold on;
plot(polSILdata.Timestamp, polSILdata.SimulatedSlagLevel*100)
plot(polSILdata.Timestamp(polSILdata.CombinedValidDeltaSounding == true), polSILdata.NewMeanSlagThickness(polSILdata.CombinedValidDeltaSounding == true))
xline(polSILdata.Timestamp(polSILdata.CombinedValidDeltaSounding == 1), 'Color', [0.8,0.8,0.8])
xline(polSILdata.Timestamp(polSILdata.IsReset == 1),'g')
ylabel("Slag Level (cm)")
legend({"SimulatedSlagLevel", "NewMeanSlagThickness"})

ax3 = subplot(3,1,3);
hold on;
plot(polSILdata.Timestamp, polSILdata.SimulatedConcentrateLevel*100)
plot(polSILdata.Timestamp(polSILdata.CombinedValidDeltaSounding == true), polSILdata.NewMeanConcThickness(polSILdata.CombinedValidDeltaSounding == true))
xline(polSILdata.Timestamp(polSILdata.CombinedValidDeltaSounding == 1), 'Color', [0.8,0.8,0.8])
xline(polSILdata.Timestamp(polSILdata.IsReset == 1),'g')
ylabel("Conc Level (cm)")
legend({"SimulatedConcentrateLevel", "NewMeanConcThickness"})

linkaxes([ax1, ax2, ax3], 'x'); % Link the x-axes only
end

function outputs = simulateCCE(parameters, data, funHandle)
% Simulate in increments of ExecutionFrequencyParam using data of length relativeTimeRange
outputs = table();
execFreqDuration = minutes(parameters.ExecutionFrequencyParam);
timeRangeDuration = minutes(parameters.relativeTimeRange);
startDate = dateshift(data.Timestamp(1)+timeRangeDuration, 'end', 'minute');
endDate = dateshift(data.Timestamp(end), 'end', 'minute');
for iCurrent = startDate:execFreqDuration:endDate
    disp(char(iCurrent - timeRangeDuration) + " to " + char(iCurrent) + " ("+ char(endDate) + ")")

    parameters.OutputTime = datestr(iCurrent - hours(2), 'yyyy-mm-ddTHH:MM:SS.fffZ');

    currentData = filterByDateTime(data, iCurrent - timeRangeDuration, iCurrent);
    inputs = table2struct(currentData);
    [out, ~] = funHandle(parameters, inputs);
    outputs = [outputs; struct2table(out)];
end
end

function outputs = simulateSILCCE(parameters, data, funHandle)
% Simulate in increments of ExecutionFrequencyParam using data of length relativeTimeRange
outputs = table();
execFreqDuration = minutes(parameters.ExecutionFrequencyParam);
timeRangeDuration = minutes(parameters.relativeTimeRange);
startDate = data.Timestamp(1)+timeRangeDuration;
endDate = data.Timestamp(end);
for iCurrent = startDate:execFreqDuration:endDate
    disp(char(iCurrent - timeRangeDuration) + " to " + char(iCurrent) + " ("+ char(endDate) + ")")

    parameters.OutputTime = datestr(iCurrent - hours(2), 'yyyy-mm-ddTHH:MM:SS.fffZ');

    currentData = filterByDateTime(data, iCurrent - timeRangeDuration, iCurrent);
    inputs = table2struct(currentData);
    [out, ~] = funHandle(parameters, inputs);
    outTable = struct2table(out);
    
    [isMatch, rowIndex] = ismember(data.Timestamp, outTable.Timestamp);

    data{isMatch, {'SimulatedMatteLevel_In', 'SimulatedSlagLevel_In' ...
        'SimulatedConcentrateLevel_In'}} = outTable{rowIndex(isMatch), {'SimulatedMatteLevel', 'SimulatedSlagLevel', 'SimulatedConcentrateLevel'}};

    outputs = [outputs; outTable];

end
end