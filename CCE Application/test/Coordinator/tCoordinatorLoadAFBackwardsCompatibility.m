classdef tCoordinatorLoadAFBackwardsCompatibility < matlab.unittest.TestCase
    %tCoordinatorLoadAF tests that the coordinator can have max load level altered from within AF 

    % Copyright 2023 Opti-Num Solutions (Pty) Ltd
    % Version: $Format:%ci$ ($Format:%h$)

    %RUN CLEAR CLASSES before running

    properties
        ElementFolder
        Connector
        Coordinator1
        Coordinator2
        Coordinator3
    end

    methods (TestClassSetup)

        function setEnv(~)
            cce.dev.setCCERoot(fullfile(fileparts(fileparts(fileparts(mfilename("fullpath")))),"configFiles", "configRootBackwards"));
        end

        function createTestElementFolder(testCase)
            testCase.Connector = af.AFDataConnector("ons-opcdev.optinum.local", "CCETest_05_07_2023");
            testCase.ElementFolder = af.Element.addElementToRoot("ProgrammaticallyCreated", "Connector", testCase.Connector); %Note how this is called since it is a static method - ie does not require existing obj
        end

    end

    methods (TestClassTeardown)
        function teardown(testCase)
            testCase.ElementFolder.deleteElement;
            if ~isempty(testCase.Coordinator1)
                testCase.Coordinator1.deleteElement;
            end
            if ~isempty(testCase.Coordinator2)
                testCase.Coordinator2.deleteElement;
            end
            if ~isempty(testCase.Coordinator3)
                testCase.Coordinator3.deleteElement;
            end
        end
    end

    methods (Test)
        function testChangeExistingCoordinatorLoad(testCase)
            %DOESNT COMPLETLY APPLY TO BACKWARDS COMPAT, CANT CHANGE
            %PARAMETER

            %Create 3 calcs with the same exe freq
            newElem1 = testCase.ElementFolder.addElement("calc1", "Template", 'sensorAdd');
            newElem1.createPiPoints;
            newElem1.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 19);
            newElem1.setAttributeValue("SensorReference", 22);
            newElem1.setAttributeValue("CalculationState", "NotAssigned");
            newElem1.setAttributeValue("ComponentName", "dependentCalcs")
            newElem1.setAttributeValue("LastCalculationTime", datetime("01/01/1970 00:00:00", "Format", 'dd/MM/uuuu HH:mm:ss'));
            testCase.ElementFolder.applyAndCheckIn;

            newElem2 = testCase.ElementFolder.addElement("calc2", "Template", 'sensorAdd');
            newElem2.createPiPoints;
            newElem2.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 19);
            newElem2.setAttributeValue("SensorReference", 24);
            newElem2.setAttributeValue("CalculationState", "NotAssigned");
            newElem2.setAttributeValue("ComponentName", "dependentCalcs")
            newElem2.setAttributeValue("LastCalculationTime", datetime("01/01/1970 00:00:00", "Format", 'dd/MM/uuuu HH:mm:ss'));
            testCase.ElementFolder.applyAndCheckIn;

            newElem3 = testCase.ElementFolder.addElement("calc3", "Template", 'sensorAdd');
            newElem3.createPiPoints;
            newElem3.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 19);
            newElem3.setAttributeValue("SensorReference", 8);
            newElem3.setAttributeValue("CalculationState", "NotAssigned");
            newElem3.setAttributeValue("ComponentName", "dependentCalcs")
            newElem3.setAttributeValue("LastCalculationTime", datetime("01/01/1970 00:00:00", "Format", 'dd/MM/uuuu HH:mm:ss'));
            testCase.ElementFolder.applyAndCheckIn;

            %Call configurator to create coordinators for them
            cceConfigurator;
            testCase.ElementFolder.refresh;

            %Check that they are in same coordinator
            coordIDs = [newElem1.getAttributeValue("CoordinatorID");
                newElem2.getAttributeValue("CoordinatorID")
                newElem3.getAttributeValue("CoordinatorID")];
            testCase.assertEqual(numel(unique(coordIDs)), 1);

            %Rerun configurator
            cceConfigurator;
            testCase.ElementFolder.refresh;

            %Check coordinator load - see that calc has been assigned to
            %different calc
            coordIDs = [newElem1.getAttributeValue("CoordinatorID");
                newElem2.getAttributeValue("CoordinatorID")
                newElem3.getAttributeValue("CoordinatorID")];

            testCase.assertNumElements(unique(coordIDs), 1);
        end

        function testManuallyCreatedCoordinator(testCase)
            %Create test calculation, with specific coordinator and freq
            newElem1 = testCase.ElementFolder.addElement("calc3", "Template", 'sensorAdd');
            newElem1.createPiPoints;
            newElem1.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 7);
            newElem1.setAttributeValue("SensorReference", 22);
            newElem1.setAttributeValue("CalculationState", "Idle");
            newElem1.setAttributeValue("ComponentName", "dependentCalcs")
            newElem1.setAttributeValue("CoordinatorID", "39")
            newElem1.setAttributeValue("LastCalculationTime", datetime("01/01/1970 00:00:00", "Format", 'dd/MM/uuuu HH:mm:ss'));
            testCase.ElementFolder.applyAndCheckIn;


            %Create second test calc, with same freq (not assigned to
            %coordinator)
            newElem2 = testCase.ElementFolder.addElement("calc4", "Template", 'sensorAdd');
            newElem2.createPiPoints;
            newElem2.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 7);
            newElem2.setAttributeValue("SensorReference", 24);
            newElem2.setAttributeValue("CalculationState", "NotAssigned");
            newElem2.setAttributeValue("ComponentName", "dependentCalcs")
            newElem2.setAttributeValue("LastCalculationTime", datetime("01/01/1970 00:00:00", "Format", 'dd/MM/uuuu HH:mm:ss'));
            testCase.ElementFolder.applyAndCheckIn;

            %Create coordinator for calc 1
            coordFolder = af.Element.findByName('CCECoordinator', 'Connector', testCase.Connector);
            coordFolder.refresh;
            testCase.Coordinator2 = coordFolder.addElement("CCECoordinator39", "Template", 'CCECoordinator');
            testCase.Coordinator2.createPiPoints;
            testCase.Coordinator2.setAttributeValue("CoordinatorID", 39);
            testCase.Coordinator2.setAttributeValue("ExecutionFrequency", 7)
            testCase.Coordinator2.setAttributeValue("Lifetime", 20)

            testCase.Coordinator2.setAttributeValue("CoordinatorState", "Idle")
            coordFolder.applyAndCheckIn;

            %Run configurator
            cceConfigurator;

            testCase.ElementFolder.refresh;

            calcCoordIDs = [newElem1.getAttributeValue("CoordinatorID");
                newElem2.getAttributeValue("CoordinatorID")];

            coordID = testCase.Coordinator2.getAttributeValue("CoordinatorID");
            matchCoordIdx = calcCoordIDs == coordID;
            testCase.assertEqual(matchCoordIdx, [true; true]);
        end

        function testUseDefaultVals(testCase)
            %Check that when the default value for coordinator load is
            %used (0), that it the system value is used

            %Create 6 calcs (over the system calcload limit)
            %Create 3 calcs with the same exe freq
            newElem1 = testCase.ElementFolder.addElement("calc5", "Template", 'sensorAdd');
            newElem1.createPiPoints;
            newElem1.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 29);
            newElem1.setAttributeValue("SensorReference", 22);
            newElem1.setAttributeValue("CalculationState", "NotAssigned");
            newElem1.setAttributeValue("ComponentName", "dependentCalcs")
            newElem1.setAttributeValue("LastCalculationTime", datetime("01/01/1970 00:00:00", "Format", 'dd/MM/uuuu HH:mm:ss'));
            testCase.ElementFolder.applyAndCheckIn;

            newElem2 = testCase.ElementFolder.addElement("calc6", "Template", 'sensorAdd');
            newElem2.createPiPoints;
            newElem2.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 29);
            newElem2.setAttributeValue("SensorReference", 24);
            newElem2.setAttributeValue("CalculationState", "NotAssigned");
            newElem2.setAttributeValue("ComponentName", "dependentCalcs")
            newElem2.setAttributeValue("LastCalculationTime", datetime("01/01/1970 00:00:00", "Format", 'dd/MM/uuuu HH:mm:ss'));
            testCase.ElementFolder.applyAndCheckIn;

            newElem3 = testCase.ElementFolder.addElement("calc7", "Template", 'sensorAdd');
            newElem3.createPiPoints;
            newElem3.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 29);
            newElem3.setAttributeValue("SensorReference", 8);
            newElem3.setAttributeValue("CalculationState", "NotAssigned");
            newElem3.setAttributeValue("ComponentName", "dependentCalcs")
            newElem3.setAttributeValue("LastCalculationTime", datetime("01/01/1970 00:00:00", "Format", 'dd/MM/uuuu HH:mm:ss'));
            testCase.ElementFolder.applyAndCheckIn;

            newElem3 = testCase.ElementFolder.addElement("calc8", "Template", 'sensorAdd');
            newElem3.createPiPoints;
            newElem3.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 29);
            newElem3.setAttributeValue("SensorReference", 8);
            newElem3.setAttributeValue("CalculationState", "NotAssigned");
            newElem3.setAttributeValue("ComponentName", "dependentCalcs")
            newElem3.setAttributeValue("LastCalculationTime", datetime("01/01/1970 00:00:00", "Format", 'dd/MM/uuuu HH:mm:ss'));
            testCase.ElementFolder.applyAndCheckIn;

            newElem4 = testCase.ElementFolder.addElement("calc9", "Template", 'sensorAdd');
            newElem4.createPiPoints;
            newElem4.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 29);
            newElem4.setAttributeValue("SensorReference", 8);
            newElem4.setAttributeValue("CalculationState", "NotAssigned");
            newElem4.setAttributeValue("ComponentName", "dependentCalcs")
            newElem4.setAttributeValue("LastCalculationTime", datetime("01/01/1970 00:00:00", "Format", 'dd/MM/uuuu HH:mm:ss'));
            testCase.ElementFolder.applyAndCheckIn;

            newElem5 = testCase.ElementFolder.addElement("calc10", "Template", 'sensorAdd');
            newElem5.createPiPoints;
            newElem5.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 29);
            newElem5.setAttributeValue("SensorReference", 8);
            newElem5.setAttributeValue("CalculationState", "NotAssigned");
            newElem5.setAttributeValue("ComponentName", "dependentCalcs")
            newElem5.setAttributeValue("LastCalculationTime", datetime("01/01/1970 00:00:00", "Format", 'dd/MM/uuuu HH:mm:ss'));
            testCase.ElementFolder.applyAndCheckIn;

            newElem6 = testCase.ElementFolder.addElement("calc11", "Template", 'sensorAdd');
            newElem6.createPiPoints;
            newElem6.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 29);
            newElem6.setAttributeValue("SensorReference", 8);
            newElem6.setAttributeValue("CalculationState", "NotAssigned");
            newElem6.setAttributeValue("ComponentName", "dependentCalcs")
            newElem6.setAttributeValue("LastCalculationTime", datetime("01/01/1970 00:00:00", "Format", 'dd/MM/uuuu HH:mm:ss'));
            testCase.ElementFolder.applyAndCheckIn;

            %Run the configurator
            cceConfigurator;
            testCase.ElementFolder.refresh;

            %Get the coordinator
            %Change coordinator load
            exeFreq = 29;
            coordinators = af.Element.findByTemplate('CCECoordinator', 'Connector', testCase.Connector);
            maxLoad = 0;

            for iCoord = 1:numel(coordinators)
                if coordinators(iCoord).getAttributeValue("ExecutionFrequency") == exeFreq
                    maxLoad = max(maxLoad, coordinators(iCoord).getAttributeValue("CalculationLoad"));
                    coordinators(iCoord).deleteElement;
                end
            end

            %Get the the system calc load:
            testCase.assertLessThanOrEqual(maxLoad, double(cce.System.CoordinatorMaxLoad));
        end

    end
end

