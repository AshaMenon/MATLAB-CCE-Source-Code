classdef AFCalculationTrigger < handle
    %AFCALCULATIONTRIGGER
    
    properties (Constant, Access = 'private')
        TriggerCategoryName = "CCETrigger";
    end
    properties (Access = 'private')
        DataConnector (1,1);
        TriggerReference;
    end
    properties (SetAccess = 'private')
        TriggerName string;
    end
    
    methods
        function obj = AFCalculationTrigger(record, dataConnector)
            %AFCALCULATIONTRIGGER
            
            if nargin > 0
                triggerCategoryName = obj.TriggerCategoryName;
                [triggerFields, name] = dataConnector.getRecordFieldsByCategory(record, triggerCategoryName);
                for k = numel(triggerFields):-1:1
                    obj(k) = cce.AFCalculationTrigger();
                    obj(k).DataConnector = dataConnector;
                    obj(k).TriggerReference = triggerFields{k};
                    obj(k).TriggerName = name{k};
                end
            end
        end
        
        function calcID = signupForUpdateEvents(obj, dataPipe, calcID)
            
            attributes = {obj.TriggerReference};
            id = repmat(calcID, size(attributes));
            dataPipe.addSignups(attributes, id);
        end
        
        function removeFromUpdateEvents(obj, dataPipe, calcID)
            
            id = repmat(calcID, size(obj));
            dataPipe.removeSignUps(id);
        end
        
        function eventTimeStamps = retrieveEventTimeStamps(obj, startTime, endTime)
            
            %TODO: Chunk into hourly chunks
            timeStampRange = startTime:hours(1):endTime;
            if timeStampRange(end) ~= endTime
                timeStampRange(end+1) = endTime;
            end
            timeStampRange = string(timeStampRange', 'dd-MM-yyyy HH:mm:ss');
            timestamps = [];
            for tr = 1:numel(timeStampRange) - 1
                chunkRange = timeStampRange(tr:tr + 1, :);
                dataConnector = obj(1).DataConnector;
                for k = numel(obj):-1:1
                    
                    [~, eventTimestamps, ~] = dataConnector.readFieldRecordedHistory(...
                        obj(k).TriggerReference, chunkRange, ...
                        'BoundaryType', 'Inside');
                    timestamps = [timestamps, eventTimestamps]; %#ok<AGROW>
                end
                eventTimeStamps = unique(timestamps);
            end
        end
    end
end

