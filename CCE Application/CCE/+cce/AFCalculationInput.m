classdef AFCalculationInput < cce.ICalculationInput
    %AFCALCULATIONINPUT Concrete implementation of cce.ICalculationInput for AF database
    %storage
    
    properties (Access = 'private')
        DataConnector (1,1);
        TimeRange (2, :) string;
        SampleRate (1, 1) string;
        UseTimestamps logical;
    end
    properties (Constant, Access = 'private')
        InputCategoryName = "CCEInput";
    end
    
    methods
        function obj = AFCalculationInput(record, dataConnector)
            %AFCALCULATIONINPUT retrieves each Parent Input Attribute categorised as
            %OBJ.INPUTCATEGORYNAME, stores the Input Attribute reference and the Input
            %name from the Parent Attribute, and reads and stores the Relative Time Range
            %(Time Range and Sample Rate) and the data richness definition from the
            %Children Attributes.
            %
            % Inputs:
            %   RECORD          -	(OSIsoft.AF.Asset.AFElement) CCE Calculation Element
            %   DATACONNECTOR   -   (af.AFDataConnector) Data Connector connected to the
            %                       Calculation AF Database
            
            if nargin > 0
                inputCategoryName = obj.InputCategoryName;
                [inputFields, name] = dataConnector.getRecordFieldsByCategory(record, inputCategoryName);
                for k = numel(inputFields):-1:1
                    obj(k) = cce.AFCalculationInput();
                    obj(k).DataConnector = dataConnector;
                    obj(k).InputReference = inputFields{k};
                    if isempty(inputFields{k}.Parent)
                        inputName = name{k};
                        obj(k).getHistoryDefinition(inputFields{k});
                        obj(k).getDataRichnessConfiguration(inputFields{k});
                    else
                        parentField = inputFields{k}.Parent;
                        inputName = join([string(parentField.Name), name{k}], '');
                        obj(k).getHistoryDefinition(parentField);
                        obj(k).UseTimestamps = false;
                    end
                    
                    obj(k).InputName = inputName;
                end
            end
        end
        
        function [data] = retrieveInputData(obj, baseTime)
            %retrieveInputData  Fetch historical data from database, referencing a base time
            %   Data = retrieveInputData(CIObj, BaseTime) retrieves the data from each
            %       cce.AFCalculationInput object in CIObj 
            %       based on the retrieval specifications set in each input's attributes. Data is a
            %       structure array containing fieldnames corresponding to the Input object CIObj
            %       Name, and includes the field NameTimestamps if that object's UseTimestamps
            %       property is true.

            arguments
                obj cce.AFCalculationInput
                baseTime (1,1) datetime;
            end
            
            data = struct();
            for k = 1:numel(obj)
                [value, timestamp, ~] = fetchHistory(obj(k), baseTime);
                data.(obj(k).InputName) = value;
                if obj(k).UseTimestamps
                    tsVarName = obj(k).InputName + "Timestamps";
                    data.(tsVarName) = timestamp;
                end
            end
        end
        
        function [inputsReady] = isReady(obj, calculationID, outputTime)
            %ISREADY returns true/ false depending on whether the
            %calculation that this calculation depends on has successfully ran
            
            arguments
                obj cce.AFCalculationInput
                calculationID
                outputTime (1,1) datetime;
            end
            
            dependeeCalcIDs = readDependentCalcs(calculationID);
            uniqueDependeeCalcIDs = unique(dependeeCalcIDs);

            uniqueDependeeCalcIDs = string(uniqueDependeeCalcIDs);

            dependentCalcs = arrayfun(@(x) af.Element.findByUniqueID(x, "Connector", obj(1).DataConnector), ...
                uniqueDependeeCalcIDs); 
            
            dependentCalcLastCalcTime = dependentCalcs.getAttributeValue("LastCalculationTime"); 

            inputsReady = all(dependentCalcLastCalcTime >= outputTime);
            
        end
        
        function [piPointPaths] = getInputPiPointPaths(obj)
            %GETINPUTPIPOINTPATHS returns the input attribute's resolved PIPoint path, if
            %the input
            inputCount = numel(obj);
            piPointPaths = strings(1, inputCount);
            for k = inputCount:-1:1
                if any(ismember(obj(k).TimeRange, "*"))
                    piPoints = cce.getAttributePiPointReference(obj(k).InputReference);
                    if ~isempty(piPoints)
                        piPointPaths(k) = string(piPoints.GetPath);
                    end
                end
            end
        end
        
        function [value, timestamp, quality] = fetchHistory(obj, baseTime)
            %FETCHHISTORY fetch the VALUES, TIMESTAMPS, and value QUALITIES of the input data attribute 
            %   [value, timestamp, quality] = fetchHistory(obj, baseTime) retrieves the value,
            %       timestamp and quality of the input obj, based on the RelativeTimeRange string,
            %       relative to the BASETIME.
            %
            %   If a start time, end time, and sample rate are defined in the RelativeTimeRange
            %   child attribute an interpolated history is retrieved. If a start time and end time
            %   are defined, compressed values are retrieved. If only an end time is defined, the
            %   last value is returned.
            %
            %   This function translates BOD(*) as "the start of the base time" and "*" as the base
            %   time.
            
            arguments
                obj (1,1) cce.AFCalculationInput
                baseTime (1,1) datetime;
            end
            
            timeRange = replace(obj.TimeRange, " ","");
            % Convert "BOD(*)" to midnight of baseTime, to support absolute data retrieval times
            baseDate = string(baseTime, 'dd-MMM-yyyy');
            timeRange = replace(timeRange, "BOD(*)", baseDate);
            % Convert current time "*" to baseTime.
            baseTime = string(baseTime, 'dd-MMM-yyyy HH:mm:ss');
            timeRange = replace(timeRange, "*", baseTime);
            if ~ismember(timeRange, "")
                if strlength(obj.SampleRate) > 0 % Interpolated
                    sampleRate = obj.SampleRate;
                    [value, timestamp, quality] = obj.DataConnector.readFieldInterpolatedHistory( ...
                        obj.InputReference, timeRange, sampleRate);
                else
                    [value, timestamp, quality] = obj.DataConnector.readFieldRecordedHistory( ...
                        obj.InputReference, timeRange);
                end
            else
                [value, timestamp, quality] = obj.DataConnector.readFieldLastHistoryValue( ...
                    obj.InputReference, timeRange(1)); 
                %FIXME: This uses the 'AtOrBefore' retrieval type (at or before the input
                %timestamp) which could be a potential problem if we are not checking the
                %timestamps.
            end
            value = value(:);
            timestamp = timestamp(:);
            quality = quality(:);
        end
        
        function valid = verifyTimeRangeConfiguration(obj)
            
            valid = false;
            baseTime = string(datetime('now'), 'dd-MMM-yyyy HH:mm:ss');
            baseDate = string(datetime('now'), 'dd-MMM-yyyy');
            for c = 1:numel(obj)
                timeRange = replace(obj(c).TimeRange," ","");
                timeRange = replace(timeRange, "BOD(*)", baseDate); % Convert BOD(*) to midnight
                timeRange = replace(timeRange, "*", baseTime); % Convert * to baseTime
                try
                    OSIsoft.AF.Time.AFTimeRange(timeRange(1, :), timeRange(2, :));
                    valid = true;
                    % Might be retrieving compressed (raw) values, so SampleRate might be empty
                    if all(strlength(timeRange) > 0) && (strlength(obj(c).SampleRate) > 0)
                        try
                            ts = obj(1).DataConnector.parseTimeSpan(obj(c).SampleRate);
                            if ts.Ticks == 0
                                valid = false;
                            else
                                valid = true;
                            end
                        catch
                            valid = false;
                        end
                    end
                catch
                    valid = false;
                end
            end
        end
    end
    
    methods (Access = 'private')
        function getHistoryDefinition(obj, parentField)
            %GETHISTORYDEFINITION read the history definition from the "RelativeTimeRange"
            %child attribute of the PARENTFIELD attribute
            
            arguments
                obj (1,1) cce.AFCalculationInput;
                parentField (1,1) OSIsoft.AF.Asset.AFAttribute;
            end

            % Wrap this in a try..catch. If the requests fail, set to *
            try
                [historyDefAttribute] = obj.DataConnector.getFieldByName(parentField, "RelativeTimeRange");
                obj.HistoryDefinition = obj.DataConnector.readField(historyDefAttribute);
            catch 
                obj.HistoryDefinition = "*";
            end
            timeParts = string(strip(split(obj.HistoryDefinition, ',')));
            obj.TimeRange = strings(2, 1);
            obj.TimeRange(1, :) = timeParts(1);
            if numel(timeParts) > 1
                obj.TimeRange(2, :) = timeParts(2);
                if numel(timeParts) > 2
                    obj.SampleRate = timeParts(3);
                else
                    obj.SampleRate = "";
                end
            end

        end
        
        function getDataRichnessConfiguration(obj, parentField)
            %GETDATARICHNESSCONFIGURATION
            try
                useTimestampsField = obj.DataConnector.getFieldByName(parentField, "UseTimestamps");
                obj.UseTimestamps = obj.DataConnector.readField(useTimestampsField);
            catch % No matter why this fails, set UseTImestamps to False
                obj.UseTimestamps = false;
            end
        end
    end
end

