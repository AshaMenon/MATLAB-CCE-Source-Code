%UPDATEERRORSTATE copies the error state enum .cs file across the
%calculations and template

%Update as calculations are converted:
calculationStrings = ["calculationTemplate",...
    "ComponentArray", "PeriodSum"];

rootfolder = fileparts(mfilename('fullpath'));
inputName = fullfile(rootfolder, "NetCalculationErrorState.cs");
for iCalc = calculationStrings
    copyfile(inputName,...
        fullfile('convertedCalculations', iCalc, iCalc,...
        "NetCalculationErrorState.cs"));
end