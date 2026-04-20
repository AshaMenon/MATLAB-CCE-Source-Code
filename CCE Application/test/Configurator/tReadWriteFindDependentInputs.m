classdef tReadWriteFindDependentInputs < matlab.unittest.TestCase
    %tCoordLogParametersForwardCompat tests that the coordinator can have log parameters altered from within AF

    % Copyright 2023 Opti-Num Solutions (Pty) Ltd
    % Version: $Format:%ci$ ($Format:%h$)

    %RUN CLEAR CLASSES before running unless already on WACP



    properties
        Connector af.AFDataConnector
        ElementFolder af.Element
        Calc0 af.Element
        Calc1 af.Element
        Calc2 af.Element
        Calc3 af.Element
        Calc4 af.Element
        Calc5 af.Element
        Calc6 af.Element
        TestCalcs cce.Calculation
    end

    methods (TestClassSetup)

        function prep(testCase)
            cce.dev.setCCERoot("dev");
            testCase.Connector = af.AFDataConnector("ons-opcdev.optinum.local", "wacp"); %Create wacp connector (default is LetheConversion)
            testCase.ElementFolder = af.Element.addElementToRoot("ProgrammaticallyCreated", "Connector", testCase.Connector); %Note how this is called since it is a static method - ie does not require existing obj
        end

        function createCalculations(testCase)
            %Calc 1 - not in chain at all
            testCase.Calc0 = testCase.ElementFolder.addElement("depTest0", "Template", 'sensorAdd');
            testCase.Calc0.createPiPoints;
            testCase.Calc0.setAttributeValue("CalculationState", "Idle")

            %Calc 1 - indep
            testCase.Calc1 = testCase.ElementFolder.addElement("depTest1", "Template", 'sensorAdd');
            testCase.Calc1.addPIPointReference("Output1", "\\ons-opcdev\WACP.uniqueDepA.SensorReference;ReadOnly=False;pointtype=Float64", "Categories", "CCEOutput");
            testCase.Calc1.addPIPointReference("Output2", "\\ons-opcdev\WACP.uniqueDepAi.SensorReference;ReadOnly=False;pointtype=Float64", "Categories", "CCEOutput");
            testCase.Calc1.createPiPoints;
            testCase.Calc1.setAttributeValue("CalculationState", "Idle")

            %Calc 2 - indep
            testCase.Calc2 = testCase.ElementFolder.addElement("depTest2", "Template", 'sensorAdd');
            testCase.Calc2.addPIPointReference("Output1", "\\ons-opcdev\WACP.uniqueDepB.SensorReference;ReadOnly=False;pointtype=Float64", "Categories", "CCEOutput");
            testCase.Calc2.createPiPoints;
            testCase.Calc2.setAttributeValue("CalculationState", "Idle")

            %Calc 3 - dep on calc 2
            testCase.Calc3 = testCase.ElementFolder.addElement("depTest3", "Template", 'sensorAdd');
            testCase.Calc3.addPIPointReference("SensorRef1", "\\ons-opcdev\WACP.uniqueDepB.SensorReference;ReadOnly=False;pointtype=Float64", "Categories", "CCEInput");
            testCase.Calc3.createPiPoints;
            testCase.Calc3.setAttributeValue("CalculationState", "Idle")

            %Calc 4 - dep on calc 1 and 2
            testCase.Calc4 = testCase.ElementFolder.addElement("depTest4", "Template", 'sensorAdd');
            testCase.Calc4.addPIPointReference("SensorRef1", "\\ons-opcdev\WACP.uniqueDepA.SensorReference;ReadOnly=False;pointtype=Float64", "Categories", "CCEInput");
            testCase.Calc4.addPIPointReference("SensorRef2", "\\ons-opcdev\WACP.uniqueDepB.SensorReference;ReadOnly=False;pointtype=Float64", "Categories", "CCEInput");
            testCase.Calc4.addPIPointReference("Output1", "\\ons-opcdev\WACP.uniqueDepC.SensorReference;ReadOnly=False;pointtype=Float64", "Categories", "CCEOutput");
            testCase.Calc4.createPiPoints;
            testCase.Calc4.setAttributeValue("CalculationState", "Idle")

            %Calc 5 - dep on calc 1 multiple inputs
            testCase.Calc5 = testCase.ElementFolder.addElement("depTest5", "Template", 'sensorAdd');
            testCase.Calc5.addPIPointReference("SensorRef1", "\\ons-opcdev\WACP.uniqueDepA.SensorReference;ReadOnly=False;pointtype=Float64", "Categories", "CCEInput");
            testCase.Calc5.addPIPointReference("SensorRef2", "\\ons-opcdev\WACP.uniqueDepAi.SensorReference;ReadOnly=False;pointtype=Float64", "Categories", "CCEInput");
            testCase.Calc5.createPiPoints;
            testCase.Calc5.setAttributeValue("CalculationState", "Idle")

            %Calc 6 - dep on calc 4
            testCase.Calc6 = testCase.ElementFolder.addElement("depTest6", "Template", 'sensorAdd');
            testCase.Calc6.addPIPointReference("SensorRef1", "\\ons-opcdev\WACP.uniqueDepC.SensorReference;ReadOnly=False;pointtype=Float64", "Categories", "CCEInput");
            testCase.Calc6.createPiPoints;
            testCase.Calc6.setAttributeValue("CalculationState", "Idle")

        end

        function createTestCalcs(testCase)
            %Create some calculations, make them dependent
            calculations = cce.Calculation.fetchFromDb([]);
            [keepIdx, orderIdx] = ismember([calculations.RecordName], ["depTest0", "depTest1", "depTest2", "depTest3", "depTest4", "depTest5", "depTest6"]);
            testCalcs = calculations(keepIdx);
            testCalcs = testCalcs(orderIdx(keepIdx)); %Sort calcs
            testCase.TestCalcs = testCalcs;
        end

    end

    methods (TestClassTeardown)
        function teardown(testCase)
            testCase.ElementFolder.deleteElement;
        end
    end

    methods (Test)


        function tFindWriteReadDependencies(testCase)
            
            testCalcs = testCase.TestCalcs;

            %Confirm direct dependencies
            directDependencies = cce.findDirectDependencies(testCalcs);
            expectedDirectDependencies = {[], [], [], testCalcs(3),...
                [testCalcs(2), testCalcs(3)], testCalcs(2), testCalcs(5)};

            for iCalc = 1:numel(directDependencies)
                if numel(directDependencies{iCalc}) < 2
                    verifyEqual(testCase, directDependencies{iCalc}, expectedDirectDependencies{iCalc})
                else
                    [~, actualIdx] = sort([directDependencies{iCalc}.CalculationID], 'ascend');
                    [~, expIdx] = sort([expectedDirectDependencies{iCalc}.CalculationID], 'ascend');
                    verifyEqual(testCase, directDependencies{iCalc}(actualIdx), expectedDirectDependencies{iCalc}(expIdx));
                end
            end
            

            %Confirm execution order
            [executionOrder, fullDependencyList, isDepChain] = cce.getExecutionOrder(testCalcs, directDependencies);
            expectedExecutionOrder = [1, 1, 1, 2, 2, 2, 3];
            verifyEqual(testCase, executionOrder, expectedExecutionOrder);
            expectedFullDepList = {char.empty, char.empty, char.empty, testCalcs(3),...
                [testCalcs(2), testCalcs(3)], testCalcs(2), [testCalcs(2), testCalcs(3), testCalcs(5)]};
            
            emptyIdx = cellfun(@isempty, fullDependencyList) & cellfun(@isempty, expectedFullDepList);
            fullDependencyList(emptyIdx) = [];
            expectedFullDepList(emptyIdx) = [];
            for iCalc = 1:numel(fullDependencyList)
                if numel(fullDependencyList{iCalc}) < 2
                    verifyEqual(testCase, fullDependencyList{iCalc}, expectedFullDepList{iCalc})
                else
                    [~, actualIdx] = sort([fullDependencyList{iCalc}.CalculationID], 'ascend');
                    [~, expIdx] = sort([expectedFullDepList{iCalc}.CalculationID], 'ascend');
                    verifyEqual(testCase, fullDependencyList{iCalc}(actualIdx), expectedFullDepList{iCalc}(expIdx));
                end
            end

            expectedIsDepChain = logical([0, 1, 1, 1, 1, 1, 1]);
            verifyEqual(testCase, isDepChain, expectedIsDepChain);

            %Write to a test file
            storeDependentInputList(testCalcs, directDependencies);
            filePath = fullfile(cce.System.DbFolder, "DependentInputsMap.csv");
            actualTable = readtable(filePath, 'TextType','string');

            dependerArray = [testCalcs(4).CalculationID;
                testCalcs(5).CalculationID;
                testCalcs(5).CalculationID;
                testCalcs(6).CalculationID;
                testCalcs(7).CalculationID];
            dependeeArray = [testCalcs(3).CalculationID;
                testCalcs(2).CalculationID;
                testCalcs(3).CalculationID;
                testCalcs(2).CalculationID;
                testCalcs(5).CalculationID];

            expectedTable = array2table([dependerArray, dependeeArray],...
                'VariableNames', ["DependerCalculationID", "DependeeCalculationID"]);

            verifyEqual(testCase, unique(actualTable, 'rows', 'sorted'), unique(expectedTable, 'rows', 'sorted'));


            %Read from test file
            expectedDependeeCalcIDs = {cell(0, 1), cell(0, 1), cell(0, 1), {char(testCalcs(3).CalculationID)},...
                {char(testCalcs(2).CalculationID); char(testCalcs(3).CalculationID)},...
                {char(testCalcs(2).CalculationID)}, {char(testCalcs(5).CalculationID)}};
            for iCalc = 1:numel(testCalcs)
                dependeeCalcIDs = readDependentCalcs(testCalcs(iCalc).CalculationID);
                expectedCalcIDs = expectedDependeeCalcIDs{iCalc};
                if ~isempty(dependeeCalcIDs) && ~isempty(expectedCalcIDs) 
                    testCase.verifyEqual(sort([dependeeCalcIDs{:}], 'ascend'),...
                        sort([expectedCalcIDs{:}], 'ascend'));
                end
                
            end

        end


    end
end

