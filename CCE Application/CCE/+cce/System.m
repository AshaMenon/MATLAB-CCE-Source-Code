classdef System < handle
    %cce.System  System configuration accessor
    %
    %   cce.System.* exposes all System configuration properties to MATLAB code. For a list of
    %   properties, type:
    %   >> properties cce.System
    %
    %   For help on a specific property, type:
    %   >> help cce.System.[property]
    %
    %   NOTE: The System configuration is cached for the MATLAB session, or until you 
    %       >> clear classes
    
    properties (Constant) % These will be read from the config file in due course.
        % System-wide properties
        
        %RootFolder: The root folder of the current CCE configuration. Typically C:\CCE unless this is
        %overridden using the CCE_Root system environment variable.
        RootFolder = envOrDefault("CCE_Root", "C:\CCE");
        %ConfigFolder: Folder containing the configuration file. Always <RootFolder>\config
        ConfigFolder = fullfile(cce.System.RootFolder, "config");
        %DbFolder: Folder containing local file-based databases. Always <RootFolder>\db
        DbFolder = fullfile(cce.System.RootFolder, "db");
        %LogFolder: Folder containing system log files. Always <RootFolder>\logs
        LogFolder = fullfile(cce.System.RootFolder, "logs");
        %ServiceType: The database service type. One of "AF", "CSV".
        ServiceType = tomlAccess("System", "ServiceType", 'AF');
        %SchedulerFolderName: The folder housing all CCE Scheduled Task in Windows Scheduler.
        SchedulerFolderName = tomlAccess("System", "SchedulerFolderName", 'CCE');
        %CCEUsername: The user who runs Scheduled Tasks created by CCE.
        CCEUsername = tomlAccess("System", "CCEUsername", 'cceServer');
        %CCEPassword: An encrypted password for the <CCEUserName>. Use cceBootstrap to generate the encrypted string.
        CCEPassword = tomlAccess("System", "CCEPassword", '<NOT SET>');
        %LogFileMaxSize: The maximum size for the coordinator and configurator log files, in MB. After the log file reaches this size, the log file 
        % will be rotated into a backup file, and a new log file will be created.
        LogFileMaxSize = tomlAccess("System", "LogFileMaxSize", 20);
        %LogFileBackupLimit: The number of backup files for each of the coordinator/configurators to keep before the oldest is purged. If this value is set t 
        % 0, then no backups are stored. The maximum number of backups is 999. Backups are named the same as the log file,
        % with "-nnn" appended to the file name.
        LogFileBackupLimit = tomlAccess("System", "LogFileBackupLimit", 20);
        
        % Database access properties
        
        %CalculationServerName: Hostname of the server hosting the calculation database
        CalculationServerName = tomlAccess("CalculationDB", "ServerName", '');
        %CalculationDBName: Name of the database hosting the calculations.
        CalculationDBName = tomlAccess("CalculationDB", "DBName", '');
        %CoordinatorServerName: Hostname of the server hosting the coordinator database. Note that this
        %could be the same as the CalculationServerName, but for security reasons may not be.
        CoordinatorServerName = tomlAccess("CoordinatorDB", "ServerName", '');
        %CalculationDBName: Name of the database hosting the coordinators. Note that this
        %could be the same as the CalculationServerName, but for security reasons may not be.
        CoordinatorDBName = tomlAccess("CoordinatorDB", "DBName", '');

        % Coordinator properties
        
        %CoordinatorLogLevel: Logging level for System Coordinator Log. One of "None", "Debug", "Error",
        %"Warn", "Info", "All". Log messages at the logging level and below will be written.
        CoordinatorLogLevel = tomlAccess("Coordinator", "LogLevel", 'None');
        %CoordinatorLogFile: Name of the log file for system coordinator logging. This will be a CSV
        %plain-text file.
        CoordinatorLogFile = fullfile(cce.System.LogFolder, tomlAccess("Coordinator", "LogFile", "coordinator.log"));
        %CoordinatorMaxLoad: Maximum number of calculations that a coordinator will manage.
        CoordinatorMaxLoad = tomlAccess("Coordinator", "MaxCalculationLoad", 10);
        %CoordinatorLifetime: Lifetime (in seconds) of a Cyclic coordinator. This property is ignored for
        %Manual, Single-shot and Event coordinators.
        CoordinatorLifetime = seconds(tomlAccess("Coordinator", "Lifetime", 12*60*60));
        %CoordinatorLifetimeOverrunPercentage: The percentage (0-1) of the CoordinatorLifetime that a Cyclic coordinator is allowed to
        %overrun before the system forcibly shuts it down. This property is ignored for
        %Manual, Single-shot and Event coordinators.
        CoordinatorLifetimeOverrunPercentage = tomlAccess("Coordinator", "LifetimeOverrunPercentage", 10);
        %CoordinatorFrequencyLimit: The longest frequency (in seconds) that a coordinator
        %can run as a cyclic coordinator with a longer lifetime. If this limit is
        %exceeded, the coordinator will act as a single-shot coordinator run all assigned
        %calculations once, shut-down and restart at the next frequency-interval.
        CoordinatorFrequencyLimit = seconds(tomlAccess("Coordinator", "FrequencyLimit", 10*60));
        
        % Configurator properties
        
        %ConfiguratorLogLevel: Logging level for System Configurator Log. One of "None", "Debug", "Error",
        %"Warn", "Info", "All". Log messages at the logging level and below will be written.
        ConfiguratorLogLevel = tomlAccess("Configurator", "LogLevel", 'None');
        %ConfiguratorLogFile: Name of the log file for system configurator logging. This will be a CSV
        %plain-text file.
        ConfiguratorLogFile = fullfile(cce.System.LogFolder, tomlAccess("Configurator", "LogFile", "configurator.log"));
        
        % Calculation server properties
        
        %CalcServerHostname: Hostname of Calculation Server for thie CCE instance.
        CalcServerHostName = tomlAccess("CalculationServer", "HostName", '');
        %CalcServerPort: Port for Calculation Server for thie CCE instance.
        CalcServerPort = uint16(tomlAccess("CalculationServer", "Port", uint16(9910)));
        %CalcServerAutoDeployFolder: Network path to the Calculation Server AutoDeploy folder.
        CalcServerAutoDeployFolder = tomlAccess("CalculationServer", "AutoDeployFolder", '');
        %CalcServerTimeout: Timeout (seconds) for asynchronous web requests. 
        CalcServerTimeout = tomlAccess("CalculationServer", "RequestTimeout", 10);

        %TestMode: Set to 1 to prevent the System Configurator form making changes to the database and
        %Scheduled Tasks. Set to 0 for normal operation.
        TestMode = tomlAccess("Configurator", "TestMode", 1);
    end
    
    methods (Static)
        function svcObj = getCoordinatorDbService(svcType)
            %getCoordinatorDbService  Retrieve the Coordinator Database Service based on the Service Type.
            %   dbSvc = getCoordinatorDbService retrieves the Coordinator Database Service for the System
            %       Service Type.
            %   dbSvc = getCoordinatorDbService(SvcType) retrieves the Coordinator Database Service for the
            %       given Service Type. SvcType must be one of "AF" or "CSV".
            arguments
                svcType (1,1) string = cce.System.ServiceType;
            end
            switch upper(svcType)
                case "CSV"
                    svcObj = cce.CSVCoordinatorDbService.getInstance();
                case "AF"
                    svcObj = cce.AFCoordinatorDbService.getInstance();
                otherwise
                    error("cce:System:UnknownServiceType", "Unknown service type %s.", svcType);
            end
        end
        function svcObj = getCalculationDbService(svcType)
            %getCalculationDbService  Retrieve the Calculation Database Service based on the Service Type.
            %   dbSvc = getCalculationDbService retrieves the Calculation Database Service for the System
            %       Service Type.
            %   dbSvc = getCalculationDbService(SvcType) retrieves the Calculation Database Service for the
            %       given Service Type. SvcType must be one of "AF" or "CSV".
            arguments
                svcType (1,1) string = cce.System.ServiceType;
            end
            switch upper(svcType)
                case "CSV"
                    svcObj = cce.CSVCalculationDbService.getInstance();
                case "AF"
                    svcObj = cce.AFCalculationDbService.getInstance();
                otherwise
                    error("cce:System:UnknownServiceType", "Unknown service type %s.", svcType);
            end
        end
    end
end

function f = envOrDefault(envVar, defaultFolder)
    f = getenv(envVar);
    if isempty(f)
        f = defaultFolder;
    end
end

function out = tomlAccess(category, property, defaultVal)
    persistent tomlData missingWarned
    if isempty(tomlData)
        try
            tomlData = toml.read(fullfile(cce.System.ConfigFolder, "cce.conf"));
        catch MExc
            if isempty(missingWarned) || (missingWarned == false)
                warning("cce:System:ConfigFileNotFound", ...
                    "Could not find configuration file cce.conf in folder %s.\nMessage was: %s", ...
                    cce.System.ConfigFolder, MExc.getReport);
                missingWarned = true;
            end
            tomlData = struct.empty;
        end
    end
    if isfield(tomlData, category)
        if isempty(property)
            out = tomlData.(category);
        elseif isfield(tomlData.(category), property)
            out = tomlData.(category).(property);
        else
            warning("cce:System:PropertyNotFound", "Property '%s' not found in category [%s]. Using default value.", ...
                property, category);
            out = defaultVal;
        end
    else
        %     warning("cce:System:CategoryNotFound", "Category [%s] not found when retrieving property '%s'. Using default value.", ...
        %         category, property);
        out = defaultVal;
    end
end