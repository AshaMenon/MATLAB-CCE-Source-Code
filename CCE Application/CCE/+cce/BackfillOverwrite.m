classdef BackfillOverwrite < uint32
    %BACKFILLOVERWRITE Enumeration for Calculation Backfill Overwrite Behaviour
    %
    %
    %	(0) None        -   No overwriting, only fill-in missing timestamps when backfilling
    %	(1) PrimaryOnly	-   Overwrite the primary calculation and its dependents.
    %	(2) All         -   Overwrite the primary calculation only. Fill-in the gaps of any dependent calculations.
    
    % Copyright 2021 Opti-Num Solutions (Pty) Ltd
    % Version: $Format:%ci$ ($Format:%h$)
    
    enumeration
        None (0)
        PrimaryOnly (1)
        All (2)
    end
end

