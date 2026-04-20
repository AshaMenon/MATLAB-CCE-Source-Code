classdef tDependentCalc < matlab.unittest.TestCase
    %tCoordLogParametersForwardCompat tests that the coordinator can have log parameters altered from within AF 

    % Copyright 2023 Opti-Num Solutions (Pty) Ltd
    % Version: $Format:%ci$ ($Format:%h$)

    %RUN CLEAR CLASSES before running unless already on WACP

    %NB, the Dependencies file must contain the following:
    %     DependerCalculationID, DependeeCalculationID
    % ce9bdaec-b9ee-11ee-9283-a44cc82276bb,c50eaa8d-b9ee-11ee-9283-a44cc82276bb
    % ce9bdaec-b9ee-11ee-9283-a44cc82276bb,dd3a9bcb-ba79-11ee-9284-a44cc82276bb

    %NB, DependentCalculations in CCETest on WACP must have dependentCalc,
    %dependeeCalc and dependeeCalc2

    properties
        ElementFolder
        Connector
        DependentElem
        DependeeElem
        DependeeElem2
        CalcTime
    end

    methods (TestClassSetup)

        function getElements(testCase)
            cce.dev.setCCERoot("dev");
            testCase.Connector = af.AFDataConnector("ons-opcdev.optinum.local", "wacp"); %Create wacp connector (default is LetheConversion)
            testCase.DependentElem = af.Element.findByPath("\\CCETest\DependentCalculations\dependentCalc", Connector=testCase.Connector);
            testCase.DependeeElem = af.Element.findByPath("\\CCETest\DependentCalculations\dependeeCalc", Connector=testCase.Connector);
            testCase.DependeeElem2 = af.Element.findByPath("\\CCETest\DependentCalculations\dependeeCalc2", Connector=testCase.Connector);
            testCase.CalcTime = datetime("now", "Format", 'dd/MM/uuuu HH:mm:ss');
        end

    end

    methods (TestClassTeardown)
        function teardown(testCase)
            
        end
    end

    methods (Test)
        function tDependeeCalcRan(testCase)
            
            %set up dependee test element
            testCase.Connector.refreshAFDbCache;

            testCase.DependeeElem.setAttributeValue("Sensor1", 21);
            testCase.DependeeElem.setAttributeValue("CalculationState", "Idle")
            testCase.DependeeElem.setAttributeValue("LastCalculationTime", testCase.CalcTime+seconds(90));
            testCase.DependeeElem.setAttributeValue("LastError", "CalcOff");
            testCase.DependeeElem.setAttributeValue("CoordinatorID", 0);
            testCase.DependeeElem.applyAndCheckIn;

            %set up dependee test element
            testCase.Connector.refreshAFDbCache;

            testCase.DependeeElem2.setAttributeValue("Sensor1", 21);
            testCase.DependeeElem2.setAttributeValue("CalculationState", "Idle")
            testCase.DependeeElem2.setAttributeValue("LastCalculationTime", testCase.CalcTime+seconds(90));
            testCase.DependeeElem2.setAttributeValue("LastError", "CalcOff");
            testCase.DependeeElem2.setAttributeValue("CoordinatorID", 0);
            testCase.DependeeElem2.setAttributeValue("OutputSensor", 30);
            testCase.DependeeElem2.applyAndCheckIn;

            %set up dependent test element
            testCase.Connector.refreshAFDbCache;

            testCase.DependentElem.setAttributeValue("CalculationState", "Idle")
            testCase.DependentElem.setAttributeValue("LastCalculationTime", testCase.CalcTime);
            testCase.DependentElem.setAttributeValue("LastError", "CalcOff");
            testCase.DependentElem.setAttributeValue("CoordinatorID", 39);
            testCase.DependentElem.applyAndCheckIn;

            coordNum = 39;

            coordinator = cce.Coordinator.fetchFromDb(coordNum);
            logLevel = cce.System.CoordinatorLogLevel;
            logFileName = cce.System.CoordinatorLogFile;
            logger = CCELogger(logFileName, "Coordinator", sprintf("Coordinator%d", coordNum), logLevel);

            exeTime = testCase.CalcTime;

            outputTime = coordinator.getNextOutputTime(exeTime);
            coordinator.executeCalculations(outputTime, logger);
            testCase.Connector.refreshAFDbCache;

            %Check output results
            lastErr = testCase.DependentElem.getAttributeValue("LastError");

            %Compare
            testCase.verifyEqual(lastErr, "Good");
        end

        function tDependeeCalcNotRan(testCase)

            %set up dependee test element
            testCase.Connector.refreshAFDbCache;
            testCase.DependeeElem.refresh;
            testCase.DependeeElem2.refresh;
            testCase.DependentElem.refresh;

            testCase.DependeeElem.setAttributeValue("CalculationState", "Idle")
            testCase.DependeeElem.setAttributeValue("LastCalculationTime", testCase.CalcTime-hours(2));
            testCase.DependeeElem.setAttributeValue("CoordinatorID", 0);
            testCase.DependeeElem.applyAndCheckIn;

            %set up dependee test element
            testCase.Connector.refreshAFDbCache;

            testCase.DependeeElem2.setAttributeValue("CalculationState", "Idle")
            testCase.DependeeElem2.setAttributeValue("LastCalculationTime", testCase.CalcTime+seconds(90));
            testCase.DependeeElem2.setAttributeValue("CoordinatorID", 0);
            testCase.DependeeElem2.applyAndCheckIn;
            
            %set up dependent test element
            testCase.Connector.refreshAFDbCache;

            testCase.DependentElem.setAttributeValue("CalculationState", "Idle")
            testCase.DependentElem.setAttributeValue("LastCalculationTime", testCase.CalcTime);
            testCase.DependentElem.setAttributeValue("LastError", "CalcOff");
            testCase.DependentElem.setAttributeValue("CoordinatorID", 39);
            testCase.DependentElem.applyAndCheckIn;
            testCase.Connector.refreshAFDbCache;

            coordNum = 39;

            coordinator = cce.Coordinator.fetchFromDb(coordNum);
            logLevel = cce.System.CoordinatorLogLevel;
            logFileName = cce.System.CoordinatorLogFile;
            logger = CCELogger(logFileName, "Coordinator", sprintf("Coordinator%d", coordNum), logLevel);

            exeTime = testCase.CalcTime;

            outputTime = coordinator.getNextOutputTime(exeTime);
            coordinator.executeCalculations(outputTime, logger);

            pause(70) % pause before rerunning coordinator so that failedTimeDiff >= 0.8*(executionFrequency)
            coordinator.executeCalculations(outputTime, logger);

            testCase.Connector.refreshAFDbCache;

            %Check last error results
            lastErr = testCase.DependentElem.getAttributeValue("LastError");

            %Compare
            testCase.verifyEqual(lastErr, "DependentInputsNotReady");
        end

        
    end
end

