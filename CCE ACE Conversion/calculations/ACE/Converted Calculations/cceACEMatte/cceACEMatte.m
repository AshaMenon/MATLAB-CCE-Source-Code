function [outputs,errorCode] = cceACEMatte(parameters,inputs)

    logger = CCELogger(parameters.LogName, parameters.CalculationID, ...
        parameters.CalculationName, parameters.LogLevel);

    newOutTime = strrep(parameters.OutputTime, "T", " ");
    newOutTime = extractBefore(newOutTime, ".");

    ExeTime = datetime(newOutTime);

    logger.logTrace("Current execution time being used: " + string(ExeTime))
    errorCode = cce.CalculationErrorState.Good;

    %Inputs
    % M_Ladle_mass_before_tap
    % M_EndTime is a timestamp
    % M_Ladle_mass_after_tap
    % M_Full_Ladle_Mass
    % M_Clay_Used

    %Parameters
    % ClayUsedFactor

    %Outputs
    % ACE_Clay_Used
    % ACE_Mass_Tapped
    % ACE_Mass_Cast
    % ACE_Tap_time
    % ACE_TapRate
    try
        % get values at time of execution

        M_Ladle_mass_before_tap = getVal(inputs.M_Ladle_mass_before_tap);
        M_EndTime = getVal(inputs.M_EndTime);
        M_Ladle_mass_after_tap = getVal(inputs.M_Ladle_mass_after_tap);
        M_Full_Ladle_Mass = getVal(inputs.M_Full_Ladle_Mass);
        M_Clay_Used = getVal(inputs.M_Clay_Used);
        valTime = getVal(inputs.M_EndTimeTimestamps);

        % tap time
        if ~isempty(M_EndTime)
            M_EndTime = datetime("1970-01-01 00:00:00") + seconds(M_EndTime) + hours(2);
            taptime =  abs(M_EndTime - valTime);
            taptime = minutes(taptime);
        else
            taptime = [];
        end

        outputs.ACE_Tap_time = taptime*60;

        % Full ladle mass
        if ~isempty(M_Full_Ladle_Mass)
            if isnumeric(M_Full_Ladle_Mass)
                fullLadle = M_Full_Ladle_Mass;
            else
                fullLadle = NaN;
            end
        else
            fullLadle = [];
        end

        % tap mass
        if ~isempty(M_Ladle_mass_before_tap)
            if isnumeric(M_Ladle_mass_before_tap) && ~isnan(fullLadle)
                tapMass = fullLadle - M_Ladle_mass_before_tap;
            else
                tapMass = NaN;
            end
        else
            tapMass = [];
        end

        outputs.ACE_Mass_Tapped = tapMass;

        % cast mass
        if ~isempty(M_Ladle_mass_after_tap)
            if isnumeric(M_Ladle_mass_after_tap) && ~isnan(fullLadle)
                castMass = fullLadle - M_Ladle_mass_after_tap;
            else
                castMass = NaN;
            end
        else
            castMass = [];
        end
        outputs.ACE_Mass_Cast = castMass;

        % tap rate
        if ~isempty(M_Ladle_mass_before_tap)
            if (taptime > 0) && ~isnan(tapMass)
                tapRate = tapMass ./ taptime;
            else
                tapRate = NaN;
            end
        else
            tapRate = [];
        end
        outputs.ACE_TapRate = tapRate;

        % clay calculation
        if ~isempty(M_Clay_Used)
            if isnumeric(M_Clay_Used)
                pasteConv = parameters.ClayUsedFactor;

                clayUsed = M_Clay_Used .* pasteConv;
            else
                clayUsed = NaN;
            end
        else
            clayUsed = [];
        end

        outputs.ACE_Clay_Used = clayUsed;

        if isdatetime(valTime) && ~ismissing(valTime)
            outputs.Timestamp = valTime;
        else
            outputs.Timestamp = ExeTime;
        end
        logger.logTrace("Complete")

        outputNames = string(fieldnames(outputs));

        for nOut = 1:length(outputNames)
            curOut = outputs.(outputNames(nOut));

            if isempty(curOut)
                outputs.(outputNames(nOut)) = nan; % Set to nan if output empty
            end
        end
    catch err
        outputs.ACE_Tap_time = [];
        outputs.ACE_Mass_Tapped = [];
        outputs.ACE_Mass_Cast = [];
        outputs.ACE_TapRate = [];
        outputs.ACE_Clay_Used = [];
        outputs.Timestamp = [];
        msg = [err.stack(1).name, ' Line ',...
            num2str(err.stack(1).line), '. ', err.message];

        logger.logError(msg);
        if errorCode == cce.CalculationErrorState.Good || isempty(errorCode)
            errorCode = cce.CalculationErrorState.CalcFailed;
        end


    end

end

function output = PIValAtTime(input,timestamp,exeTime)
    output = [];
    tol = 1.5;
    interval = timestamp >= (exeTime - seconds(30)) & timestamp <= (exeTime + seconds(30));
    vals = input(interval);
    valTime = timestamp(interval);

    for i = 1:numel(vals)
        if abs(valTime(i) - exeTime) < tol
            output = vals(i);
            break
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
