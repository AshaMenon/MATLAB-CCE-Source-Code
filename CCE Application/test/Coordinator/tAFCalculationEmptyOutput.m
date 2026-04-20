classdef tAFCalculationEmptyOutput < matlab.unittest.TestCase
    %tAFCalculationEmptyOutput checks that calculation is disabled and set
    %to no result if an empty output is returned.

    % Copyright 2023 Opti-Num Solutions (Pty) Ltd
    % Version: $Format:%ci$ ($Format:%h$)

    %RUN CLEAR CLASSES before running unless already on WACP

    properties
        ElementFolder
        Connector
    end

    methods (TestClassSetup)

        function createTestElementFolder(testCase)
            cce.dev.setCCERoot("dev");
            testCase.Connector = af.AFDataConnector("ons-opcdev.optinum.local", "wacp"); %Create wacp connector (default is LetheConversion)
            testCase.ElementFolder = af.Element.addElementToRoot("ProgrammaticallyCreated", "Connector", testCase.Connector); %Note how this is called since it is a static method - ie does not require existing obj
        end

    end

    methods (TestClassTeardown)
        function teardown(testCase)
            testCase.ElementFolder.deleteElement;
        end
    end

    methods (Test)
        function tMissingWriteNanAs(testCase)

            %Create test element
            testCase.Connector.refreshAFDbCache;
            newElem1 = testCase.ElementFolder.addElement("testEmptyOutputs", "Template", 'emptyOutputCalc');
            newElem1.createPiPoints;
            newElem1.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 16);
            newElem1.setAttributeValue("SensorReference", 21);
            newElem1.setAttributeValue("CalculationState", "Idle")
            newElem1.setAttributeValue("CoordinatorID", 201)
            newElem1.setAttributeValue("ComponentName", "testCalcs")
            newElem1.setAttributeValue("LastCalculationTime", datetime("now", "Format", 'dd/MM/uuuu HH:mm:ss'));
            testCase.ElementFolder.applyAndCheckIn;
            newElem1.createPiPoints;

            %Create and run calculation
            calcToRun = cce.Calculation.createSingleCalc(newElem1, testCase.Connector);

            testLogger = Logger("C:\CCE\calcLogs\nanCalc.log", "noOutCalc", "noOutCalc", "Debug"); %optionally specify specific logger
            calcToRun.runSingleCalculation("Logger", testLogger, "CalcTime", datetime(2023, 06, 12, 24, 0, 0)); %Optionally run calculation at specific time
            newElem1.applyAndCheckIn;

            %Check output results
            res1 = newElem1.getAttributeValue('Output1');
            res2 = newElem1.getAttributeValue('Output2');

            %Check no results were written
            actualRes = [res1, res2];
            expectedRes = ["Pt Created", "Pt Created"];
            testCase.verifyEqual(actualRes, expectedRes);

            %Check states are correct
            calcState = newElem1.getAttributeValue("CalculationState");
            lastError = newElem1.getAttributeValue("LastError");
            testCase.verifyEqual(calcState, cce.CalculationState.SystemDisabled);
            testCase.verifyEqual(lastError, cce.CalculationErrorState.NoResult);

        end

    end
end

