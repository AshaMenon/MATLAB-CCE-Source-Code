function levelTbl = assignLevelCategories(levelTbl, customOrder, tags, levelType)
    %UNTITLED14 Summary of this function goes here
    %   Detailed explanation goes here
    switch levelType
        case 'slag'
            funcHandle = @categoriseSlagLevel;
        case 'matte'
            funcHandle = @categoriseMatteLevel;
        case 'bath'
            funcHandle = @categoriseBathLevel;
        case 'bonedry'
            funcHandle = @categoriseBonedryLevel;
        otherwise
            error('Invalid Function choice')
    end

    for k = 1:length(tags)
        categories = cell(height(levelTbl), 1);
        columnName = tags{k};

        for i = 1:height(levelTbl)
            level = levelTbl.(columnName)(i);
            categories{i} = funcHandle(level);
        end

        levelTbl.([columnName 'Cat']) = categorical(categories);
        levelTbl.([columnName 'Cat']) = setcats(levelTbl.([columnName 'Cat']), customOrder);

    end
end