classdef tDataConnector_ReadData < matlab.unittest.TestCase
    %tDataConnector_ReadData Test searching for AF element(s) on the AF Database
    %
    
    properties (Constant)
        onsServer = 'ONS-OPCDEV'; %Existing ONS Server - user requires access
        onsDatabase = 'WACP'; %Existing ONS AF Database - user requires access
        elementName = 'CCECalculation1';
    end
    
    properties (Access = 'private')
       AFDataConnector
       Record
       LogicalAttribute
       DateTimeAttribute
       StringAttribute
       EnumAttribute
    end
    
    methods (TestClassSetup)
        function connectToAFDatabase(testcase)
            
            testcase.AFDataConnector = af.AFDataConnector(testcase.onsServer, testcase.onsDatabase);            
            searchCriteria = sprintf('Name:=%s', testcase.elementName);
            record = testcase.AFDataConnector.findRecords('RecordSearch', searchCriteria);
            testcase.Record = record{1, 1};
            [testcase.LogicalAttribute] = testcase.AFDataConnector.getFieldByName(testcase.Record, 'Overwrite');
            [testcase.DateTimeAttribute] = testcase.AFDataConnector.getFieldByName(testcase.Record, 'ValidUntilTime');
            [testcase.StringAttribute] = testcase.AFDataConnector.getFieldByName(testcase.Record, 'CalcServer');
            [testcase.EnumAttribute] = testcase.AFDataConnector.getFieldByName(testcase.Record, 'LogLevel');
        end
    end
    
    methods (Test)
        function tGetValue(testcase)
            
            [value] = testcase.AFDataConnector.readField(testcase.LogicalAttribute);
            [value] = testcase.AFDataConnector.readField(testcase.DateTimeAttribute);
            [value] = testcase.AFDataConnector.readField(testcase.StringAttribute);
            [value] = testcase.AFDataConnector.readField(testcase.EnumAttribute);
        end
        
        function tSetValue(testcase)
            
        end
        
    end
end

