# -*- coding: utf-8 -*-
"""
CCE Version of BPFstatsFcn
"""

# import scipy.io as sio
# import scipy
import datetime as dt
import pandas as pd
import numpy as np
import cce_logger
import calculation_error_state as ces


from scipy import stats

def matlab_to_datetime(matlab_datenum):
    """Convert matlab time to python time."""
    if matlab_datenum is None or np.isnan(matlab_datenum):
        return np.nan
    python_datetime = dt.datetime.fromordinal(int(matlab_datenum)) \
        + dt.timedelta(days=matlab_datenum % 1) - dt.timedelta(days=366)
    return python_datetime

def bpf_stats(parameters, inputs):
    """Perform bpfstats.

    sensor data: dict Fields required structure
        {
            'Data': [
                {'Label': str, 'Timestamp': [values], 'Value': [values], 'Quality': [values]
            ], # element for each period
            'Context': {
                'Name': str,
                'Type': str,
                'Parameters': {
                    'TrendLow': float,
                    'TrendHigh': float,
                    'Low': float,
                    'High': float
                }
            }
        }
    C80: int Overwrite calculated value
    P75: int 75 percentile Overwrite calculated value
    UCL: int Upper control limit. Overwrite calculated value
    LCL: int Lower control limit. Overwrite calculated value
    RunRule: float Value above which assumed to be running
    ZeroPoints: float (unsure) reference expected zero time
    Inverse: bool Switch C80 to C20 and P75 to P25
    ExcludeData: float Exclude data with value under this value
    date_as_matlab: bool Input date format
    standardSTD: int Whether to use standard STD calculations or custom
    """
    log_file = parameters['LogName']
    calculation_id = parameters['CalculationID']
    log_level = parameters['LogLevel']
    calculation_name = parameters['CalculationName']
    log = cce_logger.CCELogger(log_file, calculation_name, calculation_id, log_level)
    error_code = ces.CalculationErrorState.GOOD.value
    
    try:
        # Check that there is at least one period
        output = {}
        num_ts = len(inputs['InputSensor'])
        if num_ts == 0:
            error_code = ces.CalculationErrorState.NODATA.value
            raise Exception('Not enough data to perform BPFStats')
            
        values = inputs['InputSensor'] 
        times = inputs['InputSensorTimestamps'] 
        qualities = inputs['InputSensorQuality']
        c80 = parameters['InputSensorC80']
        p75 = parameters['InputSensorP75']
        ucl = parameters['InputSensorUCL']
        lcl = parameters['InputSensorLCL']
        run_rule = parameters['RunRule']
        zero_points = parameters['ZeroPoints']
        inverse = parameters['Inverse']
        exclude_data = parameters['ExcludeData']
        date_as_matlab = parameters['DateAsMatlab']
        standard_std = parameters['StandardStd']
        date_as_js = parameters['DateAsJS']
        sensor_type = parameters['InputSensorSensorType']
        trend_high = parameters['InputSensorTrendHigh']
        trend_low = parameters['InputSensorTrendLow']
        sensor_high = parameters['InputSensorSensorHigh']
        sensor_low = parameters['InputSensorSensorLow']
        start_time = times[0]
        end_time = times[-1]
            
        # Convert data to pandas if not pandas
        df_data = []
        df_quality = []
    
        if date_as_matlab:
            times = [matlab_to_datetime(t) for t in times]
        if date_as_js:
            times = [dt.datetime.utcfromtimestamp(t/1000) for t in times]
        
        time_step = np.mean([t - times[0] for t in times[1:]]).total_seconds()
        time_range = (times[-1] - times[0]).total_seconds()
        df_data.append(pd.Series(index=times, data=values))
        df_quality.append(pd.Series(index=times, data=qualities))
         
        # Check sensor context to remove duplicates
        if sensor_type == 'APCDigitalInstrument':
            for series in df_data:
                diff = series.diff()
                series.loc[diff == 0] = np.nan
    
        # Remove excluded data
        if exclude_data is not False:
            for series in df_data:
                series.loc[series <= exclude_data] = np.nan
        
        # Calculate missing statistics, only on period 0
        c80s = []
        p75s = []
        uc_ls = []
        lc_ls = []
        est_stds = []
        ref_zero = zero_points
        for i, series in enumerate(df_data):
            if np.isnan(c80):
                c80mean = series.loc[series > run_rule].mean()
                c80min = series.loc[series > run_rule].min()
                c80std = (c80mean - c80min) / 3
    
                current_zero = ref_zero * np.round(time_range / 60 / 60 / 24)
                nan_sum = series.loc[series > run_rule].sum()
                if current_zero < series.loc[series < run_rule].sum():
                    current_zero = series.loc[series < run_rule].sum()
    
                year_step = np.sqrt(np.round(365 * 24 * 60 * 60 / time_step))
                if not inverse:
                    current_c80 = (c80mean - c80std / year_step) * nan_sum / (nan_sum + current_zero)
                else:
                    current_c80 = (c80mean - c80std / year_step) * (nan_sum + current_zero) / (nan_sum)
                c80s.append(current_c80)
            else:
                c80s.append(c80)
    
            if np.isnan(p75):
                current_p75 = np.percentile(series, 75) if not inverse else np.percentile(series, 25)
                p75s.append(current_p75)
    
            # Test if normal distribution
            data_constant = np.abs(series.min()) if series.min() < 0 else 0
            test_data = series.values + data_constant
    
            # We are using a old scipy, this line will work with a newer version
            # rejected = stats.jarque_bera(testData).pvalue < 0.05
            test_results = stats.jarque_bera(test_data)
            rejected = test_results[1] < 0.05
    
            distribution = 'Normal' if not rejected else 'Non-normal'
    
            # TODO LOGIC NEEDED TO NORMALISE DATA FOR ADJUSTED DATA SET
    
            if distribution != 'adjusted':
                if standard_std == 0:
                    est_std = np.nansum(np.abs(series.diff())) / np.nansum(~np.isnan(np.abs(series.diff()))) / 1.128
                else:
                    est_std = series.std()
    
                if np.isnan(ucl):
                    calc_ucl = series.mean() + 3 * est_std
                    uc_ls.append(calc_ucl)
                else:
                    calc_ucl = None
                    uc_ls.append(ucl)
    
                if np.isnan(lcl):
                    calc_lcl = series.mean() - 3 * est_std
                    lc_ls.append(calc_lcl)
                else:
                    calc_lcl = None
                    lc_ls.append(lcl)
    
                est_stds.append(est_std)
    
            else:
                error_code = ces.CalculationErrorState.BADINPUT.value
                raise Exception('Non adjusted dataset not supported yet')
                
    
        y_low = trend_low or sensor_low or np.nan
        y_high = trend_high or sensor_high or np.nan
    
        if np.isnan(y_low) or np.isnan(y_high):
            all_data = pd.concat([s for s in df_data])
            y_low, y_high = all_data.min(), all_data.max()
        y_low = np.nanmin([y_low]+lc_ls)
        y_high = np.nanmax([y_high]+uc_ls)
    
        y_range = y_high - y_low
        y_low -= 0.025 * y_range
        y_high += 0.025 * y_range
        
        output['UCL'] = [uc_ls[i],uc_ls[i]]
        output['LCL'] = [lc_ls[i], lc_ls[i]]
        output['EstStdev'] = [est_stds[i], est_stds[i]]
        output['Mean'] = [series.mean(), series.mean()]
        output['C80'] = [c80s[i], c80s[i]]
        output['P75'] = [p75s[i],p75s[i]]
        output['Timestamp'] = [start_time, end_time]
        
        log.log_info('[%.2f, %.2f, %.2f, %.2f, %.2f, %.2f]' %(output['UCL'][0], output['LCL'][0], output['EstStdev'][0],  output['Mean'][0], output['C80'][0], output['P75'][0]))
        
    except Exception as e:
        output['UCL'] = []
        output['LCL'] = []
        output['EstStdev'] = []
        output['Mean'] = []
        output['C80'] = []
        output['P75'] = []
        output['Timestamp'] = []
        log.log_error(str(e))
        if error_code == ces.CalculationErrorState.GOOD.value or (isinstance(error_code, list) and len(error_code) == 0):
            error_code = ces.CalculationErrorState.CALCFAILED.value
    
    return [output, error_code]
