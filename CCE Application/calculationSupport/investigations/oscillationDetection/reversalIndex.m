% reversalIndex: detect PV reversal oscillations
% [rrInd,oscillation] = reversalIndex(raw,tSample,fs,rrWsize,unsteadyInd,pvThreshold,tIntegral,Rmax,application)
% Input:
%       raw = n x 1 double array containing PV data matrix
%       tSample = data sampling interval [seconds] (normally 10)
%       fs = filter size [ seconds] (normally 60)
%       rrWsize = reversal index windows size [seconds] (normally 150)
%       unsteadyInd = n x 1 index indicating 1's where process unsteady
%       pvThreshold = threshold of PV variance
%       tIntegral = controller integral time [seconds]
%       Rmax = threshold for reversals detected (normally 10)
%       varargin
%           'mode' = 'online'
% Return:
%       rrCount = number of reversals detected
%       rrInd = reversal index
%       oscCount = number of reversal oscillations detected
%       oscInd = indices of detected oscillations
%       pvFilt = filtered value of raw data
%
%   Modified and updated by D. Groenewald March 2004
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [rrInd,rrCount,oscInd,oscCount,pvFilt] = reversalIndex(raw,tSample,fs,rrWsize,unsteadyInd,pvThreshold,tIntegral,Rmax,varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

mode = [];
for i = 1:size(varargin,2)
   if strcmpi(varargin{i},'mode')
       mode = varargin{i+1};
   end
end
if isempty(unsteadyInd)
    unsteadyInd = ones(size(raw));
end

% Determine reversal where process unsteady and pv variance exceeding threshold
fs = fs/tSample;           % Set filtfilt filter size and adjust for sampling interval
supervisoryWindowSize = floor(5*Rmax*tIntegral/tSample);
% pvFilt = filtfilt(ones((fs),1)/(fs),1,raw);
pvFilt = movmean(raw,[fs-1 0]); % pvFilt = filter(1/fs*ones(fs,1),1,raw);
var_pv = ((pvFilt-raw).^2);
% var_pvFilt = filtfilt(ones((fs),1)/(fs),1,var_pv);
var_pvFilt = movmean(var_pv,[fs-1 0]); % var_pvFilt = filter(1/fs*ones(fs,1),1,var_pv);
if strcmpi(mode,'online')
    % For ONLINE application reduce data sizes to supervisoryWindowSize + executionRate
    raw = raw(end-supervisoryWindowSize+1:end);
    unsteadyInd = unsteadyInd(end-supervisoryWindowSize+1:end);
    pvFilt = pvFilt(end-supervisoryWindowSize+1:end);
    var_pvFilt = var_pvFilt(end-supervisoryWindowSize+1:end);
end
tmp = find(unsteadyInd==1);
% tmp1 = find((pvFilt((rrWsize/tSample):end) - pvFilt((rrWsize/tSample)-1:end-1)).*(pvFilt((rrWsize/tSample)-1:end-1) - pvFilt((rrWsize/tSample)-2:end-2)) < 0);
tmp1 = find((pvFilt((rrWsize/tSample)+1:end) - pvFilt(2:end-(rrWsize/tSample)+1)).*(pvFilt((rrWsize/tSample):end-1) - pvFilt(1:end-(rrWsize/tSample))) < 0);
tmp1 = tmp1 + (rrWsize/tSample) - 2;  % adjust for window size
tmp2 = find((var_pvFilt > pvThreshold));
rrInd = zeros(size(raw,1),1);
rrInd(intersect(intersect(tmp,tmp1),tmp2)) = 1;
oscInd = zeros(size(raw));
% Check if each reversal is part of an oscillation
rrIndex = find(rrInd==1);
% rrIndex(rrIndex<supervisoryWindowSize) = [];
for j = 1:length(rrIndex)
    if nansum(rrInd(nanmax([1 rrIndex(j)-supervisoryWindowSize+1]):rrIndex(j))) >= Rmax
        oscInd(rrIndex(j)) = 1;
    end
end

% Process results
rrCount = nansum(rrInd);
oscCount = nansum(oscInd);

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%