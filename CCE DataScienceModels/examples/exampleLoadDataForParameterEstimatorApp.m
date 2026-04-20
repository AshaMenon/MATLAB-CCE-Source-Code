%% Initialise Parameter Estimation App
% Adds all the data into the workspace required to run the parameter
% optimisation app

logFile = '.\MatteTemperature.log';
calculationName = 'TestMatteTemperature';
calculationID = 'TestMT';
logLevel = 255;

log = CCELogger(logFile, calculationName, calculationID, logLevel);

[origData, timestamps, parameters] = sdoTempModelEstimation_loadAndPreprocessData(log);

% trainingIndex = 65000:110000;
% trainingIndex = 93244:135574;
trainingIndex = 208800:height(origData);
% trainingIndex = 1:height(origData);
testingIndex = trainingIndex(end):height(origData);

% For training
[data, startDate, endDate] = sdoTempModelEstimation_Measurement(trainingIndex, timestamps, origData);
data.BathHeightProxy = (data.Lanceheight + 350)/1000;
data.BathHeightProxy(data.BathHeightProxy > 3.5) = nan;
data.BathHeightProxy = fillmissing(data.BathHeightProxy, "previous");
% For testing
% [data, startDate, endDate] = sdoTempModelEstimation_Measurement(testingIndex, timestamps, origData);

[~, ~, interpolatedMatteData] = Data.getUniqueDataPoints(data(:, "Mattetemperatures"));
[~, ~, interpolatedSlagData] = Data.getUniqueDataPoints(data(:, "Slagtemperatures"));

matteDataSeries = data(:, "Mattetemperatures");
slagDataSeries = data(:, "Slagtemperatures");

%% Define Tunable Parameters

% R = 2; %4400/2/1000; %(m) Radius of the furnace
% r_s = 0.015; %(m) Radius of slag tap hole (average between new and worn, and converted from diameter to radius)
% r_m = 0.015; %0.5*(50+75)/2/2/1000; %(m) Radius of matte tap hole (average between new and worn, and converted from diameter to radius) r_m - being lanced by oxygen lance as well, ~40% of radius of drill bit
% 
% % Thermodynamics and Heat Transfer
% alpha_Fe = 0.98158; % Extent of reaction (Take estimation at 3% Fe Matte)
% alpha_Ni = 0.09776; % Extent of reaction (Take estimation at 3% Fe Matte)
% alpha_Co = 0.98228; % Extent of reaction (Take estimation at 3% Fe Matte)
% alpha_Cu = 0.48437; % Extent of reaction (Take estimation at 3% Fe Matte)
% delta_Ts = 50;%0;
% T_furnace = 1000; %300+273.15; %(K) Freeboard/furnace temperature
% epsilon = 0.92021; %0.95; %(dimensionless) TODO: Unsure about value, probably close to 1
% m_dot_dust_and_accr = 12; %2*4.35/60; %(kg/s) Average mass flow of slag accretion. TODO: Add constraints
% U = 2500; %3000; %TODO: As an estimation, between 10 and 100. This value is now a convection coefficient only.

RMax = 2;
RMin = 1.8;
R = generateRandomVariable(RMin, RMax); %4400/2/1000; %(m) Radius of the furnace

r_sMin = 0.025;
r_sMax = 0.03;%0.0375
r_s = generateRandomVariable(r_sMin, r_sMax); %(m) Radius of slag tap hole (average between new and worn, and converted from diameter to radius)

r_mMin = 0.01;
r_mMax = 0.03;
r_m = generateRandomVariable(r_mMin, r_mMax); %0.5*(50+75)/2/2/1000; %(m) Radius of matte tap hole (average between new and worn, and converted from diameter to radius) r_m - being lanced by oxygen lance as well, ~40% of radius of drill bit

vFactor_mMin = 4/3*r_mMin;
vFactor_mMax = 1;
vFactor_m = generateRandomVariable(vFactor_mMin, vFactor_mMax);

vFactor_sMin = 4/3*r_sMin;
vFactor_sMax = 1;
vFactor_s = generateRandomVariable(vFactor_sMin, vFactor_sMax);

% Thermodynamics and Heat Transfer

alpha_FeMin = 0.9;
alpha_FeMax = 1;
alpha_Fe = generateRandomVariable(alpha_FeMin, alpha_FeMax); % Extent of reaction (Take estimation at 3% Fe Matte)

alpha_NiMin = 0.01;
alpha_NiMax = 0.1;
alpha_Ni = generateRandomVariable(alpha_NiMin, alpha_NiMax); % Extent of reaction (Take estimation at 3% Fe Matte)

alpha_CoMin = 0.5;
alpha_CoMax = 1;
alpha_Co = generateRandomVariable(alpha_CoMin, alpha_CoMax); % Extent of reaction (Take estimation at 3% Fe Matte)

alpha_CuMin = 0.05;
alpha_CuMax = 0.5;
alpha_Cu = generateRandomVariable(alpha_CuMin, alpha_CuMax); % Extent of reaction (Take estimation at 3% Fe Matte)

delta_TsMin = 25;
delta_TsMax = 300;
delta_Ts = generateRandomVariable(delta_TsMin, delta_TsMax);%0;

T_furnaceMin = 373.15;
T_furnaceMax = 1473.15;
T_furnace = generateRandomVariable(T_furnaceMin, T_furnaceMax); %300+273.15; %(K) Freeboard/furnace temperature

epsilonMin = 0.88;
epsilonMax = 0.95;
epsilon = generateRandomVariable(epsilonMin, epsilonMax); %0.95; %(dimensionless) TODO: Unsure about value, probably close to 1

m_dot_dust_and_accrMin = 0.145;
m_dot_dust_and_accrMax = 30;
m_dot_dust_and_accr = generateRandomVariable(m_dot_dust_and_accrMin, m_dot_dust_and_accrMax); %2*4.35/60; %(kg/s) Average mass flow of slag accretion. TODO: Add constraints

UMin = 1000;
UMax = 6000;
U = generateRandomVariable(UMin, UMax); %3000; %TODO: As an estimation, between 10 and 100. This value is now a convection coefficient only.

%% Define Fixed Parameters

% Matte Phase
g = 9.81; %(m/s^2) Gravitational acceleration
rho_m = 5260; %(kg/m^3) Density of molten matte
Cp_matte = 710; %(J/(kg.K)) Average specific heat capacity of matte.
Cp_bar_eq = 820/Cp_matte; %TODO: calculate equivalent. f(feed)
% Slag Phase
rho_s = 3371; %(kg/m^3) Density of molten slag
Cp_slag = 910; %(J/(kg.K)) Average specific heat capacity of slag.
Cp_bar_slag = Cp_slag/Cp_matte; %(unitless)
hs_hole = 802/1000; %(m) Vertical height difference between matte/slag tapping hole
delta_H_FeS = 5443.07*1e3; %(J/kg) Specific enthalpy of reaction of FeS
delta_H_Ni3S2 = 4212.8*1e3; %(J/kg) Specific enthalpy of reaction of Ni3S2
delta_H_CoS = 4512.58*1e3; %(J/kg) Specific enthalpy of reaction of CoS
delta_H_Cu2S = 2150.04*1e3; %(J/kg) Specific enthalpy of reaction of Cu2S
delta_H_bar_r_coal = 27.294*1e9/1000; %(J/kg) Specific heat of reaction of coal

% Furnace
h_hx = 2000/1000; % (m) Height of lower heat exchanger
Cp_offgas = 1170; %(J/(kg.K)) Average specific heat capacity of offgas.
Cp_bar_offgas = Cp_offgas/Cp_matte;
sigma = 5.671e-8; % (W/(m^2K^4)) Stefan-Boltzman constant

T_amb = 25+273.15;
hm_init = 0; % Relative to vertical matte tapping hole height. Use lance height as proxy?
hs_init = (data.Lanceheight(1) + 350)/1000 - hm_init; % TODO: How did you get this? Reference to DATA
Ts_init = data.Mattetemperatures(1)+273.15+75; %Between 50 and 75, typically
Tm_init = data.Mattetemperatures(1)+273.15;

a = 0.28; %TODO: Update
b = 911.1/1000; %TODO: Defined as a function of matte feed, not total feed. Adapted units: kg offgas/kg matte fed

%% Define Inputs

inputColumnNames = {'MatteFeedTotal', 'FeedRateTot', 'Lancemotion',...
    'TappingClassificationForPhaseMattetapblock1DT_water',...
    'TappingClassificationForPhaseMattetapblock2DT_water',...
    'SlagClassification', ...
    'LowerwaffleHeatRate', 'CoalFeedRate', 'UpperwaffleHeatRate',...
    'FeFeedblend', 'NiFeedblend', 'CoFeedblend', 'CuFeedblend',...
    'Mattetemperatures', 'Slagtemperatures', 'Lanceheight',...
    'LanceOxyEnrichPercentagePV', 'SilicaPV',...
    'PhaseMattetapblock1DT_water', 'PhaseMattetapblock2DT_water',...
    'PhaseSlagtapblockDT_water', 'Convertermode'};
slInputs = double([seconds(data.Timestamp), data{:, inputColumnNames}]);

bathHeightParamOptTarget = [seconds(data.Timestamp), data.BathHeightProxy];
matteTempParamOptTarget = [seconds(interpolatedMatteData.Timestamp),...
    interpolatedMatteData.Mattetemperatures];
slagTempParamOptTarget = [seconds(interpolatedSlagData.Timestamp),...
    interpolatedSlagData.Slagtemperatures];

figure
ax1 = subplot(3,1,1);
plot(bathHeightParamOptTarget(:,2))
ax2 = subplot(3,1,2);
plot(matteTempParamOptTarget(:,2))
hold on
plot(slagTempParamOptTarget(:,2))
legend('Matte Temperature', 'Slag Temperature')
ax3 = subplot(3,1,3);
plot(data.MattefeedPV)
linkaxes([ax1, ax2, ax3], 'x')

%% Save Parameters

parameterTable = table();
parameterTable.R = R; %4400/2/1000; %(m) Radius of the furnace
parameterTable.r_s = r_s; %(m) Radius of slag tap hole (average between new and worn, and converted from diameter to radius)
parameterTable.r_m = r_m; %0.5*(50+75)/2/2/1000; %(m) Radius of matte tap hole (average between new and worn, and converted from diameter to radius) r_m - being lanced by oxygen lance as well, ~40% of radius of drill bit
parameterTable.vFactor_m = vFactor_m;
parameterTable.vFactor_s = vFactor_s;

% Thermodynamics and Heat Transfer
parameterTable.alpha_Fe = alpha_Fe; % Extent of reaction (Take estimation at 3% Fe Matte)
parameterTable.alpha_Ni = alpha_Ni; % Extent of reaction (Take estimation at 3% Fe Matte)
parameterTable.alpha_Co = alpha_Co; % Extent of reaction (Take estimation at 3% Fe Matte)
parameterTable.alpha_Cu = alpha_Cu; % Extent of reaction (Take estimation at 3% Fe Matte)
parameterTable.delta_Ts = delta_Ts;%0;
parameterTable.T_furnace = T_furnace; %300+273.15; %(K) Freeboard/furnace temperature
parameterTable.epsilon = epsilon; %0.95; %(dimensionless) TODO: Unsure about value, probably close to 1
parameterTable.m_dot_dust_and_accr = m_dot_dust_and_accr; %2*4.35/60; %(kg/s) Average mass flow of slag accretion. TODO: Add constraints
parameterTable.U = U; %3000; %TODO: As an estimation, between 10 and 100. This value is now a convection coefficient only.

writestruct(table2struct(parameterTable), ['optParams12July2023.xml'])