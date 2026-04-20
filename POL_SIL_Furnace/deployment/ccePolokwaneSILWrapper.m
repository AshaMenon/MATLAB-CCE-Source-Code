function [outputs, errorCode] = ccePolokwaneSILWrapper(parameters, inputs)

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
outTimestamps = exeTime - minutes(parameters.ExecutionFrequencyParam):minutes(1):exeTime;
%TODO: Post process data to return the last minutes matching this

log.logInfo('--------------------------------------------------------------')
log.logInfo('Start Polokwane SIL Furnace Modelling')

try
    % [Extract inputs]
    % Data format checking and converting
    log.logDebug('Converting Data from MATLAB Struct to Timetable')
    [inputsTT, referenceTime] = convertInputs(inputs, log);

    % Set up the data
    try
        log.logInfo('Setting up Data Object')
        % Define when simulation should end (up until data runs out)
        simStopTime = seconds(inputsTT.Timestamp(end) - inputsTT.Timestamp(1));
        
        [slInputs, slParameters, simStartDateTime] = prepareDataForSim(inputsTT, parameters);

        if ~exist(fullfile(fileparts(log.LogFilePath), "rawInputs.mat"), "file")
            try
                save(fullfile(fileparts(log.LogFilePath), "rawInputs.mat"), 'inputsTT');
            catch err
                log.logWarning(err.message);
            end
        end
        log.logInfo(['Data import completed, final date set size: ' num2str(height(inputsTT))])

    catch err
        %Data setup errored - return error code, and log issue
        outputs = assignNans(inputs, log);
        errorCode = CalculationErrorState.BadInput;
        msg = [err.stack(1).name, ' Line ',...
            num2str(err.stack(1).line), '. ', err.message];
        log.logError(msg);
        return
    end

    % Set up and evaluate the model
    try
        log.logDebug('Running the Simulink Model')
        log.logInfo('Running for current time: %s', parameters.OutputTime) % can make use of the output time parameters

        simOut = polokwaneSILFurnaceModel(slInputs, slParameters, referenceTime, simStopTime, log);

        log.logDebug('Simulink Model execution complete');

        try
            
            log.logDebug('Converting Simulation Data into Outputs structure');

            % Find the last timestamp (in string format) and
            %convert from simulation time to "real" time
            fullTM = simOut.logsout.extractTimetable;
            fullTM.Time = fullTM.Time + simStartDateTime;
            [~, returnIdx] = ismember(outTimestamps, fullTM.Time);
            returnIdx(returnIdx==0) = [];

            outputs.Timestamp = fullTM.Time(returnIdx);
            outputs.SimulatedMatteLevel = fullTM{returnIdx, 'height_matte'};
            outputs.SimulatedSlagLevel = fullTM{returnIdx, 'height_slag'};
            outputs.SimulatedConcentrateLevel = fullTM{returnIdx, 'height_black_top'};
            outputs.SimulatedTotalBathLevel = fullTM{returnIdx, 'height_total'};
            outputs.SimulatedMatteMass = fullTM{returnIdx, 'm_matte'};
            outputs.SimulatedSlagMass = fullTM{returnIdx, 'm_slag'};
            outputs.SimulatedConcentrateMass = fullTM{returnIdx, 'm_black_top'};
            outputs.IsReset = fullTM{returnIdx, 'is_reset'};

        catch err
            outputs = assignNans(inputs, log);
            msg = [err.stack(1).name, ' Line ',...
                num2str(err.stack(1).line), '. ', err.message];
            log.logError(msg);
            if errorCode == CalculationErrorState.Good || isempty(errorCode)
                errorCode = CalculationErrorState.CalcFailed;
            end
            return
        end

        log.logInfo('--------------------------------------------------------------');
        log.logInfo(['Sucessfully Completed Polokwane SIL Furnace Modelling Generated: ' int2str(outputs.SimulatedTotalBathLevel(end))]);
        log.logInfo('--------------------------------------------------------------');

    catch err
        %Model evaluation failed - log error, and return error code
        outputs = assignNans(inputs, log);
        msg = [err.stack(1).name, ' Line ',...
            num2str(err.stack(1).line), '. ', err.message];
        log.logError(msg);
        if errorCode == CalculationErrorState.Good || isempty(errorCode)
            errorCode = CalculationErrorState.CalcFailed;
        end
        return
    end


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

function [inputsTT, referenceTime] = convertInputs(inputs, log)
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
    inputsTT = table2timetable(inputs);
elseif isa(inputs, 'table')
    timeKey = contains(inputs.Properties.VariableNames, 'Timestamp', 'IgnoreCase',true);
    timeName = find(timeKey, 1, "first");
    inputs.Timestamp = inputs{:,timeName};
    referenceTime = inputs.Timestamp(1);
    log.logInfo(['Timestamp ID changed from ' inputs.Properties.VariableNames{timeName}])
    inputs(:,timeName) = [];
    inputsTT = table2timetable(inputs);
elseif ~isa(inputs, 'timetable')
    error('EvaluateTurbineModel: "inputs" is not a struct.')
end
end

function outputs = assignNans(inputs, log)
%ASSIGNNANS creates an output structure that contains NANS only, written to
%the input timestamp

inputs = convertInputs(inputs, log);

outputs = struct();
outputs.Timestamp = inputs.Timestamp(end);
outputs.SimulatedMatteLevel = nan;
outputs.SimulatedSlagLevel = nan;
outputs.SimulatedConcentrateLevel = nan;
outputs.SimulatedTotalBathLevel = nan;
outputs.SimulatedMatteMass = nan;
outputs.SimulatedSlagMass = nan;
outputs.SimulatedConcentrateMass = nan;
outputs.IsReset = nan;

end