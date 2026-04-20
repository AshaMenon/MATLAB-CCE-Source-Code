function plotLevelCategorisation( plotTitle, customColourMap, percentageMatrix,...
        customOrder)
    %UNTITLED11 Summary of this function goes here
    %   Detailed explanation goes here
    portList = {'Port1'
        'Port2'
        'Port3'
        'Port4'
        'Port5'
        'Port6'
        'Port7'
        'Port8'
        'Port10'
        'Port11'};

    figure;
    hBar = bar(percentageMatrix, 'stacked');
    legend(customOrder);
    xlabel('Ports');
    ylabel('Counts');

    xticklabels(portList);
    title(['Level Categorisation - ' plotTitle]);

    colormap(customColourMap);
    numCategories = length(customOrder);

    % Assign colors from the colormap to the bars
    for i = 1:numCategories
        hBar(i).FaceColor = 'flat';
        hBar(i).CData = i;
    end
end