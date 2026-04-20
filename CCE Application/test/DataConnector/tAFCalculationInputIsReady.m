classdef tAFCalculationInputIsReady < matlab.unittest.TestCase
    %NOTE - THIS IS NOT A WORKING UNIT TEST
    % This is not a completely defined unit test, but is used to run
    %CalculationInputs isReady. Break points were used to find issues.
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

        function testIsReady(testCase)
            %Create test element 1
            testCase.Connector.refreshAFDbCache;
            newElem1 = testCase.ElementFolder.addElement("testIsReadyBug2", "Template", 'sensorAdd');
            newElem1.createPiPoints;
            newElem1.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 8);
            newElem1.setAttributeValue(["ExecutionParameters","ExecutionIndex"], 2);
            newElem1.setAttributeValue("SensorReference", 23);
            newElem1.setAttributeValue("CalculationState", "Idle")
            newElem1.setAttributeValue("CoordinatorID", 206)
            newElem1.setAttributeValue("ComponentName", "dependentCalcs")
            newElem1.setAttributeValue("LastCalculationTime", datetime("now", "Format", 'dd/MM/uuuu HH:mm:ss'));
            testCase.ElementFolder.applyAndCheckIn;
            newElem1.createPiPoints;

            %Create test element 2
            piStr = "\\ons-opcdev\WACP.testIsReadyBug.OutputSensor;ReadOnly=False;pointtype=Float64";
            newElem2 = testCase.ElementFolder.addElement("testIsReadyBug3", "Template", 'sensorAdd');
            addPIPointReference(newElem2, "SensorReference2", piStr, "Categories", "CCEInput")

            newElem2.createPiPoints;
            newElem2.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 8);
            newElem2.setAttributeValue(["ExecutionParameters","ExecutionIndex"], 2);
            newElem2.setAttributeValue("SensorReference", 23);
            newElem2.setAttributeValue("CalculationState", "Idle")
            newElem2.setAttributeValue("CoordinatorID", 206)
            newElem2.setAttributeValue("ComponentName", "dependentCalcs")
            newElem2.setAttributeValue("LastCalculationTime", datetime("now", "Format", 'dd/MM/uuuu HH:mm:ss'));
            testCase.ElementFolder.applyAndCheckIn;
            newElem2.createPiPoints;

            inputObjs = cce.AFCalculationInput(newElem2.NetElement, testCase.Connector);

            %Write to db dependencies file
            txt = char(newElem2.getAttributeValue('LogParameters|CalculationID') + ", " + "SensorReference2");
            fn = 'D:\Projects\CCE\configFiles\wacpRoot\db\DependentInputsMap.csv';
            writelines(txt, fn, WriteMode = "append")

            inputObjs(2).isReady(newElem2.getAttributeValue('LogParameters|CalculationID'), datetime)
        end

    end

end
