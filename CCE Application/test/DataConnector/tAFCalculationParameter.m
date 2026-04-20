classdef tAFCalculationParameter < matlab.unittest.TestCase
    %TAFCALCULATIONPARAMETER
    
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
        function tConstructor(testcase)
            
            parameterObjs = cce.AFCalculationParameter(testcase.CalculationElement, testcase.DataConnector);
            testcase.fatalAssertClass(parameterObjs, 'cce.AFCalculationParameter');
            testcase.fatalAssertGreaterThanOrEqual(numel(parameterObjs), 1);
        end
        
        function tGetVal(testcase)
            
            parameterObjs = cce.AFCalculationParameter(testcase.CalculationElement, testcase.DataConnector);
            for c = 1:numel(parameterObjs)
                thisParameter = parameterObjs(c);
                val = thisParameter.fetchValue();
                testcase.verifyNotEmpty(val);
            end
        end
        
        function tRetrieveStruct(testcase)
            
            parameterObjs = cce.AFCalculationParameter(testcase.CalculationElement, testcase.DataConnector);
            [parameters] = retrieveParameters(parameterObjs);
            testcase.verifyNotEmpty(parameters);
        end
    end
end

