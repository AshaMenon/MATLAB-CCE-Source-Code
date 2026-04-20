using System;
using System.Text;
using SharedLogger;

namespace TestLogger
{
    class TestLogger
    {
        static void Main(string[] args)
        {
            Console.WriteLine("Starting TestLogger application.");
            string fileName = @"D:\Scratch\NetLogfile.txt";
            Console.WriteLine("Writing output to {0}", fileName);
            Logger logger = new Logger(fileName, "", "Test", LogMessageLevel.All);
            Console.WriteLine("Logging some messages in ALL level.");
            logger.logInfo("TestLogger application started.");
            logger.logWarning("I don't know what to do with {2}, but I know that {0} {1} {2}", 7, 8, 9);

            logger.LogLevel = LogMessageLevel.Warning;
            logger.logInfo("This message is ignored."); // % Does not get written
            double val = 3.14159;
            logger.logWarning("Unexpected value {0} found. Using default.", val);  // % Gets written
            logger.logError("File not found. Aborting");  // % Gets written
            logger.LogLevel = LogMessageLevel.Info; // % logObj.LogLevel = "Info"
            logger.logInfo("I am an information message");  // % Now gets written
            Console.WriteLine("Log file written. Opening file in default application.");
            System.Diagnostics.Process.Start(fileName);
            Console.WriteLine("Press any key to exit...");
            Console.ReadKey();
        }
    }
}
