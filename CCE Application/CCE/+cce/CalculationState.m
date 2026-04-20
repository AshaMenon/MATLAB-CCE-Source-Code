classdef CalculationState < int32
    %CALCULATIONSTATE Enumeration for Calculation States
    %
    %   Disabled (0) - Calculation is temporarily disabled, to allow for fixes before re-enabling.
    %   NotAssigned (1) - Calculation has not been assigned to a Coordinator by a Configurator yet.
    %   Idle (2) - Calculation has been assigned to a Coordinator and is not yet running.
    %   FetchingData (3) - Calculation input data is being retrieved.
    %   Queued (4) - Calculation is waiting to execute, either for a data change, or time.
    %   Running (5) - Calculation function is currently executing.
    %	WritingOutputs (6) - Calculation output is being written to the archive.
    %   Retired (7) - Calculation has been retired and should no longer be executed by a Coordinator.
    %   ConfigurationError (128) -    Calculation is in a configuration error state.
    %                               Calculation configuration must be reviewed and fixed
    %                               before the Calculation will run. See Calculation's
    %                               Last Error for more information.
    
    % Copyright 2021 Opti-Num Solutions (Pty) Ltd
    % Version: $Format:%ci$ ($Format:%h$)
    
    enumeration
        Disabled (0)
        NotAssigned (1)
        Idle (2)
        FetchingData (3)
        Queued (4)
        Running (5)
        WritingOutputs (6)
        Retired (7)
        SystemDisabled (64)
        ConfigurationError (128)
    end
end

