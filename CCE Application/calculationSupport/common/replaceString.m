function strArray = replaceString(strArray, oldStr, newStr)
    %REPLACESTRING Replaces a string in a cell array of strings
    
    idx = find(strcmp(strArray, oldStr));
    if ~isempty(idx)
        strArray{idx} = newStr;
    end
end

