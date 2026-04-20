classdef tCalcExceptionHandling < matlab.unittest.TestCase
    %tCalculation_NextOutputTime Test that the nextOutputTime is as
    %expected
    %   Tests to check that the getNextOutputTime function produces the
    %   correct value, nextOutputTime
    
    properties 
        Connector af.AFDataConnector
        Coordinator1 af.Element
        ElementFolder
    end

    properties (Constant)
        Coordinator1Id = 302;
        ExeFreq = 30;
        RetryFrequency = 300;
    end

    methods (TestClassSetup)

        function createTestElementFolder(testCase)
            %Create test folder, and connector

            cce.dev.setCCERoot("dev");
            testCase.Connector = af.AFDataConnector("ons-opcdev.optinum.local", "wacp"); %Create wacp connector (default is LetheConversion)
            testCase.ElementFolder = af.Element.addElementToRoot("ProgrammaticallyCreatedExceptionTest", "Connector", testCase.Connector); %Note how this is called since it is a static method - ie does not require existing obj
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
            testCase.Coordinator1.setAttributeValue("CoordinatorState", "Idle")
            testCase.Coordinator1.setAttributeValue(["LogParameters", "LogLevel"], "trace");
            logFileName = 'coordOutOfMemoryTest1.log';
            testCase.Coordinator1.setAttributeValue(["LogParameters", "LogName"], logFileName);
            testCase.Coordinator1.setAttributeValue("ExecutionMode", "Single");
            testCase.Coordinator1.applyAndCheckIn;

            disp("Created coordinator 1.")

            testCase.Connector.refreshAFDbCache;
        end

    end

    methods (TestClassTeardown)

        function deleteElement(testCase)
            testCase.ElementFolder.deleteElement;
        end
    end

    methods (Test)

        function tIsIgnorableException(testCase)
            errMessage = "Out of memory.";
            testCase.verifyTrue(isIgnorableException(errMessage))

            errMessage = "Component not found.";
            testCase.verifyFalse(isIgnorableException(errMessage))

        end

        function tLastErrorSetting(testCase)
            errMessage = "Out of memory.";
            lastErr = getLastError(errMessage);

            testCase.verifyEqual(lastErr, cce.CalculationErrorState.OutOfMemory)

            errMessage = "Component not found.";
            lastErr = getLastError(errMessage);

            testCase.verifyEqual(lastErr, cce.CalculationErrorState.UnhandledException)
        end

        function tOutOfMemory(testCase)

            %Create test element
            testCase.Connector.refreshAFDbCache;
            newElem1 = testCase.ElementFolder.addElement("testExceptionHandling1", "Template", 'unhandledExceptionCalc');
            newElem1.createPiPoints;
            newElem1.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 13);
            newElem1.setAttributeValue("ErrorMessage", "Out of memory.")
            newElem1.setAttributeValue("CalculationState", "Idle")
            newElem1.setAttributeValue("LastError", "Good")
            newElem1.setAttributeValue("CoordinatorID", testCase.Coordinator1Id)
            newElem1.setAttributeValue("LastCalculationTime", datetime("now", "Format", 'dd/MM/uuuu HH:mm:ss'));
            testCase.ElementFolder.applyAndCheckIn;
            newElem1.createPiPoints;

            cceCoordinator(testCase.Coordinator1Id);
            
            lastError = newElem1.getAttributeValue('LastError');

            testCase.verifyEqual(lastError,"OutOfMemory")

        end

    end
end

