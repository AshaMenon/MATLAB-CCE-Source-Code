classdef tInputsNetworkIssue < matlab.unittest.TestCase
    %tCalculation_NextOutputTime Test that the nextOutputTime is as
    %expected
    %   Tests to check that the getNextOutputTime function produces the
    %   correct value, nextOutputTime
    
    properties 
        Connector af.AFDataConnector
        Coordinator1 af.Element
        CalcID (1,1) string = "71f222a3-0f65-11ee-91fb-cc2f71c979c0";
        ElementFolder
    end

    properties (Constant)
        Coordinator1Id = 301;
        ExeFreq = 7;
        RetryFrequency = 300;
    end

    methods (TestClassSetup)

        function createTestElementFolder(testCase)
            %Create test folder, and connector

            cce.dev.setCCERoot("dev");
            testCase.Connector = af.AFDataConnector("ons-opcdev.optinum.local", "wacp"); %Create wacp connector (default is LetheConversion)
            testCase.ElementFolder = af.Element.addElementToRoot("ProgrammaticallyCreatedNetworkTest", "Connector", testCase.Connector); %Note how this is called since it is a static method - ie does not require existing obj
        end

        function createCoordinator(testCase)
            %Create coordinator used in testing
            disp("Creating coordinator 1...")
            coordFolder = af.Element.findByName('CCECoordinator', 'Connector', testCase.Connector);
            coordFolder.refresh;
            coordName = "CCECoordinator" + string(testCase.Coordinator1Id);
            testCase.Coordinator1 = coordFolder.addElement(coordName, "Template", 'CCECoordinator');
            testCase.Coordinator1.createPiPoints;
            testCase.Coordinator1.setAttributeValue("CoordinatorID", testCase.Coordinator1Id);
            testCase.Coordinator1.setAttributeValue("ExecutionFrequency", testCase.ExeFreq)
            testCase.Coordinator1.setAttributeValue("Lifetime", 60)
            testCase.Coordinator1.setAttributeValue("CalculationLoad", 2)
            testCase.Coordinator1.setAttributeValue("CoordinatorState", "Idle")
            testCase.Coordinator1.setAttributeValue(["LogParameters", "LogLevel"], "trace");
            logFileName = 'coordNetworkTest1.log';
            testCase.Coordinator1.setAttributeValue(["LogParameters", "LogName"], logFileName);
            testCase.Coordinator1.setAttributeValue("ExecutionMode", "Single");
            testCase.Coordinator1.applyAndCheckIn;

            disp("Created coordinator 1.")

            testCase.Connector.refreshAFDbCache;
        end


    end

    methods (TestClassTeardown)

        function deleteElement(testCase)
            testCase.ElementFolder.deleteElement;
        end
    end

    methods (Test)

        function tWriteandReadData(testCase)
            failTime = datetime('now');

            writeNetworkErrorFailedTime(testCase.CalcID, failTime)
            lastFailedTime = getNetworkFailedTime(testCase.CalcID);

            testCase.verifyEqual(string(failTime), string(lastFailedTime))
        end

        function tRunBeforeFrequency(testCase)

            %Create test element
            testCase.Connector.refreshAFDbCache;
            newElem1 = testCase.ElementFolder.addElement("testNetworkError1", "Template", 'nanCalc');
            newElem1.createPiPoints;
            newElem1.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 13);
            newElem1.setAttributeValue("SensorReference", 21);
            newElem1.setAttributeValue("CalculationState", "Idle")
            newElem1.setAttributeValue("LastError", "NetworkError")
            newElem1.setAttributeValue("CoordinatorID", testCase.Coordinator1Id)
            newElem1.setAttributeValue("ComponentName", "testCalcs")
            newElem1.setAttributeValue("LastCalculationTime", datetime("now", "Format", 'dd/MM/uuuu HH:mm:ss'));
            testCase.ElementFolder.applyAndCheckIn;
            newElem1.createPiPoints;

            calcID = newElem1.getAttributeValue("LogParameters|CalculationID");
            writeNetworkErrorFailedTime(calcID, datetime)

            cceCoordinator(testCase.Coordinator1Id);
            
            lastError = newElem1.getAttributeValue('LastError');

            testCase.verifyEqual(lastError,"NetworkError")

        end

        function tRunAfterFrequency(testCase)
            %Create test element
            testCase.Connector.refreshAFDbCache;
            newElem1 = testCase.ElementFolder.addElement("testNetworkError2", "Template", 'nanCalc');
            newElem1.createPiPoints;
            newElem1.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 13);
            newElem1.setAttributeValue("SensorReference", 21);
            newElem1.setAttributeValue("CalculationState", "Idle")
            newElem1.setAttributeValue("LastError", "NetworkError")
            newElem1.setAttributeValue("CoordinatorID", testCase.Coordinator1Id)
            newElem1.setAttributeValue("ComponentName", "testCalcs")
            newElem1.setAttributeValue("LastCalculationTime", datetime("now", "Format", 'dd/MM/uuuu HH:mm:ss'));
            testCase.ElementFolder.applyAndCheckIn;
            newElem1.createPiPoints;

            calcID = newElem1.getAttributeValue("LogParameters|CalculationID");
            writeNetworkErrorFailedTime(calcID, datetime-minutes(10))

            cceCoordinator(testCase.Coordinator1Id);
            
            lastError = newElem1.getAttributeValue('LastError');

            testCase.verifyEqual(lastError,"Good")
        end


        function tNetworkFailActualOccurance(testCase)
            %Tests that calc is set to NetworkError and kept at idle if
            %connection is bad, instead of system disabled.

            %The PI Server must be turned off and on during the test for this test to work! 
            
            % Testing inputs
            %1. Add break point to line Calculation > getCalculationInputs> inputs{c} = calculations(c).retrieveInputs(outputTime);
            %2. Run test
            %3. When break point is reached, stop the PI Server by running "C:\Program Files\PI\adm\pisrvstop.bat"
            %4. Step code (allow attempt at pulling inputs)
            %5. Restart PI server by running "C:\Program Files\PI\adm\pisrvstart.bat"
            %6. Continue test to completion

            % Testing coordinator loading calculations
            %1. Add break point to line AFCalculationDbService > readRecord> configurationItems = cce.AFCalculationRecord(record, obj.DataConnector, obj.Logger);
            %2. Run test
            %3. When break point is reached, stop the PI Server by running "C:\Program Files\PI\adm\pisrvstop.bat"
            %4. Step code (allow attempt at pulling inputs)
            %5. Restart PI server by running "C:\Program Files\PI\adm\pisrvstart.bat"
            %6. Continue test to completion

            %Create test element
            testCase.Connector.refreshAFDbCache;
            newElem1 = testCase.ElementFolder.addElement("testNetworkError3", "Template", 'nanCalc');
            newElem1.createPiPoints;
            newElem1.setAttributeValue(["ExecutionParameters", "ExecutionFrequency"], 13);
            newElem1.setAttributeValue("SensorReference", 21);
            newElem1.setAttributeValue("CalculationState", "Idle")
            newElem1.setAttributeValue("LastError", "Good")
            newElem1.setAttributeValue("CoordinatorID", testCase.Coordinator1Id)
            newElem1.setAttributeValue("ComponentName", "testCalcs")
            newElem1.setAttributeValue("LastCalculationTime", datetime("yesterday"));
            testCase.ElementFolder.applyAndCheckIn;

            cceCoordinator(testCase.Coordinator1Id);

            lastError = newElem1.getAttributeValue('LastError');
            testCase.verifyEqual(lastError, "NetworkError")

            calcState = newElem1.getAttributeValue('CalculationState');
            testCase.verifyEqual(calcState, "Idle")
        end

        function tBadlyConfiguredInput(testCase)
            %This tests that poorly configured inputs are still turned off

            %Create test element
            testCase.Connector.refreshAFDbCache;
            newElem1 = testCase.ElementFolder.addElement("testNetworkError4", "Template", 'nanCalc');
            newElem1.createPiPoints;
            newElem1.setAttributeValue(["ExecutionParameters", "ExecutionFrequency"], 13);
            newElem1.setAttributeValue("SensorReference", 21);
            newElem1.setAttributeValue("CalculationState", "Idle")
            newElem1.setAttributeValue("LastError", "Good")
            newElem1.setAttributeValue("CoordinatorID", testCase.Coordinator1Id)
            newElem1.setAttributeValue("ComponentName", "testCalcs")
            newElem1.setAttributeValue("LastCalculationTime", datetime("yesterday"));
            testCase.ElementFolder.applyAndCheckIn;
            newElem1.addPIPointReference("SensorReference2",...
                "\\ons-opcdev\WACP.testNetworkError1.SensorReferencessd;ReadOnly=False;pointtype=Float64",...
                "CreateIfMissing", false, "Categories", "CCEInput");
            newElem1.addAttribute(["SensorReference2", "RelativeTimeRange"], "*");
            newElem1.addAttribute(["SensorReference2", "UseTimestamps"], true);

            cceCoordinator(testCase.Coordinator1Id);

            lastError = newElem1.getAttributeValue('LastError');
            testCase.verifyEqual(lastError, "ConfigurationError")

            calcState = newElem1.getAttributeValue('CalculationState');
            testCase.verifyEqual(calcState, "SystemDisabled")
        end
    end
end

