## @package data_handler
#  @brief This module provides functions for loading, processing, and saving time-series clustering data.
#
#  The `data_handler` module includes utility functions for handling different file formats
#  (CSV, Excel, MATLAB `.mat`) and preprocessing time-series data. It also provides functions
#  to save and load clustering results in JSON, CSV, and Excel formats.
#
#  **Main functionalities:**
#  - **Data Loading:**
#    - `load_csv()`: Loads time-series data from a CSV file.
#    - `load_excel()`: Loads time-series data from an Excel file.
#    - `load_mat()`: Loads time-series data from a MATLAB `.mat` file.
#  - **Data Processing:**
#    - `convert_series_to_daily_df()`: Converts a time-series to a daily aggregated DataFrame.
#    - `unpack_nested_lists()`: Unpacks nested lists or arrays in a DataFrame.
#    - `datenum_to_datetime()`: Converts MATLAB datenum values to pandas datetime objects.
#  - **Clustering Data Management:**
#    - `save_clusterung_to_json()`, `load_clusterung_from_json()`: Save and load clustering results in JSON format.
#    - `save_clusterung_to_csv()`, `save_clusterung_to_excel()`: Save clustering results to CSV and Excel.
#  - **Calendar Attributes Handling:**
#    - `calendar_to_dict_json()`: Converts `CalendarAttributes` to JSON-compatible format.
#    - `convert_dates()`: Converts date strings in a dictionary to `datetime.date` objects.
#
#  @author MaS, GPT
#  @date 2025
#
#  @note The module is designed to work with the `Clusterung` and `CalendarAttributes` classes.
import logging

import pandas as pd
import numpy as np
import scipy.io
from modules.clustering import Clusterung
from modules.calendar_attributes import CalendarAttributes
from pathlib import Path
import json


## @brief Loads data from a CSV file.
#  @param file_path Path to the CSV file.
#  @return A Pandas DataFrame containing the loaded data.
def load_csv(file_path):
    # Lade die erste Zeile als DataFrame, um die Werte zu analysieren
    first_row = pd.read_csv(file_path, nrows=1, header=None, delimiter=",")

    # Trennzeichen prüfen (= DE oder EN Formatierung)
    if len(first_row.columns) == 1:
        delimiter = ";"
        decimalsep = ","
        first_row = pd.read_csv(file_path, nrows=1, header=None, delimiter=delimiter, decimal=decimalsep)
    else:
        delimiter = ","
        decimalsep = "."

    # Prüfen, ob die erste Zeile Text enthält
    contains_text = first_row.map(lambda x: isinstance(x, str) and any(c.isalpha() for c in str(x))).any().any()

    # Prüfen, ob die erste Zeile nur aus Zahlen & NaN besteht
    contains_only_numbers_or_nan = first_row.map(lambda x: pd.isna(x) or str(x).replace(".", "").isdigit()).all().all()

    # Entscheiden, ob die erste Zeile ein Header ist
    if contains_text:
        header_option = 0  # Header vorhanden
    elif contains_only_numbers_or_nan:
        header_option = None  # Keine Header-Zeile
    else:
        header_option = 0  # Default: Header annehmen

    # CSV mit der erkannten Header-Option einlesen
    df = pd.read_csv(file_path, index_col=0, parse_dates=True, header=header_option,
                     delimiter=delimiter, decimal=decimalsep)

    df.index = convert_to_datetime(df.index)

    return df


## @brief Loads data from an Excel file.
#  @param file_path Path to the Excel file.
#  @param sheet Optional; Sheet name to load. If None, the first sheet is used.
#  @return A Pandas DataFrame containing the loaded data.
def load_excel(file_path, sheet=None):
    excel_file = pd.ExcelFile(file_path)
    if sheet is None or sheet not in excel_file.sheet_names:
        sheet = excel_file.sheet_names[0]

    # Lade die erste Zeile als DataFrame, um die Werte zu analysieren
    first_row = pd.read_excel(file_path, nrows=1, header=None, index_col=0)
    # Prüfen, ob die erste Zeile Text enthält
    contains_text = first_row.map(lambda x: isinstance(x, str) and any(c.isalpha() for c in str(x))).any().any()

    if first_row.index[0]== ""  or contains_text:
        df = pd.read_excel(file_path, index_col=0, parse_dates=False, sheet_name=sheet)
    else:
        df = pd.read_excel(file_path, index_col=0, parse_dates=False, sheet_name=sheet, header=None)

    df.index = convert_to_datetime(df.index)

    return df



## @brief Loads data from a `.mat` file (MATLAB format).
#  @param file_path Path to the `.mat` file.
#  @return A Pandas DataFrame with loaded data, using the first column as an index.
def load_mat(file_path):
    mat = scipy.io.loadmat(file_path)
    keys = [key for key in mat.keys() if not key.startswith("__")]

    if len(keys) == 1:
        data = mat[keys[0]]
        df = pd.DataFrame(data)
        df = unpack_nested_lists(df)
        df.set_index(df.columns[0], inplace=True)

        df.index = convert_to_datetime(df.index)

        return df
    else:
        raise ValueError(f"Multiple variables found in {file_path}: {keys}. Please specify.")

def convert_to_datetime(idx_df):

    # Convert first column if it is a MATLAB/Excel datenum
    if np.issubdtype(idx_df.dtype, np.floating) or np.issubdtype(idx_df.dtype, np.integer):
        try:
            new_index = datenum_to_datetime(idx_df)
        except Exception as e:
            print(f"Error converting datenum: {e}")
            new_index = idx_df
    elif isinstance(idx_df[0], str):
        # Versuche mehrere Datumsformate
        date_formats = ["%d.%m.%Y", 'ISO8601'] # ISO08601 deckt alle Kombinationen YYYY-mm-dd HH:MM:SS ab
        for fmt in date_formats:
            try:
                new_index = pd.to_datetime(idx_df, format=fmt)
                break  # Beende die Schleife, wenn die Konvertierung erfolgreich war
            except ValueError:
                continue  # Versuche das nächste Format
        else:
            logging.warning("Format datum nicht erkannt")
            new_index = pd.to_datetime(idx_df, errors="ignore") # Rückfallebene, falls Format nicht erkannt
    else:
        new_index = idx_df
        logging.warning("Keine Umwandlung Format Datum")

    return new_index





## @brief Unpacks nested lists or arrays inside a DataFrame.
#  @param df Pandas DataFrame with possible nested lists or arrays.
#  @return DataFrame with unpacked values.
def unpack_nested_lists(df):
    while df.map(lambda x: isinstance(x, (list, np.ndarray))).any().any():
        df = df.map(lambda x: x[0] if isinstance(x, (list, np.ndarray)) and len(x) > 0 else x)
    return df


## @brief Converts MATLAB datenum values to pandas datetime objects.
#  @param datenum_array Numpy array containing MATLAB datenum values.
#  @return Pandas Series of datetime objects.
def datenum_to_datetime(datenum_array):
    # MATLAB 'datenum' uses 1 for 0000-01-01 and pd.to_datetime uses 'unix' epoch of 1970-01-01.
    # Therefore, compute the difference in days between the two epochs.
    MATLAB_to_Unix_days = 719529

    # Excel Date (30.12.1899)
    Excel_to_Unix_days = 25569

    # MATLAB-Daten erkennen (sehr große Werte, z. B. ~7xxxxx)
    is_matlab = datenum_array.min() > 700000

    # Excel-Daten erkennen (realistische Werte > 40000, aber kleiner als MATLAB)
    is_excel = (datenum_array.min() > 10000) & (datenum_array.min() < 700000)

    if is_matlab:
        # Convert the MATLAB datenum to seconds since the Unix epoch.
        unix_epoch_seconds = np.round((datenum_array - MATLAB_to_Unix_days) * 86400).astype(int)  # 86400 seconds per day
    elif is_excel:
        # Convert the Excel datenum to seconds since the Unix epoch.
        unix_epoch_seconds = np.round((datenum_array - Excel_to_Unix_days) * 86400).astype(int)
    else:
        logging.warning("Fall ist nicht implementiert")
        unix_epoch_seconds = np.round((datenum_array) * 86400).astype(int)

    # Use pandas to convert these seconds into datetime objects.
    return pd.to_datetime(unix_epoch_seconds, unit='s', origin='unix')


## @brief Converts a Pandas Series with a datetime index to a daily aggregated DataFrame.
#  @param series Pandas Series with a datetime index.
#  @return Pandas DataFrame aggregated by day.
def convert_series_to_daily_df(series):
    series = series.squeeze()
    if not isinstance(series, pd.Series):
        raise TypeError("Input must be a Pandas Series.")
    df_daily = series.resample('D').sum().to_frame()
    df_daily.index = df_daily.index.date
    return df_daily


# @brief Flattens a netsed array
def flatten_array(arr):
    return [x.item() if isinstance(x, np.ndarray) else x for x in arr.flatten()]

## @brief Loads and preprocesses data from various file formats.
#  @param file_path Path to the data file.
#  @param sheet Optional; Sheet name for Excel files.
#  @return Pandas DataFrame with processed data.
def load_and_prepare_data(file_path, sheet=None):
    if file_path.suffix == ".csv":
        df = load_csv(file_path)
    elif file_path.suffix in [".xlsx", ".xls", ".xlm", ".xlsm"]:
        df = load_excel(file_path, sheet)
    elif file_path.suffix == ".mat":
        df = load_mat(file_path)
    else:
        raise ValueError(f"Unsupported file format: {file_path}")

    if isinstance(df, pd.Series) or len(df.columns) < 2:
        df = convert_series_to_daily_df(df)

    return df


## @brief Saves a Clusterung instance as a JSON file.
#  @param cluster_obj The Clusterung object to save.
#  @param filepath Path to save the JSON file.
def save_clusterung_to_json(cluster_obj, filepath):
    if not isinstance(cluster_obj, Clusterung):
        raise TypeError("Provided object is not an instance of Clusterung.")

    data = {
        "method": cluster_obj.method,
        "distance_function": cluster_obj.distance_function,
        "max_clusters": cluster_obj.max_clusters,
        "cutoff": cluster_obj.cutoff,
        "kmeans_iter": cluster_obj.kmeans_iter,
        "kmeans_presettings": cluster_obj.kmeans_presettings,
        "clusters": convert_index_and_keys_to_str(cluster_obj.clusters),
        "distance_matrix": convert_index_and_keys_to_str(cluster_obj.distance_matrix if cluster_obj.distance_matrix is not None else None),
        "properties_dates": convert_index_and_keys_to_str(cluster_obj.properties_dates),
        "representative_series": cluster_obj.representative_series.to_dict() if cluster_obj.representative_series is not None else None,
        "language": cluster_obj.language,
        "calendar": calendar_to_dict_json(cluster_obj.calendar),
        "data": convert_index_and_keys_to_str(cluster_obj.data),
        "cluster_properties": convert_index_and_keys_to_str(cluster_obj.cluster_properties),
    }
    with open(filepath, "w") as f:
        json.dump(data, f, indent=4)


## @brief Loads a Clusterung instance from a JSON file.
#  @param filepath Path to the JSON file.
#  @return A Clusterung object with restored data.
def load_clusterung_from_json(filepath):

    """Lädt eine Clusterung-Instanz aus einer JSON-Datei."""
    with open(filepath, "r") as f:
        data_file = json.load(f)

    clusters = pd.DataFrame.from_dict(data_file["clusters"], orient="index")
    data = pd.DataFrame.from_dict(data_file["data"])
    data_properties = pd.DataFrame.from_dict(data_file["properties_dates"])

    clusters.index = pd.to_datetime(clusters.index)
    data.index = pd.to_datetime(data.index)
    data_properties.index = pd.to_datetime(data_properties.index).date

    calendar_attr = CalendarAttributes(
        list_datetimes=data.index.tolist(),
        language=data_file["calendar"]["language"],
        dummy=True,
        country=data_file["calendar"]["country"],
        state=data_file["calendar"]["state"]
    )

    # Übernehmen der Daten aus dem Lesedatei
    calendar_attr.bank_holidays = convert_dates(data_file["calendar"]["bank_holidays"])
    calendar_attr.school_holidays = convert_dates(data_file["calendar"]["school_holidays"])
    calendar_attr.summertime = convert_dates(data_file["calendar"]["summertime"])
    calendar_attr.season = convert_dates(data_file["calendar"]["season"])
    calendar_attr.weekday = convert_dates(data_file["calendar"]["weekday"])
    calendar_attr.month = convert_dates(data_file["calendar"]["month"])
    calendar_attr.bridging_day = convert_dates(data_file["calendar"]["bridging_day"])
    calendar_attr.workday = convert_dates(data_file["calendar"]["workday"])

    calendar_attr.translate_attributes()

    obj = Clusterung(
        method=data_file["method"],
        distance_function=data_file["distance_function"],
        max_clusters=data_file["max_clusters"],
        cutoff=data_file["cutoff"],
        kmeans_iter=data_file["kmeans_iter"],
        kmeans_preset=data_file["kmeans_presettings"],
        data=data,
        attr_data=data_properties,
        calendar_obj=calendar_attr
    )
    obj.clusters = clusters.squeeze()
    obj.distance_matrix = pd.DataFrame.from_dict(data_file["distance_matrix"]) if data_file[
        "distance_matrix"] else None
    if obj.distance_matrix is not None:
        obj.distance_matrix.index = pd.to_datetime(obj.distance_matrix.index)
        obj.distance_matrix.columns = pd.to_datetime(obj.distance_matrix.columns)
    obj.representative_series = pd.DataFrame.from_dict(data_file["representative_series"]) if data_file[
        "representative_series"] else None
    obj.language = data_file["language"]
    obj._add_calendar_properties()
    obj.cluster_properties = pd.DataFrame.from_dict(data_file["cluster_properties"])
    obj.cluster_properties.index = obj.cluster_properties.index.astype(float).astype(int)
    obj.representative_series.index = obj.representative_series.index.astype(int)
    obj.representative_series.index.name = "cluster"

    return obj


def calendar_to_dict_json(calendar_obj):
    """Transformiert ein CalendarAttributes Objekt in ein Dict, um es als JSON zu speichern."""
    if not isinstance(calendar_obj, CalendarAttributes):
        raise TypeError("Das übergebene Objekt ist keine Instanz von CalendarAttributes.")

    if calendar_obj.language.lower() == "en":
        data = {
            "dates": [str(date) for date in calendar_obj.dates],
            "years": list(calendar_obj.years),
            "bank_holidays": {k: str(v) for k, v in calendar_obj.bank_holidays.items()},
            "school_holidays": {k: [str(date) for date in v] for k, v in calendar_obj.school_holidays.items()},
            "summertime": {k: [str(date) for date in v] for k, v in calendar_obj.summertime.items()},
            "season": {k: [str(date) for date in v] for k, v in calendar_obj.season.items()},
            "weekday": {k: [str(date) for date in v] for k, v in calendar_obj.weekday.items()},
            "month": {k: [str(date) for date in v] for k, v in calendar_obj.month.items()},
            "bridging_day": {k: [str(date) for date in v] for k, v in calendar_obj.bridging_day.items()},
            "workday": {k: [str(date) for date in v] for k, v in calendar_obj.workday.items()},
            "country": calendar_obj.country,
            "state": calendar_obj.state,
            "language": calendar_obj.language
        }
    elif calendar_obj.language.lower() == "de":
        data = {
            "dates": [str(date) for date in calendar_obj.dates],
            "years": list(calendar_obj.years),
            "bank_holidays": {k: [str(date) for date in v] for k, v in calendar_obj.feiertage.items()},
            "school_holidays": {k: [str(date) for date in v] for k, v in calendar_obj.ferien.items()},
            "summertime": {k: [str(date) for date in v] for k, v in calendar_obj.sommerzeit.items()},
            "season": {k: [str(date) for date in v] for k, v in calendar_obj.jahreszeit.items()},
            "weekday": {k: [str(date) for date in v] for k, v in calendar_obj.wochentag.items()},
            "month": {k: [str(date) for date in v] for k, v in calendar_obj.monat.items()},
            "bridging_day": {k: [str(date) for date in v] for k, v in calendar_obj.brueckentag.items()},
            "workday": {k: [str(date) for date in v] for k, v in calendar_obj.werktag.items()},
            "country": calendar_obj.country,
            "state": calendar_obj.state,
            "language": calendar_obj.language
        }
    else:
        data = {}

    return data


## @brief Converts all indices and dictionary keys to strings.
#  @param data_dict A dictionary, DataFrame, or Series to convert.
#  @return Converted dictionary with string indices and keys.
def convert_index_and_keys_to_str(data_dict):
    if isinstance(data_dict, pd.DataFrame):
        data_dict = data_dict.copy()
        data_dict.index = data_dict.index.astype(str)
        data_dict.columns = data_dict.columns.astype(str)
        return data_dict.to_dict()
    elif isinstance(data_dict, pd.Series):
        data_dict = data_dict.copy()
        data_dict.index = data_dict.index.astype(str)
        return data_dict.to_dict()
    else:
        return {str(key): value for key, value in data_dict.items()}


## @brief Loads an HTML file as a string.
#  @param html_file Path to the HTML file.
#  @return The HTML content as a string.
def load_html_file(html_file):
    with open(html_file, 'r', encoding='utf-8') as f:
        return f.read()


## @brief Saves the representative series of a clustering object to a CSV file.
#
#  This function exports only the representative time series of each cluster
#  to a CSV file. The full clustering object, including distance matrices
#  and properties, is not saved.
#
#  @param cluster_obj The clustering object of type `Clusterung`.
#  @param filepath The file path where the CSV should be saved.
#
#  @throws TypeError If `cluster_obj` is not an instance of `Clusterung`.
#  @throws ValueError If `cluster_obj` does not contain representative series.
def save_clusterung_to_csv(cluster_obj, filepath):
    """Speichert nur die repräsentativen Ganglinien der Cluster als CSV."""

    # Ensure that the input object is an instance of `Clusterung`.
    if not isinstance(cluster_obj, Clusterung):
        raise TypeError("Das übergebene Objekt ist keine Instanz von Clusterung.")

    # Ensure that the clustering object contains representative series.
    if cluster_obj.representative_series is None:
        raise ValueError("Es gibt keine repräsentativen Ganglinien zum Speichern.")

    # Save the representative series to a CSV file.
    cluster_obj.representative_series.to_csv(filepath)


## @brief Saves clustering data, properties, and results to an Excel file.
#
#  This function exports multiple components of a clustering object to an
#  Excel file, including:
#  - The original time-series data used for clustering.
#  - Additional properties assigned to each time series.
#  - The cluster assignments for each data point.
#  - The representative series for each cluster.
#  - Cluster-level properties.
#
#  @param cluster_obj The clustering object of type `Clusterung`.
#  @param filepath The file path where the Excel file should be saved.
#
#  @throws TypeError If `cluster_obj` is not an instance of `Clusterung`.
def save_clusterung_to_excel(cluster_obj, filepath):
    """Speichert cluster_data, properties, repräsentative Ganglinien und cluster_properties als Excel."""

    # Ensure that the input object is an instance of `Clusterung`.
    if not isinstance(cluster_obj, Clusterung):
        raise TypeError("Das übergebene Objekt ist keine Instanz von Clusterung.")

    # Create an Excel writer to save multiple sheets.
    with pd.ExcelWriter(filepath) as writer:
        ## Save the original time-series data if available.
        if cluster_obj.data is not None:
            cluster_obj.data.to_excel(writer, sheet_name="Data Ganglinien")

        ## Save the additional properties assigned to time-series data.
        if cluster_obj.properties_dates is not None:
            cluster_obj.properties_dates.to_excel(writer, sheet_name="Data Eigenschaften")

        ## Save the cluster assignments.
        if cluster_obj.clusters is not None:
            cluster_obj.clusters.to_excel(writer, sheet_name="Clusterzuordnung")

        ## Save the representative series for each cluster.
        if cluster_obj.representative_series is not None:
            cluster_obj.representative_series.to_excel(writer, sheet_name="Cluster Ganglinien", float_format="%.2f")

        ## Save the properties of each cluster.
        if cluster_obj.cluster_properties is not None:
            cluster_obj.cluster_properties.to_excel(writer, sheet_name="Cluster Eigenschaften")


## @brief Converts date strings within a dictionary into `datetime.date` objects.
#
#  This function processes a dictionary where the keys remain unchanged,
#  but the values (expected to be date strings) are converted into lists
#  of `datetime.date` objects.
#
#  @param dict_str_attribute A dictionary containing date strings as values.
#  @return A dictionary with the same keys, but date values converted to `datetime.date` objects.
def convert_dates(dict_str_attribute):
    """Konvertiert alle Datumsstrings innerhalb eines Dictionaries in datetime.date-Objekte."""

    ## Convert each date string into a `datetime.date` object.
    return {key: pd.to_datetime(value) for key, value in dict_str_attribute.items()}

