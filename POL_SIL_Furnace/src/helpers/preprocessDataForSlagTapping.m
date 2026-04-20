function inputsTT = preprocessDataForSlagTapping(inputsTT, parameters)
%PREPROCESSDATAFORLEVEL takes in a timetable deal with missing or
%inconsistent data and consolidate terms for input to the simulink model.

% clean data
inputsTT.SlagConveyorMass = fillmissing(inputsTT.SlagConveyorMass, "linear");
inputsTT.Flow_412_FT_201 = fillmissing(inputsTT.Flow_412_FT_201, "linear");
inputsTT.Flow_412_FT_301 = fillmissing(inputsTT.Flow_412_FT_301, "linear");
inputsTT.Flow_412_FT_401 = fillmissing(inputsTT.Flow_412_FT_401, "linear");


inputsTT.Temp_412_TT_002 = fillmissing(inputsTT.Temp_412_TT_002, "linear");
inputsTT.Temp_412_TT_007 = fillmissing(inputsTT.Temp_412_TT_007, "linear");
inputsTT.Temp_412_TT_008 = fillmissing(inputsTT.Temp_412_TT_008, "linear");
inputsTT.Temp_412_TT_009 = fillmissing(inputsTT.Temp_412_TT_009, "linear");

end