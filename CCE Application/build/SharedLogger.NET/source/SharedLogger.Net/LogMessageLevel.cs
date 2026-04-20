namespace SharedLogger
{
    public enum LogMessageLevel: uint
    {
        /*
         * LogMessageLevel describes the severity of the message, and dictates whether messages are written to the logfile (based on the LogLevel of the Logger class).
         */
        None,       // (0)   % Log no messages
        Error,      // (1)   % Error; code is likely to have failed
        Warning,    // (2)   % Warnings; code will continue
        Info,       // (3)   % Informative messages; FYI
        Debug,      // (4)   % Debug messages; More detail than Info
        Trace,      // (5)   % Trace messages: Fine-grained trace information
        All = 255   // (255) % All messages
    }

}
