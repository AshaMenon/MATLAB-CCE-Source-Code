function newStruct = appendStructs(orignalStruct, addedStruct)

fieldNamesToAppend = fields(addedStruct);
newStruct = orignalStruct;

for idx = 1:numel(fieldNamesToAppend)
    newStruct.(fieldNamesToAppend{idx}) = addedStruct.(fieldNamesToAppend{idx});

end

end