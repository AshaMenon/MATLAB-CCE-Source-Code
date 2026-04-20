function output = assignDataToVariables(inputs,fieldName)
    
    if isfield(inputs,fieldName)
       output =  inputs.(fieldName);
    else
       output = [];
    end
end

