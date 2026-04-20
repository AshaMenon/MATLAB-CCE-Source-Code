
%%
windowSize = 12*60; % in minutes
calcFreq = 30;
ExecutionFrequencyParam = 30;% in minutes
sampleRate = 1; % in minutes
dataPoints = windowSize/sampleRate;
dt = minutes(1);
parameters.SoundingTimeMin = 6;
parameters.SoundingTimeMax = 7;

for currentIdx = dataPoints:ExecutionFrequencyParam/sampleRate:height(polSILdata)
    referenceTime = polSILdata.Timestamp(currentIdx);

    parameters.SimulatedMatteLevel = polSILdata.SimulatedMatteLevel(currentIdx);
    parameters.SimulatedSlagLevel = polSILdata.SimulatedSlagLevel(currentIdx);
    parameters.SimulatedBlackTopLevel = polSILdata.SimulatedBlackTopLevel(currentIdx);

    startTime = referenceTime - minutes(windowSize);
    endTime = referenceTime;
    dataSet = polSILdata(and(polSILdata.Timestamp >= startTime, polSILdata.Timestamp <= endTime), :);

    % Find Reset Dates
    resetSoundingFlag = sum((parameters.SoundingTimeMin < hour(polSILdata.Timestamp)) & ...
        (parameters.SoundingTimeMax < hour(polSILdata.Timestamp))) > 0;

    noAvailableSimValues = isnan(parameters.SimulatedMatteLevel) ||...
        isnan(parameters.SimulatedSlagLevel) || ...
        isnan(parameters.SimulatedBlackTopLevel);

    if resetSoundingFlag || noAvailableSimValues %Change this to && if no reset is wanted

        if sum(dataSet.CombinedValidDeltaSounding) > 0
            % find last sounding time
            initialConditionIdx = find(dataSet.CombinedValidDeltaSounding, 1, 'first');
        else
            changeInHeight = abs(diff(dataSet.NewMeanMattePlusBuildupThickness + dataSet.NewMeanSlagThickness + dataSet.NewMeanConcThickness ));
            newSoundingValueIdx = [0; changeInHeight] > 0.5;

            initialConditionIdx = find(newSoundingValueIdx, 1, 'first');

            warning("No Valid Sounding found, first sounding of data period used")
        end

        initialConditionsTimes = [initialConditionsTimes; dataSet.Timestamp(initialConditionIdx)];


    else
        %Set start time of dataset
        simStartDateTime = lastSimValDateTime;

        % Use model values
        heightInitialMatte = parameters.SimulatedSlagLevel;
        heightInitialSlag = parameters.SimulatedSlagLevel;
        heightInitialBlackTop = parameters.SimulatedBlackTopLevel;

    end


end

%%
ax1 = subplot(3,1,1);
hold on;
plot(outputsSIL.Timestamp, outputsSIL.SimulatedMatteLevel)
plot(polSILdata.Timestamp(polSILdata.CombinedValidDeltaSounding == true).*100, polSILdata.NewMeanMattePlusBuildupThickness(polSILdata.CombinedValidDeltaSounding == true))
ylabel("Matte Level (m)")
legend({"SimulatedMatteLevel", "NewMeanMattePlusBuildupThickness"})

ax2 = subplot(3,1,2);
hold on;
plot(outputsSIL.Timestamp, outputsSIL.SimulatedSlagLevel)
plot(polSILdata.Timestamp(polSILdata.CombinedValidDeltaSounding == true).*100, polSILdata.NewMeanSlagThickness(polSILdata.CombinedValidDeltaSounding == true))
ylabel("Slag Level (m)")
legend({"SimulatedSlagLevel", "NewMeanSlagThickness"})

ax3 = subplot(3,1,3);
hold on;
plot(outputsSIL.Timestamp, outputsSIL.SimulatedBlackTopLevel)
plot(polSILdata.Timestamp(polSILdata.CombinedValidDeltaSounding == true).*100, polSILdata.NewMeanConcThickness(polSILdata.CombinedValidDeltaSounding == true))
ylabel("Conc Level (m)")
legend({"SimulatedBlackTopLevel", "NewMeanConcThickness"})

linkaxes([ax1, ax2, ax3], 'x'); % Link the x-axes only