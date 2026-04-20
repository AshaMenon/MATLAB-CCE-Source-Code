function point = GetLastGood(Tag, CurTime)

try

    idx = find(Tag.Times < CurTime, 1, "last");

    if ~isempty(idx)

        point.Value = Tag.Values(idx);
        point.Time = Tag.Times(idx);

    else
        point.Value = [];
        point.Time = [];
    end

catch

    point.Value = [];
    point.Time = [];

end
end