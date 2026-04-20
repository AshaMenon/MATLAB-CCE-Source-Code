using System;
using SharedLogger;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace cceCoordinator
{
    class Program
    {
        static void Main(string[] args)
        {
            if (args.Length == 0)
            {
                throw new Exception("cceCoordinator needs an argument.");
            }

            var coordID = args[0];
            int cID;

            // The cID could be a string if this is deployed.
            try
            {
                cID = int.Parse(coordID);
            } catch
            {
                var errMsg = string.Format("Could not convert {0} into a number.", coordID);
                throw new Exception(errMsg);
            }

            //Get the Coordinator start time
            DateTime coordinatorStartTime = DateTime.Now;

            // Get the log details
            String logLevel = System.CoordinatorLogLevel;
            String logFileName = System.CoordinatorLogFile;

            // Get enum value from string
            var logLevelInt = (int)((LogMessageLevel)Enum.Parse(typeof(LogMessageLevel), logLevel));

            Logger systemLogger = new Logger(logFileName, "Coordinator", "Coorinator" + coordID, (LogMessageLevel)logLevelInt);

            systemLogger.logInfo(string.Format("Fetching Coordinator {0} properties and calculations", coordID));

            Coordinator coordinatorObj = retrieveCoordinatorWithFallback(cID, systemLogger);

            String logName = coordinatorObj.GetLogName();
            string[] pathArr = logName.Split('\\');

            if (pathArr.Length < 1)
            {
                logName = System.fullfile(System.LogFolder, logName);
            }

            Logger coordLogger = new Logger(logName, "Coordinator", "Coorinator" + coordID, (LogMessageLevel)logLevelInt);
            coordLogger.logInfo(string.Format("Coordinator {0} successfully started.", coordID));

            
        }

        private static Coordinator retrieveCoordinatorWithFallback(int cID, Logger systemLogger)
        {
            throw new NotImplementedException();
        }
    }
}
