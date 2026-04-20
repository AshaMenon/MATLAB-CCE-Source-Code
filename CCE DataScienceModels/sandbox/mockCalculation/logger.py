"""
Logger Log messages (with log level) to a shared file
The Logger class allows you to configure a logger with a desired log level, and write log
messages at that level and below to a log file or STDOUT. 

Once you have constructed the Logger object, you use the various log* methods to log messages to
the log file, provided your object's LogLevel is at or above the level of the required log
message. This allows your code to define messages to log, while controlling the overall detail
of logging based on the object's LogLevel.

Logger supports multiple clients writing to the same log file, which makes it slower (owing to
needing to open the file each time a message is logged) but shareable. If you need exclusive
access to the log file, use the SimpleLogger class instead.

Logger Properties: [Access]
+ LogFilePath [R]: The full path to the log file. You can pass STDOUT (standard output, i.e.,
command window, command prompt or main log for Production Server) or a relative or absolute
path to a file. The constructor allows you to build a full path out of an environment
variable and relative path if that is required.
+ Category [R]: A category string for the client type. Use categories to group similar clients in a
log file. If empty, the category is not written to the log file; it is inadvisable to log to
the same file from clients with and without Category set.
+ UniqueID [R]: A unique identifier for the specific client.
+ LogLevel [RW]: The logging level to use for the client. Any calls to log messages at a higher
level than LogLevel are ignored.
Log Levels are: None < Error < Warning < Info < Debug < Trace < All

Logger Methods: 
log_error: Log an Error level message
log_warning: Log a Warning level message
log_Info: Log an Information level message
log_debug: Log a Debug level message
log_trace: Log a Trace level message
     
All methods behave like sprintf: Pass a format string and then arguments for each placeholder.
 
Messages are written in CSV format as follows:
YYYY-MM-DDThh:mm:ss.SSS, Category, UniqueID, Severity, Message
Category and the comma are omitted if Category is empty.

Character substitutions: To preserve CSV format, the following characters are replaced.
 + Any comma in the message is replaced by a semicolon (;)
 + Any newline or other line separator is replaced by a vertical bar (|)
      
Copyright 2021 Opti-Num Solutions (Pty) Ltd
developed as background IP during CCE development
Version: $Format:%ci$ ($Format:%h$)
"""
import os
import warnings
import time
import datetime
from log_message_level import LogMessageLevel

class Logger:
    
    
    
    def __init__(self, log_file_name = 'STDOUT',  category = '', unique_id = 'None', log_level = 255, logger_path_env = 'LoggerPath'):
        
        self.logger_path_env = logger_path_env
        self.__EXTENDED_NEW_LINE = ['\n', '\r', '\v', '\f']
        
        
        if log_file_name.lower() == 'STDOUT'.lower():
                self.__is_std_out = True
                self.__log_file_path = "<STDOUT>"
        else:
                self.__is_std_out = False
                env_path = os.getenv(logger_path_env)
                if env_path is None:
                    env_path = ''
                
                self.__log_file_path = os.path.join(env_path, log_file_name)
                log_folder = os.path.split(self.__log_file_path)[0]
                if (len(log_folder) == 0):
                    log_folder =os.getcwd()
                    self.__log_file_path = os.path.join(log_folder, log_file_name)
                    warnings.warn("File path not specified for log file. This could cause ambiguous log file locations.Using current folder %s as the path." %(log_folder));
            
                if  not os.path.isdir(log_folder):
                    warnings.warn("Creating path %s for log file." %(log_folder))
                    os.mkdir(log_folder)
                
                
        # Deal with Category and UniqueID. Strip invalid characters and concatenate for actual write.\
        invalid_chars = [","] + self.__EXTENDED_NEW_LINE
        if any(string in category for string in invalid_chars):
            warnings.warn("Removing disallowed characters from Category.")
            for string in invalid_chars:
                category = category.replace(string,'')
         
        self.__category = category
        if any(string in unique_id for string in invalid_chars):
            warnings.warn("Removing disallowed characters from UniqueID.")
            for string in invalid_chars:
                unique_id = unique_id.replace(string,'')
        
        self.__unique_id = unique_id
        if (len(category) == 0):
            self.__category_and_id = unique_id
        else:
            self.__category_and_id = "%s, %s" %(category, unique_id)
        
        # Set the initial required log level
        if isinstance(log_level, str):
            self.__log_level = LogMessageLevel[log_level]
        else:
            self.__log_level = LogMessageLevel(log_level)  

    def __write_message(self, message, severity):
        """ write_message Write message to log
        Writes the string to the log file if the required severity is at or below the object's log
        level. Attempts to open the file three times before giving up."""
        
        if (severity.value <= self.__log_level.value):
                message = message.replace(",",";");
                for string in self.__EXTENDED_NEW_LINE:
                    message = message.replace(string,"|")
                if self.__is_std_out:
                    timestamp =  datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%S.%f")[:-3]
                    print('%s, %s, %s, %s\n' %(timestamp, self.__category_and_id, severity.name.capitalize(), message))
                else:
                    #Need to open the file for writing, but something else might be doing so. Try a few times.
                    try_count = 1
                    max_attempts = 3
                    trying = True
                    while trying:
                        try:
                            fid = open(self.__log_file_path,'a')
                            trying = False
                        except:
                            try_count = try_count + 1
                            if try_count > max_attempts:
                                warnings.warning("Logger:WriteMessage:FileNotOpened")
                            else:
                                time.sleep(0.1)
                    timestamp =  datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%S.%f")[:-3]
                    fid.write('%s, %s, %s, %s\n' %(timestamp, self.__category_and_id, severity.name.capitalize(), message))
                    fid.close()
                    
    def log_error(self, msg_fmt, *args):
        """log_error  Log an error severity message to the log file."""
        message = msg_fmt %(args);
        self.__write_message(message, LogMessageLevel.ERROR);

    def log_warning(self, msg_fmt, *args):
        """log_warning  Log a warning severity message to the log file."""
        message = msg_fmt %(args);
        self.__write_message(message, LogMessageLevel.WARNING);
        
    def log_info(self, msg_fmt, *args):
        """log_info  Log an information severity message to the log file."""
        message = msg_fmt %(args);
        self.__write_message(message, LogMessageLevel.INFO);
    
    def log_debug(self, msg_fmt, *args):
        """log_debug  Log a debug severity message to the log file."""
        message = msg_fmt %(args);
        self.__write_message(message, LogMessageLevel.DEBUG);
        
    def log_trace(self, msg_fmt, *args):
        """log_trace  Log a trace severity message to the log file."""
        message = msg_fmt %(args);
        self.__write_message(message, LogMessageLevel.TRACE);
