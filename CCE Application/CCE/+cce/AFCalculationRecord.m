classdef AFCalculationRecord < cce.ICalculationRecord
    %AFCALCULATIONRECORD Concrete implementation of ICalculationRecord for AF database
    %storage
    %
    %   AF Persistence of the CalculationRecord occurs through AF elements; one per Coordinator.
    %
    %   The Calculation record is internally represented as a table.
    
    properties (SetAccess = 'private')
        RecordPath (1,:) string %Read-only
        RecordName (1,:) string %Read-only
    end
    
    properties (Access = 'private')
        DataConnector (1,1);
        Attributes struct = struct(); % Reference to Record Attribute Objects
        Logger
    end
    
    properties (Access = 'private') % Internal storage of the properties
        CoordinatorID (1,1) int32 %Attribute
        CalculationID (1,1) string %Read-only
        CalculationName (1,1) string %Read-only
        ComponentName (1,1) string %Read-only
        ExecutionOffset (1,1) duration %Read-only
        ExecutionMode cce.CalculationExecutionMode %Read-only
        ExecutionFrequency (1,1) duration %Read-only
        ExecutionIndex (1,1) uint32 %Attribute
        CalculationState cce.CalculationState %PI Point
        RequestToDisable (1,1) logical %Attribute
        WriteNanAs (1, 1) %Read-only
        LastCalculationTime (1,1) datetime %PI Point
        LastError cce.CalculationErrorState %PI Point
        LogLevel (1,1) int32 %Read-only
        LogName (1,1) string %Read-only
        BackfillState (1,1) cce.CalculationBackfillState %Attribute
        BackfillProgress (1,1) double %Attribute
        BackfillLastError (1,1) cce.CalculationErrorState %Attribute
        BackfillOverwrite (1,1) cce.BackfillOverwrite %Read-only
        BackfillStartTime (1,1) datetime %Read-only
        BackfillEndTime (1,1) datetime %Read-only
        SkipBackfill (1,1) logical %Read-only
        MissedRunsThreshold (1,1) uint32 %Read-only
    end
    
    methods
        function obj = AFCalculationRecord(record, dataConnector, logger)
            %AFCALCULATIONRECORD reads the Calculation AFElement (RECORD) from the AF
            %Database, extracts the AFAttribute objects, and creates the internal
            %representation of the AFElement.
            if nargin > 0
                obj.DataConnector = dataConnector;
                obj.Logger = logger;
                
                obj.RecordPath = string(record.GetPath);
                obj.RecordName = string(record.Name);
                extractAttributes(obj, record);
                readRecord(obj);
                checkRecordHealth(obj)
            end
        end
        
        function checkRecordHealth(obj)
            %CHECKRECORDHEALTH checks the validity of the Calculation record.
            % CHECKRECORDHEALTH ensures that the Calculation record has been properly
            % configured.
            %
            % Verify that LastCalculationTime, CalculationState, and LastError are valid
            % PIPoints.
            %
            % Verify that for Cyclic ExecutionMode calculations, the ExecutionFrequency is
            % non-zero and non-NaN and that the ExecutionOffset is less than the
            % ExecutionFrequency
            
            
            % Check Execution Mode, Execution Offset, and Execution Frequency
            if ismember(obj.ExecutionMode, cce.CalculationExecutionMode.Periodic)
                %ConfigurationError: If the Calculation is Cyclic Execution and the Frequency is 0 or NaN
                if obj.ExecutionFrequency == 0 || isnan(obj.ExecutionFrequency)
                    obj.Logger.logError("%s Calculation %s, has a %s execution frequency. Execution Frequency for %s calculations must be non-zero positive seconds.", ...
                        string(obj.ExecutionMode), obj.RecordName, string(obj.ExecutionFrequency), string(obj.ExecutionMode));
                    obj.setField('CalculationState', cce.CalculationState.ConfigurationError);
                    obj.setField('LastError', cce.CalculationErrorState.ExecutionFrequencyInvalid);
                    
                    %If the Execution Offset is greater than the Frequency for a Cyclic
                    %Calculation
                elseif obj.ExecutionOffset > obj.ExecutionFrequency
                    
                    offset = mod(obj.ExecutionOffset, obj.ExecutionFrequency);
                    obj.Logger.logWarning("Calculation %s, execution frequency (%ds) greater than execution offset (%ds). Setting offset to: %ds", ...
                        obj.RecordName, seconds(obj.ExecutionFrequency), seconds(obj.ExecutionOffset), seconds(offset));
                    % Set the execution offset to the remainder of Execution Offset /
                    % Execution Frequency & push this directly to the DB
                    obj.ExecutionOffset = offset;
                    if ~cce.System.TestMode
                        obj.DataConnector.setField(obj.Attributes.ExecutionOffset, seconds(offset));
                    end
                end
            end
            
            %PI Points
            % Check that LastCalculationTime, CalculationState, and LastError are PIPoints
            isLastCalcTimePIPoint = obj.checkValidPiPoints(obj.Attributes.LastCalculationTime);
            isCalcStatePIPoint = obj.checkValidPiPoints(obj.Attributes.CalculationState);
            isLastErrorPIPoint = obj.checkValidPiPoints(obj.Attributes.LastError);
            if ~isLastCalcTimePIPoint || ~isCalcStatePIPoint || ~isLastErrorPIPoint
                
                %Set the Calculation to the ConfigurationError State
                obj.setField('CalculationState', cce.CalculationState.ConfigurationError);
                
                if ~isLastCalcTimePIPoint
                    obj.Logger.logError("Calculation %s: Last Calculation Time attributeis not configured as a valid PI Point.", ...
                        obj.RecordPath);
                    
                    obj.setField('LastError', cce.CalculationErrorState.LastCalcTimeInvalid);
                end
                if ~isCalcStatePIPoint
                    obj.Logger.logError("Calculation %s: Calculation State attribute is not configured as a valid PI Point.", ...
                        obj.RecordPath);
                    
                    obj.setField('LastError', cce.CalculationErrorState.CalculationStateInvalid);
                end
                if ~isLastErrorPIPoint
                    obj.Logger.logError("Calculation %s: Last Error attribute is not configured as a valid PI Point.", ...
                        obj.RecordPath);
                    
                    obj.setField('LastError', cce.CalculationErrorState.ConfigurationError);
                end
            end
        end
        
        function readRecord(obj)
            %READRECORD Update the internal representation for external changes.
            % READRECORD refreshes the AF Database Cache and updates the internal
            % representation with any changes applied to the AFElement on the
            % AF Database.
            % READRECORD sets IsDirty to false as the internal representation
            % is now the same as the external representation. 
            % READRECORD gets attribute values from attributes
            
            obj.DataConnector.refreshAFDbCache();
            obj.IsDirty = false;
            
            % CCEInternalConfig
            obj.CalculationState = obj.getFieldFromDb('CalculationState');
            obj.CoordinatorID = obj.getFieldFromDb('CoordinatorID');
            obj.LastCalculationTime = obj.getFieldFromDb('LastCalculationTime');
            obj.LastError = obj.getFieldFromDb('LastError');
            
            %CCEConfig
            obj.ComponentName = obj.getFieldFromDb('ComponentName');
            obj.CalculationName = obj.getFieldFromDb('CalculationName');
            obj.RequestToDisable = obj.getFieldFromDb("RequestToDisable");
            if ~isempty(obj.Attributes.WriteNanAs) 
                %Backwards compatibility - only get value from DB if attribute exists. 
                obj.WriteNanAs = obj.getFieldFromDb('WriteNanAs');
            else
                obj.WriteNanAs = cce.WriteNanAsValue("NaN");
            end
            
            % Log Paremeters
            obj.CalculationID = obj.getFieldFromDb('CalculationID');
            obj.LogLevel = obj.getFieldFromDb('LogLevel');
            obj.LogName = obj.getFieldFromDb('LogName');
            
            % Execution Parameters
            obj.ExecutionOffset = obj.getFieldFromDb('ExecutionOffset');
            obj.ExecutionMode = obj.getFieldFromDb('ExecutionMode');
            obj.ExecutionFrequency = obj.getFieldFromDb('ExecutionFrequency');
            obj.ExecutionIndex = obj.getFieldFromDb('ExecutionIndex');

            % Backfilling Parameters
            obj.BackfillState = obj.getFieldFromDb('BackfillState');
            obj.BackfillProgress = obj.getFieldFromDb('BackfillProgress');
            obj.BackfillLastError = obj.getFieldFromDb('BackfillLastError');
            obj.BackfillOverwrite = obj.getFieldFromDb('BackfillOverwrite');
            obj.BackfillStartTime = obj.getFieldFromDb('BackfillStartTime');
            obj.BackfillEndTime = obj.getFieldFromDb('BackfillEndTime');
            obj.SkipBackfill = obj.getFieldFromDb('SkipBackfill');
            obj.MissedRunsThreshold = obj.getFieldFromDb('MissedRunsThreshold');
        end

        function readRecordForCyclicCoord(obj)
            %READRECORD Update the internal representation for external changes.
            % READRECORD refreshes the AF Database Cache and updates the internal
            % representation with any changes applied to the AFElement on the
            % AF Database (Only refreshes values needed in the execution of runCyclicCoordinator).
            % READRECORD sets IsDirty to false as the internal representation
            % is now the same as the external representation. 
            % READRECORD gets attribute values from attributes
            
            obj.DataConnector.refreshAFDbCache();
            obj.IsDirty = false;
            
            % CCEInternalConfig
            obj.CalculationState = obj.getFieldFromDb('CalculationState');
            obj.LastCalculationTime = obj.getFieldFromDb('LastCalculationTime');
            obj.LastError = obj.getFieldFromDb('LastError');
            
            %CCEConfig
            obj.ComponentName = obj.getFieldFromDb('ComponentName');
            obj.CalculationName = obj.getFieldFromDb('CalculationName');
            obj.RequestToDisable = obj.getFieldFromDb("RequestToDisable");
            if ~isempty(obj.Attributes.WriteNanAs) 
                %Backwards compatibility - only get value from DB if attribute exists. 
                obj.WriteNanAs = obj.getFieldFromDb('WriteNanAs');
            else
                obj.WriteNanAs = cce.WriteNanAsValue("NaN");
            end
            
            % Log Paremeters
            obj.LogLevel = obj.getFieldFromDb('LogLevel');
            obj.LogName = obj.getFieldFromDb('LogName');
        end
        
        function val = getField(obj, fieldName)
            %GETFIELD GETFIELD read the field value from the local Coordinator record
            % Inputs:
            %   fieldName   -   (string) Name of the AFAttribute in the Coordinator Record
            %                   to query.
            
            arguments
                obj (1,1) cce.AFCalculationRecord
                fieldName string
            end

            % getField no longer queries the DB each time CalculationState, LastError,
            % LastCalculationTime and BackfillState. This change was made to reduce coordinator
            % overhead run time
            val = obj.(fieldName);
        end
        
        function setField(obj, fieldName, val)
            %SETFIELD set the field value.
            % Inputs:
            %   fieldName   -   (string) Name of the AFAttribute in the Coordinator Record
            %                   to set the value.
            %
            % If AutoCommit is set to true, the external record - the AFElement on the AF
            % Database - is updated with the changes.
            %
            % If the field (Attribute) that is being updated, has a PIPoint data
            % reference, the value is also directly written to the PIPoint.
            
            arguments
                obj (1,1) cce.AFCalculationRecord
                fieldName string
                val
            end
            
            %Set the value for the internal representation
            obj.(fieldName) = val;
            
            %Set the value in the external (DB) representation - if it is a PIPoint, or
            %AutoCommit is true, otherwise, set the IsDirty to false for pushing to the
            %external representation later
            if ( isa(obj.Attributes.(fieldName).DataReference, 'OSIsoft.AF.Asset.DataReference.PIPointDR') || ...
                ismember(fieldName, ["CalculationState", "LastCalculationTime", "LastError"])) && ...
                    ~cce.System.TestMode %If it references a PIPoint, write immediately. No Check In needed
                
                obj.DataConnector.setField(obj.Attributes.(fieldName), val);
                
                if isdatetime(val)
                    if ismissing(val)
                        [obj.(fieldName)] = getFieldFromDb(obj, fieldName);
                    end
                end
                
            elseif obj.AutoCommit && ~cce.System.TestMode
                commit(obj);
                obj.IsDirty = false;
            else
                obj.IsDirty = true;
            end
        end
        
        function commit(obj)
            % COMMIT Commit all records in the array.
            % Check-in all local changes to the AFElements on the AF Database.
            
            if ~cce.System.TestMode
                for k = 1:numel(obj)
                    
                    dataConnector = obj(k).DataConnector;
                    attributes = obj(k).Attributes;
                    
                    %Write the local record back to the AF Database if object creation
                    %hasn't failed - i.e. the attributes are not empty, the CoordinatorID
                    %was read and the dataConnector
                    if ~isempty(fieldnames(attributes)) && ~isempty(obj(k).CoordinatorID) && ~isempty(dataConnector)
                        
                        %Commit attributes that do not reference a PI Point
                        dataConnector.setField(attributes.CoordinatorID, obj(k).CoordinatorID);
                        dataConnector.setField(attributes.ExecutionIndex, obj(k).ExecutionIndex);
                        dataConnector.setField(attributes.RequestToDisable, obj(k).RequestToDisable);
                        
                        dataConnector.setField(attributes.BackfillState, obj(k).BackfillState);
                        dataConnector.setField(attributes.BackfillProgress, obj(k).BackfillProgress);
                        dataConnector.setField(attributes.BackfillLastError, obj(k).BackfillLastError);
                        
                        dataConnector.commitToDatabase();
                        obj(k).IsDirty = false;
                    end
                end
            end
        end
        
        function delete(obj)
            %DELETE Before deleting the object, commit any changes that have not been
            %pushed to the AF Database.
            
            if ~isempty(obj) && obj.IsDirty
                commit(obj);
            end
        end
    end
    
    methods (Access = 'private')
        function extractAttributes(obj, record)
            %EXTRACTATTRIBUTES finds and stores the AFElement's (the RECORD's)
            %AFAttributes for updating the internal representation and updating the
            %AFAttribute elements with the internal representation changes.
            %
            % Inputs:
            %   record   -   (OSIsoft.AF.Asset.AFElement) CCE Calculation AFElement
            
            arguments
                obj (1,1) cce.AFCalculationRecord;
                record (1,1) OSIsoft.AF.Asset.AFElement;
            end
            
            %Internal Config
            obj.Attributes.CoordinatorID = obj.DataConnector.getFieldByName(record, 'CoordinatorID');
            obj.Attributes.CalculationState = obj.DataConnector.getFieldByName(record, 'CalculationState');
            obj.Attributes.LastCalculationTime = obj.DataConnector.getFieldByName(record, 'LastCalculationTime');
            obj.Attributes.LastError = obj.DataConnector.getFieldByName(record, 'LastError');
            
            %CCE Parameters
            obj.Attributes.CalculationName = obj.DataConnector.getFieldByName(record, 'CalculationName');
            obj.Attributes.ComponentName = obj.DataConnector.getFieldByName(record, 'ComponentName');
            obj.Attributes.RequestToDisable = obj.DataConnector.getFieldByName(record, 'RequestToDisable');
            try %WriteNanAs is optional, if this doesnt exist as a field, getFieldByName will error. 
                obj.Attributes.WriteNanAs = obj.DataConnector.getFieldByName(record, 'WriteNanAs');
            catch
                obj.Attributes.WriteNanAs = [];
            end
            
            executionParameters = obj.DataConnector.getFieldByName(record, 'ExecutionParameters');
            obj.Attributes.ExecutionOffset = obj.DataConnector.getFieldByName(executionParameters, 'ExecutionOffset');
            obj.Attributes.ExecutionMode = obj.DataConnector.getFieldByName(executionParameters, 'ExecutionMode');
            obj.Attributes.ExecutionFrequency = obj.DataConnector.getFieldByName(executionParameters, 'ExecutionFrequency');
            obj.Attributes.ExecutionIndex = obj.DataConnector.getFieldByName(executionParameters, 'ExecutionIndex');
            
            backfilling = obj.DataConnector.getFieldByName(record, 'BackfillingParameters');
            obj.Attributes.BackfillState = obj.DataConnector.getFieldByName(backfilling, 'BackfillState');
            obj.Attributes.BackfillProgress = obj.DataConnector.getFieldByName(backfilling, 'BackfillProgress');
            obj.Attributes.BackfillLastError = obj.DataConnector.getFieldByName(backfilling, 'BackfillLastError');
            obj.Attributes.BackfillOverwrite = obj.DataConnector.getFieldByName(backfilling, 'BackfillOverwrite');
            obj.Attributes.BackfillStartTime = obj.DataConnector.getFieldByName(backfilling, 'BackfillStartTime');
            obj.Attributes.BackfillEndTime = obj.DataConnector.getFieldByName(backfilling, 'BackfillEndTime');
            obj.Attributes.SkipBackfill = obj.DataConnector.getFieldByName(backfilling, 'SkipBackfill');
            obj.Attributes.MissedRunsThreshold = obj.DataConnector.getFieldByName(backfilling, 'MissedRunsThreshold');
            
            logParameters = obj.DataConnector.getFieldByName(record, 'LogParameters');
            obj.Attributes.CalculationID = obj.DataConnector.getFieldByName(logParameters, 'CalculationID');
            obj.Attributes.LogLevel = obj.DataConnector.getFieldByName(logParameters, 'LogLevel');
            obj.Attributes.LogName = obj.DataConnector.getFieldByName(logParameters, 'LogName');
            
        end
        
        function [val] = getFieldFromDb(obj, fieldName)
            %GETFIELDFROMDB read the field value from external AF database.
            % Inputs:
            %   fieldName   -   (string) Name of the AFAttribute in the Coordinator
            %                   Element to query.
            
            try
            [val] = obj.DataConnector.readField(obj.Attributes.(fieldName));

            % if value is empty or nan, retry once then error out if it
            % happens again
            if isnumeric(val)
                if (isnan(val) && ~ismember(fieldName,"ExecutionFrequency")) || isempty(val)
                    [val] = obj.DataConnector.readField(obj.Attributes.(fieldName));
                    if (isnan(val) && ~ismember(fieldName,"ExecutionFrequency")) || isempty(val)
                        error("Error reading attribute %s.", fieldName)
                    end
                end
            end
            
            switch fieldName
                case "ExecutionMode"
                    if isnumeric(val) && isempty(val)
                        val = cce.CalculationExecutionMode.Periodic;
                    else
                        val = cce.CalculationExecutionMode(val);
                    end
                case {"ExecutionFrequency", "ExecutionOffset", "Lifetime"}
                    val = duration(0, 0, val);
                    val.Format = 's';
                case "CalculationState"
                    if isnumeric(val) && isempty(val)
                        val = cce.CalculationState.NotAssigned;
                    else
                        val = cce.CalculationState(val);
                    end
                case {"LastError", "BackfillLastError"}
                    if isnumeric(val) && isempty(val)
                        val = cce.CalculationErrorState.Good;
                    else
                        val = cce.CalculationErrorState(val);
                    end
                case "BackfillState"
                    if isnumeric(val) && isempty(val)
                        val = cce.CalculationBackfillState.Off;
                    else
                        val = cce.CalculationBackfillState(val);
                    end
                case "BackfillOverwrite"
                    if isnumeric(val) && isempty(val)
                        val = cce.BackfillOverwrite.None;
                    else
                        val = cce.BackfillOverwrite(val);
                    end
            end
            catch err
                error("Error reading %s attribute. Error message: %s", fieldName, err.message)
            end
        end
    end
    
    methods (Static, Access = 'private')
        function isValid = checkValidPiPoints(attribute)
            %Check that the Attribute has a direct PIPoint DataReference
            
            dataReference = attribute.DataReference;
            isValid = isa(dataReference, 'OSIsoft.AF.Asset.DataReference.PIPointDR');
        end
    end
end

