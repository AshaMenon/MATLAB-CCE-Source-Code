classdef tFormulaInputs < matlab.unittest.TestCase
    %tCalculation_NextOutputTime Test that the nextOutputTime is as
    %expected
    %   Tests to check that the getNextOutputTime function produces the
    %   correct value, nextOutputTime
    
    properties 
        Connector af.AFDataConnector
        CalcElement af.Element
    end

    properties (Constant)
        CoordinatorId = 13;
    end

    methods (TestClassSetup)

        function getCalcElement(testCase)
            %Create test folder, and connector

            cce.dev.setCCERoot("dev");
            testCase.Connector = af.AFDataConnector("ons-opcdev.optinum.local", "wacp"); %Create wacp connector (default is LetheConversion)
            testCase.CalcElement = af.Element.findByName("FormlaCalc","Connector",testCase.Connector);
        end
    end

    methods (Test)

        function tNonMatchingInputs(testCase)

            outputTime = datetime("2024-09-26 11:00:00");
            testCase.Connector.refreshAFDbCache;
            testCase.CalcElement.setAttributeValue("LastCalculationTime", outputTime)
            testCase.CalcElement.setAttributeValue("CalculationState", "Idle")

            cceCoordinator(testCase.CoordinatorId);

            calcState = testCase.CalcElement.getAttributeValue("CalculationState");
            lastCalcTime = testCase.CalcElement.getAttributeValue("LastCalculationTime");

            testCase.assertEqual(calcState,"Idle")
            testCase.assertGreaterThan(lastCalcTime,outputTime)

        end
    end
end

