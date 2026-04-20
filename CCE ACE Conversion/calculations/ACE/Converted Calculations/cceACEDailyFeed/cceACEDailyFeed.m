function [outputs,errorCode] = cceACEDailyFeed(parameters,inputs)

    logger = CCELogger(parameters.LogName, parameters.CalculationID, ...
        parameters.CalculationName, parameters.LogLevel);

    newOutTime = strrep(parameters.OutputTime, "T", " ");
    newOutTime = extractBefore(newOutTime, ".");

    ExeTime = datetime(newOutTime);

    errorCode = cce.CalculationErrorState.Good;

    logger.logTrace("Current execution time being used: " + string(ExeTime))

    % Variable Initialisation
    TotaliseTime = 5;
    CalcStart  = ExeTime;
    %xfer_Correction = 0;
    %total_recycle = [];
    %total_lime = [];
    %Corrected_Total_feed = [];

    %FCE1_xfer = 0;
    %FCE2_xfer = 0;
    %recycleFCE1 = 0;
    %recycleFCE2 = 0;

    logger.logInfo("#012DailyFeed  Start Calc. Exec time: "  + string(CalcStart) +...
        "; Now time = " + string(datetime("now")))

    % Outputs (at first and second dates)
    outputs = struct;
    try
        % Loop calculations until end if the ratio has changed in the past
        % Calculation was triggered on
        Tag = struct;
        Tag.Value = inputs.ConcentrateRatio;
        Tag.Timestamp = inputs.ConcentrateRatioTimestamps;


        %Calculate up to last date
        lastPIdate = struct;
        lastPIdate.UTCSeconds = Tag.Timestamp(end);

        CalcStartTimeofDay = timeofday(CalcStart);
        LastDate = lastPIdate.UTCSeconds + CalcStartTimeofDay;

        % Get days to calculate forward
        DaysToCalcForward = days(LastDate -CalcStart);

        % Generate Date list
        CalcDaysToRun = [];

        for Day = 1:ceil(DaysToCalcForward)
            addedDate = CalcStart + days(Day-1);
            CalcDaysToRun = [CalcDaysToRun;addedDate];
        end

        CalcDate = CalcDaysToRun;

        % Time for current calc
        % Note the calculation runs for the period before the calculation time, if calc time is 2019-05-15 06:30:23, the calc period is 2019-05-14 05:00:01 to 2019-05-15 05:00:00
        %ExeTime = CalcDate;


        % Retrieving the right timestamp for reading
        nowtime = CalcDate;
        starttime = nowtime;
        starttime.Hour = TotaliseTime;
        starttime.Minute = -140;
        starttime.Second = 0;

        endtime = nowtime;
        endtime.Hour = TotaliseTime;
        endtime.Minute = 40;
        endtime.Second = 0;


        if any(hour(nowtime) < TotaliseTime)   %It's executed earlier than today's values - get yesterday's values
            starttime = starttime + days(-1);
            endtime = endtime + days(-1);
        end

        % Retrieve the write-dates
        % dates = CommonFunctions.GenerateTotPeriodDates(ExeTime, 86400, 18000);
        %
        % first_date = dates{1};
        % second_date = dates{2};
        second_date = ExeTime;
        second_date.Hour = 5;
        second_date.Minute = 0;
        second_date.Second = 0;

        first_date = second_date - caldays(1);
        first_date.Second = 1;

        second_datePITime = second_date;

        try
            % The transfer correction amount is written in at 06:00:01 AM so look for the value using the day end going back
            % Tag = struct;
            % Tag.Value = inputs.DailyCorrection_xfer;
            % Tag.Timestamp = inputs.DailyCorrection_xferTimestamps;
            % xfer_CorrectionPIGet = CommonFunctions.GetLastGood(Tag, second_datePITime);
            idx = inputs.DailyCorrection_xferTimestamps <= second_datePITime;
            filteredVals = inputs.DailyCorrection_xfer(idx);

            if ~isempty(filteredVals) && ~ismissing(filteredVals)
                xfer_CorrectionPIGet.Value = filteredVals(end);
            else
                xfer_CorrectionPIGet.Value = 0;
            end

            if isempty(xfer_CorrectionPIGet.Value) || isnan(xfer_CorrectionPIGet.Value) || ismissing(xfer_CorrectionPIGet.Value)
                % 2022 - correction factor now applies until set to 0 or bad If the correction amount is 0, write out a 0 to the normal manual input write-out time = 06:00 at the end of the production day.
                % This allows an ACE re-Calculation to be triggered when a correction value is entered later in the day
                xfer_Correction = 0;
            else
                xfer_Correction = xfer_CorrectionPIGet.Value;
            end

        catch err
            logger.logError("#012DailyFeed  transfer correction error Exec time: "  + string(ExeTime))
            msg = [err.stack(1).name, ' Line ',...
                num2str(err.stack(1).line), '. ', err.message];

            logger.logError(msg);
        end

        % Recycle calculations
        try

            % Calculate the total feed
            idx1 = (inputs.Tot_trf_1Timestamps >= starttime) & (inputs.Tot_trf_1Timestamps <= endtime);
            FCE1_xfer = max(inputs.Tot_trf_1(idx1));
            idx2 = (inputs.Tot_trf_2Timestamps >= starttime) & (inputs.Tot_trf_2Timestamps <= endtime);
            FCE2_xfer = max(inputs.Tot_trf_2(idx2));
            ACETag.Value = inputs.ACE_Tot_trf;
            ACETag.TimeStamp = inputs.ACE_Tot_trfTimestamps;
            SCF1_xfer = CommonFunctions.GetACE2TotValue(ACETag, CalcDate, 86400, 0.1);
            SCF1_xfer = SCF1_xfer.Value;

            if isempty(SCF1_xfer)
                SCF1_xfer = 0;
            end

            if isempty(FCE1_xfer)
                FCE1_xfer = 0;
            end

            if isempty(FCE2_xfer)
                FCE2_xfer = 0;
            end


            total_feed = sum([FCE1_xfer,FCE2_xfer,SCF1_xfer],2,'omitnan'); % Ramping tags, totals at period end

            if isnan(total_feed) || isempty(total_feed)
                total_feed = 0;
            end


            % 20220126 was Corrected_Total_feed = total_feed + xfer_Correction
            total_feed = total_feed .* (1 - xfer_Correction / 100);

            Corrected_Total_feed = total_feed;

            outputs.ACE_xfer_Tot  = Corrected_Total_feed;

            % Tag = struct;
            % Tag.Value = inputs.ConcentrateRatio;
            % Tag.Timestamp =inputs.ConcentrateRatioTimestamps;
            % ConcRatio = CommonFunctions.GetLastGood(Tag, CalcDate).Value;

            idx = inputs.ConcentrateRatioTimestamps <= CalcDate;
            filteredVals = inputs.ConcentrateRatio(idx);
            

            if ~isempty(filteredVals) && ~ismissing(filteredVals)
                ConcRatio = filteredVals(end);
            else
                ConcRatio = 0;
            end

            % ConcRatio = fillmissing(empty2nan(ConcRatio),'constant',0);

            % Calculate the total recycle from the factor

            total_recycle = total_feed .* (1 - ConcRatio);

            try
                outputs.DailyPlantRecycle  = total_recycle;

            catch err
                logger.logError("#012DailyFeed  Recycle Calc 1 error. Exec time: "  + string(ExeTime))

                outputs.ACE_xfer_Tot  = nan; %("Bad Data");
                outputs.DailyPlantRecycle  = nan; %("Bad Data"); % Total bone dry
                msg = [err.stack(1).name, ' Line ',...
                    num2str(err.stack(1).line), '. ', err.message];

                logger.logError(msg);


            end


            % Generate the ratios

            idx1 = (inputs.Tot_trf_1Timestamps >= starttime) & (inputs.Tot_trf_1Timestamps <= endtime);
            idx2 = (inputs.Tot_trf_2Timestamps >= starttime) & (inputs.Tot_trf_2Timestamps <= endtime);
            % recycle = [max(inputs.Tot_trf_1(idx1)) ./ total_feed,...
            %     max(inputs.Tot_trf_2(idx2)) ./ total_feed,...
            %     SCF1_xfer ./ total_feed] ;
            recycle1 = max(inputs.Tot_trf_1(idx1)) ./ total_feed;
            recycle2 = max(inputs.Tot_trf_2(idx2)) ./ total_feed;
            recycle3 = SCF1_xfer ./ total_feed;

            if isempty(recycle1) 
                recycle1 = 0;
            end

            if isempty(recycle2)
                recycle2 = 0;
            end

            if isempty(recycle3)
                recycle3 = 0;
            end

            recycle = [recycle1, recycle2, recycle3];

            if isempty(total_recycle)
                total_recycle=0;
            end

            % Calculate the magnitudes
            for i = 1:size(recycle,2)
                recycle(:,i) = recycle(:,i).*total_recycle;
            end

            recycleFCE1 = recycle(:,1);
            recycleFCE2 = recycle(:,2);

            % A special case - If no feed, write out no feed.
            % Transmit the recycle values
            outputs.ACE_Tot_Recycle  = recycle(:,1);
            outputs.ACE_Tot_Recycle_2  = recycle(:,2);
            outputs.ACE_Tot_Recycle_3  = recycle(:,3);

            noFeedIdx = total_feed == 0;
            outputs.ACE_Tot_Recycle(noFeedIdx) = nan; %("No Feed");
            outputs.ACE_Tot_Recycle_2(noFeedIdx) = nan; %("No Feed");
            outputs.ACE_Tot_Recycle_3(noFeedIdx) = nan; %("No Feed");


        catch err

            logger.logError("#012DailyFeed  Recycle Calc outer error. Exec time: "  + string(ExeTime))

            outputs.ACE_Tot_Lime  = nan; %("Bad Data");
            outputs.ACE_Tot_Lime_2  = nan; %("Bad Data");
            outputs.ACE_Tot_Lime_3  = nan; %("Bad Data");

            msg = [err.stack(1).name, ' Line ',...
                num2str(err.stack(1).line), '. ', err.message];

            logger.logError(msg);

        end

        try
            % Get total power
            Tag = struct;
            Tag.Value = inputs.MWhr_Tot_1;
            Tag.TimeStamp = inputs.MWhr_Tot_1Timestamps;
            Tot_Power_FCE1 = CommonFunctions.GetTotValue(Tag, ExeTime).Value; % totaliser tag, start and end output

            if isempty(Tot_Power_FCE1)
                Tot_Power_FCE1 = 0;
            end

            Tag = struct;
            Tag.Value = inputs.MWhr_Tot_2;
            Tag.TimeStamp = inputs.MWhr_Tot_2Timestamps;
            Tot_Power_FCE2 = CommonFunctions.GetTotValue(Tag, ExeTime).Value; % totaliser tag, start and end output

            if isempty(Tot_Power_FCE2)
                Tot_Power_FCE2 = 0;
            end

            % Calc SEC on new conc

            try
                SEC_NewConc_FCE1 = (Tot_Power_FCE1(end) ./ (FCE1_xfer(end) - recycleFCE1(end))) .* 1000; % x1000 For kW
            catch err
                SEC_NewConc_FCE1 = nan;

                msg = [err.stack(1).name, ' Line ',...
                    num2str(err.stack(1).line), '. ', err.message];

                logger.logError(msg);
            end

            % % If no feed, set to say so
            % zeroIdx = (FCE1_xfer) == 0;
            % SEC_NewConc_FCE1(zeroIdx) = nan; %("No Feed");
            %
            % % If no power, set to say so
            % lowPowerIdx =  Tot_Power_FCE1 < 120;
            % SEC_NewConc_FCE1(lowPowerIdx) = nan; %("Low/No Power");
            %
            %
            % % If negative, set to say so
            % negIdx = (Tot_Power_FCE1 ./ (FCE1_xfer - recycleFCE1) < zeros(numel(recycleFCE1),1));
            % SEC_NewConc_FCE1(negIdx) = nan; %("Bad Input");

            try
                SEC_NewConc_FCE2 = (Tot_Power_FCE2(end) ./ (FCE2_xfer(end) - recycleFCE2(end))) .* 1000.0; % x1000 For kW
            catch err
                SEC_NewConc_FCE2 = nan;

                msg = [err.stack(1).name, ' Line ',...
                    num2str(err.stack(1).line), '. ', err.message];

                logger.logError(msg);
            end

            % % If no feed, set to say so
            % noFeedIdx =  (FCE2_xfer) == 0;
            % SEC_NewConc_FCE2(noFeedIdx) = nan; %("No Feed");
            %
            %
            % % If no power, set to say so
            % lowPowerIdx = Tot_Power_FCE2 < 120;
            % SEC_NewConc_FCE2(lowPowerIdx) = nan; %("Low/No Power");
            %
            % %If negative, set to say so
            % negIdx =  (Tot_Power_FCE2 / (FCE2_xfer - recycleFCE2) < 0);
            % SEC_NewConc_FCE2(negIdx) = nan; %("Bad Input");

            outputs.ACE_SEC_xfer_NewConc = SEC_NewConc_FCE1;
            outputs.ACE_SEC_xfer_NewConc_2  = SEC_NewConc_FCE2;


        catch err
            logger.logWarning("#012DailyFeed  SEC error. Exec time: "  + string(ExeTime))

            outputs.ACE_SEC_xfer_NewConc = nan; %("Bad Data");
            outputs.ACE_SEC_xfer_NewConc_2  = nan; %("Bad Data");

            msg = [err.stack(1).name, ' Line ',...
                num2str(err.stack(1).line), '. ', err.message];

            logger.logError(msg);

            %

        end

        % Lime per furnace calculations
        try
            % Get the data of lime to system 1 and system 2
            Tag = struct;
            Tag.Value = inputs.System1_Lime;
            Tag.TimeStamp = inputs.System1_LimeTimestamps;
            sys1_Mass = (CommonFunctions.GetTotValue(Tag, ExeTime).Value) ./ 1000;

            if isempty(sys1_Mass)
                sys1_Mass = 0;
            end

            Tag = struct;
            Tag.Value = inputs.System2_Lime;
            Tag.TimeStamp = inputs.System2_LimeTimestamps;
            sys2_Mass  = (CommonFunctions.GetTotValue(Tag, ExeTime).Value) ./ 1000;

            if isempty(sys2_Mass)
                sys2_Mass = 0;
            end

            % Get the ratio of system 1 to system 2
            total_bin_lime = sys1_Mass + sys2_Mass;
            sys1_ratio = sys1_Mass ./ total_bin_lime;
            sys2_ratio = sys2_Mass ./ total_bin_lime;


            % Get the bonedry amounts for each furnace wrt to each system
            idxDates = (inputs.xferTot_System1_EastTimestamps >= starttime) & (inputs.xferTot_System1_EastTimestamps <= endtime);
            total_fce1_sys1 = zeros(numel(idxDates),1);
            total_fce2_sys1 = zeros(numel(idxDates),1);
            total_scf_sys1 = zeros(numel(idxDates),1);

            xferTot_System1_East = inputs.xferTot_System1_East(idxDates);
            xferTot_System1_West = inputs.xferTot_System1_West(idxDates);
            xferTot_System1_East_2 = inputs.xferTot_System1_East_2(idxDates);
            xferTot_System1_West_2 = inputs.xferTot_System1_West_2(idxDates);
            xferTot_System1_East_3 =inputs.xferTot_System1_East_3(idxDates);
            xferTot_System1_West_3 = inputs.xferTot_System1_West_3(idxDates);

            fce1numIdx =  arrayfun(@isnumeric,xferTot_System1_East) & arrayfun(@isnumeric,xferTot_System1_West);
            if sum(fce1numIdx) > 0
                total_fce1_sys1(fce1numIdx) = max(xferTot_System1_East(fce1numIdx),2) + max(xferTot_System1_West(fce1numIdx),2);
            end

            fce2numIdx =  arrayfun(@isnumeric,xferTot_System1_East_2) & arrayfun(@isnumeric,xferTot_System1_West_2);
            if sum(fce2numIdx) > 0
                total_fce2_sys1(fce2numIdx) = max(xferTot_System1_East_2(fce2numIdx),2) + max(xferTot_System1_West_2(fce2numIdx),2);
            end

            scfnumIdx = arrayfun(@isnumeric,xferTot_System1_East_3) & arrayfun(@isnumeric,xferTot_System1_West_3);
            if sum(scfnumIdx) > 0
                total_scf_sys1(scfnumIdx) = max(xferTot_System1_East_3(scfnumIdx),2) + max(xferTot_System1_West_3(scfnumIdx),2);
            end


            total_bonedry_sys1 = total_fce1_sys1 + total_fce2_sys1 + total_scf_sys1;

            total_fce1_sys2 = zeros(numel(idxDates),1);
            total_fce2_sys2 = zeros(numel(idxDates),1);
            total_scf_sys2 = zeros(numel(idxDates),1);

            xferTot_System2_East = inputs.xferTot_System2_East(idxDates);
            xferTot_System2_West = inputs.xferTot_System2_West(idxDates);
            xferTot_System2_East_2 = inputs.xferTot_System2_East_2(idxDates);
            xferTot_System2_West_2 = inputs.xferTot_System2_West_2(idxDates);
            xferTot_System2_East_3 = inputs.xferTot_System2_East_3(idxDates);
            xferTot_System2_West_3 = inputs.xferTot_System2_West_3(idxDates);

            fce1numIdx =  arrayfun(@isnumeric,xferTot_System2_East) & arrayfun(@isnumeric,xferTot_System2_West);
            if sum(fce1numIdx) > 0
                total_fce1_sys2(fce1numIdx) = max(xferTot_System2_East(fce1numIdx),2) + max(xferTot_System2_West(fce1numIdx),2);
            end

            fce2numIdx =  arrayfun(@isnumeric,xferTot_System2_East_2) & arrayfun(@isnumeric,xferTot_System2_West_2);
            if sum(fce2numIdx) > 0
                total_fce2_sys2(fce2numIdx)  = max(xferTot_System2_East_2(fce2numIdx),2) + max(xferTot_System2_West_2(fce2numIdx),2);
            end

            scfnumIdx = arrayfun(@isnumeric,xferTot_System2_East_3) & arrayfun(@isnumeric,xferTot_System2_West_3);
            if sum(scfnumIdx) > 0
                total_scf_sys2(scfnumIdx) = max(xferTot_System2_East_3(scfnumIdx),2) + max(xferTot_System2_West_3(scfnumIdx),2);
            end

            total_bonedry_sys2 = total_fce1_sys2 + total_fce2_sys2 + total_scf_sys2;

            % Calculate the ratio of the system ratio to the furnaces from bonedry

            fce1_lime = sys1_ratio .* (total_fce1_sys1 ./ total_bonedry_sys1) + sys2_ratio .* (total_fce1_sys2 ./ total_bonedry_sys2);
            fce2_lime = sys1_ratio .* (total_fce2_sys1 ./ total_bonedry_sys1) + sys2_ratio .* (total_fce2_sys2 ./ total_bonedry_sys2);


            allzerosIdx = total_bonedry_sys1 == 0 & total_bonedry_sys2 == 0;
            fce1_lime(allzerosIdx) = 0;
            fce2_lime(allzerosIdx) = 0;

            idx1 =  total_bonedry_sys1 == 0;
            fce1_lime(idx1) = sys2_ratio(idx1) .* (total_fce1_sys2(idx1) ./ total_bonedry_sys2(idx1));
            fce2_lime(idx1) = sys2_ratio(idx1) .* (total_fce2_sys2(idx1) ./ total_bonedry_sys2(idx1));

            idx2 = total_bonedry_sys2 == 0;
            fce1_lime(idx2) = sys1_ratio(idx2)  .* (total_fce1_sys1(idx2)  ./ total_bonedry_sys1(idx2) );
            fce2_lime(idx2) = sys1_ratio(idx2)  .* (total_fce2_sys1(idx2)  ./ total_bonedry_sys1(idx2) );


            % Calculate the total lime
            ACETag = struct;
            ACETag.Value = inputs.In_LimeFine_DM;
            ACETag.TimeStamp = inputs.In_LimeFine_DMTimestamps;
            total_limePIGet = CommonFunctions.GetACE2TotValue(ACETag, ExeTime, 86400, 0.5); %Summed from weigh bridge 6am to 6am.

            if isempty(total_limePIGet.Value)
                % If the recycle amount is 0, write out a 0 to the normal manual input write-out time = 06:00 at the end of the production day.
                % This allows an ACE re-Calculation to be triggered when a recycle value is entered later in the day

                total_lime = 0;

            else
                total_lime = total_limePIGet.Value ./ 1000;
            end


            nanIdx = isnan(total_lime);
            total_lime(nanIdx) = 0; % only use total from weigh bridge - bins weights are used to proportion


            fce1_lime = fce1_lime .* total_lime;
            fce2_lime = fce2_lime .* total_lime;
            scf_lime = fce2_lime .* total_lime;

            % Special cases
            % Transmit the lime values
            outputs.ACE_Tot_Lime  = fce1_lime;
            outputs.ACE_Tot_Lime_2  = fce2_lime;
            outputs.ACE_Tot_Lime_3  = scf_lime;

            zeroIdx = total_lime == 0;
            outputs.ACE_Tot_Lime(zeroIdx)  = 0;
            outputs.ACE_Tot_Lime_2(zeroIdx)  = 0;
            outputs.ACE_Tot_Lime_3(zeroIdx)  = 0;


        catch err
            logger.logError("#012DailyFeed  Lime error. Exec time: "  + string(ExeTime))

            msg = [err.stack(1).name, ' Line ',...
                num2str(err.stack(1).line), '. ', err.message];

            logger.logError(msg);

        end


        % Total New Concentrate Smelted

        try
            NewConc = Corrected_Total_feed - total_recycle - total_lime;

            outputs.ACE_NewConc_Tot  = NewConc;

        catch err
            logger.logError("#012DailyFeed  New Conc error. Exec time: "  + string(ExeTime))

            outputs.ACE_NewConc_Tot  =  nan; %("Bad Data");

            msg = [err.stack(1).name, ' Line ',...
                num2str(err.stack(1).line), '. ', err.message];

            logger.logError(msg);

        end

        % Slag Cleaning furnace belt scale and ratio calculations

        try

            % SCF Calculate feed totals using the belt scale totals and bin mass change over the day

            try % WACS total feed
                BinWACSDiff = BinDiff(inputs.bin2, first_date, second_date, logger) + ...
                    BinDiff(inputs.bin4, first_date, second_date, logger) + ...
                    BinDiff(inputs.bin5, first_date, second_date, logger) + ...
                    BinDiff(inputs.bin6, first_date, second_date, logger);

                ACETag = struct;
                ACETag.Value = inputs.T_BSWACS_2;
                ACETag.TimeStamp = inputs.T_BSWACS_2Timestamps;
                Tot_BSWACS = CommonFunctions.GetACE2TotValue(ACETag, ExeTime, 86400, 0.5).Value + BinWACSDiff;

                if isempty(Tot_BSWACS)
                    Tot_BSWACS = 0;
                end

                negIdx = Tot_BSWACS < 0;
                Tot_BSWACS(negIdx) = 0; % No negative values

                outputs.ACE_Tot_BSWACS  = Tot_BSWACS;

                TWACS = Tot_BSWACS;

            catch err
                logger.logError("#012DailyFeed  SCF WACS Feed error Exec time: "  + string(ExeTime))

                outputs.ACE_Tot_BSWACS  = nan; %("Bad Data");

                msg = [err.stack(1).name, ' Line ',...
                    num2str(err.stack(1).line), '. ', err.message];

                logger.logError(msg);

                try
                    idx = (inputs.Tot_WACSTimestamps >= starttime) & (inputs.Tot_WACSTimestamps <= endtime);
                    TWACS = max(inputs.Tot_WACS(idx),2); % WACS from feeders

                    if isempty(TWACS)
                        TWACS = 0;
                    end
                catch err
                    TWACS = 0;

                    msg = [err.stack(1).name, ' Line ',...
                        num2str(err.stack(1).line), '. ', err.message];

                    logger.logError(msg);
                end

            end

            try % Coke and Silica total feed - ratio and WACs ratios
                BinMixDiff = BinDiff(inputs.bin3, first_date, second_date, logger);
                ACETag = struct;
                ACETag.Value = inputs.T_BSCoke;
                ACETag.TimeStamp = inputs.T_BSCokeTimestamps;
                BS_Coke = CommonFunctions.GetACE2TotValue(ACETag, ExeTime, 86400, 0.5).Value;

                if isempty(BS_Coke)
                    BS_Coke = 0;
                end

                ACETag = struct;
                ACETag.Value = inputs.T_BSSilica;
                ACETag.TimeStamp = inputs.T_BSSilicaTimestamps;
                BS_Silica = CommonFunctions.GetACE2TotValue(ACETag, ExeTime, 86400, 0.5).Value;

                if isempty(BS_Silica)
                    BS_Silica = 0;
                end

                negIdx =  BS_Coke < 0 | isnan(BS_Coke);
                BS_Coke(negIdx) = 0;

                negIdx =  BS_Silica < 0 | isnan(BS_Silica);
                BS_Silica(negIdx) = 0;

                if isempty(BS_Coke)
                    BS_Coke = 0;
                end
                if isempty(BS_Silica)
                    BS_Silica = 0;
                end

                % If the belt scale did not run get the last Coke on WACS and Coke % - then use this
                if BS_Coke(end) == 0 && BS_Silica(end) == 0
                    % Gets last good total value - if recalculating the last good value could be for the current period (value at start of period)

                    ACETag = struct;
                    ACETag.Value = inputs.C_on_CandSi;
                    ACETag.TimeStamp = inputs.C_on_CandSiTimestamps;
                    ConWACS_C = CommonFunctions.GetACE2TotValue(ACETag, ExeTime, 86400, 0.5).Value;
                else
                    ConWACS_C = BS_Coke ./ (BS_Coke + BS_Silica) .* 100;
                end

                Tot_BSCoke = BS_Coke + BinMixDiff .* ConWACS_C ./ 100;
                Tot_BSSilica = BS_Silica + BinMixDiff .* (1 - ConWACS_C ./ 100);

                negIdx = Tot_BSCoke < 0;
                Tot_BSCoke(negIdx) = 0; % No negative values

                negIdx =  Tot_BSSilica < 0 | isempty(Tot_BSSilica);
                Tot_BSSilica(negIdx) = 0; % No negative values

                emptyIdx = isempty(ConWACS_C);
                ConWACS_C(emptyIdx) = 0;

                outputs.ACE_Tot_BSSilica  = Tot_BSSilica;
                outputs.ACE_Tot_BSCoke  = Tot_BSCoke;
                outputs.ACE_C_on_CandSi  = round(ConWACS_C, 3);

                try % ratios with WACS
                    try
                        outputs.ACE_Si_on_WACS  = round(Tot_BSSilica/ TWACS* 100, 3);
                    catch err
                        outputs.ACE_Si_on_WACS = nan;

                        msg = [err.stack(1).name, ' Line ',...
                            num2str(err.stack(1).line), '. ', err.message];

                        logger.logError(msg);
                    end

                    try
                        outputs.ACE_C_on_WACS  = round(Tot_BSCoke/ TWACS* 100, 3);
                    catch err
                        outputs.ACE_C_on_WACS = nan;

                        msg = [err.stack(1).name, ' Line ',...
                            num2str(err.stack(1).line), '. ', err.message];

                        logger.logError(msg);
                    end

                    lessThanOneIdx = TWACS < 1;

                    outputs.ACE_Si_on_WACS(lessThanOneIdx)  = nan; % "No Feed";
                    outputs.ACE_C_on_WACS(lessThanOneIdx)  = nan; %"Calc Failed";

                catch err
                    logger.logError("#012DailyFeed  SCF ratios error. Exec time: "  + string(ExeTime))

                    outputs.ACE_Si_on_WACS  = nan; %("Bad Data");
                    outputs.ACE_C_on_WACS  = nan; %("Bad Data");

                    msg = [err.stack(1).name, ' Line ',...
                        num2str(err.stack(1).line), '. ', err.message];

                    logger.logError(msg);



                end
            catch err
                logger.logError("#012DailyFeed  SCF Wacs ratio outer err. Exec time: "  + string(ExeTime))

                outputs.ACE_Tot_BSSilica  = nan; %("Bad Data");
                outputs.ACE_Tot_BSCoke  = nan; %("Bad Data");
                outputs.ACE_C_on_CandSi  = nan; %("Bad Data");

                msg = [err.stack(1).name, ' Line ',...
                    num2str(err.stack(1).line), '. ', err.message];

                logger.logError(msg);


            end


            try % Bone dry ratio
                ACETag = struct;
                ACETag.Value = inputs.DB_LossInWeight;
                ACETag.TimeStamp = inputs.DB_LossInWeightTimestamps;
                TBD = CommonFunctions.GetACE2TotValue(ACETag, ExeTime, 86400, 0.1).Value; % changed 31 March 2016 = SCF1_xfer

                if isempty(TBD)
                    TBD = 0;
                end

                try
                    outputs.ACE_BD_on_DBandWACS  = round(TBD(end) ./ (TWACS(end) + TBD(end)) .* 100, 3);
                catch err
                    outputs.ACE_BD_on_DBandWACS = nan;

                    msg = [err.stack(1).name, ' Line ',...
                        num2str(err.stack(1).line), '. ', err.message];

                    logger.logError(msg);
                end
                % idx = TBD + TWACS < 1; % isempty(TBD) || isempty(TWACS)  % (
                % outputs.ACE_BD_on_DBandWACS(idx)  = nan; %("No Feed");

            catch err
                logger.logError("#012DailyFeed  SCF BD ratio err. Exec time: "  + string(ExeTime))

                outputs.ACE_BD_on_DBandWACS(1)  = nan; %("Bad Data");
                outputs.ACE_BD_on_DBandWACS(2)  = nan; %("Bad Data");

                msg = [err.stack(1).name, ' Line ',...
                    num2str(err.stack(1).line), '. ', err.message];

                logger.logError(msg);

            end


        catch err
            logger.logError("#012DailyFeed  SCF outer err. Exec time: "  + string(ExeTime))

            outputs.ACE_Tot_BSWACS = []; %"Calc Failed";
            outputs.ACE_Tot_BSSilica = []; %"Calc Failed";
            outputs.ACE_Tot_BSCoke = []; %"Calc Failed";
            outputs.ACE_C_on_CandSi = []; %"Calc Failed";
            outputs.ACE_Si_on_WACS = []; %"Calc Failed";
            outputs.ACE_C_on_WACS = []; %"Calc Failed";
            outputs.ACE_BD_on_DBandWACS = []; %"Calc Failed";

            msg = [err.stack(1).name, ' Line ',...
                num2str(err.stack(1).line), '. ', err.message];

            logger.logError(msg);


        end
        outTime = ExeTime;
        outTime.Hour = 5;
        outTime.Minute = 0;
        outTime.Second = 0;

        outputs.Timestamp = outTime;

        outputNames = string(fieldnames(outputs));

        for nOut = 1:length(outputNames)
            curOut = outputs.(outputNames(nOut));

            if isempty(curOut)
                outputs.(outputNames(nOut)) = nan; % Set to nan if output empty
            end

            if any(isinf(curOut))
                outputs.(outputNames(nOut)) = nan; % Set to nan if output empty
            end
        end

    catch err
        msg = [err.stack(1).name, ' Line ',...
            num2str(err.stack(1).line), '. ', err.message];

        logger.logError(msg);
        errorCode = cce.CalculationErrorState.CalcFailed;

        outputs.Timestamp = [];
        outputs.ACE_xfer_Tot = []; %"Calc Failed";
        outputs.DailyPlantRecycle =[]; % "Calc Failed";
        outputs.ACE_Tot_Recycle =[]; % "Calc Failed";
        outputs.ACE_Tot_Recycle_2 =[]; % "Calc Failed";
        outputs.ACE_Tot_Recycle_3 =[]; % "Calc Failed";
        outputs.ACE_SEC_xfer_NewConc =[]; % "Calc Failed";
        outputs.ACE_SEC_xfer_NewConc_2 =[]; % "Calc Failed";
        outputs.ACE_Tot_Lime =[]; % "Calc Failed";
        outputs.ACE_Tot_Lime_2 =[]; % "Calc Failed";
        outputs.ACE_Tot_Lime_3 =[]; % "Calc Failed";
        outputs.ACE_NewConc_Tot =[]; % "Calc Failed";
        outputs.ACE_Tot_BSWACS = []; %"Calc Failed";
        outputs.ACE_Tot_BSSilica = []; %"Calc Failed";
        outputs.ACE_Tot_BSCoke = []; %"Calc Failed";
        outputs.ACE_C_on_CandSi = []; %"Calc Failed";
        outputs.ACE_Si_on_WACS = []; %"Calc Failed";
        outputs.ACE_C_on_WACS = []; %"Calc Failed";
        outputs.ACE_BD_on_DBandWACS = []; %"Calc Failed";

    end
end
% Sub-routines
function Diff = BinDiff(Tag,StartDate, EndDate,logger)

    try
        BinS = CommonFunctions.IterpolatedVal(Tag, string(StartDate));
        BinE = CommonFunctions.IterpolatedVal(Tag, string(EndDate));

        if isempty(BinS) || isempty(BinE)
            Diff = zeros(numel(Tag),1);
        else
            Diff = BinS.Value - BinE.Value;
        end

    catch err
        Diff =  zeros(numel(Tag),1);

        msg = [err.stack(1).name, ' Line ',...
            num2str(err.stack(1).line), '. ', err.message];

        logger.logError(msg);
        %logger.logWarning("#012DailyFeed  Bin diff err. Exec time: " + string(Tag))
    end

end