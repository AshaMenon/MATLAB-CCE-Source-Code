%% ControllerAnalysis Calc Server Example

addpath(fullfile('..','..','test', 'calcServer')); 
hostName = 'ons-mps';
portNum = 9920;
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
numOfOutputs = 2;
rmpath(fullfile('..','..','test', 'calcServer')); 

%% Queue Calculations
coordinator1Calcs = CalcServer(clientID, hostName, portNum);
noOfCalcs = 5;
urlBody = coordinator1Calcs.jsonSerialisation(functionInputs,numOfOutputs);
for calc = 1:noOfCalcs
    response = coordinator1Calcs.queueCalculation(urlBody,...
        archiveName, functionName);
    queueResult(calc) = coordinator1Calcs.jsonDeserialisation(response);
end

%% Request State
statusRequest = coordinator1Calcs.requestCalculationState(queueResult);
statusRequest = coordinator1Calcs.jsonDeserialisation(statusRequest);

%% Cancel Request
coordinator1Calcs.cancelRequest(statusRequest.data(3).self);
statusRequest = coordinator1Calcs.requestCalculationState(queueResult);
statusRequest = coordinator1Calcs.jsonDeserialisation(statusRequest);

%% Retrieve Results
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
            elseif strcmp(statusRequest.data(ii).state,'CANCELLED') && isempty(finalResult(ii).lhs)
                finalResult(ii).lhs = 'Cancelled';
            end
        end
    end
    idx = arrayfun(fun,finalResult);
    allRequestsReceived = sum(idx);
end

%% Delete Request
coordinator1Calcs.deleteRequest(statusRequest.data(2).self);
statusRequest = coordinator1Calcs.requestCalculationState(queueResult);
statusRequest = coordinator1Calcs.jsonDeserialisation(statusRequest);


