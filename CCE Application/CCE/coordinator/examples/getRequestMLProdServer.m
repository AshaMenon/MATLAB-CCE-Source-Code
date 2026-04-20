function getResult = getRequestMLProdServer(hostName, getRequestURL, command, options)
    %getRequestMLProdServer Send a get request using webread
    %hostName: eg. ons-mps:9930
    %getRequestURL: the output from a async post request to get the status 
    %or result of a request
    %command: e.g input, result
    %options: the web options required to setup a call using webread
    
    response = webread(strcat('http://',hostName,getRequestURL,command),options);
    
    getResult = jsondecode(response);
end