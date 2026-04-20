classdef tAFCalculationOutput < matlab.unittest.TestCase
    %TAFCALCULATIONOUTPUT
    
    properties (Constant, Access = private)
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
        % T1: Test constructor - Should return 1 or more cce.AFCalculationInput object
        function tConstructor(testcase)
            
            outputObjs = cce.AFCalculationOutput(testcase.CalculationElement, testcase.DataConnector);
            testcase.fatalAssertClass(outputObjs, 'cce.AFCalculationOutput');
            testcase.fatalAssertGreaterThanOrEqual(numel(outputObjs), 1);
        end
        
        function tWriting(testcase)
            
            outputObjs = cce.AFCalculationOutput(testcase.CalculationElement, testcase.DataConnector);
            outputObjs(1).writeHistory(1, datetime('now'), "Good");
        end
        
        function tWriteOutputData(testcase)
            
            outputObjs = cce.AFCalculationOutput(testcase.CalculationElement, testcase.DataConnector);
            ts = datetime('now');
            dataOut = struct();
            dataOut.Timestamp = ts;
            for c = 1:numel(outputObjs)
                dataOut.(outputObjs(c).OutputName) = 1;
            end
            outputObjs.writeOutputData(dataOut);
        end
    end
end

