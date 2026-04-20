function nanVal = empty2nan(emptyVal)
    if isempty(emptyVal)
        nanVal = NaN;
    else
        nanVal = emptyVal;
    end
end