function [outputs, errorCode] = cceCalcMatteFallFractionsAveWrapper(parameters, inputs)

 % Create log
    logFile = parameters.LogName;
    calculationID = parameters.CalculationID;
    logLevel = parameters.LogLevel;
    calculationName = parameters.CalculationName;
    log = CCELogger(logFile, calculationName, calculationID, logLevel);
    errorCode = CalculationErrorState.Good;

    newOutTime = strrep(parameters.OutputTime, "T", " ");
    newOutTime = extractBefore(newOutTime, ".");

    exeTime = datetime(newOutTime) + hours(2); % Convert from UTC

    log.logInfo('--------------------------------------------------------------')
    log.logInfo('Start matte fall calculation at execution time %s', string(exeTime))

    try
        % [Extract inputs]
        % Data format checking and converting
        inputsTT = convertInputs(inputs, log);
        matteFallFraction = calcMatteFallFractionsAve(inputsTT, parameters.NSamples, parameters.DelayHrs,log);
        outputs.MatteFallFraction = matteFallFraction(end-parameters.ExecutionFrequencyParam+1:end);
        outputs.Timestamp = inputsTT.Timestamp(end-parameters.ExecutionFrequencyParam+1:end);


    catch err
        % Unhandled error - log, assign nans, set calc state
        outputs = assignNans(inputs, log);
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
        error('calcMatteFallFractionsAve: "inputs" should be a struct, table, or timetable.')
    end
end

function outputs = assignNans(inputs, log)
    %ASSIGNNANS creates an output structure that contains NANS only, written to
    %the input timestamp

    inputs = convertInputs(inputs, log);

    outputs = struct();
    outputs.Timestamp = inputs.Timestamp(end);
    outputs.MatteFallFraction = nan;
end