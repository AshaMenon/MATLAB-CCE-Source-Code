classdef pythonInvestigationTests < matlab.unittest.TestCase
    %PYTHONINVESTIGATIONTESTS Tests the python use cases
    
    properties
        
    end
    
    properties (TestParameter)
        timesTwoOutput = {16}
        timesNInput = {{2,5}; {50,2}; {23,3}}
        timesNOutput = {10; 100; 69}
        intInput = {{3,87}; {2,12}}
        intOutput = {261;24}
        floatInput = {{2.5,2.1};{14.223, 2.456789}}
        floatOutput = {5.25; 34.942909947000004}
        logicalInput = {{2,3,true}; {[2 2 4 5],[3,2,1,4],true}}
        logicalOutput = {true; [true; true; true; true]}
        stringInput = {{'Option1'}; {'Option2'}; {{'Option1', ...
            'Option1', 'Option1'}}}
        stringOutput = {{'This is Option 1'}; {'NaN'}; ...
            {'This is Option 1';'This is Option 1';'This is Option 1'}}
        noneErrorInput = {'Option3'}
        arrayInput = {{[1 5 26 36]}}
        arrayOutput = {[2;10;52;72]}
        
    end
    
    methods (Test,ParameterCombination='sequential')
        
    methods (TestMethodSetup)
        function  setup(testCase)
            addpath(genpath('..\..\python\'))
        end
    end
        
        % Tests timesTwoFunction
        function testTimesTwoFunction(testCase,...
                timesTwoOutput)
            
            archive = 'callTimesTwo';
            functionName = 'callTimesTwo';
            hostName = 'ons-mps:9920';
            numOfOutputs = 1;
            
            output = callMLProdServer(hostName,archive,functionName,...
                {}, numOfOutputs);
            actualOutput = output.lhs.mwdata;
            
            testCase.verifyEqual(actualOutput, timesTwoOutput);
            
        end
        
        % Tests timesNFunction
        function testTimesNFunction(testCase, timesNInput,...
                timesNOutput)
            
            archive = 'callTimesN';
            functionName = 'callTimesN';
            hostName = 'ons-mps:9920';
            numOfOutputs = 1;
            
            output = callMLProdServer(hostName,archive,functionName,...
                timesNInput, numOfOutputs);
            actualOutput = output.lhs.mwdata;
            
            testCase.verifyEqual(actualOutput, timesNOutput);
            
        end
        
        % Test Integers
        function testIntFunction(testCase, intInput,...
                intOutput)
            
            archive = 'callTimesN';
            functionName = 'callTimesN';
            hostName = 'ons-mps:9920';
            numOfOutputs = 1;
            
            output = callMLProdServer(hostName,archive,functionName,...
                intInput, numOfOutputs);
            actualOutput = output.lhs.mwdata;
            
            testCase.verifyEqual(actualOutput, intOutput);
            
        end
        
        % Test Float
        function testFloatFunction(testCase, floatInput,...
                floatOutput)
            
            archive = 'callTimesN';
            functionName = 'callTimesN';
            hostName = 'ons-mps:9920';
            numOfOutputs = 1;
            
            output = callMLProdServer(hostName,archive,functionName,...
                floatInput, numOfOutputs);
            actualOutput = output.lhs.mwdata;
            
            testCase.verifyEqual(actualOutput, floatOutput);
            
        end
        
        % Test Strings
        function testStringFunction(testCase, stringInput,...
                stringOutput)
            
            archive = 'callCheckString';
            functionName = 'callCheckString';
            hostName = 'ons-mps:9920';
            numOfOutputs = 1;
            
            output = callMLProdServer(hostName,archive,functionName,...
                stringInput, numOfOutputs);
            actualOutput = output.lhs.mwdata;
            
            testCase.verifyEqual(actualOutput, stringOutput);
            
        end
        
        
        
        % Test Logical Operations
        function testLogicalFunction(testCase, logicalInput,...
                logicalOutput)
            
            archive = 'callLogicalOperations';
            functionName = 'callLogicalOperations';
            hostName = 'ons-mps:9920';
            numOfOutputs = 1;
            
            output = callMLProdServer(hostName,archive,functionName,...
                logicalInput, numOfOutputs);
            actualOutput = output.lhs.mwdata{1,1};
            
            testCase.verifyEqual(actualOutput, logicalOutput);
            
        end
        
        % Test Double Array
        function testArrayFunction(testCase, arrayInput,...
                arrayOutput)
            
            archive = 'callTimesTwoArray';
            functionName = 'callTimesTwoArray';
            hostName = 'ons-mps:9920';
            numOfOutputs = 1;
            
            output = callMLProdServer(hostName,archive,functionName,...
                arrayInput, numOfOutputs);
            actualOutput = output.lhs.mwdata;
            
            testCase.verifyEqual(actualOutput, arrayOutput);
            
        end
        
        % Test nested structs
        function testStructsFunction(testCase)
            
            archive = 'callTestStructs';
            functionName = 'callTestStructs';
            hostName = 'ons-mps:9920';
            numOfOutputs = 1;
            
            S1 = struct('Robert',357,'Mary',229,'Jack',391);
            S2 = struct('Robert',357,'Mary',229,'Jack',391);
            S3 = struct('Robert',357,'Mary',229,'Jack',391);
            input = struct('S1', S1, 'S2', S2, 'S3', S3);
            
            output = callMLProdServer(hostName,archive,functionName,...
                {input}, numOfOutputs);
            actualOutput = output.lhs.mwdata.S1.mwdata.Mary.mwdata;
            
            testCase.verifyEqual(actualOutput, 300);
            
        end

    end

end