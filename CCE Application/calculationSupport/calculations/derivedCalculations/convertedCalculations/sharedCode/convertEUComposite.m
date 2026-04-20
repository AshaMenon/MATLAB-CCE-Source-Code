function [dVal] = convertEUComposite(value,eu,expectedEU,sg)
%CONVERTEUCOMPOSITE Convert engineering units
%   [dVal] = convertEUComposite(value,eu,expectedEU,sg) converts eu of value to expectedEU
%
%   Expected inputs: value, eu, expectedEU, sg
% 
% G2 requirement for engineering unit conversion

% Assign converted to false
converted = 0;

% Asssign EU to structure
euStruct(1).eu = eu;
euStruct(2).eu = expectedEU;

% {--- Get everything before and after the divisor}
for i = 1:2
    euStruct(i).delimiter = strfind(euStruct(i).eu,'/');
    % B/A
    if ~isempty(euStruct(i).delimiter)
        euStruct(i).euB = euStruct(i).eu(1:euStruct(i).delimiter-1);
        euStruct(i).euA = euStruct(i).eu(euStruct(i).delimiter+1:end);
    else
        euStruct(i).euB = euStruct(i).eu;
        euStruct(i).euA = [];
    end
end

%   {--- Sanity checks to see if parts match up so far}
if ~isempty(euStruct(1).euB) && ~isempty(euStruct(2).euB) && ~(isempty(euStruct(1).euA) && ~isempty(euStruct(2).euA)) && ~(~isempty(euStruct(1).euA) && isempty(euStruct(2).euA))
    result = [1 1];
    for i = 1:2
        if i == 1
%             {--- EU's before the devisor}
            oldEU = euStruct(1).euB; newEU = euStruct(2).euB;
        elseif i == 2
%             {--- EU's after the devisor}
            oldEU = euStruct(1).euA; newEU = euStruct(2).euA;
        end
        
        if i == 2 && isempty(oldEU)
%             {--- No divisor check}
            result(2) = 1;
        else
%             {Calculate the conversion factor for converting oldEU to newEU.  oldEU and newEU should have the same number of units
%             (separated by ".") and may not have a divisor.  Exponent terms (eg "^2") are catered for - in this case the same exponent
%             should be used in both old and new (Unless dealing with terms like m^3 to litre)}
            oldDelim = strfind(oldEU,'.');
            newDelim = strfind(newEU,'.');
            if size(oldDelim,2) == size(newDelim,2)
                result(i) = 1;
                % For each sub-eu conversion
                for j = 1:size(oldDelim,2)+1
                    if isempty(oldDelim)
                        % If no '.' delimiter
                        oldTemp = oldEU;
                        newTemp = newEU;
                    elseif j == 1
                        oldTemp = oldEU(1:oldDelim(j)-1);
                        newTemp = newEU(1:newDelim(j)-1);
                    else
                        try
                            oldTemp = oldEU(oldDelim(j-1)+1:oldDelim(j)-1);
                            newTemp = newEU(newDelim(j-1)+1:newDelim(j)-1);
                        catch
                            oldTemp = oldEU(oldDelim(j-1)+1:end);
                            newTemp = newEU(newDelim(j-1)+1:end);
                        end
                    end
                    if ~strcmp(oldTemp,newTemp)
%                         {--- Cater for conversions like m^3 to litre}
                        F = convertEUsimple(newTemp,1,oldTemp,sg,true);
                        if ~isempty(F)
                            result(i) = result(i) * F;
                        else
%                             {--- Get exponent factors}
                            oldExp = strfind(oldTemp,'^');
                            newExp = strfind(newTemp,'^');
                            if ~isempty(oldExp) && ~isempty(newExp)
                                F = convertEUsimple(newTemp(1:newExp-1),1,oldTemp(1:oldExp-1),sg,true);
                                if ~isempty(F)
                                    result(i) = result(i) * F ^ str2double(newTemp(newExp+1:end));
                                else
                                    result(i) = 0;
                                end
                            else
                                result(i) = 0;
                            end
                        end
                    end
                end
            else
                result(i) = 0;
            end
        end
    end
    if min(result) == 0
        dVal = [];
    else
        dVal = result(1) * value / result(2);
    end
else
    dVal = [];
end