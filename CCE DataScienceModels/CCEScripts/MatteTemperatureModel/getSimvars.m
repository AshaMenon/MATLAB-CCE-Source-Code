function simVar = getSimvars(data, parameters, log)
simVar = struct();

% Matte Phase
simVar.g = 9.81; %(m/s^2) Gravitational acceleration
simVar.rho_m = 5260; %(kg/m^3) Density of molten matte
simVar.Cp_matte = 710; %(J/(kg.K)) Average specific heat capacity of matte.
simVar.Cp_bar_eq = 820/simVar.Cp_matte; %TODO: calculate equivalent. f(feed)
% Slag Phase
simVar.rho_s = 3371; %(kg/m^3) Density of molten slag
simVar.Cp_slag = 910; %(J/(kg.K)) Average specific heat capacity of slag.
simVar.Cp_bar_slag = simVar.Cp_slag/simVar.Cp_matte; %(unitless)
simVar.hs_hole = 802/1000; %(m) Vertical height difference between matte/slag tapping hole
simVar.delta_H_FeS = 5443.07*1e3; %(J/kg) Specific enthalpy of reaction of FeS
simVar.delta_H_Ni3S2 = 4212.8*1e3; %(J/kg) Specific enthalpy of reaction of Ni3S2
simVar.delta_H_CoS = 4512.58*1e3; %(J/kg) Specific enthalpy of reaction of CoS
simVar.delta_H_Cu2S = 2150.04*1e3; %(J/kg) Specific enthalpy of reaction of Cu2S
simVar.delta_H_bar_r_coal = 27.294*1e9/1000; %(J/kg) Specific heat of reaction of coal

% Furnace
simVar.h_hx = 2000/1000; % (m) Height of lower heat exchanger
simVar.Cp_offgas = 1170; %(J/(kg.K)) Average specific heat capacity of offgas.
simVar.Cp_bar_offgas = simVar.Cp_offgas/simVar.Cp_matte;
simVar.sigma = 5.671e-8; % (W/(m^2K^4)) Stefan-Boltzman constant

simVar.T_amb = 25+273.15;
simVar.hm_init = 0.1*(data.Lanceheight(1) + 350)/1000; % Relative to vertical matte tapping hole height. Use lance height as proxy?
simVar.hs_init = (data.Lanceheight(1) + 350)/1000 - simVar.hm_init; % TODO: How did you get this? Reference to DATA
simVar.Ts_init = data.Slagtemperatures(1)+273.15;
simVar.Tm_init = data.Mattetemperatures(1)+273.15;

simVar.a = 0.28; %TODO: Update
simVar.b = 911.1/1000; %TODO: Defined as a function of matte feed, not total feed. Adapted units: kg offgas/kg matte fed

switch parameters.phase
    case 'A'
        % Furnace and Tapping Geometry
        simVar.R = 2.0292; %4400/2/1000; %(m) Radius of the furnace
        simVar.r_s = 50/2/1000; %(m) Radius of slag tap hole (average between new and worn, and converted from diameter to radius)
        simVar.r_m = 0.01; %0.5*(50+75)/2/2/1000; %(m) Radius of matte tap hole (average between new and worn, and converted from diameter to radius) r_m - being lanced by oxygen lance as well, ~40% of radius of drill bit
        simVar.vFactor_m = 0.90217;
        simVar.vFactor_s = 0.48372;
        
        % Thermodynamics and Heat Transfer
        simVar.alpha_Fe = 0.98; % Extent of reaction (Take estimation at 3% Fe Matte)
        simVar.alpha_Ni = 0.0425; % Extent of reaction (Take estimation at 3% Fe Matte)
        simVar.alpha_Co = 0.81; % Extent of reaction (Take estimation at 3% Fe Matte)
        simVar.alpha_Cu = 0.17; % Extent of reaction (Take estimation at 3% Fe Matte)
        simVar.delta_Ts = 95.9814 ;%0;
        simVar.T_furnace = 1223; %300+273.15; %(K) Freeboard/furnace temperature
        simVar.epsilon = 1.1981; %0.95; %(dimensionless) TODO: Unsure about value, probably close to 1
        simVar.m_dot_dust_and_accr = 15; %2*4.35/60; %(kg/s) Average mass flow of slag accretion. TODO: Add constraints
        simVar.U = 2362.7; %3000; %TODO: As an estimation, between 10 and 100. This value is now a convection coefficient only.
    case 'B'
        % Furnace and Tapping Geometry
        simVar.R = 1.99999999937441; %4400/2/1000; %(m) Radius of the furnace
        simVar.r_s = 0.0251311024675526; %(m) Radius of slag tap hole (average between new and worn, and converted from diameter to radius)
        simVar.r_m = 0.0106265008097476; %0.5*(50+75)/2/2/1000; %(m) Radius of matte tap hole (average between new and worn, and converted from diameter to radius) r_m - being lanced by oxygen lance as well, ~40% of radius of drill bit
        simVar.vFactor_m = 0.90217;
        simVar.vFactor_s = 0.48372;

        % Thermodynamics and Heat Transfer
        simVar.alpha_Fe = 0.999999999999978; % Extent of reaction (Take estimation at 3% Fe Matte)
        simVar.alpha_Ni = 0.0995145998719664; % Extent of reaction (Take estimation at 3% Fe Matte)
        simVar.alpha_Co = 0.999999999999978; % Extent of reaction (Take estimation at 3% Fe Matte)
        simVar.alpha_Cu = 0.499999999999989; % Extent of reaction (Take estimation at 3% Fe Matte)
        simVar.delta_Ts = 222.298903763273;%0;
        simVar.T_furnace = 1473.14999999992; %300+273.15; %(K) Freeboard/furnace temperature
        simVar.epsilon = 0.94999999999996; %0.95; %(dimensionless) TODO: Unsure about value, probably close to 1
        simVar.m_dot_dust_and_accr = 2.36685052980685; %2*4.35/60; %(kg/s) Average mass flow of slag accretion. TODO: Add constraints
        simVar.U = 2461.322414440706; %3000; %TODO: As an estimation, between 10 and 100. This value is now a convection coefficient only.
end

if ~isequal(parameters.optimalParameterFile, "null")
    directorySplit = strsplit(parameters.optimalParameterFile, '\');
    fileName = directorySplit{end};
    optimalParams = readstruct(parameters.optimalParameterFile);
    simVar.U = optimalParams.U;
    simVar.delta_Ts = optimalParams.delta_Ts;
    simVar.alpha_Fe = optimalParams.alpha_Fe;
    simVar.alpha_Ni = optimalParams.alpha_Ni;
    simVar.alpha_Co = optimalParams.alpha_Co;
    simVar.alpha_Cu = optimalParams.alpha_Cu;
    simVar.m_dot_dust_and_accr = optimalParams.m_dot_dust_and_accr;
    simVar.epsilon = optimalParams.epsilon;
    simVar.T_furnace = optimalParams.T_furnace;
    simVar.R = optimalParams.R; 
    simVar.r_s = optimalParams.r_s; 
    simVar.r_m = optimalParams.r_m; 
    simVar.vFactor_m = optimalParams.vFactor_m; 
    simVar.vFactor_s = optimalParams.vFactor_s; 
else
    log.logWarning('No Optimal Parameter Set Specifed. Using default values.')
end

end