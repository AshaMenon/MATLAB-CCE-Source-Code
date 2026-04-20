function [outputs, errorCode] = EvaluateSPO2Model(parameters,inputs)
try
    %Check if there is a timestamp & convert to serial
    inputFields = fieldnames(inputs);
    timestampIdx = find(contains(inputFields,{'Timestamps', 'Timestamp'}));
    if ~isempty(timestampIdx)
        fieldName = inputFields(timestampIdx);
        for i = 1:length(fieldName)
            inputs.(fieldName{i,1}) = datenum(inputs.(fieldName{i,1}));
        end
    end

    % set a file flag to distingish Static from Dynamic models
    if parameters.NiSlagTarget > 0
        fileFlag = 'SPO2Static';
    else
        fileFlag = 'SPO2Dynamic';
    end

    % write it out as .csv
    writetable(struct2table(inputs), fullfile('D:','CCE Dependencies','CCE DataScienceModels', 'PythonFiles', ['inputs'  fileFlag '.csv']));
    writetable(struct2table(parameters), fullfile('D:','CCE Dependencies','CCE DataScienceModels', 'PythonFiles', ['parameters'  fileFlag '.csv']));

    % run python externally
    [status, sysOut] = system(['python "D:/CCE Dependencies/CCE DataScienceModels/PythonFiles/CCEScripts/RunPy' fileFlag '.py"']);
%     [status, sysOut] = system(['python ./CCEScripts/RunPy' fileFlag '.py']);

    % Check it ran successfully
    if ~status
        % read python generated output file
        outputs = readtable(fullfile('D:','CCE Dependencies','CCE DataScienceModels', 'PythonFiles', ['outputs'  fileFlag '.csv']));
        outputs = table2struct(outputs);
        outputs = rmfield(outputs, "Var1");
        errorCode = readlines(fullfile('D:', 'CCE Dependencies','CCE DataScienceModels','PythonFiles', ['error'  fileFlag '.txt']));
        errorCode = str2double(errorCode(1));

        % Convert serial dates to MATLAB datetime
        outputFields = fieldnames(outputs);
        timestampIdx = find(contains(outputFields,{'Timestamps', 'Timestamp'}));
        if ~isempty(timestampIdx)
            fieldName = outputFields(timestampIdx);
            for i = 1:length(fieldName)
                outputs.(fieldName{i,1}) = datetime(outputs.(fieldName{i,1}),...
                    'ConvertFrom','datenum');
            end
        end
    else
        % throw an error if it did not succeed
        error(['Unable to execute python script correctly: ', sysOut]);
    end
catch err
    terminate(pyenv);
    error(['Unhandled python calc exception: ' err.message]);
end
    