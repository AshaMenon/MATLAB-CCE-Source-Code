classdef tAFCalculationRecord < matlab.unittest.TestCase
    %TAFCALCULATIONRECORD
    
    properties (Constant)
        %Connect to the test server and database
        DataConnector = af.AFDataConnector(cce.System.CalculationServerName, cce.System.CalculationDBName);
        TemplateName = "CCECalculation";
    end
    properties (Access = private)
        CalculationElement
    end
    
    methods (TestClassSetup)
        function findElementToTest(testcase)
            %FINDELEMENTTOTEST find a Coordinator Record on the AF database for testing
            
            testcase.DataConnector.refreshAFDbCache();
            
            searchName = "CalcSearch";
            [record] = testcase.DataConnector.findRecordsByTemplate(searchName, testcase.TemplateName);
            testcase.CalculationElement = record{1,end};
        end
    end
    
    methods (Test)
        function tConstructor(testcase)
            %TCONSTRUCTOR
            %T1 - Test Constructor returns a single calc record
            
            recordObject = cce.AFCalculationRecord(testcase.CalculationElement, testcase.DataConnector);
            testcase.fatalAssertClass(recordObject, 'cce.AFCalculationRecord');
        end
        
        function tReadRecord(testcase)
            %TREADRECORD test the read record method that updates the local record with
            %changes from the external record on the AF database
            
            % T1: Read the record from the AF database, make local changes without pushing
            % those to the AF database. Update the record with the values stored in the
            % external AF database record. Verify that the local changes were not pus
            recordObject = cce.AFCalculationRecord(testcase.CalculationElement, testcase.DataConnector);
            val = recordObject.getField("CoordinatorID");
            %Make local updates
            recordObject.setField("CoordinatorID", val+1);
            updateVal = recordObject.getField("CoordinatorID");
            %Overwrite local changes with read from external record
            recordObject.readRecord;
            extVal = recordObject.getField("CoordinatorID");
            testcase.verifyEqual(val, extVal);
            testcase.verifyNotEqual(updateVal, val);
        end
        
        function tCommit(testcase)
            %TCOMMIT test that local changes are pushed to the external record on the AF
            %database when commit to the server
            
            % T1: Test that a local change pushed to the server is actually recorded in
            % the AF database record
            recordObject = cce.AFCalculationRecord(testcase.CalculationElement, testcase.DataConnector);
            val = recordObject.getField("CoordinatorID");
            recordObject.setField("CoordinatorID", val+1);
            recordObject.commit;
            updateVal = recordObject.getField("CoordinatorID");
            recordObject.readRecord;
            newDbVal = recordObject.getField("CoordinatorID");
            testcase.verifyNotEqual(val, newDbVal);
            testcase.verifyEqual(updateVal, newDbVal);
            
            % Teardown: do this here to restore the record on the AF database as before
            recordObject.setField("CoordinatorID", val);
            recordObject.commit;
        end
    end
end

