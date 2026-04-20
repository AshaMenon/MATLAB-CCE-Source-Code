classdef tCoordLogParametersForwardCompat < matlab.unittest.TestCase
    %tCoordLogParametersForwardCompat tests that the coordinator can have log parameters altered from within AF 

    % Copyright 2023 Opti-Num Solutions (Pty) Ltd
    % Version: $Format:%ci$ ($Format:%h$)

    %RUN CLEAR CLASSES before running unless already on WACP

    properties
        ElementFolder
        Connector
        Coordinator
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
        function tCoordLognameChange(testCase)
            
            %Create test elements
      
            %Calc1 - System disabled
            newElem1 = testCase.ElementFolder.addElement("calc1", "Template", 'sensorAdd');
            newElem1.createPiPoints;
            newElem1.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 13);
            newElem1.setAttributeValue("SensorReference", 21);
            newElem1.setAttributeValue("CalculationState", "SystemDisabled")
            newElem1.setAttributeValue("CoordinatorID", 201)
            newElem1.setAttributeValue("ComponentName", "dependentCalcs")
            newElem1.setAttributeValue("LastCalculationTime", datetime("01/01/1970 00:00:00", "Format", 'dd/MM/uuuu HH:mm:ss'));
            testCase.ElementFolder.applyAndCheckIn;

            %Calc2 - not disabled
            newElem2 = testCase.ElementFolder.addElement("calc2", "Template", 'sensorAdd');
            newElem2.createPiPoints;
            newElem2.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 13);
            newElem2.setAttributeValue("SensorReference", 22)
            % addFormulaReference(newElem2, "SensorReference5", "A=SensorReference;B=CoordinatorID;[A + B]", "Categories", "CCEInput");
            newElem2.setAttributeValue("CalculationState", "Idle")
            newElem2.setAttributeValue("CoordinatorID", 201)
            newElem2.setAttributeValue("ComponentName", "dependentCalcs")
            newElem2.setAttributeValue("LastCalculationTime", datetime("01/01/1970 00:00:00", "Format", 'dd/MM/uuuu HH:mm:ss'));
            testCase.ElementFolder.applyAndCheckIn;

            %Create coordinator
            coordFolder = af.Element.findByName('CCECoordinator', 'Connector', testCase.Connector);
            coordFolder.refresh;
            testCase.Coordinator = coordFolder.addElement("CCECoordinator201", "Template", 'CCECoordinator');
            testCase.Coordinator.createPiPoints;
            testCase.Coordinator.setAttributeValue("CoordinatorID", 201);
            testCase.Coordinator.setAttributeValue("ExecutionFrequency", 13)
            testCase.Coordinator.setAttributeValue("Lifetime", 20)
            testCase.Coordinator.setAttributeValue("CalculationLoad", 4)
            testCase.Coordinator.setAttributeValue("CoordinatorState", "Idle")
            % testCase.Coordinator.setAttributeValue("ReenableSystemDisabledCalcs", true);
            testCase.Coordinator.setAttributeValue(["LogParameters", "LogLevel"], "trace");
            logFileName = 'unitTestCoord.log';
            testCase.Coordinator.setAttributeValue(["LogParameters", "LogName"], logFileName);
            coordFolder.applyAndCheckIn;

            %Run coordinator
            cceCoordinator(201);
            testCase.ElementFolder.refresh;

            calcState1 = newElem1.getAttributeValue("CalculationState");
            calcState2 = newElem2.getAttributeValue("CalculationState");

            %Check calc states
            expected =  [cce.CalculationState.SystemDisabled, cce.CalculationState.Idle];
            testCase.verifyEqual([calcState1, calcState2], expected);

            %Check log file creation and logging
            testCase.verifyEqual(exist(fullfile(cce.System.LogFolder, logFileName), "file"), 2);
            if exist(fullfile(cce.System.LogFolder, logFileName), "file") == 2
                fId = fopen(fullfile(cce.System.LogFolder, logFileName));
                txt = fscanf(fId, '%s');
                testCase.verifyEqual(isempty(txt), false);
            end

            fclose(fId);
            deleteElement(testCase.Coordinator);
            delete(fullfile(cce.System.LogFolder, logFileName));
        end

        function tFullfileCoordLognameChange(testCase)
            
            %Create test elements
      
            %Calc1 - System disabled
            newElem1 = testCase.ElementFolder.addElement("calc1", "Template", 'sensorAdd');
            newElem1.createPiPoints;
            newElem1.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 13);
            newElem1.setAttributeValue("SensorReference", 21);
            newElem1.setAttributeValue("CalculationState", "SystemDisabled")
            newElem1.setAttributeValue("CoordinatorID", 201)
            newElem1.setAttributeValue("ComponentName", "dependentCalcs")
            newElem1.setAttributeValue("LastCalculationTime", datetime("01/01/1970 00:00:00", "Format", 'dd/MM/uuuu HH:mm:ss'));
            testCase.ElementFolder.applyAndCheckIn;

            %Calc2 - not disabled
            newElem2 = testCase.ElementFolder.addElement("calc2", "Template", 'sensorAdd');
            newElem2.createPiPoints;
            newElem2.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 13);
            newElem2.setAttributeValue("SensorReference", 22)
            % addFormulaReference(newElem2, "SensorReference5", "A=SensorReference;B=CoordinatorID;[A + B]", "Categories", "CCEInput");
            newElem2.setAttributeValue("CalculationState", "Idle")
            newElem2.setAttributeValue("CoordinatorID", 201)
            newElem2.setAttributeValue("ComponentName", "dependentCalcs")
            newElem2.setAttributeValue("LastCalculationTime", datetime("01/01/1970 00:00:00", "Format", 'dd/MM/uuuu HH:mm:ss'));
            testCase.ElementFolder.applyAndCheckIn;

            %Create coordinator
            coordFolder = af.Element.findByName('CCECoordinator', 'Connector', testCase.Connector);
            coordFolder.refresh;
            testCase.Coordinator = coordFolder.addElement("CCECoordinator201", "Template", 'CCECoordinator');
            testCase.Coordinator.createPiPoints;
            testCase.Coordinator.setAttributeValue("CoordinatorID", 201);
            testCase.Coordinator.setAttributeValue("ExecutionFrequency", 13)
            testCase.Coordinator.setAttributeValue("Lifetime", 20)
            testCase.Coordinator.setAttributeValue("CalculationLoad", 4)
            testCase.Coordinator.setAttributeValue("CoordinatorState", "Idle")
            % testCase.Coordinator.setAttributeValue("ReenableSystemDisabledCalcs", true);
            testCase.Coordinator.setAttributeValue(["LogParameters", "LogLevel"], "trace");
            logFileName = 'unitTestCoord.log';
            fullLogName = fullfile(cce.System.LogFolder, logFileName);
            testCase.Coordinator.setAttributeValue(["LogParameters", "LogName"], fullLogName);
            coordFolder.applyAndCheckIn;

            %Run coordinator
            cceCoordinator(201);
            testCase.ElementFolder.refresh;

            calcState1 = newElem1.getAttributeValue("CalculationState");
            calcState2 = newElem2.getAttributeValue("CalculationState");

            %Check calc states
            expected =  [cce.CalculationState.SystemDisabled, cce.CalculationState.Idle];
            testCase.verifyEqual([calcState1, calcState2], expected);

            %Check log file creation and logging
            testCase.verifyEqual(exist(fullLogName, "file"), 2);
            if exist(fullLogName, "file") == 2
                fId = fopen(fullLogName);
                txt = fscanf(fId, '%s');
                testCase.verifyEqual(isempty(txt), false);
            end

            fclose(fId);
            deleteElement(testCase.Coordinator);
            delete(fullLogName);
        end
    end
end

