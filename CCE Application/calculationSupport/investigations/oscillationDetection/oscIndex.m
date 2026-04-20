% oscIndex: detect PV oscillations around SP
% [ind,oscillation] = oscIndex(raw,t_sample,fs,a,t_n,t_i,Rmax);
% Input:
%       raw = n x 2 double array containing [PV SP] data matrix
%       t_sample = data sampling interval [seconds] (normally 10)
%       fs = filter size [ seconds] (normally 60)
%       a = suitable acceptable oscillation amplitude [%]
%       t_n = noise filter time constant [seconds] (normally 3)
%       t_i = controller integral time [seconds]
%       Rmax = threshold for reversals detected (normally 10)
% Return:
%       ind.osc = oscillation index
%       ind.iae = integrated absolute error
%       oscillation.num = number of reversal oscillations detected
%       oscillation.ind = indices of detected oscillations
%
%   Modified and updated by D. Groenewald March 2004
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ind,oscillation] = oscIndex(raw,t_sample,fs,a,t_n,t_i,Rmax)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Initialise parameters
ind.osc = zeros(size(raw,1),1);
ind.iae = zeros(size(raw,1),1);

% Do oscillation detection
t_sup = floor(5*Rmax*t_i/t_sample); % supervision time during which at least Rmax reversals / load disturbances have to be detected in order to conclude that oscillation is present
gamma = 1-t_sample/t_sup;
if gamma < 0, gamma = 0; end
iae_lim = 2*a/(2*pi/t_i);           % limit set on IAE to be classified as a load disturbance
fs = ceil(fs/t_sample);             % Set filtfilt filter size and adjust for sampling interval
e = raw(:,2) - raw(:,1);            % error
if (fs/t_n >= 1) && size(e,1)>1
%     e_filt =  filtfilt(ones(max([round(fs/t_n) 2]),1)/max([round(fs/t_n) 2]),1,e);
    B = ones(max([round(fs/t_n) 2]),1);
    window = max([round(fs/t_n) 2]);
    if size(e,1) < 3*size(B,2)+1
        e(end+1:3*size(B,2)+1) = e(end).*ones(3*size(B,2)+1-refSize,1);
    end
    e_filt = filtfilt(B/(window),1,e);
else
    e_filt =  e;
end
e_old_filt = [0; e_filt(1:end-1)];
ind.iae = 0;
load = 0;
oscillation.ind(1,1) = 0;
for j = 2:size(raw,1)
    if ((e_filt(j) > 0) && (e_old_filt(j) > 0)) || ((e_filt(j) < 0) && (e_old_filt(j) < 0))
        ind.iae(j) = ind.iae(j-1) + abs(e_filt(j))*t_sample;
        load(j) = 0;
    else
        if ind.iae(j-1) > iae_lim
            load(j) = 1;
        else
            load(j) = 0;
        end
        ind.iae(j) = abs(e_filt(j))*t_sample;
    end
    ind.osc(j) = ind.osc(j-1) - (Rmax-(gamma^180)*Rmax)/180 + load(j);
    if ind.osc(j) < 0
        ind.osc(j) = 0;
    end  
    % Control loop oscillating if ind.osc exceeds Rmax
    if ind.osc(j) > Rmax
        oscillation.ind(j,1) = 1;
        ind.osc(j) = 0;
    else
        oscillation.ind(j,1) = 0;
    end
end
oscillation.num = sum(oscillation.ind);
% else
%     ind.osc = [];
%     ind.iae = [];
%     oscillation.num = 0;
%     oscillation.ind = [];
% end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%