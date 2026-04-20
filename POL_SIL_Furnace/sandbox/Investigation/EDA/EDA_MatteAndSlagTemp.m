clear
clc

%% Select data files

selectFile = true;  % Activates the file browser to select a file for import when set to true

if selectFile == true
    [filename,filepath] = uigetfile("*.*", "MultiSelect","on");     % Obtains the file path and fine names of the files required for EDA. Can import multiple files at once.
    addpath(filepath)   % Adds folders to file path 
end

%% Import data into MATLAB and correct timestamp

if iscell(filename)    % Identifies if mutliple files are trying to be imported
    numFiles = size(filename,2);
else                   % If only one file has been selected then some processing of the file names need to be performed
    numFiles = 1;   
    filename = {filename};
end

for i = 1:1:numFiles
    opts = detectImportOptions(filename{i});
    opts = setvartype(opts,opts.VariableNames(2:end), 'double'); % Automatically converts all strings (bad data) to NaN which eases data processing
    data{i} = readtimetable(filename{i}, opts);   % Imports data into a timetable
    pat = digitsPattern(4);     % Timestamp gets imported in the dd-MM-yyyy format, the year gets imported incorrectly as 00XX (e.g. 0023) - this code sets a 4 digit pattern to find the incorrect year
    year = extract(string(data{i}.Timestamp),pat);
    correctedTimestamp = datetime(replace(string(data{i}.Timestamp),year(1),string(str2double(year(1)) + 2000)));   % corrects the year being imported
    data{i}.Timestamp = correctedTimestamp;
end

%% Basic data analysis and preprocessing

for i = 1:1:numFiles    % Find any missing data
    %dataMissing = (sum(ismissing(data{i},['No Data']),1)/size(data{i},1))*100;
    missingTags = {NaN, Inf, 'Bad', 'No Data', 'Not Connect', 'No Result', 'Tag not found', ''};
    dataMissing = (sum(ismissing(data{i},missingTags),1)/size(data{i},1))*100;
    dataIdx = find(dataMissing == 0);
    figure('WindowState','maximized')
    bar(categorical(data{i}.Properties.VariableNames),dataMissing); % plot the percentage of missing data per tag 
    title("Percentage Missing Data")
    ylabel("Percentage")

    tableMissing = table((data{i}.Properties.VariableNames)',(dataMissing)');
    tableMissing = tableMissing((tableMissing.Var2 > 9), :);
    tableMissing(:,2) = round(tableMissing(:,2));

    runCompleteEDA = 0 % Set this to false if MATLAB crashes when running this script. Due to te number of figures being generated it is advised to limit the size (in terms of number of tags) of the dataset before running this portion of the script.  
    if runCompleteEDA == 1    
        data{i}(:,find(dataMissing == 100)) = [];

        for cols = 1:1:size(data{i},2)      % This loop plots the timeseries data and overlays periods of missing data to analyse trends in missing data, the code also provides information about the data distribution by displaying max,min,mean and 1 standard deviation data per tag
            figure('WindowState','maximized')
            timestamp = data{i}.Timestamp;
            plot(timestamp, table2array(data{i}(:,cols)))   % Plots the raw time series data for high level trend analysis
            hold on
            area(data{i}.Timestamp, ismissing(data{i}(:,cols))*table2array(max(data{i}(:,cols))))   % Plots area bands over periods of missing data
            hold on
            yregion(table2array(mean(data{i}(:,cols),'omitmissing')) - std(table2array(data{i}(:,cols)),'omitmissing'), table2array(mean(data{i}(:,cols),'omitmissing')) + std(table2array(data{i}(:,cols)),'omitmissing'), 'FaceColor', 'g', 'FaceAlpha', 0.2); % Plots area representing 1 standard deviation from the mean
            hold on
            yline([table2array(max(data{i}(:,cols))), table2array(min(data{i}(:,cols))), table2array(mean(data{i}(:,cols),'omitmissing'))],'--',{'Max:'+string(table2array(max(data{i}(:,cols)))),'Min:'+string(table2array(min(data{i}(:,cols)))), 'Mean:'+string(table2array(mean(data{i}(:,cols),'omitmissing')))}, 'LabelVerticalAlignment', 'middle'); % Plot min,max and mean lines
            title("Trends in missing data:" + data{i}.Properties.VariableNames{cols})
            legend('Raw Data','Missing Data','1 Standard Deviation','Location','northeastoutside')
        end
    
        dataTbl = timetable2table(data{i});     % Converts the data into a table format
        dataTbl(:,1) = [];                      % Removes the timestamp from the table 
        correlations = corrcoef(table2array(dataTbl), 'Rows', 'pairwise');      % Calculates and plots the correlation between each tag 
        figure('WindowState','maximized')
        heatmap(data{i}.Properties.VariableNames,data{i}.Properties.VariableNames,correlations)
        title('Correlation coefficients between individual tags')
    
        figure('WindowState','maximized')    % Plots the distribution of data for each individual tag as a histogram
        tiledlayout(floor(sqrt(size(data{i},2))),ceil(sqrt(size(dataTbl,2)))+1);
        for cols= 1:1:size(data{i},2)
            nexttile
            histogram(table2array(dataTbl(:,cols)))
            title(string(dataTbl(1,cols).Properties.VariableNames))
        end
    end
    %uiwait(msgbox('This message will pause execution until you click OK. Clicking OK will close all open plots and perform EDA and preprocessing for additionally selected files if more than one file was imported.'));
    %close all
end

%% Matte and Slag Data EDA

tempData = data{1};

% Step 1: Find and remove temperatures out of operating ranges

tempData.EastSlagTemp(tempData.EastSlagTemp < 1440) = NaN;
tempData.EastSlagTemp(tempData.EastSlagTemp > 1695) = NaN;
tempData.CenterSlagTemp(tempData.CenterSlagTemp < 1440) = NaN;
tempData.CenterSlagTemp(tempData.CenterSlagTemp > 1695) = NaN;
tempData.WestSlagTemp(tempData.WestSlagTemp < 1440) = NaN;
tempData.WestSlagTemp(tempData.WestSlagTemp > 1695) = NaN;

tempData.EastMatteTemp(tempData.EastMatteTemp < 1300) = NaN;
tempData.EastMatteTemp(tempData.EastMatteTemp > 1570) = NaN;
tempData.CenterMatteTemp(tempData.CenterMatteTemp < 1300) = NaN;
tempData.CenterMatteTemp(tempData.CenterMatteTemp > 1570) = NaN;
tempData.WestMatteTemp(tempData.WestMatteTemp < 1300) = NaN;
tempData.WestMatteTemp(tempData.WestMatteTemp > 1570) = NaN;

%% Step 2: Identify and isolate unique data points

for column = 1:1:size(tempData, 2)
    uniqueDataIdx = [find(table2array(diff(tempData(:,column)))) + 1];
    uniqueData = tempData(uniqueDataIdx,column);
    tempData(uniqueData.Timestamp, string(tempData.Properties.VariableNames(column)) + 'Unique') = table(uniqueData{:,1});
    clear uniqueData uniqueDataIdx
end

%% Step 3: Apply a moving average filter over the non-unique data
movingAverage = dsp.MovingAverage(1440,1440-1,'Method','Sliding window');
for temperatureTag = 1:1:6
    filteredData = movingAverage(table2array(tempData(:,temperatureTag)));
    tempData(:,string(tempData.Properties.VariableNames(temperatureTag)) + 'MAFiltered') = table(filteredData);

    % figure('WindowState','maximized')
    % plot(tempData.Timestamp(20200:end), table2array(tempData(20200:end,temperatureTag)))
    % hold on
    % plot(tempData.Timestamp(20200:end), filteredData(20200:end)) 
    % ylabel('Temperature')
    % legend({'Original Data','Filtered Data'})
    % title(tempData.Properties.VariableNames(temperatureTag))
end

%% Step 4: Apply a multiscale local polynomial transform (MLPT) over unique data

for column = 7:1:12
    uniqueTimestamp = tempData.Timestamp(~ismissing(tempData{:,column}, [NaN 0]));
    uniqueData = tempData(uniqueTimestamp, column);
    MLPTData = mlptdenoise(table2array(uniqueData), uniqueTimestamp, 5);
    tempData(uniqueTimestamp,string(tempData.Properties.VariableNames(column - 6)) + 'MPLTFiltered') = table(MLPTData);
    tempData(table2array(tempData(:, string(tempData.Properties.VariableNames(column - 6)) + 'MPLTFiltered') == 0), string(tempData.Properties.VariableNames(column - 6)) + 'MPLTFiltered') = table(NaN);

    figure('WindowState','maximized')
    plot(tempData.Timestamp, table2array(tempData(:, column-6)), 'g')
    hold on
    plot(uniqueTimestamp, MLPTData, 'b.', 'MarkerSize',10)%, 'LineStyle','--', 'LineWidth', 2)
    ylabel('Temperature')
    title(string(tempData.Properties.VariableNames(column - 6)) + 'MPLTFiltered')
    legend({'Original Data', 'MLPT Filtered Data'})
end

%% Step 5: Apply a multiscale local polynomial transform (MLPT) over unique data

for column = 7:1:12
    uniqueTimestamp = tempData.Timestamp(~ismissing(tempData{:,column}, [NaN 0]));
    uniqueData = tempData(uniqueTimestamp, column);
    windowSize =  17; %floor(0.05 * size(uniqueTimestamp, 1));
    MLPTData = zeros(1,size(uniqueData,1) - windowSize)';
    for datapoint = floor(windowSize/2):1:(size(uniqueData,1) - windowSize)
        if datapoint == floor(windowSize/2)
            MLPTTempData = mlptdenoise(table2array(uniqueData(1:floor(windowSize/2),1)), uniqueTimestamp(1:floor(windowSize/2)), 3);
            MLPTData(1:floor(windowSize/2)) = MLPTTempData;
        else
            MLPTTempData = mlptdenoise(table2array(uniqueData(datapoint - floor(windowSize/2):datapoint + floor(windowSize/2),1)), uniqueTimestamp(datapoint - floor(windowSize/2):datapoint + floor(windowSize/2)), 4);
            MLPTData(datapoint) = MLPTTempData(floor(windowSize/2));
        end
    end
end

%% Step 5 (alternative): Apply a multiscale local polynomial transform (MLPT) over unique data using dates as inputs

for column = 7:1:12
    uniqueTimestamp = tempData.Timestamp(~ismissing(tempData{:,column}, [NaN 0]));
    uniqueData = tempData(uniqueTimestamp, column);
    startDate = datetime(2023,01,01,00,00,00);
    endDate = datetime(2023,01,31,23,59,00);
    MLPTSmoothData = zeros(size(uniqueTimestamp, 1),1);
    startIdx = 1;
    while endDate < uniqueData.Timestamp(end) + days(30)
        overlapStart = startDate - days(15);
        overlapEnd = endDate + days(15);
        dataRangeTimestamp = uniqueData.Timestamp(timerange(overlapStart,overlapEnd));
        MLPTData = mlptdenoise(table2array(uniqueData(timerange(overlapStart,overlapEnd),1)), dataRangeTimestamp, 4);
        smoothData = timetable(dataRangeTimestamp, MLPTData);
        smoothDataExtracted = smoothData(timerange(startDate,endDate),1);
        MLPTSmoothData(startIdx:startIdx + size(smoothDataExtracted,1)-1) = smoothDataExtracted.MLPTData;
        startDate = endDate + minutes(1);
        endDate = endDate + days(30);
        startIdx = startIdx + size(smoothDataExtracted,1);
    end
    tempData(uniqueTimestamp,string(tempData.Properties.VariableNames(column - 6)) + 'MPLTTimebasedFiltered') = table(MLPTSmoothData);
    tempData(table2array(tempData(:, string(tempData.Properties.VariableNames(column - 6)) + 'MPLTTimebasedFiltered') == 0), string(tempData.Properties.VariableNames(column - 6)) + 'MPLTTimebasedFiltered') = table(NaN);
    
    figure('WindowState','maximized')
    plot(tempData.Timestamp, table2array(tempData(:,column - 6)), 'b.', 'LineStyle', '-', 'LineWidth',0.1);
    hold on
    plot(uniqueTimestamp, MLPTSmoothData, 'g.', 'LineStyle', '-', 'LineWidth', 2);
    ylabel('Temperature')
    title(string(tempData.Properties.VariableNames(column - 6)))
end
%% Matte and Slag EDA

tempData = data{1};
tempData(modeData.Timestamp,'mode') = table(modeData.mode);

for temperatureTag = 1:1:6
    figure('WindowState','maximized')
    plot(tempData.Timestamp, table2array(tempData(:,temperatureTag)))
    hold on
    plot(tempData.Timestamp(tempData.mode == 'Off'), table2array(tempData(tempData.mode == 'Off',temperatureTag)), 'r.', tempData.Timestamp(tempData.mode == 'Normal'), table2array(tempData(tempData.mode == 'Normal',temperatureTag)), 'b*',tempData.Timestamp(tempData.mode == 'Ramp'), table2array(tempData(tempData.mode == 'Ramp',temperatureTag)), 'gdiamond',tempData.Timestamp(tempData.mode == 'Lost Capacity'), table2array(tempData(tempData.mode == 'Lost Capacity',temperatureTag)), 'mx')
    ylabel('Temperature')
    title(tempData.Properties.VariableNames(temperatureTag))
    legend({'Original Data', 'Off', 'Ramp', 'Normal', 'Lost Capacity'})
end

% Find and remove temperatures out of operating ranges
tempData.EastSlagTemp(tempData.EastSlagTemp < 1440) = NaN;
tempData.EastSlagTemp(tempData.EastSlagTemp > 1695) = NaN;
tempData.CenterSlagTemp(tempData.CenterSlagTemp < 1440) = NaN;
tempData.CenterSlagTemp(tempData.CenterSlagTemp > 1695) = NaN;
tempData.WestSlagTemp(tempData.WestSlagTemp < 1440) = NaN;
tempData.WestSlagTemp(tempData.WestSlagTemp > 1695) = NaN;

tempData.EastMatteTemp(tempData.EastMatteTemp < 1300) = NaN;
tempData.EastMatteTemp(tempData.EastMatteTemp > 1570) = NaN;
tempData.CenterMatteTemp(tempData.CenterMatteTemp < 1300) = NaN;
tempData.CenterMatteTemp(tempData.CenterMatteTemp > 1570) = NaN;
tempData.WestMatteTemp(tempData.WestMatteTemp < 1300) = NaN;
tempData.WestMatteTemp(tempData.WestMatteTemp > 1570) = NaN;

% Data smoothing -mlpe
% Find unique data points
for temperatureTag = 1:1:6
    uniqueTempDataIdx = find(diff(table2array(tempData(:,temperatureTag))));
    uniqueTempDataIdx = uniqueTempDataIdx + 1;
    uniqueTempData = tempData(uniqueTempDataIdx,temperatureTag);
    realData = ~ismissing(uniqueTempData(:,1));
    realDataIdx = uniqueTempData.Timestamp(realData);
    filteredData = mlptdenoise(table2array(uniqueTempData(:,1)), uniqueTempData.Timestamp,3)
    figure('WindowState','maximized')
    plot(tempData.Timestamp, table2array(tempData(:,temperatureTag)))
    hold on
    plot(realDataIdx, filteredData)
end

% Using MA
for temperatureTag = 1:1:6
    movingAverage = dsp.MovingAverage(720,720-1,'Method','Sliding window');
    filteredData = movingAverage(table2array(tempData(:,temperatureTag)));
    figure('WindowState','maximized')
    plot(tempData.Timestamp, table2array(tempData(:,temperatureTag)))
    hold on
    plot(tempData.Timestamp, filteredData) 
    ylabel('Temperature')
    legend({'Original Data','Filtered Data'})
    title(tempData.Properties.VariableNames(temperatureTag))
end

% Using EWMA
for temperatureTag = 1:1:6
    movingAverage = dsp.MovingAverage('Method','Exponential weighting', 'ForgettingFactor',0.99);
    filteredData = movingAverage(table2array(tempData(:,temperatureTag)));
    figure('WindowState','maximized')
    plot(tempData.Timestamp, table2array(tempData(:,temperatureTag)))
    hold on
    plot(tempData.Timestamp, filteredData) 
    ylabel('Temperature')
    legend({'Original Data','Filtered Data'})
    title(tempData.Properties.VariableNames(temperatureTag))
end