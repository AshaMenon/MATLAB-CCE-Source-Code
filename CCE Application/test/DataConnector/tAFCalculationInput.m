classdef tAFCalculationInput < matlab.unittest.TestCase
    %TAFCALCULATIONINPUT
    
    properties (Constant, Access = private)
        %Connect to the test server and database
        DataConnector = af.AFDataConnector("ons-opcdev.optinum.local", "CCETest");
        TemplateName = "CCECalculation";
    end
    properties (Access = private)
        CalculationElement
        TimerangeElement
    end
    
    methods (TestClassSetup)
        function findElementToTest(testcase)
            %FINDELEMENTTOTEST find a Coordinator Record on the AF database for testing
            
            testcase.DataConnector.refreshAFDbCache();
            
            searchName = "CalcSearch";
            [record] = testcase.DataConnector.findRecordsByTemplate(searchName, testcase.TemplateName);
            testcase.CalculationElement = record{1,end};
            inputRecord = testcase.DataConnector.findRecords("TestInput", "Name:'inputSpecTester' Template:CCECalculation");
            assert(~isempty(inputRecord), "COuld not find inputSpecTester record");
            testcase.TimerangeElement = inputRecord{1,1};
        end
    end
    
    methods (Test)
        % T1: Test constructor - Should return 1 or more cce.AFCalculationInput object
        function tConstructor(testcase)
            
            inputObjs = cce.AFCalculationInput(testcase.CalculationElement, testcase.DataConnector);
            testcase.fatalAssertClass(inputObjs, 'cce.AFCalculationInput');
            testcase.fatalAssertGreaterThanOrEqual(numel(inputObjs), 1);
        end
        
        % T2: Test fetching data - Should return some data
        function tFetchData(testcase)
            
            inputObjs = cce.AFCalculationInput(testcase.CalculationElement, testcase.DataConnector);
            fetchEndTime = datetime('now');
            nInputs = numel(inputObjs);
            for c = 1:nInputs
                [value, timestamp, quality] = inputObjs(c).fetchHistory(fetchEndTime);
                testcase.verifyNotEmpty(value);
                testcase.assertNotEmpty(timestamp);
                testcase.assertNotEmpty(quality);
                testcase.verifyClass(timestamp, 'datetime');
                testcase.verifyClass(quality, 'string');
            end
        end
        
        function tRetrieveInputs(testcase)
            
            inputObjs = cce.AFCalculationInput(testcase.CalculationElement, testcase.DataConnector);
            fetchEndTime = datetime('now');
            inputData = inputObjs.retrieveInputData(fetchEndTime);
            
            fields = fieldnames(inputData);
            nInputs = numel(inputObjs);
            for c = 1:nInputs
                fieldName = inputObjs(c).InputName;
                testcase.verifyNotEmpty(inputData.(fieldName));
                tsFieldName = fieldName + "Timestamps";
                if any(ismember(fields, tsFieldName))
                    testcase.assertEqual(size(inputData.(fieldName)), size(inputData.(tsFieldName)))
                    testcase.assertNotEmpty(inputData.(tsFieldName));
                    testcase.verifyClass(inputData.(tsFieldName), 'datetime');
                end
            end
        end

        % tTimeRangeSpecs
        function tTimeRangeSpecs (testcase)
            %tTimeRangeSpecs  Ensure that all time range specifications are accepted
            inputObjs = cce.AFCalculationInput(testcase.TimerangeElement, testcase.DataConnector);
            fetchEndTime = datetime('now')-minutes(10);
            inputData = inputObjs.retrieveInputData(fetchEndTime);
            % Should have three input elements, with their corresponding time ranges
            fields = fieldnames(inputData);
            nInputs = numel(inputObjs);
            for c = 1:nInputs
                fieldName = inputObjs(c).InputName;
                testcase.verifyNotEmpty(inputData.(fieldName));
                tsFieldName = fieldName + "Timestamps";
                if any(ismember(fields, tsFieldName))
                    testcase.assertEqual(size(inputData.(fieldName)), size(inputData.(tsFieldName)))
                    testcase.assertNotEmpty(inputData.(tsFieldName));
                    testcase.verifyClass(inputData.(tsFieldName), 'datetime');
                end
            end
        end
    end
end

