classdef tInvalidAttributes < matlab.unittest.TestCase
    %tCalculation_NextOutputTime Test that the nextOutputTime is as
    %expected
    %   Tests to check that the getNextOutputTime function produces the
    %   correct value, nextOutputTime
    
    properties 
        Connector af.AFDataConnector
        Coordinator1 af.Element
    end

    properties (Constant)
        Coordinator1Id = 310;
        ExeFreq = 7;
        RetryFrequency = 300;
    end

    methods (TestClassSetup)

        function createTestElementFolder(testCase)
            %Create test folder, and connector

            cce.dev.setCCERoot("dev");
            testCase.Connector = af.AFDataConnector("ons-opcdev.optinum.local", "wacp"); %Create wacp connector (default is LetheConversion)
        end

        function createCoordinator(testCase)
            %Create coordinator used in testing
            disp("Creating coordinator 1...")
            coordFolder = af.Element.findByName('CCECoordinator', 'Connector', testCase.Connector);
            coordFolder.refresh;
            coordName = "CCECoordinator" + string(testCase.Coordinator1Id);
            testCase.Coordinator1 = coordFolder.addElement(coordName, "Template", 'CCECoordinator');
            testCase.Coordinator1.createPiPoints;
            testCase.Coordinator1.setAttributeValue("CoordinatorID", testCase.Coordinator1Id);
            testCase.Coordinator1.setAttributeValue("ExecutionFrequency", testCase.ExeFreq)
            testCase.Coordinator1.setAttributeValue("Lifetime", 60)
            testCase.Coordinator1.setAttributeValue("CalculationLoad", 2)
            testCase.Coordinator1.setAttributeValue("CoordinatorState", "Disabled")
            testCase.Coordinator1.setAttributeValue(["LogParameters", "LogLevel"], "trace");
            logFileName = 'coordNetworkTest1.log';
            testCase.Coordinator1.setAttributeValue(["LogParameters", "LogName"], logFileName);
            testCase.Coordinator1.setAttributeValue("ExecutionMode", "Single");
            testCase.Coordinator1.applyAndCheckIn;

            disp("Created coordinator 1.")

            testCase.Connector.refreshAFDbCache;

        end


    end

    methods (TestClassTeardown)

        function deleteElement(testCase)
            testCase.Coordinator1.deleteElement;
        end
    end

    methods (Test)

        function tValidAttribute(testCase)
            
            exitCode = cceCoordinator(testCase.Coordinator1Id);
            testCase.verifyEqual(0, exitCode)
        end

        function tInValidAttribute(testCase)

            testCase.Coordinator1.setAttributeValue("Lifetime", NaN)

            testCase.Connector.refreshAFDbCache;
            exitCode = cceCoordinator(testCase.Coordinator1Id);
            testCase.verifyEqual(-1, exitCode)
        end

    end
end

