function inputValidation(input,class)
    %UNTITLED8 Summary of this function goes here
    %   Detailed explanation goes here
    if ~ isa(input,class)
         ME = MException('InputValidation:InputTypeNotValid', ...
        'Input type not valid');
        throw(ME)
    end
end

