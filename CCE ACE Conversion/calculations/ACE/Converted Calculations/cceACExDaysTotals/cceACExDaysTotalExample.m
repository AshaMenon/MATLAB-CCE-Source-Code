parameters = struct;
parameters.LogName = "xDaysTotal.log";
parameters.CalculationName = "xDaysTotal";
parameters.CalculationID = "xDaysTotal";
parameters.LogLevel = 4;

parameters.OutputTime = "2023-12-05T12:00:00.000Z";
parameters.CalcPath = "\\usmlpi.angloiit.net\StreamMapperReceiptsCalcs\ReceiptsHourly"; % Context

inputs = struct();

[outputs,errorCode] = cceACExDaysTotals(parameters, inputs);