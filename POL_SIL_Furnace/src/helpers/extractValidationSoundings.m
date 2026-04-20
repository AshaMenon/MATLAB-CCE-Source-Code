function [validMatteSoundingsCm, isValidationMatteSounding, validSlagSoundingsCm, isValidationSlagSounding, validConcSoundingsCm, isValidationConcSounding] = extractValidationSoundings(inputsTT, ...
        NameValueArgs)
% EXTRACTVALIDATIONSOUNDINGS extracts the sounding values to be used for
% validation metrics such as RMSE
% This function assumes that the first row in inputsTT corresponds to a
% sounding (though not necessarily a valid one).
% Note: the criteria for a sounding to be used for validation metrics might
% will likely be less strict than the criteria for a sounding to be used as
% an initial condition for the model

arguments
    inputsTT {mustBeA(inputsTT, ["table", "timetable"])}
    NameValueArgs.tolCm (1, 1) {mustBeNumeric} = 0.1
    NameValueArgs.matteLevelMaxCm (1, 1) {mustBeNumeric} = 76
    NameValueArgs.matteLevelMinCm (1, 1) {mustBeNumeric} = 54
    NameValueArgs.slagLevelMaxCm (1, 1) {mustBeNumeric} = 150
    NameValueArgs.slagLevelMinCm (1, 1) {mustBeNumeric} = 76
    NameValueArgs.concLevelMaxCm (1, 1) {mustBeNumeric} = 130
    NameValueArgs.concLevelMinCm (1, 1) {mustBeNumeric} = 0
    NameValueArgs.includeFirstVal (1, 1) {mustBeA(NameValueArgs.includeFirstVal, "logical")} = false % whether to treat the first value as a 'soundng'
end

[validMatteSoundingsCm, isValidationMatteSounding] = extractValidationSoundingsForComponent(inputsTT.MatteThickness + inputsTT.BuildUpThickness, NameValueArgs.tolCm, NameValueArgs.matteLevelMaxCm, NameValueArgs.matteLevelMinCm, NameValueArgs.includeFirstVal);
[validSlagSoundingsCm, isValidationSlagSounding] = extractValidationSoundingsForComponent(inputsTT.SlagThickness, NameValueArgs.tolCm, NameValueArgs.slagLevelMaxCm, NameValueArgs.slagLevelMinCm, NameValueArgs.includeFirstVal);
[validConcSoundingsCm, isValidationConcSounding] = extractValidationSoundingsForComponent(inputsTT.ConcThickness, NameValueArgs.tolCm, NameValueArgs.concLevelMaxCm, NameValueArgs.concLevelMinCm, NameValueArgs.includeFirstVal);
end

function [validationSoundings, isValidationSounding] = extractValidationSoundingsForComponent(values, tolerance, max, min, includeFirstVal)
    isValidationSounding = [includeFirstVal; abs(diff(values)) > tolerance] & values <= max & values >= min;
    validationSoundings = values(isValidationSounding);
end