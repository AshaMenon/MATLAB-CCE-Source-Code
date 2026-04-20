classdef tAFCoordinatorDbService < matlab.unittest.TestCase
    %TAFCOORDINATORDBSERVICE
    
    properties
        AFCoordDbService = cce.AFCoordinatorDbService.getInstance();
    end
    
    methods (TestClassSetup)
        function refreshDB(testcase)
            %REFRESHDB refresh AF DB cache
            
            testcase.AFCoordDbService.DataConnector.refreshAFDbCache();
        end
    end
    
    methods (Test)
        function tFindCoordinators(testcase)
            %TFINDCOORDINATOR Test finding a Coordinator record on the AF database with a
            %specified Coordinator ID
            
            coordRecords = testcase.AFCoordDbService.findCoordinators(1);
            nCoords = numel(coordRecords);
            testcase.verifyClass(coordRecords, 'cce.AFCoordinatorRecord');
            testcase.verifyEqual(nCoords, 1);
        end
        
        function tFindAllCoords(testcase)
            %TFINDALLCOORDS Test finding all Coordinator records on the AF database
            
            coordRecords = testcase.AFCoordDbService.findAllCoordinators();
            testcase.verifyClass(coordRecords, 'cce.AFCoordinatorRecord');
            testcase.verifyNotEmpty(coordRecords);
            testcase.verifyGreaterThanOrEqual(numel(coordRecords), 1);
        end
        
        function tCreateCoord(testcase)
            %TCREATECOORD - Test creation of a Coordinator element on the AF database
            
            mode = cce.ExecutionMode.Single;
            frequency = seconds(30);
            offset = seconds(30);
            lifetime = hours(12);
            calcLoad = uint32(0);
            
            % T1: test attempting to create a Coordinator element on the AF database with the ID
            % of an existing coordinator
            id = uint32(1);
            coordRecordHandle = @() testcase.AFCoordDbService.createCoordinator(id, mode, frequency, offset, lifetime, calcLoad);
            testcase.verifyError(coordRecordHandle, "cce:AFCoordinatorRecord:RecordExists");
            
            % T2: test creating a Coordinator element on the AF database with an ID that
            % is not in use
            idAdded = 3;
            [~] = testcase.AFCoordDbService.createCoordinator(idAdded, mode, frequency, offset, lifetime, calcLoad);
            addedRecord = testcase.AFCoordDbService.findCoordinators(idAdded);
            testcase.verifyClass(addedRecord, 'cce.AFCoordinatorRecord');
            val = addedRecord.getField("CoordinatorID");
            testcase.verifyNotEmpty(addedRecord);
            testcase.verifyEqual(double(val - idAdded), 0);
            
            %Teardown: remove added Coordinator element from the AF Database
            if ~isempty(idAdded)
                testcase.AFCoordDbService.removeCoordinator(idAdded);
            end
            
            
        end
    end
end

