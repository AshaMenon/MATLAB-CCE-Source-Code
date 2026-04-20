classdef tInputFailedInputRetrieval < matlab.unittest.TestCase
    %tInputFailedInputRetrieval tests that if input retrieval fails, the
    %calculation is set to SystemDisabled, with lastErrorState set to ConfigurationError 

    % Copyright 2023 Opti-Num Solutions (Pty) Ltd
    % Version: $Format:%ci$ ($Format:%h$)

    %TODO Neaten, add code to teardown/delete added elements from AF

    properties
        ElementFolder
        Connector
    end

    methods (TestClassSetup)

        function createTestElementFolder(testCase)
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
        function tMultipleCalcs(testCase)
            %tMissingComponent creates a test element with an incorrect ComponentName,
            % to cause an unhandledException and corresponding coordinator

            %Create test element
      
            %Calc1 - should fail
            newElem1 = testCase.ElementFolder.addElement("failedInputTest1", "Template", 'sensorAdd');
            newElem1.createPiPoints;
            newElem1.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 13);
            newElem1.setAttributeValue("SensorReference", 21)
            addFormulaReference(newElem1, "SensorReference6", "A=CANTFind;B=CoordinatorID;[A + B]", "Categories", "CCEInput"); %This should cause failure
            newElem1.setAttributeValue("CalculationState", "Idle")
            newElem1.setAttributeValue("CoordinatorID", 201)
            newElem1.setAttributeValue("ComponentName", "dependentCalcs")
            newElem1.setAttributeValue("LastCalculationTime", datetime("01/01/1970 00:00:00", "Format", 'dd/MM/uuuu HH:mm:ss'));
            testCase.ElementFolder.applyAndCheckIn;

            %Calc2 - shouldnt fail
            newElem2 = testCase.ElementFolder.addElement("failedInputTest2", "Template", 'sensorAdd');
            newElem2.createPiPoints;
            newElem2.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 13);
            newElem2.setAttributeValue("SensorReference", 22)
            addFormulaReference(newElem2, "SensorReference5", "A=SensorReference;B=CoordinatorID;[A + B]", "Categories", "CCEInput"); %Double checking that formula works
            newElem2.setAttributeValue("CalculationState", "Idle")
            newElem2.setAttributeValue("CoordinatorID", 201)
            newElem2.setAttributeValue("ComponentName", "dependentCalcs")
            newElem2.setAttributeValue("LastCalculationTime", datetime("01/01/1970 00:00:00", "Format", 'dd/MM/uuuu HH:mm:ss'));
            testCase.ElementFolder.applyAndCheckIn;

            %Calc3 - shouldnt fail
            newElem3 = testCase.ElementFolder.addElement("failedInputTest3", "Template", 'sensorAdd');
            newElem3.createPiPoints;
            newElem3.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 13);
            newElem3.setAttributeValue("SensorReference", 24)
            newElem3.setAttributeValue("CalculationState", "Idle")
            newElem3.setAttributeValue("CoordinatorID", 201)
            newElem3.setAttributeValue("ComponentName", "dependentCalcs")
            newElem3.setAttributeValue("LastCalculationTime", datetime("01/01/1970 00:00:00", "Format", 'dd/MM/uuuu HH:mm:ss'));
            testCase.ElementFolder.applyAndCheckIn;

            %Calc4 - should fail
            newElem4 = testCase.ElementFolder.addElement("failedInputTest4", "Template", 'sensorAdd');
            newElem4.createPiPoints;
            newElem4.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 13);
            newElem4.setAttributeValue("SensorReference", 3);
            addPIPointReference(newElem4, "SensorReference3",...
                "\\ons-opcdev\WACP.dontCreateThis2;ReadOnly=False;ptclassname=classic;pointtype=Float64",...
                "Categories", "CCEInput");
            newElem4.setAttributeValue("CalculationState", "Idle")
            newElem4.setAttributeValue("CoordinatorID", 201)
            newElem4.setAttributeValue("ComponentName", "dependentCalcs")
            newElem4.setAttributeValue("LastCalculationTime", datetime("01/01/1970 00:00:00", "Format", 'dd/MM/uuuu HH:mm:ss'));
            testCase.ElementFolder.applyAndCheckIn;

            %Create coordinator
            coordFolder = af.Element.findByName('CCECoordinator', 'Connector', testCase.Connector);
            coordFolder.refresh;
            newCoord = coordFolder.addElement("CCECoordinator201", "Template", 'CCECoordinator');
            newCoord.createPiPoints;
            newCoord.setAttributeValue("CoordinatorID", 201);
            newCoord.setAttributeValue("ExecutionFrequency", 13)
            newCoord.setAttributeValue("Lifetime", 20)
            newCoord.setAttributeValue("CalculationLoad", 4)
            newCoord.setAttributeValue("CoordinatorState", "Idle")
            coordFolder.applyAndCheckIn;

            %Run coordinator
            cceCoordinator(201);

            testCase.ElementFolder.refresh;

            calcState1 = newElem1.getAttributeValue("CalculationState");
            calcState2 = newElem2.getAttributeValue("CalculationState");
            calcState3 = newElem3.getAttributeValue("CalculationState");
            calcState4 = newElem4.getAttributeValue("CalculationState");

            lastError1 = newElem1.getAttributeValue("LastError");
            lastError2 = newElem2.getAttributeValue("LastError");
            lastError3 = newElem3.getAttributeValue("LastError");
            lastError4 = newElem4.getAttributeValue("LastError");

            
            expected =  [cce.CalculationState.SystemDisabled, cce.CalculationState.Idle,...
                cce.CalculationState.Idle, cce.CalculationState.SystemDisabled];
            testCase.verifyEqual([calcState1, calcState2, calcState3, calcState4], expected);

            expected =  ["ConfigurationError", "Good", "Good", "ConfigurationError"];
            testCase.verifyEqual([lastError1, lastError2, lastError3, lastError4], expected);

            deleteElement(newCoord);
        end

        function tSingleCalc(testCase)
            %Calc1 - should fail
            newElem1 = testCase.ElementFolder.addElement("failedInputTest5", "Template", 'sensorAdd');
            newElem1.createPiPoints;
            newElem1.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 13);
            newElem1.setAttributeValue("SensorReference", 21)
            addFormulaReference(newElem1, "SensorReference6", "A=CANTFind;B=CoordinatorID;[A + B]", "Categories", "CCEInput"); %This should cause failure
            newElem1.setAttributeValue("CalculationState", "Idle")
            newElem1.setAttributeValue("ComponentName", "dependentCalcs")
            testCase.ElementFolder.applyAndCheckIn;

            calcToRun = cce.Calculation.createSingleCalc(newElem1, testCase.Connector); %Create calc obj from element
            testLogger = Logger("C:\CCE\calcLogs\testCalcs.log", "inputRobustTest", "inputRobustTest", "Debug"); %optionally specify specific logger
            calcToRun.runSingleCalculation("Logger", testLogger); %Run calc obj

            newElem1.applyAndCheckIn;

            calcState1 = newElem1.getAttributeValue("CalculationState");
            lastError1 = newElem1.getAttributeValue("LastError");

            expected =  cce.CalculationState.SystemDisabled;
            testCase.verifyEqual(calcState1, expected);

            expected =  "ConfigurationError";
            testCase.verifyEqual(lastError1, expected);
        end

        function tManualExecutedBackfillCoordinator(testCase)
            %Calc1 - should fail
            newElem1 = testCase.ElementFolder.addElement("failedInputTest6", "Template", 'sensorAdd');
            newElem1.createPiPoints;
            newElem1.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 13);
            newElem1.setAttributeValue("SensorReference", 21)
            addFormulaReference(newElem1, "SensorReference1", "A=CANTFind;B=CoordinatorID;[A + B]", "Categories", "CCEInput"); %This should cause failure
            newElem1.setAttributeValue("CalculationState", "Idle")
            newElem1.setAttributeValue("CoordinatorID", 203)
            newElem1.setAttributeValue("ComponentName", "dependentCalcs")
            newElem1.setAttributeValue("LastCalculationTime", datetime("01/01/1970 00:00:00", "Format", 'dd/MM/uuuu HH:mm:ss'));
            newElem1.setAttributeValue(["BackfillingParameters", "BackfillEndTime"], datetime(2023, 02, 12, 0, 0, 30));
            newElem1.setAttributeValue(["BackfillingParameters", "BackfillStartTime"], datetime(2023, 02, 12, 0, 0, 0));
            newElem1.setAttributeValue(["BackfillingParameters", "BackfillState"], "Running");
            newElem1.setAttributeValue(["BackfillingParameters", "BackfillOverwrite"], "PrimaryOnly");
            testCase.ElementFolder.applyAndCheckIn;

                        %Create coordinator
            coordFolder = af.Element.findByName('CCECoordinator', 'Connector', testCase.Connector);
            coordFolder.refresh;
            newCoord1 = coordFolder.addElement("CCECoordinator203", "Template", 'CCECoordinator');
            newCoord1.createPiPoints;
            newCoord1.setAttributeValue("CoordinatorID", 203);
            newCoord1.setAttributeValue("ExecutionFrequency", 13)
            newCoord1.setAttributeValue("Lifetime", 15)
            newCoord1.setAttributeValue("CalculationLoad", 4)
            newCoord1.setAttributeValue("CoordinatorState", "Idle")
            newCoord1.setAttributeValue("ExecutionMode", "Manual")
            coordFolder.applyAndCheckIn;

            %Run coordinator
            cceCoordinator(203);

            %Calc2 - shouldnt fail
            newElem2 = testCase.ElementFolder.addElement("failedInputTest7", "Template", 'sensorAdd');
            newElem2.createPiPoints;
            newElem2.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 13);
            newElem2.setAttributeValue("SensorReference", 21)
            newElem2.setAttributeValue("CalculationState", "Idle")
            newElem2.setAttributeValue("CoordinatorID", 204)
            newElem2.setAttributeValue("ComponentName", "dependentCalcs")
            newElem2.setAttributeValue("LastCalculationTime", datetime("01/01/1970 00:00:00", "Format", 'dd/MM/uuuu HH:mm:ss'));
            newElem2.setAttributeValue(["BackfillingParameters", "BackfillEndTime"], datetime(2023, 02, 12, 0, 0, 30));
            newElem2.setAttributeValue(["BackfillingParameters", "BackfillStartTime"], datetime(2023, 02, 12, 0, 0, 0));
            newElem2.setAttributeValue(["BackfillingParameters", "BackfillState"], "Running");
            newElem2.setAttributeValue(["BackfillingParameters", "BackfillOverwrite"], "PrimaryOnly");
            testCase.ElementFolder.applyAndCheckIn;

            %Create coordinator
            coordFolder = af.Element.findByName('CCECoordinator', 'Connector', testCase.Connector);
            coordFolder.refresh;
            newCoord2 = coordFolder.addElement("CCECoordinator204", "Template", 'CCECoordinator');
            newCoord2.createPiPoints;
            newCoord2.setAttributeValue("CoordinatorID", 204);
            newCoord2.setAttributeValue("ExecutionFrequency", 13)
            newCoord2.setAttributeValue("Lifetime", 15)
            newCoord2.setAttributeValue("CalculationLoad", 4)
            newCoord2.setAttributeValue("CoordinatorState", "Idle")
            newCoord2.setAttributeValue("ExecutionMode", "Manual")
            coordFolder.applyAndCheckIn;

            %Run coordinator
            cceCoordinator(204);

            bfState1 = newElem1.getAttributeValue(["BackfillingParameters", "BackfillState"]);
            bfErr1 = newElem1.getAttributeValue(["BackfillingParameters", "BackfillLastError"]);
            bfState2 = newElem2.getAttributeValue(["BackfillingParameters", "BackfillState"]);
            bfErr2 = newElem2.getAttributeValue(["BackfillingParameters", "BackfillLastError"]);
            testCase.verifyEqual([bfState1, bfState2], ["Error", "Finished"]);
            testCase.verifyEqual([bfErr1, bfErr2], ["InputConfigInvalid", "Good"]);

            newCoord1.deleteElement;
            newCoord2.deleteElement;
        end



    end
end

