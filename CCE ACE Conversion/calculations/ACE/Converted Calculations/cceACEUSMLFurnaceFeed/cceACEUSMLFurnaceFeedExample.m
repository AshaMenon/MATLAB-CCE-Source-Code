%% Inputs
contData = readtable("USMLFurnaceData.xlsx", "Sheet", "Sheet6");
variables = string(contData.Properties.VariableNames);

for n = 1:2:length(variables)
    variables(n) = variables(n+1) + "Timestamps";
end

contData.Properties.VariableNames = variables;
% variables(1:14) = [];

inputs = struct;

for varName = variables
    inputs.(varName) = contData{:, varName};
end


%% Parameters

parameters = struct;
parameters.OutputTime = "2023-04-18T05:14:00.000Z";
parameters.LogName = "USMLFurnaceFeed.log";
parameters.CalculationName = "ACEUSMLFurnaceFeed";
parameters.CalculationID = "ACEUSMLFurnaceFeed";
parameters.LogLevel = 4;

parameters.LastState = "On";

parameters.ACE_xfer_Tot_Span = 2200;
parameters.ACE_xfer_Tot_Zero = 0;
parameters.ACE_xfr_2tot_Span = 100;
parameters.ACE_xfr_2tot_Zero = 0;
parameters.ACE_TotSmelted_Calc_2Tot_Span = 4000;
parameters.ACE_TotSmelted_Calc_2Tot_Zero = 0;
parameters.ACE_PlantRecycle_Tot_Span = 600;
parameters.ACE_PlantRecycle_Tot_Zero = 0;
parameters.ACE_NewConc_Tot_Span = 4000;
parameters.ACE_NewConc_Tot_Zero = 0;
parameters.ACE_SEC_xfer_NewConc_Span = 1900;
parameters.ACE_SEC_xfer_NewConc_Zero = 0;
parameters.ACE_SEC_xfer_BD_Span = 1900;
parameters.ACE_SEC_xfer_BD_Zero = 0;
parameters.ACE_Smelted_Calc_2Tot_Span = 2200;
parameters.ACE_Smelted_Calc_2Tot_Zero = 0;
parameters.ACE_Fed_Tot_Span = 2200;
parameters.ACE_Fed_Tot_Zero = 0;

%%
expectedOutputs = struct;
expectedOutputs.ACE_xfer_Tot = contData.ACE_xfer_Tot(12:13);
expectedOutputs.ACE_xfr_2tot = contData.ACE_xfr_2tot(6:7);
expectedOutputs.ACE_TotSmelted_Calc_2Tot = contData.ACE_TotSmelted_Calc_2Tot(12:13);
expectedOutputs.ACE_Smelted_Calc_2Tot = contData.ACE_Smelted_Calc_2Tot(12:13);
expectedOutputs.ACE_PlantRecycle_Tot = contData.ACE_PlantRecycle_Tot(12:13);
expectedOutputs.ACE_NewConc_Tot = contData.ACE_NewConc_Tot(12:13);
expectedOutputs.ACE_SEC_xfer_NewConc = contData.ACE_SEC_xfer_NewConc(12:13);
expectedOutputs.ACE_SEC_xfer_BD = string(contData.ACE_SEC_xfer_BD(12:13));
expectedOutputs.ACE_Fed_Tot = contData.ACE_Fed_Tot(12:13);

%%

[outputs,errorCode] = cceACEUSMLFurnaceFeed(parameters, inputs);