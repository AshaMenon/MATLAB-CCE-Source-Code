classdef tDataConnector_NewRecords < matlab.unittest.TestCase
    %TDATACONNECTOR_NEWRECORDS Test AF element creation on the AF Database
    %
    
    properties (Constant)
        onsServer = 'ONS-OPCDEV'; %Existing ONS Server - user requires access
        onsDatabase = 'WACP'; %Existing ONS AF Database - user requires access
        templateName = "CCECoordinator";
    end
    
    properties (Access = 'private')
       AFDataConnector
       RootRecord
       HierarchyRecord
    end
    
    methods (TestMethodSetup)
        function connectToAFDatabase(testcase)
            testcase.AFDataConnector = af.AFDataConnector(testcase.onsServer, testcase.onsDatabase);
        end
    end
    
    methods (TestMethodTeardown)
        function removeElements(testcase)
            if ~isempty((testcase.RootRecord))
                testcase.AFDataConnector.deleteRecord(testcase.RootRecord);
            end
            if ~isempty((testcase.HierarchyRecord))
                testcase.AFDataConnector.deleteRecord(testcase.HierarchyRecord);
            end
            testcase.AFDataConnector.commitToDatabase;
        end
    end
    
    methods (Test)
        function tCreateRecordInRoot(testcase)
            %TCREATERECORDINROOT
            
            [testcase.RootRecord] = testcase.AFDataConnector.createRecord(testcase.templateName, 'coordinatorTest');
            testcase.assertClass(testcase.RootRecord, 'OSIsoft.AF.Asset.AFElement');
            parentName = testcase.RootRecord.Parent;
            testcase.verifyEqual(parentName, []);
        end
        
        function tCreateRecordInHierarchy(testcase)
            %TCREATERECORDINROOT
            
            [testcase.RootRecord] = testcase.AFDataConnector.createRecordWithHierarchy(testcase.templateName, 'coordinatorTest', {'CCETest'});
            testcase.assertClass(testcase.RootRecord, 'OSIsoft.AF.Asset.AFElement');
            parentName = testcase.RootRecord.Parent.Name;
            testcase.verifyEqual(string(parentName), "CCETest");
        end
        
        function tFindTemplateByName(testcase)
            %TCREATERECORDINROOT
            
            [template] = testcase.AFDataConnector.findTemplateByName(testcase.templateName);
            testcase.assertClass(template, 'OSIsoft.AF.Asset.AFElementTemplate');
            testcase.verifyEqual(string(template.Name), testcase.templateName);
        end
        
        function tDeleteRecord(testcase)
            %TCREATERECORDINROOT
            
            [recordToDelete] = testcase.AFDataConnector.createRecordWithHierarchy(testcase.templateName, 'deleteTest', {'CCETest'});
            testcase.AFDataConnector.deleteRecord(recordToDelete);
            [records] = testcase.AFDataConnector.findRecords('searchDeleted', fprintf('Name:=''deleteTest'' Template:''%s''', testcase.templateName));
            testcase.verifyEmpty(records);
        end
    end
end

