function missingDataAnalysis(data, dataMissing)
    %UNTITLED4 Summary of this function goes here
    %   Detailed explanation goes here
    data(:,find(dataMissing == 100)) = [];

    for cols = 1:1:size(data,2)      % This loop plots the timeseries data and overlays periods of missing data to analyse trends in missing data, the code also provides information about the data distribution by displaying max,min,mean and 1 standard deviation data per tag
        figure('WindowState','maximized')
        timestamp = data.Timestamp;
        plot(timestamp, table2array(data(:,cols)))   % Plots the raw time series data for high level trend analysis
        hold on
        area(data.Timestamp, ismissing(data(:,cols))*table2array(max(data(:,cols))))   % Plots area bands over periods of missing data
        hold on
        yregion(table2array(mean(data(:,cols),'omitmissing')) - std(table2array(data(:,cols)),'omitmissing'), table2array(mean(data(:,cols),'omitmissing')) + std(table2array(data(:,cols)),'omitmissing'), 'FaceColor', 'g', 'FaceAlpha', 0.2); % Plots area representing 1 standard deviation from the mean
        hold on
        yline([table2array(max(data(:,cols))), table2array(min(data(:,cols))), table2array(mean(data(:,cols),'omitmissing'))],'--',{'Max:'+string(table2array(max(data(:,cols)))),'Min:'+string(table2array(min(data(:,cols)))), 'Mean:'+string(table2array(mean(data(:,cols),'omitmissing')))}, 'LabelVerticalAlignment', 'middle'); % Plot min,max and mean lines
        title("Trends in missing data:" + data.Properties.VariableNames{cols})
        legend('Raw Data','Missing Data','1 Standard Deviation','Location','northeastoutside')
    end

    dataTbl = timetable2table(data);     % Converts the data into a table format
    dataTbl(:,1) = [];                      % Removes the timestamp from the table
    correlations = corrcoef(table2array(dataTbl), 'Rows', 'pairwise');      % Calculates and plots the correlation between each tag
    figure('WindowState','maximized')
    heatmap(data.Properties.VariableNames,data.Properties.VariableNames,correlations)
    title('Correlation coefficients between individual tags')

    figure('WindowState','maximized')    % Plots the distribution of data for each individual tag as a histogram
    tiledlayout(floor(sqrt(size(data,2))),ceil(sqrt(size(dataTbl,2)))+1);
    for cols= 1:1:size(data,2)
        nexttile
        histogram(table2array(dataTbl(:,cols)))
        title(string(dataTbl(1,cols).Properties.VariableNames))
    end
end