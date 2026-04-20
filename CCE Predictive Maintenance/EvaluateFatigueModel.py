import pandas as pd
import numpy as np
from numpy import asarray, exp, log, log10, nan, nansum, zeros, isfinite
from rainflow import count_cycles
from scipy.optimize import root_scalar
import CCEUtils.common.cce_logger as cce_logger
import CCEUtils.common.calculation_error_state as ces

# --- Constants (Keep exactly as your original) ---
bs7608_data = {
    'C':  {'C_0': 1.08e14, 'Log10C_0': 14.03423, 'm': 3.5},
    'D':  {'C_0': 3.99e12, 'Log10C_0': 12.60076, 'm': 3.0, 'C_2': 1.52e12},
    'B':  {'C_0': 2.34e15, 'Log10C_0': 15.36977, 'm': 4.0, 'C_2': 1.01e15},
    'E':  {'C_0': 3.29e12, 'Log10C_0': 12.51706, 'm': 3.0, 'C_2': 1.04e12},
    'F':  {'C_0': 1.73e12, 'Log10C_0': 12.23704, 'm': 3.0, 'C_2': 6.33e11},
    'F2': {'C_0': 1.23e12, 'Log10C_0': 12.09026, 'm': 3.0, 'C_2': 4.32e11},
    'G':  {'C_0': 5.66e11, 'Log10C_0': 11.75251, 'm': 3.0, 'C_2': 2.50e11},
    'W1': {'C_0': 2.50e11, 'Log10C_0': 11.39794, 'm': 3.0, 'C_2': 9.33e10},
}

weld_params = {
    'k': 1192, 'n': 0.17, 'E': 188e3, 
    'sigf': (bs7608_data['C']['C_0']**(1/bs7608_data['C']['m'])) / 1.6, 
    'b': -0.333, 'epsf': 0.13, 'C': -0.43
}

# --- Core Math Functions ---
def fen_carbon_steel(T, eps_rate, DO, S):
    S_ = 2 + 98 * S if S <= 0.015 else 3.47
    T_ = 0.395 if T < 150 else (T-75)/190
    O_ = 1.49 if DO < 0.04 else (log(max(DO, 0.0001)/0.009) if DO < 0.5 else 4.02)
    rate_limit = 0.0004
    eps_rate_ = 0 if eps_rate > 2.2 else (log(eps_rate/2.2) if eps_rate > rate_limit else log(rate_limit/2.2))
    return exp((0.003 - 0.031 * eps_rate_) * S_ * T_ * O_)

def compute_cycles_to_failure(stress_ranges, params):
    cycles = zeros(len(stress_ranges))
    def eq(N, strain_amp):
        return (params['sigf']/params['E']*(2*N)**params['b'] + params['epsf']*(2*N)**params['C'] - strain_amp)
    for i, stress in enumerate(stress_ranges):
        strain_amp = (stress/2)/params['E'] + (stress/2/params['k'])**(1/params['n'])
        try:
            sol = root_scalar(eq, args=(strain_amp,), method='brentq', bracket=[1, 1e12])
            cycles[i] = sol.root if sol.converged else nan
        except: cycles[i] = nan
    return cycles

# --- The Main CCE Function ---
def EvaluateFatigueModel(parameters, inputs):
    outputs = {}
    error_code = ces.CalculationErrorState.GOOD.value
    
    # 1. Setup Logging
    log = cce_logger.CCELogger(parameters['LogName'], parameters['CalculationName'], 
                               parameters['CalculationID'], parameters['LogLevel'])
    
    try:
        log.log_info('Beginning Fatigue Calculation (CCE Mode)')

        # 2. Extract Data from MATLAB inputs
        # MATLAB sends 'inputs' as a dict of lists. Convert to DataFrame.
        df_inputs = pd.DataFrame.from_dict(inputs)
        #temps = df_inputs['Value'].dropna().tolist() # Assumes column name in PI/Matlab is 'Value'
        temps = [t for t in inputs['Tag'] if np.isfinite(t)]

        if len(temps) < 2:
            outputs['TotalDamage'] = [0.0]
            log.log_warning('Insufficient data points')
            return [outputs, error_code]

        # 3. Extract Parameters sent from MATLAB
        w_class    = str(parameters['WeldClass']).strip()
        c_type     = str(int(parameters['CurveType'])) # '0' or '2'
        stress_ref = float(parameters['StressRange'])
        T_env      = float(parameters['T'])
        eps_rate   = float(parameters['eps_rate'])
        DO         = float(parameters['DO'])
        S          = float(parameters['S'])
        corrosion_on = bool(parameters['CorrosionOn'])

        # 4. Perform Rainflow Math
        rf = count_cycles(temps, binsize=5)
        t_ranges = [item[0] for item in rf][1:] 
        counts = [item[1] for item in rf][1:]

        # 5. Stress Scaling
        T_eff = 1 / (1 - 4e-4 * (T_env - 20))
        ratio = stress_ref / 200.0
        
        # K-Factor Logic
        c_mean_val = bs7608_data['C']['C_0']
        m_mean = bs7608_data['C']['m']
        mean_endurance_stress = 10**((log10(c_mean_val) - log10(1e7)) / m_mean)
        
        c_class_key = "C_0" if c_type == "0" else "C_2"
        c_class_val = float(bs7608_data[w_class][c_class_key])
        m_class = bs7608_data[w_class]['m']
        class_endurance_stress = 10**((log10(c_class_val) - log10(1e7)) / m_class)
        
        K = mean_endurance_stress / class_endurance_stress
        actual_stresses = asarray(t_ranges) * ratio * T_eff * K

        # 6. Fatigue Result
        Nr = compute_cycles_to_failure(actual_stresses, weld_params)
        
        if corrosion_on:
            Fen = fen_carbon_steel(T_env, eps_rate, DO, S)
            Nr = Nr / Fen

        total_damage = nansum(asarray(counts) / Nr)

        # 7. Format Output for MATLAB
        outputs['TotalDamage'] = [float(total_damage) if isfinite(total_damage) else 0.0]
        log.log_info(f'Calculation Complete. Damage: {total_damage}')

    except Exception as e:
        log.log_error(f'Calculation Error: {str(e)}')
        error_code = ces.CalculationErrorState.CALCFAILED.value
        outputs['TotalDamage'] = [0.0]

    return [outputs, error_code]