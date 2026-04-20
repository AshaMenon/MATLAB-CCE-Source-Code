function [outputs, errorCode] = cceCalcSoundingValuesWrapper(parameters, inputs)

% Create log
logFile = parameters.LogName;
calculationID = parameters.CalculationID;
logLevel = parameters.LogLevel;
calculationName = parameters.CalculationName;
log = CCELogger(logFile, calculationName, calculationID, logLevel);
errorCode = CalculationErrorState.Good;

newOutTime = strrep(parameters.OutputTime, "T", " ");
newOutTime = extractBefore(newOutTime, ".");

parameters.exeTime = datetime(newOutTime) + hours(2); % Convert from UTC

log.logInfo('--------------------------------------------------------------')
log.logInfo('Start sounding calculation at execution time %s', string(parameters.exeTime))

try
    % [Extract inputs]
    % Data format checking and converting
    dataTT = combineSoundings(inputs);
    dataTT = convertInputs(dataTT, log);

    outputs = calcSoundingValues(dataTT, parameters);

    if any(structfun(@isempty, outputs))
        outputs = assignNans();
        outputs.Timestamp = parameters.exeTime;
    end

catch err
    % Unhandled error - log, assign nans, set calc state
    outputs = assignNans();
    outputs.Timestamp = parameters.exeTime;
    msg = [err.stack(1).name, ' Line ',...
        num2str(err.stack(1).line), '. ', err.message];
    log.logError(msg);
    if errorCode == CalculationErrorState.Good || isempty(errorCode)
        errorCode = CalculationErrorState.CalcFailed;
    end
end

end

function [inputs, referenceTime] = convertInputs(inputs, log)
%CONVERTINPUTS Converts inputs to a time table,
%finds the variable that contains
%timestamps, and assigns that to REFERENCETIME

if isa(inputs, 'struct')
    inputs = struct2table(inputs);
    timeKey = contains(inputs.Properties.VariableNames, 'Timestamp', 'IgnoreCase',true);
    timeName = find(timeKey, 1, "first");
    inputs.Timestamp = inputs{:,timeName};
    referenceTime = inputs.Timestamp(1);
    log.logInfo(['Timestamp ID changed from ' inputs.Properties.VariableNames{timeName}])
    %inputs(:,timeName) = [];
    inputs = table2timetable(inputs);
elseif isa(inputs, 'table')
    timeKey = contains(inputs.Properties.VariableNames, 'Timestamp', 'IgnoreCase',true);
    timeName = find(timeKey, 1, "first");
    inputs.Timestamp = inputs{:,timeName};
    referenceTime = inputs.Timestamp(1);
    log.logInfo(['Timestamp ID changed from ' inputs.Properties.VariableNames{timeName}])
    inputs(:,timeName) = [];
    inputs = table2timetable(inputs);
elseif ~isa(inputs, 'timetable')
    error('calcSoundingValues: "inputs" is not a struct.')
end
end

function outputs = assignNans()
%ASSIGNNANS creates an output structure that contains NANS only, written to
%the input timestamp

outputs = struct();
outputs.NewMeanMattePlusBuildupThickness = nan;
outputs.NewMeanSlagThickness = nan;
outputs.NewMeanConcThickness = nan;
outputs.NewMeanTotalLiquidThickness = nan;
outputs.IsValidDeltaMatte = nan;
outputs.IsValidDeltaSlag = nan;
outputs.IsValidDeltaConc = nan;
outputs.CombinedValidDeltaSounding = nan;

end