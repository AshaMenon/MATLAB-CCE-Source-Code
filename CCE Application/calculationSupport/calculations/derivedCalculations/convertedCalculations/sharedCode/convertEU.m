function [dVal,converted] = convertEU(expectedEU,value,eu,sg)
%CONVERTEU Convert engineering units
%   [dVal,converted] = convertEU(expectedEU,value,eu,sg) converts eu of value to expectedEU
%
%   Expected inputs: expectedEU, value, eu, sg
% 
% G2 requirement for engineering unit conversion

dVal = [];

% Assign converted to false
converted = 0;

if strcmpi(expectedEU,eu)
    % if CurrentEU = NewEU > return CurrentVal
    dVal = value;
    converted = 1;
else
    % Try simple EU conversion
    dVal = convertEUsimple(expectedEU,value,eu,sg,false);
    if ~isempty(dVal)
        converted = 1;
    elseif isempty(dVal) && (max(size(strfind(eu,'.'))) > 0 || max(size(strfind(eu,'/'))) || max(size(strfind(eu,'^'))))
        % Do composite EU conversion
        dVal = convertEUComposite(value,eu,expectedEU,sg);
        if ~isempty(dVal)
            converted = 1;
        end
    end
end
% If no conversion was done for whatever reason
if isempty(dVal)
	dVal = value;
end