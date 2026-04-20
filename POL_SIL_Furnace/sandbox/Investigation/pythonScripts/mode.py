import pandas as pd

def create_mode_proxy(df):
    """
    Creates a proxy signal to determine the mode of the furnace.
    Detailed explanation goes here.

    :param df: Input DataFrame
    :return: DataFrame with an additional 'mode' column
    """

    # Define thresholds
    normal_threshold = 68
    off_threshold = 0.1
    time_threshold = 5  # minutes
    lost_cap_threshold = 66

    # Define the category order
    category_order = ['Off', 'Lost Capacity', 'Ramp', 'Normal']

    # Initialize mode column
    df['mode'] = pd.Categorical([""] * len(df), categories=category_order, ordered=True)
    df.loc[df['Furnace Power SP'] >= normal_threshold, 'mode'] = "Normal"
    df.loc[df['Total Electrode Power'] < off_threshold, 'mode'] = "Off"

    for i in range(0, len(df)):
        prev_mode = df['mode'].iloc[i-1]
        curr_mode = df['mode'].iloc[i]
        
        if (prev_mode == "Off" or prev_mode == "Ramp") and curr_mode not in ["Normal", "Off"]:
            df.at[i, 'mode'] = "Ramp"

    df.loc[(df['Furnace Power SP'] < normal_threshold) & (df['mode'] != "Ramp") & (df['mode'] != "Off"), 'mode'] = "Lost Capacity"

    for i in range(0,len(df)):
        if i >= time_threshold:
            time_window = df['Furnace Power SP'].iloc[i-time_threshold+1:i+1]

            if df['Furnace Power SP'].iloc[i] < normal_threshold and df['Furnace Power SP'].iloc[i] >= lost_cap_threshold:
                if df['Furnace Power SP'].iloc[i-time_threshold] >= normal_threshold and all(time_window < normal_threshold):
                    df['mode'].iloc[i-time_threshold+1:i+1] = "Lost Capacity"
                elif df['mode'].iloc[i-time_threshold] >= "Lost Capacity" and all(time_window < normal_threshold):
                    df['mode'].iloc[i] = "Lost Capacity"
                else:
                    df.at[i, 'mode'] = "Normal"
    return df
