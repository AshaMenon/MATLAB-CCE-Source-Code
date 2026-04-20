setup
load("init.mat")
load("sl_config.mat")

%% Aligned Fe Model
buildCalc("AlignedFeModel", {'EvaluateFeMatteModel'}, {''})

%% SPO2 Model
buildCalc("SPO2Model", {'EvaluateSPO2Model'}, {''})

%% Basicity Model
buildCalc("BasicityModel", {'EvaluateBasicityModel'}, {''})

%% Matte Temp Model
buildCalc("MatteTempModel", {'EvaluateTemperatureModel'}, {''})
