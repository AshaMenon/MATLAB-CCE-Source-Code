function ax = descriptivePlot(x, y, lineStyle, colour, plotTitle)
    figure
    ax = subplot(1,2,1);
    plot(x, y, lineStyle, 'Color', colour)
    hold on
    xlabel('Timestamp')
    ylabel(plotTitle)
    subplot(1,2,2)
    histogram(y, 50, 'FaceColor', colour)
end