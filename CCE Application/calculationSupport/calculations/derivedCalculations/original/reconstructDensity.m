function [dDVal, dDQual, dDTime] = reconstructDensity(V1, Q1, T1, V2, Q2, T2, V3, Q3, T3, V4, Q4, T4, K1, K2, K3, K4)
%RECONSTRUCTDENSITY Compute reconstructed density forwards or backwards with quality
%   [dVal, dQual] = RECONSTRUCTDENSITY(V1, Q1, T1, V2, Q2, T2, V3, Q3, T3, V4, Q4, T4, K1, K2, K3, K4) computes in mill density taking
%   into account associated sensor quality values in Q1 and Q2.
%   For backwards need to spec at least water feed, slurry density, slurry flow
%   For forwards need to spec at least solids feed, water feed
%   V1 - solids feed
%   V2 - water feed
%   V3 - slurry density
%   V4 - slurry flow
%   K1 - circulating load solids %
%   K2 - circulating moisture %
%   K3 - flag (1 - calculate from input side / 2 - calculate from discharge side)
%   K4 - solidsSG

% Copyright 2013 Anglo American Platinum
% $Revision: 1.2 $ $Date: 2012/10/02 11:02:20 $
% from ETL code supplied by AngloPlat

% Arg Checking
if nargin ~= 16
    % Map to temporary variable
    try
        tmp(1).data = V1; tmp(2).data = Q1; tmp(3).data = T1;
        tmp(4).data = V2; tmp(5).data = Q2; tmp(6).data = T2;
        tmp(7).data = V3; tmp(8).data = Q3; tmp(9).data = T3;
        tmp(10).data = V4; tmp(11).data = Q4; tmp(12).data = T4;
        tmp(13).data = K1; tmp(14).data = K2; tmp(15).data = K3; tmp(16).data = K4;
    catch
    end
    %Assign empty variables
    V1 = []; Q1 = []; T1 = []; 
    V2 = []; Q2 = []; T2 = []; 
    V3 = []; Q3 = []; T3 = []; 
    V4 = []; Q4 = []; T4 = []; 
    % Assign constants
    K4 = tmp(nargin).data;
    K3 = tmp(nargin-1).data;
    K2 = tmp(nargin-2).data;
    K1 = tmp(nargin-3).data;
    tmp(nargin-3:end) = [];
    if K3 == 1
        % Assing variables
        try
            V1 = tmp(1).data; Q1 = tmp(2).data; T1 = tmp(3).data;
            V2 = tmp(4).data; Q2 = tmp(5).data; T2 = tmp(6).data;
            V3 = tmp(7).data; Q3 = tmp(8).data; T3 = tmp(9).data;
            V4 = tmp(10).data; Q4 = tmp(11).data; T4 = tmp(12).data;
        catch
        end
    elseif K3 == 2
        % Assing variables
        try
            T4 = tmp(nargin-4).data; Q4 = tmp(nargin-5).data; V4 = tmp(nargin-6).data;
            T3 = tmp(nargin-7).data; Q3 = tmp(nargin-8).data; V3 = tmp(nargin-9).data;
            T2 = tmp(nargin-10).data; Q2 = tmp(nargin-11).data; V2 = tmp(nargin-12).data;
            T1 = tmp(nargin-13).data; Q1 = tmp(nargin-14).data; V1 = tmp(nargin-15).data;
        catch
        end
    end
end
% error(nargchk(16,16,nargin))

% Define waterSG
waterSG = 1;

%% Calculate dry solids in the streams
% If slurry flow & density specified
solidsMass = [];
waterMass = [];

if min(size(V3)) > 0 && min(size(V4)) > 0
    % solidsFractionSlurry = (slurryDensity - waterSG)./(solidsSG - waterSG);
    [solidsFractionSlurry, solidsFractionSlurryQ, solidsFractionSlurryT] = derivedSubtract(V3, Q3, T3, waterSG);
    [solidsFractionSlurry, solidsFractionSlurryQ, solidsFractionSlurryT] = derivedDivide(solidsFractionSlurry, solidsFractionSlurryQ, solidsFractionSlurryT, (K4-waterSG));
    solidsFractionSlurry(solidsFractionSlurry<0) = 0;

    % solidsMass = solidsFractionSlurry .* slurryFlow .* solidsSG;
    [solidsMass, solidsMassQ, solidsMassT] = derivedMultiply(solidsFractionSlurry, solidsFractionSlurryQ, solidsFractionSlurryT, V4, Q4, T4, K4);

    % waterMass = (1-solidsFractionSlurry) .* slurryFlow .* waterSG;
    [waterMass ,waterMassQ, waterMassT] = derivedMultiply((1-solidsFractionSlurry),solidsFractionSlurryQ,solidsFractionSlurryT,V4,Q4,T4,waterSG);
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
    [solidsFeed,solidsFeedQ,solidsFeedT] = derivedAdd(V1,Q1,T1,solidsFeed,solidsFeedQ,solidsFeedT);
elseif min(size(V1)) > 0
    solidsFeed = V1;
    solidsFeedQ = Q1;
    solidsFeedT = T1;
end

if min(size(solidsFeed)) > 0 && min(size(solidsMass)) > 0
    [solidsMass,solidsMassQ,solidsMassT] = derivedAdd(solidsMass,solidsMassQ,solidsMassT,solidsFeed,solidsFeedQ,solidsFeedT);
elseif min(size(solidsFeed)) > 0
    solidsMass = solidsFeed; 
    solidsMassQ = solidsFeedQ;
    solidsMassT = solidsFeedT;
end

if min(size(waterFeed)) > 0 && min(size(waterMass)) > 0
    if K3 == 1
        [waterMass,waterMassQ,waterMassT] = derivedAdd(waterMass,waterMassQ,waterMassT,waterFeed,waterFeedQ,waterFeedT);
    elseif K3 == 2
        [waterMass,waterMassQ,waterMassT] = derivedSubtract(waterMass,waterMassQ,waterMassT,waterFeed,waterFeedQ,waterFeedT);
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
[dFVal,dFQual,dFTime] = derivedAdd(dFVal,dFQual,dFTime,solidsMass,solidsMassQ,solidsMassT);
[dFVal,dFQual,dFTime] = derivedDivide(dFVal,dFQual,dFTime,K4);
[totalMass,totalMassQ,totalMassT] = derivedAdd(solidsMass,solidsMassQ,solidsMassT,waterMass,waterMassQ,waterMassT);

%% Calculate combined density
zeroInd = [];
if min(round(dFVal)) == 0
    zeroInd = find(round(dFVal) == 0);
    zeroData = dFVal(zeroInd);
    dFVal(zeroInd) = 1;
end

[dDVal, dDQual, dDTime] = derivedDivide(totalMass,totalMassQ,totalMassT,dFVal,dFQual,dFTime);

if min(size(zeroInd)) > 0
    dDVal(zeroInd) = 0;
    dFVal(zeroInd) = zeroData;
end