function [outputs, errorCode] = acpLeakDetectionTrain(parameters,inputs)
    %EVALACPLEAKDETECTION evaluates the Data_Preparation.R and Calculate_Prediction.R
    % scripts for preparing converter offgas moisture raw data and predictions.

    %   Parameters: Configuration data for measures – tag names etc. [struct]
    %   Inputs: All Raw PI Data [struct]

    logger = CCELogger(parameters.LogName, parameters.CalculationID, ...
        parameters.CalculationName, parameters.LogLevel);

    newOutTime = strrep(parameters.OutputTime, "T", " ");
    newOutTime = extractBefore(newOutTime, ".");

    ExeTime = datetime(newOutTime);

    logger.logTrace("Current execution time being used: " + string(ExeTime))
    errorCode = cce.CalculationErrorState.Good; 

    try
        %format inputs
        inputFieldNames = string(fieldnames(inputs));
        timestampIdx = contains(inputFieldNames,"Timestamps");
        inputFieldNames(timestampIdx) = [];

        inputNames = [];
        values = [];
        timestamps = [];

        for feature = inputFieldNames'
            inputNames = [inputNames; repmat(feature,length(inputs.(feature)),1)];
            values = [values; inputs.(feature)];
            timestamps = [timestamps; inputs.(feature + "Timestamps")];
        end

        timestamps.Format = "MM/dd/yyyy hh:mm:ss";

        inTbl = table;
        inTbl.Tags = inputNames;
        inTbl.timestamp = timestamps;
        inTbl.Values = values;

        writetable(inTbl,"D://CCE Dependencies//CCE Leak Detection//ConvertorLeakDetectionAnalytics//Model_Rebuild//Data.csv","WriteMode","overwrite");

        %Build Model
        commandline = '"C://Program Files//R//R-3.6.3//bin//Rscript.exe" "D://CCE Dependencies//CCE Leak Detection//ConvertorLeakDetectionAnalytics//Model_Rebuild//Build_Model.R"';

        [status,sysOut]=system(commandline);

        %read outputs
        if ~status
            modelPerformance = readtable("D://CCE Dependencies//CCE Leak Detection//ConvertorLeakDetectionAnalytics//Model_Rebuild//model_performance.csv");
            outputs = table2struct(modelPerformance,'ToScalar',true);
            outputs.Timestamp = ExeTime;
        else
            err = MException("LeakDetectionTrain:BuildModelError","Error running Build Model.R: "+sysOut);
            throw(err)
        end
    catch err
        msg = [err.stack(1).name, ' Line ',...
            num2str(err.stack(1).line), '. ', err.message];

        logger.logError(msg);
        errorCode = cce.CalculationErrorState.CalcFailed;

        outputs.Timestamp = [];
        outputs.bias = [];
        outputs.errorll = [];
        outputs.errormean = [];
        outputs.errorsd = [];
        outputs.errorul = [];
        outputs.rmse = [];
        outputs.rsq = [];
    end
end