classdef tDataConnector_Construct < matlab.unittest.TestCase
    %TDATACONNECTOR_CONSTRUCT Test construction of the cce.DataConnector Singleton Class
    %
    
    properties (Constant)
        onsServer = 'ONS-OPCDEV'; %Existing ONS Server - user requires access
        onsDatabase = 'WACP'; %Existing ONS AF Database - user requires access
        madeupServer = 'ONS-fake-server';
        madeupDatabase = 'ONS-fake-database';
    end
    
    methods (Test)
        function tConstructionConnection(testcase)
            %TCONSTRUCTIONCONNECTION tests the connection behaviour and connection errors
            
            % T1 - Calling with a non-existent server
            testcase.verifyError( ...
                @() af.AFDataConnector(testcase.madeupServer, testcase.madeupDatabase), ...
                'cce:AFDataConnector:UnknownServer')
            
            % T2 - Calling with a non-existent database
            testcase.verifyError( ...
                @() af.AFDataConnector(testcase.onsServer, testcase.madeupDatabase), ...
                'cce:AFDataConnector:FailedDbConnect')
            
            % T3 - Calling with existing server and database
            obj = af.AFDataConnector(testcase.onsServer, testcase.onsDatabase);
            testcase.verifyMatches(obj.ServerName, testcase.onsServer)
            testcase.verifyMatches(obj.DatabaseName, testcase.onsDatabase)
        end
    end
end

