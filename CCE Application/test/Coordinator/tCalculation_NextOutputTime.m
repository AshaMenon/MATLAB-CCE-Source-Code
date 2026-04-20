classdef tCalculation_NextOutputTime < matlab.unittest.TestCase
    %tCalculation_NextOutputTime Test that the nextOutputTime is as
    %expected
    %   Tests to check that the getNextOutputTime function produces the
    %   correct value, nextOutputTime
    
    properties (TestParameter)
        %lastCalculationTime at midnight
        lastCalculationTime1 = {datetime(2021, 8, 16, 0, 0, 0)}; % 16 Aug 2021 00:00:00
        offset1 = {minutes(10)};
        frequency1 = {minutes(60)};
        
        %Offset greater than frequency
        lastCalculationTime2 = {datetime(2021, 8, 16, 0, 0, 0)}; % 16 Aug 2021 00:00:00
        offset2 = {minutes(70)};
        frequency2 = {minutes(60)};
        
        %lastCalculationTime at hour below 30 minutes
        lastCalculationTime3 = {datetime(2021, 8, 16, 17, 8, 32)}; %16 Aug 2021 17:08:32
        offset3 = {minutes(30)};
        frequency3 = {minutes(60)};
        
        %lastCalculationTime at hour above 30 minutes
        lastCalculationTime4 = {datetime(2021, 8, 16, 17, 40, 11)}; % 16 Aug 2021 17:40:11
        offset4 = {minutes(30)};
        frequency4 = {minutes(60)};
        
        %frequency less than an hour
        lastCalculationTime5 = {datetime(2021, 8, 16, 02, 10, 18)}; % 16 Aug 2021 02:10:18
        offset5 = {minutes(30)};
        frequency5 = {minutes(40)};
        
        %frequency greater than an hour
        lastCalculationTime6 = {datetime(2021, 8, 16, 02, 40, 20)}; % 16 Aug 2021 02:40:20
        offset6 = {minutes(30)};
        frequency6 = {minutes(70)};
        
        %lastCalculationTime equidistant between outputTimes
        lastCalculationTime7 = {datetime(2021, 8, 16, 2, 0, 0)}; % 16 Aug 2021 02:00:00
        offset7 = {minutes(30)};
        frequency7 = {minutes(60)};
        
        %different lastCalculationTime 
        lastCalculationTime8 = {datetime(2021, 8, 14, 15, 07, 0)}; % 14 Aug 2021 15:07:00
        offset8 = {minutes(20)};
        frequency8 = {minutes(30)};
    end
    
    methods (Test)
        function tMidnightLastCalculationTime(testCase, lastCalculationTime1, offset1, frequency1)
            actual = cce.getNextOutputTime(lastCalculationTime1, offset1, frequency1);
            expected = datetime(2021, 8, 16, 0, 10, 0); % 16 Aug 2021 00:10:00
            
            testCase.verifyEqual(actual, expected);
        end
        
        function tOffsetGreaterThanFrequency(testCase, lastCalculationTime2, offset2, frequency2)
            actual = cce.getNextOutputTime(lastCalculationTime2, offset2, frequency2);
            expected = datetime(2021, 8, 16, 0, 10, 0); % 16 Aug 2021 00:10:00
            
            testCase.verifyEqual(actual, expected);
        end
        
        function tLastCalculationTimeBelowHalfPast(testCase, lastCalculationTime3, offset3, frequency3)
            actual = cce.getNextOutputTime(lastCalculationTime3, offset3, frequency3);
            expected = datetime(2021, 8, 16, 17, 30, 0); % 16 Aug 2021 17:30:00
            
            testCase.verifyEqual(actual, expected);
        end
        
        function tLastCalculationTimeAboveHalfPast(testCase, lastCalculationTime4, offset4, frequency4)
            actual = cce.getNextOutputTime(lastCalculationTime4, offset4, frequency4);
            expected = datetime(2021, 8, 16, 18, 30, 0); % 16 Aug 2021 18:30:00
            
            testCase.verifyEqual(actual, expected);
        end
        
        function tFrequencyLessThanAnHour(testCase, lastCalculationTime5, offset5, frequency5)
            actual = cce.getNextOutputTime(lastCalculationTime5, offset5, frequency5);
            expected = datetime(2021, 8, 16, 2, 30, 0); % 16 Aug 2021 02:30:00
            
            testCase.verifyEqual(actual, expected);
        end
        
        function tFrequencyGreaterThanAnHour(testCase, lastCalculationTime6, offset6, frequency6)
            actual = cce.getNextOutputTime(lastCalculationTime6, offset6, frequency6);
            expected = datetime(2021, 8, 16, 2, 50, 0); % 16 Aug 2021 02:50:00
            
            testCase.verifyEqual(actual, expected);
        end
        
        function tLastCalculationTimeEquidistant(testCase, lastCalculationTime7, offset7, frequency7)
            actual = cce.getNextOutputTime(lastCalculationTime7, offset7, frequency7);
            expected = datetime(2021, 8, 16, 2, 30, 0); % 16 Aug 2021 02:30:00
            
            testCase.verifyEqual(actual, expected);
        end
        
        function tDifferentLastCalculationTime(testCase, lastCalculationTime8, offset8, frequency8)
            actual = cce.getNextOutputTime(lastCalculationTime8, offset8, frequency8);
            expected = datetime(2021, 8, 14, 15, 20, 0); % 14 Aug 2021 15:20:00
            
            testCase.verifyEqual(actual, expected);
        end
    end
end

