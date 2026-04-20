classdef CalcServerQueueTests < matlab.unittest.TestCase
    %PYTHONINVESTIGATIONTESTS Tests the python use cases
    
    properties
        HostName = 'ons-mps';
        PortNum = uint16(9920);
        ClientID = 'coordinator1';
        UrlBody
        ArchiveName = 'controllerAnalysisDelayed';
        FunctionName = 'controllerAnalysisDelayed';
        FunctionInputs
        NumOfOutputs
    end
    
    properties (TestParameter)
       noOfCalcs = {5}
       expectedOutput = {'IN_QUEUE'}
    end
    methods (TestMethodSetup)
        function  setup(testCase)
            addpath(genpath('..\..\cce\calcServer'))
        end
        
        function setProps(testCase)
            filenames = {'Mogn_NIcc_Hpgr_Crush_a406Bn002a_a406Lic405_Data.csv',...
                'Mogn_NIcc_Hpgr_Crush_a406Bn002a_a406Lic405_Attributes.csv',...
                'Mogn_NIcc_Hpgr_Crush_a406Bn002a_a406Lic405_Parameters.csv'};
            startRange = datetime(2020,12,13,1,0,0);
            endRange = startRange + hours(1);
            timerange = [startRange, endRange];
            [parameters,inputs,~,~] =...
                controllerAnalysisMockInterfaceTest(filenames, timerange);           
            testCase.FunctionInputs = {parameters,inputs};
            testCase.NumOfOutputs = 1;
        end
    end
    methods (Test, ParameterCombination='sequential')
        function testQueueing(testCase, noOfCalcs, expectedOutput)
            coordinator1Calcs = CalcServer(testCase.ClientID, testCase.HostName, testCase.PortNum);
            urlBody = coordinator1Calcs.jsonSerialisation(testCase.FunctionInputs,...
                testCase.NumOfOutputs);
            for calc = 1:noOfCalcs
                response = coordinator1Calcs.queueCalculation(urlBody,...
                    testCase.ArchiveName, testCase.FunctionName);
                queueResult(calc) = coordinator1Calcs.jsonDeserialisation(response);
            end
            
            statusRequest = coordinator1Calcs.requestCalculationState(queueResult);
            statusRequest = coordinator1Calcs.jsonDeserialisation(statusRequest);
            
            actualOutput = statusRequest.data(5).state;
            testCase.verifyEqual(actualOutput, expectedOutput);

        end

    end
end