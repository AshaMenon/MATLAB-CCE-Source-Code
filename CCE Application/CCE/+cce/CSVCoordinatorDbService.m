classdef CSVCoordinatorDbService < cce.ICoordinatorDbService
    properties (SetAccess = private)
        DataConnector (1,1) cce.CSVDataConnector;
    end
    
    methods (Static)
        function obj = getInstance(rootFolder)
            arguments
                rootFolder (1,1) string {mustBeFolder} = cce.System.DbFolder;
            end
            persistent singletonMap
            if isempty(singletonMap) || ~isKey(singletonMap, rootFolder)
                newMap = containers.Map(rootFolder, cce.CSVCoordinatorDbService(rootFolder));
                singletonMap = [singletonMap; newMap];
            end
            obj = singletonMap(rootFolder);
        end
    end
    methods (Access = private) % Constructor - use getInstance to create these
        function obj = CSVCoordinatorDbService(dbFolderRoot)
            obj.DataConnector = cce.CSVDataConnector(dbFolderRoot, "Coordinator");
        end
    end
    methods % Interfaces of ICoordinatorDBService
        function coordinatorObj = findCoordinators(obj, id)
            % findCoordinator find Coordinator(s) in the CSV database
            %   findCoordinator(obj, id) finds the Coordinators matching the given list of Ids.
            %
            %   For now the scalar search is implemented.
            arguments
                obj (1,1) cce.CSVCoordinatorDbService
                id (1,1) uint32;
            end
            notFound = true(size(id)); % Assume they're all missing
            for k=numel(id):-1:1
                if recordExists(obj.DataConnector, id(k))
                    coordinatorObj(k)  = cce.CSVCoordinatorRecord(id, obj.DataConnector);
                    notFound(k) = false;
                end
            end
            if any(notFound)
                if all(notFound)
                    error("cce:CoordinatorDbService:RecordNotFound", ...
                        "Could not find any of the required records in CSV database.");
                else
                    warning("cce:CoordinatorDbService:RecordNotFound", ...
                        "Could not find some records in CSV database.");
                end
            end
            % Remove the entries where the record is not found
            coordinatorObj(notFound) = [];
        end
        function coordinatorObj = findAllCoordinators(obj)
            % Need to load all of them
            idList = obj.DataConnector.findRecords;
            if isempty(idList)
                coordinatorObj  = cce.CSVCoordinatorRecord.empty;
            else
                for k=numel(idList):-1:1
                    coordinatorObj (k) = cce.CSVCoordinatorRecord(idList(k), obj.DataConnector);
                end
            end
        end
        function coordinatorObj = createCoordinator(obj, id, mode, frequency, offset, lifetime, calcLoad)
            %createCoordinator  Create a CoordinatorRecord for CCE
            %   CObj = createCoordinator(id, mode, frequency, offset, lifetime, calcLoad) creates a new
            %       Coordinator with index id, and other related properties.
            arguments
                obj
                id (1,1) uint32
                mode (1,1) cce.CoordinatorExecutionMode
                frequency (1,1) duration
                offset (1,1) duration
                lifetime (1,1) duration
                calcLoad (1,1) uint32
            end
            % Error if record exists
            if recordExists(obj.DataConnector, id)
                error("cce:CSVCoordinatorRecord:RecordExists", "Record " + id + " already exists in the database.");
            end
            % We enforce a duration string
            frequency.Format = 'hh:mm:ss';
            offset.Format = 'hh:mm:ss';
            lifetime.Format = 'hh:mm:ss';
            newTable = table(id, mode, frequency, offset, lifetime, calcLoad, cce.CoordinatorState.NotRunning, ...
                'VariableNames', ["CoordinatorID", "ExecutionMode", "ExecutionFrequency", "ExecutionOffset", ...
                "Lifetime", "CalculationLoad", "CoordinatorState"]);
            obj.DataConnector.writeRecord(newTable);
            coordinatorObj = cce.CSVCoordinatorRecord(id, obj.DataConnector);
        end
        function removeCoordinator(obj, id)
            if recordExists(obj.DataConnector, id)
                removeRecord(obj.DataConnector, id);
            else
                error("cce:CSVCoordinatorDbService:RecordNotFound", ...
                    "Record %d could not be found for deletion.", id);
            end
        end
    end    
end