using System;
using System.Text;
using System.Text.RegularExpressions;
using System.IO;
using System.Threading.Tasks;
using System.Runtime.InteropServices;

namespace SharedLogger
{
    /*
     * The SharedLogger Class implements a shared logger, taking message requests in SPRINTF format and writing those at or above a specified LogMessageLevel to a file
     */
    public class Logger

    {
        public string LogFilePath;  // Full path to the log file to write to
        public string Category;     // General classification of this message. If omitted this part of the log is not created.
        public string UniqueID;     // Unique Identifier for this logger.

        public LogMessageLevel LogLevel = LogMessageLevel.All;

        private Boolean IsStdOut = true;
        private string CategoryAndID;
        /*
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
        */
        public Logger(string logFileName = @"STDOUT", string category = @"", string uniqueID = @"None", LogMessageLevel logLevel = LogMessageLevel.All, string LoggerPathEnv = @"")
        {
            string argPath;
            // Construct the LogFIlePath
            if (string.Compare(logFileName, "STDOUT", true) == 0)
            {
                this.IsStdOut = true;
                this.LogFilePath = @"<STDOUT>"; // Strictly don't need this as it's never used
            }
            else
            {
                this.IsStdOut = false;

                // Construct the full path to the log file and create the directory if it does not exist.
                // Do we have an environment variable to fetch?
                string envPath = null;
                if (!string.IsNullOrEmpty(LoggerPathEnv))
                {
                    envPath = Environment.GetEnvironmentVariable(LoggerPathEnv);
                }
                if (string.IsNullOrEmpty(envPath))
                {
                    argPath = logFileName;
                }
                else
                {
                    argPath = Path.Combine(envPath, logFileName);
                }
                // Now strip out the folder and filename
                string logFolder = Path.GetDirectoryName(argPath);
                string argFilename = Path.GetFileName(argPath);
                if (string.IsNullOrEmpty(logFolder))
                {
                    logFolder = Directory.GetCurrentDirectory();
                    // TODO: Throw a warning at the cmd-line.
                }
                this.LogFilePath = Path.Combine(logFolder, argFilename);
                if (Directory.Exists(logFolder) == false)
                {
                    // Construct the path
                    Directory.CreateDirectory(logFolder);
                    // TODO: warning("Logger:Logger:PathCreated", "Creating path %s for log file.", logFolder);
                }

                // % Deal with Category and UniqueID. Strip invalid characters and concatenate for actual write.\
                this.Category = System.Text.RegularExpressions.Regex.Replace(category, @"[\r\n\v\f,]", string.Empty);
                this.UniqueID = System.Text.RegularExpressions.Regex.Replace(uniqueID, @"[\r\n\v\f,]", string.Empty);

                // % Construct the combined Category and UniqueID string
                if (string.IsNullOrEmpty(Category))
                {
                    this.CategoryAndID = UniqueID;
                }
                else
                {
                    this.CategoryAndID = Category + ", " + UniqueID;
                }
                // % Set the initial required log level
                this.LogLevel = logLevel;
            }
        } // end Logger

        private async Task writeMessage(LogMessageLevel severity, string msgFmt, Object[] args)
        {
            if (severity <= this.LogLevel)
            {
                // TODO: Make this type safe (catch errors)
                string message = string.Format(msgFmt, args);
                // % Replace special characters with vertical bar
                message = Regex.Replace(message, @"[\r\n\v\f]", @"|");
                // % Replace commas with semi-colons
                message = Regex.Replace(message, @",", @";") + Environment.NewLine;
                // Write the message
                string lineToWrite = string.Format("{0}, {1}, {2}, {3}", DateTime.Now, this.CategoryAndID, severity.ToString(), message);
                if (this.IsStdOut)
                {
                    Console.WriteLine(lineToWrite);
                }
                else
                {
                    UnicodeEncoding uniencoding = new UnicodeEncoding();
                    byte[] result = uniencoding.GetBytes(lineToWrite);
                    using (FileStream SourceStream = File.Open(this.LogFilePath, FileMode.OpenOrCreate))
                    {
                        SourceStream.Seek(0, SeekOrigin.End);
                        await SourceStream.WriteAsync(result, 0, result.Length);
                    }
                }
            }
        } // end writeMessage

        public async void logError(string msgFmt, [Optional] params Object[] args)
        {
            await this.writeMessage(LogMessageLevel.Error, msgFmt, args);
        }
        public async void logWarning(string msgFmt, [Optional] params Object[] args)
        {
            await this.writeMessage(LogMessageLevel.Warning, msgFmt, args);
        }
        public async void logInfo(string msgFmt, [Optional] params Object[] args)
        {
            await this.writeMessage(LogMessageLevel.Info, msgFmt, args);
        }
        public async void logDebug(string msgFmt, [Optional] params Object[] args)
        {
            await this.writeMessage(LogMessageLevel.Debug, msgFmt, args);
        }
        public async void logTrace(string msgFmt, [Optional] params Object[] args)
        {
            await this.writeMessage(LogMessageLevel.Trace, msgFmt, args);
        }

    }
}
