%% AsyncCalls
%This is for testing how to make asynchronous call to MATLAB Production
%Server

%% 1. Initial test for making asynchronous calls
% Create and send the request by adding the necessary parameters
%Include the async mode E.g. POST /addTwo/addTwo?mode=async HTTP/1.1
%Setup inputs to function
hostName = 'ons-mps:9930';
archive = 'addTwo';
functionName = 'addTwo';
asyncMode = true;
inputs = {1,2};
numOutputs = 1;

% Send post request to MPS
[postResult, options] = postRequestMLProdServer(hostName,archive,functionName,...
    asyncMode,inputs,numOutputs);
% Poll the request and return the result or error
t0 = datetime('now');
while seconds(datetime('now') - t0) < 3
   [finalResult,errorMsg] = pollRequest(hostName,postResult,options);
   if ~isempty(finalResult) || ~isempty(errorMsg)
       break;
   end
end
%% 2. Queue multiple calcs with varying completion times
%Setup parameters to make calls
hostName = 'ons-mps:9930';
archive = 'runForNSeconds';
functionName = 'runForNSeconds';
asyncMode = true;
numOutputs = 1;
clientID = 'demo2';

% Create post requests
inputTimes = [10,30,5,2,7];
for ii = 1:5
    inputs = {inputTimes(ii)};
    [postResult(ii),options] = postRequestMLProdServer(hostName,archive,functionName,...
    asyncMode,inputs,numOutputs,clientID);
end

% Get results
noOfRequests = size(postResult);
noOfRequests = noOfRequests(2);
allRequestsReceived = 1;
fun = @(s) all(structfun(@isempty,s));
finalResult(noOfRequests) = struct('lhs','');
tic
while allRequestsReceived ~= 0
    command = strcat('?since=', num2str(postResult(1).lastModifiedSeq),'&clients=',postResult(1).client);
    getRequest = getRequestMLProdServer(hostName, postResult(1).up, command, options);
    if ~isempty(getRequest)
        for ii=1:noOfRequests
            if strcmp(getRequest.data(ii).state,'READY') && isempty(finalResult(ii).lhs)
                command = '/result';
                getResult = getRequestMLProdServer(hostName,getRequest.data(ii).self,command,options);
                finalResult(ii) = getResult;
                disp("Request");
                disp(ii);
                disp(jsonencode(finalResult(ii)));
                disp("---------------------------")
            end
        end
    end
    
    idx = arrayfun(fun,finalResult);
    allRequestsReceived = sum(idx);
end
toc