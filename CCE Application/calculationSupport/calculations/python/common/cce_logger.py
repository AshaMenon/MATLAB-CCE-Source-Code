"""CCELogger  Specialisation of Logger class to maks environment variable name from authors.
CCE needs to use a different special environment variable but not make it a requirement for 
Calculation authors to set the environment variable. This class overrides the constructor to
achieve this requirement."""

import logger

class CCELogger(logger.Logger):
    
    """Logger  Construct a shared logger class
       self = Logger(LogFilePath, Category, UniqueID, LogLevel) creates a message
           interface to a CSV log file at the concatenation of getenv("CCE_Calc_Logs") and LogFilePath.
           All log messages from lObj are tagged with the given Category and UniqueID.
    
       Arguments:
       + LogFileName [R]: The relative or absolute path name of the log file. You can pass STDOUT
       (standard output, i.e.,
           command window, command prompt or main log for Production Server) or a relative or absolute
           path to a file. LogFileName is prefixed by getenv(LoggerPathEnv) to derive the final log
           file path.
       + Category [R]: A category string for the client type. Use categories to group similar clients
           in a log file. If empty, the category is not written to the log file; it is inadvisable to
           log to the same file from clients with and without Category set.
       + UniqueID [R]: A unique identifier for the specific client. 
       + LogLevel [RW]: The logging level to use for the client. Any calls to log messages at a higher
           level than LogLevel are ignored. 
           Log Levels are: None < Info < Warning < Error < Debug < All"""
           
    def __init__(self, log_file_name, category, unique_id, log_level):
        logger_path_env = "CCE_Calc_Logs"
        super().__init__(log_file_name, category, unique_id, log_level, logger_path_env)
    