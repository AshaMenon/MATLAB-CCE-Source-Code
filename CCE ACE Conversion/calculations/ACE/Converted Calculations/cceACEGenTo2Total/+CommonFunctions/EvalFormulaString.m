function Result = EvalFormulaString( BaseTagVal, inputs, FormulaString, ExecTimeD,logger)
    whileLoopBreakLimit = 100;
    Whilecount = 0;
    Result = [];
    BaseTagString = "'tag'";
    Delimiter = "'";
    tagIndex = 0;
    TagDataDelim = ".";
    MatchTol = 0.25;
    LoopCount = 0;
    TaglistArr = [];

    try
        %FormulaString = FormulaString.Replace(" ", "") 'remove white spaces
        %do not remove white spaces as they are allowed in tag names
        % substitute in base tag data

        FormulaString = strrep(FormulaString, BaseTagString, string(BaseTagVal));

        Split = strsplit(FormulaString, Delimiter);
        if length(Split) == 1 % contains no tags
            %no action

        elseif length(Split) >= 2  % got tags and info

            if strfind(FormulaString, Delimiter) > 1
                tagIndex = 2; % first string is a tag, but split
            else
                tagIndex = 1;
            end

            for St = Split

                if LoopCount == tagIndex && ~isempty(St) % current string is a tag
                    logger.logTrace("TagIdx " + tagIndex)
                    logger.logTrace("Split len " + length(Split))
                    subString = Delimiter + Split(tagIndex) + Delimiter + Split(tagIndex + 1) + Delimiter;
                    
                    GotTagDat = false;
                    %Check tag is not in array list
                    for TagList = TaglistArr
                        if TagList == subString %got item
                            GotTagDat = true; % do not need to substitute in - done previously
                            break
                        end
                    end

                    if GotTagDat == false %get data and substitute in string
                        TagData = strsplit(Split(tagIndex + 1), TagDataDelim);

                        if length(TagData) == 3 % only continue if there is the correct data
                            Period = double(TagData(1));
                            Offset = double(TagData(2));
                            Type = TagData(3);

                            if Period <= 24
                                %period is in hours
                                Period = Period * 60 * 60;
                                Offset = Offset * 60 * 60;
                            end

                            %get tag

                            try
                                tagName = strsplit(subString, "'");
                                tagName = "Formula_" + tagName(2);
                                tagName = matlab.lang.makeValidName(tagName);

                                CurrentTag.Values = inputs.(tagName);
                                CurrentTag.Times = inputs.(tagName + "Timestamps");

                                %get data
                                itVal = CommonFunctions.GetEndOfDay(CurrentTag, Period, Offset, Type, ExecTimeD, MatchTol);
                            catch ex
                                itVal = 0;

                                msg = [ex.stack(1).name, ' Line ',...
                                    num2str(ex.stack(1).line), '. ', ex.message];

                                logger.logError(msg);
                            end

                            if isempty(itVal) || isnan(itVal)
                                itVal = 0;
                            end
                            %substitute in original string
                            if contains(FormulaString, subString)
                                FormulaString = strrep(FormulaString, subString, string(itVal(end)));
                                logger.logTrace(FormulaString)
                            end

                            % add to tag array list
                            TaglistArr = [TaglistArr; subString];

                        else
                            throw(MException('EvalFormulaString:inputError', "not enough tag data: " + string(FormulaString)))
                        end
                    end
                    %Step tag index, can not have two tags next to each other
                    %Will have 'tag'data' exp 'tag'data'
                    tagIndex = tagIndex + 3;

                end
                %step loop counter
                LoopCount = LoopCount + 1;
            end
        else
            throw(MException("EvalFormulaString:configError", "Config error: " + string(FormulaString)))
        end

        % SctCont As New MSScriptControl.ScriptControl()
        %set scripting language
        %SctCont.Language = "VBScript"

        % Check if the input string has an iIF function - if it does evaluate
        if contains(FormulaString, "IF(")

            %check for disallowed characters
            if contains(FormulaString, "#")
                throw(MException("EvalFormulaString:inputError", "Formula string contains a ""#"": " + string(FormulaString)))
            end
            %Remove spaces
            FormulaString = strrep(FormulaString, " ", ""); % done after tags are evaluated, in case tags contain spaces or #

            % replace IF( if function with a delimiter
            IfStr = strrep(FormulaString, "IF(", "#");
            %Split on delimiter
            splitIIf = strsplit(IfStr, "#"); % will evaluate any number of If functions
            for Substr = splitIIf

                %split sub-strings to find arguments
                If_str = strsplit(Substr, ",");

                % check inputs
                if length(If_str) == 3 %else not enough, or too many arguments
                    IIfres = "";
                    FalseStr = "";
                    %Check condition

                    % Get false expression - by counting ( and ) as there can be trailing text
                    FalseChar = char(If_str(3));
                    CloseBrace = 0;
                    OpenBrace = 0;
                    FalseEnd = 0;
                    CloseCmp = ')';
                    OpenCmp = '(';

                    for fn = 1:length(FalseChar)
                        if FalseChar(fn) == CloseCmp
                            CloseBrace = CloseBrace + 1;
                        elseif FalseChar(fn) == OpenCmp
                            OpenBrace = OpenBrace + 1;
                        end

                        if CloseBrace > OpenBrace % last ) for if function
                            FalseEnd = fn;
                            break
                        end

                    end
                    %Get False expression
                    FalseStr = If_str(3).Substring(0, FalseEnd);

                    %evaluate
                    try
                        eval(If_str(1));
                        Logic = true;
                    catch
                        Logic = false;
                    end

                    if Logic %Evaluate condition
                        %If true

                        IIfres = string(eval(If_str(2)));
                    else
                        %If false
                        IIfres = string(eval(FalseStr));
                    end

                    %older using MSscript
                    %If Convert.ToBoolean(SctCont.Eval(If_str(0))) Then 'Evaluate condition
                    %    'If true
                    %    IIfres = Convert.ToString(SctCont.Eval(If_str(1)))
                    %Else
                    %    'If false
                    %    IIfres = Convert.ToString(SctCont.Eval(FalseStr))
                    %End If

                    %replace IF expression with result
                    %substitute into original string
                    FormulaString = FormulaString.Replace("IF(" & If_str(1) & "," & If_str(2) & "," & FalseStr & ")", IIfres);

                else
                    %no action, could be any trailing or leading string
                end

            end

        end
        % end of IF string evaluation

        %evaluate final expression
        logger.logTrace(FormulaString)
        Result = eval(FormulaString);

        if isnan(Result) || isinf(Result)
            Result = 0;
        end

        %Result = SctCont.Eval(FormulaString)

    catch ex
        %throw(MException("EvalFormulaString:calcError", "error: " + string(FormulaString) + " " + ex.message))
        rethrow(ex)
    end

end