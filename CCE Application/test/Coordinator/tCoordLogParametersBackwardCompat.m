classdef tCoordLogParametersBackwardCompat < matlab.unittest.TestCase
    %tCoordLogParametersBackwardCompat tests that the coordinator runs
    %successfully with new CCE code, using the old AF element setup - for
    %backwards compatibility purposes.

    % Copyright 2023 Opti-Num Solutions (Pty) Ltd
    % Version: $Format:%ci$ ($Format:%h$)

    %MUST CLEAR CLASSES BEFORE RUN FOR THIS TO WORK
    %REQUIRES CCEBackwardsCompatibilityTest_05_07_2023 database to pass

    properties
        ElementFolder1
        Connector1 %Old setup for backwards compatibility test
        Coordinator1
    end

    methods (TestClassSetup)
        function setEnv(~)
            cce.dev.setCCERoot(fullfile(fileparts(fileparts(fileparts(mfilename("fullpath")))),"configFiles", "backwards"));
        end

        function createTestElementFolder1(testCase)
            testCase.Connector1 = af.AFDataConnector("ons-opcdev.optinum.local", "CCEBackwardsCompatibilityTest_05_07_2023"); %Create wacp connector (default is LetheConversion)
            testCase.ElementFolder1 = af.Element.addElementToRoot("ProgrammaticallyCreated", "Connector", testCase.Connector1); %Note how this is called since it is a static method - ie does not require existing obj
        end

    end

    methods (TestClassTeardown)
        function teardown(testCase)
            testCase.ElementFolder1.deleteElement;
        end
    end

    methods (Test)
        function testBackwardsCompatibility(testCase)
            
            %Create test elements
      
            %Calc1 - System disabled
            newElem1 = testCase.ElementFolder1.addElement("calc1", "Template", 'sensorAdd');
            newElem1.createPiPoints;
            newElem1.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 13);
            newElem1.setAttributeValue("SensorReference", 21);
            newElem1.setAttributeValue("CalculationState", "Idle")
            newElem1.setAttributeValue("CoordinatorID", 201)
            newElem1.setAttributeValue("ComponentName", "dependentCalcs")
            newElem1.setAttributeValue("LastCalculationTime", datetime("01/01/1970 00:00:00", "Format", 'dd/MM/uuuu HH:mm:ss'));
            testCase.ElementFolder1.applyAndCheckIn;

            %Calc2 - not disabled
            newElem2 = testCase.ElementFolder1.addElement("calc2", "Template", 'sensorAdd');
            newElem2.createPiPoints;
            newElem2.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 13);
            newElem2.setAttributeValue("SensorReference", 22)
            addFormulaReference(newElem2, "SensorReference5", "A=SensorReference;B=CoordinatorID;[A + B]", "Categories", "CCEInput");
            newElem2.setAttributeValue("CalculationState", "Idle")
            newElem2.setAttributeValue("CoordinatorID", 201)
            newElem2.setAttributeValue("ComponentName", "dependentCalcs")
            newElem2.setAttributeValue("LastCalculationTime", datetime("01/01/1970 00:00:00", "Format", 'dd/MM/uuuu HH:mm:ss'));
            testCase.ElementFolder1.applyAndCheckIn;

            %Create coordinator
            coordFolder = af.Element.findByName('CCECoordinator', 'Connector', testCase.Connector1);
            coordFolder.refresh;
            testCase.Coordinator1 = coordFolder.addElement("CCECoordinator201", "Template", 'CCECoordinator');
            testCase.Coordinator1.createPiPoints;
            testCase.Coordinator1.setAttributeValue("CoordinatorID", 201);
            testCase.Coordinator1.setAttributeValue("ExecutionFrequency", 13)
            testCase.Coordinator1.setAttributeValue("Lifetime", 20)
            testCase.Coordinator1.setAttributeValue("CalculationLoad", 2)
            testCase.Coordinator1.setAttributeValue("CoordinatorState", "Idle")
            % testCase.Coordinator1.setAttributeValue("ReenableSystemDisabledCalcs", true);
            coordFolder.applyAndCheckIn;

            %Run coordinator
            cceCoordinator(201);
            testCase.ElementFolder1.refresh;

            %Check that calculations ran as expected
            calcState1 = newElem1.getAttributeValue("CalculationState");
            calcState2 = newElem2.getAttributeValue("CalculationState");
            expected =  [cce.CalculationState.Idle, cce.CalculationState.Idle];
            testCase.verifyEqual([calcState1, calcState2], expected);

            lastErr1 = newElem1.getAttributeValue("LastError");
            lastErr2 = newElem2.getAttributeValue("LastError");
            expected = [cce.CalculationErrorState.Good, cce.CalculationErrorState.Good];
            testCase.verifyEqual([lastErr1, lastErr2], expected);

            deleteElement(testCase.Coordinator1);
        end

       


    end
end

