%Data upload and initialization
parameters = struct();
inputs = struct();

%Set up logging
parameters.Path = 'chemistryData_Apr-Jun-22_v1.csv';

parameters.LogName = 'CCE Data Upload';

parameters.CalculationID = 'TLB';

parameters.LogLevel = 'All';

parameters.CalculationName = 'Test CCE Data Upload';

[outputs, errorCode] = dataUpload(parameters,inputs);