function [outputs, errorCode] = EvaluateTemperatureModel(parameters, inputs)
%EVALUATETEMPERATUREMODEL Evaluates the results of the temperature model (Simulink)

% Create log
logFile = parameters.LogName;
calculationID = parameters.CalculationID;
logLevel = parameters.LogLevel;
calculationName = parameters.CalculationName;
log = CCELogger(logFile, calculationName, calculationID, logLevel);
errorCode = CalculationErrorState.Good;

log.logInfo('--------------------------------------------------------------')
log.logInfo('Beginning Evaluating Matte Temperature Model')

try
    % [Extract inputs]
    % Data format checking and converting
    log.logDebug('Converting Data from MATLAB Struct to Simulink input')
    [inputs, referenceTime] = convertInputs(inputs, log);
    log.logInfo(['Running for current time: ', datestr(inputs.Timestamp(end))])
    
    % Extract complex or constant parameters
    log.logInfo('Extracting additional parameters')
    parameters = getTempModelParameters(parameters, inputs, log);
    
    % Check converter mode if running in production
    if strcmp(parameters.simMode, 'production') && ~ismember(inputs.Convertermode(end), parameters.filterFurnaceModes)
        log.logWarning(strcat('EvaluateTemperatureModel: Current Converter Mode: ',...
            string(inputs.Convertermode(end)), '. Out of range.'))
        outputs = assignNans(inputs, log);
        return
    end

    % Set up the data
    try
        log.logInfo('Setting up Data Object')

        if ~exist("D:\rawInputs.mat")
            save('D:\rawInputs', 'inputs');
        end

        dataModel = Data(inputs, log);
    
        [data, ~, ~] = preprocessingAndFeatureEngineering(dataModel,...
            struct('add', false, 'mode',8), parameters.resampleTime, ...
            parameters.resampleMethod, parameters.tapClassification, ...
            parameters.smoothFuelCoal, parameters.responseTags, ...
            parameters.referenceTags, parameters.highFrequencyPredictorTags,...
            parameters.lowFrequencyPredictorTags, parameters.phase, false);
        log.logInfo(['Data preprocessing completed, final date set size: ' num2str(height(inputs))])
    catch err
        outputs = assignNans(inputs, log);
        log.logError(err.message)
        return
    end
    
    % Set up and evaluate the model
    try
        log.logDebug('Running the Simulink Model')
        modelName = parameters.ModelName;

        outputs = MatteTempModel(data, modelName, referenceTime, parameters, log);
        log.logDebug('Simulink Model execution complete');

        log.logInfo('--------------------------------------------------------------');
        log.logInfo(['Sucessfully Completed Evaluating Matte Temperature Change: ' int2str(outputs.SimulatedMatteTemperature(end))]);
        log.logInfo('--------------------------------------------------------------');
    catch err
        outputs = assignNans(inputs, log);
        log.logError(err.message)
        return
    end
    
    % Logging
catch err
    % [Handle errors]
    outputs = assignNans(inputs, log);
    log.logError(err.message)
    % Convert errorCode to uint32 for MATLAB Production Server
    errorCode = uint32(errorCode);
end

end

function [inputs, referenceTime] = convertInputs(inputs, log)
if isa(inputs, 'struct')
    inputs = struct2table(inputs);
    timeKey = contains(inputs.Properties.VariableNames, 'Timestamp', 'IgnoreCase',true);
    timeName = find(timeKey, 1, "first");
    inputs.Timestamp = inputs{:,timeName};
    referenceTime = inputs.Timestamp(1);
    log.logInfo(['Timestamp ID changed from ' inputs.Properties.VariableNames{timeName}])
    % inputs(:,timeName) = [];
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
    error('EvaluateTemperatureModel: "inputs" is not a struct or a table')
end
end

function outputs = assignNans(inputs, log)

inputs = convertInputs(inputs, log);

outputs = struct();
outputs.Timestamp = inputs.Timestamp(end);

outputs.SimulatedMatteTemperature = nan;
outputs.SimulatedSlagTemperature = nan;
outputs.SimulatedMatteHeight = nan;
outputs.SimulatedSlagHeight = nan;
outputs.SimulatedTotalBathHeight = nan;

outputs.MatteTapping = nan;
outputs.SlagTapping = nan;

outputs.RecommendedFuelCoalSP = nan;

outputs.HeatConductedfromSlagtoMatte = nan;
outputs.HeatMassFlowfromSlagtoMatte = nan;
outputs.HeatConductedfromMattetoWaffleCooler = nan;
outputs.HeatMassFlowMatteTappedMatteBath = nan;
outputs.HeatGeneratedSlag = nan;
outputs.HeatMassFlowfromSlagtoInflow = nan;
outputs.HeatMassFlowfromSlagtoMatte = nan;
outputs.HeatMassFlowMatteTappedFullBath = nan;
outputs.HeatMassFlowMatteTappedMatteBath = nan;
outputs.HeatMassFlowSlagTapped = nan;
outputs.HeatConductedfromFullBathtoWaffleCooler = nan;
outputs.HeatRadiatedfromSlagtoFurnace = nan;
outputs.HeatMassFlowfromOffgastoFurnace = nan;
outputs.HeatMassFlowfromAccruedSlagandDusttoFurnace = nan;

outputs.TotalHeatInMatte = nan;
outputs.TotalHeatOutMatte = nan;
outputs.TotalHeatInBath = nan;
outputs.TotalHeatOutBath = nan;

outputs.SmoothedSlagTemperature = nan;
outputs.SmoothedMatteTemperature = nan;

outputs.SlagTappingRate = nan;
outputs.MatteTappingRate = nan;

end

