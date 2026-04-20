function [finalResult, errorMsg] = pollRequest(hostName,postResult,options)
    finalResult = struct('lhs','');
    errorMsg = [];
    command = strcat('?since=', num2str(postResult.lastModifiedSeq),'&ids=',postResult.id);
    getRequest = getRequestMLProdServer(hostName, postResult.up, command, options);
    if isempty(getRequest)
        pollRequest(hostName,postResult,options);
        return;
    else
        if ~strcmp(getRequest.data.state,'READY') && ~strcmp(getRequest.data.state,'ERROR')
            pollRequest(hostName,postResult,options);
        elseif strcmp(getRequest.data.state,'READY')
            command = '/result';
            finalResult = getRequestMLProdServer(hostName,postResult.self,command,options);
        elseif strcmp(getRequest.data.state,'ERROR')
            errorMsg = "The request did not complete successfully";
        end
    end
end