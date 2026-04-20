function  plotTimeseries(timestamp, data, label, legendText, plotTitle)
    %UNTITLED5 Summary of this function goes here
    %   Detailed explanation goes here

    figure('WindowState','maximized')
    plot(timestamp, table2array(data))
    ylabel(label)
    legend(legendText)
    title(plotTitle)

end