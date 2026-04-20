classdef tDataConnector_GetAttributes < matlab.unittest.TestCase
    %TDATACONNECTOR_GETATTRIBUTES Test retrieving AF attributes(s)
    %
    
    properties (Constant)
        onsServer = 'ONS-OPCDEV'; %Existing ONS Server - user requires access
        onsDatabase = 'WACP'; %Existing ONS AF Database - user requires access
        tempSearchCriteria = 'CCECalculation'
        elementWithNestedAttributes = '373-XV-501B505B-A';
    end
    
    properties (Access = 'private')
       AFDataConnector
       Record
       RecordWithAttributeNesting
    end
    
    methods (TestClassSetup)
        function connectToAFDatabase(testcase)
            
            testcase.AFDataConnector = af.AFDataConnector(testcase.onsServer, testcase.onsDatabase);
            [records] = testcase.AFDataConnector.findRecordsByTemplate('TemplateSearch', testcase.tempSearchCriteria);
            testcase.Record = records{1, 1};
            
            searchCriteria = sprintf('Name:=%s', testcase.elementWithNestedAttributes);
            record = testcase.AFDataConnector.findRecords('NestedAttsSearch', searchCriteria);
            testcase.RecordWithAttributeNesting = record{1, 1};
        end
    end
    
    methods (Test)
        function tGetAttributes(testcase)
            
            [fields] = testcase.AFDataConnector.getFields(testcase.Record);
            testcase.verifyClass(fields, 'OSIsoft.AF.Asset.AFAttributeList');
        end
        
        function tGetAttributesByName(testcase)
            
            [field] = testcase.AFDataConnector.getFieldByName(testcase.Record, 'LogName');
            testcase.verifyClass(field, 'OSIsoft.AF.Asset.AFAttribute');
            
            [field] = testcase.AFDataConnector.getFieldByName(testcase.Record, 'NonsensicalAttributeName');
            testcase.verifyEmpty(field);
        end
        
        function tNestedAttributes(testcase)
            
            [parentField] = testcase.AFDataConnector.getFieldByName(testcase.RecordWithAttributeNesting, 'OutletValve1Name');
            [field] = testcase.AFDataConnector.getFields(parentField);
            testcase.verifyClass(field, 'OSIsoft.AF.Asset.AFAttributeList');
            [field] = testcase.AFDataConnector.getFieldByName(parentField, 'RunStatus');
            testcase.verifyClass(field, 'OSIsoft.AF.Asset.AFAttribute');
            testcase.verifyEqual(string(field.Name), "RunStatus");
        end
        
        function tGetAttributesByCategory(testcase)
            
            [fields, names] = testcase.AFDataConnector.getRecordFieldsByCategory(...
                testcase.RecordWithAttributeNesting, "Output");
            testcase.verifyEqual(numel(fields), numel(names));
        end
    end
end

