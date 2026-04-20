function [outputs, errorCode] = ccePyForecastConcKpi(parameters,inputs)
try
    %Check if there is a timestamp & convert to serial
    siteFolder = parameters.siteName;
    inputFields = fieldnames(inputs);
    timestampIdx = find(contains(inputFields,{'Timestamps', 'Timestamp'}));
    if ~isempty(timestampIdx)
        fieldName = inputFields(timestampIdx);
        for i = 1:length(fieldName)
            inputs.(fieldName{i,1}) = datenum(inputs.(fieldName{i,1}));
        end
    end

    % write it out as .xml
    writetable(struct2table(inputs), fullfile('D:', 'CCE Dependencies','CCE DataScienceModels', 'PythonFiles', 'Data', 'Forecast',siteFolder,'inputsForecast.csv'));
    writetable(struct2table(parameters), fullfile('D:','CCE Dependencies','CCE DataScienceModels', 'PythonFiles', 'Data', 'Forecast', siteFolder, 'parametersForecast.csv'));

    % run python externally
    [status, sysOut] = system(sprintf('python "D:/CCE Dependencies/CCE DataScienceModels/PythonFiles/CCEScripts/RunPyForecast.py" %s', siteFolder));
%     [status, sysOut] = system('python ./CCEScripts/RunPyBasicity.py');

    % Check it ran successfully
    if ~status
        % read python generated output file
        outputs = readtable(fullfile('D:', 'CCE Dependencies', 'CCE DataScienceModels', 'PythonFiles', 'Data', 'Forecast', siteFolder, 'outputsForecast.csv'));
        outputs = table2struct(outputs);
        outputs = rmfield(outputs, "Var1");
        errorCode = readlines(fullfile('D:', 'CCE Dependencies', 'CCE DataScienceModels', 'PythonFiles', 'Data', 'Forecast', siteFolder, 'errorForecast.txt'));
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

        % Set to boolean
        % if isequal(outputs.ProcessSteadyState, 'True')
        %     outputs.ProcessSteadyState = true;
        % else
        %     outputs.ProcessSteadyState = false; 
        % end
    else
        % throw an error if it did not succeed
        error(['Unable to execute python script correctly: ', sysOut]);
    end
catch err
    error(['Unhandled python calc exception: ' err.message]);
end