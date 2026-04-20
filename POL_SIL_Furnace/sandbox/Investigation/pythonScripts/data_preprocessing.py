import pandas as pd

def remove_threshold_outliers(df, tags, threshold, fill_method='ffill'):
    """
    Set values in the given tags/columns of the DataFrame to NA if they are >= threshold.
    Then fill missing values using the previous value.
    
    :param df: Input DataFrame
    :param tags: List of columns/tags to process
    :param threshold: Value above which entries are set to NA.
    :param fill_method: Method used for filling NaN values. Default is 'ffill' (forward fill).
                        Other common methods include 'bfill' (backward fill).
    :return: Modified DataFrame
    """
    for tag in tags:
        if tag in df.columns:
            df.loc[df[tag] >= threshold, tag] = pd.NA
            df[tag] = df[tag].fillna(method=fill_method)
    return df


