classdef TimeSeriesModel < handle
    %TIMESERIESMODEL First-pass attempt at making a reusable class that
    %   does common time series tasks such as decomposition,
    %   autocorrelation, and linear modelling

    properties
        RawData timetable
        Trend
        Season
        Residuals
    end

    methods
        function obj = TimeSeriesModel(data)
            %TIMESERIESMODEL Constructor
            obj.RawData = data;
        end

        function decompose(obj)
            %DECOMPOSE Performs linear time series decomposition of input
            %   series, in order to obtain a stationary series
            [trend, season, residuals] = trenddecomp(obj.RawData.Variables);
            obj.Trend = trend;
            obj.Season = season;
            obj.Residuals = residuals;
        end

        function plotComponents(obj)
            figure
            plot(obj.RawData.Properties.RowTimes, obj.RawData.Variables)
            hold on
            plot(obj.RawData.Properties.RowTimes, obj.Trend)
            plot(obj.RawData.Properties.RowTimes, obj.Season)
            plot(obj.RawData.Properties.RowTimes, obj.Residuals)
            title('Decomposition of Time Series')
            legend('Raw Data','Trend','Seasonality','Residuals')
        end

        function stationaryTests(obj, seriesName)
            %STATIONATYTESTS Performs multiple tests for time series
            %   stationarity
            arguments
                obj TimeSeriesModel
                seriesName string {mustBeMember(seriesName,{'Raw', 'Res'})} = 'Raw'
            end

            if strcmp(seriesName, 'Raw')
                dataToTest = obj.RawData.Variables;
            elseif strcmp(seriesName, 'Res')
                dataToTest = obj.Residuals;
            else
                error('TIMESERIESMODEL:: stationaryTests: Invalid Series Name')
            end

            % Augmented Dicky Fuller
            [h, pValue] = adftest(dataToTest);
            if h == 1
                % Reject null hypothesis -> Series is stationary
                sprintf('ADF Test: %s Series Stationary, p = %0.3f', seriesName, pValue)
            else
                % Fail to reject null hypothesis -> Series not stationary
                sprintf('ADF Test: %s Series NOT Stationary, p = %0.3f', seriesName, pValue)
            end

            % Phillips Peron
            [h,pValue,~,~,~] = pptest(dataToTest);
            if h == 1
                % Reject null hypothesis -> Series is stationary
                sprintf('PP Test: %s Series Stationary, p = %0.5f', seriesName, pValue)
            else
                % Fail to reject null hypothesis -> Series not stationary
                sprintf('PP Test: %s Series NOT Stationary, p = %0.5f', seriesName, pValue)
            end
        end
        
        function randomWalkTest(obj, seriesName)
            %RANDOMWALKLTEST Tests to see whether the series is a random
            %   walk
            arguments
                obj TimeSeriesModel
                seriesName string {mustBeMember(seriesName,{'Raw', 'Res'})} = 'Raw'
            end

            if strcmp(seriesName, 'Raw')
                dataToTest = obj.RawData.Variables;
            elseif strcmp(seriesName, 'Res')
                dataToTest = obj.Residuals;
            else
                error('TIMESERIESMODEL:: randomWalkTest: Invalid Series Name')
            end

            [h,pValue,~,~] = vratiotest(dataToTest);
            if h == 1
                % Reject null hypothesis -> Series NOT a random walk
                sprintf('VRatio Test: %s Series NOT a Random Walk, p = %0.5f', seriesName, pValue)
            else
                % Fail to reject null hypothesis -> Series is a random walk
                sprintf('VRatio Test: %s Series is a Random Walk, p = %0.5f', seriesName, pValue)
            end
        end

    end
end