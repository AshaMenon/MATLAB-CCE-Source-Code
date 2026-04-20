function [outputs,errorCode] = cceACEUSMLFurnaceFeed(parameters, inputs)

    logger = CCELogger(parameters.LogName, parameters.CalculationID, ...
        parameters.CalculationName, parameters.LogLevel);

    newOutTime = strrep(parameters.OutputTime, "T", " ");
    newOutTime = extractBefore(newOutTime, ".");

    ExeTime = datetime(newOutTime);
    ExeTime = ExeTime + hours(2);

    logger.logTrace("Current execution time being used: " + string(ExeTime))
    errorCode = cce.CalculationErrorState.Good;

    try
        %Calculate corrected transfered
        %Calculate recycle
        %Calculate New conc
        %Calculate SEC

        %Declarations
        tTol = 0.25; %time tolerance
        CalcErr = nan;
        LoPowerSEC = 120; %MWhr
        LoXferSEC = 0; %t

        first_date = ExeTime-days(1);
        second_date = ExeTime;

        first_date.Minute = 0;
        first_date.Second = 1;
        first_date.Hour = 5;
        second_date.Minute = 0;
        second_date.Second = 0;
        second_date.Hour = 5;

        outputs.Timestamp = [first_date; second_date];

        % totTime = inputs.ACE_xfr_2totTimestamps(1);
        % first_date.Second = totTime.Second;
        % second_date.Second = totTime.Second;

        first_dateMA = first_date + hours(1);

        %Corrected Transfer
        try
            %retrieve all correction factors

            tag.Values = inputs.M_Correcton_Factor_xfer;
            tag.Times = inputs.M_Correcton_Factor_xferTimestamps;
            CorrFac = inputs.M_Correcton_Factor_xfer(end);
            if isempty(CorrFac) || ismissing(CorrFac) || isnan(CorrFac)
                %default to 1 - no correction applied
                CorrFac = 1;
            end
            xferCorrFac = CorrFac;


            %retrieve all correction values
            tag.Values = inputs.M_DailyCorrection_xfer;
            tag.Times = inputs.M_DailyCorrection_xferTimestamps;
            [xferCorr, writeOutZero] = TranferCorr(tag, first_date, tTol);

            if isnan(xferCorr) || isempty(xferCorr)
                xferCorr = 0;
            end

            if writeOutZero
                outputs.M_DailyCorrection_xfer = [xferCorr; xferCorr];
            end

            % tag.Values = inputs.ACE_xfr_2tot;
            % tag.Times = inputs.ACE_xfr_2totTimestamps;
            % xfer = getValueAtTime(tag, first_date);

            timeIdx = isbetween(inputs.ACE_xfr_2totTimestamps, first_date, second_date);
            filteredVals = inputs.ACE_xfr_2tot(timeIdx);

            xfer = filteredVals(1);

            if isempty(xfer)
                xfer = 0;
            end

            %adjust
            %%x factor then add adjustment
            xfer = (xfer * xferCorrFac) + xferCorr;

            
            %writeout
            %Write out total
            outputs.ACE_xfer_Tot = [xfer; xfer];
            outputs.ACE_Fed_Tot = [xfer; xfer];

        catch ex
            logger.logError("#***USMLFurnaceFeed Total transfered Exec Time: " + ...
                string(ExeTime) + " NowTime: " + string(datetime) + ...
                "  -First Date: " + string(first_date) + ...
                "  -Error: " + ex.message + " Line: " + ex.stack.line)

            %Write out total
            outputs.ACE_xfer_Tot = [CalcErr; CalcErr];
            %Write out to furnaces
            outputs.ACE_Fed_Tot = [CalcErr; CalcErr];

        end

        %Calculated feed from sec manual input
        try
            %time in seconds furnace was on from manual input

            %Get power data
            inPiAcePower.Values = inputs.MWhr_Tot;
            inPiAcePower.Times = inputs.MWhr_TotTimestamps;
            % first_date.Second = inputs.MWhr_TotTimestamps(1).Second;

            inPiRawPower.Values = inputs.MW;
            inPiRawPower.Times = inputs.MWTimestamps;

            inPiFCEOn.Values = inputs.M_On;
            inPiFCEOn.Times = inputs.M_OnTimestamps;

            Power = GetPowerVals(inPiAcePower, inPiRawPower, inPiFCEOn, first_date, second_date, parameters, logger);

            if isempty(Power) || isnan(Power)
                Power = 0;
            end

            %retrieve all SEC manual values
            % inPiAceSEC.Values = inputs.M_Sec_Feedcalc;
            % inPiAceSEC.Times = inputs.M_Sec_FeedcalcTimestamps;
            % SEC = GetLastGood(inPiAceSEC, second_date + hours(1));

            SEC = inputs.M_Sec_Feedcalc(end);

            if isempty(SEC) || isnan(SEC) || ismissing(SEC)
                %default to 1 - no correction applied
                SEC = 1;
            end
            SECMAN = SEC;

            %total fed

            if SECMAN ~= 0
                calcfeed = (Power / SECMAN);
            else
                calcfeed = 0;
            end

            %writeout
            %Write out total
            outputs.ACE_TotSmelted_Calc_2Tot = [calcfeed; calcfeed];
            outputs.ACE_Smelted_Calc_2Tot = [calcfeed; calcfeed];

        catch ex
            logger.logError("#***USMLFurnaceFeed Total calc feed Exec Time: " + ...
                string(ExeTime) + " NowTime: " + string(datetime) + ...
                "  -First Date: " + string(first_date) + "  -Error: " + ex.message + " Line: " + ex.stack.line)

            %Write out total
            outputs.ACE_TotSmelted_Calc_2Tot = [CalcErr; CalcErr];
            outputs.ACE_Smelted_Calc_2Tot = [CalcErr; CalcErr];

        end

        %use calculated feed to get newconc and recycle
        feed = calcfeed;

        %total_feed < 0

        %Calc NewConc and Recycle
        try
            % Get Lime
            % inPiAceLime.Values = inputs.MW;
            % inPiAceLime.Times = inputs.MWTimestamps;
            % Lime = getValueAtTime(inPiAceLime, first_date);

            timeIdx = isbetween(inputs.M_Lime_FedTimestamps,first_date,second_date);
            filteredVals = inputs.M_Lime_Fed(timeIdx);

            Lime = filteredVals(1);

            if isempty(Lime) || ismissing(Lime) || isnan(Lime)
                Lime = 0;
            end

            %Get the concentrate factor
            % M_RecyleRatio.Values = inputs.M_RecyleRatio;
            % M_RecyleRatio.Times = inputs.M_RecyleRatioTimestamps;
            % ConcRatio = CommonFunctions.GetLastGood(M_RecyleRatio, first_dateMA);
            timeIdx = inputs.M_RecyleRatioTimestamps <= first_dateMA;
            filteredVals = inputs.M_RecyleRatio(timeIdx);

            ConcRatio = filteredVals(end);

            if isempty(ConcRatio) || ismissing(ConcRatio) || isnan(ConcRatio)
                ConcRatio = 0;
            end

            %recycle = (correctted trasfer - lime) * (1 - ConcRatio)
            recycle = (feed - Lime) * (1 - ConcRatio);

            %NewConc = corrected transfer - lime - recycle
            newConc = feed - Lime - recycle;

            %writeout
            %Write out total Recycle
            outputs.ACE_PlantRecycle_Tot = [recycle; recycle];

            %write out total NewConc
            outputs.ACE_NewConc_Tot = [newConc; newConc];

        catch ex
            logger.logError("#***USMLFurnaceFeed Total Recycle and New Conc Exec Time: " + ...
                string(ExeTime) + " NowTime: " + string(datetime) + ...
                "  -First Date: " + string(first_date) + "  -Error: " + ...
                ex.message + " Line: " + ex.stack.line)

            %Write out total Recycle
            outputs.ACE_PlantRecycle_Tot = [CalcErr; CalcErr];

            %write out total NewConc
            outputs.ACE_NewConc_Tot = [CalcErr; CalcErr];

        end

        %SEC for furnace 2
        try
            %Check feed and power first
            if Power < LoPowerSEC
                SECNewConcDig = 2; %Low/No Power
                SECxferDig = 2;
            elseif xfer <= LoXferSEC

                SECxferDig = 1; % No Feed
                SECNewConcDig = 1;
            else
                SECxferDig = 0; %Good
                SECNewConcDig = 0;
            end

            SECNewConc = Power / newConc * 1000; %x1000 For kW/t
            SECxfer = Power / xfer * 1000; %x1000 For kW/t

            if isnan(SECNewConc)
                SECNewConc = 0;
            end
            if isnan(SECxfer)
                SECxfer = 0;
            end

            %Write out to furnaces SEC
            outputs.ACE_SEC_xfer_NewConc = [SECNewConc; SECNewConc];
            outputs.ACE_SEC_xfer_BD = [SECxfer; SECxfer];
            outputs.ACE_SEC_xfer_NewConc_Dig = [SECNewConcDig; SECNewConcDig];
            outputs.ACE_SEC_xfer_BD_Dig = [SECxferDig; SECxferDig];


        catch ex
            logger.logError("#***USMLFurnaceFeed FCE SEC Exec Time: " + ...
                string(ExeTime) + " NowTime: " + string(datetime) + ...
                "  -First Date: " + string(first_date) + "  -Error: " + ...
                ex.message + " Line: " + ex.stack.line)

            %Write out to furnaces SEC
            outputs.ACE_SEC_xfer_NewConc = [CalcErr; CalcErr];
            outputs.ACE_SEC_xfer_BD = [CalcErr; CalcErr];

        end

        outputNames = string(fieldnames(outputs));

        for nOut = 1:length(outputNames)
            curOut = outputs.(outputNames(nOut));

            if isempty(curOut)
                outputs.(outputNames(nOut)) = nan; % Set to nan if output empty
            end
        end

        logger.logTrace("Complete")
    catch err
        outputs.ACE_Fed_Tot = [];
        outputs.ACE_NewConc_Tot = [];
        outputs.ACE_PlantRecycle_Tot = [];
        outputs.ACE_SEC_xfer_BD = [];
        outputs.ACE_SEC_xfer_BD_Dig = [];
        outputs.ACE_SEC_xfer_NewConc = [];
        outputs.ACE_SEC_xfer_NewConc_Dig = [];
        outputs.ACE_Smelted_Calc_2Tot = [];
        outputs.ACE_TotSmelted_Calc_2Tot = [];
        outputs.ACE_xfer_Tot = [];
        outputs.Timestamp = [];

        logger.logError("Line: " + err.stack(1).line + ": " + err.message)
        if errorCode == cce.CalculationErrorState.Good || isempty(errorCode)
            errorCode = cce.CalculationErrorState.CalcFailed;
        end
    end
end

function val = getValueAtTime(tag,searchTime)
    idx = tag.Times == searchTime;

    if ~isempty(idx)
        val = tag.Values(idx);
    else
        val = 0;
    end
end

function [xfer_Corr, writeOutZero] = TranferCorr(PiTag, GetDate, tTol)

    %Corrected bone dry transfered - with manual transfer correction input
    % The transfer correction is entered to correct for errors in the transfer system PLC measurments.
    % the correction is per furnace
    first_dateMA = GetDate + hours(1);

    %The transfer correction amount is written in at 6am by accounting, so retrieve then.
    xfer_CorrectionPIGet = CommonFunctions.GetValueAtTime(PiTag, first_dateMA, tTol);
    writeOutZero = false;

    if isempty(xfer_CorrectionPIGet)
        % If the correction amount is 0, write out a 0 to the normal manual input write-out time = 06:01 at the start of the production day.
        % This allows an ACE re-Calculation to be triggered when a correction value is entered later in the day

        xfer_Corr = 0;
        writeOutZero = true;
        % CommonFunctions.SendViaPISDK(MyBase.Context, M_DailyCorrection_xfer.Tag, xfer_Corr, first_dateMA.LocalDate)

    else
        xfer_Corr = xfer_CorrectionPIGet.Value;
        if ~isnumeric(xfer_Corr) || isempty(xfer_Corr) || isnan(xfer_Corr)
            xfer_Corr = 0;
        end

    end
end

function inPowerVals = GetPowerVals(inAcePoints,inPiRawPowerPoints, ...
        inPiOnPoints, FirstDate, SecondDate, parameters, logger)

    %get on time
    OnTime = TimeEQ(inPiOnPoints, FirstDate, SecondDate, "On", parameters);

    Pval = 0;

    if OnTime < 86400 - 3600
        % furnace on for 23 hours or less
        if OnTime <= 3600
            %furnace on for less than 1 hour
            Pval = 0;
        else
            % get power total from expresion, total power wihle FCE = "On"
            Pval = totalPowerWhenOn(inPiRawPowerPoints, inPiOnPoints, FirstDate, SecondDate);

        end

    else
        timeIdx = isbetween(inAcePoints.Times,FirstDate,SecondDate);
        filteredVals = inAcePoints.Values(timeIdx);

        Res = filteredVals(1);
        % Res = getValueAtTime(inAcePoints, FirstDate);
        if ~isempty(Res)
            Pval = Res;
            logger.logTrace(Res)
        else
            Pval = 0;
        end

    end

    inPowerVals = Pval;
end

function TotPower = totalPowerWhenOn(PowerTag, FCEON, FirstDate, SecondDate)

    try

        idx = isbetween(FCEON.Times, FirstDate, SecondDate) & FCEON.Values == "On";
        onTimes = FCEON.Times(idx);

        powerTagIdx = PowerTag.Times == onTimes;
        TotPower = sum(PowerTag.Values(powerTagIdx));

        % as with total for PI convert to hourly
        TotPower = TotPower * 24;

    catch ex
        throw(MException("USMLFurnaceFeed:inputError", "Error on Power with switch calc " + ex.message))
    end
end

function TotTime = TimeEQ(inPiOnPoints, FirstDate, SecondDate, val, parameters)

    try
        idx = isbetween(inPiOnPoints.Times, FirstDate, SecondDate);

        if nnz(idx) > 0
            times = inPiOnPoints.Times(idx);
            values = inPiOnPoints.Values(idx);

            timesDiff = diff([times; SecondDate]);
            valDiff = [diff(values == val); 1];
            valDiffMultiplier = valDiff >= 0;

            TotTime = sum(timesDiff*valDiffMultiplier);
        else
            if isstring(parameters.LastState)
                if lower(parameters.LastState) == "on"
                    TotTime = 86400;
                else
                    TotTime = 0;
                end
            elseif isnumeric(parameters.LastState)
                if parameters.LastState == 1
                    TotTime = 86400;
                else
                    TotTime = 0;
                end
            else
                TotTime = 0;
            end
        end
    catch
        TotTime = 86400;
    end
end

function point = GetLastGood(Tag, CurTime)

try

    idx = find(Tag.Times < CurTime, 1, "last");

    if ~isempty(idx)

        point.Value = Tag.Values(idx);
        point.Time = Tag.Times(idx);

    else
        point.Value = [];
        point.Time = [];
    end

catch

    point.Value = [];
    point.Time = [];

end
end