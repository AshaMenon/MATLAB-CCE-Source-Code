classdef (Abstract) ICalculationParameter < handle
    %ICALCULATIONPARAMETER

    % Copyright 2021 Opti-Num Solutions (Pty) Ltd
    % Version: $Format:%ci$ ($Format:%h$)
    
    properties (SetAccess = 'protected')
        ParameterName string;
    end
    properties (Access = 'protected')
        ParameterReference
    end
    
    methods (Abstract) % Implementors must follow these signatures
        val = fetchValue(obj) % Read the parameter field value
    end
end

