classdef AFCoordinatorRecord < cce.ICoordinatorRecord
    %AFCOORDINATORRECORD  Concrete implementation of ICoordinatorDbService for AF database
    %storage
    %
    %   AF Persistence of the CoordinatorRecord occurs through AF elements; one per Coordinator.
    %
    %   The Coordinator record is internally represented as a Coordinator Object.
    
    properties (Access = 'private')
        DataConnector %(1,1) af.AFDataConnector;
        Attributes struct = struct(); % Reference to Record Attribute Objects
    end
    
    properties (Access = 'private') % Internal storage of the properties
        CoordinatorID (1,1) int32 %Attribute
        ExecutionMode cce.CoordinatorExecutionMode %Attribute
        ExecutionFrequency (1,1) duration %Attribute
        ExecutionOffset (1,1) duration %Attribute
        Lifetime (1,1) %Attribute
        CalculationLoad (1,1) int32 %Attribute
        MaxCalculationLoad (1,1) int32 = cce.System.CoordinatorMaxLoad;
        CoordinatorState (1,1) %PI Point
        RequestToDisable (1,1) logical %Attribute
        ReenableSystemDisabledCalcs (1,1) logical = false; %Attribute
        LogLevel (1, 1) LogMessageLevel = LogMessageLevel.Warning; %Attribute
        LogName (1, 1) string = "coordinator.log"; %Attribute
        RetryFrequency uint32
        SkipBackfill logical
        ElementName string
    end
    
    methods
        function obj = AFCoordinatorRecord(record, dataConnector)
            %AFCOORDINATORRECORD reads the AFElement (RECORD) from the AF Database,
            %extracts the AFAttribute objects, and creates the internal representation of
            %the AFElement.
            
            if nargin > 0
                obj.DataConnector = dataConnector;
                extractAttributes(obj, record);
                readRecord(obj);
            end
        end
        
        function readRecord(obj)
            %READRECORD Update the internal representation for external changes.
            % READRECORD refreshes the AF Database Cache and updates the internal
            % representation with any changes applied to the AFElement on the
            % AF Database.
            % READRECORD sets IsDirty to false as the internal representation
            % is now the same as the external representation.
            
            obj.DataConnector.refreshAFDbCache();
            
            %Read Record will overwrite any local changes.
            obj.CoordinatorID = obj.getFieldFromDB('CoordinatorID');
            obj.ExecutionMode = obj.getFieldFromDB('ExecutionMode');
            obj.ExecutionFrequency = obj.getFieldFromDB('ExecutionFrequency');
            obj.ExecutionOffset = obj.getFieldFromDB('ExecutionOffset');
            obj.Lifetime = obj.getFieldFromDB('Lifetime');
            obj.CalculationLoad = obj.getFieldFromDB('CalculationLoad');
            obj.CoordinatorState = obj.getFieldFromDB('CoordinatorState');
            obj.RequestToDisable = obj.getFieldFromDB('RequestToDisable');
            obj.RetryFrequency = obj.getFieldFromDB('RetryFrequency');
            obj.SkipBackfill = obj.getFieldFromDB('SkipBackfill');
            obj.ElementName = obj.getFieldFromDB('ElementName');

            %Only retrieve if attribute exists - the following attributes
            %were added to CCE as of version 1.2.7. Old coordinators will
            %be updated with template update. 
            if ~isempty(obj.Attributes.ReenableSystemDisabledCalcs) 
                obj.ReenableSystemDisabledCalcs = obj.getFieldFromDB('ReenableSystemDisabledCalcs');
                obj.LogLevel = obj.getFieldFromDB('LogLevel');
                obj.LogName = obj.getFieldFromDB('LogName');
            end
            if ~isempty(obj.Attributes.MaxCalculationLoad)
                obj.MaxCalculationLoad = obj.getFieldFromDB('MaxCalculationLoad');
                obj.MaxCalculationLoad = getCalculationLoad(obj.ExecutionFrequency);
                
            end

            obj.IsDirty = false;
        end
        
        function val = getField(obj, fieldName)
            %GETFIELD read the field value from the local Coordinator record
            % Inputs:
            %   fieldName   -   (string) Name of the AFAttribute in the Coordinator Record
            %                   to query.
            arguments
                obj (1,1) cce.AFCoordinatorRecord
                fieldName string
            end
            
            % If the field is expected to be a PIPoint, read the value directly from the
            % external representation (DB) otherwise read from the internal
            % representation. 
            % To updated the internal representation with the external updates,
            % readRecord(obj) should be called first.

            if ismember(fieldName, ["CoordinatorState", "RequestToDisable"]) && ~cce.System.TestMode 
                %Added RequestToDisable, to prevent the need for refreshAttributes
                % call in checkForDisabled function

                %Refresh cache
                obj.DataConnector.refreshAFDbCache();

                %Get value
                [val] = getFieldFromDB(obj, fieldName);
                obj.(fieldName) = val;
            else
                val = obj.(fieldName);
            end
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
                obj (1,1) cce.AFCoordinatorRecord
                fieldName string
                val
            end
            
            obj.(fieldName) = val;
            
            %Set the value in the external (DB) representation - if it is a PIPoint, or
            %AutoCommit is true, otherwise, set the IsDirty to false for pushing to the
            %external representation later
            if (isa(obj.Attributes.(fieldName).DataReference, 'OSIsoft.AF.Asset.DataReference.PIPointDR') || ...
                    ismember(fieldName, "CoordinatorState")) && ~cce.System.TestMode %If it references a PIPoint, write immediately. No checkin needed
                if isenum(val)
                    val = string(val);
                end
                obj.DataConnector.setField(obj.Attributes.(fieldName), val);
                if isdatetime(val)
                    if ismissing(val)
                        [obj.(fieldName)] = getFieldFromDB(obj, fieldName);
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
            %COMMIT Commit all records in the array.
            % Check-in all local changes to the AFElements on the AF Database.
            
            if ~cce.System.TestMode
                for k=1:numel(obj)
                    
                    dataConnector = obj(k).DataConnector;
                    attributes = obj(k).Attributes;
                    
                    if ~isempty(fieldnames(attributes)) && ~isempty(obj(k).CoordinatorID) && ~isempty(dataConnector)
                        dataConnector.setField(attributes.CoordinatorID, obj(k).CoordinatorID);
                        dataConnector.setField(attributes.ExecutionMode, double(obj(k).ExecutionMode));
                        dataConnector.setField(attributes.ExecutionFrequency, seconds(obj(k).ExecutionFrequency));
                        dataConnector.setField(attributes.ExecutionOffset, seconds(obj(k).ExecutionOffset));
                        dataConnector.setField(attributes.Lifetime, seconds(obj(k).Lifetime));
                        dataConnector.setField(attributes.CalculationLoad, obj(k).CalculationLoad);
                        dataConnector.setField(attributes.CoordinatorState, double(obj(k).CoordinatorState));
                        dataConnector.setField(attributes.RequestToDisable, obj(k).RequestToDisable);
                        dataConnector.setField(attributes.SkipBackfill, obj(k).SkipBackfill);

                        %Properties added in CCE version 1.2.7,
                        %check if empty for backwards compatibility
                        if ~isempty(attributes.ReenableSystemDisabledCalcs)
                            dataConnector.setField(attributes.ReenableSystemDisabledCalcs, obj(k).ReenableSystemDisabledCalcs);
                        end
                        if ~isempty(attributes.MaxCalculationLoad)
                            dataConnector.setField(attributes.MaxCalculationLoad, obj(k).MaxCalculationLoad);
                        end

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
            % EXTRACTATTRIBUTES finds the existing AFAttributes in a CCE Coordinator
            % element. If the CoordinatorState PIPoint/ Datareferences has not been
            % created, EXTRACTATTRIBUTES will create the PIPoint.
            %
            % Inputs:
            %   record   -   (OSIsoft.AF.Asset.AFElement) CCE Coordinator AFElement
            
            arguments
                obj (1,1) cce.AFCoordinatorRecord;
                record (1,1) OSIsoft.AF.Asset.AFElement;
            end
            
            attributes = record.Attributes;
            
            obj.Attributes.CoordinatorID = attributes.Item('CoordinatorID');
            obj.Attributes.ExecutionMode = attributes.Item('ExecutionMode');
            obj.Attributes.ExecutionFrequency = attributes.Item('ExecutionFrequency');
            obj.Attributes.ExecutionOffset = attributes.Item('ExecutionOffset');
            obj.Attributes.Lifetime = attributes.Item('Lifetime');
            obj.Attributes.CalculationLoad = attributes.Item('CalculationLoad');
            obj.Attributes.CoordinatorState = attributes.Item('CoordinatorState');
            obj.Attributes.RequestToDisable = attributes.Item('RequestToDisable');
            obj.Attributes.RetryFrequency = attributes.Item('RetryFrequency');
            obj.Attributes.SkipBackfill = attributes.Item('SkipBackfill');
            obj.Attributes.ElementName = attributes.Item('ElementName');

            %Newly added coordinator parameters, must be backwards
            %compatible - leaves attributes as empty if these don't exist. 
            try
                obj.Attributes.ReenableSystemDisabledCalcs = attributes.Item('ReenableSystemDisabledCalcs');
                obj.Attributes.LogLevel = attributes.Item("LogParameters").Attributes.Item("LogLevel");
                obj.Attributes.LogName = attributes.Item("LogParameters").Attributes.Item("LogName");
                obj.Attributes.MaxCalculationLoad = attributes.Item('MaxCalculationLoad');
            catch
                obj.Attributes.ReenableSystemDisabledCalcs = [];
                obj.Attributes.LogLevel = [];
                obj.Attributes.LogName = [];
                obj.Attributes.MaxCalculationLoad = [];
            end

            if ~isempty(obj.Attributes.CoordinatorState.DataReference)
                try
                    obj.Attributes.CoordinatorState.PIPoint;
                catch err
                    if ismember(err.identifier, {'MATLAB:NET:CLRException:PropertyGet'}) && isa(err.ExceptionObject, 'OSIsoft.AF.PI.PIPointInvalidException')
                        obj.Attributes.CoordinatorState.DataReference.CreateConfig();
                        writeFieldHistory(obj.DataConnector, obj.Attributes.CoordinatorState, ...
                            int32(cce.CoordinatorState.NotRunning), datetime('now'), "Good", []);
                    end
                end
            end
        end
        
        function val = getFieldFromDB(obj, fieldName)
            %GETFIELDFROMDB read the field value from external AF database.
            % Inputs:
            %   fieldName   -   (string) Name of the AFAttribute in the Coordinator
            %                   Element to query.
            
            try
            [val] = obj.DataConnector.readField(obj.Attributes.(fieldName));

            % if value is empty or nan, retry once then error out if it
            % happens again
            if isnumeric(val)
                if (isnan(val) && ~ismember(fieldName,"ExecutionFrequency")) || isempty(val) % ExecutionFrequency can be nan for manual coordinator
                    [val] = obj.DataConnector.readField(obj.Attributes.(fieldName));
                    if (isnan(val) && ~ismember(fieldName,"ExecutionFrequency")) || isempty(val)
                        error("Invalid attribute value.")
                    end
                end
            end
            
            switch fieldName
                case "ExecutionMode"
                    val = cce.CoordinatorExecutionMode(val);
                case "CoordinatorState"
                    val = cce.CoordinatorState(val);
                    if isempty(val)
                       val = cce.CoordinatorState.NotRunning;
                    end
                case {"ExecutionFrequency", "ExecutionOffset", "Lifetime"}
                    val = duration(0, 0, val);
                    val.Format = 's';
            end
            catch err
                error("Error reading %s attribute. Error message: %s", fieldName, err.message)
            end
        end
    end
end

