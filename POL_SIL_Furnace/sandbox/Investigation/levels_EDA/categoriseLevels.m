function [percentageMatrix, levelTbl] = categoriseLevels(tags,levelTbl, levelType,...
        customOrder)
    %UNTITLED9 Summary of this function goes here
    %   Detailed explanation goes here
   
    levelTbl = assignLevelCategories(levelTbl, customOrder, tags, levelType);
    countMatrix = zeros(length(tags), length(customOrder));

    % Calculate counts for each port and category
    for i = 1:length(tags)
        columnName = tags{i};
        for j = 1:length(customOrder)
            countMatrix(i, j) = sum(levelTbl{:,[columnName 'Cat']} == customOrder{j});
        end
    end

    rowTotals = height(levelTbl);
    percentageMatrix = countMatrix/rowTotals * 100;

   
end