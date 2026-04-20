classdef stressTestCoordinator < matlab.unittest.TestCase
    %STRESSTESTCOORDINATOR tests that the coordinator runs as expected,
    %with various last calc times, enabled and calc indices, as well as
    %tests the speed of the coordinator. 

    % Copyright 2024 Opti-Num Solutions (Pty) Ltd
    % Version: $Format:%ci$ ($Format:%h$)

    %RUN CLEAR CLASSES before running unless already on WACP

    properties
        ElementFolder af.Element
        Connector af.AFDataConnector
        Calcs (:, 1) af.Element
        Coordinator1 af.Element
        Coordinator2 af.Element
        CreateCalcs = true; %Set this to true on first time running. Set to false if already run, to speed things up. 
    end

    properties (Constant)
        Coordinator1Id = 701;
        Coordinator2Id = 702;
        ExeFreq = 7;
        NumCalcs = 1000;
        CalcIdxArray = reshape(repmat(1:10, 100, 1), [], 1);
    end

    methods (TestClassSetup)

        function createTestElementFolder(testCase)
            %Create test folder, and connector

            cce.dev.setCCERoot("dev");
            testCase.Connector = af.AFDataConnector("ons-opcdev.optinum.local", "wacp"); %Create wacp connector (default is LetheConversion)
            testCase.ElementFolder = af.Element.addElementToRoot("ProgrammaticallyCreatedStressTest", "Connector", testCase.Connector); %Note how this is called since it is a static method - ie does not require existing obj
        end

        function createCalcs(testCase)
            %This programatically creates the calcs used in testing. Sets
            %calc index, and other required attributes. Does not set
            %lastcalctime or calc state.
            global calcs
            % calcs = []
            calcIdxArray = testCase.CalcIdxArray;
            if isempty(calcs)
                calcs = af.Element.empty;
                disp("Creating calcs...")
                
                for iCalc = 1:testCase.NumCalcs
                    calcName = "calc" + string(iCalc);
                    calcs(iCalc) = testCase.ElementFolder.addElement(calcName, 'Template', 'dependentAdd');
                    calcs(iCalc).createPiPoints;
                    calcs(iCalc).setAttributeValue(["ExecutionParameters","ExecutionFrequency"], testCase.ExeFreq);
                    calcs(iCalc).setAttributeValue("Sensor1", 5);
                    calcs(iCalc).setAttributeValue(["ExecutionParameters","ExecutionIndex"], calcIdxArray(iCalc));
                end
            end

            

            dependeeCalcIDs = string.empty;
            dependerCalcIDs = string.empty;
            for iCalc = 1:testCase.NumCalcs
                if calcIdxArray(iCalc) > 1
                    calcIdx = calcIdxArray(iCalc);
                    dependeeCalcID =  calcs(find(calcIdxArray == (calcIdx - 1), 1, "first")).UniqueID; %Find a calc to use as the dependee (must run before). This just needs a lower exe index
                    dependeeCalcIDs = [dependeeCalcIDs, dependeeCalcID];
                    dependerCalcIDs = [dependerCalcIDs, calcs(iCalc).UniqueID];
                end
            end
            testCase.Calcs = calcs;
            testCase.ElementFolder.applyAndCheckIn;

            %Overwrite dependencies file
            writeCalculationDependentInputMap(dependerCalcIDs, dependeeCalcIDs);
            disp("Created calcs.")
        end


        function createCoordinators(testCase)
            %Create coordinator used in testing
            disp("Creating coordinator 1...")
            coordFolder = af.Element.findByName('CCECoordinator', 'Connector', testCase.Connector);
            coordFolder.refresh;
            coordName = "CCECoordinator" + string(testCase.Coordinator1Id);
            testCase.Coordinator1 = coordFolder.addElement(coordName, "Template", 'CCECoordinator');
            testCase.Coordinator1.createPiPoints;
            testCase.Coordinator1.setAttributeValue("CoordinatorID", testCase.Coordinator1Id);
            testCase.Coordinator1.setAttributeValue("ExecutionFrequency", testCase.ExeFreq)
            testCase.Coordinator1.setAttributeValue("Lifetime", 60*5)
            testCase.Coordinator1.setAttributeValue("CalculationLoad", testCase.NumCalcs)
            testCase.Coordinator1.setAttributeValue("CoordinatorState", "Idle")
            testCase.Coordinator1.setAttributeValue(["LogParameters", "LogLevel"], "trace");
            logFileName = 'coordStressTest1.log';
            testCase.Coordinator1.setAttributeValue(["LogParameters", "LogName"], logFileName);
            testCase.Coordinator1.setAttributeValue("ExecutionMode", "Single");
            testCase.Coordinator1.applyAndCheckIn;

            disp("Created coordinator 1.")


            disp("Creating coordinator 2...")
            coordName = "CCECoordinator" + string(testCase.Coordinator2Id);
            testCase.Coordinator2 = coordFolder.addElement(coordName, "Template", 'CCECoordinator');
            testCase.Coordinator2.createPiPoints;
            testCase.Coordinator2.setAttributeValue("CoordinatorID", testCase.Coordinator2Id);
            testCase.Coordinator2.setAttributeValue("ExecutionFrequency", testCase.ExeFreq)
            testCase.Coordinator2.setAttributeValue("Lifetime", 60*5);
            testCase.Coordinator2.setAttributeValue("CalculationLoad", testCase.NumCalcs)
            testCase.Coordinator2.setAttributeValue("CoordinatorState", "Idle")
            testCase.Coordinator2.setAttributeValue(["LogParameters", "LogLevel"], "trace");
            logFileName = 'coordStressTest2.log';
            testCase.Coordinator2.setAttributeValue(["LogParameters", "LogName"], logFileName);
            testCase.Coordinator2.setAttributeValue("ExecutionMode", "Single");
            testCase.Coordinator2.applyAndCheckIn;
            % coordFolder.applyAndCheckIn;
            disp("Created coordinator 2.")

            testCase.Connector.refreshAFDbCache;
        end

    end

    methods (TestClassTeardown)
        function teardown(testCase)
            %Delete element to prevent db clutter, and trickling into other
            %tests - tests r
            % testCase.ElementFolder.deleteElement;
        end
    end

    methods (Test)


        function testCoordinatorFunctionality(testCase)
            %This function tests whether coordinator runs calcs as expected

            %ONLY RUNS 100 calcs, checks the functionality of the
            %coordinator

            disp("Test1...")
            disp("Updating values...")

            %Set specific calc attributes for test
            calcTimeArray = datetime.empty;
            calcTimeArray(1:5) = datetime(2024, 02, 13);
            calcTimeArray(6:testCase.NumCalcs) = datetime(2024, 02, 12); %Needed for function to work

            enabledArray = string.empty;
            enabledArray(1:30) = "Idle";
            enabledArray(31:50) = "Disabled";
            enabledArray(100:120) = "Disabled";
            enabledArray(121:150) = "Idle";
            enabledArray(200:210) = "Idle";

            enabledArray(51:99) = "Disabled";
            enabledArray(151:testCase.NumCalcs) = "Disabled";%Needed for function to work

            coordIDArray(1:testCase.NumCalcs) = testCase.Coordinator2Id;
            coordIDArray(1:50) = testCase.Coordinator1Id;
            coordIDArray(100:150) = testCase.Coordinator1Id;
            coordIDArray(200:210) = testCase.Coordinator1Id;

            testCase.updateCalcAttributes(calcTimeArray, enabledArray, coordIDArray);

            %Run coordinator
            disp("Running coordinator...")
            cceCoordinator(testCase.Coordinator1Id);

            %Retrieve last calc times for comparison
            disp("Getting lastcalc times...")
            for iCalc = 1:testCase.NumCalcs
                calcTime(iCalc) = testCase.Calcs(iCalc).getAttributeValue("LastCalculationTime");
            end

            expSameArray = true(1, testCase.NumCalcs);
            expSameArray(6:30) = false; %Calcs only run here - the rest either have results, or disabled, or dep inputs not ready
            expSameArray(121:150) = false;
            compareCalcTimes = calcTimeArray == calcTime;
            testCase.verifyEqual(compareCalcTimes, expSameArray)
            disp("Done test 1")
        end


        function timeCoordinatorRunIdx1(testCase)
            %This sets all dependent calcs to disabled, and runs the coordinator to see
            %how much backfilling is achieved, for comparitive purposes.

            disp("Test2...")
            disp("Updating values...")

            %Update calc times
            calcTimeArray = datetime.empty;
            calcTimeArray(1:testCase.NumCalcs) = datetime(2024, 02, 12);

            %Disable all calcs other than index 1
            enabledArray = string.empty;
            enabledArray(1:testCase.NumCalcs) = "Idle";
            enabledArray(testCase.CalcIdxArray ~= 1) = "Disabled";

            coordIDArray(1:testCase.NumCalcs) = testCase.Coordinator2Id;

            testCase.updateCalcAttributes(calcTimeArray, enabledArray, coordIDArray);

            %Run coordinator
            tic
            disp("Running coordinator...")
            cceCoordinator(testCase.Coordinator2Id);
            disp("Coord run time: ")
            toc

            disp("Done test 2")
        end


    end

    methods

        function updateCalcAttributes(testCase, calcTimeArray, enabledArray, coordinatorIDArray)

            for iCalc = 1:testCase.NumCalcs
                testCase.Calcs(iCalc).setAttributeValue("CalculationState", enabledArray(iCalc))
                testCase.Calcs(iCalc).setAttributeValue("LastCalculationTime", calcTimeArray(iCalc));
                testCase.Calcs(iCalc).setAttributeValue("CoordinatorID", coordinatorIDArray(iCalc));
            end

            testCase.ElementFolder.applyAndCheckIn;
        end


    end
end

