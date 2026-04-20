function [outliers, outlierIndices] = identifyOutliers(data)
    %UNTITLED16 Summary of this function goes here
    %   Detailed explanation goes here
    Q1 = quantile(data, 0.25);
    Q3 = quantile(data, 0.75);
    IQR = Q3 - Q1;

    lower_bound = Q1 - 1.5 * IQR;
    upper_bound = Q3 + 1.5 * IQR;

    outliers = data(data < lower_bound | data > upper_bound);
    outlierIndices = find(data < lower_bound | data > upper_bound);

end