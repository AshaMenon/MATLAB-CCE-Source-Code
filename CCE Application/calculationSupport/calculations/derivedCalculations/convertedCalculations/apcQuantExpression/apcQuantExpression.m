function [outputs, errorCode] = apcQuantExpression(parameters, inputs)
    %APCQUANTEXPRESSION Computes dVal based on specified expression.
    % The output instrument’s unit is used as the expected units as well as the resulting unit.
    %inputs:struct with the following fields for each input sensor:
    %   
    %   Value - eg. InputSensor1Value = [nx1] Double
    %   Timestamps - eg. InputSensor1Timestamps = [nx1] Datetime 
    %   Quality - eg. InputSensor1Quality = [nx1] Double
    %   Active - eg. InputSensor1Active = [nx1] Double
    %   Condition- eg. InputSensor1Condition = [nx1] Double
    
    %parameters: struct with the following fields:
    %   LogName
    %   CalculationID
    %   LogLevel
    %   CalculationName
    %   Expression - There will only be one expression
    %   DerivedSensorClass - Output sensor class
    %   DerivedSensorEU - Output sensor class
    %   DerivedSensorSG - Output sensor class
    %   ID - eg. InputSensor1ID = 'P1'
    %   Eu: Sensor Engineering Units - for each input sensor
    %   Sg - for each input sensor
    
    %outputs: struct with the following fields:
    %   DVal
    %   DQual
    %   Timestamp

    logFile = parameters.LogName;
    calculationID = parameters.CalculationID;
    logLevel = parameters.LogLevel;
    calculationName = parameters.CalculationName;
    log = CCELogger(logFile, calculationName, calculationID,logLevel);
    errorCode = cce.CalculationErrorState.Good;
    
    try
        % Read inputs
        funcInputs{1} = char(parameters.DerivedSensorClass);
        funcInputs{2} = char(parameters.DerivedSensorEU);
        funcInputs{3} = parameters.DerivedSensorSG;
        sensorNum = length(fieldnames(inputs))/5;
        valueLength = length(inputs.InputSensor1);
        expression{1} = char(parameters.Expression);
        expression{2} = NaN(valueLength,1);
        expression{3} = NaN(valueLength,1);
        expression{4} = inputs.InputSensor1Timestamps;
        expression{5} = NaN(valueLength,1);
        expression{6} = NaN(valueLength,1);
        expression{7} = 'nan';
        expression{8} = NaN;

        k = 0;
        for i = 1:sensorNum
            sensorInputs{k+1} = char(parameters.(sprintf('InputSensor%dID',i)));
            sensorInputs{k+2} = inputs.(sprintf('InputSensor%d',i));
            sensorInputs{k+3} = inputs.(sprintf('InputSensor%dQuality',i));
            sensorInputs{k+4} = inputs.(sprintf('InputSensor%dTimestamps',i));
            sensorInputs{k+5} = inputs.(sprintf('InputSensor%dActive',i));
            sensorInputs{k+6} = inputs.(sprintf('InputSensor%dCondition',i));
            sensorInputs{k+7} = char(parameters.(sprintf('InputSensor%dEu',i)));
            sensorInputs{k+8} = parameters.(sprintf('InputSensor%dSg',i));
            k = k + 8;
        end
        funcInputs = [funcInputs, expression, sensorInputs];
        
        %TODO: Improve code and efficiency by removing parseInputs.
        
        % Parse inputs
        [derivedSensorClass,derivedSensorEU,derivedSensorSG,numInputs,id,value,quality,timeStamp,...
            active,condition,eu,sg,constants,leadingConstants,ignoreInd] = parseInputs(funcInputs,false,'');
       
        % Call algorithm
        [dVal, dQual, dTime] = apcQuantExpressionAlgorithm(derivedSensorClass,...
        derivedSensorEU,derivedSensorSG,numInputs,id,value,quality,timeStamp,...
            active,condition,eu,sg,constants,leadingConstants,ignoreInd, funcInputs);
        
        log.logInfo('[%d, %d]', [dVal, dQual]);
        outputs.DerivedSensorQuality = dQual;
        outputs.DerivedSensor = dVal;
        outputs.Timestamp = dTime;
    catch err
        outputs.DerivedSensorQuality = [];
        outputs.DerivedSensor = [];
        outputs.Timestamp = [];
        msg = [err.stack(1).name, ' Line ',...
            num2str(err.stack(1).line), '. ', err.message];
        log.logError(msg);
        if errorCode == cce.CalculationErrorState.Good || isempty(errorCode)
            errorCode = cce.CalculationErrorState.CalcFailed;
        end
    end
    errorCode = uint32(errorCode);
end
