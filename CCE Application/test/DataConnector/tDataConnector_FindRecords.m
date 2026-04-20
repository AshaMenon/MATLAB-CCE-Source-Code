classdef tDataConnector_FindRecords < matlab.unittest.TestCase
    %TDATACONNECTOR_FINDRECORDS Test searching for AF element(s) on the AF Database
    %
    
    properties (Constant)
        onsServer = 'ONS-OPCDEV'; %Existing ONS Server - user requires access
        onsDatabase = 'WACP'; %Existing ONS AF Database - user requires access
        searchName = 'searchTest';
        searchCriteria = 'Name:=373-XV*';
        tempSearchCriteria = 'CCECalculation'
    end
    
    properties (Access = 'private')
       AFDataConnector
    end
    
    methods (TestClassSetup)
        function connectToAFDatabase(testcase)
            testcase.AFDataConnector = af.AFDataConnector(testcase.onsServer, testcase.onsDatabase);
        end
    end
    
    methods (Test)
        function tFindRecords(testcase)
            %TFINDRECORDS
            
            [records] = testcase.AFDataConnector.findRecords(testcase.searchName, testcase.searchCriteria, 0);
            nOriginalRecs = numel(records);
            testcase.assertNotEmpty(records);
            testcase.verifyClass(records{1,1}, 'OSIsoft.AF.Asset.AFElement');
            
            startIdx = 100;
            [records] = testcase.AFDataConnector.findRecords(testcase.searchName, testcase.searchCriteria, startIdx);
            nRecords = numel(records);
            expectedRecords = nOriginalRecs - startIdx;
            testcase.verifyEqual(nRecords, expectedRecords);
            
            %TODO: Test maxReturned fields
        end
        
        function tTemplateSearch(testcase)
            
            [records] = testcase.AFDataConnector.findRecordsByTemplate(testcase.searchName, testcase.tempSearchCriteria);
            testcase.assertNotEmpty(records);
            testcase.verifyClass(records{1,1}, 'OSIsoft.AF.Asset.AFElement');
        end
        
        function tNothingFound(testcase)
            
            [records] = testcase.AFDataConnector.findRecords(testcase.searchName, 'Name:SomeNonsenseNameThatWillNeverBeFound');
            testcase.verifyEmpty(records);
        end
    end
end

