function [outputs, errorCode] = EvaluateMockModel(parameters,inputs)
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

    % write it out as .xml
    writetable(struct2table(inputs), fullfile('D:', 'PythonFiles', 'inputsMockModel.csv'));
    writetable(struct2table(parameters), fullfile('D:', 'PythonFiles', 'parametersMockModel.csv'));

    % run python externally
%     [status, sysOut] = system('python D:/PythonFiles/CCEScripts/RunMockModel.py');
    %[status, sysOut] = system('python RunMockModel.py');
    [status, sysOut] = system('C:\Users\KimendreeNaidoo\AppData\Local\Programs\Python\Python38\pythonw.exe runMockModel.py');

    % Check it ran successfully
    if ~status
        % read python generated output file
        outputs = readtable(fullfile('D:', 'PythonFiles', 'outputsMockModel.csv'));
        outputs = table2struct(outputs);
        outputs = rmfield(outputs, "Var1");
        errorCode = readlines(fullfile('D:', 'PythonFiles', 'errorMockModel.txt'));
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
    error(['Unhandled python calc exception: ' err.message]);
end