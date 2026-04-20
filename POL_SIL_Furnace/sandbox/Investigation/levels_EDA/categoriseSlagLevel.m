function category = categoriseSlagLevel(level)
    %CATERGORISESLAGLEVEL Categorises slag level according to operation guide
    %   Detailed explanation goes here

    if level >= 145
        category = 'Extremely High';
    elseif level >= 130 && level < 145
        category = 'Very High';
    elseif level >= 120 && level < 130
        category = 'High';
    elseif level >= 100 && level < 120 
        category = 'Normal';
    elseif level >= 90 && level < 100
        category = 'Low';
    elseif level >= 80 && level < 90
        category = 'Very Low';
    elseif level < 80 
        category = 'Extremely Low';
    else
        category = 'Undefined';
    end
end
