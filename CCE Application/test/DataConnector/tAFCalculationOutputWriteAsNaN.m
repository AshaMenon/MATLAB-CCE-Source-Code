classdef tAFCalculationOutputWriteAsNaN < matlab.unittest.TestCase
    %tCoordLogParametersForwardCompat tests that the coordinator can have log parameters altered from within AF

    % Copyright 2023 Opti-Num Solutions (Pty) Ltd
    % Version: $Format:%ci$ ($Format:%h$)

    %RUN CLEAR CLASSES before running unless already on WACP

    properties
        ElementFolder
        Connector
        % Coordinator
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
            newElem1 = testCase.ElementFolder.addElement("testWriteNanAsCalc2", "Template", 'nanCalc');
            newElem1.createPiPoints;
            newElem1.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 13);
            newElem1.setAttributeValue("SensorReference", 21);
            newElem1.setAttributeValue("CalculationState", "Idle")
            newElem1.setAttributeValue("CoordinatorID", 201)
            newElem1.setAttributeValue("ComponentName", "testCalcs")
            newElem1.setAttributeValue("LastCalculationTime", datetime("now", "Format", 'dd/MM/uuuu HH:mm:ss'));
            testCase.ElementFolder.applyAndCheckIn;
            newElem1.createPiPoints;

            %Create and run calculation
            calcToRun = cce.Calculation.createSingleCalc(newElem1, testCase.Connector);

            testLogger = Logger("C:\CCE\calcLogs\nanCalc.log", "nanCalc", "nanCalc", "Debug"); %optionally specify specific logger
            calcToRun.runSingleCalculation("Logger", testLogger, "CalcTime", datetime(2023, 06, 12, 24, 0, 0)); %Optionally run calculation at specific time
            newElem1.applyAndCheckIn;

            %Check output results
            res1 = newElem1.getAttributeValue('OutputSensorNaN1');
            res2 = newElem1.getAttributeValue('OutputSensorNaN1');
            res3 = newElem1.getAttributeValue('OutputSensorGood1');
            res4 = newElem1.getAttributeValue('OutputSensorGood2');

            actualRes = [res1, res2, res3, res4];
            expectedRes = ["Invalid Float" "Invalid Float" "1" "2"];

            %Compare
            testCase.verifyEqual(actualRes, expectedRes);
        end

        function tWriteNanAsSetToBad(testCase)

            %Create test element
            testCase.Connector.refreshAFDbCache;
            newElem1 = testCase.ElementFolder.addElement("testWriteNanAsCalc2", "Template", 'nanCalc');
            newElem1.createPiPoints;
            newElem1.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 13);
            newElem1.setAttributeValue("SensorReference", 21);
            newElem1.setAttributeValue("CalculationState", "Idle")
            newElem1.setAttributeValue("CoordinatorID", 201)
            newElem1.setAttributeValue("ComponentName", "testCalcs")
            newElem1.setAttributeValue("WriteNanAs", "SetToBad")
            newElem1.setAttributeValue("LastCalculationTime", datetime("now", "Format", 'dd/MM/uuuu HH:mm:ss'));
            testCase.ElementFolder.applyAndCheckIn;
            newElem1.createPiPoints;

            %Create and run calculation
            calcToRun = cce.Calculation.createSingleCalc(newElem1, testCase.Connector);

            testLogger = Logger("C:\CCE\calcLogs\nanCalc.log", "nanCalc", "nanCalc", "Debug"); %optionally specify specific logger
            calcToRun.runSingleCalculation("Logger", testLogger, "CalcTime", datetime(2023, 06, 12, 24, 0, 0)); %Optionally run calculation at specific time
            newElem1.applyAndCheckIn;

            %Check output results
            res1 = newElem1.getAttributeValue('OutputSensorNaN1');
            res2 = newElem1.getAttributeValue('OutputSensorNaN1');
            res3 = newElem1.getAttributeValue('OutputSensorGood1');
            res4 = newElem1.getAttributeValue('OutputSensorGood2');

            actualRes = [res1, res2, res3, res4];
            expectedRes = ["Set to Bad" "Set to Bad" "1" "2"];

            %Compare
            testCase.verifyEqual(actualRes, expectedRes);
        end

        function tWriteNanAsNoOutput(testCase)

            %Create test element
            testCase.Connector.refreshAFDbCache;
            newElem1 = testCase.ElementFolder.addElement("testWriteNanAsCalc3", "Template", 'nanCalc');
            newElem1.createPiPoints;
            newElem1.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 13);
            newElem1.setAttributeValue("SensorReference", 21);
            newElem1.setAttributeValue("CalculationState", "Idle")
            newElem1.setAttributeValue("CoordinatorID", 201)
            newElem1.setAttributeValue("ComponentName", "testCalcs")
            newElem1.setAttributeValue("WriteNanAs", "NoOutput")
            newElem1.setAttributeValue("LastCalculationTime", datetime("now", "Format", 'dd/MM/uuuu HH:mm:ss'));
            testCase.ElementFolder.applyAndCheckIn;
            newElem1.createPiPoints;

            %Create and run calculation
            calcToRun = cce.Calculation.createSingleCalc(newElem1, testCase.Connector);

            testLogger = Logger("C:\CCE\calcLogs\nanCalc.log", "nanCalc", "nanCalc", "Debug"); %optionally specify specific logger
            calcToRun.runSingleCalculation("Logger", testLogger, "CalcTime", datetime(2023, 06, 12, 24, 0, 0)); %Optionally run calculation at specific time
            newElem1.applyAndCheckIn;

            %Check output results
            res1 = newElem1.getAttributeValue('OutputSensorNaN1');
            res2 = newElem1.getAttributeValue('OutputSensorNaN1');
            res3 = newElem1.getAttributeValue('OutputSensorGood1');
            res4 = newElem1.getAttributeValue('OutputSensorGood2');

            actualRes = [res1, res2, res3, res4];
            expectedRes = ["Pt Created" "Pt Created" "1" "2"];

            %Compare
            testCase.verifyEqual(actualRes, expectedRes);
        end

        % createAFValues
        function tCreateAFValuesSystemCode(testCase)
            testCase.Connector.refreshAFDbCache;
            value = {2; "SetToBad"};
            timestamp = [datetime; datetime("yesterday")];
            UOM = [];
            valueStatus = repmat("Good",1,2);

            [afVals] = cce.createAFValues(value, timestamp, valueStatus, UOM, true);

            res1 = afVals.Item(0).Value;
            res2 = string(afVals.Item(1).Value.Name);

            actualRes = [res1, res2];
            expectedRes = [2 "Set to Bad"];

            %Compare
            testCase.verifyEqual(actualRes, expectedRes)
        end
    end
end

