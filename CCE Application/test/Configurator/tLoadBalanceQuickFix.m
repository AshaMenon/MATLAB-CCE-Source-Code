classdef tLoadBalanceQuickFix < matlab.unittest.TestCase
        
    properties
        DataConnector = af.AFDataConnector(cce.System.CalculationServerName, cce.System.CalculationDBName);
        Elements
    end
    
    methods (TestClassSetup)
        function setElements(testcase)
            elems = af.Element.findByName("LoadBalanceQuickFix","Connector",testcase.DataConnector);
            testcase.Elements = elems.Children;

            for elem = testcase.Elements
                elem.setAttributeValue("CalculationState", "NotAssigned");
                elem.setAttributeValue("CoordinatorID", 0);
            end
        end

        function deleteCoordinators(testcase)

            coordParent = af.Element.findByName("CCECoordinator","Connector",testcase.DataConnector);
            coords = coordParent.Children;

            for coord = coords
                coord.deleteElement
            end
        end
    end
    
    methods (TestClassTeardown)

    end
    
    methods (Test)
        function tGetCalculationLoad(testcase)
            execFreqs = [10 100 1000 2000 4000 NaN];
            calcLoads = zeros(length(execFreqs),1);
            expectedLoads = [3; 30; 100; 250; cce.System.CoordinatorMaxLoad; cce.System.CoordinatorMaxLoad];

            for i = 1:length(execFreqs)
                calcLoads(i) = getCalculationLoad(execFreqs(i));
            end

            testcase.assertEqual(calcLoads, expectedLoads)
        end
        
        function tCoordinatorAssignment(testcase)
            cceConfigurator()

            calcElements = testcase.Elements;
            assignedCoords = zeros(length(calcElements),1);

            for i = 1:length(calcElements)
                assignedCoords(i) = calcElements.getAttributeValue("CoordinatorID");
            end

            % check if all calcs assigned
            testcase.assertEqual(nnz(assignedCoords), numel(assignedCoords));
        end
        
        
    end
end

