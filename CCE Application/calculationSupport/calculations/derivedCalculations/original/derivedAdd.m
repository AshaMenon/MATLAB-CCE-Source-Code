function [dVal, dQual, dTime] = derivedAdd(V1, Q1, T1, V2, Q2, T2, V3, Q3, T3, V4, Q4, T4, V5, Q5, T5, V6, Q6, T6, V7, Q7, T7, V8, Q8, T8, V9, Q9, T9, V10, Q10, T10, V11, Q11, T11, V12, Q12, T12, V13, Q13, T13, V14, Q14, T14, V15, Q15, T15, V16, Q16, T16, V17, Q17, T17, V18, Q18, T18, V19, Q19, T19, V20, Q20, T20)
%DERIVEDADD Compute derived addition with quality
%   [dVal, dQual] = DERIVEDADD(V1, Q1, T1, V2, Q2, T2, ...) computes V1 + V2, taking
%   into account associated sensor quality values in Q1 and Q2.
%
%   The algorithm for computing quality is as follows:
%   1. If (quality1 or quality2) is missing data -> Results is missing data; Result Quality is 1
%   2. If (Quality1=NotRunning) And (Quality2=Running) -> Use Value 2; Result Quality2
%   3. If (Quality2=NotRunning) And (Quality1=Running) -> Use Value1; Result Quality1
%   4. If (Quality1 = NotRunning) And (Quality2=NotRunning) -> Value=0; Result Quality = Not Running
%   else perform addition and use normal quality rules.

% Copyright 2013 Anglo American Platinum
% $Revision: 1.2 $ $Date: 2012/10/02 11:02:18 $
% from ETL code supplied by AngloPlat

% Arg Checking
% error(nargchk(4,Inf,nargin))
narginchk(4,Inf);

% Handle multiple input signals & constants
isConstant = 0;
value = [];
quality = [];
constant = [];
for i = 1:ceil(nargin/3)
    eval(['isConstant = ~exist(' '''Q' num2str(i) '''' ');']);
    if isConstant == 1
        eval(['constant = V' num2str(i) ';']);
    else
        eval(['value(:,' num2str(i) ') = V' num2str(i) ';']);
        eval(['quality(:,' num2str(i) ') = Q' num2str(i) ';']);
        eval(['timeStamps(:,' num2str(i) ') = T' num2str(i) ';']);
    end
end

% We can assume that the data is the same length here?
% goodQualityVal = ap.DataQuality.opmqualityval('good'); % Identify the missing values
% missingQualityVal = ap.DataQuality.opmqualityval('missing data'); % Identify the missing values
% notRunningQualityVal = ap.DataQuality.opmqualityval('not running'); % Identify the not running values
goodQualityVal = 0;
missingQualityVal = 1;
notRunningQualityVal = 2;
dVal = nan(size(V1));
dQual = goodQualityVal*ones(size(V1));
dTime = T1;
for i = 1:ceil(nargin/3)-1
    % Assign data
    if (i == 1) && (size(value,2) > 1)
        V1 = value(:,1); Q1 = quality(:,1); T1 = timeStamps(:,1);
        V2 = value(:,2); Q2 = quality(:,2); T2 = timeStamps(:,2);
    elseif (i == 1) && (size(value,2) == 1)
        V1 = value(:,1); Q1 = quality(:,1); T1 = timeStamps(:,1);
        V2 = constant*ones(size(value,1),1); Q2 = goodQualityVal*ones(size(value,1),1); T2 = zeros(size(value,1),1);
    elseif i > 1
        V1 = dVal;
        Q1 = dQual;
        T1 = dTime;
        if (max(size(constant)) > 0) && (i == ceil(nargin/3)-1)
            V2 = constant*ones(size(value,1),1); Q2 = goodQualityVal*ones(size(value,1),1); T2 = zeros(size(value,1),1);
        else
            V2 = value(:,i+1); Q2 = quality(:,i+1); T2 = timeStamps(:,i+1);
        end
    end

    % Set all not running data to 0
    V1(Q1 == notRunningQualityVal) = 0;
    V2(Q2 == notRunningQualityVal) = 0;
    
    isMissingData = (Q1 == missingQualityVal) | (Q2 == missingQualityVal);
    isV1NotRunning = (Q1 == notRunningQualityVal) & (Q2 ~= notRunningQualityVal);
    isV2NotRunning = (Q2 == notRunningQualityVal) & (Q1 ~= notRunningQualityVal);
    isBothNotRunning = isV1NotRunning & isV2NotRunning;

    mustCalc = ~ (isMissingData | isV1NotRunning | isV2NotRunning | isBothNotRunning);

    %   1. If (quality1 or quality2) is missing data -> Results is missing data; Result Quality is 1
    dVal(isMissingData) = NaN;    % TODO: How do we get missing data value?
    dQual(isMissingData) = missingQualityVal;

    %   2. If (Quality1=NotRunning) And (Quality2=Running) -> Use Value 2; Result Quality2
    dVal(isV1NotRunning) = V2(isV1NotRunning);
    dQual(isV1NotRunning) = Q2(isV1NotRunning);

    %   3. If (Quality2=NotRunning) And (Quality1=Running) -> Use Value1; Result Quality1
    dVal(isV2NotRunning) = V1(isV2NotRunning);
    dQual(isV2NotRunning) = Q1(isV2NotRunning);

    %   4. If (Quality1 = NotRunning) And (Quality2=NotRunning) -> Value=0; Result Quality = Not Running
    dVal(isBothNotRunning) = 0;
    dQual(isBothNotRunning) = notRunningQualityVal;

    if (isConstant == 1) && (i == ceil(nargin/3)-1)
        dVal(mustCalc) = V1(mustCalc) + constant;
        dQual = Q1;
    else
        % Normal calcs
        dVal(mustCalc) = V1(mustCalc) + V2(mustCalc);
        dQual(mustCalc) = derivedSetQuality(Q1(mustCalc), Q2(mustCalc));
    %dQual(mustCalc) = 1;
    end
end