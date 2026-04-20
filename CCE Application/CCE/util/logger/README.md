# SharedLogger

Shared Logger class. Instantiate a Logger class from multiple actors (clients) and write 
to the same log file. Rotate log files when they get too big. Echo log output to STDOUT.

The Logger class allows you to configure a logger with a desired log level, and write log
messages at that level and below to a log file and/or STDOUT. 

Once you have constructed the Logger object, you use the various `log*` methods to log messages to
the log file, provided your object's `LogLevel` is at or above the level of the required log
message. This allows your code to define messages to log, while controlling the overall detail
of logging based on the object's `LogLevel`.

Logger supports multiple clients writing to the same log file, which makes it slower (owing to
needing to open the file each time a message is logged) but shareable. If you need exclusive
access to the log file, use the SimpleLogger class instead.

Logger rotates log files when they reach a maximum size limit. You control the log file size and 
number of backups to keep.

### Logger Properties
Access to properties is shown in square braces
- `LogFilePath` [R]: The full path to the log file. You can pass STDOUT (standard output, i.e.,
command window, command prompt or main log for Production Server) or a relative or absolute
path to a file. The constructor allows you to build a full path out of an environment
variable and relative path if that is required.
- `Category` [R]: A category string for the client type. Use categories to group similar clients in a
log file. If empty, the category is not written to the log file; it is inadvisable to log to
the same file from clients with and without Category set.
- `UniqueID` [R]: A unique identifier for the specific client.
- `LogLevel` [RW]: The logging level to use for the client. Any calls to log messages at a higher
	level than `LogLevel` are ignored. For instance, a LogLevel of "Info" will silently ignore any logWarning or 
	logError calls.
- `Echo` [RW]: Set to true to to print log messages to STDOUT as well as the log file. Note that if `Echo` is set to 
	true and `LogFilePath` is set to STDOUT, duplicate messages are displayed in STDOUT.

Log Levels are: `None` < `Error` < `Warning` < `Info` < `Debug` < `Trace` < `All`

### Log Rotation Properties
- `LogFileMaxSize` [RW]: The maximum size for the log file, in MB. After the log file reaches this size, the log file
    will be rotated into a backup file, and a new log file will be created. You control the number of backups based
    on `LogFileBackupLimit`. A value of 0 means no maximum size and no rotation takes place.
- `LogFileBackupLimit` [RW]: The number of backup files to keep before the oldest is purged. If this value is set t
    0, then no backups are stored. The maximum number of backups is 999. Backups are named the same as the log file,
    with "-nnn" appended to the file name. For exampe, if the LogFilePath is set to D:\logs\myFile.log, the first
    backup will be named D:\logs\myFile-001.log, then myFile-002.log, and so on, until LogFileBackupLimit is
    reached, and then the backup will overwrite myFile-001.log, then myFile-002.log, and so on. Logger does not fill
    in gaps if you delete a backup file; it will always write to one index more (with wrapping) than the newest file
    in the backup list.

### Logger Methods
- `logTrace`: Log a Trace level message
- `logDebug`: Log a Debug level message
- `logError`: Log an Error level message
- `logWarning`: Log a Warning level message
- `logInfo`: Log an Information level message

All methods behave like `sprintf`: Pass a format string and then arguments for each placeholder.
 
Messages are written in CSV format as follows:
```
    YYYY-MM-DDThh:mm:ss.SSS, Category, UniqueID, Severity, Message
```
Category and the comma are omitted if `Category` is empty.

### Other Behaviour
**Character substitutions**: To preserve CSV format, the following characters are replaced.
- Any comma in the message is replaced by a semicolon (`;`)
- Any newline or other line separator is replaced by a vertical bar (`|`)

** Use of an environment variable**: The constructor allows you to specify an environment variable to use as a log file path prefix. By default this is `LoggerPath` but can be overridden in the Logger constructor. You can also set this value using a custom class (e.g. `MyLogger`) sub-classed from `Logger` that reads the log file prefix from `MyEnvVar` like this:
```
classdef MyLogger < Logger
    methods
        function obj = MyLogger(logFileName, category, uniqueID, logLevel)
            obj = obj@Logger(logFileName, category, uniqueID, logLevel, "MyEnvVar");
        end
    end
end
```

## Status
This project came out of the AngloPlat CCE project, and so many of the examples and tests 
didn't make it into this repo. You should probably talk to Kim or Dean R about this repo 
if you want to use it. Otherwise consult the help for Logger.

Tasks to complete include:
- Move the LogMessageLevel enum into the Logger class, and provide for extension of those through subclassing.
- Make it easier to subclass a specific Environment Variable setting for a project. (Comes out of CCE implementation)
