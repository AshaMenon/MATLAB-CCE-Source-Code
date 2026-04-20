# -*- coding: utf-8 -*-
import numpy as np
import pandas as pd
from numpy import asarray, exp, log, log10, nan, nansum, zeros, isfinite
from rainflow import count_cycles
from scipy.optimize import root_scalar
import CCEUtils.common.cce_logger as cce_logger
import CCEUtils.common.calculation_error_state as ces

# --- CONSTANTS FROM ORIGINAL LOGIC ---
bs7608 = {
    'B': {'C_0': 2.34e15, 'Log10C_0': 15.36977, 'm': 4, 'SD': 0.1821, 'C_2': 1.01e15, 'S_oc': 100, 'S_ov': 67},
    'C': {'C_0': 1.08e14, 'Log10C_0': 14.03423, 'm': 3.5, 'SD': 0.2041, 'C_2': 4.23e13, 'S_oc': 78, 'S_ov': 50},
    'D': {'C_0': 3.99e12, 'Log10C_0': 12.60076, 'm': 3, 'SD': 0.2095, 'C_2': 1.52e12, 'S_oc': 53, 'S_ov': 31},
    'E': {'C_0': 3.29e12, 'Log10C_0': 12.51706, 'm': 3, 'SD': 0.2509, 'C_2': 1.04e12, 'S_oc': 47, 'S_ov': 28},
    'F': {'C_0': 1.73e12, 'Log10C_0': 12.23704, 'm': 3, 'SD': 0.2183, 'C_2': 6.33e11, 'S_oc': 40, 'S_ov': 23},
    'F2': {'C_0': 1.23e12, 'Log10C_0': 12.09026, 'm': 3, 'SD': 0.2279, 'C_2': 4.32e11, 'S_oc': 35, 'S_ov': 21},
    'G': {'C_0': 5.66e11, 'Log10C_0': 11.75251, 'm': 3, 'SD': 0.1793, 'C_2': 2.5e11, 'S_oc': 29, 'S_ov': 17},
    'G2': {'C_0': 3.91e11, 'Log10C_0': 11.59184, 'm': 3, 'SD': 0.1952, 'C_2': 1.48e11, 'S_oc': 25, 'S_ov': 14},
    'W1': {'C_0': 2.5e11, 'Log10C_0': 11.39794, 'm': 3, 'SD': 0.214, 'C_2': 9.33e10, 'S_oc': 21, 'S_ov': 12},
    'X': {'C_0': 9.3e11, 'Log10C_0': 11.96839, 'm': 3, 'SD': 0.2134, 'C_2': 3.51e11, 'S_oc': 33, 'S_ov': 19},
    'S_1': {'C_0': 5.9e16, 'Log10C_0': 16.771, 'm': 5, 'SD': 0.235, 'C_2': 2e16, 'S_oc': 46, 'S_ov': 46},
    'S_2': {'C_0': 3.95e16, 'Log10C_0': 16.59649, 'm': 5, 'SD': 0.39, 'C_2': 6.55e15, 'S_oc': 37, 'S_ov': 37},
    'TJ': {'C_0': 8.75e12, 'Log10C_0': 12.94201, 'm': 3, 'SD': 0.233, 'C_2': 3.02e12, 'S_oc': 67, 'S_ov': 39},
}

weld_params = {
    'k': 1192, 'n': 0.17, 'E': 188e3, 
    'sigf': (bs7608['C']['C_0']**(1/bs7608['C']['m']))/1.6, 
    'b': -0.333, 'epsf': 0.13, 'C': -0.43
}

# --- HELPER FUNCTIONS FROM ORIGINAL LOGIC ---
def determine_K(plot_class, curve_type='2'):
    mean_endur_stress = 10**((bs7608['C']['Log10C_0'] - log10(10**7))/bs7608['C']['m'])
    class_spec_endur_stress = 10**((log10(bs7608[plot_class]['C_'+curve_type]) - log10(10**7))/bs7608[plot_class]['m'])
    return mean_endur_stress / class_spec_endur_stress

def compute_cycles_to_failure(stress_ranges, material_params):
    k, n, E, sigf, b, epsf, C = material_params.values()
    def eq(N, strain_amp):
        return sigf / E * (2*N)**b + epsf * (2*N)**C - strain_amp
    
    ctf = zeros(len(stress_ranges))
    for i, stress in enumerate(stress_ranges):
        strain_amp = (stress/2) / E + (stress/2/k)**(1/n)
        try:
            sol = root_scalar(eq, args=(strain_amp,), method='brentq', bracket=[1, 1e9])
            ctf[i] = sol.root if sol.converged else nan
        except: ctf[i] = nan
    return ctf

def fen_carbon_steel(T, eps_rate, DO, S):
    S_ = 2 + 98 * S if S <= 0.015 else 3.47
    T_ = 0.395 if T < 150 else (T-75)/190
    O_ = 1.49 if DO < 0.04 else (log(DO/0.009) if DO < 0.5 else 4.02)
    eps_rate_ = log(max(eps_rate, 0.0004)/2.2) if eps_rate <= 2.2 else 0
    return exp((0.003 - 0.031 * eps_rate_) * S_ * T_ * O_)

# --- THE CCE ENTRY POINT ---
def EvaluateFatigueModel(parameters, inputs):
    outputs = {}
    error_code = ces.CalculationErrorState.GOOD.value
    log_obj = cce_logger.CCELogger(parameters['LogName'], parameters['CalculationName'], 
                                   parameters['CalculationID'], parameters['LogLevel'])
    
    try:
        # 1. Process Input Data (Last 7 days at 1-minute interval provided by CCE)
        data = [t for t in inputs['Tag'] if isfinite(t)]
        if len(data) < 2:
            outputs['TotalDamage'] = [0.0]
            outputs['Timestamp'] = [float(inputs['TagTimestamps'][-1])]
            return [outputs, error_code]

        # 2. Extract Parameters
        stress_ref = float(parameters['StressRange'])
        w_class    = str(parameters['WeldClass']).strip()
        c_type     = str(int(parameters['CurveType'])) # '0' or '2'
        
        # 3. Environmental Scaling
        T_effect = 1 / (1 - 4e-4 * (float(parameters['T']) - 20))
        K = determine_K(w_class, c_type)

        # 4. Rainflow counting (binsize 5 as per original logic)
        rf_raw = count_cycles(data, binsize=5)
        df = pd.DataFrame({'Cycles': [item[1] for item in rf_raw][1:], 
                           'Temp': [item[0] for item in rf_raw][1:]})

        # 5. Stress Scaling (Original formula)
        df['Stress ranges'] = df['Temp'] * (stress_ref / 200) * T_effect
        stress_ranges = asarray(df['Stress ranges']) * K
        
        # 6. Cycles to Failure (Original Root Solver)
        df['N_r'] = compute_cycles_to_failure(stress_ranges, weld_params)
        
        # 7. Apply Corrosion (Fen)
        Fen = fen_carbon_steel(parameters['T'], parameters['eps_rate'], parameters['DO'], parameters['S'])
        if parameters['CorrosionOn']:
            df['N_r'] = df['N_r'] / Fen

        # 8. Miner's Sum
        df['Damage'] = df['Cycles'] / df['N_r']
        total_damage = nansum(df['Damage'])

        # 9. Format Outputs
        outputs['TotalDamage'] = [float(total_damage)]
        outputs['Timestamp'] = [float(inputs['TagTimestamps'][-1])]

    except Exception as e:
        log_obj.log_error(f"Logic Error: {str(e)}")
        error_code = ces.CalculationErrorState.CALCFAILED.value
        outputs = {'TotalDamage':[0.0], 'Timestamp':[float(inputs['TagTimestamps'][-1])]}

    return [outputs, error_code]