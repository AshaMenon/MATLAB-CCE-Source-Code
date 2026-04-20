function events = GetValueAtTime(ACETag, GetTime, Tol, pTol, Range)

arguments
    ACETag
    GetTime
    Tol
    pTol = 0.25;
    Range = 30;
end

%Need to minus clockdrift, the server adds the drift to the local machine time for data extraction

SearchTime = GetTime;
events = [];

% ACETag.AdjustClockOffset = True;

try

    PIInVals = []; % input values from PI

    try %get input data

        % PIInVals = ACETag.Values(SearchTime - Range - CDbl(ACETag.ClockDrift), SearchTime + Range - CDbl(ACETag.ClockDrift), BoundaryTypeConstants.btInside)
        idx = isbetween(ACETag.Times, SearchTime - seconds(Range), SearchTime + seconds(Range));
        PIInVals.Values = ACETag.Values(idx);
        PIInVals.Times = ACETag.Times(idx);

    catch 
        PIInVals.Values = [];
        PIInVals.Times = [];
    end

    %Dim Res As Double
    ResList.Times = NaT;
    ResList.Values = nan;
    ResList.Diff = nan;

    PIInVals.Diff = seconds(PIInVals.Times - SearchTime);

    %get values meeting time range
    for PIVal = 1:length(PIInVals.Values)
        Diff = seconds(PIInVals.Times(PIVal) - SearchTime);
        if Diff > -Tol && Diff < pTol
            %meets criteria add to match list, if a match with the same tolerance exists discard second
            if ~ismember(ResList.Diff, abs(Diff))
                ResList.Values = [ResList.Values; PIInVals.Values(PIVal)];
                ResList.Times = [ResList.Times; PIInVals.Times(PIVal)];
                ResList.Diff = [ResList.Diff; abs(Diff)];
            end
        end
    end

    if ~isempty(ResList.Diff) % extract best match
        [~, BestDiff] = min(ResList.Diff);
        events.Value = ResList.Values(BestDiff);
        events.Time = ResList.Times(BestDiff);
    end

catch 
    events.Value = [];
    events.Time = [];
end
end