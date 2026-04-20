function paramStruct = fileRead(paramFileData)

    paramFileData = string(paramFileData);
    paramFileData = strrep(paramFileData,";",",");

    for nCol = 1:size(paramFileData,2)
        idx = ismissing(paramFileData(:,nCol));
        paramFileData(idx,nCol) = "";
    end

    paramFileData2 = paramFileData(:,1);

    for nCol = 2:size(paramFileData,2)
        paramFileData2 = strcat(paramFileData2,",",paramFileData(:,nCol));
    end

    paramStruct = struct;

    for nRow = 1:length(paramFileData2)
        fieldName = extractBefore(paramFileData2(nRow),",");
        fieldValue = extractAfter(paramFileData2(nRow),",");

        if contains(fieldValue,"[")
            fieldValue = strrep(fieldValue,"[", "");
            fieldValue = strrep(fieldValue,"]", "");
            fieldValue = strsplit(fieldValue,",");
            fieldValue(fieldValue == "") = [];
        end

        if length(fieldValue) == 1
            fieldValue = strrep(fieldValue,",","");
        end

        if ~ismissing(fieldName)
        paramStruct.(fieldName) = fieldValue;
        end
    end