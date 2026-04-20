function category = categoriseBathLevel(level)
    %CATERGORISESLAGLEVEL Categorises slag level according to operation guide
    %   Detailed explanation goes here

    if level >= 220
        category = 'Extremely High';
    elseif level >= 200 && level < 220
        category = 'Above Waffle Coolers';
    elseif level >= 195 && level < 200
        category = 'Very High';
    elseif level >= 185 && level < 195
        category = 'High';
    elseif level >= 160 && level < 185 
        category = 'Normal';
    elseif level < 160 
        category = 'Low';
    else
        category = 'Undefined';
    end
end