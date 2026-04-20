function [exportTimeCode,exportTimeRange,exportTimeLabels] = getExportTimeDetails(entity)
% GETEXPORTDETAILS create the necessary export tag and plant values
%   exportDetails = getExportDetails(sensor,varargin) creates a structure EXPORTDETAILS with
%   fields EXPORTTAGVALUE and PLANTNAME for the export tag and plant values respectively. The
%   SENSOR export tag value and plant (either as a sensor object or structure)

%   TimeCodes:
%       Generic:              OPM description
%       Hourly:               Hourly – 1 hr
%       Shiftly:              Shiftly – 8/12 hr
%       Daily:                Daily – 24 hr
%       Weekly:               Weekly – 7 days
%       Monthly:              Monthly – 28-31 days
%       Yearly:               Yearly – 365 days
% if numel(timeCode) > 2 && ~isempty(timeCode) &&...
%         any(strcmp(timeCode,{'Hourly','Shiftly','Daily','Weekly','Monthly','Yearly'}))
%     validateattributes(timeCode,{'char'},{'nonempty'})
% elseif ~isempty(timeCode) &&...
%         ~any(strcmp(timeCode,{'Hourly','Shiftly','Daily','Weekly','Monthly','Yearly'}))
%     error('');
% else
%     timeCode = [];
% end

% Define time codes in terms of seconds
% timeCodesValues = [1*60*60,8*60*60,12*60*60,24*60*60,7*24*60*60,28*24*60*60,29*24*60*60,...
%     30*24*60*60,31*24*60*60,364*24*60*60];
% timeCodesValues = [3600,28800,43200,86400,604800,2419200,2505600,2592000,2678400,31449600];
timeCodesValues = [3600,28800,43200,86400,604800,2419200,2505600,2592000,2678400,31449600];
timeCodesDescription = {'Hourly','Shiftly','Shiftly','Daily','Weekly','Monthly',...
    'Monthly','Monthly','Monthly','Yearly'};

if isa(entity,'ap.SensorData')
    % Determine the time code
    
    % Getting tag names from sensor data objects
    periodLabels = [];
    exportTimeRange = cell(1,numel(entity));
    exportTimeCode = cell(1,numel(entity));
    for thisSensorData = 1:numel(entity)
        % Determine the time code        
        diffTime = arrayfun(@(x)abs(x - (etime(datevec(entity(thisSensorData).TimeRange(2)),...
            datevec(entity(thisSensorData).TimeRange(1))))),timeCodesValues);
        [~,diffTimeIndx] = min(diffTime);
        exportTimeCode{thisSensorData}  = timeCodesDescription{diffTimeIndx};
        
        exportTimeRange{thisSensorData} = entity(thisSensorData).TimeRange;
        periodLabels = [periodLabels,{entity(thisSensorData).Label}]; %#ok<AGROW>
    end
    exportTimeLabels = periodLabels;
elseif isa(entity,'struct')    
    numTimeSpans = numel(entity.Data);
    exportTimeCode =  cell(1,numTimeSpans);
    exportTimeRange = cell(1,numTimeSpans);
    exportTimeLabels =  cell(1,numTimeSpans);
    
    for thisTimeSpan = 1:numTimeSpans
        diffTime = arrayfun(@(x)abs(x -...
            (etime(datevec(entity.Data(thisTimeSpan).TimeRange(2)),...
            datevec(entity.Data(thisTimeSpan).TimeRange(1))))),timeCodesValues);
        [~,diffTimeIndx] = min(diffTime);
        exportTimeCode{thisTimeSpan}  = timeCodesDescription{diffTimeIndx};
        exportTimeRange{thisTimeSpan} = entity.Data(thisTimeSpan).TimeRange;
        exportTimeLabels{thisTimeSpan} = entity.Data(thisTimeSpan).Label;
    end
end

