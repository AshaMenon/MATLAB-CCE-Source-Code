function [outputs,errorCode] = cceACECalculatedLevel(parameters, inputs)

    % Calculates daily measured stock, daily theoretical stock and surveyed stock.
    % Any surveyed stock values take priority in the theoretical calculation
    % Theoretical Stock= IF no surveyed stock = "previous days stock” + “Add” - “Subtract” else = surveyed stock + PlantMeasures (if any)
    % Measured Stock = Sum of all tags to give a daily stock total
    % Surveyed Stock = sum of survey tag alias values, if there are any vsurvey alues add the plant measuremnts, if there there are
    %  If a surveyed stock alias exists in the context root - write the total to this alias. This gives the option of having multiple survey input tags and having a total survey tag output, or having on a total survey tag.

    logger = CCELogger(parameters.LogName, parameters.CalculationID, ...
        parameters.CalculationName, parameters.LogLevel);

    newOutTime = strrep(parameters.OutputTime, "T", " ");
    newOutTime = extractBefore(newOutTime, ".");

    ExeTime = datetime(newOutTime) + hours(2);

    logger.logTrace("Current execution time being used: " + string(ExeTime))
    errorCode = cce.CalculationErrorState.Good;

    try

        second_date = ExeTime;
        second_date.Hour = 6;
        second_date.Minute = 0;
        second_date.Second = 0;

        Tol = 0.25;

        addInputs = assignInputs(inputs, "Add");
        subInputs = assignInputs(inputs, "Subtract");
        measInputs = assignInputs(inputs, "Measured");
        survInputs = assignInputs(inputs, "Surveyed");
        survPlantMeasInputs = assignInputs(inputs, "PlantMeasure");

        startDate = second_date - caldays(parameters.DaysBack);

        daysToRun = startDate:second_date;

        newStock = nan(size(daysToRun));
        SurveStock = nan(size(daysToRun));
        MeasStock = nan(size(daysToRun));

        for ExeIdx = 1:length(daysToRun)

            try % Measured stock
                %Check for output alias
                %Get PIACEPoint from PIAlias

                try
                    logger.logTrace("Calculating Measured Stock")
                    MeasStock(ExeIdx) = aliasDataGet(measInputs, daysToRun(ExeIdx), Tol, inputs, logger);
                catch ex
                    logger.logError("{#StockCalc#} MeasStock Total failed on: " + ...
                        ex.message + " for run time @ " + ...
                        string(datetime) + " (now) with execution time @ " + ...
                        string(daysToRun(ExeIdx)))
                    MeasStock(ExeIdx) = nan;

                end

            catch
            end

            try %Surveyed Stock level

                try %Get Surveyed Stock level
                    logger.logTrace("Calculating Surveyed Stock")
                    SurveStock(ExeIdx) = aliasDataGet(survInputs, daysToRun(ExeIdx), Tol, inputs, logger);

                    if SurveStock(ExeIdx) == 0
                        SurveStock(ExeIdx) = nan;
                    end

                catch ex
                    logger.logError("{#StockCalc#} SurveyStock Total failed on: " + ...
                        ex.message + " for run time @ " + string(datetime) + ...
                        " (now) with execution time @ " + string(daysToRun(ExeIdx)))
                    SurveStock(ExeIdx) = nan;

                end

                try
                    if SurveStock(ExeIdx) > 0 % Got surveyed values, get PlantMeasures
                        SurvePlantMeasures = aliasDataGet(survPlantMeasInputs, daysToRun(ExeIdx), Tol, inputs, logger);

                        if isnan(SurvePlantMeasures) || isempty(SurvePlantMeasures) || ismissing(SurvePlantMeasures)
                            SurvePlantMeasures = 0;
                        end

                        SurveStock(ExeIdx) = SurveStock(ExeIdx) + SurvePlantMeasures;
                    end
                catch ex
                    logger.logError("{#StockCalc#} SurveyStock Plant Measures Total failed on: " + ...
                        ex.message + " for run time @ " + string(datetime) + ...
                        " (now) with execution time @ " + string(daysToRun(ExeIdx)))
                    SurveStock(ExeIdx) = nan;
                end
            catch
            end

            try % Theoretical stock level
                logger.logTrace("Calculating Theoretical Stock")
                if SurveStock(ExeIdx) > 0 % Got a Surveyed stock figure therefore use it
                    newStock(ExeIdx) = SurveStock(ExeIdx);
                else

                    %If no surveyed value; calculate theoretical stock.

                    try %Previous Stock level
                        %Get PIACEPoint from PIAlias
                        % TheorTag.Values = inputs.TheoreticalStockLevelIn;
                        % TheorTag.Times = inputs.TheoreticalStockLevelInTimestamps;
                        %
                        % PrevStock = CommonFunctions.GetEndOfDay(TheorTag, 24 * 60 * 60, 6 * 60 * 60, "ETot", ExeTime, Tol);

                        prevDay = daysToRun(ExeIdx) - caldays(1);
                        prevDay.Hour = 6;
                        prevDay.Minute = 0;
                        prevDay.Second = 0;

                        stockIdx = ismember(inputs.TheoreticalStockLevelInTimestamps, prevDay);
                        PrevStock = inputs.TheoreticalStockLevelIn(stockIdx);

                        if any(isnan(PrevStock)) || isempty(PrevStock) || ismissing(PrevStock)
                            PrevStock = 0;
                        end

                        AddTot = aliasDataGet(addInputs, daysToRun(ExeIdx), Tol, inputs, logger);
                        if any(isnan(AddTot)) || isempty(AddTot) || ismissing(AddTot)
                            AddTot = 0;
                        end

                        SubTot = aliasDataGet(subInputs, daysToRun(ExeIdx), Tol, inputs, logger);
                        if any(isnan(SubTot)) || isempty(SubTot) || ismissing(SubTot)
                            SubTot = 0;
                        end

                        newStock(ExeIdx) = PrevStock(end) + AddTot(end) - SubTot(end);
                    catch ex
                        logger.logError("{#StockCalc#} TheoreticalStock failed on: " + ex.message + ...
                            " for run time @ " + string(datetime) + ...
                            " (now) with execution time @ " + string(daysToRun(ExeIdx)))
                        newStock(ExeIdx) = nan;
                    end


                end
            catch ex
                % can not write out
                logger.logError("{#StockCalc#} TheoreticalStock failed on: " + ex.message + ...
                    " for run time @ " + string(datetime) + ...
                    " (now) with execution time @ " + string(ExeTime))
            end
        end

        outputs.TheoreticalStockLevel = newStock;
        outputs.SurveyedStockLevel = SurveStock;
        outputs.MeasuredStockLevel = MeasStock;

        outputs.Timestamp = daysToRun';

        logger.logTrace("Complete")
    catch err
        outputs.MeasuredStockLevel = [];
        outputs.SurveyedStockLevel = [];
        outputs.TheoreticalStockLevel = [];
        outputs.Timestamp = [];

        msg = [err.stack(1).name, ' Line ',...
            num2str(err.stack(1).line), '. ', err.message];
        logger.logError(msg);
        if errorCode == cce.CalculationErrorState.Good || isempty(errorCode)
            errorCode = cce.CalculationErrorState.CalcFailed;
        end
    end
end

function assignedInputs = assignInputs(inStruct, inputTypeString)
    assignedInputs = struct;

    inputFieldNames = string(fieldnames(inStruct));
    inputFieldNames(~contains(inputFieldNames, inputTypeString)) = [];

    for fieldName = inputFieldNames'
        assignedInputs.(fieldName) = inStruct.(fieldName);
    end
end

function RetVal = aliasDataGet(aliasStruct, ExecTimeD, MatchTol, inputs, logger)
    %Delimites the alias name and sends the info to the function to return the totalised value
    RetVal = 0;

    try
        tagAliases = string(fieldnames(aliasStruct));
        tagAliases(contains(tagAliases, "Timestamps")) = [];

        for Tag_Alias = tagAliases'

            IntVal = 0;

            try
                AliasConfig = strsplit(Tag_Alias, "_"); %delimit alias name
                LenConfig = length(AliasConfig);

                if LenConfig >= 4 %got required number of variables

                    %Get PIACEPoint from PIAlias
                    CurrentTag.Values = aliasStruct.(Tag_Alias);
                    CurrentTag.Times = aliasStruct.(Tag_Alias + "Timestamps");

                    Period = double(AliasConfig(LenConfig - 2));
                    Offset = double(AliasConfig(LenConfig - 1));
                    TagType = AliasConfig(LenConfig);

                    %set if config is in hours or seconds.
                    if Period <= 24
                        %period is in hours
                        Period = Period * 60 * 60;
                        Offset = Offset * 60 * 60;
                    end

                    IntVal = CommonFunctions.GetEndOfDay(CurrentTag, Period, Offset, TagType, ExecTimeD, MatchTol);

                    if isempty(IntVal) || isnan(IntVal) || ismissing(IntVal)
                        IntVal = 0;
                    end

                    try
                        %Get conversion formula from properties and apply
                        convFac = parameters.("Formula_"+Tag_Alias);

                        if ischar(convFac)
                            %get formula
                            IntVal = CommonFunctions.EvalFormulaString(IntVal, inputs, convFac, ExecTimeD);
                        else
                            IntVal = IntVal * convFac;
                        end
                    catch
                        %do nothing
                    end

                end

            catch ex
                IntVal = 0;
                msg = [ex.stack(1).name, ' Line ',...
                    num2str(ex.stack(1).line), '. ', ex.message];

                logger.logError(msg);
            end

            RetVal = RetVal + IntVal;

        end
    catch

    end

    if isempty(RetVal) || isnan(RetVal) || ismissing(RetVal)
        RetVal = 0;
    end
end