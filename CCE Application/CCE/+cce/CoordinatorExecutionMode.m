classdef CoordinatorExecutionMode < uint32
    % CoordinatorExecutionMode Enumeration for a Coordinator's Execution Modes
    %
    %   Single (0) - Run calculations once, then exit. Ignore Lifetime
    %   Cyclic (1) - Run calculations every ExecutionFrequency until Lifetime is reached, then exit
    %   Event (2) - Run calculations in response to Events until Lifetime is reached, then exit
    %   Manual (3) - Run calculations once, then exit. Ignore Lifetime
    
    % Copyright 2021 Opti-Num Solutions (Pty) Ltd
    % Version: $Format:%ci$ ($Format:%h$)
    
    enumeration
        Single (0)
        Cyclic (1)
        Event (2)
        Manual (3)
    end
end