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
import plotly.express as px
from copy import deepcopy


## @class ConfigManager
#  @brief Manages the configuration of the Clustertool.
#
#  This class implements the Singleton pattern to ensure only one configuration
#  manager exists throughout the application. It handles loading, saving, and
#  providing access to configuration settings and color schemes.
class ConfigManager:
    _instance = None  # Singleton-Pattern

    ## @brief Creates a new ConfigManager instance or returns the existing one (Singleton pattern).
    #  @param cls The class being instantiated.
    #  @return The singleton instance of ConfigManager.
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(ConfigManager, cls).__new__(cls)
            cls._instance._initialized = False
        return cls._instance

    ## @brief Initializes the ConfigManager instance.
    #
    #  Sets up configuration paths, ensures the config directory exists,
    #  creates default configuration files if needed, and loads configurations.
    #  If the instance is already initialized, this method returns early.
    def __init__(self):
        if self._initialized:
            return

        ## @var config_dir
        #  Path to the configuration directory.
        self.config_dir = Path(__file__).parent.parent / "config"

        ## @var config_file
        #  Path to the main configuration JSON file.
        self.config_file = self.config_dir / "config.json"

        ## @var colors_file
        #  Path to the colors configuration JSON file.
        self.colors_file = self.config_dir / "colors.json"

        # Ensure config directory exists
        self.config_dir.mkdir(exist_ok=True)

        # Load or create configurations
        if not self.config_file.exists():
            self._create_default_config()
        if not self.colors_file.exists():
            self._create_default_colors()

        self._load_config()
        self._load_colors()


    ## @brief Creates the default configuration file.
    #
    #  Generates a JSON configuration file with default settings for the GUI,
    #  clustering parameters, calendar settings, and file paths.
    def _create_default_config(self):
        default_config = {
            "gui": {
                "default_language": "de",
                "window_size": [1024, 768],
                "default_property": "Wochentag"
            },
            "clustering": {
                "default_method": "average",
                "default_distance": "SQV Counts",
                "default_cutoff": 0.8,
                "default_kmeans_preset": "random"
            },
            "calendar": {
                "default_state": "BW"
            },
            "paths": {
                "data_dir": "data/",
                "temp_dir": "temp/"
            }
        }
        with open(self.config_file, 'w') as f:
            json.dump(default_config, f, indent=4)

    ## @brief Creates the default color configuration.
    #
    #  Generates a JSON file with default color settings including color sequences
    #  for clusters, properties, and weekdays, as well as gradient color scales.
    def _create_default_colors(self):
        default_colors = {
            "_meta": {
                "description": '''Farbdefinitionen, unterteilt in Farbsequenzen und Farbskalen. 
                Sequenzen können als Listen oder LookUp Dicts übergeben werden.  
                Spezielle Colormaps entsprechen einsortieren mit key = Bezugsattribut.
                Beim Update der Farben erfolgt die Zuordnung Listenreihenfolge zu alphabetisch sortierten Attributswerten''',
                "version": "1.0"
            },
            "sequences": {
                "default": {
                    "type": "sequence",
                    "name": "Dark24",
                    "colors": list(px.colors.qualitative.Dark24)

                },
                "properties": {
                    "type": "sequence",
                    "name": "G10",
                    "colors": list(px.colors.qualitative.G10)

                },
                "wochentag": {
                    "type": "sequence",
                    "name": "Wochentag",
                    "colors": {
                        "Montag": "#008000",
                        "Dienstag": "#000080",
                        "Mittwoch": "#00FFFF",
                        "Donnerstag": "#0000FF",
                        "Freitag": "#FF7F00",
                        "Samstag": "#FF0000",
                        "Sonntag": "#800000"
                    }
                }
            },
            "gradients": {
                "default": {
                    "type": "gradient",
                    "name": "spectral"
                }
            }
        }
        with open(self.colors_file, 'w') as f:
            json.dump(default_colors, f, indent=4)

    ## @brief Loads the configuration from the JSON file.
    #
    #  Reads the configuration settings from the JSON file and stores them
    #  in the config attribute.
    def _load_config(self):
        with open(self.config_file) as f:
            self.config = json.load(f)

    ## @brief Loads the color configuration from the JSON file.
    #
    #  Reads the color settings from the JSON file, converts cluster keys
    #  from strings back to integers, and stores the configuration in the
    #  colors attribute.
    def _load_colors(self):
        with open(self.colors_file) as f:
            colors_data = json.load(f)

        # Convert cluster keys from strings back to integers
        if "cluster" in colors_data["sequences"]:
            colors_data["sequences"]["cluster"]["colors"] = {
                int(k): v for k, v in colors_data["sequences"]["cluster"]["colors"].items()
            }

        self.colors = colors_data


    ## @brief Returns colors from a specified color sequence.
    #
    #  Retrieves a color sequence by name. If the requested sequence doesn't exist,
    #  falls back to either the "properties" sequence (if flag_property is True)
    #  or the "default" sequence.
    #
    #  @param name The name of the color sequence to retrieve (default: "default").
    #  @param flag_property If True, uses the "properties" sequence as fallback instead of "default".
    #  @return A list or dictionary of colors from the specified sequence.
    def get_colors(self, name="default", flag_property=False):
        sequence = self.colors["sequences"].get(name.lower())
        if not sequence:
            # Fall back to default sequence
            if flag_property:
                sequence = self.colors["sequences"]["properties"]
            else:
                sequence = self.colors["sequences"]["default"]
            logging.info(f"Color sequence {name} not found, using default")

        colors = sequence["colors"]

        return colors

    ## @brief Retrieves a specific clustering configuration attribute.
    #
    #  @param attr_name The name of the clustering attribute to retrieve.
    #  @return The value of the requested clustering attribute.
    def get_cluster_attribute(self, attr_name):
        return self.config["clustering"].get(attr_name)

    ## @brief Returns the name of a color gradient.
    #
    #  Retrieves a color gradient by name. If the requested gradient doesn't exist,
    #  falls back to the "default" sequence.
    #
    #  @param name The name of the color gradient to retrieve (default: "default").
    #  @return The name of the specified gradient.
    def get_colorscale(self, name="default"):
        gradient = self.colors["gradients"].get(name)
        if not gradient:
            # Fall back to default sequence
            gradient = self.colors["sequences"]["default"]
            logging.info(f"Color gradient {name} not found, using default")

        return gradient["name"]

    ## @brief Saves the current configuration to JSON files.
    #
    #  Writes both the main configuration and color settings to their
    #  respective JSON files.
    def save(self):
        with open(self.config_file, 'w') as f:
            json.dump(self.config, f, indent=4)
        with open(self.colors_file, 'w') as f:
            json.dump(self.colors, f, indent=4)

    ## @brief Reloads the configuration from JSON files.
    #
    #  Refreshes both the main configuration and color settings by
    #  reading them again from their respective JSON files.
    def reload(self):
        self._load_config()
        self._load_colors()


    ## @brief Saves the current color configuration to a JSON file.
    #
    #  Creates a copy of the color configuration and saves it to the specified file.
    #  If no file path is provided, the default colors file path is used.
    #
    #  @param filepath Optional; Path to the target file. If None, self.colors_file is used.
    def write_colors(self, filepath=None):
        if filepath is None:
            filepath = self.colors_file

        # Erstelle eine Kopie der Farbkonfiguration
        colors_data = {
            "_meta": {
                "description": self.colors["_meta"]["description"],
                "version": self.colors["_meta"]["version"],
            },
            "sequences": self.colors["sequences"].copy(),
            "gradients": self.colors["gradients"].copy()
        }

        # # Konvertiere nur Cluster-Farben zu Strings
        # Problem: keine Deepcopy, verÃ¤ndert Original. Konvertierung direkt in json.dump ausgelagert
        # if "cluster" in colors_data["sequences"]:
        #     colors_data["sequences"]["cluster"]["colors"] = {
        #         str(k): v for k, v in colors_data["sequences"]["cluster"]["colors"].items()
        #     }

        # Speichere als JSON mit Einrückung
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(prepare_json_safe(colors_data), f, indent=4, ensure_ascii=False)


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


def explode_dict_cells(df: pd.DataFrame) -> pd.DataFrame:
    """
    Explodiert Spalten mit dict-Zellen zu einem DataFrame mit MultiIndex-Spalten.

    Beispiel:
    Spalte 'Ferien' mit dict {"Sommerferien": 0.2, "Osterferien": 0.8}
    ➝ MultiIndex-Spalten ('Ferien', 'Sommerferien'), ('Ferien', 'Osterferien')
    """
    exploded_parts = []

    for col in df.columns:
        if df[col].apply(lambda x: isinstance(x, dict)).all():
            # Normale Zellen mit dict → expandieren
            col_df = pd.json_normalize(df[col])
            col_df.columns = pd.MultiIndex.from_product([[col], col_df.columns])
            exploded_parts.append(col_df)
        else:
            # Andere Spalten (nicht dict) → behalten
            exploded_parts.append(pd.DataFrame({(col, ''): df[col]}))

    result = pd.concat(exploded_parts, axis=1)
    return result



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

    # Add indicators for data if available
    if hasattr(cluster_obj, 'indicators_data') and cluster_obj.indicators_data:
        data["indicators_data"] = {}
        for indicator_name, indicator_df in cluster_obj.indicators_data.items():
            data["indicators_data"][indicator_name] = convert_index_and_keys_to_str(indicator_df)

    # Add indicators for clusters if available
    if hasattr(cluster_obj, 'indicators_clusters') and cluster_obj.indicators_clusters:
        data["indicators_clusters"] = {}
        for indicator_name, indicator_df in cluster_obj.indicators_clusters.items():
            data["indicators_clusters"][indicator_name] = convert_index_and_keys_to_str(indicator_df)

    with open(filepath, "w") as f:
        json.dump(data, f, indent=4)


## @brief Loads a Clusterung instance from a JSON file.
#  @param filepath Path to the JSON file.
#  @param config_manager Optional; ConfigManager instance to use. If None, the global config_manager is used.
#  @return A Clusterung object with restored data.
def load_clusterung_from_json(filepath, config_manager=None):
    # Use the global config_manager if none is provided
    if config_manager is None:
        from modules.data_handler import config_manager as global_config_manager
        config_manager = global_config_manager

    """Lädt eine Clusterung-Instanz aus einer JSON-Datei."""
    with open(filepath, "r") as f:
        data_file = json.load(f)

    clusters = pd.DataFrame.from_dict(data_file["clusters"], orient="index")
    data = pd.DataFrame.from_dict(data_file["data"])
    data_properties = pd.DataFrame.from_dict(data_file["properties_dates"])

    # Stelle potenzielle MultiIndex-Spalten wieder her
    data = restore_multiindex_columns(data)
    data_properties = restore_multiindex_columns(data_properties)
    clusters = restore_multiindex_columns(clusters)


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
        calendar_obj=calendar_attr,
        config_manager=config_manager
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

    # Bei den Indikatoren auch MultiIndex wiederherstellen
    if "indicators_data" in data_file and data_file["indicators_data"]:
        obj.indicators_data = {}
        for indicator_name, indicator_data in data_file["indicators_data"].items():
            indicator_df = pd.DataFrame.from_dict(indicator_data)
            indicator_df.index = pd.to_datetime(indicator_df.index)
            indicator_df = restore_multiindex_columns(indicator_df)
            obj.indicators_data[indicator_name] = indicator_df

    if "indicators_clusters" in data_file and data_file["indicators_clusters"]:
        obj.indicators_clusters = {}
        for indicator_name, indicator_data in data_file["indicators_clusters"].items():
            indicator_df = pd.DataFrame.from_dict(indicator_data)
            indicator_df.index = indicator_df.index.astype(int)
            indicator_df = restore_multiindex_columns(indicator_df)
            obj.indicators_clusters[indicator_name] = indicator_df

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

        # Wenn es ein MultiIndex ist: zu String
        if isinstance(data_dict.columns, pd.MultiIndex):
            data_dict.columns = ["|".join(map(str, col)) if isinstance(col, tuple) else str(col)
                               for col in data_dict.columns]
            return data_dict.to_dict()

        else:
            # Für normale Spalten, behalte bisheriges Verhalten bei
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
    """Speichert cluster_data, properties, repräsentative Ganglinien, cluster_properties und Indikatoren als Excel."""

    # Ensure that the input object is an instance of `Clusterung`.
    if not isinstance(cluster_obj, Clusterung):
        raise TypeError("Das übergebene Objekt ist keine Instanz von Clusterung.")

    # Create an Excel writer to save multiple sheets.
    with pd.ExcelWriter(filepath) as writer:
        ## Save the original time-series data if available.
        if cluster_obj.data is not None:
            cluster_obj.data.to_excel(writer, sheet_name="Data Ganglinien", float_format="%.0f")

        ## Save the additional properties assigned to time-series data.
        if cluster_obj.properties_dates is not None:
            cluster_obj.properties_dates.to_excel(writer, sheet_name="Data Eigenschaften")

        ## Save the cluster assignments
        if cluster_obj.clusters is not None:
            cluster_obj.clusters.to_excel(writer, sheet_name="Clusterzuordnung", float_format="%.0f")

        ## Save the representative series for each cluster.
        if cluster_obj.representative_series is not None:
            cluster_obj.representative_series.to_excel(writer, sheet_name="Cluster Ganglinien", float_format="%.0f")

        ## Save the properties of each cluster.
        if cluster_obj.cluster_properties is not None:
            exploded = explode_dict_cells(cluster_obj.cluster_properties).fillna(0)
            exploded.to_excel(writer, sheet_name="Cluster Eigenschaften",
                                                    float_format="%.2f", merge_cells=True)

        ## Save the indicators for the original data if available - combined into a single table
        if hasattr(cluster_obj, 'indicators_data') and cluster_obj.indicators_data:
            # Create a combined DataFrame for all data indicators
            combined_data_indicators = harmonize_and_concat_dfs(cluster_obj.indicators_data)
            # Indexnamen entfernen
            combined_data_indicators.index.name = None
            # Save the combined DataFrame to a single sheet
            combined_data_indicators.to_excel(writer, sheet_name="Data Kenngrößen", startrow=0,
                                              float_format="%.0f", merge_cells=True)

        ## Save the indicators for the clusters if available - combined into a single table
        if hasattr(cluster_obj, 'indicators_clusters') and cluster_obj.indicators_clusters:
            # Create a combined DataFrame for all cluster indicators
            combined_cluster_indicators = harmonize_and_concat_dfs(cluster_obj.indicators_clusters)
            # Indexnamen entfernen
            combined_cluster_indicators.index.name = None
            # Save the combined DataFrame to a single sheet
            combined_cluster_indicators.to_excel(writer, sheet_name="Cluster Kenngrößen",
                                                 float_format="%.0f", merge_cells=True)


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


def restore_multiindex_columns(df):
    """Stellt MultiIndex-Spalten aus den mit | getrennten Spaltennamen wieder her."""
    if df is None:
        return None

    if any("|" in str(col) for col in df.columns):
        # Konvertiere die Spalten zurück zu MultiIndex
        df.columns = pd.MultiIndex.from_tuples([
            tuple(col.split("|")) if "|" in str(col) else (col,)
            for col in df.columns
        ])
    return df


def harmonize_and_concat_dfs(dict_dfs):
    # Finde die maximale Anzahl von Levels
    max_levels = max(
        len(df.columns.levels) if isinstance(df.columns, pd.MultiIndex) else 1
        for df in dict_dfs.values()
    )

    # Harmonisiere die Column-Levels
    harmonized_dfs = {}
    for key, df in dict_dfs.items():
        if not isinstance(df.columns, pd.MultiIndex):
            # Wenn keine MultiIndex-Spalten, erstelle einen MultiIndex
            df = df.copy()
            df.columns = pd.MultiIndex.from_tuples([(col,) + ("-",) * (max_levels - 1) for col in df.columns])
        elif len(df.columns.levels) < max_levels:
            # Wenn weniger Levels, fülle mit "-" auf
            df = df.copy()
            new_tuples = [tuple(list(col) + ["-"] * (max_levels - len(col))) for col in df.columns]
            df.columns = pd.MultiIndex.from_tuples(new_tuples)
        harmonized_dfs[key] = df

    # Füge die harmonisierten DataFrames zusammen
    return pd.concat(harmonized_dfs, axis=1, keys=harmonized_dfs.keys())


def prepare_json_safe(obj):
    """Rekursiv: Wandelt numpy-Typen und dict-Keys in JSON-kompatible Typen um, ohne Original zu verändern."""
    if isinstance(obj, dict):
        return {str(k): prepare_json_safe(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [prepare_json_safe(i) for i in obj]
    elif isinstance(obj, tuple):
        return tuple(prepare_json_safe(i) for i in obj)
    elif isinstance(obj, np.integer):
        return int(obj)
    elif isinstance(obj, np.floating):
        return float(obj)
    elif isinstance(obj, np.bool_):
        return bool(obj)
    elif isinstance(obj, np.ndarray):
        return obj.tolist()
    else:
        return obj


# Instanz wird erstellt - nicht auskommentieren!
config_manager = ConfigManager()
