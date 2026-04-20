classdef CSVCoordinatorRecord < cce.ICoordinatorRecord
    %CSVCoordinatorRecord  Concrete implementation of ICoordinatorDbService for CSV storage
    %
    %   CSV Persistence of the CoordinatorRecord occurs through CSV files; one per Coordinator.
    %
    %   The Coordinator record is internally represented as a table.
    
    properties (Access = private) % These are used to realise the storage
        Table; % Internal storage of the properties
        DataConnector (1,1) cce.CSVDataConnector; % Connection serialiser
    end
        
    methods % Constructor, Destructor
        function obj = CSVCoordinatorRecord(id, dataConnector)
            % Constructor - instantiate a record.
            if nargin > 0
                obj.DataConnector = dataConnector;
                readRecord(obj, id);
            end
        end
    end
    methods
        function delete(obj)
            % Write the table if required
            if ~isempty(obj) && obj.IsDirty
                commit(obj);
            end
        end
    end
    methods % Implementations of ICoordinatorDBService
        function commit(obj)
            % commit Commit all records in the array
            for k=1:numel(obj)
                % "Convert" duration values
                if ~isempty(obj(k).Table)
                    writeRecord(obj(k).DataConnector, obj(k).Table);
                    obj(k).IsDirty = false;
                end
            end
        end
        function setField(obj, field, val)
            arguments
                obj (1,1) cce.CSVCoordinatorRecord
                field
                val
            end
            if ismember(field, ["ExecutionOffset","ExecutionFrequency","Lifetime"])
                val.Format = 'hh:mm:ss';
            end
            obj.Table.(field) = val;
            if obj.AutoCommit
                commit(obj); % We always write the table. 
                % TODO: Might need to improve to write only the specific field.
            else
                obj.IsDirty = true;
            end
        end
        function val = getField(obj, field)
            % getField Return the value of a field
            arguments
                obj (1,1) cce.CSVCoordinatorRecord
                field
            end
            val = obj.Table.(field);
        end
        function readRecord(obj, id)
            %readRecord Update the internal representation for external changes
            if nargin<2
                id = obj.Table.CoordinatorID;
            end
            obj.Table = obj.DataConnector.readRecord(id);
            % Special case data types
            obj.Table.ExecutionMode = cce.CoordinatorExecutionMode(obj.Table.ExecutionMode);
            obj.Table.ExecutionFrequency = duration(obj.Table.ExecutionFrequency);
            obj.Table.ExecutionOffset = duration(obj.Table.ExecutionOffset);
            obj.Table.Lifetime = duration(obj.Table.Lifetime);
            obj.Table.CoordinatorState = cce.CoordinatorState(obj.Table.CoordinatorState);
            obj.IsDirty = false;
        end
    end
end