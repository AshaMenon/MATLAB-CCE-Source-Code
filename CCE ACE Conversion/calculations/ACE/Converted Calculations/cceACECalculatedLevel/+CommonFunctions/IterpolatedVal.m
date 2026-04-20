function Val = IterpolatedVal(Tag, CurTime)

    % timeIdx = Tag.Times <= CurTime + minutes(1);
    % filtVal = Tag.Values(timeIdx);
    % Val.Value = filtVal(end);
try
    Ev1 = CommonFunctions.GetLastGood(Tag, CurTime); % incase there is a value at the current time
    Ev2 = CommonFunctions.GetNextGood(Tag, CurTime);

    if ~isempty(Ev1.Value) && ~isempty(Ev2.Value)
        if Ev1.Time == CurTime % there was a value at the requested timestamp

            Val = Ev1;
        else
            Val.Value = Ev1.Value + (Ev2.Value - Ev1.Value) / ...
                (datenum(Ev2.Time) - datenum(Ev1.Time) ) * ...
                (datenum(CurTime) - datenum(Ev1.Time));

            % Val.Value = (Ev1.Value + Ev2.Value)/2;
            % Val.Time = CurTime;

            if isnumeric(Val.Value) == false
                Throw New Exception("Not numeric")
            end
        end
    elseif ~isempty(Ev1.Value)
        Val = Ev1;
    else
        Val = Ev2;
    end
catch
    Val.Value = [];
    Val.Time = [];
end
end