## @package indicators
#  @brief This module provides functions for calculating various indicators for time-series data.
#
#  The `indicators` module includes functions for calculating basic indicators like mean, max, min, sum, std,
#  as well as more complex indicators like peak hour and nth hour. These functions are designed to work with
#  filtered dataframes and can be applied vectorially using map(fcn, series_cs.values()).
#
#  **Main functionalities:**
#  - **Basic Indicators:**
#    - `calculate_mean()`: Calculates the mean value of a time-series.
#    - `calculate_tv()`: Calculates the sum value of a time-series.
#  - **Complex Indicators:**
#    - `calculate_peak_hour()`: Identifies the hour with the maximum value.
#    - `calculate_nth_hour()`: Identifies the hour with the nth highest value.
#    - `calculate_peak_period()`: Identifies the period with the highest sum.
#
#  @author MaS, based on Matlab Clustertool, supported by GPT
#  @date 2025
#
#  @note The module is designed to work with pandas DataFrames and Series.

import pandas as pd
import numpy as np
import logging

## @brief Calculates the mean value of a time-series.
#
#  This function calculates the mean value of a time-series along the specified axis.
#
#  @param data The input time-series data (DataFrame or Series).
#  @param axis The axis along which to calculate the mean (0 for columns, 1 for rows).
#  @return The mean value(s) of the time-series.
def calculate_mean(data, list_col: list=None):
    """
    Calculate the mean value of a time-series.

    Parameters:
    -----------
    data : pandas.DataFrame or pandas.Series
        The input time-series data.
    axis : int, optional
        The axis along which to calculate the mean (0 for columns, 1 for rows).
        Default is 1 (rows).

    Returns:
    --------
    pandas.Series or float
        The mean value(s) of the time-series.
    """

    if list_col is not None:
        series_agg = data.loc[:, list_col].mean(axis=1)
    else:
        series_agg = data.mean(axis=1)

    return series_agg.to_frame(name="avg")


## @brief Identifies the hour with the maximum value in a time-series.
#
#  This function identifies the hour (column) with the maximum value for each row in a time-series.
#  It can calculate peak hours for different periods (day, morning, evening) and can handle both
#  global and local calculations.
#
#  @param data The input time-series data (DataFrame).
#  @param period The period to consider ('day', 'am', 'pm'). Default is 'day' (all hours).
#  @param is_local Whether to perform local calculation. Default is False (global calculation).
#  @param indices_list For local calculations, a list of indices for each count station. Default is None.
#  @return A Series containing the hour with the maximum value for each row.
def identify_peak_hour(data, list_columns=None,period='day', is_locale=True, return_q_max=True,
                          n_intervals: int=24):
    """
    Identify the hour with the maximum value in a time-series.

    Parameters:
    -----------
    data : pandas.DataFrame
        The input time-series data.
    period : str, optional
        The period to consider ('day', 'am', 'pm'). Default is 'day' (all hours).
    is_local : bool, optional
        Whether to perform local calculation. Default is False (global calculation).
    indices_list : list, optional
        For local calculations, a list of indices for each count station. Default is None.
    morning_hours : list, optional
        A list of column names or indices representing morning hours. Default is None.
    evening_hours : list, optional
        A list of column names or indices representing evening hours. Default is None.

    Returns:
    --------
    pandas.Series or dict
        A Series containing the hour (column) with the maximum value for each row,
        or a dictionary of Series for local calculations.
    """
    # Filter data based on the specified period
    filtered_data = data.copy()

    # Handle local vs. global calculation
    if is_locale:
        if list_columns is not None:
            filtered_data = filtered_data.loc[:, list_columns]
            # Spaltenname = Index
            filtered_data.columns = [ k % n_intervals for k, col in enumerate(filtered_data.columns)]

        if period == 'am':
            end_period = np.ceil(n_intervals/2).astype(int)
            # Morning peak hour (AM)
            filtered_data = filtered_data.iloc[:, 0:end_period]

        elif period == 'pm':
            start_period = np.floor(n_intervals/2).astype(int)
            # Afternoon peak hour
            filtered_data = filtered_data.iloc[:, start_period:]

        # Handle rows with all NA values to prevent FutureWarning
        # First check if there are any rows with all NAs
        all_na_rows = filtered_data.isna().all(axis=1)

        # For rows that are not all NAs, use idxmax with skipna=True
        series_agg = pd.Series(index=filtered_data.index)
        series_agg.loc[~all_na_rows] = filtered_data.loc[~all_na_rows].idxmax(axis=1, skipna=True)

        # For rows that are all NAs, set to NA explicitly
        series_agg.loc[all_na_rows] = pd.NA
    else:
        if list_columns is not None:
            logging.warning("Spaltenfilter wird bei globaler Option ignoriert")

        # Spaltenname = Index
        filtered_data.columns = [k % n_intervals for k, col in enumerate(filtered_data.columns)]

        if period == 'am':
            end_period = np.ceil(n_intervals/2).astype(int)
            list_columns = list(range(0, end_period))
            filtered_data = filtered_data.loc[:, list_columns] # Achtung: Reihenfolge geht verloren, wegen Summe aber egal

        elif period == 'pm':
            start_period = np.floor(n_intervals/2).astype(int)
            list_columns = list(range(start_period, n_intervals))
            filtered_data = filtered_data.loc[:,
                            list_columns]  # Achtung: Reihenfolge geht verloren, wegen Summe aber egal

        filtered_data = filtered_data.stack()

        filtered_data = filtered_data.groupby(level=[0,1]).sum().unstack()
        series_agg = filtered_data.idxmax(axis=1, skipna=True)

    df_agg = series_agg.to_frame(name="sp")

    if return_q_max:
        # For rows that are not all NAs, get the max value with skipna=True
        # For rows that are all NAs, the max will be NaN
        df_agg['q_max'] = filtered_data.max(axis=1, skipna=True)

    return df_agg


## @brief Identifies the hour with the nth highest value in a time-series.
#
#  This function identifies the hour (column) with the nth highest value for each row in a time-series.
#
#  @param data The input time-series data (DataFrame).
#  @param n The rank of the value to find (1 for highest, 2 for second highest, etc.).
#  @return A Series containing the hour with the nth highest value for each row.
def q_nth_hour(data, n=50 , col_value: str="value", col_n: str="n"):
    """
    Identify the hour with the nth highest value in a time-series.

    Parameters:
    -----------
    data : pandas.DataFrame
        The input time-series data.
    n : int, optional
        The rank of the value to find (1 for highest, 2 for second highest, etc.).
        Default is 1 (highest).

    Returns:
    --------
    pandas.Series
        A Series containing the hour (column) with the nth highest value for each row.
    """
    if n < 1:
        raise ValueError("n must be a positive integer")

    if len(data) < n:
        return 0

    if col_n in data.columns:
        return data.loc[data[col_n] == n, "value"].values[0]
    else:
        data.sort_values(by=col_value, ascending=False, inplace=True)
        return data[col_value].iloc[n-1].values[0]


def q_percentile(data, q=0.994, col_value: str="value"):
    """
    Identify the value & hour of the p percentile in a time-series.

    Parameters:
    -----------
    data : pandas.DataFrame
        The input time-series data.
    n : int, optional
        The rank of the value to find (1 for highest, 2 for second highest, etc.).
        Default is 1 (highest).

    Returns:
    --------
    pandas.Series
        A Series containing the hour (column) with the nth highest value for each row.
    """
    if q > 1:
        # Interpretation als Perzentil anstatt Quantil
        q = q / 100

    return data[col_value].quantile(q)







## @brief Calculates the total volume (TV) of a time-series.
#
#  This function calculates the total volume (sum) of a time-series.
#  It is an alias for calculate_sum.
#
#  @param data The input time-series data (DataFrame or Series).

#  @return The total volume of the time-series.
def calculate_tv(data, indices_list=None, n_intervals: int=24):
    """
    Calculate the total volume (TV) of a time-series.

    Parameters:
    -----------
    data : pandas.DataFrame or pandas.Series
        The input time-series data.


    Returns:
    --------
    pandas.Series or float
        The total volume of the time-series.
    """

    if indices_list is not None:
        filtered_data = data.loc[:, indices_list]
    else:
        filtered_data = data

    df_sum = filtered_data.sum(axis=1, min_count=1).to_frame(name="TV")

    n_cs = len(filtered_data.columns) / n_intervals

    if n_cs % 1 != 0:
        logging.warning("sth is wrong, n_cs must be a multiple of n_intervals")

    return df_sum / n_cs
