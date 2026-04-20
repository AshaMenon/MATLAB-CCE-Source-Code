function events = GetValueAtTime(ACETag, GetTime, Tol, pTol, Range)

arguments
    ACETag
    GetTime
    Tol
    pTol = 0.25;
    Range = 30;
end

events = struct;

% ACETag.AdjustClockOffset = True;

try

    timeIdx = isbetween(ACETag.Times, GetTime - seconds(Tol), GetTime + seconds(Tol));

    if nnz(timeIdx) > 0
        vals = ACETag.Values(timeIdx);
        times = ACETag.Times(timeIdx);

        events.Value = vals(end);
        events.Time = times(end);
    else
        events.Value = 0;
        events.Time = NaT;
    end

catch 
    events.Value = [];
    events.Time = [];
end
end