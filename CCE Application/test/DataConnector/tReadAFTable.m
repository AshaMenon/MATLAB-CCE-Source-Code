classdef tReadAFTable < matlab.unittest.TestCase
    %TREADAFTABLE
    
    properties (Constant, Access = private)
        DataConnector = af.AFDataConnector("ons-opcdev.optinum.local", "WACP");
    end
    properties (Access = private)
        TestTable
        TestTable2
        TableName1 = "TestTable";
        TableName2 = "TestTable2";
        TableName3 = "TestTbl";
        
    end
    
    methods (TestClassSetup)
        function setUpTestTable(testcase)
            testTbl = table;

            testTbl.Description = "Test string";
            testTbl.Bool = false;
            testTbl.Value = 0;
            testTbl.Date = datetime('2024-03-04 00:00:00');

            %Table 1 contains items
            testcase.TestTable = testTbl;

            %Table 2 is empty
            testTbl(1, :) = [];
            testcase.TestTable2 = testTbl;

            testcase.DataConnector.refreshAFDbCache;
        end
    end
    
    methods (Test)

        function tReadTable(testcase)
            
            outputTbl = testcase.DataConnector.getTable(testcase.TableName1);

            testcase.verifyEqual(outputTbl, testcase.TestTable)
        end
        
        function tNonExistantTable(testcase)
            
            outputTbl = testcase.DataConnector.getTable(testcase.TableName3);
            emptyTbl = table;

            testcase.verifyEqual(outputTbl, emptyTbl)
        end

        function tReadEmptyTable(testcase)
            outputTbl = testcase.DataConnector.getTable(testcase.TableName2);
            emptyTbl = testcase.TestTable2;

            testcase.verifyEqual(isempty(outputTbl), isempty(emptyTbl))


        end
        
    end
end

