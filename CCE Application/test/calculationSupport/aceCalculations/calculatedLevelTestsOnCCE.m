classdef calculatedLevelTestsOnCCE < matlab.unittest.TestCase
    %Test that old CCE ace calcs work as expected
    
    properties
        CalcElement
        ElementFolder
        DataConnector
    end


    methods (TestClassSetup)
        function createAndPopulateElement(testCase)

            %Create test element
            connector = af.AFDataConnector("ons-opcdev.optinum.local", "wacp"); %Create wacp connector (default is LetheConversion)
            elementFolder = af.Element.addElementToRoot("TestOldAceCalc", "Connector", connector); %Note how this is called since it is a static method - ie does not require existing obj

            newElem = elementFolder.addElement("bpfStats2", "Template", 'calculatedLevel');

            newElem.createPiPoints;
            newElem.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 300);
            newElem.setAttributeValue("CalculationState", "Idle");
            newElem.setAttributeValue("CoordinatorID", 201);
            newElem.setAttributeValue("LastCalculationTime", datetime("01/01/1970 00:00:00", "Format", 'dd/MM/uuuu HH:mm:ss'));

            %Set parameter values - leave as is
            elementFolder.applyAndCheckIn;
            testCase.CalcElement = newElem;
            testCase.ElementFolder = elementFolder;
            testCase.DataConnector = connector;

        end

    end
    methods (TestClassTeardown)
        function deleteElements(testCase)
            testCase.CalcElement.deleteElement;
            testCase.ElementFolder.deleteElement;

        end

    end
    methods (Test)
        function testBPFStatsRunning(testCase)
            %Run single calculation
            calcToRun = cce.Calculation.createSingleCalc(testCase.CalcElement, testCase.DataConnector); %Create calc obj from element
            testLogger = Logger("C:\CCE\calcLogs\testCalcs.log", "testOldAce", "testOldAce", "Trace"); %optionally specify specific logger
            calcToRun.runSingleCalculation("Logger", testLogger) %Run calc obj

            testCase.CalcElement.applyAndCheckIn;

            %Test that calc ran properly
            lastError = testCase.CalcElement.getAttributeValue("LastError");
            testCase.verifyEqual(lastError, "Good");

        end

    end
end