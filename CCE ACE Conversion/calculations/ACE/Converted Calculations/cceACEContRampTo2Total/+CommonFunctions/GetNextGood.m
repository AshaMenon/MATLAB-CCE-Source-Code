function point = GetNextGood(Tag, CurTime)

try

    idx = find(Tag.Times > CurTime, 1);

    if ~isempty(idx)

        point.Value = Tag.Values(idx);
        point.Time = Tag.Times(idx);

    else
        point.Value = [];
        point.Times = [];
    end

catch

    point.Value = [];
    point.Time = [];

end
end