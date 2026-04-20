function total = GetTotalizedPeriod(tag, first_date, second_date)

tot = nan;
total = [];

try
    idx = isbetween(tag.Timestamp, first_date, second_date+seconds(1));
    values = tag.Value(idx);
    timestamps = tag.Timestamp(idx);
    for i = 1:length(values)
        if isnumeric(values(i)) && ~isnan(values(i)) && (timestamps(i) >= first_date && timestamps(i) <= second_date+seconds(1))
            if isnan(tot)
                tot = values(i);
            else
                tot = tot + values(i);
            end

        end
    end

    if ~isnan(tot)
        total = tot;
    end

catch

    total = [];

    %If there's an error return nothing
end
end
