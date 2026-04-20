function rootCause = getRootCause(timespanData, rangeMV,k)
    %GETROOTCAUSE Calculates the root cause for a controller
    %   Uses historical data of 1 hour. 
    
    % Calculate MV deadband
    mvDeadBand = [rangeMV(1)+2/100*diff(rangeMV) rangeMV(2)-2/100*diff(rangeMV)];
    % Assign default "(0)" to all controller rootcause
    timespanData.rootCause{k} = zeros(size(timespanData.plotQuality{k},1),1);
    % Assign "Cause unknown (5)" to all "Unhealty (4)" quality within first moving window
    timespanData.rootCause{k}(timespanData.cntrlQuality{k}(1:60*60/timespanData.timeStep{k}-1)==4) = 5;
    % Calculate root cause over hourly moving window
    
    for i = 60*60/timespanData.timeStep{k}:height(timespanData.plotCntrlData{k})
        % Only determine root cause for "Unhealty (4)" controller quality
        if timespanData.cntrlQuality{k}(i) == 4
            movingWindow = (i-60*60/timespanData.timeStep{k}+1:i);
            
            if sum(timespanData.plotCntrlData{k}(movingWindow,3) <...
                    mvDeadBand(1))/(60*60/timespanData.timeStep{k})*100 > 50
                % more than 10% of data saturated at low limit
                % Assign "Saturation (1)" to controller rootcause
                timespanData.rootCause{k}(i) = 1;
            elseif sum(timespanData.plotCntrlData{k}(movingWindow,3) >...
                    mvDeadBand(2))/(60*60/timespanData.timeStep{k})*100 > 50
                % more than 10% of data saturated at high limit
                % Assign "Saturation (1)" to controller rootcause
                timespanData.rootCause{k}(i) = 1;
            else
                timespanData.filtplotData{k} = timespanData.plotCntrlData{k}(movingWindow,5);
                % Fill missing data with previous value
                timespanData.filtplotData{k} = fillmissing(timespanData.filtplotData{k},'previous');
                
                if ceil(30/timespanData.timeStep{k}) >= 2
                    timespanData.filtplotData{k} = ...
                        filtfilt(ones(ceil(30/timespanData.timeStep{k}),1)...
                        /ceil(30/timespanData.timeStep{k}),1,...
                        timespanData.plotCntrlData{k}(movingWindow,5));
                end
                
                % Check for oscillation
                autoCorrelation = acf(timespanData.filtplotData{k},60*60/...
                    timespanData.timeStep{k});
                autoCorrelation(1:60*60/timespanData.timeStep{k}+1) = [];
                
                normAutoCorrelation = autoCorrelation;
                normAutoCorrelation(autoCorrelation>=0) = 1;
                normAutoCorrelation(autoCorrelation<0) = 0;
                pos = find(diff(normAutoCorrelation)==1);
                neg = find(diff(normAutoCorrelation)==-1);
                % Find half periods 2-11
                Tp = [];
                
                for j = 1:min([5 length(pos) length(neg)-1])
                    Tp(end+1) = length(neg(j)+1:pos(j));
                    Tp(end+1) = length(pos(j)+1:neg(j+1));
                end
                
                if length(Tp) < 4
                    % Assign "Cause unknown (5)" to controller rootcause
                    timespanData.rootCause{k}(i) = 5;
                elseif 1/3*mean(Tp)/std(Tp) <= 1
                    % Assign "External disturbance or slow control (2)" to controller rootcause
                    timespanData.rootCause{k}(i) = 2;
                else % control loop oscillating, check for stiction
                    MSEtri = [];
                    MSEsin = [];
                    % For each of the oscillations
                    for j = 1:min([5 length(pos) length(neg)-1])
                        % For each of the half periods per oscillation
                        for m = 1:2
                            if m == 1
                                halfPeriodData = abs(autoCorrelation(neg(j)+1:pos(j)));
                            elseif m == 2
                                halfPeriodData = abs(autoCorrelation(pos(j)+1:neg(j+1)));
                            end
                            % For each of the peak locations calculate MSEtri
                            MSEtri(end+1) = inf;
                            for n = 2:length(halfPeriodData)-1
                                % Fit positive y = mx + c; model = [x - x0]\(y - y0);
                                modelPos = ([1:n]'-1)\(halfPeriodData(1:n)-halfPeriodData(1));
                                % ypred = polyval([model;y0],xpred - x0);
                                ypredPos = polyval([modelPos;halfPeriodData(1)],[1:n]' - 1);
                                % Fit negative y = -mx + c; model = [x - x0]\(y - y0);
                                modelNeg = ([n:length(halfPeriodData)]'...
                                    -length(halfPeriodData))\...
                                    (halfPeriodData(n:end)-halfPeriodData(end));
                                % ypred = polyval([model;y0],xpred - x0);
                                ypredNeg = polyval([modelNeg;...
                                    halfPeriodData(end)],...
                                    [n:length(halfPeriodData)]' - length(halfPeriodData));
                                MSE = mean(([halfPeriodData(1:n);...
                                    halfPeriodData(n:end)]-[ypredPos; ypredNeg]).^2);
                                if MSEtri(end) > MSE
                                    MSEtri(end) = MSE;
                                end
                            end
                            % For each of the peak locations calculate MSEsin
                            model = sin([0:length(halfPeriodData)-1]'...
                                /pi)\(halfPeriodData/max(halfPeriodData));
                            
                            % Evaluate model
                            ypred = model*sin([0:length(halfPeriodData)-1]'/pi);
                            MSEsin(end+1) = mean((halfPeriodData-ypred).^2);
                        end
                    end
                    
                    % Calculate stiction index
                    SI = nanmean(MSEsin) / (nanmean(MSEsin) + nanmean(MSEtri));
                    if SI < 0.4
                        % Assign "Inner loop too fast or external disturbance (3)" to controller rootcause
                        timespanData.rootCause{k}(i) = 3;
                    elseif SI > 0.6
                        % Assign "Valve stiction or pump problem (4)" to controller rootcause
                        timespanData.rootCause{k}(i) = 4;
                    else
                        % Assign "Cause unknown (5)" to controller rootcause
                        timespanData.rootCause{k}(i) = 5;
                    end
                end
            end
        else
            timespanData.rootCause{k}(i) = 0;
        end
    end
    rootCause = timespanData.rootCause(k);
end

