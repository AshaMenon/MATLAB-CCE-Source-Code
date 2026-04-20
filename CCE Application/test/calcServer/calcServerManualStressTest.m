%% Calc Server Stress Testing

hostName = 'ons-mps:9920';
archiveName = 'mpsStressTestCalc';
functionName = 'mpsStressTestCalc';
functionInputs = {3};
numOfOutputs = 1;

%% Queue Calculations - Coordinator 1
coordinator1Calcs = CalcServer(hostName, 'coord6');
urlBody = coordinator1Calcs.jsonSerialisation(functionInputs,numOfOutputs);
for calc = 1:15
    response = coordinator1Calcs.queueCalculation(urlBody,...
        archiveName, functionName);
    startTime1(calc) = datetime('now');
    queueResult(calc) = coordinator1Calcs.jsonDeserialisation(response);
end

%% Queue Calculations - Coordinator 2
coordinator2Calcs = CalcServer(hostName, 'coord5');
urlBody = coordinator2Calcs.jsonSerialisation(functionInputs,numOfOutputs);
for calc = 1:5
    response = coordinator2Calcs.queueCalculation(urlBody,...
        archiveName, functionName);
    startTime2(calc) = datetime('now');
    queueResult2(calc) = coordinator2Calcs.jsonDeserialisation(response);
end

%% Retrieve Results
noOfCalcs = 15;
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
                result = coordinator1Calcs.formatCalcOutput(output);
                endTime1(ii) = datetime('now');
                finalResult(ii) = result;
            elseif strcmp(statusRequest.data(ii).state,'CANCELLED') && isempty(finalResult(ii).lhs)
                finalResult(ii).lhs = 'Cancelled';
           
            end
        end
    end
    idx = arrayfun(fun,finalResult);
    allRequestsReceived = sum(idx);
end
%%
noOfCalcs = 5;
allRequestsReceived = 1;
fun = @(s) all(structfun(@isempty,s));
finalResult2(noOfCalcs) = struct('lhs','');
while allRequestsReceived ~= 0
    statusRequest = coordinator2Calcs.requestCalculationState(queueResult2);
    statusRequest = coordinator2Calcs.jsonDeserialisation(statusRequest);
    if ~isempty(statusRequest)
        for ii=1:noOfCalcs
            if strcmp(statusRequest.data(ii).state,'READY') && isempty(finalResult2(ii).lhs)
                output =  coordinator1Calcs.getCalculationResults(statusRequest.data(ii));
                result = coordinator1Calcs.formatCalcOutput(output);
                endTime2(ii) = datetime('now');
                finalResult2(ii) = result;
            elseif strcmp(statusRequest.data(ii).state,'CANCELLED') && isempty(finalResult2(ii).lhs)
                finalResult2(ii).lhs = 'Cancelled';
           
            end
        end
    end
    idx = arrayfun(fun,finalResult2);
    allRequestsReceived = sum(idx);
end

%%
queueTime1 = endTime1 - startTime1 - seconds(5);
queueTime2 = endTime2 - startTime2  - seconds(5);
totalQueueTime = sum(queueTime1) + sum(queueTime2);
avgQueueTime = totalQueueTime/20;

