classdef Logger
    %LOGGER  Log messages (with log level) to a shared file
    %   The Logger class allows you to configure a logger with a desired log level, and write log
    %   messages at that level and below to a log file or STDOUT. 
    %
    %   Once you have constructed the Logger object, you use the various log* methods to log messages to
    %   the log file, provided your object's LogLevel is at or above the level of the required log
    %   message. This allows your code to define messages to log, while controlling the overall detail
    %   of logging based on the object's LogLevel.
    %
    %   Logger supports multiple clients writing to the same log file, which makes it slower (owing to
    %   needing to open the file each time a message is logged) but shareable. If you need exclusive
    %   access to the log file, use the SimpleLogger class instead.
    %
    %   Logger Properties: [Access]
    %   + LogFilePath [R]: The full path to the log file. You can pass STDOUT (standard output, i.e.,
    %       command window, command prompt or main log for Production Server) or a relative or absolute
    %       path to a file. The constructor allows you to build a full path out of an environment
    %       variable and relative path if that is required.
	%	+ Echo [RW]: Set to true to print log messages to STDOUT as well as the log file. Note that if Echo is set to true
	%		and LogFilePath is set to STDOUT, duplicate messages are displayed in STDOUT.
    %   + Category [R]: A category string for the client type. Use categories to group similar clients in a
    %       log file. If empty, the category is not written to the log file; it is inadvisable to log to
    %       the same file from clients with and without Category set.
    %   + UniqueID [R]: A unique identifier for the specific client.
    %   + LogLevel [RW]: The logging level to use for the client. Any calls to log messages at a higher
    %       level than LogLevel are ignored.
    %       Log Levels are: None < Error < Warning < Info < Debug < Trace < All
    %
    %   Properties affecting log file size:
    %   + LogFileMaxSize [RW]: The maximum size for the log file, in MB. After the log file reaches this size, the log file
    %       will be rotated into a backup file, and a new log file will be created. You control the number of backups based
    %       on LogFileBackupLimit. A value of 0 means no maximum size and no rotation takes place.
    %   + LogFileBackupLimit [RW]: The number of backup files to keep before the oldest is purged. If this value is set to
    %       0, then no backups are stored. The maximum number of backups is 999. Backups are named the same as the log file,
    %       with "-nnn" appended to the file name. For exampe, if the LogFilePath is set to D:\logs\myFile.log, the first
    %       backup will be named D:\logs\myFile-001.log, then myFile-002.log, and so on, until LogFileBackupLimit is
    %       reached, and then the backup will overwrite myFile-001.log, then myFile-002.log, and so on. Logger does not fill
    %       in gaps if you delete a backup file; it will always write to one index more (with wrapping) than the newest file
    %       in the backup list.
    %
    %   Logger Methods: 
    %       logError: Log an Error level message
    %       logWarning: Log a Warning level message
    %       logInfo: Log an Information level message
    %       logDebug: Log a Debug level message
    %       logTrace: Log a Trace level message
    %       
    %   All methods behave like sprintf: Pass a format string and then arguments for each placeholder.
    %
    %   Messages are written in CSV format as follows:
    %       YYYY-MM-DDThh:mm:ss.SSS, Category, UniqueID, Severity, Message
    %   Category and the comma are omitted if Category is empty.
    %
    %   Character substitutions: To preserve CSV format, the following characters are replaced.
    %       + Any comma in the message is replaced by a semicolon (;)
    %       + Any newline or other line separator is replaced by a vertical bar (|)
      
    % Copyright 2021-2023 Opti-Num Solutions (Pty) Ltd
    % developed as background IP during CCE development
    % Version: $Format:%ci$ ($Format:%h$)

    properties (SetAccess = private)
        % The full pathto the log file, or STDOUT
        LogFilePath (1,1) string
        % A grouping category string. If empty, the category is not written to the log file
        Category (1,1) string
        % A unique identifier for the specific client.
        UniqueID (1,1) string
    end
    properties
        % The logging level to use for the client. Log Levels are: None < Error < Warning < Info < Debug < Trace < All
        LogLevel (1,1) LogMessageLevel = LogMessageLevel.All
        % The maximum size for the log file, in MB, before it is rotated to a backup. A value of 0 means no rotation.
        LogFileMaxSize (1,1) double = 0
        % The number of backup files to keep before the oldest is purged.A value of 0 means no backups are created.
        LogFileBackupLimit (1,1) uint16 = uint16(0)
        Echo (1,1) logical = false % Do we echo to stdout?
    end
    properties (Access = private)
        IsStdOut (1,1) logical
        CategoryAndID (1,1) string
        FilePath (1,1) string
        FileName (1,1) string
        FileExt (1,1) string
    end
    properties (Constant, Access = private)
        ExtendedNewline = [newline, sprintf("\r"), sprintf("\v"), sprintf("\f")];
    end
    
    methods
        function obj = Logger(logFileName, category, uniqueID, logLevel, loggerPathEnv)
            %Logger  Construct a shared logger class
            %   lObj = Logger(LogFilePath, Category, UniqueID, LogLevel, LoggerPathEnv) creates a message
            %       interface to a CSV log file at the concatenation of getenv(LoggerPathEnv) and LogFilePath.
            %       All log messages from lObj are tagged with the given Category and UniqueID.
            %
            %   Arguments:
            %   + LogFileName [R]: The relative or absolute path name of the log file. You can pass STDOUT
            %   (standard output, i.e.,
            %       command window, command prompt or main log for Production Server) or a relative or absolute
            %       path to a file. LogFileName is prefixed by getenv(LoggerPathEnv) to derive the final log
            %       file path.
            %   + Category [R]: A category string for the client type. Use categories to group similar clients
            %       in a log file. If empty, the category is not written to the log file; it is inadvisable to
            %       log to the same file from clients with and without Category set.
            %   + UniqueID [R]: A unique identifier for the specific client. 
            %   + LogLevel [RW]: The logging level to use for the client. Any calls to log messages at a higher
            %       level than LogLevel are ignored. 
            %       Log Levels are: None < Info < Warning < Error < Debug < All
            %   + LoggerPathEnv: The system environment variable to read as a prefix to the LogFileName. Use
            %       this to set a system-wide log file path. The default value is "LoggerPath". The LogFilePath
            %       is the fullfile combination of getenv(LoggerPathEnv) and LogFileName.
            %
            %   LogFilePath need not exist prior to creating the Logging object. If the path does not exist, it
            %   is created with a warning. If the file does not exist, it is automatically created.
            %
            %   Typically Category is not specific to the object, but UniqueID is specific, however this is not
            %   enforced. You can also set Category empty if that is not relevant, but all clients writing to the
            %   same log file should then use an empty Category.
            %
            %   You control the level of logging through the LogLevel of lObj. The default value if not passed
            %   is All. Any log message written through lObj with a severity level above the LogLevel set by
            %   lObj will be silently ignored. You can change LogLevel during the lifetime of lObj, but no other
            %   parameters.
            %
            %   Log Levels are: None < Info < Warning < Error < Debug < All
            %
            %   Write messages to the log file using logDebug, logError, logWarning, and logInfo methods. Each
            %   log* method takes the message format string and arguments (see |sprintf| for syntax).
            %
            %   Character substitutions: To preserve CSV format, the following characters are replaced.
            %       + Any comma in the message is replaced by a semicolon (;)
            %       + Any newline or other line separator is replaced by a vertical bar (|)
            %
            %   Example: Create a logger object and only write messages at warning level and below.
            %       logObj = Logger("C:\Temp\Example.log", "Examples", "Example1", "Warning")
            %       logObj.logInfo("This message is ignored.") % Does not get written
            %       logObj.logWarning("Unexpected value %d found. Using default.", val);  % Gets written
            %       logObj.logError("File not found. Aborting");  % Gets written
            %       % Now change the log level to include information messages
            %       logObj.LogLevel = "Info"
            %       logObj.logInfo("I am an information message") % Now gets written

            arguments
                logFileName (1,1) string = "STDOUT"
                category (1,1) string = ""
                uniqueID (1,1) string = "None"
                logLevel (1,1) LogMessageLevel = LogMessageLevel.All
                loggerPathEnv (1,1) string = "LoggerPath"
            end

            % Construct the LogFilePath. If it ends with STDOUT, we write to console
            if endsWith(logFileName, "STDOUT", "Ignorecase",true)
                obj.IsStdOut = true;
                obj.LogFilePath = "<STDOUT>";
            else
                obj.IsStdOut = false;
                obj.LogFilePath = fullfile(getenv(loggerPathEnv), logFileName);
                % Now split this out for the log rotation algorithm
                [obj.FilePath, obj.FileName, obj.FileExt] = fileparts(obj.LogFilePath);
                if (strlength(obj.FilePath) == 0)
                    obj.FilePath = pwd;
                    obj.LogFilePath = fullfile(obj.FilePath, logFileName);
                    warning("Logger:Logger:RelativeFilePath", "%s %s\n%s", ...
                        "File path not specified for log file. " ,...
                        "This could cause ambiguous log file locations." ,...
                        sprintf("Using current folder %s as the path.", obj.FilePath));
                end
                if ~exist(obj.FilePath, "dir")
                    warning("Logger:Logger:PathCreated", "Creating path %s for log file.", obj.FilePath);
                    mkdir(obj.FilePath);
                end
            end
            
            % Deal with Category and UniqueID. Strip invalid characters and concatenate for actual write.\
            invalidChars = [",", obj.ExtendedNewline];
            if contains(category, invalidChars)
                warning("Logger:Category:DisallowedChars", "Removing disallowed characters from Category.");
                category = replace(category, invalidChars, "");
            end
            obj.Category = category;
            if contains(uniqueID, invalidChars)
                warning("Logger:UniqueID:DisallowedChars", "Removing disallowed characters from UniqueID.");
                uniqueID = replace(uniqueID, invalidChars, "");
            end
            obj.UniqueID = uniqueID;
            if (strlength(category) == 0)
                obj.CategoryAndID = uniqueID;
            else
                obj.CategoryAndID = sprintf("%s, %s", category, uniqueID);
            end
            % Set the initial required log level
            obj.LogLevel = logLevel;
        end
    end
    
    methods (Access = private)
        function writeMessage(obj,severity, msgFmt, varargin)
            %WRITEMESSAGE Write message to log
            %   Writes the string to the log file if the required severity is at or below the object's log
            %   level. Attempts to open the file three times before giving up.
            arguments
                obj (1,1) Logger
                severity (1,1) LogMessageLevel
                msgFmt (1,1) string
            end
            arguments (Repeating)
                varargin
            end
            % Replace missing in arguments with empty string
            for k=1:numel(varargin)
                if ismissing(varargin{k})
                    varargin{k} = "";
                end
            end
            % Now do a safe conversion, reporting the failure as an error if it doesn't work
            try
                message = sprintf(msgFmt, varargin{:});
            catch MExc
                message = sprintf("Logger Error: Message construction failed with message: '%s'", MExc.message);
                severity = LogMessageLevel.Error;
                warning("Logger:writeMessage:InvalidMessageArguments", "Failed to construct message: '%s'", MExc.message);
            end
            if (severity <= obj.LogLevel)
                message = replace(message, ",",";");
                message = replace(message, obj.ExtendedNewline,"|");
                if obj.IsStdOut
                    fid = 1;
                else
                    % Need to open the file for writing, but something else might be doing so. Try a few times.
                    tryCount = 1;
                    maxAttempts = 3;
                    keepTrying = true;
                    while keepTrying
                        try
                            % First check the log file size.
                            checkAndRotateLogFile(obj);
                            % Then try to open it
                            fid = fopen(obj.LogFilePath,'a');
                            keepTrying = false;
                        catch
                            tryCount = tryCount + 1;
                            if tryCount > maxAttempts
                                warning("Logger:WriteMessage:FileNotOpened", "Failed to open file. Could not write message.");
                                return;
                            else
                                pause(0.1);
                            end
                        end
                    end
                    if (fid == -1)
                        error("Logger:WriteMessage:InvalidFilePath", "Previously valid file path is now invalid. External changes have removed a folder and/or file.");
                    end
                end
                timestamp = datetime('now', 'Format', 'uuuu-MM-dd''T''HH:mm:ss.SSS');
                fprintf(fid, '%s, %s, %s, %s\n', timestamp, obj.CategoryAndID, severity, message);
                if obj.Echo
                    fprintf(1, '%s, %s, %s, %s\n', timestamp, obj.CategoryAndID, severity, message);
                end
                if ~obj.IsStdOut
                    fclose(fid);
                end
            end
        end
    end
    methods % Useful logging methods
        function logError(obj, msgFmt, varargin)
            %logError  Log an error severity message to the log file.
            obj.writeMessage(LogMessageLevel.Error, msgFmt, varargin{:});
        end
        function logWarning(obj, msgFmt, varargin)
            %logWarning  Log a warning severity message to the log file.
            obj.writeMessage(LogMessageLevel.Warning, msgFmt, varargin{:});
        end
        function logInfo(obj, msgFmt, varargin)
            %logInfo  Log an information severity message to the log file.
            obj.writeMessage(LogMessageLevel.Info, msgFmt, varargin{:});
        end
        function logDebug(obj, msgFmt, varargin)
            %logDebug  Log a debug severity message to the log file.
            obj.writeMessage(LogMessageLevel.Debug, msgFmt, varargin{:});
        end
        function logTrace(obj, msgFmt, varargin)
            %logTrace  Log a trace severity message to the log file.
            obj.writeMessage(LogMessageLevel.Trace, msgFmt, varargin{:});
        end
    end
    methods (Access = protected)
        function checkAndRotateLogFile(obj)
            %checkAndRotateLogFile  Log File rotation algorithm
            if ((obj.LogFileMaxSize > 0) && exist(obj.LogFilePath, "file")) % Need to check file size
                fInfo = dir(obj.LogFilePath);
                logSizeMB = fInfo.bytes/(1024^2);
                if (logSizeMB >= obj.LogFileMaxSize)
                    % Need to rotate files.
                    existingBackupFiles = dir(fullfile(obj.FilePath, obj.FileName+"-*"+obj.FileExt));
                    if numel(existingBackupFiles) == 0
                        nextInd = 1;
                    else
                        % Sort dates, and use next number in the sequence. This ignores skipped numbers, by design.
                        existingDatenum = [existingBackupFiles.datenum];
                        [~,dtInd] = sort(existingDatenum);
                        lastInd = sscanf(existingBackupFiles(dtInd(end)).name, obj.FileName+"-"+"%d.");
                        nextInd = lastInd+1;
                        if (nextInd > obj.LogFileBackupLimit)
                            nextInd = 1;
                        end
                    end
                    bkpFileName = sprintf("%s-%03d%s", obj.FileName, nextInd, obj.FileExt);
                    copyfile(obj.LogFilePath, fullfile(obj.FilePath, bkpFileName));
                    delete(obj.LogFilePath);
                end
            end
        end
    end
end
