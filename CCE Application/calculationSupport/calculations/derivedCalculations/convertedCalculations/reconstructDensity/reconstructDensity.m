function [outputs, errorCode] = reconstructDensity(parameters, inputs)
    %RECONSTRUCTDENSITY Compute reconstructed density forwards or backwards with quality
    %   Computes in mill density taking into account associated sensor quality values in Q1 and Q2.
    %   For backwards need to spec at least water feed, slurry density, slurry flow
    %   For forwards need to spec at least solids feed, water feed

    %inputs:struct with the following fields:
    %   SolidsFeed
    %   SolidsFeedQuality
    %   SolidsFeedTimestamps
    %   WaterFeed
    %   WaterFeedQuality
    %   WaterFeedTimestamps
    %   SlurryDensity
    %   SlurryDensityQuality
    %   SlurryDensityTimestamps
    %   SlurryFlow
    %   SlurryFlowQuality
    %   SlurryFlowTimestamps
    
    %parameters: struct with the following fields:
    %   LogName
    %   CalculationID
    %   LogLevel
    %   CalculationName
    %   K1 - circulating load solids %
    %   K2 - circulating moisture %
    %   K3 - flag (1 - calculate from input side / 2 - calculate from discharge side)
    %   K4 - solidsSG 
    
    %outputs: struct with the following fields:
    %   DDVal
    %   DDQual
    
    %% Create Log
    logFile = parameters.LogName;
    calculationID = parameters.CalculationID;
    logLevel = parameters.LogLevel;
    calculationName = parameters.CalculationName;
    log = CCELogger(logFile, calculationName, calculationID,logLevel);
    errorCode = cce.CalculationErrorState.Good;
    
    try 
    % Parameters
    
    K1 = assignDataToVariables(parameters,'K1');
    K2 = assignDataToVariables(parameters,'K2');
    K3 = assignDataToVariables(parameters,'K3');
    K4 = assignDataToVariables(parameters,'K4');
 
    % Compulsory Inputs
    V2 = inputs.WaterFeed;
    Q2 = inputs.WaterFeedQuality;
    T2 = inputs.WaterFeedTimestamps;
    
    % Optional Inputs
    V1 = assignDataToVariables(inputs,'SolidsFeed');
    Q1 = assignDataToVariables(inputs,'SolidsFeedQuality');
    T1 = assignDataToVariables(inputs,'SolidsFeedTimestamps');
    V3 = assignDataToVariables(inputs,'SlurryDensity');
    Q3 = assignDataToVariables(inputs,'SlurryDensityQuality');
    T3 = assignDataToVariables(inputs,'SlurryDensityTimestamps');
    V4 = assignDataToVariables(inputs,'SlurryFlow');
    Q4 = assignDataToVariables(inputs,'SlurryFlowQuality');
    T4 = assignDataToVariables(inputs,'SlurryFlowTimestamps');

    % Define waterSG
    waterSG = 1;
    
    %% Calculate dry solids in the streams
    % If slurry flow & density specified
    solidsMass = [];
    waterMass = [];
    
    if min(size(V3)) > 0 && min(size(V4)) > 0
        [solidsFractionSlurry, solidsFractionSlurryQ,...
            solidsFractionSlurryT] = derivedSubtract(V3, Q3, T3, waterSG);
        [solidsFractionSlurry, solidsFractionSlurryQ,...
            solidsFractionSlurryT] =...
            derivedDivide(solidsFractionSlurry, solidsFractionSlurryQ,...
            solidsFractionSlurryT, (K4-waterSG));
        solidsFractionSlurry(solidsFractionSlurry<0) = 0;
        
        [solidsMass, solidsMassQ, solidsMassT] =...
            derivedMultiply(solidsFractionSlurry,...
            solidsFractionSlurryQ, solidsFractionSlurryT, V4, Q4, T4, K4);
        [waterMass ,waterMassQ, waterMassT] =...
            derivedMultiply((1-solidsFractionSlurry),...
            solidsFractionSlurryQ,solidsFractionSlurryT,V4,Q4,T4,waterSG);
    end
    
    % If circulating load, solids feed and water feed specified
    waterFeed = [];
    if min(size(K2)) > 0 && min(size(K1)) > 0 && min(size(V1)) > 0 && min(size(V2)) > 0
        % Add circulating load to waterFeed
        [waterFeed,waterFeedQ,waterFeedT] = derivedMultiply(V1,Q1,T1,(K1/100 * K2/100));
        [waterFeed,waterFeedQ,waterFeedT] = derivedAdd(V2,Q2,T2,waterFeed,waterFeedQ,waterFeedT);
    elseif min(size(V2)) > 0
        waterFeed = V2;
        waterFeedQ = Q2;
        waterFeedT = T2;
    end
    
    % If circulating load and solids feed specified
    solidsFeed = [];
    if min(size(K2)) > 0 && min(size(K1)) > 0 && min(size(V1)) > 0
        % Add circulating load to solidsFeed
        [solidsFeed,solidsFeedQ,solidsFeedT] = derivedMultiply(V1,Q1,T1,K1/100);
        [solidsFeed,solidsFeedQ,solidsFeedT] = derivedAdd(V1,Q1,T1,...
            solidsFeed,solidsFeedQ,solidsFeedT);
    elseif min(size(V1)) > 0
        solidsFeed = V1;
        solidsFeedQ = Q1;
        solidsFeedT = T1;
    end
    
    if min(size(solidsFeed)) > 0 && min(size(solidsMass)) > 0
        [solidsMass,solidsMassQ,solidsMassT] = derivedAdd(solidsMass,...
            solidsMassQ,solidsMassT,solidsFeed,solidsFeedQ,solidsFeedT);
    elseif min(size(solidsFeed)) > 0
        solidsMass = solidsFeed;
        solidsMassQ = solidsFeedQ;
        solidsMassT = solidsFeedT;
    end
    
    if min(size(waterFeed)) > 0 && min(size(waterMass)) > 0
        if K3 == 1
            [waterMass,waterMassQ,waterMassT] = derivedAdd(waterMass,...
                waterMassQ,waterMassT,waterFeed,waterFeedQ,waterFeedT);
        elseif K3 == 2
            [waterMass,waterMassQ,waterMassT] = derivedSubtract(waterMass,...
                waterMassQ,waterMassT,waterFeed,waterFeedQ,waterFeedT);
        end
    elseif min(size(waterFeed)) > 0
        if K3 == 1
            waterMass = waterFeed;
            waterMassQ = waterFeedQ;
            waterMassT = waterFeedT;
        elseif K3 == 2
            waterMass = -waterFeed;
            waterMassQ = waterFeedQ;
            waterMassT = waterFeedT;
        end
    end
    
    % Calculate total flow and total mass
    [dFVal,dFQual,dFTime] = derivedMultiply(waterMass,waterMassQ,waterMassT,K4);
    [dFVal,dFQual,dFTime] = derivedDivide(dFVal,dFQual,dFTime,waterSG);
    [dFVal,dFQual,dFTime] = derivedAdd(dFVal,dFQual,dFTime,solidsMass,...
        solidsMassQ,solidsMassT);
    [dFVal,dFQual,dFTime] = derivedDivide(dFVal,dFQual,dFTime,K4);
    [totalMass,totalMassQ,totalMassT] = derivedAdd(solidsMass,solidsMassQ,...
        solidsMassT,waterMass,waterMassQ,waterMassT);
    
    %% Calculate combined density
    zeroInd = [];
    if min(round(dFVal)) == 0
        zeroInd = find(round(dFVal) == 0);
        zeroData = dFVal(zeroInd);
        dFVal(zeroInd) = 1;
    end
    
    [dDVal, dDQual, dDTime] = derivedDivide(totalMass,totalMassQ,...
        totalMassT,dFVal,dFQual,dFTime);
    
    if min(size(zeroInd)) > 0
        dDVal(zeroInd) = 0;
        dFVal(zeroInd) = zeroData;
    end
    
    log.logInfo('[%d, %d]', [dDVal, dDQual]);
    outputs.DerivedSensor = dDVal;
    outputs.DerivedSensorQuality = dDQual;
    outputs.Timestamp = dDTime;
    
    catch err
        outputs.DerivedSensor = [];
        outputs.DerivedSensorQuality = [];
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