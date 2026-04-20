classdef (Abstract) ICalculationRecord < handle
    %ICalculationRecord Calculation Record
    %   This abstract class provides the interface to a Calculation Record. A Calculation Record
    %   serialises a Calculation into a specific database. Each database implements a different
    %   serialisation process for each of the properties.
    %
    %   The Calculation Database Service allows the user to commit changes to properties immediately, or
    %   through a final commit() method. To control this, use the AutoCommit property.
    
    properties
        % Set to true to commit changes to the database immediately on set.
        AutoCommit (1,1) logical = false;
    end
    
    properties (SetAccess = protected) % Concrete classes use IsDirty
        IsDirty (1,1) logical = false; % Do we need to commit on destructor?
    end
    
    methods % Constructor/Destructor 
        function delete(obj)
            % delete Write any late changes before destroying object
            if obj.IsDirty
                commit(obj);
            end
        end
    end
    
    methods (Abstract) %Function signatures for concrete implementations
        commit(obj) % Write all changes to the database in one go. Reset IsDirty flag
        val = getField(obj, field) % Read a field from the Coordinator record
        setField(obj, field, val) % Set field value and (if AutoCommit) write to database
        readRecord(obj) % Read the entire record from the database (handle external updates)
    end
end

