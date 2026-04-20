classdef tAFCalculationDbService < matlab.unittest.TestCase
    %TAFCALCULATIONDBSERVICE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        AFCalcDbService = cce.AFCalculationDbService.getInstance();
    end
    
    methods (TestClassSetup)
        function refreshDB(testcase)
            %REFRESHDB refresh AF DB cache
            
            testcase.AFCalcDbService.DataConnector.refreshAFDbCache();
        end
    end
    
    methods (Test)
        function tFindCalculations(testcase)
            %TFINDCALCULATIONS Test find Calculation elements on the AF database
            
            % T1: Find Calculation elements with a coordinator ID equal to 1
            id = 0;
            [calcRecords, calcInput, calcParameter, calcOutput] = testcase.AFCalcDbService.findCalculations(id);
            testcase.verifyClass(calcRecords, 'cce.AFCalculationRecord');
            testcase.verifyNotEmpty(calcRecords);
            testcase.verifyGreaterThanOrEqual(numel(calcRecords), 1);
            
            testcase.verifyClass(calcInput{end}, 'cce.AFCalculationInput');
            testcase.verifyNotEmpty(calcInput);
            testcase.verifyEqual(numel(calcInput), numel(calcRecords));
            
            testcase.verifyClass(calcParameter{end}, 'cce.AFCalculationParameter');
            testcase.verifyNotEmpty(calcParameter);
            testcase.verifyEqual(numel(calcParameter), numel(calcRecords));
            
            testcase.verifyClass(calcOutput{end}, 'cce.AFCalculationOutput');
            testcase.verifyNotEmpty(calcOutput);
            testcase.verifyEqual(numel(calcOutput), numel(calcRecords));
        end
        
        function tFindAllCalculations(testcase)
            %TFINDALLCALCULATIONS Test find all Calculation elements on the AF database
            
            % T1: Find all Calculation elements on the AF database
            [calcRecords, calcInput, calcParameter, calcOutput] = testcase.AFCalcDbService.findAllCalculations();
            testcase.verifyClass(calcRecords, 'cce.AFCalculationRecord');
            testcase.verifyNotEmpty(calcRecords);
            testcase.verifyGreaterThanOrEqual(numel(calcRecords), 1);
            
            testcase.verifyClass(calcInput{end}, 'cce.AFCalculationInput');
            testcase.verifyNotEmpty(calcInput);
            testcase.verifyEqual(numel(calcInput), numel(calcRecords));
            
            testcase.verifyClass(calcParameter{end}, 'cce.AFCalculationParameter');
            testcase.verifyNotEmpty(calcParameter);
            testcase.verifyEqual(numel(calcParameter), numel(calcRecords));
            
            testcase.verifyClass(calcOutput{end}, 'cce.AFCalculationOutput');
            testcase.verifyNotEmpty(calcOutput);
            testcase.verifyEqual(numel(calcOutput), numel(calcRecords));
        end
    end
end

