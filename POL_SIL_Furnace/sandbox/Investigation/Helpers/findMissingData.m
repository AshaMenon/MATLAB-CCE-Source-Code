function [tableMissing, dataMissing] = findMissingData(data)
    %UNTITLED3 Summary of this function goes here
    %   Detailed explanation goes here

    %dataMissing = (sum(ismissing(data{i},['No Data']),1)/size(data{i},1))*100;
    missingTags = {NaN, Inf, 'Bad', 'No Data', 'Not Connect', 'No Result', 'Tag not found', ''};
    dataMissing = (sum(ismissing(data,missingTags),1)/size(data,1))*100;
    dataIdx = find(dataMissing == 0);
    figure('WindowState','maximized')
    bar(categorical(data.Properties.VariableNames),dataMissing); % plot the percentage of missing data per tag
    title("Percentage Missing Data")
    ylabel("Percentage")

    tableMissing = table((data.Properties.VariableNames)',(dataMissing)');
    tableMissing = tableMissing((tableMissing.Var2 > 9), :);
    tableMissing(:,2) = round(tableMissing(:,2));
end