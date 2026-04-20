"""Python port of BPFStatsFcn.m ."""
import scipy.io as sio
import scipy
import datetime as dt
import pandas as pd
import numpy as np

from scipy import stats


def struct_to_dict(struct_or):
    """Convert a struct to dict for MATLAB input."""
    type_ = type(struct_or)
    if type_ is scipy.io.matlab.mio5_params.mat_struct:
        new_dict = {}
        for field in struct_or._fieldnames:
            new_dict[field] = struct_to_dict(struct_or.__getattribute__(field))
        return new_dict
    elif type_ is list or type_ is np.array or type_ is np.ndarray:
        new_list = []
        for item in struct_or:
            new_list.append(struct_to_dict(item))
        return new_list
    else:
        if type(struct_or) is scipy.io.matlab.mio5_params.MatlabFunction:
            return 'NaN'
        return struct_or


def matlab_to_datetime(matlab_datenum):
    """Convert matlab time to python time."""
    if matlab_datenum is None or np.isnan(matlab_datenum):
        return np.nan
    python_datetime = dt.datetime.fromordinal(int(matlab_datenum)) \
        + dt.timedelta(days=matlab_datenum % 1) - dt.timedelta(days=366)
    return python_datetime


def get_or_none(content, *args):
    """Get multiple level arg from dict."""
    current = content
    for arg in args:
        found = False
        if isinstance(current, dict) and arg in current.keys():
            current = current[arg]
            found = True
    if found:
        return current
    else:
        return None


def bpfstats(description, sensor_data, c80=None, p75=None,
             ucl=None, lcl=None, run_rule=0, zero_points=0, inverse=False,
             exclude_data=False, date_as_matlab=False, standard_std=0,
             date_as_js=False):
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
    results = {
        'error': None
    }

    # Check that there is at least one period
    if 'Data' not in sensor_data.keys():
        results['error'] = 'Not enough data to perform BPFStats'
        return results

    # Check that context is available and has 'Type' in context
    if 'Context' in sensor_data.keys() and 'Type' in sensor_data['Context'].keys():
        sensor_type = sensor_data['Context']['Type']
    else:
        sensor_type = None

    num_ts = len(sensor_data['Data'])
    # Convert data to pandas if not pandas
    df_data = []
    df_quality = []
    for i, data in enumerate(sensor_data['Data']):
        value_key = 'Value' if 'Value' in data.keys() else 'value'
        time_key = 'TimeStamp' if 'TimeStamp' in data.keys() else 'timestamp'
        quality_key = 'Quality' if 'Quality' in data.keys() else 'quality'
        values = data[value_key]
        times = data[time_key]
        qualities = data[quality_key]
        if date_as_matlab:
            times = [matlab_to_datetime(t) for t in times]
        if date_as_js:
            times = [dt.datetime.utcfromtimestamp(t/1000) for t in times]
        if i == 0:
            time_step = np.mean([t - times[0] for t in times[1:]]).total_seconds()
            time_range = (times[-1] - times[0]).total_seconds()
        df_data.append(pd.Series(index=times, data=values))
        df_quality.append(pd.Series(index=times, data=qualities))

    if num_ts == 0:
        results['error'] = 'Not enough data to perform BPFStats'
        return results

    # Check sensor context to remove duplicates
    if sensor_type == 'APCDigitalInstrument':
        for series in df_data:
            diff = series.diff()
            series.loc[diff == 0] = np.nan

    # Remove excluded data
    if exclude_data is not False:
        for series in df_data:
            series.loc[series <= exclude_data] = np.nan

    # 30 sample moving average
    # for i, series in enumerate(df_data):
    #     df_data[i] = series.rolling(30, min_periods=1).mean()

    # Calculate missing statistics, only on period 0
    c80s = []
    p75s = []
    uc_ls = []
    lc_ls = []
    est_stds = []
    ref_zero = zero_points
    for i, series in enumerate(df_data):
        if c80 is None:
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

        if p75 is None:
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

            if ucl is None:
                calc_ucl = series.mean() + 3 * est_std
                uc_ls.append(calc_ucl)
            else:
                calc_ucl = None
                uc_ls.append(ucl)

            if lcl is None:
                calc_lcl = series.mean() - 3 * est_std
                lc_ls.append(calc_lcl)
            else:
                calc_lcl = None
                lc_ls.append(lcl)

            est_stds.append(est_std)

        else:
            results['error'] = 'Non adjusted dataset not supported yet'
            return results

    trend_low = get_or_none(sensor_data, 'Context', 'Parameters', 'TrendLow')
    trend_high = get_or_none(sensor_data, 'Context', 'Parameters', 'TrendHigh')
    sensor_low = get_or_none(sensor_data, 'Context', 'Parameters', 'Low')
    sensor_high = get_or_none(sensor_data, 'Context', 'Parameters', 'High')

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

    results['yLim'] = [y_low, y_high]

    # Implement OOC rules
    results['plot_data'] = []
    # 7 or more points in a row increasing (White face) or decreasing (Red face)
    for i, series in enumerate(df_data):
        rdata = {}
        rstats = {}
        plot_data = {}
        increasing = (series.diff() > 0).rolling(window=7, min_periods=1).sum()
        decreasing = (series.diff() < 0).rolling(window=7, min_periods=1).sum()

        # 7 or more points on the same side of the mean (W->pos, R->neg)
        above_mean = (series > series.mean()).rolling(window=7, min_periods=1).sum()
        below_mean = (series < series.mean()).rolling(window=7, min_periods=1).sum()

        # 1 point more than 3 STD from the mean all red
        out_of_bounds = (series > 3 * est_stds[i]) | (series < -3 * est_stds[i])

        rdata['red_marker'] = [int(b) for b in ((increasing == 7) | (above_mean == 7) | out_of_bounds).values]
        rdata['white_marker'] = [int(b) for b in ((decreasing == 7) | (below_mean == 7)).values]
        rdata['timestamp'] = [int(si.strftime("%s%f"))/1000 for si in series.index]
        rdata['value'] = list(series.values)
        rdata['qualities'] = list(df_quality[i][series.index].values)
        rstats['UCL'] = uc_ls[i]
        rstats['LCL'] = lc_ls[i]
        rstats['estStdev'] = est_stds[i]
        rstats['Mean'] = series.mean()
        rstats['C80'] = c80s[i]
        rstats['P75'] = p75s[i]

        # good_fraction = (sum(rdata['Qualities']==0) + sum(rdata['Qualities'] == 'Good')) / len(rdata['Qualities'])
        good_fraction = sum([1 for q in rdata['qualities'] if q == 0 or 1 == 'Good']) / len(rdata['qualities'])
        rstats['validation'] = {'Good [%]': good_fraction * 100}
        plot_data['Inverse'] = inverse
        plot_data['yLim'] = [y_low, y_high]
        # plot_data['name'] = sensor_data['Data'][i]['Label']

        plot_data['data'] = rdata
        plot_data['stats'] = rstats
        results['plot_data'].append(plot_data)

    # results['pandas_data'] = df_data
    return results


def convert_bpfstats_for_plotly(bpf_results):
    """Convert bpfstats output to plotly shape."""
    results = {}
    results['boxPlot'] = {
        'timeRanges': [
            {'data': bs['data']['value']} for bs in bpf_results['plot_data']
        ]
    }
    results['resultTable'] = {
        'timeRanges': [
            {'data': {'value': bs['stats']}} for bs in bpf_results['plot_data']
        ]
    }
    results['timeSeries'] = {
        'timeRanges': [
            {'data': bs['data'], 'stats': bs['stats']} for bs in bpf_results['plot_data']
        ]
    }
    return results


if __name__ == '__main__':
    input_data = sio.loadmat('../../tests/BPFstatsFcn_input.mat', struct_as_record=False, squeeze_me=True,
                             mat_dtype=True)
    sensor_data = struct_to_dict(input_data['varargin'][1])
    result = bpfstats('Test', sensor_data, date_as_matlab=True, zero_points=0.005479452054794521)
    result = convert_bpfstats_for_plotly(result)
    print(result)
