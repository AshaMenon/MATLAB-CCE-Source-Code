function [checkFlagB,productValue] = callPlantBCalc(input1,input2)
    objB = PlantBCalc(input1,input2);
    checkFlagB = checkValue(objB);
    productValue = multiplyValues(objB);
end