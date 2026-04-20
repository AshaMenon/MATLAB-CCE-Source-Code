function point = GetLastGood(Tag, CurTime)

try

    idx = find(Tag.Times < CurTime, 1, "last");

    if ~isempty(idx)

        point.Values = Tag.Values(idx);
        point.Time = Tag.Times(idx);

    else
        point.Values = [];
        point.Time = [];
    end

catch

    point.Values = [];
    point.Time = [];

end
end