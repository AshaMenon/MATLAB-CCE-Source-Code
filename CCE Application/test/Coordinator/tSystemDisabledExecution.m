classdef tSystemDisabledExecution < matlab.unittest.TestCase
    %tSystemDisabledExecution Tests that a calculation is automatically set
    %to System disabled if Calculation has had 2 consecutive UnhandledException LastError states

    % Copyright 2023 Opti-Num Solutions (Pty) Ltd
    % Version: $Format:%ci$ ($Format:%h$)

    %TODO Neaten, add code to teardown/delete added elements from AF

    properties
        Calculation
        Connector
    end

    methods (TestClassSetup)

        function setCCEConfig(testCase)
            % tc.OriginalCCERootEnv = getenv("CCE_Root");
            % setenv("CCE_Root", tc.CCERootPathForTest);
            % clear classes %#ok<CLCLS>
            % cce.dev.setCCERoot("test")
            testCase.Connector = af.AFDataConnector("ons-opcdev.optinum.local", "wacp"); %Create wacp connector (default is LetheConversion)
        end

    end

    methods (TestClassTeardown)

    end

    methods (Test)
        function tMissingComponent(testCase)
            %tMissingComponent creates a test element with an incorrect ComponentName,
            % to cause an unhandledException and corresponding coordinator

            %Create test element
            
            elementFolder = af.Element.addElementToRoot("ProgrammaticallyCreated", "Connector", testCase.Connector); %Note how this is called since it is a static method - ie does not require existing obj

            newElem = elementFolder.addElement("checkSystemDisabled", "Template", 'sensorAdd');
            newElem.createPiPoints;
            newElem.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 13);
            newElem.setAttributeValue("SensorReference", 21)
            newElem.setAttributeValue("CalculationState", "Idle")
            newElem.setAttributeValue("CoordinatorID", 200)
            newElem.setAttributeValue("ComponentName", "dependentCalcsy")
            newElem.setAttributeValue("LastCalculationTime", datetime("01/01/1970 00:00:00", "Format", 'dd/MM/uuuu HH:mm:ss'));
            elementFolder.applyAndCheckIn;

            %Create coordinator
            coordFolder = af.Element.findByName('CCECoordinator', 'Connector', testCase.Connector);
            coordFolder.refresh;
            newCoord = coordFolder.addElement("CCECoordinator200", "Template", 'CCECoordinator');
            newCoord.createPiPoints;
            newCoord.setAttributeValue("CoordinatorID", 200);
            newCoord.setAttributeValue("ExecutionFrequency", 13)
            newCoord.setAttributeValue("Lifetime", 20)
            newCoord.setAttributeValue("CalculationLoad", 1)
            newCoord.setAttributeValue("CoordinatorState", "Idle")
            coordFolder.applyAndCheckIn;

            %Run coordinator
            cceCoordinator(200);

            %Check if calc state set to system disabled
            elementFolder.refresh;
            calcState = newElem.getAttributeValue("CalculationState");
            testCase.verifyEqual(calcState, cce.CalculationState.SystemDisabled);

            delete(newElem);
            delete(newCoord);
        end



        function tUnhandledException(testCase)
            %tUnhandledException creates an error test element that is not
            %caught

            %Create test element
            elementFolder = af.Element.findByName('ProgrammaticallyCreated','Connector',testCase.Connector);
            elementFolder.refresh;
            newElem = elementFolder.addElement("errorCalc1", "Template", 'errorCalc');
            newElem.createPiPoints;
            newElem.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 9);
            newElem.setAttributeValue("CalculationState", "Idle")
            newElem.setAttributeValue("CoordinatorID", 22)
            newElem.setAttributeValue("CatchError", false)
            newElem.setAttributeValue("LastCalculationTime", datetime("01/01/1970 00:00:00", "Format", 'dd/MM/uuuu HH:mm:ss'));
            
            elementFolder.applyAndCheckIn;

            %Create coordinator
            coordFolder = af.Element.findByName('CCECoordinator','Connector',testCase.Connector);
            coordFolder.refresh;
            newCoord = coordFolder.addElement("CCECoordinator22", "Template", 'CCECoordinator');
            newCoord.createPiPoints;
            newCoord.setAttributeValue("CoordinatorID", 22);
            newCoord.setAttributeValue("ExecutionFrequency", 9)
            newCoord.setAttributeValue("Lifetime", 20)
            newCoord.setAttributeValue("CalculationLoad", 1)
            newCoord.setAttributeValue("CoordinatorState", "Idle")
            coordFolder.applyAndCheckIn;

            %Run coordinator
            cceCoordinator(22);

            %Check if calc state set to system disabled
            elementFolder.refresh;
            calcState = newElem.getAttributeValue("CalculationState");
            testCase.verifyEqual(calcState, cce.CalculationState.SystemDisabled);
        end


        function tHandledException(testCase)
            %tHandledException creates an error test element that is caught

            %Create test element
            elementFolder = af.Element.findByName('ProgrammaticallyCreated','Connector',testCase.Connector);
            elementFolder.refresh;
            newElem = elementFolder.addElement("errorCalc2", "Template", 'errorCalc');
            newElem.createPiPoints;
            newElem.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 8);
            newElem.setAttributeValue("CalculationState", "Idle")
            newElem.setAttributeValue("CoordinatorID", 23)
            newElem.setAttributeValue("CatchError", true)
            newElem.setAttributeValue("LastCalculationTime", datetime("01/01/1970 00:00:00", "Format", 'dd/MM/uuuu HH:mm:ss'));
            
            elementFolder.applyAndCheckIn;

            %Create coordinator
            coordFolder = af.Element.findByName('CCECoordinator','Connector',testCase.Connector);
            coordFolder.refresh;
            newCoord = coordFolder.addElement("CCECoordinator23", "Template", 'CCECoordinator');
            newCoord.createPiPoints;
            newCoord.setAttributeValue("CoordinatorID", 23);
            newCoord.setAttributeValue("ExecutionFrequency", 8)
            newCoord.setAttributeValue("Lifetime", 20)
            newCoord.setAttributeValue("CalculationLoad", 1)
            newCoord.setAttributeValue("CoordinatorState", "Idle")
            coordFolder.applyAndCheckIn;

            %Run coordinator
            cceCoordinator(23);

            %Check if calc state set to system disabled
            elementFolder.refresh;
            calcState = newElem.getAttributeValue("CalculationState");
            testCase.verifyEqual(calcState, cce.CalculationState.SystemDisabled);
        end



    end
end

