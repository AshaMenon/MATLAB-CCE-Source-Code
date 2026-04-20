classdef (Abstract) ICalculationInput < handle
    %ICALCULATIONINPUT

    % Copyright 2021 Opti-Num Solutions (Pty) Ltd
    % Version: $Format:%ci$ ($Format:%h$)
    
    properties (SetAccess = 'protected')
        InputName string;
    end
    properties (Access = 'protected')
        InputReference
        HistoryDefinition string;
    end
            
    methods (Abstract) % Implementors must follow these signatures
        [value, timestamp, quality] = fetchHistory(obj, baseTime); %Read the input field historical values from the database
    end
end

