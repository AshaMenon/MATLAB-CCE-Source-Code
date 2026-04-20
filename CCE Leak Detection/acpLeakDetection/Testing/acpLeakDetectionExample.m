% Example script for executing R Calculation via MATLAB

% All Parameters
% configPath = 'Config.csv';
% config = readtable(configPath);
% attribute_name = strcat(string(config.Feature), "_",string(config.Section),"_",...
%     string(config.Phase), "_", string(config.Digital));

%% Parameters
parameters = struct;
parameters.OutputTime = "2023-09-02T06:00:00.000Z";
parameters.LogName = "ContRampTo2Total.log";
parameters.CalculationName = "ACEContRampTo2Total";
parameters.CalculationID = "ACEContRampTo2Total";
parameters.LogLevel = 4;
parameters.FactorTypeTags = "ConvertorMode_0_0";
parameters.ConvertorPhase = 2;
%ModelPerformance
parameters.ModelPerformance_errormean = -0.000795389729336685;
parameters.ModelPerformance_errorul = 0.27726862000318;
parameters.ModelPerformance_errorll = -0.278859399461853;
parameters.ModelPerformance_errorsd = 0.278064009732516;
parameters.ModelPerformance_rmse = 0.278063793222971;
parameters.ModelPerformance_rsq = 0.964031224621893;
parameters.ModelPerformance_bias = -0.0291446134978409;
% Lance Air
parameters.LanceAir_0_0_F_GrossOutlierDetection = 1;
parameters.LanceAir_0_0_F_GrossOutlierDetection_k = 5;
parameters.LanceAir_0_0_F_Smoothing = 1;
parameters.LanceAir_0_0_F_Smoothing_a = 60;
parameters.LanceAir_0_0_F_Smoothing_p = 0.6;
% parameters.LanceAir_0_0_Tag = "PrcCtl_LanceGas/LaArOxCtl.LaArPV";
% Convertor Mode
parameters.ConvertorMode_0_0_F_GrossOutlierDetection = 0;
parameters.ConvertorMode_0_0_F_GrossOutlierDetection_k = -1;
parameters.ConvertorMode_0_0_F_Smoothing = 0;
parameters.ConvertorMode_0_0_F_Smoothing_a = -1;
parameters.ConvertorMode_0_0_F_Smoothing_p = -1;
%
parameters.MakeUpPump012_0_1_F_GrossOutlierDetection = 0;
parameters.MakeUpPump012_0_1_F_GrossOutlierDetection_k = -1;
parameters.MakeUpPump012_0_1_F_Smoothing = 0;
parameters.MakeUpPump012_0_1_F_Smoothing_a = -1;
parameters.MakeUpPump012_0_1_F_Smoothing_p = -1;
%
parameters.MakeUpPump005_0_1_F_GrossOutlierDetection = 0;
parameters.MakeUpPump005_0_1_F_GrossOutlierDetection_k = -1;
parameters.MakeUpPump005_0_1_F_Smoothing = 0;
parameters.MakeUpPump005_0_1_F_Smoothing_a = -1;
parameters.MakeUpPump005_0_1_F_Smoothing_p = -1;
% parameters.ConvertorMode_0_0_Tag = "PrcCtl_Modes/PrcMd.PrcMdQ"; 

%% Inputs
% inputsFile = "acpLeakDetectionDataSample.xlsx";
% data = readtable(inputsFile,'Sheet', 4,'VariableNamingRule', 'preserve');
% inputs = struct;
% inputs.LanceAir_0_0Timestamps = data.Timestamp(data.Tag == "A:lance_air");
% inputs.LanceAir_0_0 = data.Value(data.Tag == "A:lance_air");
% inputs.ConvertorMode_0_0Timestamps = data.Timestamp(data.Tag == "PrcCtl_Modes/PrcMd.PrcMdQ");
% inputs.ConvertorMode_0_0 = data.Value(data.Tag == "PrcCtl_Modes/PrcMd.PrcMdQ");
% Inputs = struct2table(inputs);
% writetable(Inputs,'Inputs.xlsx');

data = readtable('acpLeakDetection.xlsx','VariableNamingRule', 'preserve', 'Sheet',2);
%data = data(1:10,:);
inputs = struct;
inputs.LanceAir_0_0Timestamps = datetime(data.LanceAir_0_0Timestamps);
inputs.LanceAir_0_0 = data.LanceAir_0_0;
inputs.ConvertorMode_0_0Timestamps = datetime(data.LanceAir_0_0Timestamps);
% inputs.ConvertorMode_0_0 = data.ConvertorMode_0_0;
inputs.ConvertorMode_0_0 = randi(8,height(data),1);
inputs.MakeUpPump005_0_1 = data.LanceAir_0_0;
inputs.MakeUpPump012_0_1 = data.LanceAir_0_0;
inputs.MakeUpPump005_0_1Timestamps = datetime(data.LanceAir_0_0Timestamps);
inputs.MakeUpPump012_0_1Timestamps = datetime(data.LanceAir_0_0Timestamps);

%% Evaluate R Calc
[outputs, errorCode] = acpLeakDetection(parameters,inputs);
