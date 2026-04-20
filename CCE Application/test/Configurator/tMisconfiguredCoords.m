classdef tMisconfiguredCoords < matlab.unittest.TestCase
        
    properties
        Connector = af.AFDataConnector(cce.System.CalculationServerName, cce.System.CalculationDBName);
        Coordinator1
        Coordinator2
        Coordinator3
        Coordinator1Id = 1000;
        Coordinator2Id = 1001;
        Coordinator3Id = 1002;
        Elements
    end
    
    methods (TestClassSetup)
        function setElements(testCase)
            %Create coordinator used in testing
            disp("Creating coordinator 1...")
            coordFolder = af.Element.findByName('CCECoordinator', 'Connector', testCase.Connector);
            coordFolder.refresh;
            coordName = "CCECoordinator" + string(testCase.Coordinator1Id);
            testCase.Coordinator1 = coordFolder.addElement(coordName, "Template", 'CCECoordinator');
            testCase.Coordinator1.createPiPoints;
            testCase.Coordinator1.setAttributeValue("CoordinatorID", testCase.Coordinator1Id);
            testCase.Coordinator1.setAttributeValue("CoordinatorState", "Idle")
            testCase.Coordinator1.applyAndCheckIn;

            disp("Created coordinator 1.")


            disp("Creating coordinator 2...")
            coordName = "CCECoordinator" + string(testCase.Coordinator2Id);
            testCase.Coordinator2 = coordFolder.addElement(coordName, "Template", 'CCECoordinator');
            testCase.Coordinator2.createPiPoints;
            testCase.Coordinator2.setAttributeValue("CoordinatorState", "Idle")
            testCase.Coordinator2.applyAndCheckIn;
            % coordFolder.applyAndCheckIn;
            disp("Created coordinator 2.")

            disp("Creating coordinator 3...")
            coordName = "CCECoordinator" + string(testCase.Coordinator3Id);
            testCase.Coordinator3 = coordFolder.addElement(coordName, "Template", 'CCECoordinator');
            testCase.Coordinator3.createPiPoints;
            testCase.Coordinator3.setAttributeValue("CoordinatorState", "Disabled")
            testCase.Coordinator3.applyAndCheckIn;
            % coordFolder.applyAndCheckIn;
            disp("Created coordinator 3.")

            testCase.Connector.refreshAFDbCache;
        end

    end
    
    methods (TestClassTeardown)

    end
    
    methods (Test)
        function tCoordDeletion(testcase)
            cceConfigurator;

            coord1 = af.Element.findByName("CCECoordinator"+testcase.Coordinator1Id,"Connector",testcase.Connector);
            coord2 = af.Element.findByName("CCECoordinator"+testcase.Coordinator2Id,"Connector",testcase.Connector);
            coord3 = af.Element.findByName("CCECoordinator"+testcase.Coordinator3Id,"Connector",testcase.Connector);

            testcase.verifyFalse(isempty(coord1))
            testcase.verifyEmpty(coord2)
            testcase.verifyEmpty(coord3)

        end      
        
    end
end

