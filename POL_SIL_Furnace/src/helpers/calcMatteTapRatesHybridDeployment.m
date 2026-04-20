function matteTapRatesTonPerHr = calcMatteTapRatesHybridDeployment(inputsTT, defaultLadleWeightTon, minimumTapDurationMins, executionPeriodMins)
    %CALCMATTETAPRATESHYBRIDDEPLOYMENT calculates the matte tapping rates,
    % and applies modifications that could cause inaccuracies in
    % deployment.
    % In deployment, assuming we're not overwriting tags, issues come into
    % play when a matte tap spans more than one execution period. This
    % function solves these
    % Note: this amendment could cause unrealistically high matte tap
    % rates, but the total amount of matte tapped will remain correct
    
    matteTapRatesTonPerHr = calcMatteTapRatesHybrid(inputsTT, defaultLadleWeightTon, minimumTapDurationMins);
    
    % ensure correct behaviour for tapping events that included the last
    % and current execution window
    if length(matteTapRatesTonPerHr) <= executionPeriodMins || matteTapRatesTonPerHr(end - executionPeriodMins) == 0 || matteTapRatesTonPerHr(end - executionPeriodMins + 1) == 0
        % no matte tapping spanning current and prev window
        return
    end

    % if there is a matte tapping instance included in prev and current window
    
    % calculate tapping duration in prev window
    durationInPrevWindow = 1;
    while executionPeriodMins + durationInPrevWindow < length(matteTapRatesTonPerHr) &&  matteTapRatesTonPerHr(end-executionPeriodMins-durationInPrevWindow) > 0
        durationInPrevWindow = durationInPrevWindow + 1;
    end

    % calculate tapping duration in current window
    durationInCurrWindow= 1;
    while durationInCurrWindow < executionPeriodMins &&  matteTapRatesTonPerHr(end-executionPeriodMins+1+durationInCurrWindow) > 0
        durationInCurrWindow = durationInCurrWindow+ 1;
    end


    if durationInPrevWindow >= minimumTapDurationMins
        % ignore tapping in current window since it's already been included
        % in the previous window
        matteTapRatesTonPerHr(end-executionPeriodMins+1 : end-executionPeriodMins+durationInCurrWindow) = 0;
    else
        % treat the full ladle as if it was tapped in the current window
        % since it was ignored in the previous one
        matteTapRatesTonPerHr(end-executionPeriodMins+1-durationInPrevWindow : end-executionPeriodMins) = 0;
        
        tapRateTonPerHr = (defaultLadleWeightTon/durationInCurrWindow) * 60;
        matteTapRatesTonPerHr(end-executionPeriodMins+1 : end-executionPeriodMins+durationInCurrWindow) = tapRateTonPerHr;
    end
end

