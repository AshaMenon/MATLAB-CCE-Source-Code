function dObj = bestDurationFormat(dObj)
    % bestDurationFormat  Make a duration display as meaningfully as possible
    s = seconds(dObj);
    if (s >= 86400)
        if mod(s, 86400) == 0
            dObj.Format = "d";
        else
            dObj.Format = "dd:hh:mm:ss";
        end
    elseif (s >= 3600)
        if mod(s, 3600) == 0
            dObj.Format = "h";
        else
            dObj.Format = "hh:mm:ss";
        end
    elseif (s >= 60)
        if (mod(s, 60) == 0)
            dObj.Format = "m";
        else
            dObj.Format = "mm:ss";
        end
    else
        dObj.Format = "s";
    end
end

