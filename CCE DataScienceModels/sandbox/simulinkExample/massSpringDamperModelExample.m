parameters.LogName = ".\MassSpringDamperModel.log";
parameters.CalculationID = "Mass1";
parameters.LogLevel = 255;
parameters.CalculationName = "MassSpringDamperModel";

parameters.StiffnessSpinnerValue = 128;
inputs.MassSpinnerValue = 2;
inputs.TestInput = 0;
parameters.DampingSpinnerValue = 3;
parameters.InitialPositionEditFieldValue = 0;
parameters.StopTimeSpinnerValue = 20;
parameters.InputForceMagnitudeSpinnerValue = 10;
parameters.InputForceShapeDropDownValue = 'Gate';


[outputs, errorCode] = testMassSpringDamperModel(parameters, inputs);


