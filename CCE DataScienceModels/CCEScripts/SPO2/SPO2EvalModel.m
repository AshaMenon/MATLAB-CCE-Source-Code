function [outputs, errorCode] = SPO2EvalModel(parameters,inputs)
    %LINEARBASICITYMODEL Function to call the Python LinearBasicityModelfunction
    try
        pyenv("ExecutionMode","OutOfProcess");
        % Setup
        exec = pyenv;
        if exec.Status == "NotLoaded"
            try
                terminate(pyenv);
                exec = pyenv("Version", "3.8");
            catch ME
                disp(ME.message);
                ME.message
            end
        end

        [v, exe] = pyversion;
        eval("py.multiprocessing.spawn.set_executable(exe)");

        % Get absolute path of the deployment folder
        filePath = which('EvaluateSPO2.py');
        filePath = erase(filePath,'\EvaluateSPO2.py');

        % Add this path to the Python Search Path
        if eval('count(py.sys.path,filePath) == 0')
            eval('insert(py.sys.path,int32(0),filePath)');
        end
        
        % Reload Python Modules - This must be done to ensure that we use the latest version of the
        % Python code if we update the CTF and don't restart the workers.
        SPO2EvalreloadPythonModule;
        
        % Check if there is a timestamp & convert to serial
        inputFields = fieldnames(inputs);
        timestampIdx = find(contains(inputFields,{'Timestamps', 'Timestamp'}));
        if ~isempty(timestampIdx)
            fieldName = inputFields(timestampIdx);
            for i = 1:length(fieldName)
                inputs.(fieldName{i,1}) = datenum(inputs.(fieldName{i,1}));
            end
        end
        
        outputPy = eval('py.EvaluateSPO2.EvaluateSPO2(parameters, inputs)');
        outputArray = cell(outputPy);
        outputs = struct(outputArray{1});
        outputFields = fieldnames(outputs);
        % Check for empty py.list and convert to empty array
        for i = 1:length(outputFields)
            if isa(outputs.(outputFields{i}), 'py.list')
                outputs.(outputFields{i}) = cell2mat(cell(outputs.(outputFields{i})));
                if isempty(outputs.(outputFields{i}))
                    outputs.(outputFields{i}) = [];
                end
            end
        end
        
        % Convert serial dates to MATLAB datetime
        timestampIdx = find(contains(outputFields,{'Timestamps', 'Timestamp'}));
        if ~isempty(timestampIdx)
            fieldName = outputFields(timestampIdx);
            for i = 1:length(fieldName)
                outputs.(fieldName{i,1}) = datetime(outputs.(fieldName{i,1}),...
                    'ConvertFrom','datenum');
            end
        end
        errorCode = double(outputArray{2});
        terminate(pyenv);
    catch err
        error(['Unhandled python calc exception: ' err.message]);
        terminate(pyenv);
    end
end

