classdef CoordinatorState < int32
    % CoordinatorState Enumeration for Coordinator State
    %
    %   Disabled (0) - Coordinator is turned off
    %   NotRunning (1) - Coordinator is not running
    %   Starting (2) - Coordinator is staring up; fetching calculation configurations
    %   Idle (3) - Coordinator is waiting for the next trigger (cyclic or event)
    %   Backfilling (4) - Coordinator is backfilling a prior calculation
    %   Executing (5) - Coordinator is executing a current calculation
    %   ShuttingDown (6) - Coordinator is shutting down; lifetime exceeded
    %   ForDeletion (7) - Coordinator has a zero Calculation load and must be deleted from
    %   the Coordinator Database
    
    % Copyright 2021 Opti-Num Solutions (Pty) Ltd
    % Version: $Format:%ci$ ($Format:%h$)
    
    enumeration
        Disabled (0)
        NotRunning (1)
        Starting (2)
        Idle (3)
        Backfilling (4)
        Executing (5)
        ShuttingDown (6)
        ForDeletion (7)
    end
end