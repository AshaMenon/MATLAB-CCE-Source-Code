function [outputs,errorCode] = cceACEEventDetection(parameters,inputs)


    logger = Logger(parameters.LogName, parameters.CalculationID, ...
        parameters.CalculationName, parameters.LogLevel);

    newOutTime = strrep(parameters.OutputTime, "T", " ");
    newOutTime = extractBefore(newOutTime, ".");

    ExeTime = datetime(newOutTime);

    errorCode = cce.CalculationErrorState.Good;

    logger.logTrace("Current execution time being used: " + datestr(ExeTime))
    try
        % Pull calculation parameter data
        paramFile = fullfile(parameters.OPMParameterPath,"\",parameters.OPMAnalysisName+".csv");
        opts = detectImportOptions(paramFile,"ReadRowNames",true,"FileType","delimitedtext",...
            "ConsecutiveDelimitersRule","join",'ReadVariableNames', false);
        opts.Delimiter = [",",";"];
        opts.DataLines = [1,inf];
        paramData = readtable(paramFile,opts);
        paramData = rows2vars(paramData);
        paramData.OriginalVariableNames = [];
        paramVars = string(paramData.Properties.VariableNames(1:end));

        % Quick data cleaning
        % Remove the "[" and "]" on some data entries
        CalcParam = struct;
        for varName = paramVars
            CalcParam.(varName) = rmmissing(paramData{:, varName});

            try
                CalcParam.(varName) = erase(CalcParam.(varName),["[","]"]);
            catch
                % logger.logInfo("Parameter data doesn't contain any leading or trailing '[]'.   NowTime" + string(datetime('now')))
            end
        end

        %% Variable initialisation

        % For testing from file
        RunTestFromFile = 0;
        RunTestDataRows = "";
        RunTestDataRowColumns ="";
        %     runTestData = OPMMonitoring.runTestData;
        RunTestLineResults = "";

        IterateTest = 0; % iterate through steps from a start time
        IterateTestForceEvents = 0; % iterate through steps from a start time
        IterateTestTagHiHiStart= datetime("2022-02-20 20:10:10");
        IterateTestTagHiHiEnd  = datetime("2022-01-17 15:12:30");
        IterateTestModleHiHiStart = IterateTestTagHiHiStart;
        IterateTestModleHiHiEnd = datetime("2022-01-17 15:12:00");

        % Event Active state
        outEvent_RunState = string(OPMEnums.State.CalcError);
        EventActivestr = "";
        TagsOutofSigmaString = "";
        TagsOutofSigmaCount  = 0;


        % Last values to check against
        pi_eventstr = "";
        pi_TagsOutofSigmaString = "";
        pi_TagsOutofSigmaCount = "0";
        ModleEventActiveChange = 0;


        ParameterFileLife = 172800; % 1 day and 1 hr
        ConfigOnNormalReloadInterval = 3600; % on error try reload every hour
        ConfigOnErrorReloadInterval = 600; % on error try reload every 5 min
        ConfigReloadTime = 3600; % reload every hour


        % Generate random number for configuration reload offset
        ReloadOffset = randi([0 floor(3600-0+1)]);

        % Heartbeat output every x seconds
        HeartBeatUpdateTime = 60;
        FirstStart = 0;
        ConfigLoadCounter = 0;
        HeartBeatConter = 0;
        outHeartBeat = 0;
        lastRunTime = 0;
        ConfigurationGood = 0;



        %% Check configuration
        try
            il_CheckLimits  = parameters.CheckLimits;
            il_ParameterFileLife = parameters.ParameterFileLife;
            il_ConfigReloadTime = parameters.ConfigReloadTime;
            il_TimeLag = 0;

            if ~isnumeric(il_ParameterFileLife)
                il_ParameterFileLife = 90000;
                logger.logError("OPM Event Detection parse ParameterFileLife error. Using default: " + string(il_ParameterFileLife))
            end

            if ~isnumeric(il_ConfigReloadTime)
                il_ConfigReloadTime = 3600;
                logger.logError("OPM Event Detection parse ConfigReloadTime error. Using default: " + string(il_ConfigReloadTime))
            end

            if il_ConfigReloadTime < 1800
                il_ConfigReloadTime = 3600;
                logger.logError("OPM Event Detection ConfigReloadTime time to short error. Using default of 3600s")
            end

            if (il_CheckLimits) ~= 0 || (il_CheckLimits) ~= 1
                il_CheckLimits = 0;
            end

            ParamFileName = parameters.OPMAnalysisName;
            mdb_outPath = parameters.OPMParameterPath;
            ParamFilePath = fullfile(mdb_outPath,ParamFileName,".csv");
            TagEventHistoryFilePath = fullfile(mdb_outPath,"TagEventHistory\",ParamFileName,".csv");

            %          if RunTestFromFile
            %                 ParamFilePath = OPMMonitoring.runTestData.TestConfigFilePath;
            %                 TagEventHistoryFilePath = OPMMonitoring.runTestData.TestDataEventHistoryPath
            %          end

            % Get last character of file name to determine Model type _L, _S; needed for correct parameter selection
            splitStr = strsplit(ParamFileName,"_");
            ModleType = "_"+splitStr(end);


            % Must have a value, but default to zero
            if isnan(str2double([CalcParam.timeLag{:}]))
                il_TimeLag = 0;
            else
                il_TimeLag = str2double([CalcParam.timeLag{:}]);
            end

            il_Direction = CalcParam.eventDirection;

            tagNo = numel(CalcParam.pcaRefMean);
            %CalcParam.pcaRefEigenvectors = reshape(CalcParam.pcaRefEigenvectors, [tagNo tagNo]);

            il_CalcParam = CalcParam;

            % Check file parameter row and column counts
            TestParameterSize(il_CalcParam.tsquareCL_S, 2, 1, "T²")
            TestParameterSize(il_CalcParam.ssresidualslim_S, 2, 1, "SPE limits")
            TestParameterSize(il_CalcParam.pcaRefMean, tagNo,1, "pcaRefMean")
            TestParameterSize(il_CalcParam.pcaRefStd, tagNo,1, "pcaRefStd")
            TestParameterSize(il_CalcParam.nSigma_S, tagNo, 1,"nSigma")
            TestParameterSize(il_CalcParam.nRawSigma_S, tagNo,1, "nRawSigma")
            TestParameterSize(il_CalcParam.pcaRefEigenvalues, tagNo, 1, "pcaRefEigenvalues")
            TestParameterSize(il_CalcParam.pcaRefEigenvectors, tagNo,tagNo, "pcaRefEigenvectors")
            TestParameterSize(il_CalcParam.rawDataRefMean, tagNo,1 ,"pcaRawDataRefMean")

            il_AFrawTags = string(il_CalcParam.rawTagNames);
            if tagNo ~= numel(~ismissing(il_AFrawTags))
                Me = MException("DT tag number and raw tag number do not match. expecting " + tagNo + " raw tags");
                throw(Me)
            end

            if RunTestFromFile


            else
                % Isolate data specific to Exetime
                datesIdx = abs(seconds(inputs.Event_1Timestamps - ExeTime)) < 1;
                % Add Input tags to attribute list
                % Tags in list
                %%TagList = unique(inputs.TagName_1(datesIdx));

                % Select only raw tags that are not already in tag list - in some cases tags and raw tags are equal, calc expression dt and hearth
                %idxTagsNotInc =  ~ismember(TagList,CalcParam.tagNames);
                %il_AFrawTags = [TagList; TagList(idxTagsNotInc)];

                % Select unique water tags, group by tag name then take first and add af attribute
                il_TagWaterList = inputs.WaterTag_1(abs(seconds(inputs.WaterTag_1Timestamps - ExeTime)) < 1);

                % Add Mean and Event tags to attribute list
                %il_TagRawMeanOut = inputs.OPMEvent_RawMean(datesIdx);
                il_TagRawMean_3SigmaOut = inputs.Sigma_1(abs(seconds(inputs.Sigma_1Timestamps - ExeTime)) < 1);
                il_TagEventOut = inputs.Event_1(datesIdx);

            end

            %TagAttList = il_AFrawTags;
            TagWaterList = il_TagWaterList;
            %TagEventOut = il_TagEventOut;
            rawMean_3Sigma= il_TagRawMean_3SigmaOut;

            %il_TagRawMeanOut - only used at configuration load to save file parameters
            %CheckLimits = il_CheckLimits;
            ParameterFileLife = il_ParameterFileLife;
            ConfigReloadTime = il_ConfigReloadTime;

            %TimeLag = il_TimeLag;
            %Direction = il_Direction;

            % set calc check time
            exactFieldname = "eventWindow"+ModleType;
            eventWindow = CalcParam.(exactFieldname);
            exactFieldname = "eventThreshold"+ModleType;
            eventThreshold = CalcParam.(exactFieldname);
            %checkTimeTimeTrue = str2double(cell2mat(eventWindow)) * str2double(cell2mat(eventThreshold));
            % Reset event string to force an update


            %WriteTime = datetime("now");

            if ~RunTestFromFile && ~IterateTest
                try
                    if ConfigurationGood  % modle does not run with bad configuration
                        % Write out individual tags mean from file, need to write per attribute
                        WriteRes = 0;

                        % Write out data quality from file
                        %                         MDB_Alias.Add(AFGetConfig.mdp_tagDataQuality, CurModule.PIAliases(AFGetConfig.mdp_tagDataQuality))
                        %                         AFWrite.CreatAFAttributeAndWriteItem(MDB_Alias(AFGetConfig.mdp_tagDataQuality).DataSource.PathName, CalcParam.DataQuality.Column(0)(0).ToString(), WriteTime, WriteRes)

                        try
                            % Use current time and not modle time
                            for imeanAtt = 1:numel(il_TagRawMeanOut)
                                meanAtt = il_TagRawMeanOut(imeanAtt)

                                % il_TagRawMeanOut
                                meanAtt(imeanAtt) = CalcParam.pcaRawDataRefMean(imeanSSATT);
                                %                             outputs.meanAtt = meanAtt;

                            end

                            % Create  list of attributes write out all
                            for imeanSSATT = 1:numel(il_TagRawMean_3SigmaOut)
                                meanSSAtt = il_TagRawMean_3SigmaOut(imeanSSAtt)

                                % il_TagRawMeanOut
                                exactFieldname = "nRawSigma"+ModleType;
                                nRawSigma = CalcParam.(exactFieldname);
                                Value = str2double(cell2mat(nRawSigma(imeanSSATT)));
                                meanSSAtt(imeanSSATT) = Value;
                            end

                        catch
                            logger.logError("OPM Event Detection config load write.   NowTime" + string(datetime('now')))

                        end

                    end

                catch
                    logger.logError("OPM Event Detection Configuration file parameter write out error.   NowTime " + string(datetime('now')))
                end

            end

            ConfigurationGood = 1;
            logger.logInfo("OPM Event Detection Configuration loaded.   NowTime "  +string(datetime('now')) +...
                "Configuration = ConfigurationGood")

            % Proceed on to calculation
        catch exeption
            logger.logError("OPM Event Detection Load Configuration Error.   NowTime" + string(datetime('now')))
            logger.logError(exeption.message)
            logger.logError(exeption.stack.line)

            throw(exeption)
            %         throw(MException("OPM Event Detection Load Configuration Error"))
            % Do not proceed to calculation

        end

        %% Start Calculation

        CalcRuns = 0;  % Initial value = 0, otherwise calculation iterates twice

        if IterateTest == 1
            CalcRuns = 4000;
        end

        lexeTime = ExeTime;

        calcRunTime = lexeTime;

        if IterateTest == 1
            lexeTime = datetime("2022-03-30 12:37:00");  % For testing
        end

        for Eachcalc = 1:CalcRuns
            % Iteration test
            if IterateTest == 1
                calcRunTime = lexeTime;
            end
        end

        %      if RunTestFromFile
        %                 %For each loop get new test time and test data for time
        %                 doRestart = 1;
        %
        %                 % Add time step for current run time
        %                 if lastRunTime ~= 0
        %                     lexeTime = lastRunTime + OPMMonitoring.runTestData.timestepSeconds;
        %                 end
        %
        %
        %                 if doRestart && Eachcalc == 17639
        %                     TestingRestart = 1;
        %                     TestingRestart = 0;
        %                 else
        %                     TestingRestart = 0;
        %                 end
        %      end

        TimeSinceLastRun = 0;

        if lastRunTime == 0
            lastRunTime = lexeTime;
        else
            TimeSinceLastRun = hours(lexeTime - lastRunTime);
        end

        %     if RunTestFromFile == 1
        %
        %         % Do not write out data
        %         SendDataToPI = 1;
        %
        %         % Load test file for data and set run count
        %         RunTestDataRows = runTestData.testFileLines(RunTestDataRowColumns);
        %         % Get row count to loop through
        %         CalcRuns = numel(RunTestDataRows) - 1; % Set to total row count
        %
        %         % Get start time from config
        %         lexeTime = OPMMonitoring.runTestData.TestStartFromDate;
        %
        %         % Make first row of output file
        %         RunTestLineResults = RunTestDataRowColumns;
        %     end

        CalcTime = lexeTime;
        outputs = struct;

        % Update counters and times
        ConfigLoadCounter = ConfigLoadCounter + TimeSinceLastRun;
        HeartBeatConter = HeartBeatConter + TimeSinceLastRun;

        exactFieldname = "eventWindow"+ModleType;
        eventWindow = CalcParam.(exactFieldname);
        eventWindow = str2double(eventWindow{1});
        EventwindowStartTime = CalcTime + seconds(-1 * eventWindow); % shift one period forward and test

        % Loop through for each calcDate
        uniqueDates = unique(inputs.RawMean_1Timestamps);
        for iCalc = 1:numel(uniqueDates)
            lexeTime = uniqueDates(iCalc);

            try
                try
                    if FirstStart == 0

                        if ConfigLoadCounter >= ConfigReloadTime
                            % Re-load time is reached

                            % Test load failed reading file - continuing
                            logger.logError("OPM Event Detection reloading configuration start.   NowTime " + string(datetime('now')))

                            outHeartBeat = 0; % Reset heartbeat on successful configuration file load
                        end
                    else
                        % Set a random offset on the configuration counter reload
                        ConfigLoadCounter = ConfigLoadCounter + ReloadOffset;
                        logger.logError("OPM Event Detection first start configuration offset = " + string(ReloadOffset)+ "NowTime" + string(datetime('now')))
                    end
                catch
                    logger.logError("OPM Event Detection re-loading configuration error. Continuing without stopping  NowTime " + string(datetime('now')))
                    ConfigurationGood = 1;
                end

                if ConfigurationGood == 1
                    ConfigReloadTime = ConfigOnNormalReloadInterval;
                else
                    % On configuration load error, try reload every 10min
                    ConfigReloadTime = ConfigOnErrorReloadInterval;
                end


                % Write out HeartBeat
                if HeartBeatConter >= HeartBeatUpdateTime
                    % Increment heartbeat and reset counter
                    outHeartBeat = outHeartBeat + 1;
                    HeartBeatConter = 0;
                end

                HeartBeat = struct;
                HeartBeat.Value = outHeartBeat;
                HeartBeat.TimeStamp = lexeTime;


                if RunTestFromFile == 0 &&  IterateTest == 0
                    try
                        timeDiff = (seconds(lexeTime - datetime((CalcParam.modelTimeStamp),"InputFormat","yyyy/MM/dd HH:mm:ss")));
                    catch
                        timeDiff = 0;
                    end
                    if ParameterFileLife ~= 0  && timeDiff > ParameterFileLife
                        % Parameter file is too old to use
                        ConfigurationGood = 0;
                        logger.logError("OPM Event Detection Parameter file is stale. Age is over  " + string(ParameterFileLife)+  "s. Retrying in "+...
                            num2str((ConfigReloadTime(end) - ConfigLoadCounter(end))) + "s")
                    end
                end

                try
                    if ConfigurationGood == 1
                        % Set default of no alarm
                        Event_RunState = OPMEnums.State.NoAlarm;
                        %
                        %                     if RunTestFromFile == 1
                        %                         runTestData.ConvertRowtoAndUpdateAFAttributes(CalcTime, TagAttList, RunTestDataRows(Eachcalc))
                        %                     end

                        afDTVal = inputs.RawMean_1(inputs.RawMean_1Timestamps == uniqueDates(iCalc));  % mean values
                        afWaterVal = TagWaterList;
                        afrawVal = rawMean_3Sigma;
                        badValsCount = 0;

                        if CalcParam.calcExpression == OPMEnums.CalcExpression.dt
                            % Calc DT ad af attribute
                            CalcDT = struct;

                            for iafrv = 1:numel(afrawVal)
                                afrv = afrawVal(iafrv);
                                CalcDT.Timestamp = calcRunTime;
                                CalcDT.Attribute = afrv;  % Set attribute to get index name

                                %Get water tag name from raw tag index, the index for the water tag names match
                                wName = CalcParam.tagNames(iafrv);

                                % Get water tag value from the tag name
                                afW  = afWaterVal(wName == TagList);

                                if ~isnan(afW) && ~isempty(afrv)
                                    CalcDT.Value = af-afW;
                                    CalcDT.IsGood = 1;

                                else
                                    CalcDT.Value = "Not Data";
                                    CalcDT.IsGood = 0;
                                    badValsCount = badValsCount+1;
                                end

                                afDTVal(iafrv) = CalcDT.Value;
                            end
                        else
                            %afdTVal remains unchanged
                        end

                        badAfDT = badValsCount;

                        if badAfDT > 0

                            % Bad values present
                            % Write out bad values
                            logger.logError("OPM Event Detection bad value was found in input tags. NowTime"  + datestr(calcRunTime))

                            %default state changes to bad tag
                            Event_RunState = State.BadTag;
                        end


                        % Get raw values into matrix
                        convertedpcaRefMean = cellfun(@str2double, CalcParam.pcaRefMean, 'UniformOutput', false);
                        convertedpcaRefMean = cat(1,convertedpcaRefMean{:});
                        rawDTVals = BuildRowMatrixFromList(ConvertAllVal(afDTVal,convertedpcaRefMean).Value);  %For all non empty tags
                        convertedrawDataRefMean = cellfun(@str2double, CalcParam.rawDataRefMean, 'UniformOutput', false);
                        convertedrawDataRefMean =  cat(1,convertedrawDataRefMean{:});
                        rawRawVals = BuildRowMatrixFromList(ConvertAllVal(afrawVal,convertedrawDataRefMean).Value);

                        % Normalize data = value - mean/std
                        convertedRefStd =  cellfun(@str2double, CalcParam.pcaRefStd, 'UniformOutput', false);
                        convertedRefStd = cat(1,convertedRefStd{:});
                        NormalVals = ((rawDTVals) -(convertedpcaRefMean))./(convertedRefStd);

                        % Reduce EigenVectores with the principle components. number Columns = number_PC
                        convertedEigVecs = cellfun(@str2double, (CalcParam.pcaRefEigenvectors), 'UniformOutput', false);
                        reducedToIdx = 1:str2double(CalcParam.num_pcs{1});
                        PCscore_EigenVector = convertedEigVecs(1:end);
                        PCscore_EigenVector = cell2mat(PCscore_EigenVector);

                        % Calculate Scores, reduce columns of eigenvectors to = number of principle components no_PC
                        ScoreVales = NormalVals'*PCscore_EigenVector;

                        % Reconstruct data
                        reconstrucVales = ScoreVales*(PCscore_EigenVector)';

                        % Calculate residuals
                        residualVals = NormalVals-reconstrucVales';

                        % Calc SPE result should have 1 row
                        SPE = sum((residualVals).^2,2);

                        % Calc T² - Hotellings T^2 statistic for each observation
                        % Reduce Eigen values to principle components
                        convertedRefEigVals = cellfun(@str2double, (CalcParam.pcaRefEigenvalues), 'UniformOutput', false);
                        convertedRefEigVals = cat(1,convertedRefEigVals{:});
                        pcaEigVals = convertedRefEigVals;
                        PC_pcaRefEigenvalues = transpose(pcaEigVals(reducedToIdx));
                        try
                            T = ScoreVales(reducedToIdx)*diag(1./sqrt(PC_pcaRefEigenvalues))*PCscore_EigenVector';
                        catch
                            T = 0;
                        end
                        T2 = sum(T.^2);

                        % These must be hi min for an individual hi
                        exactFieldname = "ssresidualslim"+ModleType;
                        ssresidualslim = CalcParam.(exactFieldname);
                        SPEtolimits  = CheckHi(SPE, str2double(ssresidualslim{1}), ...
                            str2double(ssresidualslim{2}));

                        exactFieldname = "tsquareCL"+ModleType;
                        tsquareCL = CalcParam.(exactFieldname);
                        T2tolimits  = CheckHi(T2, str2double(tsquareCL{1}), ...
                            str2double(tsquareCL{2}));

                        if IterateTest == 1 && IterateTestForceEvents == 1
                            if calcRunTime >= IterateTestTagHiHiStart && calcRunTime < IterateTestTagHiHiEnd
                                SPEtolimits = OPMEnums.State.HiHi;

                            else
                                SPEtolimits = OPMEnums.State.NoAlarm;
                            end

                            if calcRunTime >= IterateTestModleHiHiStart && calcRunTime < IterateTestModleHiHiEnd
                                % Update raw sigma for tag to force to trigger, tag index 4
                                CalcParam.nRawSigma_S{4} = 0;
                            end

                        end


                        % Combine states
                        Event_RunState = CombineStatesHighestWins([SPEtolimits, T2tolimits]);


                        % Check each raw tag against raw > (Nsigma)  (Nsigma = mean + 3sigma)
                        SigmaExceded = [];
                        for nn = 1: numel(rawRawVals)

                            if ismember(string(CalcParam.eventDirection{1}), "positive")
                                Direction = 1;
                            else
                                Direction = 0;
                            end

                            if ChecktoCalcDirection(rawRawVals(nn), str2double(CalcParam.nRawSigma_S{nn}), Direction) && ...
                                    Event_RunState == OPMEnums.State.HiHi
                                SigmaExceded = [SigmaExceded; 1];
                            else
                                SigmaExceded = [SigmaExceded; 0];
                            end
                        end

                        % Run through current calculation states and update the tagStates, turn off if the module drops to no alarm
                        LastCalcRunDate = lastRunTime;


                        % Get list of tags that are causing the event
                        isolateDate = uniqueDates(iCalc);
                        try
                        datesIdx = (inputs.RawMean_1Timestamps == isolateDate) & (inputs.Event_1 == 1);
                        catch
                            datesIdx = [];
                        end
                        isolateTagnames = inputs.TagName_1(datesIdx);
                        EventTagList = string(unique((isolateTagnames)));  % Isolate only active event states

                        % Get tag list and do calculation and tag in event string as the number of tags can change
                        TagsOutofSigmaCount = numel(EventTagList);

                        if TagsOutofSigmaCount > 0

                            TagsOutofSigmaString = string(EventTagList);

                            TagsOutofSigmaList = EventTagList;

                            if ~ismember(EventActivestr,"On")
                                EventActivestr = "On";
                                % Get state that hits window
                                % Need to use earliest start of events in HIHI
                                % Get all active eventperiods into one list
                                % Get all HiHi from that List
                                % Get min event star period
                                ModleEventActiveChange = 1;
                            else
                                ModleEventActiveChange = 0;
                            end
                        else
                            % Reset if none out
                            TagsOutofSigmaString = "";
                            TagsOutofSigmaCount = 0;
                            TagsOutofSigmaList = [];
                            ModleEventActiveChange = 0;

                            % If there aren't any active sensors, the event state has to be
                            % no-alarm
                            Event_RunState =  OPMEnums.State.NoAlarm;
                        end


                        if Event_RunState == OPMEnums.State.NoAlarm

                            if ~ismember(EventActivestr,"Off")
                                EventActivestr = "Off";
                                EventStart = LastCalcRunDate;
                                ModleEventActiveChange = 1;

                            else
                                ModleEventActiveChange = 0;
                            end

                        end

                        % Event tag state must come from the modle if Hi or HiHi, if modle is no alarm then check for bad tags or bad config
                        outEvent_RunState = Event_RunState;

                        if Event_RunState ~= OPMEnums.State.Hi || Event_RunState ~= OPMEnums.State.HiHi
                            if Event_RunState == OPMEnums.State.ConfigError
                                outEvent_RunState = OPMEnums.State.ConfigError;
                            elseif Event_RunState == OPMEnums.State.CalcError
                                outEvent_RunState = OPMEnums.State.CalcError;
                            elseif Event_RunState == OPMEnums.State.BadTag
                                outEvent_RunState = OPMEnums.State.BadTag;
                            else

                            end
                        end

                        if IterateTest && (outEvent_RunState == State.NoAlarm) || CalcRuns == 9999
                            PauseRun = 1;
                        end

                    else

                        %logger.logError("OPM Event Detection Calculation configuration was bad. NowTime"  + datestr(calcRunTime))
                        msg = [err.stack(1).name, ' Line ',...
                            num2str(err.stack(1).line), '. ', err.message];

                        logger.logError(msg);
                        % Configuration load failed
                        outEvent_RunState = OPMEnums.State.ConfigError;
                    end
                catch err
                    %logger.logError("OPM Event Detection run error.   NowTime"  + datestr(calcRunTime))
                    msg = [err.stack(1).name, ' Line ',...
                        num2str(err.stack(1).line), '. ', err.message];

                    logger.logError(msg);
                    % Configuration load failed
                    outEvent_RunState = OPMEnums.State.CalcError;
                end

                if IterateTest == 1 % for testing stop debug when tag out of sigma list changes
                    if IterateTestTagsOutofSigmaString ~= TagsOutofSigmaString
                        IterateTestTagsOutofSigmaString = TagsOutofSigmaString;
                        if ModleEventActiveChange
                            iterationTestWriteOutDate = EventStart;
                        end
                        Pause = 1;
                    end
                end

                % Write out individual tags mean from file, need to write per attribute
                if CheckForChaneg(pi_eventstr, EventActivestr, 1) == 1
                    if ismember(EventActivestr,'Off')
                        val = 0;
                    else
                        val = 1;
                    end
                    outputs.EventActiveInt(iCalc) = val;
                end


                outputs.ActiveTags(iCalc)  = {TagsOutofSigmaString};
                outputs.ActiveTagsCount(iCalc) = TagsOutofSigmaCount;
                outputs.Timestamp(iCalc) = uniqueDates(iCalc);

                % Only write out if event state changes, compare to current PI value
                if RunTestFromFile == 0 && IterateTest == 0

                    % Write out tags out of sigma count
                    if CheckForChaneg(pi_TagsOutofSigmaCount, string(TagsOutofSigmaCount),[]) == 1
                        outputs.ActiveTagsCount(iCalc) = TagsOutofSigmaCount;
                    end

                    if CheckForChaneg(pi_TagsOutofSigmaString, TagsOutofSigmaString,[]) == 1

                        attTagsEventing = TagsOutofSigmaString;

                        % Write out here as tags could change but event count not
                        allEventAtt = attTagsEventing;
                        if ~isempty(allEventAtt)
                            % Write out event state to all individual tags those in HiHi and those not (must turn off tags the are no longer eventing), check if each has changed
                            for iEventAtt = 1:numel(allEventAtt)
                                EventAtt = allEventAtt(iEventAtt);
                                pi_aftagEventVal = string(CalcParam.tagNames);
                                if ismember(EventAtt,pi_aftagEventVal)
                                    % Check for change
                                    if ismember(EventAtt,TagsOutofSigmaList)
                                        % idxMatchingTags = (EventAtt == inputs.RawTagName) & (inputs.EventTimestamps == ExeTime);
                                        logger.logTrace(class(EventAtt))
                                        idxMatchingTags = (EventAtt == inputs.TagName_1);
                                        eventAtTag = inputs.Event_1(idxMatchingTags);
                                        if eventAtTag == 1
                                            eventAtMatchingTags = "On";
                                        else
                                            eventAtMatchingTags = "Off";
                                        end
                                        if CheckForChaneg(eventAtMatchingTags, "On",[]) == 1
                                            EventActive = "On";
                                            EventActiveInt = 1;
                                        else
                                            EventActive = eventAtMatchingTags;
                                            EventActiveInt = eventAtTag;
                                        end

                                    else
                                        idxMatchingTags = (EventAtt == inputs.TagName_1) & (inputs.Event_1Timestamps == ExeTime);
                                        eventAtTag = inputs.Event_1(idxMatchingTags);
                                        if eventAtTag == 1
                                            eventAtMatchingTags = "On";
                                        else
                                            eventAtMatchingTags = "Off";
                                        end

                                        if CheckForChaneg(eventAtMatchingTags, "Off",[]) == 1
                                            EventActive = 0;
                                            EventActiveInt = 0;
                                        else
                                            EventActive = eventAtMatchingTags;
                                            EventActiveInt = eventAtTag;
                                        end
                                    end
                                else
                                    EventActive = 0;    % Tag name doesn't match tags from the config file
                                    EventActiveInt = 0;
                                end
                            end
                            outputs.EventActive(iCalc) = EventActive;
                            outputs.EventActiveInt(iCalc) = EventActiveInt;
                            outputs.ActiveTagsCount(iCalc) = numel(allEventAtt);
                        else
                            outputs.EventActive(iCalc) = 0;  % No active tags
                            outputs.EventActiveInt(iCalc) = 0;
                            outputs.ActiveTagsCount(iCalc) = 0;
                        end
                    else
                        outputs.EventActive(iCalc) = EventActivestr;  % No change
                        if ismember(EventActivestr,'Off')
                            val = 0;
                        else
                            val = 1;
                        end
                        outputs.EventActiveInt(iCalc) = val;
                        if ~ismember(TagsOutofSigmaString,"")
                            count = numel(TagsOutofSigmaString);
                        else
                            count = 0;
                        end
                        outputs.ActiveTagsCount(iCalc) = count;
                    end

                end

                outputs.EventInt(iCalc) = double(outEvent_RunState);
                

                % Convert the alarm states to strings
                switch  string(outEvent_RunState)
                    case "NoAlarm"
                        outputs.Event(iCalc)  = 0;
                    case "Hi"
                        outputs.Event(iCalc)  = 1;
                    case "HiHi"
                        outputs.Event(iCalc)  = 2;
                    case "ConfigError"
                        outputs.Event(iCalc)  = 4;
                    case "BadTag"
                        outputs.Event(iCalc)  = 5;
                    otherwise
                        outputs.Event(iCalc)  = 3;
                end
            catch err
                %logger.logError("OPM Event Detection Calculation Failed.   NowTime"  + datestr(calcRunTime))
                msg = [err.stack(1).name, ' Line ',...
                    num2str(err.stack(1).line), '. ', err.message];

                logger.logError(msg);
                % Configuration load failed

                errorCode = cce.CalculationErrorState.CalcFailed;
                outputs.Event = 3;  % Alarm state
                outputs.EventActiveInt = [];  % OPMEventActive
                outputs.ActiveTagsCount = [];  % Number of active events
                outputs.EventActive = [];   % On or off
                outputs.ActiveTags = [];
                outputs.EventInt = [];
                outputs.Timestamp = ExeTime;
            end
        end

        %outputs.Timestamp = ExeTime;
        outputs.EventActive = outputs.EventActive(end);

        if isstring(outputs.EventActive)
        if lower(outputs.EventActive) == "off"
            outputs.EventActive = 0;
        elseif lower(outputs.EventActive) == "on"
            outputs.EventActive = 1;
        else
            outputs.EventActive = [];
        end
        end

        outputs.ActiveTags = nan;

        outputs.ActiveTagsCount = outputs.ActiveTagsCount(end);
        outputs.Event = outputs.Event(end);
        outputs.EventActiveInt = outputs.EventActiveInt(end);
        outputs.EventInt = outputs.EventInt(end);
        outputs.Timestamp = ExeTime;
        outputs.Active = nan;

        outputNames = string(fieldnames(outputs));

        for nOut = 1:length(outputNames)
            curOut = outputs.(outputNames(nOut));

            if isempty(curOut)
                outputs.(outputNames(nOut)) = nan; % Set to nan if output empty
            end
        end

    catch err
        outputs.Event = [];  % Alarm state
        outputs.EventActiveInt = [];  % OPMEventActive
        outputs.ActiveTagsCount = [];  % Number of active events
        outputs.EventActive = [];   % On or off
        outputs.ActiveTags = [];
        outputs.EventInt = [];
        outputs.Timestamp = [];

        msg = [err.stack(1).name, ' Line ',...
            num2str(err.stack(1).line), '. ', err.message];

        logger.logError(msg);
        if errorCode == cce.CalculationErrorState.Good || isempty(errorCode)
            errorCode = cce.CalculationErrorState.CalcFailed;
        end
    end

    %% Subroutines
    function TestParameterSize(Matrix, Row, Column, Name)

        [rowCount,colCount] = size(Matrix);
        if colCount ~= Column && rowCount ~= Row
            ME = MException("Parameter File Matrix " + Name + " of " + num2str(rowCount) + " x " + num2str(colCount) + ...
                "does not match required ensions of " + num2str(Row) + " x " + num2str(Column));
            throw(ME)
        end
    end

    function KeyValuePair = ConvertAllVal(AFV, ModelMean)
        % Variable initialisation
        % KeyValuePair contains an integer & a double
        KeyValuePair = struct;
        i = -1;

        if ~isnan(AFV)

            try
                v = AFV;
            catch
                v = nan;
            end

            KeyValuePair.Integer = i;
            KeyValuePair.Value = v;
        else
            try
                KeyValuePair.Integer = i-1;
                KeyValuePair.Value =  ModelMean;
            catch
                KeyValuePair.Integer = i-1;
                KeyValuePair.Value =  nan;
            end

        end
    end

    function State = CheckHi(Val, hi, hihi)
        if isnan(Val)
            State = OPMEnums.State.CalcError;
        else
            if sum(Val) > hihi
                if ~isnan(hihi)
                    State = OPMEnums.State.HiHi;
                else
                    State = OPMEnums.State.NoAlarm; % This event state is not carried through to the final output
                end
            elseif sum(Val) > hi
                if ~isnan(hi)
                    State = OPMEnums.State.Hi;
                else
                    State = OPMEnums.State.NoAlarm; % This event state is not carried through to the final output
                end
            else
                State = OPMEnums.State.NoAlarm;
            end

        end

    end

    function state =  nSigmaModle(nSigmaOut, MoudleState)
        if nSigmaOut == 1 % True
            state =  MoudleState;
        else
            state = OPMEnums.State.NoAlarm;
        end

    end

    function finalMAtrix = BuildRowMatrixFromList(Items)
        MatrixBuild = Items;
        finalMAtrix = full(MatrixBuild); % build dense matrix
    end

    function direction  = ChecktoCalcDirection(Raw, Raw_Sigma, CalDirection)


        if  CalDirection > 0
            direction =  Raw > Raw_Sigma;
        elseif CalDirection < 0
            direction =  Raw < Raw_Sigma;
        elseif CalcDirection > 0  && CalcDirection < 0
            randAssign = randi([1 2]);
            if  randAssign == 1
                direction = Raw > Raw_Sigma;
            else
                direction = Raw < Raw_Sigma;
            end

        else % default and positive direction
            direction =  Raw > Raw_Sigma;
        end
    end

    function Highstate = CombineStatesHighestWins(inStates)

        [~,idx] = max(inStates);
        Highstate = inStates(idx);
    end

    function status = CheckForChaneg(oldVal, newVal, SuppresEmptyNew)
        if ~isempty(SuppresEmptyNew) && SuppresEmptyNew == 1
            if isempty(newVal)
                status = 0; % False
            end
        end

        if oldVal ~= newVal
            status = 1; % True
        else
            status = 0;  % False
        end
    end
end

