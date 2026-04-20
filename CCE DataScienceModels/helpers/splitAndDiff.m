function difference = splitAndDiff(tappingData, tag, splits)
    difference = zeros(size(tappingData,1),1);
    for i = 1:splits
        difference(i+splits:splits:end,1) = diff(table2array(tappingData(i:splits:end, tag)));
    end
end