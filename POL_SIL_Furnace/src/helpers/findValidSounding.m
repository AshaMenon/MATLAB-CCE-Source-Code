function isValidArray = findValidSounding(sounding, changeThreshold)
soundingHeld = fillmissing(sounding, "previous");
changeInHeight = [0; abs(diff(soundingHeld))];
isValidArray = (changeInHeight <= changeThreshold) & (~isnan(sounding));
end