inTbl = readtable("data2.xlsx");

inputs = table2struct(inTbl, "ToScalar", true);
inputs.FCE2_Electrode1_SlipPowerKPI_24_5Timestamps = ...
    datetime(inputs.FCE2_Electrode1_SlipPowerKPI_24_5Timestamps);

%% Parameters

parameters = struct;
parameters.OutputTime = "2023-09-02T06:00:00.000Z";
parameters.LogName = "ContRampTo2Total.log";
parameters.CalculationName = "ACEContRampTo2Total";
parameters.CalculationID = "ACEContRampTo2Total";
parameters.LogLevel = 4;
parameters.CompDev = 0.6;
parameters.Zero = -2000;
parameters.Formula = "'tag'/'T:350-PY-211/PV.V.TT'24.5.2Tot'*'T:350-EY-211/PV.V.TOTAVE'24.5.2Tot'/('T:350-EY-211/PV.V.TOTAVE'24.5.2Tot'+'T:350-EY-221/PV.V.TOTAVE'24.5.2Tot')";

%% Run Calc
[outputs, errorCode] = cceACEContRampTo2Total(parameters, inputs);