classdef CalcServer
    %CALCSERVER Interface to the MATLAB Production Server

    %TODO: Document this class better.

    %TODO: Make this class string-friendly.
    
    properties
        Hostname (1,1) string
        Port (1,1) uint16
    end
    properties (Access = protected)
        Options
    end
    properties (SetAccess = protected)
        ClientID
    end
    properties (Dependent, Access = private)
        HostAndPort
    end

    methods % getters
        function str = get.HostAndPort(obj)
            %getHostAndPort  Shorthand for hostname:port
            str = sprintf('%s:%d', obj.Hostname, obj.Port);
        end
    end
    
    methods
        function obj = CalcServer(clientID, hostName, portNum)
            %CALCSERVER Constructor to create a CalcServer object
            %   obj = CalcServer(clientID, hostName, portNum) constructs a CalcServer object using the defined
            %       parameters. Connection to the MLProdServer is assumed over http.
            %   obj = CalcServer(clientID) uses the hostName and portNum values from the System Configuration
            %       file.
            arguments
                clientID (1,:) char % Must specify a client ID
                hostName (1,:) char = cce.System.CalcServerHostName;
                portNum (1,1) uint16 = cce.System.CalcServerPort;
            end
            obj.Hostname = hostName;
            obj.Port = portNum;
            obj.ClientID = clientID;
            obj.Options = weboptions;
            obj.Options.Timeout = cce.System.CalcServerTimeout; % Adjust timeout from the config file
            obj.Options.ContentType = 'text';
            obj.Options.MediaType ='application/json';
            obj.Options.ArrayFormat = 'json';
        end
        
        function queueResult = queueCalculation(obj,urlBody,archiveName,...
                functionName)
            %QUEUECALCULATION Makes a request to queue a calculation
            str = ['http://', obj.HostAndPort, '/',archiveName,'/',...
                functionName,'?mode=async&client=',obj.ClientID];
            try
                queueResult = webwrite(str, urlBody, obj.Options);
            catch MExc
                if strcmp(MExc.identifier, 'MATLAB:webservices:Timeout')
                    % Try again, just once
                    queueResult = webwrite(str, urlBody, obj.Options);
                else
                    rethrow(MExc);
                end
            end
        end
        
        function statusRequest = requestCalculationState(obj, createdSeq, up) % input updates: client, createdSeq, up
            %REQUESTCALCULATIONSTATE Requests the status of all
            %   calculations with the same ClientID
            command = strcat('?since=', num2str(createdSeq),...
                '&clients=',obj.ClientID);
            requestURL = strcat('http://',obj.HostAndPort,up,command);
            try
                statusRequest = webread(requestURL,obj.Options);
            catch MExc
                if strcmp(MExc.identifier, 'MATLAB:webservices:Timeout')
                    % Try again, just once
                    statusRequest = webread(requestURL,obj.Options);
                else
                    rethrow(MExc);
                end
            end
        end
        
        function calculationOutputs = getCalculationResults(obj,statusRequest)
            %GETCALCULATIONRESULTS Retrieve calculation results.
            command = '/result';
            requestURL = strcat('http://',obj.HostAndPort,statusRequest.self,command);
            try
                calculationOutputs = webread(requestURL,obj.Options);
            catch MExc
                if strcmp(MExc.identifier, 'MATLAB:webservices:Timeout')
                    % Try again, just once
                    calculationOutputs = webread(requestURL,obj.Options);
                else
                    rethrow(MExc);
                end
            end
        end
        
        function jsonString = jsonSerialisation(obj,inputs, numOfOutputs)
            %JSONSERIALISATION Converts MATLAB cell array of inputs into a
            % JSON string.
             jsonString = mps.json.encoderequest(inputs, 'nargout', numOfOutputs,...
                'OutputFormat', 'large');
        end
        
        function outputStruct = jsonDeserialisation(obj,jsonString)
            %JSONDESERIALISATION Converts a JSON string into a MATLAB struct.
            outputStruct = jsondecode(jsonString);
        end
        
        function formattedOutputStruct = formatCalcOutput(obj, jsonString)
            output = obj.jsonDeserialisation(jsonString);
            if isfield(output, 'error')
                 formattedOutputStruct = output;
            else
                outputFields = fieldnames(output.lhs(1).mwdata);
                for i = 1:length(outputFields)                    
                    if strcmp(outputFields{i}, 'Timestamp')
                        sOutput.(outputFields{i}) = output.lhs(1).mwdata.Timestamp;
                        if isempty(sOutput.(outputFields{i}).mwdata)
                            sOutput.Timestamp = [];
                        else
                            sOutput.Timestamp.mwdata.TimeStamp = sOutput.Timestamp.mwdata.TimeStamp.mwdata;
                        end
                        % Convert NaNs to the correct format
                    else
                        %Loop through multiple output times
                        numOuts = numel(output.lhs(1).mwdata.(outputFields{i}).mwdata);
                        % Deal with empty output
                        if numOuts == 0
                            sOutput.(outputFields{i}) = [];
                        else
                            for iOut = 1:numOuts
                                if isa(output.lhs(1).mwdata.(outputFields{i}).mwdata, 'cell')
                                    val = output.lhs(1).mwdata.(outputFields{i}).mwdata{iOut};
                                else
                                    val = output.lhs(1).mwdata.(outputFields{i}).mwdata(iOut);
                                end

                                if ischar(val) && strcmp(val, 'NaN') &&...
                                        strcmp(output.lhs(1).mwdata.(outputFields{i}).mwtype, 'double')
                                    sOutput.(outputFields{i})(iOut) = nan;
                                else
                                    try
                                        sOutput.(outputFields{i})(iOut) = val;
                                    catch err
                                        %Error catching that logs val
                                        %regardless of type.
                                        error("Calc output formatting failed, error message: %s. Attempted value: %s",...
                                            err.message, evalc('disp(val)'));
                                    end
                                end
                            end
                        end
                    end

                end
                formattedOutputStruct.lhs{2,1} = output.lhs(2);
                formattedOutputStruct.lhs{1,1} = sOutput;
            end
        end
        
        function deleteRequest(obj, requestURI)
            %DELETEREQUEST Deletes a completed request
            requestURL = strcat('http://',obj.HostAndPort,requestURI);
            obj.Options.RequestMethod = 'delete';
            webread(requestURL,obj.Options);
            obj.Options.RequestMethod = 'auto';
        end
        
        function cancelRequest(obj, requestURI)
            %CANCELREQUEST Cancels a request that has not been completed
            command = '/cancel';
            obj.Options.MediaType ='application/x-www-form-urlencoded';
            requestURL = strcat('http://',obj.HostAndPort,requestURI,command);
            webwrite(requestURL,obj.Options);
            obj.Options.MediaType ='application/json';
        end
        
        function fnNames = discoverFunctions(obj)
            %discoverFunctions  List all functions available on calculation server
            try
                discResult = webread("http://" + obj.HostAndPort + "/api/discovery");
                componentNames = fieldnames(discResult.archives);
                fnNames = string.empty;
                for cI = 1:numel(componentNames)
                    funcNames = fieldnames(discResult.archives.(componentNames{cI}).functions);
                    for fI = 1:numel(funcNames)
                        fnNames(end+1,1) = sprintf("%s/%s", componentNames{cI}, funcNames{fI});
                    end
                end
            catch MExc
                warning("CCE:CalcServer:DiscoveryServiceFailed", "Discovery service failed with ID %s: %s", MExc.identifier, MExc.message);
            end
        end
    end
end


