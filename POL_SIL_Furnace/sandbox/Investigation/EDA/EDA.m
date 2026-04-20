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


    runCompleteEDA = 1 % Set this to false if MATLAB crashes when running this script. Due to te number of figures being generated it is advised to limit the size (in terms of number of tags) of the dataset before running this portion of the script.  
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

%% EDA - temperature tag analysis

% Bottom plate
timestamp = data{1}.Timestamp;
temperatureData = data{1}(:,{'BtmPlateThermocouplesA', 'BtmPlateThermocouplesB', 'BtmPlateThermocouplesC','BtmPlateThermocouplesD','BtmPlateThermocouplesE','BtmPlateThermocouplesF','BtmPlateThermocouplesG'});
figure('WindowState','maximized')
plot(timestamp, table2array(temperatureData))
ylabel('Temperature')
legend({'BtmPlateThermocouplesA', 'BtmPlateThermocouplesB', 'BtmPlateThermocouplesC','BtmPlateThermocouplesD','BtmPlateThermocouplesE','BtmPlateThermocouplesF','BtmPlateThermocouplesG'})
title('Temperature readings from bottom plate thermocouples')

% Centerline
temperatureData = data{1}(:,{'CentreLineThermocouples770A','CentreLineThermocouples770B','CentreLineThermocouples770C','CentreLineThermocouples770D','CentreLineThermocouples770E','CentreLineThermocouples770F','CentreLineThermocouples770G','CentreLineThermocouples770H','CentreLineThermocouples770I','CentreLineThermocouples770J','CentreLineThermocouples770K','CentreLineThermocouples770L','CentreLineThermocouples770M','CentreLineThermocouples770N','CentreLineThermocouples770O','CentreLineThermocouples770P','CentreLineThermocouples770Q','CentreLineThermocouples770R','CentreLineThermocouples770S','CentreLineThermocouples770T','CentreLineThermocouples770U','CentreLineThermocouples770V','CentreLineThermocouples770W','CentreLineThermocouples770X'});
figure('WindowState','maximized')
plot(timestamp, table2array(temperatureData))
ylabel('Temperature')
legend({'CentreLineThermocouples770A','CentreLineThermocouples770B','CentreLineThermocouples770C','CentreLineThermocouples770D','CentreLineThermocouples770E','CentreLineThermocouples770F','CentreLineThermocouples770G','CentreLineThermocouples770H','CentreLineThermocouples770I','CentreLineThermocouples770J','CentreLineThermocouples770K','CentreLineThermocouples770L','CentreLineThermocouples770M','CentreLineThermocouples770N','CentreLineThermocouples770O','CentreLineThermocouples770P','CentreLineThermocouples770Q','CentreLineThermocouples770R','CentreLineThermocouples770S','CentreLineThermocouples770T','CentreLineThermocouples770U','CentreLineThermocouples770V','CentreLineThermocouples770W','CentreLineThermocouples770X'})
title('Temperature readings from centerline thermocouples')

% Matte and Slag Offgas
temperatureData = data{1}(:,{'MatteEndOffgasThermocouple','SlagEndOffgasThermocouple'});
figure('WindowState','maximized')
plot(timestamp, table2array(temperatureData))
ylabel('Temperature')
legend({'MatteEndOffgasThermocouple','SlagEndOffgasThermocouple'})
title('Temperature readings from Matte and Slag Off gas')

% Investigating Centerline thermocouple sensors O,Q,R,K,L,J,I  
temperatureData = data{1}(:,{'CentreLineThermocouples770O','CentreLineThermocouples770Q','CentreLineThermocouples770R','CentreLineThermocouples770K','CentreLineThermocouples770L','CentreLineThermocouples770J','CentreLineThermocouples770I'});
figure('WindowState','maximized')
plot(timestamp, table2array(temperatureData))
ylabel('Temperature')
legend({'CentreLineThermocouples770O','CentreLineThermocouples770Q','CentreLineThermocouples770R','CentreLineThermocouples770K','CentreLineThermocouples770L','CentreLineThermocouples770J','CentreLineThermocouples770I'})
title('Temperature readings from centerline thermocouples for sensors O,Q,R,K,L,J,I')

% Find the average temperature distribution in different sections of the
% furnace
temperatureData = data{1}(:,{'CentreLineThermocouples770T','CentreLineThermocouples770U','CentreLineThermocouples770V','CentreLineThermocouples770W','CentreLineThermocouples770E','CentreLineThermocouples770X','CentreLineThermocouples770F','CentreLineThermocouples770D','CentreLineThermocouples770C','CentreLineThermocouples770B','CentreLineThermocouples770A'});
meanTemp = mean(table2array(temperatureData),2,'omitmissing');
plot(timestamp, meanTemp);
legend('Mean temperature of West of furnace')

% Find the local mean temperature per tag
temperatureData = data{1}(:,{'CentreLineThermocouples770A','CentreLineThermocouples770B','CentreLineThermocouples770C','CentreLineThermocouples770D','CentreLineThermocouples770E','CentreLineThermocouples770F','CentreLineThermocouples770G','CentreLineThermocouples770H','CentreLineThermocouples770I','CentreLineThermocouples770J','CentreLineThermocouples770K','CentreLineThermocouples770L','CentreLineThermocouples770M','CentreLineThermocouples770N','CentreLineThermocouples770O','CentreLineThermocouples770P','CentreLineThermocouples770Q','CentreLineThermocouples770R','CentreLineThermocouples770S','CentreLineThermocouples770T','CentreLineThermocouples770U','CentreLineThermocouples770V','CentreLineThermocouples770W','CentreLineThermocouples770X'});
meanTemp = mean(table2array(temperatureData),1,'omitmissing');
meanTemp = array2table(meanTemp,'VariableNames',{'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X'});
centerlineTemp = [meanTemp.P,meanTemp.O,meanTemp.Q,meanTemp.R,meanTemp.S,meanTemp.T,meanTemp.U,meanTemp.V,meanTemp.W,0;meanTemp.N,0,meanTemp.K,0,meanTemp.H,0,meanTemp.E,0,meanTemp.X,0;meanTemp.M,meanTemp.L,meanTemp.J,meanTemp.I,meanTemp.G,meanTemp.F,meanTemp.D,meanTemp.C,meanTemp.B,meanTemp.A];

%% EDA - Matte and Slag Temperatures

%Identifying and removing spikes in data
rateOfChange = diff(data{1});

for i = 1:1:size(rateOfChange,2)
    rateOfChangeIdx = find(table2array(rateOfChange(:,i)));
    rateOfChangeTimestamp = rateOfChange.Timestamp(rateOfChangeIdx);
    rateOfChangeTable = timetable(rateOfChangeTimestamp, rateOfChange{rateOfChangeIdx,i});
    rateOfChangeTemps = rateOfChangeTable(2:end,"Var1")./minutes(diff(rateOfChangeTable.rateOfChangeTimestamp));
    rateOfChange(rateOfChangeTemps.rateOfChangeTimestamp,i) = table(rateOfChangeTemps.Var1);
    for j = 1:1:(size(rateOfChangeIdx)-1)
        rateOfChange(rateOfChangeIdx(j):rateOfChangeIdx(j+1),i) = table(rateOfChangeTemps.Var1(j));
    end
end

%Scatter plot of Matte vs Slg per category
figure('WindowState','maximized')
scatter(data{1}.EastSlagTemp,data{1}.EastMatteTemp)
xlabel('East Slag Temp (degC)')
ylabel('East Matte Temp (degC)')
title('Scatter plot of Slag against Matte temperatures for East side')

figure('WindowState','maximized')
%hold on
scatter(data{1}.CenterSlagTemp,data{1}.CenterMatteTemp)
xlabel('Center Slag Temp (degC)')
ylabel('Center Matte Temp (degC)')
title('Scatter plot of Slag against Matte temperatures for Center')

figure('WindowState','maximized')
%hold on
scatter(data{1}.WestSlagTemp,data{1}.WestMatteTemp)
xlabel('West Slag Temp (degC)')
ylabel('West Matte Temp (degC)')
title('Scatter plot of Slag against Matte temperatures for West side')

% xlabel('Slag temperatures (degC)')
% ylabel('Matte temperatures (degC)')
% title('Scatter plot of Slag against Matte temperatures')
% legend({'East temperatures','Center temperatures','West temperatures'})