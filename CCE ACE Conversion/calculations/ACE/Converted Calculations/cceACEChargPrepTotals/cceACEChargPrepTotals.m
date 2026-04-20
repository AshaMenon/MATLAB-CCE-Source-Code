function [outputs,errorCode] = cceACEChargPrepTotals(parameters,inputs)

    logger = CCELogger(parameters.LogName, parameters.CalculationID, ...
        parameters.CalculationName, parameters.LogLevel);

    newOutTime = strrep(parameters.OutputTime, "T", " ");
    newOutTime = extractBefore(newOutTime, ".");

    ExeTime = datetime(newOutTime);

    logger.logTrace("Current execution time being used: " + string(ExeTime))
    errorCode = cce.CalculationErrorState.Good;

    % inputs
    % T_Wet_Feed_Tot (inPiAceFeed)
    % M_Correcton_Factor_Feed (inPiAceCorrFac)
    % M_DailyCorrection_Feed (inPiAceCorr)
    % Feed_H2O (inPiAceMoist)

    % outputs
    % WetConc_Dried_Tot
    % DryConc_Dried_Tot_2
    try
        % Get wet feed total
        try
            wetFeed = inputs.T_Wet_Feed_Tot(end);
        catch
            wetFeed = nan;
            logger.LogTrace("No Weet Feed found for period")
        end

        % Get correction factor
        try
            corrFactor = inputs.M_Correcton_Factor_Feed(end);
        catch
            corrFactor = nan;
            logger.LogTrace("No Correction Factor found for period")
        end

        if isempty(corrFactor) || isnan(corrFactor) || corrFactor == 0
            corrFactor = 1;
        end

        % Get correction values
        try
            corrVal = inputs.M_DailyCorrection_Feed(end);
        catch
            corrVal = 0;
            logger.LogTrace("No Correction Value found for period")
        end

        if isempty(corrVal) || isnan(corrVal)
            corrVal = 1;
        end

        % Adjust wet feed values with correction factors and values
        wetConc_Dried_Tot = (wetFeed .* corrFactor) + corrVal;

        % Get moisute values
        try
            dryFeed = inputs.Feed_H2O(end);
        catch
            dryFeed = nan;
            logger.LogTrace("No Dry Feed found for period")
        end

        % Apply corrections to moisture values
        dryConc_Dried_Tot_2 = (1-dryFeed ./ 100) .* wetConc_Dried_Tot;

        % Assign outputs
        outputs.WetConc_Dried_Tot = wetConc_Dried_Tot;
        outputs.DryConc_Dried_Tot_2 = dryConc_Dried_Tot_2;
        
        ExeTime.Hour = 6;
        ExeTime.Minute = 0;
        ExeTime.Second = 0;

        outputs.Timestamp = ExeTime;

        outputNames = string(fieldnames(outputs));

        for nOut = 1:length(outputNames)
            curOut = outputs.(outputNames(nOut));

            if isempty(curOut)
                outputs.(outputNames(nOut)) = nan; % Set to nan if output empty
            end
        end

    catch err
        outputs.WetConc_Dried_Tot = [];
        outputs.DryConc_Dried_Tot_2 = [];
        outputs.Timestamp = [];
        msg = [err.stack(1).name, ' Line ',...
            num2str(err.stack(1).line), '. ', err.message];

        logger.logError(msg);
        if errorCode == cce.CalculationErrorState.Good || isempty(errorCode)
            errorCode = cce.CalculationErrorState.CalcFailed;
        end
        errorCode = uint32(errorCode);
    end

end