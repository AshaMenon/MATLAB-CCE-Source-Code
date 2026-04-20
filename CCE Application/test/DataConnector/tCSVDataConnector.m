classdef tCSVDataConnector < matlab.unittest.TestCase
    %tCSVDataConnector  Test behaviour of CSVDataConnector class
    %   Tests the operation of a CSVDataConnector, which serialises records as CSV files
    
    properties (Constant)
        RecordName = "TestRecord"
        TestFolderPath = fullfile(tempdir, mfilename("class"));
        RecordTemplate = table(1, {'string'}, 15, 'VariableNames',["CoordinatorID", "AString", "ANumber"]);
    end
    
    methods (TestMethodSetup)
        function CreateFolder(tc)
            if ~exist(tc.TestFolderPath, "dir")
                mkdir(tc.TestFolderPath);
            end
        end
    end
    methods (TestMethodTeardown)
        function RemoveFolder(tc)
            rmdir(tc.TestFolderPath, "s");
        end
    end
    
    methods (Test)
        function Constructor(tc) % Test constructor of CSVDataRecord
            % T1: Default constructor creates a folder and will create "Record" elements
            c = tc.verifyWarning(@()cce.CSVDataConnector(), ...
                "cce:CSVDataConnector:FolderCreated", "Default constructor did not issue FolderCreated warning.");
            tc.verifyGreaterThan(exist(c.FolderPath, "dir"), 0, "FolderPath for DataConnector not created.")
            tc.verifyEqual(c.RecordType, "Record");
            % Clean up - Have to do this as it's not in the usual location.
            rmdir(c.FolderPath);
            % T2: Constructor with folder name that exists does not error.
            tc.verifyWarningFree(@()cce.CSVDataConnector(tc.TestFolderPath), ...
                "Constructor with existing folder name issued a warning.");
            % No cleanup necessary; TestClassTeardown removes the folder.
        end
        function RecordCreation(tc) % Test creation of records
            c = cce.CSVDataConnector(tc.TestFolderPath, "TestRecord");
            testTable = tc.RecordTemplate;
            fName = c.writeRecord(testTable);
            % T1: Filename must be created.
            tc.verifyGreaterThan(exist(fName, "file"), 0, ...
                "Record file not created.");
            % T2: Filename must include record type
            tc.verifyNotEmpty(strfind(fName, "TestRecord1.csv"), ...
                "Filename does not include RecordType.")
        end
        function RecordExists(tc) % Test record existence functions
            c = cce.CSVDataConnector(tc.TestFolderPath, "TestRecord");
            % T1: recordExists must return false if the record does not exist.
            tc.verifyFalse(recordExists(c, 1), "recordExists returned true when record should not exist.");
            % T2: recordExists must return true if the record does exist.
            testTable = tc.RecordTemplate;
            c.writeRecord(testTable);
            tc.verifyTrue(recordExists(c, 1), "recordExists returned false when record should exist.");
        end
        function DeleteRecord(tc) % Test record deletion
            % Setup some records
            c = cce.CSVDataConnector(tc.TestFolderPath, "TestRecord");
            testTable1 = tc.RecordTemplate;
            testTable2 = tc.RecordTemplate;
            testTable2.CoordinatorID = 2;
            writeRecord(c, testTable1);
            writeRecord(c, testTable2);
            % T1: Verify that two files exist
            d = dir(fullfile(tc.TestFolderPath, "*.csv"));
            tc.verifyNumElements(d, 2, "Two files not written for two records.");
            % T2: Remove the record - file must be deleted
            c.removeRecord(1);
            tc.verifyFalse(recordExists(c, 1), "deleteRecord did not delete a record.");
            d = dir(fullfile(tc.TestFolderPath, "*.csv"));
            tc.verifyNumElements(d, 1, "DeleteRecord did not remove a file.");
        end
        function ReadRecord(tc) % Test record reading
            % Set up the test
            c = cce.CSVDataConnector(tc.TestFolderPath, "TestRecord");
            testTable1 = tc.RecordTemplate;
            testTable2 = tc.RecordTemplate;
            testTable2.CoordinatorID = 2;
            writeRecord(c, testTable1);
            writeRecord(c, testTable2);
            % T1: ReadRecord must return the correct table.
            persistedTable1 = readRecord(c, 1);
            tc.verifyEqual(testTable1, persistedTable1, "Table on disk is not the same as written.");
            % T2: Attempting to read a non-existent record errors
            tc.verifyError(@()readRecord(c, 3), "cce:CSVDataConnector:RecordNotFound", ...
                "Attempting to read non-existent record does not error correctly.");
        end
    end
end

