classdef AFCalculationOutput < cce.ICalculationOutput
    %AFCALCULATIONOUTPUT
    
    properties (Access = 'private')
        DataConnector (1,1) %af.AFDataConnector;
    end
    properties (Constant, Access = 'private')
        OutputCategoryName = "CCEOutput";
    end
    
    methods
        function obj = AFCalculationOutput(record, dataConnector)
            %AFCALCULATIONOUTPUT Retrieve Output AFAttributes from AF Element
            %   obj = AFCalculationOutput(record, dataConnector) retrieves and stores the references to the Calculation
            %       Output AFAttributes for the CCE Calculation Element, RECORD.
            %
            %   Only Attributes in the defined Category and with a PI Point Data Reference (or
            %   Formula reference that resolves to a PI Point) are returned. Attributes that do not
            %   resolve to PI Points are silently ignored.
            
            if nargin > 0
                [outputs, name] = dataConnector.getRecordFieldsByCategory(record, obj.OutputCategoryName);
                % Check that each output resolves to a PI Point
                isPiPoint = false(size(outputs));
                for k=1:numel(outputs)
                    piPoint = cce.getAttributePiPointReference(outputs{k});
                    isPiPoint(k) = ~isempty(piPoint);
                end
                outputs = outputs(isPiPoint);
                name = name(isPiPoint);

                for k = numel(outputs):-1:1
                    obj(k) = cce.AFCalculationOutput();
                    obj(k).DataConnector = dataConnector;
                    obj(k).OutputReference = outputs{k};
                    
                    if isempty(outputs{k}.Parent)
                        outputName = name{k};
                    else
                        outputName  = join([string(outputs{k}.Parent.Name), name{k}], '');
                    end
                    obj(k).OutputName = outputName;
                end
            end
        end
        
        function writeOutputData(obj, data, opts)
            %WRITEOUTPUTDATA write the CCE AF Calculation output DATA to the PI Historian.
            % The data in field of DATA is written to the output AFAttribute of the same
            % name. WRITEOUTPUTDATA searches for the cce.AFCalculationOutput object in the
            % OBJ array with the OBJ.OUTPUTNAME corresponding to the DATA field name, and
            % writes the field's data to that AFAttribute (through the
            % OBJ.OUTPUTREFERENCE).
            % The value (data from the field), timestamp (from the DATA.TIMESTAMP output)
            % and the quality (default "good") is written and captured by the PI Historian
            % for each output.
            %
            % Inputs:
            %   DATA - (struct) Struct containing fields whose name matches the CCE AF
            %   Calculation's Output names.
            %   OPTS.WRITENANAS - Optional input, cce.WriteNanAsValue("NaN") by defualt,
            %   what to replace ouputted NaNs with.
            
            arguments
                obj (1, :) cce.AFCalculationOutput;
                data struct
                opts.WriteNanAs (1, 1) cce.WriteNanAsValue = cce.WriteNanAsValue("NaN");
            end
            
            timestamp = data.Timestamp;
            for k = numel(obj):-1:1
                outputName = obj(k).OutputName;
                
                value = data.(outputName);
                
                quality = repmat("Good", size(value)); %TODO: read quality from calculation outputs
                % May actually get a mismatch in number of timestamps vs values, so assume the
                % values are for the first N timestamps.
                if numel(timestamp) > numel(value)
                    timestampToWrite = timestamp(1:numel(value)); % ASSUME Early values
                else
                    timestampToWrite = timestamp;
                end
                
                % Guard against writing data in the future
                isInFuture = (timestampToWrite > datetime('now'));
                timestampToWrite = timestampToWrite(~isInFuture);
                valueToWrite = value(~isInFuture);
                qualityToWrite = quality(~isInFuture);
                obj(k).writeHistory(valueToWrite, timestampToWrite, qualityToWrite, 'WriteNanAs', opts.WriteNanAs);
            end
        end
        
        function [piPointPaths] = getOutputPiPointPaths(obj)
            
            outputCount = numel(obj);
            piPointPaths = strings(1, outputCount);
            for k = outputCount:-1:1
                piPoints = cce.getAttributePiPointReference(obj(k).OutputReference);
                    if ~isempty(piPoints)
                        piPointPaths(k) = string(piPoints.GetPath);
                    end
            end
        end
        
        function writeHistory(obj, value, timestamp, quality, opts)
            %WRITEHISTORY write CCE AF Calculation output VALUE, TIMESTAMP and QUALITY to the
            %AFAttribute (OBJ.OUTPUTREFERENCE) on the AF database.
            %
            % Inputs:
            %   VALUE       -   output data to be written to the CCE Calculation output
            %                   attribute referenced in OBJ.
            %   TIMESTAMP   -   (datetime) timestamps for each point in VALUE.
            %   QUALITY     -   (string) string array of the data quality for each point
            %                   in VALUE. The string value in QUALITY must correspond to
            %                   the string value of one of the value statuses in the
            %                   AFValueStatus enumeration.
            %   OPTS.WRITENANAS - Optional input, cce.WriteNanAsValue("NaN") by defualt,
            %   what to replace ouputted NaNs with.
            %
            % See: https://docs.osisoft.com/bundle/af-sdk/page/html/T_OSIsoft_AF_Asset_AFValueStatus.htm
            
            arguments
                obj (1,1) cce.AFCalculationOutput;
                value
                timestamp datetime;
                quality string {mustBeMember(quality, ...
                    {'Bad', 'Questionable', 'Good', 'QualityMask', 'SubstatusMask', 'BadSubstituteValue', ...
                    'UncertainSubstituteValue', 'Substituted', 'Constant', 'Annotated'})};
                opts.WriteNanAs cce.WriteNanAsValue = cce.WriteNanAsValue("NaN");
            end
            
            if ~cce.System.TestMode
                obj.DataConnector.writeFieldHistory(obj.OutputReference, value, timestamp, quality, 'WriteNanAs', opts.WriteNanAs);
            end
        end
        
        function removeHistory(obj, startTime, endTime)
            %REMOVEHISTORY deletes the recorded history for the output tag within
            %(inclusive) a given time range
            
            timeRange = [startTime; endTime];
            for k = 1:numel(obj)
                obj(k).DataConnector.removeFieldRecordedHistory(obj(k).OutputReference, timeRange);
            end
        end
        
        function [tf] = hasDataForTimestamp(obj, outputTime)
            %HASDATAFORTIMESTAMP
            
            arguments
                obj cce.AFCalculationOutput
                outputTime (1,1) datetime;
            end
            
            outputTimeTS = string(outputTime, 'dd-MMM-yyyy HH:mm:ss');
            tf = true;
            
            for k = 1:numel(obj)
                
                % For each dependent input, check if the output has a timestamp for the
                % input TIMESTAMP. 
                % 
                % Check the timestamps of the data for this output at/ around the
                % outputTime timestamps. If any of the outputs don't have a a recorded
                % history value at the timestamp, then we will return that it does not
                % have data for that time.
                
                [~, timestamp, quality] = obj(k).DataConnector.readFieldLastHistoryValue( ...
                    obj(k).OutputReference, outputTimeTS); 
                %This uses the 'AtOrBefore' retrieval type (at or before the input
                %outputTime)
                
                %TODO: What is a realistic tolerance?
                hasData = any(outputTime - timestamp <= seconds(1));


                
                if ~hasData || ismember(quality, "Bad")
                    tf = false;
                end
            end
        end
    end
end

