function [outputs,errorCode] = cceACEAddSounding(parameters,inputs)

    % Calculates the solid + Matte level and the Solid + Matte + Slag level for a sounding port
    % runs on a 0.5 hr schedual and only adds the values if the current totals are not within
    % 1 cm of the inputted soundings

    logger = CCELogger(parameters.LogName, parameters.CalculationID, ...
        parameters.CalculationName, parameters.LogLevel);

    newOutTime = strrep(parameters.OutputTime, "T", " ");
    newOutTime = extractBefore(newOutTime, ".");

    ExeTime = datetime(newOutTime);

    logger.logTrace("Current execution time being used: " + string(ExeTime))
    errorCode = cce.CalculationErrorState.Good;

    try

        % CalcStart
        logger.logInfo("AddLevel CalcStart Exec Time: "+ string(ExeTime) +...
            " NowTime: " + string(datetime('now')));

        outputs.Calc_Sol_M = [];
        outputs.Calc_Sol_M_S = [];

        SlagEnt = inputs.Slag(end);
        valTime = inputs.SlagTimestamps(end);


        if ~isnan(SlagEnt) || ~ismissing(SlagEnt)

            SolEnt = inputs.Solid(end);
            MatEnt = inputs.Matte(end);           

            CalSolM = CheckandCalc_Sol_M(SolEnt, MatEnt);
            CalSolMSlag = CheckandCalc_Sol_M_Slag(CalSolM, SlagEnt);

            if ~isnan(SlagEnt)
                if ~isnan(MatEnt)
                    outputs.Calc_Sol_M = CalSolM(end);
                    outputs.Calc_Sol_M_S = CalSolMSlag(end);

                else
                    logger.logWarning("AddLevel No matte level found  Exec Time: " + string(ExeTime) +...
                        " NowTime: " + string(datetime))
                end
            else
                logger.logWarning("AddLevel No Slag level found  Exec Time: " + string(ExeTime) +...
                    " NowTime: " + string(datetime('now')))
            end

        else
            logger.logWarning("AddLevel calc end slag had no level  Exec Time: " + string(ExeTime) +...
                " NowTime: " + string(datetime('now')))
        end

        if isdatetime(valTime) && ~ismissing(valTime)
            outputs.Timestamp = valTime;
        else
            outputs.Timestamp = ExeTime;
        end

        outputNames = string(fieldnames(outputs));

        for nOut = 1:length(outputNames)
            curOut = outputs.(outputNames(nOut));

            if isempty(curOut)
                outputs.(outputNames(nOut)) = nan; % Set to nan if output empty
            end
        end
    catch err

        msg = [err.stack(1).name, ' Line ',...
            num2str(err.stack(1).line), '. ', err.message];

        logger.logError(msg);

        errorCode = cce.CalculationErrorState.CalcFailed;

        % Return empty outputs
        outputs.Timestamp = [];
        outputs.Calc_Sol_M = [];
        outputs.Calc_Sol_M_S = [];
    end

end

% Subroutines
function SolMatte_Lvl = CheckandCalc_Sol_M(SolEnt, MatEnt)

    if isempty(SolEnt)
        SolEnt = 0;
    end

    if isempty(MatEnt)
        SolMatte_Lvl = 0;  % Return no results if there's no matte level
    else
        SolMatte_Lvl = SolEnt(end) + MatEnt(end);
    end


end

function Calc_Sol_M_Slag = CheckandCalc_Sol_M_Slag(CalSolM, SlagEnt)

    if ~isempty(CalSolM) && ~isempty(SlagEnt) % Data entered for both
        Calc_Sol_M_Slag = CalSolM(end) + SlagEnt(end);
    else
        if isempty(CalSolM)
            CalSolM = 0;
        end
        if isempty(SlagEnt)
            SlagEnt = 0;
        end
        Calc_Sol_M_Slag = CalSolM(end) + SlagEnt(end);
    end

end

