classdef CalculationExecutionMode < uint32
    % ExecutionMode Enumeration for a Calculation/ Coordinator Execution Modes
    %
    %   Periodic (1) - Runs at an ExecutionFrequency
    %   Event (2) - Runs in response to CCETrigger input data changes
    %   Manual (3) - Runs only when user sets BackfillState to Requested
    
    % Copyright 2021 Opti-Num Solutions (Pty) Ltd
    % Version: $Format:%ci$ ($Format:%h$)
    
    enumeration
        Periodic (1)
        Event (2)
        Manual (3)
    end
end