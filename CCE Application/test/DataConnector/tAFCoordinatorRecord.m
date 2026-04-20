classdef tAFCoordinatorRecord < matlab.unittest.TestCase
    %TAFCOORDINATORRECORD
    
    %TODO: Test actual values
    
    properties (Constant)
        %Connect to the test server and database
        DataConnector = af.AFDataConnector(cce.System.CalculationServerName, cce.System.CalculationDBName);
        CoordinatorID = 1;
        TemplateName = "CCECoordinator";
    end
    properties (Access = private)
        CoordinatorElement
    end
    
    methods (TestClassSetup)
        function findElementToTest(testcase)
            %FINDELEMENTTOTEST find a Coordinator Record on the AF database for testing
            
            searchName = "CoordinatorSearchID" + testcase.CoordinatorID;
            searchCriteria = sprintf("Template:'%s' ""|CoordinatorID"":='%d'""", testcase.TemplateName, testcase.CoordinatorID); %TODO: This needs to align with Coordinator Template in CCE
            [record] = testcase.DataConnector.findRecords(searchName, searchCriteria);
            testcase.CoordinatorElement = record{:};
        end
    end
    
    methods (Test)
        function tCoordRecordConstructor(testcase)
            %TCOORDRECORDCONSTRUCTOR test that the constructor returns a
            %cce.AFCoordinatorRecord object when passed the record and data connector
            
            recordObject = cce.AFCoordinatorRecord(testcase.CoordinatorElement, testcase.DataConnector);
            testcase.fatalAssertClass(recordObject, 'cce.AFCoordinatorRecord');
        end
        
        function tReadRecord(testcase)
            %TREADRECORD test the read record method that updates the local record with
            %changes from the external record on the AF database
            
            % T1: Read the record from the AF database, make local changes without pushing
            % those to the AF database. Update the record with the values stored in the
            % external AF database record. Verify that the local changes were not pus
            recordObject = cce.AFCoordinatorRecord(testcase.CoordinatorElement, testcase.DataConnector);
            val = recordObject.getField("CoordinatorID");
            recordObject.setField("CoordinatorID", val+1);
            updateVal = recordObject.getField("CoordinatorID");
            recordObject.readRecord;
            origVal = recordObject.getField("CoordinatorID");
            testcase.assertEqual(val, origVal);
            testcase.assertNotEqual(updateVal, val);
        end
        
        function tCommit(testcase)
            %TCOMMIT test that local changes are pushed to the external record on the AF
            %database when commit to the server
            
            % T1: Test that a local change pushed to the server is actually recorded in
            % the AF database record
            recordObject = cce.AFCoordinatorRecord(testcase.CoordinatorElement, testcase.DataConnector);
            val = recordObject.getField("CoordinatorID");
            recordObject.setField("CoordinatorID", val+1);
            recordObject.commit;
            updateVal = recordObject.getField("CoordinatorID");
            recordObject.readRecord;
            newDbVal = recordObject.getField("CoordinatorID");
            testcase.assertNotEqual(val, newDbVal);
            testcase.assertEqual(updateVal, newDbVal);
            
            % Teardown: do this here to restore the record on the AF database as before
            recordObject.setField("CoordinatorID", val);
            recordObject.commit;
        end
    end
end

