classdef tCoordinatorPersistenceCSV < matlab.unittest.TestCase
    %tCoordinatorPersistenceCSV  Validate behaviour of Coordinator CSV Persistence
    %   Checks that Coordinator properties persist in the CSV database
    %
    %   Makes use of both the CSVCoordinatorDbService and CSVCoordinatorRecord.
    
    properties
        DataService % Data service to use; Constructed in the TestClassSetup
        TestDbFolder = tempname; % Temporary folder for storing database entries
    end
    
    methods(TestMethodSetup)
        function createFolderAndDbService(tc)
            % In this case, we set an environment variable to override the CCE system
            if ~exist(tc.TestDbFolder, "dir")
                mkdir(tc.TestDbFolder);
            end
            tc.DataService = cce.CSVCoordinatorDbService.getInstance(tc.TestDbFolder);
        end
    end
    methods(TestMethodTeardown)
        function eraseFolder(tc)
            rmdir(tc.TestDbFolder, "s");
        end
    end
    methods(Test)
        function tConstructors(tc) % Test creation of Coordinators through createNew etc.
            % Set up defaults
            id = 1;
            defaultExecutionMode = cce.ExecutionMode.Single;
            defaultExecutionFrequency = minutes(1);
            defaultExecutionOffset = seconds(0);
            defaultLifetime = hours(8);
            defaultState = cce.CoordinatorState.NotRunning;
            % T1: Construct a new Coordinator - Default values are as defined
            cce.Coordinator.createNew(id, DatabaseService = tc.DataService);
            cPersisted = cce.Coordinator.fetchFromDb(id, DatabaseService = tc.DataService);
            tc.verifyEqual(cPersisted.CoordinatorID, id);
            tc.verifyEqual(cPersisted.ExecutionMode, defaultExecutionMode);
            tc.verifyEqual(cPersisted.ExecutionFrequency, defaultExecutionFrequency);
            tc.verifyEqual(cPersisted.ExecutionOffset, defaultExecutionOffset);
            tc.verifyEqual(cPersisted.Lifetime, defaultLifetime);
            tc.verifyEqual(cPersisted.CoordinatorState, defaultState);
            % T2: Construct a new Coordinator - Some non-default values are as defined
            id2 = 2;
            newMode = cce.ExecutionMode.Event;
            newFrequency = seconds(20);
            newOffset = minutes(2);
            newLifetime = hours(2);
            
            cce.Coordinator.createNew(id2, ...
                ExecutionMode = newMode,...
                ExecutionFrequency = newFrequency, ...
                ExecutionOffset = newOffset, ...
                Lifetime = newLifetime, ...
                DatabaseService = tc.DataService);
            cPersisted = cce.Coordinator.fetchFromDb(id2, DatabaseService = tc.DataService);
            tc.verifyEqual(cPersisted.CoordinatorID, id2);
            tc.verifyEqual(cPersisted.ExecutionMode, newMode);
            tc.verifyEqual(cPersisted.ExecutionFrequency, newFrequency);
            tc.verifyEqual(cPersisted.ExecutionOffset, newOffset);
            tc.verifyEqual(cPersisted.Lifetime, newLifetime);
            % State is always set to the default
            tc.verifyEqual(cPersisted.CoordinatorState, defaultState);
            % T3: Test loading all Coordinators
            cAll = cce.Coordinator.fetchFromDb([], DatabaseService = tc.DataService);
            tc.verifyNumElements(cAll, 2);
        end
        function tRemove(tc) % Test removal of Coordinators
            % Start by creating some coordinators
            cce.Coordinator.createNew(1, DatabaseService = tc.DataService);
            cce.Coordinator.createNew(2, DatabaseService = tc.DataService);
            cce.Coordinator.createNew(3, DatabaseService = tc.DataService);
            % Check coordinator records before deleting one
            cAll = cce.Coordinator.fetchFromDb([], DatabaseService = tc.DataService);
            tc.verifyNumElements(cAll, 3);
            % Delete the middle one
            cce.Coordinator.removeFromDb(2, DatabaseService = tc.DataService);
            % T1: Record must not exist
            tc.verifyError(@()cce.Coordinator.fetchFromDb(2, DatabaseService = tc.DataService), ...
                "cce:CoordinatorDbService:RecordNotFound");
            % T2: Removing an existing Coordinator from memory doesn't recreate it
            clear cAll
            tc.verifyError(@()cce.Coordinator.fetchFromDb(2, DatabaseService = tc.DataService), ...
                "cce:CoordinatorDbService:RecordNotFound");
            % T3: Other records must not be disturbed
            cAfterDelete = cce.Coordinator.fetchFromDb([], DatabaseService = tc.DataService);
            tc.verifyNumElements(cAfterDelete, 2);
        end            
        function tPropertyChanges(tc) % Test property changes for Coordinators
        end
    end
end

