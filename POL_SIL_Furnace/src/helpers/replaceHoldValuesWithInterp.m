function array = replaceHoldValuesWithInterp(array)
    
    changeInVals = abs(gradient(array));
    array(1 > changeInVals) = NaN;

    array = fillmissing(array, 'linear');

end