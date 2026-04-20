function category = categoriseMatteLevel(level)
    %CATERGORISEMATTELEVEL Categorises matte level according to operation guide
    %   Detailed explanation goes here

    if level >= 72
        category = 'Run Out';
    elseif level >= 70 && level < 72
        category = 'Very High';
    elseif level >= 68 && level < 70
        category = 'High';
    elseif level >= 62 && level < 68 
        category = 'Normal';
    elseif level >= 58 && level < 62
        category = 'Very Low';
    elseif level < 58 
        category = 'Extremely Low';
    else
        category = 'Undefined';
    end
end