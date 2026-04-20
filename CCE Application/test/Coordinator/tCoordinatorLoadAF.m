classdef tCoordinatorLoadAF < matlab.unittest.TestCase
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
        Coordinator4
    end

    methods (TestClassSetup)

        function setEnv(~)
            cce.dev.setCCERoot(fullfile(fileparts(fileparts(fileparts(mfilename("fullpath")))),"configFiles", "configRoot"));
        end

        function createTestElementFolder(testCase)
            testCase.Connector = af.AFDataConnector("ons-opcdev.optinum.local", "CCETest");
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


            %Change coordinator load
            coordID = coordIDs(1);
            coordinators = af.Element.findByTemplate('CCECoordinator', 'Connector', testCase.Connector);

            for iCoord = 1:numel(coordinators)
                if coordinators(iCoord).getAttributeValue("CoordinatorID") == coordID
                    testCase.Coordinator1 = coordinators(iCoord);
                    break
                end
            end
            if isempty(testCase.Coordinator1)
                return
            end
            testCase.Coordinator1.setAttributeValue("MaxCalculationLoad", 2)
            testCase.Coordinator1.applyAndCheckIn;

            %Rerun configurator
            cceConfigurator;
            testCase.ElementFolder.refresh;

            %Check coordinator load - see that calc has been assigned to
            %different calc
            coordIDs = [newElem1.getAttributeValue("CoordinatorID");
                newElem2.getAttributeValue("CoordinatorID")
                newElem3.getAttributeValue("CoordinatorID")];

            testCase.assertEqual(numel(unique(coordIDs)), 2);
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
            % testCase.Coordinator2.setAttributeValue("CalculationLoad", 1)
            testCase.Coordinator2.setAttributeValue("MaxCalculationLoad", 1);
            testCase.Coordinator2.setAttributeValue("CoordinatorState", "Idle")
            coordFolder.applyAndCheckIn;

            %Run configurator - check that only calc one is assigned to it
            cceConfigurator;

            testCase.ElementFolder.refresh;

            calcCoordIDs = [newElem1.getAttributeValue("CoordinatorID");
                newElem2.getAttributeValue("CoordinatorID")];

            coordID = testCase.Coordinator2.getAttributeValue("CoordinatorID");
            matchCoordIdx = calcCoordIDs == coordID;
            testCase.assertEqual(matchCoordIdx, [true; false]);
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



        function testShortDependencyMaxCalcLoadResetMultiCoord(testCase)
            %Checks that short chain dependencies aren't split across
            %multiple coordinators, and that no ghost coordinators are
            %created

            %Create 6 calcs (over the system calcload limit)
            %Create 3 calcs with the same exe freq
            newElem1 = testCase.ElementFolder.addElement("calc5", "Template", 'sensorAdd');
            newElem1.createPiPoints;
            newElem1.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 21);
            newElem1.setAttributeValue("SensorReference", 22);
            newElem1.setAttributeValue("CalculationState", "NotAssigned");
            newElem1.setAttributeValue("ComponentName", "dependentCalcs")
            newElem1.setAttributeValue("LastCalculationTime", datetime("01/01/1970 00:00:00", "Format", 'dd/MM/uuuu HH:mm:ss'));
            testCase.ElementFolder.applyAndCheckIn;

            newElem2 = testCase.ElementFolder.addElement("calc6", "Template", 'sensorAdd');
            newElem2.createPiPoints;
            newElem2.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 21);
            newElem2.setAttributeValue("SensorReference", 24);
            configStr = "\\ons-opcdev\CCETest.calc5.OutputSensor;ReadOnly=False";
            addPIPointReference(newElem2, "SensorReference2", configStr, "Categories", "CCEInput");
            newElem2.setAttributeValue("CalculationState", "NotAssigned");
            newElem2.setAttributeValue("ComponentName", "dependentCalcs")
            newElem2.setAttributeValue("LastCalculationTime", datetime("01/01/1970 00:00:00", "Format", 'dd/MM/uuuu HH:mm:ss'));
            testCase.ElementFolder.applyAndCheckIn;

            newElem3 = testCase.ElementFolder.addElement("calc7", "Template", 'sensorAdd');
            newElem3.createPiPoints;
            newElem3.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 21);
            newElem3.setAttributeValue("SensorReference", 8);
            configStr = "\\ons-opcdev\CCETest.calc6.OutputSensor;ReadOnly=False";
            addPIPointReference(newElem3, "SensorReference2", configStr, "Categories", "CCEInput");
            newElem3.setAttributeValue("CalculationState", "NotAssigned");
            newElem3.setAttributeValue("ComponentName", "dependentCalcs")
            newElem3.setAttributeValue("LastCalculationTime", datetime("01/01/1970 00:00:00", "Format", 'dd/MM/uuuu HH:mm:ss'));
            testCase.ElementFolder.applyAndCheckIn;

            newElem4 = testCase.ElementFolder.addElement("calc9", "Template", 'sensorAdd');
            newElem4.createPiPoints;
            newElem4.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 21);
            newElem4.setAttributeValue("SensorReference", 8);
            configStr = "\\ons-opcdev\CCETest.calc7.OutputSensor;ReadOnly=False";
            addPIPointReference(newElem4, "SensorReference2", configStr, "Categories", "CCEInput");
            newElem4.setAttributeValue("CalculationState", "NotAssigned");
            newElem4.setAttributeValue("ComponentName", "dependentCalcs")
            newElem4.setAttributeValue("LastCalculationTime", datetime("01/01/1970 00:00:00", "Format", 'dd/MM/uuuu HH:mm:ss'));
            testCase.ElementFolder.applyAndCheckIn;

            %second coordinator
            newElem11 = testCase.ElementFolder.addElement("calc55", "Template", 'sensorAdd');
            newElem11.createPiPoints;
            newElem11.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 13);
            newElem11.setAttributeValue("SensorReference", 22);
            newElem11.setAttributeValue("CalculationState", "NotAssigned");
            newElem11.setAttributeValue("ComponentName", "dependentCalcs")
            newElem11.setAttributeValue("LastCalculationTime", datetime("01/01/1970 00:00:00", "Format", 'dd/MM/uuuu HH:mm:ss'));
            testCase.ElementFolder.applyAndCheckIn;

            newElem22 = testCase.ElementFolder.addElement("calc66", "Template", 'sensorAdd');
            newElem22.createPiPoints;
            newElem22.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 13);
            newElem22.setAttributeValue("SensorReference", 24);
            configStr = "\\ons-opcdev\CCETest.calc55.OutputSensor;ReadOnly=False";
            addPIPointReference(newElem22, "SensorReference2", configStr, "Categories", "CCEInput");
            newElem22.setAttributeValue("CalculationState", "NotAssigned");
            newElem22.setAttributeValue("ComponentName", "dependentCalcs")
            newElem22.setAttributeValue("LastCalculationTime", datetime("01/01/1970 00:00:00", "Format", 'dd/MM/uuuu HH:mm:ss'));
            testCase.ElementFolder.applyAndCheckIn;

            newElem33 = testCase.ElementFolder.addElement("calc77", "Template", 'sensorAdd');
            newElem33.createPiPoints;
            newElem33.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 13);
            newElem33.setAttributeValue("SensorReference", 8);
            configStr = "\\ons-opcdev\CCETest.calc66.OutputSensor;ReadOnly=False";
            addPIPointReference(newElem33, "SensorReference2", configStr, "Categories", "CCEInput");
            newElem33.setAttributeValue("CalculationState", "NotAssigned");
            newElem33.setAttributeValue("ComponentName", "dependentCalcs")
            newElem33.setAttributeValue("LastCalculationTime", datetime("01/01/1970 00:00:00", "Format", 'dd/MM/uuuu HH:mm:ss'));
            testCase.ElementFolder.applyAndCheckIn;

            newElem44 = testCase.ElementFolder.addElement("calc99", "Template", 'sensorAdd');
            newElem44.createPiPoints;
            configStr = "\\ons-opcdev\CCETest.calc77.OutputSensor;ReadOnly=False";
            addPIPointReference(newElem44, "SensorReference2", configStr, "Categories", "CCEInput");
            newElem44.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 13);
            newElem44.setAttributeValue("CalculationState", "NotAssigned");
            newElem44.setAttributeValue("ComponentName", "dependentCalcs")
            newElem44.setAttributeValue("LastCalculationTime", datetime("01/01/1970 00:00:00", "Format", 'dd/MM/uuuu HH:mm:ss'));
            testCase.ElementFolder.applyAndCheckIn;

            %Delete any coordinators with matching exe freq
            exeFreq = 21;
            exeFreq2 = 13;
            coordinators = af.Element.findByTemplate('CCECoordinator', 'Connector', testCase.Connector);
            for iCoord = 1:numel(coordinators)
                if coordinators(iCoord).getAttributeValue("ExecutionFrequency") == exeFreq || coordinators(iCoord).getAttributeValue("ExecutionFrequency") == exeFreq2
                    coordinators(iCoord).deleteElement;
                    coordinators(iCoord).applyAndCheckIn;
                end
            end

            %Run the configurator for the first time to assign the
            %dependent calcs to the coordinator
            testCase.Connector.refreshAFDbCache;
            cceConfigurator;
            testCase.Connector.refreshAFDbCache;
            testCase.ElementFolder.refresh;

            %Get the coordinator
            %Change coordinator load
            exeFreq = 21;
            exeFreq2 = 13;
            coordinators = af.Element.findByTemplate('CCECoordinator', 'Connector', testCase.Connector);
            x = 0;
            for iCoord = 1:numel(coordinators)
                if coordinators(iCoord).getAttributeValue("ExecutionFrequency") == exeFreq
                    coordinators(iCoord).setAttributeValue("MaxCalculationLoad", 3);
                    coordinators(iCoord).applyAndCheckIn;
                    x = x + 1;
                    usedCoord(x) = coordinators(iCoord);
                end
                if coordinators(iCoord).getAttributeValue("ExecutionFrequency") == exeFreq2
                    coordinators(iCoord).setAttributeValue("MaxCalculationLoad", 3);
                    coordinators(iCoord).applyAndCheckIn;
                    x = x + 1;
                    usedCoord(x) = coordinators(iCoord);
                end
            end

            %There should be 2 coordinators
            testCase.Coordinator1 = usedCoord(1);
            testCase.Coordinator2 = usedCoord(2);
            testCase.verifyEqual(usedCoord(1).getAttributeValue("MaxCalculationLoad"), int32(3));
            testCase.verifyEqual(usedCoord(1).getAttributeValue("CalculationLoad"), int32(4));

            testCase.verifyEqual(usedCoord(2).getAttributeValue("MaxCalculationLoad"), int32(3));
            testCase.verifyEqual(usedCoord(2).getAttributeValue("CalculationLoad"), int32(4));

            %Rerun the configurator, to test that the calcmax load gets
            %reset
            cceConfigurator;
            usedCoord.refresh;
            testCase.verifyEqual(usedCoord(1).getAttributeValue("MaxCalculationLoad"), int32(cce.System.CoordinatorMaxLoad));
            testCase.verifyEqual(usedCoord(1).getAttributeValue("CalculationLoad"), int32(4));

            testCase.verifyEqual(usedCoord(2).getAttributeValue("MaxCalculationLoad"), int32(cce.System.CoordinatorMaxLoad));
            testCase.verifyEqual(usedCoord(2).getAttributeValue("CalculationLoad"), int32(4));

            %Delete the coordinator
            usedCoord(1).deleteElement;
            usedCoord(2).deleteElement;

        end

        function testShortDependencyMaxCalcLoadReset(testCase)
            %Checks that short chain dependencies aren't split across
            %multiple coordinators, and that no ghost coordinators are
            %created

            %Create 6 calcs (over the system calcload limit)
            %Create 3 calcs with the same exe freq
            newElem1 = testCase.ElementFolder.addElement("calc5", "Template", 'sensorAdd');
            newElem1.createPiPoints;
            newElem1.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 21);
            newElem1.setAttributeValue("SensorReference", 22);
            newElem1.setAttributeValue("CalculationState", "NotAssigned");
            newElem1.setAttributeValue("ComponentName", "dependentCalcs")
            newElem1.setAttributeValue("LastCalculationTime", datetime("01/01/1970 00:00:00", "Format", 'dd/MM/uuuu HH:mm:ss'));
            testCase.ElementFolder.applyAndCheckIn;

            newElem2 = testCase.ElementFolder.addElement("calc6", "Template", 'sensorAdd');
            newElem2.createPiPoints;
            newElem2.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 21);
            newElem2.setAttributeValue("SensorReference", 24);
            configStr = "\\ons-opcdev\CCETest.calc5.OutputSensor;ReadOnly=False";
            addPIPointReference(newElem2, "SensorReference2", configStr, "Categories", "CCEInput");
            newElem2.setAttributeValue("CalculationState", "NotAssigned");
            newElem2.setAttributeValue("ComponentName", "dependentCalcs")
            newElem2.setAttributeValue("LastCalculationTime", datetime("01/01/1970 00:00:00", "Format", 'dd/MM/uuuu HH:mm:ss'));
            testCase.ElementFolder.applyAndCheckIn;

            newElem3 = testCase.ElementFolder.addElement("calc7", "Template", 'sensorAdd');
            newElem3.createPiPoints;
            newElem3.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 21);
            newElem3.setAttributeValue("SensorReference", 8);
            configStr = "\\ons-opcdev\CCETest.calc6.OutputSensor;ReadOnly=False";
            addPIPointReference(newElem3, "SensorReference2", configStr, "Categories", "CCEInput");
            newElem3.setAttributeValue("CalculationState", "NotAssigned");
            newElem3.setAttributeValue("ComponentName", "dependentCalcs")
            newElem3.setAttributeValue("LastCalculationTime", datetime("01/01/1970 00:00:00", "Format", 'dd/MM/uuuu HH:mm:ss'));
            testCase.ElementFolder.applyAndCheckIn;

            newElem4 = testCase.ElementFolder.addElement("calc9", "Template", 'sensorAdd');
            newElem4.createPiPoints;
            newElem4.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 21);
            newElem4.setAttributeValue("SensorReference", 8);
            configStr = "\\ons-opcdev\CCETest.calc7.OutputSensor;ReadOnly=False";
            addPIPointReference(newElem4, "SensorReference2", configStr, "Categories", "CCEInput");
            newElem4.setAttributeValue("CalculationState", "NotAssigned");
            newElem4.setAttributeValue("ComponentName", "dependentCalcs")
            newElem4.setAttributeValue("LastCalculationTime", datetime("01/01/1970 00:00:00", "Format", 'dd/MM/uuuu HH:mm:ss'));
            testCase.ElementFolder.applyAndCheckIn;

            %Run the configurator for the first time to assign the
            %dependent calcs to the coordinator
            cceConfigurator;
            testCase.ElementFolder.refresh;

            %Get the coordinator
            %Change coordinator load
            exeFreq = 21;
            coordinators = af.Element.findByTemplate('CCECoordinator', 'Connector', testCase.Connector);

            for iCoord = 1:numel(coordinators)
                if coordinators(iCoord).getAttributeValue("ExecutionFrequency") == exeFreq
                    coordinators(iCoord).setAttributeValue("MaxCalculationLoad", 3);
                    coordinators(iCoord).applyAndCheckIn;
                    usedCoord = coordinators(iCoord);
                end
            end
            testCase.assertEqual(usedCoord.getAttributeValue("MaxCalculationLoad"), int32(3));
            testCase.assertEqual(usedCoord.getAttributeValue("CalculationLoad"), int32(4));

            %Rerun the configurator, to test that the calcmax load gets
            %reset
            cceConfigurator;
            usedCoord.refresh;
            testCase.assertEqual(usedCoord.getAttributeValue("MaxCalculationLoad"), int32(cce.System.CoordinatorMaxLoad));
            testCase.assertEqual(usedCoord.getAttributeValue("CalculationLoad"), int32(4));

            %Delete the coordinator
            usedCoord.deleteElement;

            %Get the the system calc load:
            % testCase.assertLessThanOrEqual(maxLoad, double(cce.System.CoordinatorMaxLoad));

        end
    end
end

