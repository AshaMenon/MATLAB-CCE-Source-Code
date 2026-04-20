function [checkFlagA,sumValue] = callPlantACalc(input1,input2)
    objA = PlantACalc(input1,input2);
    checkFlagA = checkValue(objA);
    sumValue = addValues(objA);
end