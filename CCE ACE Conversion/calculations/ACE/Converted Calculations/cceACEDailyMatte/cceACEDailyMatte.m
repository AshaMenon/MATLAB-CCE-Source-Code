function [outputs,errorCode] = cceACEDailyMatte(parameters,inputs)

    logger = CCELogger(parameters.LogName, parameters.CalculationID, ...
        parameters.CalculationName, parameters.LogLevel);

    newOutTime = strrep(parameters.OutputTime, "T", " ");
    newOutTime = extractBefore(newOutTime, ".");

    ExeTime = datetime(newOutTime);

    logger.logTrace("Current execution time being used: " + datestr(ExeTime))

    try
        % Calculation logic goes here
        TriggerCalcTimeOffset = 0;
        Offset  = 5 * 3600;
        DaysBack  = 14;

        CalcTime = ExeTime;

        logger.logInfo("#**DailyMatte CalcTimes Exec Time :" + datestr(CalcTime) + " NowTime: " + string(datetime("now")))

        conversion4E  = 1 / 31.1035;
        DaysTogetRealData = 5; % Number of days elapsed to start looking for real matte assay

        logger.logTrace("Complete")

        %dates = CommonFunctions.GenerateTotPeriodDates(CalcTime, 86400, Offset); % (last value in delimit is time totaliser resets)
        %first_date = dates{1}; 
        %second_date = dates{2};

        first_date = ExeTime - caldays(1);
        first_date.Hour = 5;
        first_date.Minute = 0;
        first_date.Second = 1;

        second_date = first_date + caldays(1);
        second_date.Second = 0;

        logger.logInfo("#**DailyMatte CalcTimes Exec Time :" + string(CalcTime) + " NowTime: " + string(datetime("now")))

        % Initialise outputs
        ACE_Matte_fall = struct;
        outputs = struct;

        % Input data

        try
            % Capacity property references a separate property
            % idxDates = seconds(inputs.CastingSilicaEntrain_PerTimestamps -CalcTime) <= 1;
            CastingSi_per = inputs.CastingSilicaEntrain_Per(end);
            logger.logTrace(CastingSi_per)
        catch err
            CastingSi_per = 20;
            logger.logError("#**DailyMatte get prop error. Exec Time :" + string(CalcTime) + " NowTime: " + string(datetime("now")))
            logger.logError("Line: " + err.stack.line + ": " + err.message)
        end

        % Get totals
        try
            % 2 point ACE totalisers get data
            Tag = struct;
            Tag.Value = inputs.MatteGran;
            Tag.TimeStamp = inputs.MatteGranTimestamps;
            P_MatteGran = CommonFunctions.GetACE2TotValue(Tag, ExeTime, 86400, 0.5).Values;

            if isempty(P_MatteGran) || isnan(P_MatteGran)
                P_MatteGran = 0;
            end

            % Ramping tags get data
            Tag=  struct;
            Tag.Value = inputs.Smelted;
            Tag.TimeStamp = inputs.SmeltedTimestamps;
            P_FCE2BD = CommonFunctions.GetACE2TotValue(Tag, CalcTime, 86400, 0.5).Values;

            if isempty(P_FCE2BD) || isnan(P_FCE2BD)
                P_FCE2BD = 0;
            end

            % Get exact day
            Tag = struct;
            Tag.Value = inputs.MA_FCE2_4E;
            Tag.Timestamp = inputs.MA_FCE2_4ETimestamps;
            MA_FCE24E = CommonFunctions.GetLastGood(Tag, first_date+hours(2)).Values; %data written at 06:00:01

            % Get 4 E values try data for specific day else get previous, if <=0 get default values from properties
            if isempty(MA_FCE24E)
                MA_FCE24E = 0;
            end

            if MA_FCE24E <= 0
                Tag = struct;
                Tag.Value = inputs.MA_FCE2_4E;
                Tag.Timestamp = inputs.MA_FCE2_4ETimestamps;
                MA_FCE24E = CommonFunctions.GetLastGood(Tag, CalcTime).Values;
            end

            if isempty(MA_FCE24E)
                DefaultFCE2Matte_4E = inputs.DefaultFCE2_4E(end);
                MA_FCE24E = DefaultFCE2Matte_4E;
            end

            if isempty(MA_FCE24E) || isnan(MA_FCE24E)
                MA_FCE24E = 0;
            end

            % The Cast to Pits amount is written in at 6am by accounting, so retrieve then. Manual data is written by the metal accountants to the start of the production day at 06:00:00
            Tag = struct;
            Tag.Value = inputs.MatteEast_E;
            Tag.Timestamp = inputs.MatteEast_ETimestamps;
            total_MatteEastPIGet = sum(CommonFunctions.GetInputEvents(Tag, first_date+hours(2), second_date+hours(2), 0, "event").Values);

            Tag = struct;
            Tag.Value = inputs.MatteWest_E;
            Tag.Timestamp = inputs.MatteWest_ETimestamps;
            total_MatteWestPIGet = sum(CommonFunctions.GetInputEvents(Tag, first_date+hours(2), second_date+hours(2), 0, "event").Values);

            Tag = struct;
            Tag.Value = inputs.MatteCentre_E;
            Tag.Timestamp = inputs.MatteCentre_ETimestamps;
            total_MatteCenterPIGet  = sum(CommonFunctions.GetInputEvents(Tag, first_date+hours(2), second_date+hours(2), 0, "event").Values);

            M_MatteCast = total_MatteEastPIGet + total_MatteWestPIGet + total_MatteCenterPIGet;


        catch err
            logger.logError("#**DailyMatte Data get error. Exec Time:" + datestr(CalcTime) + " NowTime: " + string(datetime("now")))
            logger.logError("Line: " + err.stack.line + ": " + err.message)
        end

        try
            ACE_MatteProd.Value = P_MatteGran + M_MatteCast;
            ACE_SiInMatte.Value = (M_MatteCast * CastingSi_per) / 100;
            ACE_MatteProdSi.Value = ACE_MatteProd.Value + ACE_SiInMatte.Value;

            if (P_FCE2BD) > 100  % Do not calculate if there is no feed - large values result
                ACE_Matte_fall.Value = ACE_MatteProd.Value / (P_FCE2BD) * 100;
            else
                ACE_Matte_fall.Value = 0; %"No Feed";
            end


            % Proportion 4E on BD fed
            Tot4E = (MA_FCE24E * P_FCE2BD) / (P_FCE2BD);

            ACE_MatteProd_4E = ACE_MatteProd.Value * Tot4E * conversion4E;

            ACE_SlagProd = P_FCE2BD - ACE_MatteProd.Value; % Slag produced from a simple mass balance;
            if ACE_SlagProd < 0
                ACE_SlagProd = 0;
            end

        catch err
            logger.logWarning("#**DailyMatte Calc error. Exec Time :" + datestr(CalcTime) + " NowTime: " + string(datetime("now")))
            logger.logError("Line: " + err.stack.line + ": " + err.message)
        end

        try
            % Outputs
            outputs.ACE_MatteProd_2Tot = ACE_MatteProd.Value;   % Total produced
            outputs.ACE_SiInMatte_2Tot = ACE_SiInMatte.Value;  % Total silica in matte cast
            outputs.ACE_MatteProdSi_2Tot = ACE_MatteProdSi.Value; % Total matte and silica produced
            outputs.ACE_Matte_fallBD_2Tot = ACE_Matte_fall.Value; % Total fall on BD
            outputs.ACE_MatteProd_4E_2Tot = ACE_MatteProd_4E; % Total 4e in matte produced
            outputs.ACE_Slag_2Tot = ACE_SlagProd; % Total 4e in matte dried

            errorCode = cce.CalculationErrorState.Good;
        catch err
            logger.logError("#**DailyMatte Write error. Exec Time:" + datestr(CalcTime) + " NowTime: " + string(datetime("now")))
            logger.logError("Line: " + err.stack.line + ": " + err.message)
            throw(err)
        end

        ExeTime.Hour = 5;
        ExeTime.Minute = 0;
        ExeTime.Second = 1;
        outputs.Timestamp = ExeTime;

        outputNames = string(fieldnames(outputs));

        for nOut = 1:length(outputNames)
            curOut = outputs.(outputNames(nOut));

            if isempty(curOut)
                outputs.(outputNames(nOut)) = nan; % Set to nan if output empty
            end
        end

    catch err

        logger.logError("Line: " + err.stack.line + ": " + err.message)

        outputs.ACE_MatteProd_2Tot = [];   % Total produced
        outputs.ACE_SiInMatte_2Tot = [];  % Total silica in matte cast
        outputs.ACE_MatteProdSi_2Tot = []; % Total matte and silica produced
        outputs.ACE_Matte_fallBD_2Tot = []; % Total fall on BD
        outputs.ACE_MatteProd_4E_2Tot = []; % Total 4e in matte produced
        outputs.ACE_Slag_2Tot = []; % Total 4e in matte dried
        outputs.Timestamp = [];

        errorCode = cce.CalculationErrorState.CalcFailed;
    end
