
function cleanTable = performOutlierAnalysis(data, variablesToAnalyse, variableToDisplay, ...
        fillMethod, outlierMethod)

%The function takes in a table of data and a list of variables that should
%be considered in the outlier analysis. The variablesToAnalyse variable
%should be a comma separated list of strings indicating the heading of the
%table column to analyse eg: ["SlagChrome", "SlagSilica"]. 

% fillMethod = "nearest";
% outlierMethod = "movmean";


% Fill outliers
[cleanTable,outlierIndices,thresholdLow,thresholdHigh] = filloutliers(data(:,variablesToAnalyse),...
    fillMethod,outlierMethod,days(10),"SamplePoints",data.Timestamp);

% Display results for one of the cleaned variables. 
%variableToDisplay = "SlagCopper";

cleanVariable= cleanTable.(variableToDisplay);
outlierData = data.(variableToDisplay);

figure
plot(data.Timestamp, outlierData, "Color",[77 190 238]/255,...
    "DisplayName","Input data")
hold on
plot(data.Timestamp, cleanVariable,"Color",[0 114 189]/255,"LineWidth",1.5,...
    "DisplayName","Cleaned data")

% Plot outliers
plot(data.Timestamp(outlierIndices(:,1)), outlierData(outlierIndices(:,1)),...
    "x","Color",[64 64 64]/255,"DisplayName","Outliers")

% Plot filled outliers
plot(data.Timestamp(outlierIndices(:,1)),cleanVariable(outlierIndices(:,1)),".",...
    "MarkerSize",12,"Color",[217 83 25]/255,"DisplayName","Filled outliers")

% Plot outlier thresholds
plot([data.Timestamp(:); missing; data.Timestamp(:)],...
    [thresholdHigh.(variableToDisplay); missing; thresholdLow.(variableToDisplay)],...
    "Color",[145 145 145]/255,"DisplayName","Outlier thresholds")

hold off
title("Number of outliers cleaned: " + nnz(outlierIndices(:,1)))
legend
ylabel(variableToDisplay)
xlabel("Timestamp")
clear thresholdLow thresholdHigh