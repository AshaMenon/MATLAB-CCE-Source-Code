function total = GetTotalizedPeriod(tag, first_date, second_date)

tot = nan;
total = [];

try
    idx = isbetween(tag.Times, first_date, second_date);
    values = tag.Values(idx);
    timestamps = tag.Times(idx);
    for i = 1:length(values)
        if IsNumeric(values(i)) && ~isnan(values(i)) && (timestamps(i) >= first_date && timestamps(i) <= second_date)
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