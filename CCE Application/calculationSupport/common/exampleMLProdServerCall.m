%% Example MLProdServer Call

hostName = 'ons-mps:9920';
archive = 'callTimesN';
functionName = 'callTimesN';
inputs = {2,3};
numOfOutputs = 1;

output = callMLProdServer(hostName,archive,...
        functionName, inputs, numOfOutputs);