function [outputs,errorCode] = cceACEMatteTapping(parameters,inputs)

    logger = CCELogger(parameters.LogName, parameters.CalculationID, ...
        parameters.CalculationName, parameters.LogLevel);

    newOutTime = strrep(parameters.OutputTime, "T", " ");
    newOutTime = extractBefore(newOutTime, ".");

    ExeTime = datetime(newOutTime);
    ExeTime = ExeTime + hours(2);
    % outputs.Timestamp = ExeTime;

    logger.logTrace("Current execution time being used: " + string(ExeTime))

    errorCode = cce.CalculationErrorState.Good;

    % Inputs
    % M_Empty_Ladle_Mass
    % M_EndTime
    % M_Full_Ladle_Mass
    % M_Large_ladle_level
    % M_Small_ladle_level

    % Parameters
    % LargeLadleTonnesperLadle
    % SmallLadleTonnesperLadle

    % Outputs
    % Mass_Tapped
    % Tap_time
    % Tap_Rate

    try

        M_Full_Ladle_Mass = getVal(inputs.M_Full_Ladle_Mass);
        M_EndTime = getVal(inputs.M_EndTime);
        M_Empty_Ladle_Mass = getVal(inputs.M_Empty_Ladle_Mass);
        M_Small_ladle_level = getVal(inputs.M_Small_ladle_level);
        M_Large_ladle_level = getVal(inputs.M_Large_ladle_level);
        valTime = getVal(inputs.M_EndTimeTimestamps);

        % Tap Time
        if ~isempty(M_EndTime)
            logger.logTrace("Calculating TapTime")
            M_EndTime = datetime("1970-01-01 00:00:00") + seconds(M_EndTime) + hours(2);
            taptime =  abs(M_EndTime - valTime);
            taptime = minutes(taptime);
        else
            taptime = nan;
        end

        outputs.Tap_time = taptime;

        % Tap mass

        % Full ladle mass
        logger.logTrace("Calculating TapMass")
        if ~isempty(M_Full_Ladle_Mass) && ~isempty(M_Empty_Ladle_Mass)
            if isnumeric(M_Full_Ladle_Mass) && isnumeric(M_Empty_Ladle_Mass)
                tapMass = M_Full_Ladle_Mass - M_Empty_Ladle_Mass;
            else
                tapMass = NaN;
            end
        else
            tapMass = NaN;
        end

        if isnan(tapMass)

            if ~isempty(M_Large_ladle_level)

                if isnumeric(M_Large_ladle_level)
                    tapMass = parameters.LargeLadleTonnesperLadle .* M_Large_ladle_level;
                else
                    tapMass = NaN;
                end
            else
                if ~isempty(M_Small_ladle_level)

                    if isnumeric(M_Small_ladle_level)
                        tapMass = parameters.SmallLadleTonnesperLadle .* M_Small_ladle_level;
                    else
                        tapMass = NaN;
                    end
                end
            end
        end

        if ~isnan(tapMass)
            outputs.Mass_Tapped = tapMass;
        else
            outputs.Mass_Tapped = nan;
        end

        % Tap rate
        logger.logTrace("Calculating TapRate")
        if ~isempty(M_Full_Ladle_Mass)
            if (taptime>0) && ~isnan(tapMass)
                tapRate = tapMass ./ taptime;
            else
                tapRate = nan;
            end
        else
            tapRate = nan;
        end

        outputs.Tap_Rate = tapRate;

        outputNames = string(fieldnames(outputs));

        for nOut = 1:length(outputNames)
            curOut = outputs.(outputNames(nOut));

            if isempty(curOut)
                outputs.(outputNames(nOut)) = nan; % Set to nan if output empty
            end
            if length(curOut) > 1
                outputs.(outputNames(nOut)) = outputs.(outputNames(nOut))(end);
            end
        end 

        if isdatetime(valTime) && ~ismissing(valTime)
            outputs.Timestamp = valTime;
        else
            outputs.Timestamp = ExeTime;
        end
    catch err
        outputs.Tap_time = [];
        outputs.Mass_Tapped = [];
        outputs.Tap_Rate = [];
        outputs.Timestamp = [];

        msg = [err.stack(1).name, ' Line ',...
            num2str(err.stack(1).line), '. ', err.message];

        logger.logError(msg);
        if errorCode == cce.CalculationErrorState.Good || isempty(errorCode)
            errorCode = cce.CalculationErrorState.CalcFailed;
        end

    end
end

function out = getVal(input)

    try
        out = input(end);
    catch
        out = [];
    end
end

function output = PIValAtTime(input,timestamp,exeTime,tol)

    interval = timestamp >= (exeTime - seconds(10)) & timestamp <= (exeTime + seconds(10));
    vals = input(interval);
    valTime = timestamp(interval);
    output = [];
    for i = 1:numel(vals)
        if (valTime(i) - exeTime) < tol
            output = vals(i);
            break
        end
    end
end
