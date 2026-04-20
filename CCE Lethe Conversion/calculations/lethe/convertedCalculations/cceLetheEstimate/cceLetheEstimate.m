function [outputs, errorCode] = cceLetheEstimate(parameters, inputs)
    %UNTITLED Summary of this function goes here
    %   Detailed explanation goes here
    
    try
        % Get path of calculation
        filePath = which('cceLetheEstimate.dll');
        if isempty(which("cceLetheEstimate.cceLetheEstimateClass"))
            asm = NET.addAssembly(filePath); %#ok<NASGU>
        end     
        
        % Create instance of class and set inputs and parameters
        calcInstance = cceLetheEstimate.cceLetheEstimateClass();
        
        % Assign Parameters
        netParams = cceLetheEstimate.Parameters();
        netParamsFields = string(properties(netParams));
        for iField = 1:length(netParamsFields)
            fieldName = char(netParamsFields(iField));
            val = assignDataToVariables(netParams.(fieldName), parameters, fieldName);
            if ~isempty(val)
                netParams.(fieldName) = val;
            end
        end
        
        % Check for rollups
        if isfield(parameters, "RollupInputs") && ~isempty(parameters.RollupInputs)
            rollupInputs = parameters.RollupInputs;
        else
            rollupInputs = string();
        end
        rollupSuffixNames = rollupInputs + "Suffixes";

        % Check for additional inputs
        if isfield(parameters, "AdditionalInputs") && ~isempty(parameters.AdditionalInputs)
            additionalInputFields = parameters.AdditionalInputs;
        else
            additionalInputFields = string([]);
        end
        
        % Assign Inputs
        netInputs = cceLetheEstimate.Inputs();
        netInputsFields = string(properties(netInputs));
        for iField = 1:length(netInputsFields)
            fieldName = char(netInputsFields(iField));
            if ~ismember(fieldName, rollupSuffixNames)
                if ismember(fieldName, rollupInputs)
                    %Apply rollup behavior
                    [valArray, suffixStr] = rollupInput(fieldName, inputs);
                    netInputs.(fieldName) = valArray;
                    netInputs.([fieldName, 'Suffixes']) = cellstr(suffixStr');
                elseif ismember(fieldName, ["AdditionalInputs", "AdditionalTimestamps"])
                    % Skip these inputs as they will be handled later
                else
                    %Non rollup input
                    if contains(fieldName, 'Timestamps')
                        %Timestamps
                        natIdx = isnat(inputs.(fieldName));

                        if nnz(natIdx) > 0
                            inputs.(fieldName)(natIdx) = datetime('yesterday'); %set default date
                        end

                        netInputs.(fieldName) = parseMatlabDateTime(inputs.(fieldName));
                    else
                        %Normal inputs
                        val = assignDataToVariables(netInputs.(fieldName), inputs, fieldName);
                        if ~isempty(val)
                            netInputs.(fieldName) = val;
                        end
                    end
                end
            end
        end

        if ~isempty(additionalInputFields)
            % Combine additional inputs into 2D double and DateTime arrays
            [outVal, outTime] = combineAdditionalInputs(inputs, additionalInputFields);

            netInputs.AdditionalInputs = outVal;
            netInputs.AdditionalTimestamps = parseMatlabDateTime(outTime);
        end
        
        %Set logging parameters
        calcInstance.CalculationID = parameters.CalculationID;
        calcInstance.CalculationName = parameters.CalculationName;
        calcInstance.LogLevel = parameters.LogLevel;
        calcInstance.LogName = parameters.LogName;
        
        % Run calc
        sOutputs = calcInstance.RunCalc(netParams, netInputs);
        
        % Get outputs
        outputFields = fieldnames(sOutputs);
        for iField = 1:length(outputFields)
            % Convert arrays
            if contains(class(sOutputs.(outputFields{iField})), '[]')
                outputs.(outputFields{iField}) = convertNetArrayToMatlabArray(sOutputs.(outputFields{iField}));
            else
                % Convert .NET System.DateTime to MATLAB datetime
                if strcmp(outputFields{iField}, 'Timestamp')
                    if sOutputs.(outputFields{iField}).Length < 1
                        sOutputs.(outputFields{iField}) = [];
                    else
                        outputs.(outputFields{iField}) = datetime(parseNetDateTime(sOutputs.(outputFields{iField})(1)),...
                            'Format', 'dd/MM/yyyy HH:mm:ss');
                    end
                else
                    outputs.(outputFields{iField}) = sOutputs.(outputFields{iField});
                end
            end
        end
        errorCode = calcInstance.ErrorCode;
        errorCode = errorCode.GetHashCode;
        
    catch err
        error(['Unhandled .NET calc exception: ' err.message]);
    end
end

function [valArray, suffixStr] = rollupInput(prefixString, availInputs)
    %rollupInput Looks at the available input values, and assigns
    %them to Input variables in the .net class with matching substrings,
    %each in a new column
    availFields = fieldnames(availInputs);
    useIdx = contains(availFields, prefixString);
    useFields = availFields(useIdx);
    
    %Remove Timestamps if included
    timeStampsIdx = contains(string(useFields), "Timestamps");
    useFields(timeStampsIdx) = [];
    
    if ~isempty(useFields)
        valArray = NaN(numel(availInputs.(useFields{1})), numel(useFields));
        suffixStr = strings([1, numel(useFields)]);
        for iField = 1:numel(useFields)
            valArray(:, iField) = availInputs.(useFields{iField});
            suffixStr(iField) = erase(useFields(iField), prefixString);
        end
    else
        suffixStr = {};
        valArray = NaN;
    end
end

function outVal = assignDataToVariables(netInput, availInputs, fieldName)
    %ASSIGNDATATOVARIABLES replaces missing data values with NaN's
    if isfield(availInputs, fieldName)
        outVal = availInputs.(fieldName);
    else
        if ~isempty(netInput) && isnumeric(netInput) && netInput == 0
            outVal = NaN;
        else
            outVal = [];
        end
    end
end

function [outVal, outTime] = combineAdditionalInputs(additionalInputs, inputFields)
% COMBINEADDITIONALINPUTS Combine additional inputs into 2D double and DateTime arrays

arraySizes = structfun(@length,additionalInputs);

outVal = nan(max(arraySizes), length(inputFields));
outTime = NaT(max(arraySizes), length(inputFields));
colIdx = 1;

for field = inputFields
    val = additionalInputs.(field);
    outVal(1:length(val), colIdx) = val;

    if any(ismember(fieldnames(additionalInputs), field + "Timestamps"))
        timestamps = additionalInputs.(field + "Timestamps");
        outTime(1:length(timestamps), colIdx) = timestamps;
    end

    colIdx = colIdx + 1;
end
end

