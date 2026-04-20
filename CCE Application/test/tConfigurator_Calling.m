classdef tConfigurator_Calling < matlab.unittest.TestCase
    %tConfigurator_Calling Test COnfigurator calling syntax
    %   Tests the calling syntax of a CCE configurator.
    %
    %   Relies on configuration files passing.conf and bad.conf in resources\configurator folder.
    %
    %   NOTE: Do not create a missing.conf file.
    
    % Copyright 2021 Opti-Num Solutions (Pty) Ltd
    % Version: $Format:%ci$ ($Format:%h$)
    
    properties (Constant)
        ConfigPathRoot = fullfile(fileparts(mfilename("fullpath")),"resources","configurator");
        ConfigFileGood = "passing.conf";
        ConfigFileBad = "bad.conf";
        ConfigFileMissing = "missing.conf"; % Do not ever create this file!
    end
    properties (Transient)
        CCEConfigFileEnv = "";
    end
    
    methods (TestMethodSetup)
        function storeConfigEnv(tc)
            tc.CCEConfigFileEnv = getenv("CCE_Config_File");
        end
    end
    methods (TestMethodTeardown)
        function restoreConfigEnv(tc)
            setenv("CCE_Config_File", tc.CCEConfigFileEnv);
        end
    end
    
    methods (Test)
        function tConfiguratorConfigFile(tc)
            %tConfiguratorDefault Check configurator behaviour for configuration files
            
            % T1 - Calling with no config and no environment variable will fail with error
            
            tc.verifyError(@cceConfigurator, "CCE:Configurator:DefaultConfigPathMissing", ...
                "Calling configurator with no environment set up does not produce expected error.");
            
            % T2 - Calling with an environment variable set but no file will fail with error
            setenv("CCE_Config_File", fullfile(tc.ConfigPathRoot, tc.ConfigFileMissing));
            tc.verifyError(@cceConfigurator, "CCE:Configurator:ConfigFileNotFound", ...
                "Calling configurator with Environment Variable incorrectly set up does not produce expected error.");
            
            % T3 - Calling the Configurator with a missing AFDatabaseEntry will fail with error
            setenv("CCE_Config_File", fullfile(tc.ConfigPathRoot, tc.ConfigFileBad));
            tc.verifyError(@cceConfigurator, "CCE:Configurator:AFDatabaseNotFound", ...
                "Calling configurator with bad config up does not produce expected error.");
            
            % T4 - Calling the Configurator with a defined config file overrides the default
            setenv("CCE_Config_File", "");
            cceConfigurator("-config", fullfile(tc.ConfigPathRoot, tc.ConfigFileGood));
        end
    end
end

