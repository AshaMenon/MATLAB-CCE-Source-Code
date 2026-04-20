using System;
using System.Collections.Generic;
using System.Linq;
using System.IO;
using System.Text;
using System.Threading.Tasks;
using Tomlyn;
using Tomlyn.Model;

namespace cceCoordinator
{
    class System
    {
        // System-wide properties
        
        //RootFolder: The root folder of the current CCE configuration.Typically C:\CCE unless this is
        //overridden using the CCE_Root system environment variable.
        public static String RootFolder = "C:\\CCE";
        //ConfigFolder: Folder containing the configuration file.Always<RootFolder>\config
        public static String ConfigFolder = fullfile(RootFolder, "config");
        //DbFolder: Folder containing local file-based databases.Always<RootFolder>\db
        public static String DbFolder = fullfile(RootFolder, "db");
        //LogFolder: Folder containing system log files.Always<RootFolder>\logs
        public static String LogFolder = fullfile(RootFolder, "logs");
        //ServiceType: The database service type.One of "AF", "CSV".
        public static String ServiceType = tomlAccess("System", "ServiceType", "AF");
        //SchedulerFolderName: The folder housing all CCE Scheduled Task in Windows Scheduler.
        public static String SchedulerFolderName = tomlAccess("System", "SchedulerFolderName", "CCE");
        //CCEUsername: The user who runs Scheduled Tasks created by CCE.
        public static String CCEUsername = tomlAccess("System", "CCEUsername", "cceServer");
        //CCEPassword: An encrypted password for the<CCEUserName>.Use cceBootstrap to generate the encrypted string.
        public static String CCEPassword = tomlAccess("System", "CCEPassword", "<NOT SET>");
        //LogFileMaxSize: The maximum size for the coordinator and configurator log files, in MB.After the log file reaches this size, the log file
        // will be rotated into a backup file, and a new log file will be created.
        public static String LogFileMaxSize = tomlAccess("System", "LogFileMaxSize", "20");
        //LogFileBackupLimit: The number of backup files for each of the coordinator/configurators to keep before the oldest is purged.If this value is set t 
        // 0, then no backups are stored.The maximum number of backups is 999. Backups are named the same as the log file,
        // with "-nnn" appended to the file name.
        public static String LogFileBackupLimit = tomlAccess("System", "LogFileBackupLimit", "20");

        // Database access properties

        //CalculationServerName: Hostname of the server hosting the calculation database
        public static String CalculationServerName = tomlAccess("CalculationDB", "ServerName", "");
        //CalculationDBName: Name of the database hosting the calculations.
        public static String CalculationDBName = tomlAccess("CalculationDB", "DBName", "");
        //CoordinatorServerName: Hostname of the server hosting the coordinator database. Note that this
        //could be the same as the CalculationServerName, but for security reasons may not be.
        public static String CoordinatorServerName = tomlAccess("CoordinatorDB", "ServerName", "");
        //CalculationDBName: Name of the database hosting the coordinators.Note that this
        //could be the same as the CalculationServerName, but for security reasons may not be.
        public static String CoordinatorDBName = tomlAccess("CoordinatorDB", "DBName", "");

        // Coordinator properties

        //CoordinatorLogLevel: Logging level for System Coordinator Log.One of "None", "Debug", "Error",
        //"Warn", "Info", "All". Log messages at the logging level and below will be written.
        public static String CoordinatorLogLevel = tomlAccess("Coordinator", "LogLevel", "None");
        //CoordinatorLogFile: Name of the log file for system coordinator logging.This will be a CSV
        //plain-text file.
        public static String CoordinatorLogFile = fullfile(LogFolder, tomlAccess("Coordinator", "LogFile", "coordinator.log"));
        //CoordinatorMaxLoad: Maximum number of calculations that a coordinator will manage.
        public static String CoordinatorMaxLoad = tomlAccess("Coordinator", "MaxCalculationLoad", "10");
        //CoordinatorLifetime: Lifetime (in seconds) of a Cyclic coordinator. This property is ignored for
        //Manual, Single-shot and Event coordinators.
        public static int CoordinatorLifetime = int.Parse(tomlAccess("Coordinator", "Lifetime", "43200"));
        //CoordinatorLifetimeOverrunPercentage: The percentage (0-1) of the CoordinatorLifetime that a Cyclic coordinator is allowed to
        //overrun before the system forcibly shuts it down. This property is ignored for
        //Manual, Single-shot and Event coordinators.
        public static String CoordinatorLifetimeOverrunPercentage = tomlAccess("Coordinator", "LifetimeOverrunPercentage", "10");
        //CoordinatorFrequencyLimit: The longest frequency (in seconds) that a coordinator
        //can run as a cyclic coordinator with a longer lifetime. If this limit is
        //exceeded, the coordinator will act as a single-shot coordinator run all assigned
        //calculations once, shut-down and restart at the next frequency-interval.
        public static int CoordinatorFrequencyLimit = int.Parse(tomlAccess("Coordinator", "FrequencyLimit", "600"));

        // Configurator properties

        //ConfiguratorLogLevel: Logging level for System Configurator Log. One of "None", "Debug", "Error",
        //"Warn", "Info", "All". Log messages at the logging level and below will be written.
        public static String ConfiguratorLogLevel = tomlAccess("Configurator", "LogLevel", "None");
        //ConfiguratorLogFile: Name of the log file for system configurator logging. This will be a CSV
        //plain-text file.
        public static String ConfiguratorLogFile = fullfile(LogFolder, tomlAccess("Configurator", "LogFile", "configurator.log"));

        // Calculation server properties

        //CalcServerHostname: Hostname of Calculation Server for thie CCE instance.
        public static String CalcServerHostName = tomlAccess("CalculationServer", "HostName", "");
        //CalcServerPort: Port for Calculation Server for thie CCE instance.
        public static UInt16 CalcServerPort = UInt16.Parse(tomlAccess("CalculationServer", "Port", "9910"));
        //CalcServerAutoDeployFolder: Network path to the Calculation Server AutoDeploy folder.
        public static String CalcServerAutoDeployFolder = tomlAccess("CalculationServer", "AutoDeployFolder", "");
        //CalcServerTimeout: Timeout (seconds) for asynchronous web requests. 
        public static String CalcServerTimeout = tomlAccess("CalculationServer", "RequestTimeout", "10");

        //TestMode: Set to 1 to prevent the System Configurator form making changes to the database and
        //Scheduled Tasks. Set to 0 for normal operation.
        public static String TestMode = tomlAccess("Configurator", "TestMode", "1");

        public static String fullfile(String str1, String str2)
        {
            return str1 + "\\" + str2;
        }
        public static String tomlAccess(String category, String property, String defaultValue)
        {
            String outVal;
            var tomlData = File.ReadAllText(fullfile(System.ConfigFolder, "cce.conf"));
            var model = Toml.ToModel(tomlData);

            if (model.ContainsKey(category)) // category exists
            {
                if (String.IsNullOrEmpty(property)) // property empty
                {
                    outVal = model[category].ToString();
                } else if (((TomlTable)model[category]).ContainsKey(property)) //property exists
                {
                    outVal = ((TomlTable)model[category])[property].ToString();
                } else
                {
                    outVal = defaultValue;
                }

            }else
            {
                outVal = defaultValue;
            }
            return outVal;
        }
    }
}
