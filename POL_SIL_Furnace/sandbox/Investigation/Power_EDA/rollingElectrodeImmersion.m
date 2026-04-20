function [rollingImmersionMean,rollingImmersionStdDev] = rollingElectrodeImmersion(electrodeData, windowSize)
    %ROLLINGELECTRODEIMMERSION Creates a metric for rolling electrode immersion
    %   Detailed explanation goes here

    rollingImmersionMean = movmean(electrodeData, windowSize);
    rollingImmersionStdDev = movstd(electrodeData, windowSize);
end