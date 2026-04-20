function [outputs,errorCode] = cceACEGenTo2Total(parameters, inputs)

    logger = CCELogger(parameters.LogName, parameters.CalculationID, ...
        parameters.CalculationName, parameters.LogLevel);

    newOutTime = strrep(parameters.OutputTime, "T", " ");
    newOutTime = extractBefore(newOutTime, ".");

    ExeTime = datetime(newOutTime);

    logger.logTrace("Current execution time being used: " + string(ExeTime))

    errorCode = cce.CalculationErrorState.Good;

    try
        Tol = 0.25; %2 value match tolerance percent

        %Get output times from module name
        try

            W_Config = strsplit(parameters.ElementName, "."); %delimit alias name
            W_LenConfig = length(W_Config);

            if W_LenConfig >= 3 %got required number of variables
                W_Period = double(W_Config(end-1));
                W_Offset = double(W_Config(end));

                %set if config is in hours or seconds.
                if W_Period <= 24
                    %period is in hours
                    W_Period = W_Period * 60 * 60;
                    W_Offset = W_Offset * 60 * 60;
                end

                %Retrieve the write-dates
                dates = CommonFunctions.GenerateTotPeriodDates(ExeTime, W_Period, W_Offset);
                first_date = dates(1);
                second_date = dates(2);

                %Run through list of alias in module - input tags

                inputTags = string(fieldnames(inputs));
                inputTags(contains(inputTags, ["Timestamp", "Formula"])) = [];

                %If TagAlias.Name.Contains("ACP:ACE:WACS.LPG.Consumption.Daily.Ave.86400.18300.MeasEt") Then
                % Beakstop As String = "Stopwatch"
                %End If

                try
                    Tot = nan;
                    AliasConfig = strsplit(inputTags(1), "_"); %delimit alias name
                    LenConfig = length(AliasConfig);
                    DoConvsion = false; %must a data formula or conversion be applied

                    if LenConfig >= 4 %got required number of variables

                        %Get PIACEPoint from PIAlias
                        CurrentTag.Times = inputs.(inputTags(1)+"Timestamps");
                        CurrentTag.Values = inputs.(inputTags(1));

                        Period = double(AliasConfig(LenConfig - 2));
                        Offset = double(AliasConfig(LenConfig - 1));
                        TagType = AliasConfig(LenConfig);

                        %set if config is in hours or seconds.
                        if Period <= 24
                            %period is in hours
                            Period = Period * 60 * 60;
                            Offset = Offset * 60 * 60;
                        end

                        Tot = CommonFunctions.GetEndOfDay(CurrentTag, Period, Offset, TagType, ExeTime, Tol);
                        if isempty(Tot)
                            Tot = 0;
                        end
                        
                        try

                            if iscell(parameters.Formula)
                                convFac = parameters.Formula{1};
                            else
                                convFac = parameters.Formula(1);
                            end

                            if ~isnan(str2double(convFac))
                                convFac = str2double(convFac);
                            end

                            if ischar(convFac) || isstring(convFac)
                                DoConvsion = true;
                                %get formula
                                Tot = CommonFunctions.EvalFormulaString(Tot, inputs, convFac, ExeTime,logger);
                            else
                                DoConvsion = true;
                                Tot = Tot * convFac;
                            end
                        catch ex
                            if DoConvsion == true
                                Tot = nan;
                                outputs.("Out_" + inputTags(1)) = [Tot; Tot];
                                logger.logError("#GenTo2tot# Calc Form Error.  " + ...
                                    " NowTime " + string(datetime('now')) + ...
                                    " ExecTime " + string(ExeTime) + ...
                                    " current Tag Alias = " + inputTags(1) + ...
                                    " error: " + ex.message)

                                msg = [ex.stack(1).name, ' Line ',...
                                    num2str(ex.stack(1).line), '. ', ex.message];

                                logger.logError(msg);
                            else
                                if isempty(Tot)
                                    Tot = nan;
                                end
                                outputs.("Out_" + inputTags(1)) = [Tot; Tot];
                            end

                        end

                        %get output tag name
                        % OutTagName As String = CurModule.PIModules(OutPutTagModual_Name).PIAliases(inputTags(1).Name).DataSource.Name

                        outputs.("Out_" + inputTags(1)) = [Tot; Tot];

                    end
                catch ex
                    logger.logError("#GenTo2tot# Calc Error.   NowTime " + ...
                        string(datetime) + " ExecTime " + string(ExeTime) + ...
                        " current Tag Alias = " + inputTags(1) + ...
                        " error: " + ex.message)
                    outputs.("Out_" + inputTags(1)) = [Tot; Tot];

                end

                %testing if used to skip items so that specific aliases can be checked
                %End If

                outputs.Timestamp = [first_date; second_date];

            end
        catch ex
            outputs.Timestamp = [];
            inputTags = string(fieldnames(inputs));
            inputTags(contains(inputTags,["Timestamp", "Formula"])) = [];

            outputs.("Out_" + inputTags(1)) = [];

            errorCode = cce.CalculationErrorState.CalcFailed;

            logger.logError(ex.message)
        end

        outputNames = string(fieldnames(outputs));

        for nOut = 1:length(outputNames)
            curOut = outputs.(outputNames(nOut));

            if isempty(curOut)
                outputs.(outputNames(nOut)) = nan; % Set to nan if output empty
            end

            if any(isinf(curOut))
                outputs.(outputNames(nOut)) = nan(size(curOut)); % Set to nan if output empty
            end
        end

    catch ex
        outputs.Timestamp = [];
        inputTags = string(fieldnames(inputs));
        inputTags(contains(inputTags,["Timestamp", "Formula"])) = [];

        outputs.("Out_" + inputTags(1)) = [];

        errorCode = cce.CalculationErrorState.CalcFailed;

        logger.logError(ex.message)

    end
