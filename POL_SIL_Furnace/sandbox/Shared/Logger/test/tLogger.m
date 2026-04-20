classdef tLogger < matlab.unittest.TestCase
    %tLogger  Tests for the Logger class
    
    
    properties (Constant)
        LogDir = tempname;
        FileName1 = "test1.log";
        FileNameNoCat = "testNoCat.log";
        MsgFmt1 = "Test with number %d placeholder of %s";
        mgsArg1 = {12, "some string"};
    end
    properties (TestParameter)
        % We need to enclose the cell array we want to store in a cell array, hence the triple curly braces!
        MsgParams = struct('two', {{"Test with number %d placeholder of %s", {12, "string"}}}, ...
            'none', {{"Test with no placeholders.", {}}}, ...
            'tooMany', {{"Test with too %s many %s placeholders.", {'freaking'}}});
        LogFnName = {"Info", "Warning", "Error", "Debug", "Trace"};
    end
    
    methods (TestClassSetup)
        function createFolder(tc)
            %createFolder  Ensure that source folder is created and destroyed at exit
            if ~exist(tc.LogDir, "dir")
                mkdir(tc.LogDir);
                tc.addTeardown(@()rmdir(tc.LogDir, "s"));
            end
        end
    end
    methods (TestMethodTeardown)
        function deleteAllFilesInFolder(tc)
            %deleteAllFilesInFolder  Remove all files in the test log folder
            if exist(tc.LogDir, "dir")
                allLogFiles = dir(fullfile(tc.LogDir,"*.log"));
                for k=1:numel(allLogFiles)
                    delete(fullfile(tc.LogDir, allLogFiles(k).name));
                end
            end
        end
    end

    methods (Test)
        function loggerConstructor1Arg(tc)
            %loggerConstructor1Arg  Test constructor with one input argument
            %   logger(filePath) must set the right defaults.
            path1 = fullfile(tc.LogDir, tc.FileName1);
            logger1 = Logger(path1);
            
            tc.verifyClass(logger1, "Logger");
            tc.verifyEqual(logger1.LogFilePath, path1);
            tc.verifyEqual(logger1.Category, "");
            tc.verifyEqual(logger1.UniqueID, "None");
            tc.verifyEqual(logger1.LogLevel, LogMessageLevel.All);
            % Defining a relative path should throw a warning
            path2 = tc.FileName1;
            logger2 = tc.verifyWarning(@()Logger(path2), "Logger:Logger:RelativeFilePath");
            tc.verifyEqual(logger2.LogFilePath, fullfile(pwd, path2));
        end
        function loggerConstructor2Arg(tc)
            %loggerConstructor2Arg  Test constructor with filename and category
            path1 = fullfile(tc.LogDir, tc.FileName1);
            cat1 = "Cat1";
            logger1 = Logger(path1, cat1);
            tc.verifyClass(logger1, "Logger");
            tc.verifyEqual(logger1.LogFilePath, path1);
            tc.verifyEqual(logger1.Category, cat1);
            tc.verifyEqual(logger1.UniqueID, "None");
            tc.verifyEqual(logger1.LogLevel, LogMessageLevel.All);
        end
        function loggerConstructor3Arg(tc)
            %loggerConstructor3Arg  Test constructor with filename, category and ID
            path1 = fullfile(tc.LogDir, tc.FileName1);
            cat1 = "Cat1";
            myId = "Id";
            logger1 = Logger(path1, cat1, myId);
            tc.verifyClass(logger1, "Logger");
            tc.verifyEqual(logger1.LogFilePath, path1);
            tc.verifyEqual(logger1.Category, cat1);
            tc.verifyEqual(logger1.UniqueID, myId);
            tc.verifyEqual(logger1.LogLevel, LogMessageLevel.All);
        end
        function loggerConstructor4Arg(tc)
            %loggerConstructor4Arg  Test constructor with all arguments
            path1 = fullfile(tc.LogDir, tc.FileName1);
            cat1 = "Cat1";
            myId = "Id";
            [lvlEnum, lvlName] = enumeration("LogMessageLevel");
            lvlInt = int32(lvlEnum); % These things can be int32 values also
            for lI=1:numel(lvlEnum)
                % Check the enumeration itself as an argument
                l = Logger(path1, cat1, myId, lvlEnum(lI));
                tc.verifyEqual(l.LogLevel, lvlEnum(lI));
                % Check that the string version also works
                l = Logger(path1, cat1, myId, lvlName(lI));
                tc.verifyEqual(l.LogLevel, lvlEnum(lI));
                % Check that the integer version also works
                l = Logger(path1, cat1, myId, lvlInt(lI));
                tc.verifyEqual(l.LogLevel, lvlEnum(lI));
            end
        end
    end
    methods (Test) % Test the write methods
        function tLogFunctionSweep(tc, MsgParams, LogFnName)
            %tLogFunctionSweep  Test that logging and messages with different formats work.
            %   This is a parameterised test. We sweep across 3 different message formats (MsgParams) and across
            %   all the available log write levels (logInfo, logWarning, logError, etc.)
            %
            %   Note that if this combination gets too large, so does the eventual log file. 
            fPath = fullfile(tc.LogDir, tc.FileName1);
            catStr = "Cat1";
            idStr = "ID";
            logObj = Logger(fPath, catStr, idStr, "All");
            logFn = str2func("log"+LogFnName);
            logFn(logObj, MsgParams{1}, MsgParams{2}{:});
            % Now read the file back
            txt = join(readlines(fPath), newline);
            finalStr = sprintf("%s, %s, %s, %s", catStr, idStr, LogFnName, sprintf(MsgParams{1}, MsgParams{2}{:}));
            tc.verifySubstring(txt, finalStr);
        end
        function tLoggerNoCat(tc)
            %tLoggerNoCat  Check that empty category arguments skips that in the output
            fPath = fullfile(tc.LogDir, tc.FileNameNoCat);
            idStr = "ID";
            msgStr = "This is a string.";
            logObj = Logger(fPath, "", idStr, "All");
            logObj.logInfo(msgStr);
            txt = join(readlines(fPath), newline);
            % We can't search for a substring, because we don't know the time this is being written.
            % Instead, count the commas.
            tc.verifyLength(strfind(txt, ","), 3, "Empty category wrote too many commas");
        end
        function tLogSpecial(tc)
            %tLogSpecial  Test logging of special characters
            %   Try to write out a newline, and a comma, in the message format
            fPath = fullfile(tc.LogDir, tc.FileName1);
            % Make sure the file is empty.
            if exist(fPath, "file")
                delete(fPath);
            end
            catStr = "Category";
            idStr = "ID";
            msgStr = "This is a string, with a comma.";
            logObj = Logger(fPath, catStr, idStr, "All");
            logObj.logInfo(msgStr);
            txt = join(readlines(fPath), newline);
            % We can't search for a substring, because we don't know the time this is being written.
            % Instead, count the commas.
            tc.verifyLength(strfind(txt, ","), 4, "Comma in the message broke the CSV formatting");
        end 
        function tLogMissing(tc)
            %tLogMissing  Test for missing in message arguments
            %   Because sprintf craps out if you pass it a missing string.
            fPath = fullfile(tc.LogDir, tc.FileNameNoCat);
            % Make sure the file is empty.
            if exist(fPath, "file")
                delete(fPath);
            end
            msgStr = "String1: %s; String2: %s";
            logObj = Logger(fPath);
            logObj.logInfo(msgStr, missing, "2");
            logObj.logInfo(msgStr, "1", missing);
            logLines = readlines(fPath);
            tc.verifySubstring(logLines(1), "String1: ; String2: 2", "Missing followed by string produced wrong output");
            tc.verifySubstring(logLines(2), "String1: 1; String2: ", "Missing after string produced wrong output");
        end
        function tLogRotate(tc)
            %tLogRotate  Test log file rotation
            fName = "test";
            logObj = Logger(fullfile(tc.LogDir, fName+".log"));
            % Set up a really small log size, and limit to 3 backups
            numCharsToFill = 512;
            logObj.LogFileMaxSize = numCharsToFill/(1024^2);
            logObj.LogFileBackupLimit = 3;
            % Now populate the log file with really long strings
            msgString = "The quick brown fox jumped over the lazy dog";
            numMsgToFill = ceil(numCharsToFill/(strlength(msgString)+35)); % 35 characters in the preamble to the message.
            % Generate more than LogFileMaxSize messages
            for k=1:numMsgToFill+1
                logObj.logInfo(msgString);
            end
            % Check the folder. We should have a new file.
            fList = dir(fullfile(tc.LogDir, "*.log"));
            tc.verifyNumElements(fList, 2, "Could not find two files in log folder.");
            tc.verifyTrue(all(ismember(string({fList.name}), [fName+".log", fName+"-001.log"])), ...
                "Backup file not found.");
            % Keep logging messages until the number of files is above BackupLimit. Pause a second
            % between runs to ensure the the file time is different for each backup.
            for fI = 1:logObj.LogFileBackupLimit
                pause(1);
                for k=1:(numMsgToFill)+1
                    logObj.logInfo(msgString);
                end
            end
            fList = dir(fullfile(tc.LogDir, fName+"-*.log"));
            tc.assertLessThanOrEqual(numel(fList), 3, "Found too many backup files in folder.");
            tc.assertGreaterThan(numel(fList), 0, "Found no backup logs in folder.");
            % The newest backup file should be -001, because we have wrapped around
            [~,dtInd] = sort([fList.datenum]);
            tc.verifyEqual(string(fList(dtInd(end)).name), fName+"-001.log", ...
                "Newest backup is not as expected.");
        end
    end
end