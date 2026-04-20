function plotCombinedLevel(levelTbl,lvlType, plotTitle)
    %UNTITLED6 Summary of this function goes here
    %   Detailed explanation goes here
    variableNames = levelTbl.Properties.VariableNames;
    matteColumns = contains(variableNames, lvlType);
    matteData = levelTbl{:, matteColumns};
    maxMatteValues = calculateLevelMax(matteData, matteColumns);
    levelTbl.maxMatteLevel = maxMatteValues;
    levelTbl.maxMatteLevel(levelTbl.maxMatteLevel == 0) = NaN;
    levelTbl.maxMatteLevel = fillmissing(levelTbl.maxMatteLevel, 'previous');

    avgMatteValues = calculateLevelAverage(matteData, matteColumns);
    levelTbl.avgMatteLevel = avgMatteValues;
    levelTbl.avgMatteLevel(levelTbl.avgMatteLevel == 0) = NaN;
    levelTbl.avgMatteLevel = fillmissing(levelTbl.avgMatteLevel, 'previous');

    matteTbl = levelTbl(:, matteColumns);
    changes = [false(1, 10); diff(matteTbl.Variables) ~= 0];
    num_changes = sum(changes, 2);
    matteTbl = matteTbl(num_changes >= 1, :);

    dataMatrix = matteTbl.Variables;
    changes2 = [false(1, size(dataMatrix, 2)); diff(dataMatrix) ~= 0];
    [rowIdx, colIdx] = find(changes2);


    figure;
    for col = 1:size(dataMatrix, 2)
        times = matteTbl.Timestamp(changes2(:, col));
        values = dataMatrix(changes2(:, col), col);

        scatter(times, values, 'filled', 'DisplayName', matteTbl.Properties.VariableNames{col});
        hold on;
    end
    plot(levelTbl.Timestamp, levelTbl.avgMatteLevel)
    plot(levelTbl.Timestamp, levelTbl.maxMatteLevel)

    currentLgend = legend;
    currentLgend.String{11} =  'Avg';
    currentLgend.String{12} =  'Max';
    legend('Location','bestoutside');
    xlabel('Time');
    ylabel('Values');
    title(plotTitle);
    grid on;
    hold off;
    
    figure
    h1 = histogram(levelTbl.avgMatteLevel, 'Normalization', 'probability', 'FaceAlpha', 0.4);
    binEdges = h1.BinEdges;
    hold on;
    histogram(levelTbl.maxMatteLevel, binEdges, 'Normalization', 'probability', 'FaceAlpha', 0.4);
    hold off;
    legend('Average', 'Max');
    title(plotTitle)

    figure
    plot(levelTbl.Timestamp, levelTbl.avgMatteLevel);
    title('Average')
    
end