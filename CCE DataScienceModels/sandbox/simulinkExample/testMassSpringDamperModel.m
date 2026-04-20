function [outputs, errorCode] = testMassSpringDamperModel(parameters,inputs)
    %UNTITLED6 Summary of this function goes here
    %   Detailed explanation goes here
    %   This a template for CCE MATLAB calculations. 
    %   Replace calculationTemplate with the calculation name.
    %   parameters is a struct that includes data that does not have a 
    %   value in time and can be considered constants 
    %   inputs have one or more historical values for a particular
    %   element/attribute based on the output time. 
    
    % Create Log
    logFile = parameters.LogName;
    calculationID = parameters.CalculationID;
    logLevel = parameters.LogLevel;
    calculationName = parameters.CalculationName;
%     log = CCELogger(logFile, calculationName, calculationID,logLevel);
    errorCode = cce.CalculationErrorState.Good;
        
    try
        %open_system('MassSpringDamperModel');
        simOut = massSpringDamperModel(inputs, parameters);
        
        if isempty(simOut.ErrorMessage)
            %outputs.Position = simOut.y.signals(1).values(end);
            %outputs.Velocity = simOut.y.signals(2).values(end);
            outputs.Position = simOut.logsout{1}.Values.Data(end);
            outputs.Velocity = simOut.logsout{2}.Values.Data(end);
            outputs.Timestamp = datetime('now');
        else
            error(simOut.ErrorMessage)
        end
    catch err
        outputs.Position = [];
        outputs.Velocity = [];
        outputs.Timestamp = [];
        msg = [err.stack(1).name, ' Line ',...
            num2str(err.stack(1).line), '. ', err.message];
%         log.logError(msg);
        fileID = fopen('logfile.txt', 'a'); % Open log file in append mode
        
        % Write log message to file
      
        fprintf(fileID, '%s\n', msg);
        
        fclose(fileID); % Close log file
        if errorCode == cce.CalculationErrorState.Good || isempty(errorCode)
            errorCode = cce.CalculationErrorState.CalcFailed;
        end
    end
    errorCode = uint32(errorCode);
end