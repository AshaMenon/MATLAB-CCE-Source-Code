classdef tReadWriteDependenciesDB < matlab.unittest.TestCase
    
    properties
        OriginalCCERootEnv = getenv("CCE_Root");
        DBName
    end
    
    properties
       CalcID = "2";
       OutputTime = datestr(datetime('now'));
       FailTime = datestr(datetime('now'));
    end
    
    methods (TestClassSetup)
        function setCCEConfig(~)
            clear('global')
            setenv("CCE_Root", fullfile(fileparts(fileparts(mfilename("fullpath"))), "resources", "configRoot"));
        end
        function deleteDB(testcase)
            
            testcase.DBName = fullfile(cce.System.DbFolder, "cce.db");
            if exist(testcase.DBName, 'file')
                delete(testcase.DBName)
            end
        end
    end
    
    methods (TestClassTeardown)
        function restoreCCERoot(testcase)
            %restoreCCERoot  Restore CCE_Root environment variable
            clear('global')
            setenv("CCE_Root", testcase.OriginalCCERootEnv);
            clear('all')
        end
        function removeDB(testcase)
            delete(testcase.DBName)
        end
    end
    methods (Test)
        function writeWithCreateDB(testcase)
            
            calcIDs = "1";
            outputTimes = datestr(datetime('now'));
            failTimes = datestr(datetime('now'));
            writeDependenciesReadyFailedTime(calcIDs, outputTimes, failTimes);
            testcase.verifyTrue(exist(testcase.DBName, 'file') == 2);
        end
        function writeToExistingDB(testcase)
            
            writeDependenciesReadyFailedTime(testcase.CalcID, testcase.OutputTime, testcase.FailTime);
        end
        function writeMultipleLines(testcase)
            
            calcIDs = ["1", "2"];
            outputTimes = datestr([datetime('now'), datetime('now')]);
            failTimes = datestr([datetime('now') - seconds(10), datetime('now')]);
            writeDependenciesReadyFailedTime(calcIDs, outputTimes, failTimes);
        end
        function readFromDB(testcase)
            
            lastFailedTime = getCheckFailedTime(testcase.CalcID, testcase.OutputTime);
            testcase.verifyEqual(lastFailedTime, datetime(testcase.FailTime)); 
        end
        function readNonexistentID(testcase)
            
            lastFailedTime = getCheckFailedTime("Non-existent-ID", testcase.OutputTime);
            testcase.verifyTrue(ismissing(lastFailedTime));
        end
    end
end

