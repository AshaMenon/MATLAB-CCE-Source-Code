classdef AFCalculationParameter < cce.ICalculationParameter
    %AFCALCULATIONPARAMETER
    
    properties (Access = 'private')
        DataConnector (1,1) %af.AFDataConnector;
    end
    properties (Constant, Access = 'private')
        ParameterCategoryName string = "CCEParameter";
    end
    
    methods
        function obj = AFCalculationParameter(record, dataConnector)
            %AFCALCULATIONPARAMETER retrieves and stores the CCE parameter AFAttribute
            %objects for a CCE AF Calculation.
            
            if nargin > 0
                [parameters, name] = dataConnector.getRecordFieldsByCategory(record, obj.ParameterCategoryName);
                for k = numel(parameters):-1:1
                    obj(k) = cce.AFCalculationParameter();
                    obj(k).DataConnector = dataConnector;
                    obj(k).ParameterReference = parameters{k};
                    if ~isempty(parameters{k}.Parent)
                        paramName = join([string(parameters{k}.Parent.Name), name{k}], '');
                    else
                        paramName = name{k};
                    end
                    obj(k).ParameterName = paramName;
                end
            end
        end
        
        function [parameters] = retrieveParameters(obj)
            %RETRIEVEPARAMETERS fetches the value for all parameters in the
            %AFCalculationParameter OBJ array and returns the paramters as a struct
            
            arguments
                obj cce.AFCalculationParameter
            end
            
            parameters = struct();
            
            for k = 1:numel(obj)
                if ~isempty(obj(k).ParameterName) && ~isempty(obj(k).ParameterReference)
                    [value] = fetchValue(obj(k));
                    parameters.(obj(k).ParameterName) = value;
                end
            end
        end
        
        function [val] = fetchValue(obj)
            %FETCHVALUE fetch the value of the parameter AFAttribute.
            
            arguments
                obj (1,1) cce.AFCalculationParameter
            end
            
            [val] = obj.DataConnector.readField(obj.ParameterReference);
        end
    end
end

