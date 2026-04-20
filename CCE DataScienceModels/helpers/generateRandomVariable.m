function var = generateRandomVariable(varMin, varMax)
%GENERATERANDOMVARIABLE - To be used with the parameter estimator app.
%   Generates random number between VARMIN and VARMAX

var = varMin + (varMax - varMin)*rand;

end