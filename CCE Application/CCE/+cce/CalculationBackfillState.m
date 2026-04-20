classdef CalculationBackfillState < uint32
    %CALCULATIONSTATE Enumeration for Calculation States
    %
    %   Off (0) - No backfilling is running or requested
    %   Requested (1) - Request backfilling for the given backfilling parameters
    %   Running (2) - Backfilling is in progress
    %   Finished (3) - Backfilling has successfully run for the backfilling parameters and has completed the backfilling
    %   Error (4) - An error was returned during the backfilling process and the backfilling stopped and has been placed in an error state
    
    % Copyright 2021 Opti-Num Solutions (Pty) Ltd
    % Version: $Format:%ci$ ($Format:%h$)
    
    enumeration
        Off (0)
        Requested (1)
        Running (2)
        Finished (3)
        Error (4)
    end
end

