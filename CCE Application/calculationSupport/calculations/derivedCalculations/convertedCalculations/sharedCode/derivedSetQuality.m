function dQ = derivedSetQuality(Q1, Q2)
%DERIVEDSETQUALITY Compute quality for derived sensors
%   dQ = derivedSetQuality(Q1, Q2) sets the derived quality from the two
%   sourcequalities as follows:
%   1. If Q1 and Q2 are MD, dQ is MD
%   2. If either Q is MD, dQ is other Q
%   3. dQ is lowest of Q values.
goodQualityVal = DataQuality.Good;
notValidatedQualityVal = DataQuality.NotValidated;

dQ = [Q1 Q2];
if ~isempty(dQ)
    dQ((dQ(:,1) == goodQualityVal),1) = notValidatedQualityVal;
    dQ((dQ(:,2) == goodQualityVal),2) = notValidatedQualityVal;
    dQ = min(dQ,[],2);
    dQ((dQ == notValidatedQualityVal),:) = goodQualityVal;
end