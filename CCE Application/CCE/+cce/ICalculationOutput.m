classdef (Abstract) ICalculationOutput < handle
    %ICalculationOutput

    % Copyright 2021 Opti-Num Solutions (Pty) Ltd
    % Version: $Format:%ci$ ($Format:%h$)
    
    properties (SetAccess = 'protected')
        OutputName string;
    end
    properties (Access = 'protected')
        OutputReference
    end
            
    methods (Abstract) % Implementors must follow these signatures
        writeHistory(obj, value, timestamp, quality) %Write the output values to the database
    end
end
