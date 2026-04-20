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
        idx = isbetween(ACETag.Timestamp, SearchTime - Range, SearchTime + Range);
        PIInVals.Value = ACETag.Value(idx);
        PIInVals.Timestamp = ACETag.Timestamp(idx);

        specificTimeIdx = abs(days(ACETag.Timestamp-SearchTime))<0.1;
        PIInVals.Value = PIInVals.Value(specificTimeIdx);
        PIInVals.Timestamp = PIInVals.Timestamp(specificTimeIdx);

    catch 
        PIInVals.Value = [];
        PIInVals.Timestamp = [];
    end

    %Dim Res As Double
    ResList.Timestamp = [];
    ResList.Value = [];
    ResList.Diff = [];

    PIInVals.Diff = PIInVals.Timestamp - SearchTime;

    %get values meeting time range
    for PIVal = 1:length(PIInVals.Value)
        Diff = PIInVals.Timestamp(PIVal) - SearchTime;
        if Diff > -Tol && Diff < pTol
            %meets criteria add to match list, if a match with the same tolerance exists discard second
            if ~ismember(ResList.Diff, abs(Diff))
                ResList.Value = [ResList.Value; PIInVals.Value(PIVal)];
                ResList.Timestamp = [ResList.Times; PIInVals.Timestamp(PIVal)];
                ResList.Diff = [ResList.Diff; abs(Diff)];
            end
        end
    end

    if ~isempty(ResList.Diff) % extract best match
        [~, BestDiff] = min(ResList.Diff);
        events.Value = ResList.Value(BestDiff);
        events.Timestamp = ResList.Timestamp(BestDiff);
    else
        events.Value = PIInVals.Value;
        events.Timestamp = PIInVals.Timestamp;
    end

    %For Each PIVal As PIValue In PIInVals
    %    If PIVal.TimeStamp.UTCSeconds - SearchTime > -Tol And PIVal.TimeStamp.UTCSeconds - SearchTime < pTol Then
    %        events.Value = PIVal.Value.ToString
    %        events.TimeStamp = PIVal.TimeStamp.UTCSeconds
    %    End If
    %Next

catch 
    events.Value = [];
    events.Timestamp = [];
end
end
