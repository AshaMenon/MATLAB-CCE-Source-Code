function [outputs, errorCode] = acpLeakDetection(parameters,inputs)
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

    %% Add Preferences
    % R
    setpref("acpLeakDetection","RPath", fullfile('C:','Program Files','R','R-4.3.1','bin'));
    % Intermediate Data
    setpref("acpLeakDetection","Data", fullfile('D:', 'CCE Dependencies', 'CCE Leak Detection', 'ConvertorLeakDetectionAnalytics','cce-r-model','Data'));
    setpref("acpLeakDetection","Configuration", fullfile('D:', 'CCE Dependencies', 'CCE Leak Detection', 'ConvertorLeakDetectionAnalytics','cce-r-model','Configuration'));
    % Calculations
    setpref("acpLeakDetection","DataPreparation", fullfile('D:', 'CCE Dependencies', 'CCE Leak Detection','ConvertorLeakDetectionAnalytics','cce-r-model','run_preparedata.R'));
    setpref("acpLeakDetection","CalculatePrediction", fullfile('D:', 'CCE Dependencies', 'CCE Leak Detection','ConvertorLeakDetectionAnalytics','cce-r-model','run_model_predict.R'));

    try
        %% Data Preparation
        errorCode = cce.CalculationErrorState.Good;    

        inputFields = fieldnames(inputs);
        timestampIdx = contains(inputFields,{'Timestamps', 'Timestamp'});
        features_uniq = unique(string(inputFields(~timestampIdx)),'stable');     

        for feature = features_uniq'
            if iscell(inputs.(feature))
                inputs.(feature) = cellfun(@formatCell,inputs.(feature));
            end
        end

        %cleaned inputs
        idx = contains(features_uniq,"_In");
        cleanedInputs = features_uniq(idx);

        cleanInStruct = struct;
        for feature = cleanedInputs'
            cleanName = extractBefore(feature,"_In");
            cleanInStruct.(cleanName) = inputs.(feature);
            cleanInStruct.(cleanName+"Timestamps") = inputs.(feature+"Timestamps");
        end

        inputs = rmfield(inputs,cleanedInputs);
        inputs = rmfield(inputs,cleanedInputs+"Timestamps");

        %% Data Preparation
        [Inputs, Config, ModelPerformance] = prepareInputs(inputs, parameters);

        if ~parameters.Backfill
            writecell(Inputs, "D://CCE Dependencies//CCE Leak Detection//ConvertorLeakDetectionAnalytics//Data//Raw//Data.csv","WriteMode","overwrite");
            writetable(Config, "D://CCE Dependencies//CCE Leak Detection//ConvertorLeakDetectionAnalytics//Configuration//Config.csv","WriteMode","overwrite");
            writetable(ModelPerformance, "D://CCE Dependencies//CCE Leak Detection//ConvertorLeakDetectionAnalytics//Configuration//Model_Performance.csv","WriteMode","overwrite");
        else
            writecell(Inputs, "D://CCE Dependencies//CCE Leak Detection//ConvertorLeakDetectionAnalytics//Backfill//Data//Raw//Data.csv","WriteMode","overwrite");
            writetable(Config, "D://CCE Dependencies//CCE Leak Detection//ConvertorLeakDetectionAnalytics//Backfill//Configuration//Config.csv","WriteMode","overwrite");
            writetable(ModelPerformance, "D://CCE Dependencies//CCE Leak Detection//ConvertorLeakDetectionAnalytics//Backfill//Configuration//Model_Performance.csv","WriteMode","overwrite");
        end

        if ~parameters.Backfill
            commandline = '"C://Program Files//R//R-3.6.3//bin//Rscript.exe" "D://CCE Dependencies//CCE Leak Detection//ConvertorLeakDetectionAnalytics//Scripts//Data_Preparation.R"';
        else
            commandline = '"C://Program Files//R//R-3.6.3//bin//Rscript.exe" "D://CCE Dependencies//CCE Leak Detection//ConvertorLeakDetectionAnalytics//Backfill//Scripts//Data_Preparation.R"';
        end

        [status,sysOut]=system(commandline);

        if ~parameters.Backfill
            files = getFiles('D://CCE Dependencies//CCE Leak Detection//ConvertorLeakDetectionAnalytics//Data//Output//Intermediate');
        else
            files = getFiles('D://CCE Dependencies//CCE Leak Detection//ConvertorLeakDetectionAnalytics//Backfill//Data//Output//Intermediate');
        end

        inputsPrep = getPreparedData(files, parameters.Backfill);

        %% Prediction Calculation
        cleanData = getCleanData(cleanInStruct, parameters);
        try
            if ~parameters.Backfill
                delete('D://CCE Dependencies//CCE Leak Detection//ConvertorLeakDetectionAnalytics//Data//Clean//Data.csv')
            else
                delete('D://CCE Dependencies//CCE Leak Detection//ConvertorLeakDetectionAnalytics//Backfill//Data//Clean//Data.csv')
            end
        catch
        end

        if ~parameters.Backfill
            writetable(cleanData, 'D://CCE Dependencies//CCE Leak Detection//ConvertorLeakDetectionAnalytics//Data//Clean//Data.csv');
        else
            writetable(cleanData, 'D://CCE Dependencies//CCE Leak Detection//ConvertorLeakDetectionAnalytics//Backfill//Data//Clean//Data.csv');
        end

        if ~parameters.Backfill
            commandline = '"C://Program Files//R//R-3.6.3//bin//Rscript.exe" "D://CCE Dependencies//CCE Leak Detection//ConvertorLeakDetectionAnalytics//Scripts//Calculate_Prediction.R"';
        else
            commandline = '"C://Program Files//R//R-3.6.3//bin//Rscript.exe" "D://CCE Dependencies//CCE Leak Detection//ConvertorLeakDetectionAnalytics//Backfill//Scripts//Calculate_Prediction.R"';
        end

        [status,sysOut]=system(commandline);
        if ~parameters.Backfill
            file = getFiles('D://CCE Dependencies//CCE Leak Detection//ConvertorLeakDetectionAnalytics//Data//Output//PI');
        else
            file = getFiles('D://CCE Dependencies//CCE Leak Detection//ConvertorLeakDetectionAnalytics//Backfill//Data//Output//PI');
        end

        %% Read in outputs
        if ~status
            if ~parameters.Backfill
                fileId = fopen(['D://CCE Dependencies//CCE Leak Detection//ConvertorLeakDetectionAnalytics//Data//Output//PI//',file{end}]);
            else
                fileId = fopen(['D://CCE Dependencies//CCE Leak Detection//ConvertorLeakDetectionAnalytics//Backfill//Data//Output//PI//',file{end}]);
            end
            outData = textscan(fileId,"%s %D %f",'Delimiter',',');
            tagNames = outData{1};
            outDate = outData{2};
            outVals = outData{3};

            tagNamesUniq = unique(tagNames);

            for curTag = tagNamesUniq'
                idx = ismember(tagNames,curTag);
                curTag = strrep(curTag,"A:","");
                curTag = matlab.lang.makeValidName(curTag);

                outputs.(curTag) = double(outVals(idx));
            end

            warning off
            outputs.Timestamp = outDate(idx)-hours(2);
            for n =1:length(file)
                if ~parameters.Backfill
                    delete(['D://CCE Dependencies//CCE Leak Detection//ConvertorLeakDetectionAnalytics//Data//Output//PI//',file{n}])
                else
                    delete(['D://CCE Dependencies//CCE Leak Detection//ConvertorLeakDetectionAnalytics//Backfill//Data//Output//PI//',file{n}])
                end
            end
            warning on

            outlen = length(outputs.Timestamp);

            cleanFieldNames = string(fieldnames(inputsPrep));
            timestampIdx = contains(cleanFieldNames,{'Timestamps', 'Timestamp'});
            cleanFieldNames = unique(string(cleanFieldNames(~timestampIdx)),'stable');

            for fieldName = cleanFieldNames'
                try
                outputs.(fieldName) = inputsPrep.(fieldName)(end-outlen+1:end);
                catch
                    outputs.(fieldName) = inputsPrep.(fieldName);
                end
            end

            outputs.Moisture_Smoothed_Ctrl_Bias = outputs.Moisture_Smoothed_Ctrl;
            outputs.run_mode = outputs.run_mode;

        else
            logger.logError(sysOut)

            outputs.Timestamp = inputs.AcidPlantGasFlowrate_0_0Timestamps(end):minutes(10):(inputs.AcidPlantGasFlowrate_0_0Timestamps(end)+hours(2));

            outputs.Timestamp = outputs.Timestamp';
            numOuts = length(outputs.Timestamp);
            inputFields = fieldnames(inputs);
            timestampIdx = contains(inputFields,{'Timestamps', 'Timestamp'});
            features_uniq = unique(string(inputFields(~timestampIdx)),'stable');

            for outFeature = features_uniq'
                outputs.("Out_" + outFeature) = nan(numOuts,1);
            end

            outputs.Moisture_Prediction = nan(numOuts,1);
            outputs.Moisture_Cumsum = nan(numOuts,1);
            outputs.Moisture_Residual = nan(numOuts,1);
            outputs.Moisture_Smoothed = nan(numOuts,1);

            try
                outputs.Moisture_Prediction = outs.pred;
                outputs.Moisture_Cumsum = outs.outcum;
                outputs.Moisture_Residual = outs.res;
                outputs.Timestamp = outs.Time;
                outputs.Moisture_Smoothed = outs.smooth;
                for outFeature = features_uniq'
                    outputs.("Out_" + outFeature) = inputs.(outFeature);
                end
            catch
            end
        end

        logger.logTrace("Completed prediction for: " + string(ExeTime))

    catch err

        msg = [err.stack(1).name, ' Line ',...
            num2str(err.stack(1).line), '. ', err.message];

        logger.logError(msg);
        errorCode = cce.CalculationErrorState.CalcFailed;

    end
end

function a = formatNames(a)
    if contains(a,'A:')
        a = strrep(a,"A:","");
    end

    a = strsplit(a,"_");

    % if ~isnan(double(a(end)))
    %     a(end) = [];
    % end

    for n = 1:length(a)
        curStr = char(a(n));
        a(n) = strcat(upper(curStr(1)),curStr(2:end));
    end
    a = strjoin(a,"");
end

function cleanData = getCleanData(inputs,parameters)
    if ~parameters.Backfill
        fileId = fopen(sprintf('D://CCE Dependencies//CCE Leak Detection//ConvertorLeakDetectionAnalytics/cce-r-model/Config/clean_tags.txt'));
    else
        fileId = fopen(sprintf('D://CCE Dependencies//CCE Leak Detection//ConvertorLeakDetectionAnalytics/Backfill/cce-r-model/Config/clean_tags.txt'));
    end
    cleanTags = textscan(fileId,"%s");
    cleanTagsOri = string(cleanTags{1});

    cleanTagsFormated = arrayfun(@formatNames,cleanTagsOri);
    % cleanTagsFormated = arrayfun(@(x)strrep(x,"A:",""),cleanTags);

    cleanData = table;
    cleanTags = [];
    cleanTimes = [];
    cleanVals = [];

    inputFields = fieldnames(inputs);
    timestampIdx = contains(inputFields,{'Timestamps', 'Timestamp'});
    features_uniq = unique(string(inputFields(~timestampIdx)),'stable');

    features_uniqFormatted = arrayfun(@formatNames,features_uniq);

    for n = 1:length(cleanTagsFormated)
        tagIdx = contains(features_uniqFormatted, cleanTagsFormated(n));
        curTag = features_uniq(tagIdx);
        if ~isempty(curTag)
            curTag = curTag(end);
        else
            continue
        end

        timestamps = inputs.(curTag+"Timestamps");
        values = inputs.(curTag);
        tags = repmat(cleanTagsOri(n),length(values),1);

        cleanTags = [cleanTags; tags];
        cleanTimes = [cleanTimes; timestamps];
        cleanVals = [cleanVals; values];
    end

    cleanData.Tag = cleanTags;
    cleanData.timestamp = cleanTimes;
    cleanData.Value = cleanVals;
end

function out = formatCell(in)
    switch lower(in)
        case "on"
            out = 1;
        case "off"
            out = 0;
        otherwise
            out = nan;
    end
end

function inputs = getPreparedData(files, backfill)

    inputs = struct;

    for curFile = string(files)'
        if ~backfill
            fileId = fopen(['D://CCE Dependencies//CCE Leak Detection//ConvertorLeakDetectionAnalytics//Data//Output//Intermediate//',char(curFile)]);
        else
            fileId = fopen(['D://CCE Dependencies//CCE Leak Detection//ConvertorLeakDetectionAnalytics//Backfill//Data//Output//Intermediate//',char(curFile)]);
        end

        outData = textscan(fileId,"%s %D %f",'Delimiter',',');
        tagNames = outData{1};
        outDate = outData{2};
        outVals = outData{3};

        fclose(fileId);
        if ~backfill
            delete(['D://CCE Dependencies//CCE Leak Detection//ConvertorLeakDetectionAnalytics//Data//Output//Intermediate//',char(curFile)]);
        else
            delete(['D://CCE Dependencies//CCE Leak Detection//ConvertorLeakDetectionAnalytics//Backfill//Data//Output//Intermediate//',char(curFile)]);
        end

        curTag = tagNames{1};
        curTag = strrep(curTag,"A:","");

        % curTag = strsplit(curTag,"_");
        % if length(curTag) > 2
        %     curTag(end-1:end) = [];
        % end
        curTag = strjoin(curTag,"_");
        curTag = matlab.lang.makeValidName(curTag);

        inputs.(curTag) = double(outVals);
        inputs.(curTag+"Timestamps") = outDate - hours(2);


    end
end