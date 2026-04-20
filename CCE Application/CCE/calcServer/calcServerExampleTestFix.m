%% Calc Server SensorAdd Example
% Uses sensorAdd
clear all
clc


%% Create Data & Parameters
inputs.SensorReference = 5;
inputs.SensorReferenceTimestamps = datetime('now');
parameters.Constant = 5;

parameters.CalculationID = 'sensTest001';
parameters.LogLevel = {'All'};
parameters.LogName = 'sensy01';
parameters.CalculationName = 'SensorAdd';
%% Set Up
hostName = 'ons-opcdev';
portNum = 9910;
clientID = 'calcServerExample';
archiveName = 'dependentCalcs';
functionName = 'sensorAdd';
%calculationNames = {'oscDet1'};
% calculationNames = {'sensTest1', 'sensTest2', 'sensTest3', 'sensTest4', 'sensTest5'};
functionInputs = {parameters,inputs};
numOfOutputs = 1;

%% Setup calcServer and response
calcServer = CalcServer(clientID, hostName, portNum);
noOfCalcs = 100;
urlBody = calcServer.jsonSerialisation(functionInputs,numOfOutputs);
% response = calcServer.queueCalculation(urlBody,...
%     archiveName, functionName);
firstPass = true;

%% Retrieve Results
allRequestsReceived = 1;
fun = @(s) all(structfun(@isempty,s));
finalResult(noOfCalcs) = struct('lhs','');

queueTimes = randi(10, [noOfCalcs, 1]);
queueIdx = false(noOfCalcs, 1);
queueResults = [];
tic
while allRequestsReceived ~= 0

    %Queue calcs randomly
    mustQueue = toc >= queueTimes & ~queueIdx;
    queueIdx(mustQueue) = true;
    disp("Queueing " + string(sum(mustQueue)))
    for iCalc = 1:sum(mustQueue)
        response = calcServer.queueCalculation(urlBody,...
            archiveName, functionName);
        queueResult = calcServer.jsonDeserialisation(response);
        queueResults = [queueResults; queueResult];
        if firstPass
            up = queueResult.up;
            createdSeq = queueResult.lastModifiedSeq;
            firstPass = false;
        end
    end

    if ~firstPass
        statusRequest = calcServer.requestCalculationState(createdSeq, up);
        statusRequest = calcServer.jsonDeserialisation(statusRequest);
        createdSeq = statusRequest.createdSeq;

        changedCalcs = statusRequest.data;
        disp("FoundCalcs: " + string(numel(changedCalcs)));
        if ~isempty(changedCalcs)
            for ii=1:numel(changedCalcs)
                [~, calcIdx] = ismember(changedCalcs(ii).id, {queueResults.id});
                if calcIdx > 0
                    if strcmp(changedCalcs(ii).state,'READY') && isempty(finalResult(calcIdx).lhs)
                        output =  calcServer.getCalculationResults(statusRequest.data(ii));
                        result = calcServer.jsonDeserialisation(output);
                        finalResult(calcIdx) = result;
                        
                    end
                end
            end
        end
        idx = arrayfun(fun, finalResult);
        allRequestsReceived = sum(idx);
    end
end

for iQueueRes = 1:numel(queueResults)
    calcServer.deleteRequest(queueResults(iQueueRes).self);
end
