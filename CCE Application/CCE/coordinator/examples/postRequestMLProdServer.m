function [postResult,options]= postRequestMLProdServer(hostName,archive,...
        functionName, asyncMode, inputs, numOfOutputs, clientID)
        %postRequestMLProdServer Calls functions on MLProdServer
    %Inputs:
    %   hostName: eg. 'ons-mps:9930'
    %   archive: Archive name eg. 'addMatrix'
    %   functionName: eg. 'addMatrix'
    %   asyncMode: set to true if asynchronous call is to be used
    %   inputs: Inputs to the function on the MLProdServer eg. {3,2}
    %   numOfOutputs: Number of outputs from the function on the MLProdServer
    
    % Options
    options = weboptions;
    options.Timeout = 500;
    options.ContentType = 'text';
    options.MediaType ='application/json';
    options.ArrayFormat = 'json';
    
    body =  mps.json.encoderequest(inputs, 'nargout', numOfOutputs);
    %body = struct('rhs',inputs,'nargout',numOfOutputs);
    if asyncMode
        str = ['http://', hostName,'/',archive,'/',functionName,'?mode=async&client=',clientID];
    else
        str = ['http://', hostName,'/', archive,'/',functionName]; 
    end
     
    response = webwrite(str, body, options);
  
    % Convert Output Format From JSON to Struct
    postResult = jsondecode(response);
    
end

