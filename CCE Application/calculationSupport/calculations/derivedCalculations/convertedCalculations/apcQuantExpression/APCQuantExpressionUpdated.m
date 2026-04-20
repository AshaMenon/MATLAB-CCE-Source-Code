function [dVal, dQual, dTime] = APCQuantExpression(varargin)
    %APCQUANTEXPRESSION Evaluate expression
    %   [dVal, dQual, dTime] = APCQuantExpression(varargin) computes
    %   dVal based on specified expression.
    %
    %   Expected inputs: class, id, value, quality, timeStamp, active, condition, eu
    %
    % The output instrument’s unit is used as the expected units as well as the resulting unit.
    %
    % G2 calculation as obtained from ACM db
    
    %% Read inputs
    % Parse inputs
    [derivedSensorClass,derivedSensorEU,derivedSensorSG,numInputs,id,value,quality,timeStamp,...
        active,condition,eu,sg,constants,leadingConstants,ignoreInd] = parseInputs(varargin,false,'');
    
    % Call algorithm
    [dVal, dQual, dTime] = apcQuantExpressionAlgorithm(derivedSensorClass,...
        derivedSensorEU,derivedSensorSG,numInputs,id,value,quality,timeStamp,...
        active,condition,eu,sg,constants,leadingConstants,ignoreInd,varargin);
end