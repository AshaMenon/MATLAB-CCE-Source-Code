classdef tBackfillSkip < matlab.unittest.TestCase
    
    properties
        ElementFolder af.Element
        Connector af.AFDataConnector
        Calc (1, 1) af.Element
        Coordinator1 af.Element
    end

    properties (Constant)
        Coordinator1Id = 801;
        ExeFreq = 30;
        NumCalcs = 1;
        NumMissedRuns = 50;
    end

    methods(TestClassSetup)
        function createTestElementFolder(testCase)
            %Create test folder, and connector

            cce.dev.setCCERoot("dev");
            testCase.Connector = af.AFDataConnector("ons-opcdev.optinum.local", "wacp"); %Create wacp connector (default is LetheConversion)
            testCase.ElementFolder = af.Element.addElementToRoot("BackfillSkipTest", "Connector", testCase.Connector); %Note how this is called since it is a static method - ie does not require existing obj
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
            testCase.Coordinator1.setAttributeValue("Lifetime", testCase.ExeFreq)
            testCase.Coordinator1.setAttributeValue("CalculationLoad", testCase.NumCalcs)
            testCase.Coordinator1.setAttributeValue("CoordinatorState", "Idle")
            testCase.Coordinator1.setAttributeValue(["LogParameters", "LogLevel"], "trace");
            logFileName = 'coordSkipBackfill1.log';
            testCase.Coordinator1.setAttributeValue(["LogParameters", "LogName"], logFileName);
            testCase.Coordinator1.setAttributeValue("ExecutionMode", "Single");
            testCase.Coordinator1.applyAndCheckIn;

            disp("Created coordinator 1.")
        end

        function createCalculations(testCase)
            disp("Creating calculation")

            testCase.Connector.refreshAFDbCache;
            newElem1 = testCase.ElementFolder.addElement("skipBackfillTest2", "Template", 'dependentAdd');
            newElem1.createPiPoints;
            newElem1.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], testCase.ExeFreq);
            newElem1.setAttributeValue(["BackfillingParameters","MissedRunsThreshold"], testCase.NumMissedRuns);
            newElem1.setAttributeValue("Sensor1", 21);
            newElem1.setAttributeValue("CalculationState", "Idle")
            newElem1.setAttributeValue("CoordinatorID", testCase.Coordinator1Id)
            testCase.ElementFolder.applyAndCheckIn;
            newElem1.createPiPoints;
            testCase.Calc = newElem1;

            disp("Calculation created")
        end
    end
    
    methods(TestMethodSetup)
        % Setup for each test
    end
    
    methods(Test)
        % Test methods
        
        function testSkipDisabled(testCase)
            nowTime = datetime;
            testCase.Calc.setAttributeValue("LastCalculationTime", nowTime - caldays(10));
            testCase.Calc.setAttributeValue(["BackfillingParameters","SkipBackfill"], false);
            cceCoordinator(testCase.Coordinator1Id);

            lastCalcTime = testCase.Calc.getAttributeValue('LastCalculationTime');

            testCase.verifyLessThan(lastCalcTime,nowTime)
        end

        function testSkipEnabled(testCase)
            nowTime = datetime;
            testCase.Calc.setAttributeValue("LastCalculationTime", nowTime - caldays(10));
            testCase.Calc.setAttributeValue(["BackfillingParameters","SkipBackfill"], true);

            cceCoordinator(testCase.Coordinator1Id);

            lastCalcTime = testCase.Calc.getAttributeValue('LastCalculationTime');
            testCase.verifyGreaterThan(lastCalcTime, nowTime - seconds(testCase.ExeFreq))
        end

        function testWithinThreshold(testCase)
            nowTime = datetime;
            secsBack = (testCase.NumMissedRuns - 2)*testCase.ExeFreq;
            testCase.Calc.setAttributeValue("LastCalculationTime", nowTime - seconds(secsBack));
            testCase.Calc.setAttributeValue(["BackfillingParameters","SkipBackfill"], true);

            cceCoordinator(testCase.Coordinator1Id);

            lastCalcTime = testCase.Calc.getAttributeValue('LastCalculationTime');
            testCase.verifyLessThan(lastCalcTime,nowTime)
        end
    end
    
end