classdef CalcServerTests < matlab.unittest.TestCase
    %PYTHONINVESTIGATIONTESTS Tests the python use cases
    
    properties
        HostName
        PortNum = uint16(9920);
        ClientID
        UrlBody
        ArchiveName
        FunctionName
    end
    
    properties (TestParameter)
        queueInputs = {{'oscDet1', 'oscDet2', 'oscDet3', 'oscDet4',...
            'oscDet5'}}
        jsonInputs = {'jsonCase1.mat'; 'jsonCase2.mat'; 'jsonCase3.mat'}
        expectedOutputs = {'finalResult2.mat'}
        funcOutput = {{{'parameters';'pv';'pvTimeStamp';'rrCountRef';...
            'oscCountRef'}; {'rrCount';'oscCount'}}}
        formatInputs = {'format1'; 'format2'; 'format3'}

        
    end
    methods (TestMethodSetup)
        function  setup(testCase)
            addpath(genpath('..\..\cce\calcServer'))
        end
        
        function setProps(testCase)
            testCase.HostName = 'ons-mps';
            testCase.ClientID = 'coordinator1';
            testCase.ArchiveName = 'oscillationDetection';
            testCase.FunctionName = 'oscillationDetection';
            load('oscDetMockData.mat');
            inputs = {parameters,pv, pvTimestamp,rrCountRef,oscCountRef};
            numOfOutputs = 2;
            testCase.UrlBody = mps.json.encoderequest(inputs, 'nargout', numOfOutputs);
        end
    end
    methods (Test,ParameterCombination='sequential')
        
        function testQueueCalcs(testCase,queueInputs)
            expectedOutput = {'id';'self';'up';'lastModifiedSeq';'state';'client'};
            coordinator1Calcs = CalcServer(testCase.ClientID, testCase.HostName,...
                testCase.PortNum);
            noOfCalcs = length(queueInputs);
            for calc = 1:noOfCalcs
                response = coordinator1Calcs.queueCalculation(testCase.UrlBody,...
                    testCase.ArchiveName, testCase.FunctionName);
                queueResult(calc) = jsondecode(response);
            end
            actualOutput = fieldnames(queueResult);
            testCase.verifyEqual(actualOutput, expectedOutput);
        end
        
        function testRequestStatus(testCase, queueInputs)
            expectedOutput = {'createdSeq';'data'};
            coordinator1Calcs = CalcServer(testCase.ClientID, testCase.HostName,...
                testCase.PortNum);
            noOfCalcs = length(queueInputs);
            for calc = 1:noOfCalcs
                response = coordinator1Calcs.queueCalculation(testCase.UrlBody,...
                    testCase.ArchiveName, testCase.FunctionName);
                queueResult(calc) = jsondecode(response);
            end
            output = coordinator1Calcs.requestCalculationState(queueResult);
            output = jsondecode(output);
            actualOutput = fieldnames(output);
            testCase.verifyEqual(actualOutput, expectedOutput);
        end

        function testJSONSerialisation(testCase, jsonInputs)
            load(jsonInputs)
            coordinator1Calcs = CalcServer(testCase.ClientID, testCase.HostName,...
                testCase.PortNum);
            actualOutput = coordinator1Calcs.jsonSerialisation(inputs, numOfOutputs);
            testCase.verifyEqual(actualOutput, jsonString);
        end
        
        function testJSONDeserialisation(testCase, jsonInputs)
            load(jsonInputs)
            coordinator1Calcs = CalcServer(testCase.ClientID, testCase.HostName,...
                testCase.PortNum);
            actualOutput = coordinator1Calcs.jsonDeserialisation(jsonString);
            testCase.verifyEqual(actualOutput, structOutput);
        end
        
        function testDeleteRequest(testCase)
            clientID = 'coordinator2';
            archiveName = 'controllerAnalysis';
            functionName = 'controllerAnalysis';
            
            filenames = {'Mogn_NIcc_Hpgr_Crush_a406Bn002a_a406Lic405_Data.csv',...
                'Mogn_NIcc_Hpgr_Crush_a406Bn002a_a406Lic405_Attributes.csv',...
                'Mogn_NIcc_Hpgr_Crush_a406Bn002a_a406Lic405_Parameters.csv'};
            startRange = datetime(2020,12,13,1,0,0);
            endRange = startRange + hours(1);
            timerange = [startRange, endRange];
            [parameters,inputs,~,~] =...
                controllerAnalysisMockInterfaceTest(filenames, timerange);
            functionInputs = {parameters,inputs};
            numOfOutputs = 2;
            
            coordinator1Calcs = CalcServer(clientID, testCase.HostName, testCase.PortNum);
            noOfCalcs = 3;
            urlBody = coordinator1Calcs.jsonSerialisation(functionInputs,numOfOutputs);
            for calc = 1:noOfCalcs
                response = coordinator1Calcs.queueCalculation(urlBody,...
                    archiveName, functionName);
                queueResult(calc) = coordinator1Calcs.jsonDeserialisation(response);
            end
            
            allRequestsReceived = 1;
            fun = @(s) all(structfun(@isempty,s));
            finalResult(noOfCalcs) = struct('lhs','');
            
            while allRequestsReceived ~= 0
                statusRequest = coordinator1Calcs.requestCalculationState(queueResult);
                statusRequest = coordinator1Calcs.jsonDeserialisation(statusRequest);
                if ~isempty(statusRequest)
                    for ii=1:noOfCalcs
                        if strcmp(statusRequest.data(ii).state,'READY') && isempty(finalResult(ii).lhs)
                            output =  coordinator1Calcs.getCalculationResults(statusRequest.data(ii));
                            result = coordinator1Calcs.jsonDeserialisation(output);
                            finalResult(ii) = result;
                        end
                    end
                end
                idx = arrayfun(fun,finalResult);
                allRequestsReceived = sum(idx);
            end
            
            expectedResult = statusRequest.data([1,3]);
            coordinator1Calcs.deleteRequest(statusRequest.data(2).self);
            
            statusRequest = coordinator1Calcs.requestCalculationState(queueResult);
            statusRequest = coordinator1Calcs.jsonDeserialisation(statusRequest);
            actualResult = statusRequest.data;
            testCase.verifyEqual(expectedResult, actualResult);
            
        end
        
         function testCancelRequest(testCase)
            clientID = 'coordinator2';
            archiveName = 'controllerAnalysisDelayed';
            functionName = 'controllerAnalysisDelayed';
            
            filenames = {'Mogn_NIcc_Hpgr_Crush_a406Bn002a_a406Lic405_Data.csv',...
                'Mogn_NIcc_Hpgr_Crush_a406Bn002a_a406Lic405_Attributes.csv',...
                'Mogn_NIcc_Hpgr_Crush_a406Bn002a_a406Lic405_Parameters.csv'};
            startRange = datetime(2020,12,13,1,0,0);
            endRange = startRange + hours(1);
            timerange = [startRange, endRange];
            [parameters,inputs,~,~] =...
                controllerAnalysisMockInterfaceTest(filenames, timerange);
            functionInputs = {parameters,inputs};
            numOfOutputs = 1;
            
            coordinator1Calcs = CalcServer(clientID, testCase.HostName, testCase.PortNum);
            noOfCalcs = 3;
            urlBody = coordinator1Calcs.jsonSerialisation(functionInputs,numOfOutputs);
            for calc = 1:noOfCalcs
                response = coordinator1Calcs.queueCalculation(urlBody,...
                    archiveName, functionName);
                queueResult(calc) = coordinator1Calcs.jsonDeserialisation(response);
            end
            
            allRequestsReceived = 1;
            fun = @(s) all(structfun(@isempty,s));
            finalResult(noOfCalcs) = struct('lhs','');
            
            statusRequest = coordinator1Calcs.requestCalculationState(queueResult);
            statusRequest = coordinator1Calcs.jsonDeserialisation(statusRequest);
            requestURI = statusRequest.data(2).self;
            coordinator1Calcs.cancelRequest(requestURI);
            
            while allRequestsReceived ~= 0
                statusRequest = coordinator1Calcs.requestCalculationState(queueResult);
                statusRequest = coordinator1Calcs.jsonDeserialisation(statusRequest);
                if ~isempty(statusRequest)
                    for ii=1:noOfCalcs
                        if strcmp(statusRequest.data(ii).state,'READY') && isempty(finalResult(ii).lhs)
                            output =  coordinator1Calcs.getCalculationResults(statusRequest.data(ii));
                            result = coordinator1Calcs.jsonDeserialisation(output);
                            finalResult(ii) = result;
                        elseif strcmp(statusRequest.data(ii).state,'CANCELLED') && isempty(finalResult(ii).lhs)
                            finalResult(ii).lhs = 'Cancelled';
                        end
                    end
                end
                idx = arrayfun(fun,finalResult);
                allRequestsReceived = sum(idx);
            end
            testCase.verifyEqual('Cancelled', finalResult(2).lhs);
            
         end
        
         function testFormatCalcOutputs(testCase, formatInputs)
             load(formatInputs)
             c1 = CalcServer(testCase.ClientID, testCase.HostName, testCase.portNum);
             actualOutput = c1.formatCalcOutput(result);
             testCase.verifyEqual(actualOutput, output);      
         end
    end
end