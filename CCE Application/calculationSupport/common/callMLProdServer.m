function output = callMLProdServer(hostName,archive,...
        functionName, inputs, numOfOutputs)
    %callMLProdServer Calls functions on MLProdServer
    %Inputs:
    %   hostName: eg. 'ons-mps:9920'
    %   archive: Archive name eg. 'addMatrix'
    %   functionName: eg. 'addMatrix'
    %   inputs: Inputs to the function on the MLProdServer eg. {3,2}
    %   numOfOutputs: Number of outputs from the function on the MLProdServer
    
    %  
    options = weboptions;
    options.Timeout = 120;
    options.ContentType = 'text';
    options.MediaType ='application/json';
    options.ArrayFormat = 'json';
    
    body =  mps.json.encoderequest(inputs, 'Nargout', numOfOutputs,...
        'OutputFormat', 'large');
    str = ['http://', hostName,'/', archive,'/',functionName];  
    response = webwrite(str,body, options);
  
    % Convert Output Format From JSON to Struct
    output = mps.json.decoderesponse(response);
end

