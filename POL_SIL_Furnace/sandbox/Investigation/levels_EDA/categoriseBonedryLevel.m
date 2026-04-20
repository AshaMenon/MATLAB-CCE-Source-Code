function category = categoriseBonedryLevel(level)
    %CATERGORISEBONEDRYLEVEL Categorises bonedry level according to operation guide
    %   Detailed explanation goes here

    if level >= 120
        category = 'Extremely High';
    elseif level >= 100 && level < 120
        category = 'High';
    elseif level >= 80 && level < 100
        category = 'Normal';
    elseif level < 80
        category = 'Low';
    else
        category = 'Undefined';
    end
end