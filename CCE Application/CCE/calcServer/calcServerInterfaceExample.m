%% Calc Server Interface Example
% Uses ocsillationDetection

%% Load Data & Parameters
dataTbl = readtimetable(fullfile('..','..','mockData','oscillationDetectionSample.csv'));
inputs.PV = dataTbl.PV;
inputs.PVTimestamps = dataTbl.Date;
inputs.RRCount = dataTbl.reversalCount(end);
inputs.OscCount = dataTbl.oscillationCount(end);
parameters.TSample = 10;
parameters.Fs = 900;
parameters.RRWsize = 100;
parameters.PVThreshold = 10000;
parameters.TIntegral = 500;
parameters.Rmax = 10;
parameters.LogName = 'oscillationDetection';
parameters.CalculationID = 'osc001';
parameters.LogLevel = {'All'};
parameters.CalculationName = 'Oscillation Detection';
%% Set Up
hostName = 'ons-opcdev';
portNum = 9910;
clientID = 'calcServerExample';
archiveName = 'oscillationDetection';
functionName = 'oscillationDetection';
%calculationNames = {'oscDet1'};
calculationNames = {'oscDet1', 'oscDet2', 'oscDet3', 'oscDet4', 'oscDet5'};
functionInputs = {parameters,inputs};
numOfOutputs = 1;

%% Queue Calculations
calcServer = CalcServer(clientID, hostName, portNum);
noOfCalcs = length(calculationNames);
urlBody = calcServer.jsonSerialisation(functionInputs,numOfOutputs);
for calc = 1:noOfCalcs
    response = calcServer.queueCalculation(urlBody,...
        archiveName, functionName);
    queueResult(calc) = calcServer.jsonDeserialisation(response);
end
up = queueResult(1).up;
createdSeq = queueResult(1).lastModifiedSeq;
firstPass = false;
%% Request State
% statusRequest = calcServer.requestCalculationState(createdSeq, up);
% statusRequest = calcServer.jsonDeserialisation(statusRequest);
% createdSeq = statusRequest.createdSeq;

%% Retrieve Results
allRequestsReceived = 1;
fun = @(s) all(structfun(@isempty,s));
finalResult(noOfCalcs) = struct('lhs','');

while allRequestsReceived ~= 0
    statusRequest = calcServer.requestCalculationState(createdSeq, up);
    statusRequest = calcServer.jsonDeserialisation(statusRequest);
    if firstPass
        createdSeq = statusRequest.createdSeq;
        firstPass = false;
    end

    changedCalcs = statusRequest.data;
    if ~isempty(changedCalcs)
        for ii=1:numel(changedCalcs)
            [~, calcIdx] = ismember(changedCalcs(ii).id, {queueResult.id});
            if strcmp(changedCalcs(ii).state,'READY') && isempty(finalResult(calcIdx).lhs)
                output =  calcServer.getCalculationResults(statusRequest.data(ii));
                result = calcServer.jsonDeserialisation(output);
                finalResult(calcIdx) = result;
            end
        end
    end
    idx = arrayfun(fun, finalResult);
    allRequestsReceived = sum(idx);
end
