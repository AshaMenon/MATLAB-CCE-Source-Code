classdef AFCoordinatorDbService < cce.ICoordinatorDbService
    
    properties (Constant)
        DataConnector af.AFDataConnector = af.AFDataConnector(cce.System.CoordinatorServerName, cce.System.CoordinatorDBName);
        TemplateName = "CCECoordinator";%TODO: Add to cce.System?
        CoordinatorHierarchy = {'CCECoordinator'}; %cce.System.CoordinatorHierarchy;%TODO: Add to cce.System?
    end
    
    methods (Static)
        function obj = getInstance()
            persistent singleton
            if isempty(singleton)
                singleton = cce.AFCoordinatorDbService();
            end
            obj = singleton;
        end
    end
    
    methods % Interfaces of ICoordinatorDBService
        function [coordinatorRecord] = findCoordinators(obj, id) % Find Coordinators with specific id
            % FINDCOORDINATORS find Coordinator(s) in a specific database
            %   FINDCOORDINATORS(OBJ, ID) finds the Coordinators matching the given list of Ids.
            % Inputs:
            %   id  - (uint32) a list of CoordinatorID numbers to search for on the AF Database
            %
            % Outputs:
            %   coordinatorRecord - (cce.AFCoordinatorRecord) array of
            %                       cce.AFCoordinatorRecord objects returned from search
            
            arguments
                obj (1,1) cce.AFCoordinatorDbService;
                id (1, :) int32;
            end
            
            notFound = true(size(id));
            for notFoundSub = numel(id):-1:1
                
                searchName = "CoordinatorSearchID" + id(notFoundSub);
                searchCriteria = sprintf("Template:'%s' ""|CoordinatorID"":='%d'""", obj.TemplateName, id(notFoundSub));
                [record] = obj.DataConnector.findRecords(searchName, searchCriteria);
                
                if ~isempty(record)
                    notFound(notFoundSub) = false;
                    %FIXME: This assumes that only one coord record will be found per template + ID?
                    coordinatorRecord(notFoundSub)  = cce.AFCoordinatorRecord(record{:}, obj.DataConnector);
                end
            end
            
            if any(notFound)
                if all(notFound)
                    coordinatorRecord  = cce.AFCoordinatorRecord.empty;
                    warning("cce:CoordinatorDbService:RecordNotFound", ...
                        "Could not find any CCE Coordinators in the AF database. Server: %s, Database: %s.", ...
                        obj.DataConnector.ServerName, obj.DataConnector.DatabaseName);
                else
                    missingID = id(notFound);
                    missingIDString = string(sort(missingID));
                    warnStr = join(missingIDString(1:end-1), ", ");
                    warnStr = join([warnStr, missingIDString(end)], ", and ");
                    warning("cce:CoordinatorDbService:RecordNotFound", ...
                        "Could not find CCE Coordinators with id(s): %s in the AF database. Server: %s, Database: %s.", ...
                        warnStr, obj.DataConnector.ServerName, obj.DataConnector.DatabaseName);
                end
                notFoundSub = find(notFound);
                coordinatorRecord(notFoundSub(notFoundSub <= numel(coordinatorRecord))) = [];
            end
        end
        
        function [coordinatorRecord] = findAllCoordinators(obj) % Find all Coordinators in the database
            % FINDALLCOORDINATORS find all Coordinator(s) in a specific database.
            %   FINDALLCOORDINATORS(OBJ) finds the all the Coordinators.
            % Outputs:
            %   coordinatorRecord - (cce.AFCoordinatorRecord) array of
            %                       cce.AFCoordinatorRecord objects returned from search
            
            [records] = obj.DataConnector.findRecordsByTemplate('CoordinatorSearch', obj.TemplateName);
            if isempty(records)
                coordinatorRecord  = cce.AFCoordinatorRecord.empty;
            else
                for k = numel(records):-1:1
                    coordinatorRecord(k) = cce.AFCoordinatorRecord(records{k}, obj.DataConnector);
                end
            end
        end
        
        function [coordinatorRecord] = createCoordinator(obj, id, mode, frequency, offset, lifetime, calcLoad, skipBackfill) % Create a new coordinator in the database
            %CREATECOORDINATOR  Create a CoordinatorRecord for CCE
            %   COBJ = CREATECOORDINATOR(ID, MODE, FREQUENCY, OFFSET, LIFETIME, CALCLOAD) creates a new
            %       Coordinator Element on the Coordinator AF Database and sets the
            %       CoordinatorID, ExecutionMode, ExecutionFrequency, ExecutionOffset,
            %       LifeTime, and CalculationLoad attributes of the created Coordinator
            %       element.
            % Inputs:
            %   id          -	(int32) unique identifier for the new Coordinator Element, sets the
            %                   Coordinator element CoordinatorID. ID must be a new unique
            %                   identifier. If the input ID value is already used,
            %                   CREATECOORDINATOR will throw an error, no Coordinator
            %                   element will be created.
            %   mode        -   (cce.CoordinatorExecutionMode) sets the CoordinatorExecutionMode of the Coordinator
            %                   element.
            %   frequency	-   (duration) sets the ExecutionFrequency of the Coordinator
            %                   element.
            %   offset      -   (duration) sets the ExecutionOffset of the Coordinator
            %                   element.
            %   lifetime    -   (duration) sets the LifeTime of the Coordinator element.
            %   calcLoad    -   (uint32) sets the CalculationLoad of the Coordinator
            %                   element.
            %
            % Outputs:
            %	coordinatorRecord	-	(cce.AFCoordinatorRecord) cce.AFCoordinatorRecord
            %                           object of the created Coordinator element
            
            
            arguments
                obj
                id (1,1) int32
                mode (1,1) cce.CoordinatorExecutionMode
                frequency (1,1) duration
                offset (1,1) duration
                lifetime (1,1) duration
                calcLoad (1,1) uint32
                skipBackfill (1,1) logical
            end
            
            searchName = "CoordinatorSearchID" + id;
            searchCriteria = sprintf("Template:'%s' ""|CoordinatorID"":='%d'""", obj.TemplateName, id);
            [record] = obj.DataConnector.findRecords(searchName, searchCriteria, 0, 1);
            if ~isempty(record)
                error("cce:AFCoordinatorRecord:RecordExists", "Record %d already exists in the database (Server: %s. Database: %s). No coordinator record was created.", id, obj.DataConnector.ServerName, obj.DataConnector.DatabaseName);
            end
            
            recordName = "CCECoordinator" + id;
            if ~cce.System.TestMode
                [record] = obj.DataConnector.createRecordWithHierarchy(obj.TemplateName, recordName, obj.CoordinatorHierarchy);
            else
                [template] = obj.DataConnector.findTemplateByName("CCECoordinator");
                record = OSIsoft.AF.Asset.AFElement(recordName, template);
            end
            coordinatorRecord = cce.AFCoordinatorRecord(record, obj.DataConnector);
            
            coordinatorRecord.setField("CoordinatorID", id);
            coordinatorRecord.setField("ExecutionMode", mode);
            coordinatorRecord.setField("ExecutionFrequency", frequency);
            coordinatorRecord.setField("ExecutionOffset", offset);
            coordinatorRecord.setField("Lifetime", lifetime);
            coordinatorRecord.setField("CalculationLoad", calcLoad);
            coordinatorRecord.setField("SkipBackfill", skipBackfill);
            coordinatorRecord.setField("RequestToDisable", false);
            if ~ismember(coordinatorRecord.getField("CoordinatorState"), cce.CoordinatorState.NotRunning)
                coordinatorRecord.setField("CoordinatorState", cce.CoordinatorState.NotRunning);
            end
            if ~cce.System.TestMode
                coordinatorRecord.commit();
                
                coordinatorRecord.readRecord();
            end
        end
        
        function removeCoordinator(obj, id)
            %REMOVECOORDINATOR Permanently deletes the Coordinator element with
            % CoordinatorID, ID from the Coordinator AF Database.
            % REMOVECOORDINATOR(OBJ, ID) premanently deletes the Coordinator element with
            % CoordinatorID matching ID from the Coordinator AF Database.
            %
            % Inputs:
            %	id	-	(int32) CoordinatorID numbers of the Coordinator element to
            %           delete.
            
            if ~cce.System.TestMode
                searchName = "CoordinatorSearchID" + id;
                searchCriteria = sprintf("Template:'%s' ""|CoordinatorID"":='%d'""", obj.TemplateName, id);
                [record] = obj.DataConnector.findRecords(searchName, searchCriteria, 0, 1);
                obj.DataConnector.deleteRecord(record{:});
                obj.DataConnector.commitToDatabase();
            end
        end
    end
end
