classdef ConfiguratorState < int32
    % ConfiguratorState Enumeration for Configurator State
    %
    %   NotRunning (0) - Configurator is not running
    %   Running (1) - Configurator is running
    %   Failed (2) - Configurator failed during last run
    
    enumeration
        NotRunning (0)
        Running (1)
        Failed (2)
    end
end