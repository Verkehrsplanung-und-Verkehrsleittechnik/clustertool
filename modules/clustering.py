## @package clustering
#  @brief This module provides functionality for time-series clustering.
#
#  The `clustering` module includes the `Clusterung` class, which performs clustering
#  on time-series data using hierarchical clustering and k-means. The module also
#  provides utilities for visualizing clustering results, formatting plots, and
#  handling cluster colors.
#
#  **Main functionalities:**
#  - **Clustering Algorithms:**
#    - `Clusterung`: Class for hierarchical and k-means clustering.
#  - **Plot Formatting:**
#    - `format_diagrams()`: Applies localized formatting to Plotly figures.
#    - `has_subplots()`: Checks whether a figure contains subplots.
#  - **Cluster Visualization:**
#    - `get_cluster_colors()`: Assigns colors to clusters for consistency in plots.
#
#  The module integrates with Plotly for visualization and supports
#  different language settings for formatted plots.
#
#  @author MaS, based on Matlab Clustertool, supported by GPT
#  @date 2025
#
#  @note The module relies on SciPy for clustering and Plotly for visualization.
import datetime

import numpy as np
import pandas as pd
from scipy.cluster.hierarchy import linkage, fcluster, dendrogram
from scipy.spatial.distance import pdist, squareform
from scipy.cluster.vq import kmeans2
import modules
import plotly.graph_objects as go
from plotly.subplots import make_subplots
import plotly.express as px
from pathlib import Path
import logging
from functools import partial


## @class Clusterung
#  @brief Performs clustering on time-series data using different clustering methods.
class Clusterung:
    ## @brief Constructor for the Clusterung class.
    #  @param data DataFrame with time-series data to cluster.
    #  @param attr_data Additional attribute data related to the time-series.
    #  @param calendar_obj Calendar object containing holiday and other date information.
    #  @param method Clustering method ("average", "complete", "ward", or "kmeans").
    #  @param distance_function Distance metric ("euclidean", "geh", etc.).
    #  @param max_clusters Maximum number of clusters.
    #  @param cutoff Distance cutoff for hierarchical clustering.
    #  @param kmeans_iter Number of iterations for kmeans clustering.
    #  @param kmeans_preset Preset configurations for kmeans clustering.
    #  @param use_calendar Boolean flag to use calendar attributes.
    def __init__(self, data: pd.DataFrame, attr_data=None, calendar_obj=None, method=None,
                 distance_function=None, max_clusters=None, cutoff=None,
                 kmeans_iter=None, kmeans_preset=None, use_calendar=True, f_sqv=None,
                 config_manager=None
                 ):

        self.config = config_manager or modules.data_handler.ConfigManager()

        ## @var method
        #  Selected clustering method (e.g., "average", "kmeans").
        if method is None:
            self.method = self.config.get_cluster_attribute("default_method")
        else:
            self.method = method

        ## @var distance_function
        #  Distance metric used for clustering (e.g., "euclidean", "geh").
        if distance_function is None:
            self.distance_function = self.config.get_cluster_attribute("default_distance_function").replace(" ", "_").lower()
        else:
            self.distance_function = distance_function.replace(" ", "_").lower()

        ## @var max_clusters
        #  Maximum number of clusters for clustering methods that require it.
        if max_clusters is None:
            self.max_clusters = self.config.get_cluster_attribute("default_max_clusters")
        else:
            self.max_clusters = max_clusters

        ## @var cutoff
        #  Distance cutoff for hierarchical clustering.
        if cutoff is None:
            self.cutoff = self.config.get_cluster_attribute("default_cutoff")
        else:
            self.cutoff = cutoff

        ## @var kmeans_iter
        #  Number of iterations for k-means clustering.
        if kmeans_iter is None:
            self.kmeans_iter = self.config.get_cluster_attribute("default_kmeans_iterations")
        else:
            self.kmeans_iter = kmeans_iter

        ## @var kmeans_presettings
        #  Mapping of k-means preset configuration names to algorithmic settings.
        if kmeans_preset is None:
            self.kmeans_presettings = self.config.get_cluster_attribute("default_kmeans_presettings")
        else:
            self.kmeans_presettings = {"zufällige Auswahl": "points",
                                   "Normalverteilung": "random",
                                   "++ Algorithmus": "++"}.get(kmeans_preset, kmeans_preset)

        ## @var factor_sqv
        #  Scaling factor for SQV-based distance functions.
        if f_sqv is None:
            self.factor_sqv = self.config.get_cluster_attribute("scaling_factor_sqv")
        else:
             self.factor_sqv = f_sqv

        ## @var data
        #  Input DataFrame containing time-series data to be clustered.
        self.data = data

        ## @var clusters
        #  Series storing the cluster assignment for each time series.
        self.clusters = pd.Series(-1, index=data.index, name='cluster')

        ## @var distance_matrix
        #  Distance matrix computed based on the selected distance function.
        self.distance_matrix = None

        # Validate clustering settings
        self._validate_parameters()

        ## @var calendar
        #  Calendar object containing holiday and other date information.
        if calendar_obj is None and use_calendar:
            self.calendar = modules.calendar_attributes.CalendarAttributes(
                self.data.index.tolist(),
                dir_data_holidays=Path(__file__).parents[1] / "data"
            )
        elif not use_calendar:
            self.calendar = modules.calendar_attributes.CalendarAttributes(self.data.index.tolist(), dummy=True)
        else:
            self.calendar = calendar_obj

        ## @var properties
        #  Dictionary storing attributes for each time series.
        self.properties = {}

        ## @var representative_series
        #  Representative series for each cluster, computed after clustering.
        self.representative_series = None

        ## @var language
        #  Language setting (default: "de").
        self.language = "de"

        ## @var properties_dates
        #  DataFrame containing additional attributes for time series.
        if attr_data is not None:
            self.properties_dates = attr_data.loc[data.index, :]
            self.properties_dates.columns = self.properties_dates.columns.astype(str)
        else:
            self.properties_dates = pd.DataFrame()

        if len(self.properties_dates) > 0:
            self.properties.update({col: self.properties_dates[col].unique().tolist()
                                    for col in self.properties_dates.columns})

        if use_calendar:
            self._add_calendar_properties()

        ## @var cluster_properties
        #  DataFrame storing computed cluster properties.
        self.cluster_properties = None

        # Process properties and map to attributes
        self._fill_properties_dates()

        ## @var n_count_intervals
        # Number of count intervals per day and count station.
        # It is used to calculate indicators per count station in concatenated time profiles.
        self.n_count_intervals = 24

        self.indicators_clusters = {}

        self.indicators_data = {}

    ## @brief Adds calendar-based properties to the properties dictionary.
    #
    #  This method adds time-related properties (e.g., holidays, seasons, weekdays)
    #  from the calendar object to the `self.properties` dictionary. It translates
    #  attribute names based on the selected language (German or English).
    def _add_calendar_properties(self):
        # Define attribute name mappings for German and English
        if self.language == "de":
            attribute_mapping = {
                "school_holidays": "Ferien",
                "bank_holidays": "Feiertage",
                "summertime": "Sommerzeit",
                "season": "Jahreszeit",
                "weekday": "Wochentag",
                "month": "Monat",
                "workday": "Werktag",
                "bridging_day": "Brueckentag"
            }
        else:
            attribute_mapping = {
                "school_holidays": "school_holidays",
                "bank_holidays": "bank_holidays",
                "summertime": "summertime",
                "season": "season",
                "weekday": "weekday",
                "month": "month",
                "workday": "workday",
                "bridging_day": "bridging_day"
            }

        # Add school holidays to the properties dictionary if data is available
        if len(getattr(self.calendar, attribute_mapping["school_holidays"].lower())) > 1:
            self.properties.update({
                attribute_mapping["school_holidays"]: list(getattr(self.calendar,
                                                                   attribute_mapping["school_holidays"].lower()).keys())
            })

        # Add bank holidays to the properties dictionary if data is available
        if len(getattr(self.calendar, attribute_mapping["bank_holidays"].lower())) > 1:
            self.properties[attribute_mapping["bank_holidays"]] = list(getattr(self.calendar,
                                                                               attribute_mapping[
                                                                                   "bank_holidays"].lower()).keys())

        # Add other time-related properties (summertime, season, weekday, etc.)
        for prop in ["summertime", "season", "weekday", "month", "workday", "bridging_day"]:
            translated_key = attribute_mapping[prop]  # Get the translated property name
            if translated_key in self.properties:
                continue
            else:
                self.properties[translated_key] = list(getattr(self.calendar, prop, {}).keys())


    ## @brief Performs clustering based on initialized parameters.
    #
    #  This method applies either k-means or hierarchical clustering to the dataset.
    #  It calculates the distance matrix, performs clustering, and evaluates the resulting clusters.
    def perform_clustering(self):
        ## Decide clustering method
        if self.method == "kmeans":

            ## Ensure the selected distance function is compatible with k-means
            if self.distance_function.lower() not in ["euclidean"]:
                raise ValueError("Distanzmethode ist mit kmeans nicht abgebildet")

            ## Identify indices of rows that contain NaN values.
            #  K-means does not support NaN values, so rows with missing values are removed.
            self.index_not_nan = self.data.loc[~self.data.isna().any(axis=1)].index
            data_values = self.data.loc[self.index_not_nan, :].values

            ## Log warning if rows are removed due to NaN values.
            if data_values.shape[0] < len(self.index_not_nan):
                logging.warning(f"Es werden Datensätze mit fehlenden Zähldaten für kmeans gelöscht. "
                                f"Von {len(self.index_not_nan)} Datensätzen werden {data_values.shape[0]} verwendet.")

            # Apply k-means clustering.
            #  - `centroid`: The centroids of the clusters.
            #  - `cluster_index`: The cluster assignments for each data point.
            centroid, cluster_index = kmeans2(data_values.astype(float), self.max_clusters, minit=self.kmeans_presettings,
                                              iter=self.kmeans_iter)

            cluster_index += 1 # default indices star with 0
            self._calculate_distance_matrix(return_vector=False)
        else:

            distance_vector, method = self._calculate_distance_matrix(return_vector=True)

            # Perform hierarchical clustering using the selected method.
            linkage_matrix = linkage(distance_vector[~np.isnan(distance_vector)], method=method)

            # Determine cluster assignments based on the linkage matrix.
            cluster_index = self._determine_clusters(linkage_matrix)

            # Store linkage result for later use (e.g., dendrogram visualization).
            self.linkage_matrix = linkage_matrix

            # # Compute silhouette scores to assess clustering quality.
            # self._calculate_silhouette() # muss nach assign_clusters kommen bzw wird beim SIlhuettenplot kalkuliert

        # Assign clusters to the data.
        self._assign_clusters(cluster_index)
        logging.info("Clusterung erfolgreich durchgeführt")

        # Calculate representative time-series for each cluster (default: mean).
        self._calculate_representative_series('mean')

        # Evaluate cluster properties (e.g., distribution of categorical attributes).
        self._evaluate_properties_cluster()

        logging.info("Eigenschaften der Cluster und repräsentative Ganglinien ermittelt")


    # @brief Calculates the distance vector based on the chosen distance function.
    #
    # This method computes pairwise distances between data points using the specified distance function.
    # It supports different distance metrics, including "euclidean" and custom metrics like "sqv".
    #
    # @param data_values A 2D numpy array or DataFrame containing the numerical data to compute distances for.
    # @return A condensed distance matrix (1D array) with pairwise distances between rows in `data_values`.
    def _calculate_distance_vector(self, data_values):
        # @var distance_func
        #  The selected distance function, either a predefined metric or a custom function from `modules.metrics`.

        # If "euclidean" is selected, use SciPy's built-in function unless NaNs are present
        if self.distance_function in ['euclidean']:
            distance_func = getattr(modules.metrics, self.distance_function) if np.isnan(data_values).any() \
                else self.distance_function

        # If "sqv" or "sqv_counts" is selected, use a partial function with the scaling factor `f_sqv`
        elif self.distance_function in ["sqv", "sqv_counts"]:
            distance_func = partial(getattr(modules.metrics, self.distance_function), f=self.factor_sqv)

        # Otherwise, fetch the distance function from `modules.metrics`
        else:
            distance_func = getattr(modules.metrics, self.distance_function)

        # Compute pairwise distances using the selected function
        return pdist(data_values, distance_func)


    ## @brief Determines clusters from the hierarchical linkage matrix.
    #
    # This method assigns cluster labels based on hierarchical clustering results.
    # The clusters are either determined by a distance threshold (`cutoff`) or by a fixed number of clusters (`max_clusters`).
    # After initial assignment, the clusters are sorted by size, and labels are reassigned accordingly.
    #
    # @param linkage_matrix A numpy array representing the hierarchical clustering linkage matrix.
    # @return A numpy array containing the assigned cluster labels for each data point.
    def _determine_clusters(self, linkage_matrix):
        # @var labels
        #  Initial cluster labels assigned based on the selected method (cutoff or max_clusters).

        # Determine cluster labels based on cutoff or max_clusters
        if self.cutoff is not None:
            if "sqv" in self.distance_function:
                labels = fcluster(linkage_matrix, t=(1 - self.cutoff), criterion='distance')
            else:
                labels = fcluster(linkage_matrix, t=self.cutoff, criterion='distance')
        else:
            labels = fcluster(linkage_matrix, t=self.max_clusters, criterion='maxclust')

        # @var cluster_sizes
        #  Dictionary storing the size of each cluster before label reassignment.

        # Calculate cluster sizes
        unique_labels, counts = np.unique(labels, return_counts=True)
        cluster_sizes = dict(zip(unique_labels, counts))

        # @var sorted_clusters
        #  List of clusters sorted by size in descending order.

        # Sort clusters by size (largest first)
        sorted_clusters = sorted(cluster_sizes.keys(), key=lambda c: -cluster_sizes[c])

        # @var cluster_mapping
        #  Dictionary mapping old cluster labels to new labels based on size ordering.

        # Create a mapping for new cluster labels (largest gets label 1, next largest gets 2, etc.)
        cluster_mapping = {old: new for new, old in enumerate(sorted_clusters, start=1)}

        # @var new_labels
        #  The final adjusted cluster labels after reordering by size.

        # Assign new cluster labels
        new_labels = np.array([cluster_mapping[label] for label in labels])

        return new_labels

    ## @brief Sets the number of count intervals per day and count station.
    #
    #  This internal method validates and sets the number of count intervals
    #  used to calculate indicators per count station in concatenated time profiles.
    #
    #  @param value The new number of count intervals
    #  @throws ValueError If the value is not a positive integer
    def _set_count_intervals(self, value):
        if not isinstance(value, int):
            raise ValueError("n_count_intervals must be an integer")
        if value <= 0:
            raise ValueError("n_count_intervals must be greater than 0")

        self.n_count_intervals = value


    def _calculate_distance_matrix(self, return_vector):
        ## Extract numerical values from the dataset.
        data_values = self.data.values

        ## Identify indices of rows that contain valid data (non-empty rows).
        self.index_not_nan = self.data.loc[~self.data.isna().all(axis=1)].index

        ## Log warning if rows are removed due to empty data.
        if data_values.shape[0] < len(self.index_not_nan):
            logging.warning(f"Es werden Datensätze ohne Daten gelöscht."
                            f"Von {len(self.index_not_nan)} Datensätzen werden {data_values.shape[0]} verwendet.")

        ## Compute pairwise distances using the selected distance function.
        distance_vector = self._calculate_distance_vector(data_values)

        ## Define the linkage method for hierarchical clustering.
        method = self.method.lower().replace(" linkage", "")

        # Create a distance matrix as a Pandas DataFrame.
        self.distance_matrix = pd.DataFrame(squareform(distance_vector), columns=self.data.index, index=self.data.index)

        # Adjust distance values if "sqv" is used as a distance function.
        if "sqv" in self.distance_function:
            np.fill_diagonal(self.distance_matrix.values, 1)  # Set diagonal values to 1
            distance_vector = 1 - distance_vector  # Invert values: 0 = optimal match, 1 = no match

        if return_vector:
            return distance_vector, method


    ## @brief Calculates indicators for data and/or clusters using vectorized operations.
    #
    # This method calculates indicators for raw data and/or clusters based on the specified parameter.
    # It uses vectorized operations and dictionary comprehensions for improved performance.
    # For each count station, indicators are calculated using the n_count_intervals attribute.
    # Cluster indicators are only calculated if clustering has been performed.
    #
    # @param calc_for String specifying what to calculate indicators for: "data", "clusters", or "both".
    # @return A tuple of two DataFrames: (indicators_data, indicators_clusters). Either may be None if not calculated.
    def calculate_indicators_cs(self, calc_for="both"):
        # Performance optimization note:
        # This method has been optimized to use vectorized operations and efficient pandas techniques:
        # 1. Dictionary comprehensions instead of explicit loops
        # 2. Direct DataFrame creation and assignment instead of cell-by-cell operations
        # 3. Batch processing of results before assignment to minimize DataFrame modifications
        # 4. Grouped column assignments where possible to leverage pandas' optimized operations

        logging.info("Start Berechnung der Ganglinienindikatoren")

        # Indicators and implementation - mapping indicator names to their calculation functions
        dict_indicators_calc = {
            "TV": partial(modules.indicators.calculate_tv, n_intervals=self.n_count_intervals),
            "avg": modules.indicators.calculate_mean,
            "SP": partial(modules.indicators.identify_peak_hour, period='day', is_locale=True,
                          n_intervals=self.n_count_intervals),  # Standardfall mit period='day'
            "SP_am": partial(modules.indicators.identify_peak_hour, period='am', is_locale=True,
                          n_intervals=self.n_count_intervals),
            "SP_pm": partial(modules.indicators.identify_peak_hour, period='pm', is_locale=True,
                          n_intervals=self.n_count_intervals)
        }

        # Check if the parameter is valid
        if calc_for not in ["data", "clusters", "both"]:
            logging.warning(f"Invalid value for calc_for: {calc_for}. Must be one of: 'data', 'clusters', 'both'")
            return

        self.calculate_series_cs()

        if any(self.series_cs.str.len() != self.n_count_intervals):
            logging.warning(f"Error Assignment of count stations: length intervals != n_count_intervals")

        # Calculate indicators for raw data if requested
        if calc_for in ["data", "both"]:
            # Check if indicators for data already exist
            indicators_exist = all(indicator in self.indicators_data for indicator in dict_indicators_calc.keys())
            if not indicators_exist:
                self.indicators_data = self._calculate_indicators_for_data(self.data, dict_indicators_calc)
            else:
                logging.info("Indicators for data already exist. Skipping calculation.")

        # Calculate indicators for clusters if requested and clustering has been performed
        if calc_for in ["clusters", "both"]:
            # Check if clustering has been performed
            if self.representative_series is None:
                logging.warning("Clustering has not been performed yet. Cannot calculate indicators for clusters.")
                return

            self.indicators_clusters = self._calculate_indicators_for_data(self.representative_series, dict_indicators_calc)

        logging.info("Indicators calculated")



    def calculate_indicators_global(self, calc_for="both"):
        logging.info("Start Berechnung der Netzganglinienindikatoren (global)")

        # Indicators and implementation - mapping indicator names to their calculation functions
        dict_indicators_calc = {
            "TV": partial(modules.indicators.calculate_tv, n_intervals=self.n_count_intervals),
            "avg": modules.indicators.calculate_mean,
            "SP": partial(modules.indicators.identify_peak_hour, period='day', is_locale=False,
                          n_intervals=self.n_count_intervals),  # Standardfall mit period='day'
            "SP_am": partial(modules.indicators.identify_peak_hour, period='am', is_locale=False,
                          n_intervals=self.n_count_intervals),
            "SP_pm": partial(modules.indicators.identify_peak_hour, period='pm', is_locale=False,
                          n_intervals=self.n_count_intervals)
        }

        # Check if the parameter is valid
        if calc_for not in ["data", "clusters", "both"]:
            logging.warning(f"Invalid value for calc_for: {calc_for}. Must be one of: 'data', 'clusters', 'both'")
            return

        self.indicators_data_global = getattr(self, "indicators_data_global", {})
        self.indicators_cluster_global = getattr(self, "indicators_cluster_global", {})

        # Calculate indicators for raw data if requested
        if calc_for in ["data", "both"]:
            for key, function_ind in dict_indicators_calc.items():
                self.indicators_data_global[key] = function_ind(self.data)

        # Calculate indicators for clusters if requested and clustering has been performed
        if calc_for in ["clusters", "both"]:
            # Check if clustering has been performed
            if self.representative_series is None:
                logging.warning("Clustering has not been performed yet. Cannot calculate indicators for clusters.")
                return

            for key, function_ind in dict_indicators_calc.items():
                self.indicators_cluster_global[key] = function_ind(self.representative_series)

        logging.info("Indicators calculated")




    ## @brief Assigns the calculated cluster labels to the dataset.
    #
    # This method updates the `self.clusters` Series with the calculated cluster labels.
    # The labels are assigned only if their length matches the number of valid (non-NaN) data points.
    #
    # @param cluster_index A numpy array or pandas Series containing cluster labels for the data points.
    # @throws ValueError If the length of `cluster_index` does not match the number of valid indices (`index_not_nan`).
    def _assign_clusters(self, cluster_index):
        # @var self.clusters
        #  A pandas Series storing the assigned cluster labels for each data point.

        # Ensure the cluster labels match the number of non-NaN indices
        if len(cluster_index) == len(self.index_not_nan):
            cluster_index = pd.Series(cluster_index, index=self.index_not_nan)
            self.clusters.loc[cluster_index.index] = cluster_index
        elif self.method == "kmeans":
            cluster_index = pd.Series(cluster_index, index=self.data.index)
            self.clusters.loc[cluster_index.index] = cluster_index
        else:
            raise ValueError("Debug - Assignment of indices is wrong")


    ## @brief Generates and returns plots of clustering results.
    #
    # This method creates a figure with two subplots:
    # - The first subplot shows the original time-series data.
    # - The second subplot shows the representative cluster series.
    #
    # Additionally, it generates separate property distribution plots for each cluster property.
    #
    # @param vertical_lines_series: number of time intervals for one count station
    #
    # @return A tuple containing:
    #   - `fig_series`: A Plotly figure with two subplots (original & representative data).
    #   - `dict_fig_property`: A dictionary of property plots, where keys are property names and values are Plotly figures.
    def plots_results(self, vertical_lines=None):
        ## @var fig_series
        #  A Plotly figure with two subplots: original time-series data and representative cluster series.

        # Create subplots with two rows (original data & representative cluster series)
        fig_series = make_subplots(rows=2, cols=1,
                                   shared_xaxes='all',
                                   shared_yaxes='all',
                                   subplot_titles=["", ""],
                                   vertical_spacing=0)

        # Plot the original and clustered series
        self.plot_data_series(fig_series)
        self.plot_cluster_series(fig_series, row_subplot=2, scale_width=True)

        # Plot vertical lines if desired
        if vertical_lines is not None:
            self.add_vertical_lines(fig_series, vertical_lines)

        ## @var fontsize
        #  The font size for the plot labels.
        fontsize = 14

        ## @var font
        #  The font family used in the plot layout.
        font = "arial"

        # Configure layout options
        fig_series.update_layout(
            height=600,
            width=1000,
            template="simple_white",
            font_size=fontsize,
            font_family=font,
            legend_font_size=fontsize,
            margin=dict(l=10, r=10, t=10, b=10),
            legend_tracegroupgap=0,
            separators=",.",
            # Achsen-Konfiguration explizit definieren
            xaxis=dict(
                showline=True, linewidth=0.5, linecolor='black', mirror=True
            ),
            yaxis=dict(
                showline=True, linewidth=0.5, linecolor='black', mirror=True
            ),
            xaxis2=dict(
                showline=True, linewidth=0.5, linecolor='black', mirror=True,
                matches='x'  # Hier wird die X-Achse mit der ersten verknüpft
            ),
            yaxis2=dict(
                showline=True, linewidth=0.5, linecolor='black', mirror=True
            ),

            # Layout settings for legend
            legend=dict(
                font=dict(
                    size=fontsize,
                    family=font
                )
            )
        )
        # fig_series.update_xaxes(showline=True, linewidth=0.5, linecolor='black', mirror=True)
        # fig_series.update_yaxes(showline=True, linewidth=0.5, linecolor='black', mirror=True)

        fig_series.update_xaxes(title="", row=1, col=1)

        # Apply formatting to the figure
        fig_series = format_diagrams(fig_series, self.language)

        ## @var dict_fig_property
        #  A dictionary storing property distribution plots for each cluster property.
        dict_fig_property = {}

        # Generate a property distribution plot for each cluster property
        for col in self.cluster_properties.columns:
            fig = self.plot_properties(col)
            fig.update_layout(
                height=600,
                width=600,
                template="simple_white",
                font_size=fontsize,
                font_family=font,
                legend_font_size=fontsize,
                margin=dict(l=10, r=10, t=10, b=10),
                legend_tracegroupgap=0,
                separators=",."
            )
            fig = format_diagrams(fig, self.language)
            dict_fig_property[col] = fig

        return fig_series, dict_fig_property


    ## @brief Adds vertical lines in diagrams of series
    #
    # @param fig_series the figure to add vertical lines. Note: fig_series is changed directly, no return value.
    # @param no_intervals number of intervals of a count station
    def add_vertical_lines_series(self, fig_series, no_intervals_count_station):

        # reset existing shapes
        fig_series.layout.shapes = ()

        interval = no_intervals_count_station
        idx_max = self.data.shape[1]

        list_vertical_lines_idx = [] # init list
        while interval < idx_max:
            x = self.data.columns[interval]
            if isinstance(x, (float, int)):
                x = float(x)- 0.5  # x zwischen den Messquerschnitten
            fig_series.add_vline(x=x, line_width=1, line_dash="dash", line_color="black", row=1, col=1)
            fig_series.add_vline(x=x, line_width=1, line_dash="dash", line_color="black", row=2, col=1)
            # list_vertical_lines_idx.append(fig_series.layout.shapes[-1]) # store trace id, necessary for changes without new figure
            interval += no_intervals_count_station


    ## @brief Plots the distribution of a given property within clusters.
    #
    # This method generates a horizontal stacked bar chart showing the distribution of
    # a categorical property across different clusters. Each cluster is represented by
    # a separate bar, with proportions of each category within the cluster stacked together.
    #
    # @param property The name of the property to plot.
    # @return A Plotly bar chart figure representing the distribution of the property in clusters.
    def plot_properties(self, property):
        ## @var series_dict_properties
        #  A pandas Series containing property distributions for each cluster.

        series_dict_properties = self.cluster_properties[property]

        ## @var df
        #  A DataFrame where each row represents a cluster, and columns represent property categories.

        df = pd.DataFrame(series_dict_properties.tolist(), index=series_dict_properties.index)

        # Convert the DataFrame to long format for plotting
        ## @var df_long
        #  A long-format DataFrame where each row represents a cluster-category proportion.

        df_long = df.stack().reset_index()
        df_long.columns = ['Cluster', 'Category', 'Proportion']
        df_long.set_index("Cluster", inplace=True)

        # Compute the actual count of data points per category within each cluster
        df_long.loc[:, "Anzahl"] = df_long["Proportion"] * self.cluster_properties["counts"]

        # Map colors to categories (assumes 'Category' contains weekdays)
        if property in ["Wochentag", "weekday"]:
            dict_sort = {
            "monday": 1,
            "tuesday": 2,
            "wednesday": 3,
            "thursday": 4,
            "friday": 5,
            "saturday": 6,
            "sunday": 7,
            "Montag": 1,
            "Dienstag": 2,
            "Mittwoch": 3,
            "Donnerstag": 4,
            "Freitag": 5,
            "Samstag": 6,
            "Sonntag": 7,
            }
            df_long.sort_values(by="Category", key=lambda x: x.map(dict_sort), inplace=True)

        color_sequence = self.config.get_colors(property, flag_property=True)

        if isinstance(color_sequence, dict):
            color_sequence = [color_sequence[day] for day in df_long['Category'].unique()]

        ## @var fig
        #  A Plotly figure containing the stacked bar chart.
        fig = px.bar(df_long,
             x='Anzahl',
             y=df_long.index,
             color='Category',
             orientation='h',  # Horizontal bar chart
             color_discrete_sequence=color_sequence
        )

        # Layout options for the stacked bar chart
        fig.update_layout(
            barmode='stack',
            xaxis_title="Anzahl Ganglinien",
            yaxis_title="Cluster ID",
            legend=dict(
                x=0.99, y=0.99,  # Position: Top-right
                xanchor="right", yanchor="top",
                title=property,
                borderwidth=1
            )
        )

        # Formatting axes to ensure clean and readable layout
        fig.update_xaxes(showline=True, linewidth=0.5, linecolor='black', mirror=True)
        fig.update_yaxes(showline=True, linewidth=0.5, linecolor='black', mirror=True,
                         type="category", categoryorder='total descending')

        return fig


    ## @brief Plots the time series data grouped by clusters.
    #  @param fig Optional existing figure to add the plot to.
    #  @param row_subplot Row index for subplot.
    #  @param col_subplot Column index for subplot.
    #  @param dict_color Optional dictionary to define colors by cluster.
    #  @return A plotly Figure object with the data series plot added.
    def plot_data_series(self, fig=None, row_subplot: int = 1, col_subplot: int = 1):
        if fig is None:
            fig = go.Figure()

        # Define or use provided dictionary to determine line colors for each cluster
        dict_color = self._get_cluster_colors()

        # Track clusters already added to the legend
        cluster_in_legend = set()

        df_plot = self.data.copy()
        df_plot["series"] = "Originale Ganglinien"
        df_plot["cluster"] = self.clusters.values
        df_plot.sort_values(by=["cluster"], inplace=True)
        df_plot = pd.melt(df_plot.reset_index(names=["index"]), id_vars=["index", "cluster", "series"],
                          value_vars=df_plot.columns.to_list(),
                          var_name="index_series"   # Spaltennamen/Index
                          )

        # Add each cluster's data series to the plot
        for label, group in df_plot.groupby(["index"], sort=False):
            cluster = group['cluster'].iloc[0]
            cluster_label = f"Cluster {cluster} (n={self.cluster_properties.loc[cluster, 'counts']})"
            show_legend = cluster_label not in cluster_in_legend

            list_hover = []
            list_hover.append(group["index"].dt.strftime("%d.%m.%Y"))

            if hasattr(self, "series_cs") and self.series_cs is not None:
                # Erstelle Dictionary für schnellen Lookup
                lookup = {val: idx for idx, lst in self.series_cs.items() for val in lst}
                group.loc[:, "rmq"] = group["index_series"].map(lookup)

                for indicator in ["TV", "avg"]:
                    series_indicator = self.indicators_data[indicator].loc[label, :].T.squeeze(axis=1)
                    mapped_series = group["rmq"].map(series_indicator)
                    mapped_series.name = indicator
                    list_hover.append(mapped_series)

            list_hover.append(pd.Series(round(group["value"].mean(), 0), index=group.index, name="Ø q Netzganglinie"))
            df_hover = pd.concat(list_hover, axis=1)

            df_hover.rename(columns={
                "avg": "Ø q Ganglinie RMQ"
            }, inplace=True)

            self._add_trace_to_fig(fig, group, cluster, show_legend, dict_color, row_subplot=row_subplot,
                                   col_subplot=col_subplot, add_hoverdata=df_hover)

            cluster_in_legend.add(cluster_label)

        if has_subplots(fig):
            # fig.update_xaxes(title_text="Zählintervallindex Ganglinie [-]", row=row_subplot, col=col_subplot)
            fig.update_yaxes(title_text="Werte der Ganglinien", row=row_subplot, col=col_subplot)
        else:
            fig.update_layout(
                xaxis_title="Zählintervallindex Ganglinie [-]",
                yaxis_title="Werte der Ganglinien",
            )

        return fig


    ## @brief Plots the representative series for each cluster.
    #  @param fig Optional existing figure to add the plot to.
    #  @param row_subplot Row index for subplot.
    #  @param col_subplot Column index for subplot.
    #  @param dict_color Optional dictionary to define colors by cluster.
    #  @param scale_width Boolean flag to adjust line width based on cluster size.
    #  @return A plotly Figure object with the representative series plot added.
    def plot_cluster_series(self, fig=None, row_subplot: int = 1, col_subplot: int = 1, dict_color=None,
                            scale_width: bool = False):
        show_legend = False

        if fig is None:
            fig = go.Figure()
            show_legend = True

        # Define or use provided dictionary to determine line colors for each cluster
        dict_color = self._get_cluster_colors()

        df_plot = self.representative_series.copy()
        df_plot["series"] = "Repräsentative Clusterganglinien"
        df_plot["cluster_num"] = df_plot.index
        df_plot.sort_values(by=["cluster"], inplace=True)
        df_plot = pd.melt(df_plot.reset_index(names=["index"]), id_vars=["index", "cluster_num", "series"],
                          value_vars=df_plot.columns.to_list(),
                          var_name="index_series")

        series_width = self._determine_series_width(scale_width)

        for label, group in df_plot.groupby(["index"], sort=False):
            cluster = group["cluster_num"].iloc[0]

            list_hover = []
            list_hover.append(pd.Series(f"Cluster {cluster}", index=group.index, name="Cluster"))

            if hasattr(self, "series_cs") and self.series_cs is not None:
                # Erstelle Dictionary für schnellen Lookup
                lookup = {val: idx for idx, lst in self.series_cs.items() for val in lst}
                group.loc[:, "rmq"] = group["index_series"].map(lookup)

                for indicator in ["TV", "avg"]:
                    series_indicator = self.indicators_clusters[indicator].loc[label, :].T.squeeze(axis=1)
                    mapped_series = group["rmq"].map(series_indicator)
                    mapped_series.name = indicator
                    list_hover.append(mapped_series)

            list_hover.append(pd.Series(round(group["value"].mean(), 0), index=group.index, name="Ø q Netzganglinie"))
            df_hover = pd.concat(list_hover, axis=1)


            self._add_trace_to_fig(fig, group, cluster, show_legend, dict_color, row_subplot=row_subplot,
                                   col_subplot=col_subplot, width=series_width[cluster], add_hoverdata=df_hover)

        if has_subplots(fig):
            fig.update_xaxes(title_text="Zählintervallindex Ganglinie [-]", row=row_subplot, col=col_subplot)
            fig.update_yaxes(title_text="Werte der Cluster", row=row_subplot, col=col_subplot)
        else:
            fig.update_layout(
                xaxis_title="Zählintervallindex Ganglinie [-]",
                yaxis_title="Werte der Cluster",
            )

        return fig

    ## @brief Plots a heatmap of clusters against calendar weeks with color coding.
    #
    # This method creates a calendar-style heatmap where each cell represents a
    # cluster assignment for a specific day in a given calendar week. The colors
    # indicate different clusters, and additional information is displayed via hover text.
    #
    # @param flag_show_value Boolean flag to control whether to display the cluster values in the cells.
    # @param flag_show_border Boolean flag to control whether to display cell borders.
    # @return A Plotly Figure object representing the calendar cluster plot.
    def plot_calendar_cluster(self, flag_show_value:bool=False, flag_show_border:bool=False):
        """Erstellt eine Kalender-Heatmap mit Clusterfarben."""

        ## @var dict_color
        #  A dictionary mapping cluster labels to colors.
        dict_color = self._get_cluster_colors()

        # ## @var colorscale
        # #  A color scale for Plotly based on the cluster mappings.
        if -1 in dict_color.keys():
            colorscale = [[(cluster + 1) / len(dict_color), color] for cluster, color in dict_color.items()]
        else:
            colorscale = [[(cluster - 1) / (len(dict_color) - 1), color] for cluster, color in dict_color.items()]


        ## @var df_plot
        #  A DataFrame containing cluster assignments and corresponding calendar attributes.
        df_plot = self.clusters.to_frame(name="cluster")
        df_plot.loc[:, "day"] = df_plot.index.day_name()  # Extracts day names
        df_plot.loc[:, "day_no"] = df_plot.index.weekday  # Numerical representation of weekdays
        df_plot.loc[:, "year"] = df_plot.index.isocalendar().year
        df_plot.loc[:, "week"] = df_plot.index.isocalendar().week  # ISO calendar week
        df_plot.loc[:, "calendar_week"] = "CW " + df_plot["week"].astype(str)  + " " + df_plot["year"].astype(str)#  Format week labels

        # Label clusters with counts
        df_plot.loc[:, "label"] = df_plot.index.date.astype(str) + \
                                      ", Cluster " + df_plot["cluster"].astype(str) + \
                                  " (n=" + df_plot["cluster"].replace(self.cluster_properties["counts"]).astype(str) + ")"

        # Sort by day number and week (descending)
        df_plot.sort_values(["year", "day_no", "week"], inplace=True, ascending=[False, True,  False])

        # Translate day names and calendar week labels if language is German
        if self.language == "de":
            df_plot.loc[:, "day"] = df_plot["day"].replace({
                "Monday": "Montag",
                "Tuesday": "Dienstag",
                "Wednesday": "Mittwoch",
                "Thursday": "Donnerstag",
                "Friday": "Freitag",
                "Saturday": "Samstag",
                "Sunday": "Sonntag"
            })
            df_plot.loc[:, "calendar_week"] = df_plot["calendar_week"].str.replace("CW", "KW")

        ## @var fig
        #  A Plotly Figure object representing the calendar heatmap.
        fig = go.Figure(data=go.Heatmap(
            z=df_plot["cluster"],   # Cluster assignments
            x=df_plot["day"],       # X-axis: Weekdays
            y=df_plot["calendar_week"],  # Y-axis: Calendar weeks
            text=df_plot["label"],  # Labels for hover text
            colorscale=colorscale,  # Cluster colors
            showscale=False, 
            texttemplate="%{z}" if flag_show_value else None,  # Show Z-values if flag is True
            textfont={"size": 12},
            xgap=2 if flag_show_border else 0,  # Add horizontal gap between cells if flag_show_border is True
            ygap=2 if flag_show_border else 0))

        # Layout adjustments
        fig.update_layout(
            xaxis={'side': 'top'},
            template="simple_white",
            font_family="Arial",
            font_size=14
        )
        fig.update_xaxes(showline=True, linewidth=0.5, linecolor='black', mirror=True)
        fig.update_yaxes(showline=True, linewidth=0.5, linecolor='black', mirror=True)

        # Language-specific axis labels
        if self.language == "de":
            fig.update_layout(
                title="Kalenderdarstellung Cluster",
                xaxis_title="Wochentage",
                yaxis_title="Kalenderwochen",
            )

        return fig


    ## @brief Plots a silhouette diagram based on the calculated silhouette values.
    #
    # This method generates a silhouette plot, which visualizes how well data points fit
    # within their assigned clusters. The silhouette score ranges from -1 (misclassified)
    # to 1 (well-clustered). The plot includes color-coded bars for each cluster and
    # background shading indicating different silhouette score ranges.
    #
    # @return A Plotly Figure object representing the silhouette plot.
    def plot_silhouette(self):
        """Erstellt ein Silhouettendiagramm basierend auf den berechneten Silhouettenwerten."""

        if self.distance_matrix is None:
            self._calculate_distance_matrix(return_vector=False)

        ## @var silhouette_values
        #  A Series containing the silhouette scores sorted in ascending order.
        if not hasattr(self, "series_silhouette"):
            self._calculate_silhouette()

        silhouette_values = self.series_silhouette.sort_values()

        ## @var cluster_labels
        #  A Series containing the cluster labels sorted in the same order as `silhouette_values`.
        cluster_labels = self.clusters.loc[silhouette_values.index]
        unique_clusters = np.unique(cluster_labels)

        ## @var dict_color
        #  A dictionary mapping cluster labels to colors.
        dict_color = self._get_cluster_colors()

        fig = go.Figure()
        dist_cluster_plot = 0
        y_lower = dist_cluster_plot # Initial y-position for the first cluster

        # Plot silhouette values for each cluster
        for cluster in unique_clusters:
            cluster_silhouette_values = silhouette_values[cluster_labels == cluster]
            size_cluster = cluster_silhouette_values.shape[0]
            y_upper = y_lower + size_cluster

            ## @var hover_texts
            #  A list of hover tooltips displaying the silhouette score and index for each point.
            hover_texts = [f"ID: {idx}<br>Silhouette: {val:.2f}" for idx, val in
                           zip(cluster_silhouette_values.index.date, cluster_silhouette_values)]

            fig.add_trace(go.Bar(
                x=cluster_silhouette_values,
                y=np.arange(y_lower, y_upper),
                marker=dict(color=dict_color[cluster]),
                name=f"Cluster {cluster}",
                orientation="h",
                text=hover_texts,  # Setzt die Hover-Information
                hoverinfo="text",
                textposition="none"  # Verhindert direkte Anzeige des Textes
            ))

            y_lower = y_upper + dist_cluster_plot  # Abstand zwischen Clustern

        # Hintergrundbalken für die Strukturierung
        structure_zones = [
            {"min": 0.75, "max": 1, "color": "rgba(0,255,0,0.1)", "label": "Stark"},
            {"min": 0.5, "max": 0.75, "color": "rgba(255,255,0,0.1)", "label": "Mittel"},
            {"min": 0.25, "max": 0.5, "color": "rgba(255,165,0,0.1)", "label": "Schwach"},
            {"min": 0, "max": 0.25, "color": "rgba(255,0,0,0.1)", "label": "Keine Struktur"},
            {"min": -1, "max": 0, "color": "rgba(255,0,0,0.1)", "label": "Potenziell falsche Zuordnung"},
        ]

        for zone in structure_zones:
            fig.add_shape(
                type="rect",
                x0=zone["min"], x1=zone["max"], y0=0, y1=len(silhouette_values),
                fillcolor=zone["color"], opacity=0.3, line_width=0.5
            )
            fig.add_annotation(
                x=(zone["min"] + zone["max"]) / 2,
                y=len(silhouette_values) + 10,
                text=zone["label"],
                showarrow=False,
                font=dict(size=12)
            )

        fig.update_layout(
            title="Silhouettendiagramm der Ganglinien je Cluster",
            xaxis_title="Silhouettenwert",
            yaxis_title="Datenpunkte",
            showlegend=True,
            template="simple_white",
            font_family="Arial",
            font_size=14,
            separators=",."
        )
        fig.update_xaxes(showline=True, linewidth=0.5, linecolor='black', mirror=True, range=[-1, 1], dtick=0.25)
        fig.update_yaxes(showline=True, linewidth=0.5, linecolor='black', mirror=True)

        fig = format_diagrams(fig, self.language,n_dec_x=2)

        return fig


    ## @brief Plots a hierarchical clustering dendrogram.
    #
    # This method generates a hierarchical clustering dendrogram using Plotly,
    # where branches are grouped by cluster. The legend only displays the final clusters.
    #
    # @return A Plotly Figure object representing the dendrogram.
    def plot_dendrogramm(self):
        """
        Erstellt ein Dendrogramm mit Plotly und gruppiert die Traces nach Cluster,
        sodass in der Legende nur die resultierenden Cluster angezeigt werden.
        """

        if self.method == "kmeans":
            logging.warning("Keine hierarchische Clustermethode, Dendrogramm nicht vorhanden")
            return go.Figure()

        if not hasattr(self, "linkage_matrix"):
            logging.warning("Keine Clusterung durchgeführt, Dendrogramm nicht vorhanden")
            return go.Figure()

        # Berechne das Dendrogramm (ohne es mit Matplotlib zu plotten!)
        dendro = dendrogram(self.linkage_matrix, no_plot=True)

        # Extrahiere die Koordinaten für das Plotly-Format
        icoord = np.array(dendro["icoord"])  # x-Koordinaten der Verbindungslinien
        dcoord = np.array(dendro["dcoord"])  # y-Koordinaten (Höhe der Cluster)
        leaves = np.array(dendro["leaves"])  # Reihenfolge der Blätter

        # Farben für die Cluster bestimmen

        color_map = self._get_cluster_colors()

        fig = go.Figure()
        added_clusters = set()  # Speichert bereits in die Legende aufgenommene Cluster

        # Linien für jede Clusterverbindung erstellen
        for i in range(len(icoord)):
            # Cluster-Index bestimmen
            leaf1, leaf2 = int(icoord[i][1] // 10), int(icoord[i][2] // 10)
            cluster_id = self.clusters.iloc[leaves[leaf1]]  # Cluster des ersten Punktes
            color = color_map[cluster_id]

            # Legende nur einmal pro Cluster anzeigen
            show_legend = cluster_id not in added_clusters
            added_clusters.add(cluster_id)

            # Linie hinzufügen
            fig.add_trace(go.Scatter(
                x=icoord[i],  # X-Werte
                y=dcoord[i],  # Y-Werte (Clusterhöhe)
                mode="lines",
                line=dict(color=color, width=2),
                hoverinfo="y",
                name=f"Cluster {cluster_id}",  # Clustername für die Legende
                legendgroup=f"Cluster {cluster_id}",  # Gruppierung der Linien
                showlegend=show_legend  # Nur ein Eintrag pro Cluster in der Legende anzeigen
            ))

        # Falls Cutoff-Wert gesetzt, horizontale Linie hinzufügen
        if self.cutoff is not None:
            cutoff_y = 1 - self.cutoff if "sqv" in self.distance_function else self.cutoff
            fig.add_hline(y=cutoff_y, annotation_text="CutOff",
                          line=dict(color="black", width=2))

        # Plot-Layout optimieren
        fig.update_layout(
            xaxis=dict(showline=True, linewidth=0.5, linecolor='black', mirror=True, showticklabels=False),
            yaxis=dict(
                title=f"Distanz ({self.distance_function})"
                if "sqv" not in self.distance_function else f"1 - Distanz ({self.distance_function})",
                showline=True, linewidth=0.5, linecolor='black', mirror=True),
            template="simple_white",
            font_family="Arial",
            legend=dict(title="Cluster"),
        )

        fig = format_diagrams(fig, self.language, n_dec_y=2)

        return fig


    ## @brief Plots a heatmap of the distance matrix.
    #
    # This method visualizes the distance matrix before and after sorting by cluster assignment.
    #
    # @return A Plotly Figure object containing the heatmap of distances.
    def plot_distances(self):
        if not hasattr(self, "distance_matrix"):
            raise AttributeError("Zuerst Clusterung ausführen")

        ## @var colormap
        #  The color map used for the heatmap (depends on the selected distance function).
        colormap = "spectral" if "sqv" in self.distance_function else "spectral_r"

        idx_sorted_cluster = self.clusters.sort_values().index

        fig = make_subplots(rows=2, cols=1,
                            shared_xaxes=False,
                            subplot_titles=[
                                "Abstandsmatrix, Ganglinien nach Datum sortiert",
                                "Abstandsmatrix, Ganglinien nach Clusterzugehörigkeit sortiert"],
                            vertical_spacing=0.1)

        fig.add_trace(go.Heatmap(
            z=self.distance_matrix.values,
            x=self.distance_matrix.columns,
            y=self.distance_matrix.index,
            colorscale=colormap,
            colorbar=dict(title=f"{self.distance_function}"),
        ), row=1, col=1)

        mtx_sorted = self.distance_matrix.loc[idx_sorted_cluster, idx_sorted_cluster].reset_index(drop=True)
        mtx_sorted.columns = mtx_sorted.index

        fig.add_trace(go.Heatmap(
            z=mtx_sorted.values,
            x=mtx_sorted.columns,
            y=mtx_sorted.index,
            colorscale=colormap,  # Alternativen: "Cividis", "Blues", "RdBu"
            colorbar=dict(title=f"{self.distance_function}",
                          ),
        ), row=2, col=1)

        fig.update_layout(
            template="simple_white",
            font=dict(family="Arial", size=14),
            separators=",."
        )
        fig.update_xaxes(showline=True, linewidth=0.5, linecolor='black', mirror=True, row=[1, 2], col=1)
        fig.update_yaxes(showline=True, linewidth=0.5, linecolor='black', mirror=True, row=[1, 2], col=1)

        return fig


    def update_colors_diagram(self, fig=None, plottype: str="series", name: str="Cluster"):
        """
        Updates the colors in a diagram without recreating it.

        Args:
            fig: The figure to update. If None, returns None.
            plottype: The type of plot to update ('series', 'calendar', 'silhouette', 'dendrogram', 'property', 'distances').
            name: The name of the color map to use.

        Returns:
            The updated figure or None if fig is None.
        """
        if fig is None:
            logging.warning("No figure provided to update_colors_diagrams")
            return None

        # Get updated colors from configuration
        if plottype in ["series", "silhouette", "dendrogram"]:
            # Get cluster colors
            dict_color = self._get_cluster_colors()

            # Update colors in traces
            for trace in fig.data:
                if "Cluster" in trace.name:
                    cluster = int(trace.name.split(" ")[1])
                    if cluster in dict_color:
                        trace.line.color = dict_color[cluster]

        elif plottype == "calendar":
            # Get cluster colors
            dict_color = self._get_cluster_colors()

            # Create new colorscale
            if -1 in dict_color.keys():
                colorscale = [[(cluster + 1) / len(dict_color), color] for cluster, color in dict_color.items()]
            else:
                colorscale = [[(cluster - 1) / (len(dict_color) - 1), color] for cluster, color in dict_color.items()]

            # Update colorscale in heatmap
            for trace in fig.data:
                if isinstance(trace, go.Heatmap):
                    trace.colorscale = colorscale

        elif plottype == "property":
            # Get property colors
            property_colors = self.config.get_colors(name=name, flag_property=True)

            if isinstance(property_colors, list):
                attribute_values = sorted([trace.name for trace in fig.data])

                #  A dictionary mapping each cluster label to a unique color.
                property_colors = {c: property_colors[i % len(property_colors)] for i, c in enumerate(attribute_values)}

            # Update colors in traces
            for trace in fig.data:
                if trace.name in property_colors:
                    trace.marker.color = property_colors[trace.name]

        elif plottype == "distances":
            # Get colorscale for distances
            colorscale = self.config.get_colorscale(name=name)

            # Update colorscale in heatmap
            for trace in fig.data:
                if isinstance(trace, go.Heatmap):
                    trace.colorscale = colorscale

        else:
            logging.error(f"Unknown plottype {plottype}")


        logging.info("Update Farben abgeschlossen")
        return fig






    ## @brief Adds a line trace to a Plotly figure for a given cluster.
    #
    # @param fig The Plotly figure to modify.
    # @param group The DataFrame group containing the cluster data.
    # @param cluster The cluster ID.
    # @param show_legend Boolean flag indicating whether to show the legend entry.
    # @param dict_color Dictionary mapping cluster IDs to colors.
    # @param row_subplot The subplot row index.
    # @param col_subplot The subplot column index.
    # @param width The width of the line.
    def _add_trace_to_fig(self, fig, group, cluster, show_legend, dict_color, row_subplot=1, col_subplot=1, width=1,
                          add_hoverdata: pd.DataFrame=None):

        hovertemplate = "<b>%{customdata[0]}</b><br>X-Wert: %{x}<br>Y-Wert: %{y:.2f}<br>"  # Hover-Text
        # ggf weitere Daten adden
        if add_hoverdata is not None:
            str_data ="<br>".join([ f"{col}: %" + "{customdata[" + str(k+1) +"]:.0f}" for k, col in enumerate(add_hoverdata.columns[1:])])
            hovertemplate += str_data
        hovertemplate += "<extra></extra>"

        if has_subplots(fig):
            fig.add_trace(
                go.Scatter(
                    x=group["index_series"],
                    y=group["value"],
                    mode="lines",
                    name=f"Cluster {cluster}",
                    legendgroup=f"Cluster {cluster}",
                    showlegend=show_legend,
                    line=dict(color=dict_color[cluster], width=width),
                    customdata=add_hoverdata if add_hoverdata is not None else [""] * len(group),
                    hovertemplate=hovertemplate,
                ), row = row_subplot, col = col_subplot)
        else:
            fig.add_trace(
                go.Scatter(
                    x=group["index_series"],
                    y=group["value"],
                    mode="lines",
                    name=f"Cluster {cluster}",
                    legendgroup=f"Cluster {cluster}",
                    showlegend=show_legend,
                    line=dict(color=dict_color[cluster], width=width),
                    customdata=add_hoverdata if add_hoverdata is not None else [""] * len(group),
                    hovertemplate=hovertemplate,
                ))



    ## @brief Determines the width of each cluster line for plotting.
    #
    # The width is scaled based on the relative frequency of each cluster.
    #
    # @param scale_width Boolean flag indicating whether to scale line widths by cluster size.
    # @return A pandas Series containing the line width for each cluster.
    def _determine_series_width(self, scale_width):
        if scale_width:
            max_width = 15  # Maximum line width in plot
            return (self.clusters.value_counts(normalize=True) * max_width).apply(lambda x: max(x, 1))
        else:
            return pd.Series([2] * len(self.clusters.unique()), index=self.clusters.unique())



    ## @brief Calculates the representative series for each cluster using an aggregation function.
    #
    # This method computes a representative time series for each cluster by applying the
    # specified aggregation function (e.g., 'mean', 'median') to the grouped data.
    #
    # @param aggregation_fcn The aggregation function to use ('mean', 'median', 'sum', etc.).
    def _calculate_representative_series(self, aggregation_fcn='mean'):
        if self.clusters.isna().all():
            raise ValueError("No clusters assigned. Run 'perform_clustering()' first.")

        if aggregation_fcn not in ['mean', 'median', 'sum', 'min', 'max']:
            raise ValueError(f"Unknown aggregation function: {aggregation_fcn}")

        # Calculate the representative value for each cluster using the specified aggregation function
        self.representative_series = self.data.groupby(self.clusters).agg(aggregation_fcn)


    ## @brief Evaluates and calculates properties for each cluster.
    #
    # This method calculates the property distributions within each cluster and
    # computes the pairwise distances between the representative series of each cluster.
    def _evaluate_properties_cluster(self):
        ## @var cluster_properties
        #  A DataFrame where each row corresponds to a cluster, and columns contain
        #  properties with their respective proportions in dictionary format.
        self.cluster_properties = self.properties_dates.groupby(self.clusters
                                                                ).agg(lambda x: x.value_counts(normalize=True, dropna=False).to_dict())

        self.cluster_properties.loc[:, "counts"] = self.clusters.value_counts()

        # Compute distances based on the selected distance function
        distance_vector = self._calculate_distance_vector(self.representative_series.values)

        ## @var cluster_dist_matrix
        #  A distance matrix storing the pairwise distances between cluster representatives.
        self.cluster_dist_matrix = pd.DataFrame(squareform(distance_vector),
                                                columns=self.representative_series.index,
                                                index=self.representative_series.index)

        if "sqv" in self.distance_function:
            np.fill_diagonal(self.cluster_dist_matrix.values, 1)


    ## @brief Fills the `properties_dates` DataFrame with consistent property data.
    #
    # This method ensures that all necessary properties are included in `properties_dates`
    # and fills missing values with `False` if properties are not available.
    def _fill_properties_dates(self):
        if len(self.properties.keys()) < 1:
            logging.warning("keine Eigenschaften vorhanden")
            return

        df_properties = self.properties_dates.copy()
        list_append = [df_properties]

        for property in self.properties.keys():
            if property not in df_properties.columns:
                if hasattr(self.calendar, property.lower()):
                    indices = getattr(self.calendar, property.lower())
                    list_indices = []
                    for holiday, dates in indices.items():
                        if isinstance(dates, set):
                            dates = list(dates)
                        list_indices.append({"date": dates, property: holiday})
                    list_append.append(pd.DataFrame(list_indices).explode("date").set_index("date"))
                else:
                    logging.warning(f" Property '{property}' is not existing")

        # Concatenate all property data into a single DataFrame and fill missing values with False
        df_properties = pd.concat(list_append, axis=1).fillna(False)

        self.properties_dates = df_properties

    ## @brief Validates the clustering parameters to avoid invalid settings.
    #
    # This method checks if the selected clustering method, distance function, and
    # other parameters are valid and consistent.
    def _validate_parameters(self):
        valid_methods = {"average", "complete", "single", "centroid", "median", "ward", "kmeans"}
        valid_distances = {"euclidean", "geh", "sqv_counts"}

        if self.method.lower().replace(" linkage", "") not in valid_methods:
            raise ValueError(f"Ungültige Clustering-Methode: {self.method}. Zulässig sind: {', '.join(valid_methods)}.")

        if self.distance_function not in valid_distances:
            raise ValueError(f"Ungültige Distanzfunktion: {self.distance_function}. Erlaubt sind: {', '.join(valid_distances)}.")

        logging.info("Parameterprüfung erfolgreich abgeschlossen.")


    ## @brief Computes the silhouette scores for each data point in the clustering.
    #
    # The silhouette score measures how similar a point is to its assigned cluster
    # compared to other clusters. A higher score indicates better clustering quality.
    def _calculate_silhouette(self):

        if self.distance_matrix is None:
            self._calculate_distance_matrix(return_vector=False)

        series_silhouette = pd.Series(np.inf, index=self.clusters.index)

        # Adjust distance matrix for specific distance functions
        distance_matrix = 1 - self.distance_matrix if "sqv" in self.distance_function else self.distance_matrix

        # Compute silhouette values for each cluster
        for cluster, indices in self.clusters.groupby(self.clusters).groups.items():
            if len(indices) < 2:
                series_silhouette.loc[indices] = 0
            else:
                for ind in indices:
                    # fremdähnlichkeit/separation
                    separation = np.inf # init as inf
                    for cluster_other, indizes_others in self.clusters.groupby(self.clusters).groups.items():
                        if cluster_other == cluster:
                            # Eigenähnlichkeit/cohesion
                            cohesion = distance_matrix.loc[ind, indices[indices != ind]].mean()
                        else:
                            separation = min(separation,
                                             self.distance_matrix.loc[ind, indizes_others].mean())
                    if np.isinf(separation) or (separation == 0 and cohesion == 0):
                        silhouette = 0
                    else:
                        silhouette = (separation - cohesion) / max(cohesion, separation)
                    if np.isnan(silhouette):
                        a=1
                    series_silhouette.loc[ind] = silhouette
                    del cohesion, separation

        self.series_silhouette = series_silhouette

    # Helper function to calculate indicators for a given data source
    def _calculate_indicators_for_data(self, data_source, dict_indicators_calc):
        indicators_dict = {}
        for indicator in dict_indicators_calc.keys():
            # Create DataFrame for this indicator
            indicators_dict[indicator] = pd.DataFrame(index=data_source.index, columns=self.series_cs.keys())

            # Get the indicator function
            indicator_func = dict_indicators_calc[indicator]

            # Apply the indicator function to each set of columns
            results = {key: indicator_func(data_source, value) for key, value in self.series_cs.items()}

            # Handle different return types
            first_key = next(iter(results))
            first_value = results[first_key]



            if isinstance(first_value, pd.DataFrame):
                results_df = pd.concat(results, axis=1)
            else:
                results_df = pd.DataFrame(results, index=data_source.index)

            indicators_dict[indicator] = results_df

        return indicators_dict

    ## @brief Retrieves the maximum internal distances within each cluster.
    #
    # @param flag_element_wise If True, calculates the extreme distances element-wise instead of using the distance matrix.
    # @return A pandas Series containing the maximum distance per cluster.
    def get_max_distances_cluster(self, flag_element_wise: bool = False):
        extrema_cluster = pd.Series(-1, index=self.cluster_properties.index, dtype=float)

        for cluster, indices in self.clusters.groupby(self.clusters).groups.items():
            if len(indices) < 2:
                extrema_cluster.loc[cluster] = 1 if "sqv" in self.distance_function else 0
            else:
                distances_cluster = self.distance_matrix.loc[indices, indices] if not flag_element_wise else {}

                if "sqv" in self.distance_function:
                    extrema_cluster.loc[cluster] = np.min(distances_cluster)
                else:
                    extrema_cluster.loc[cluster] = np.max(distances_cluster)

        return extrema_cluster

    ## @brief Returns information about the current clustering state.
    #
    # This method provides details about the clustering process, including parameters,
    # dataset size, number of clusters, and internal distances.
    #
    # @return A pandas Series containing clustering parameters and state information.
    def get_info(self):
        dict_info = {
            "Methode": self.method,
            "Distanz": self.distance_function,
            "Startdatum": self.data.index.date.min(),
            "Enddatum": self.data.index.date.max(),
            "Max. Anz Cluster": self.max_clusters,
            "CutOff": self.cutoff,
            "Wdh. kmeans": self.kmeans_iter,
            "Start kmeans": self.kmeans_presettings,
            "Anz. Daten": len(self.data),
            "Anz. Cluster": len(self.cluster_properties),
            "max. Clustergröße": self.cluster_properties.counts.max(),
        }

        max_dist_series = self.get_max_distances_cluster()
        max_index = max_dist_series.idxmin() if "sqv" in self.distance_function else max_dist_series.idxmax()
        max_value = max_dist_series.min() if "sqv" in self.distance_function else max_dist_series.max()
        dict_info["max. interne Distanz"] = f"{max_value:.2f} (Cluster {max_index:.0f})"

        return pd.Series(dict_info)

    ## @brief Generates a consistent color mapping for clusters using a Plotly color scale.
    #
    # This function assigns a unique color to each cluster using the `Dark24` color palette
    # (or an alternative, such as Set1, Pastel1, Viridis).
    #
    # @param clusters A list or set of unique cluster labels.
    # @return A dictionary mapping each cluster label to a color.
    def _get_cluster_colors(self):
        """Erstellt eine konsistente Farbzuteilung für Cluster basierend auf einer Plotly-Farbskala."""

        clusters = self.clusters.unique()

        ## @var colors
        colors = self.config.get_colors(name="cluster")

        if isinstance(colors, list) or len(colors) < len(clusters):
            ## @var unique_clusters
            #  A sorted list of unique cluster labels.
            unique_clusters = sorted(set(clusters))

            if isinstance(colors, dict):
                colors = list(colors.values())

            ## @var color_dict
            #  A dictionary mapping each cluster label to a unique color.
            color_dict = {c: colors[i % len(colors)] for i, c in enumerate(unique_clusters)}

            self.config.colors["sequences"]["cluster"] = {
                "type": "sequence",
                "colors": color_dict,
            }
        else:
            color_dict = colors


        return color_dict


    def calculate_series_cs(self):
        # identify number of count stations
        n = self.data.shape[1] / self.n_count_intervals

        if (n % n) > 0:
            logging.warning(f"Number of count stations ({n}) is not an integer. "
                            f"The number of count stations will be rounded down to the nearest integer.")
        else:
            n = int(n)

        # Create a temporary dictionary to store the key-value pairs
        temp_dict = {}

        # Assign indices
        for k in range(n):
            temp_dict[f"RMQ_{k + 1}"] = self.data.columns[k * self.n_count_intervals
                                                          :(k + 1) * self.n_count_intervals]

        # Convert the dictionary to a pandas Series for better lookup functionality
        self.series_cs = pd.Series(temp_dict)


## @brief Checks if the figure has subplots.
#  @param fig The figure to check.
#  @return True if the figure has subplots, otherwise False.
def has_subplots(fig):
    return hasattr(fig, '_grid_ref') and fig._grid_ref is not None


## @brief Formats a Plotly figure based on the language setting.
#
# This function applies localized formatting to the x-axis and y-axis tick labels.
# It supports different decimal formats for German ("de") and English ("en") locales.
#
# @param fig The Plotly figure to format.
# @param language The language setting ('de' for German, otherwise English).
# @param n_dec_x The number of decimal places for the x-axis labels.
# @param n_dec_y The number of decimal places for the y-axis labels.
# @param font_size The font size for the figure text.
# @return The formatted Plotly figure.
def format_diagrams(fig, language, n_dec_x=0, n_dec_y=0, font_size=16):
    """Formatiert die Diagramme basierend auf der Spracheinstellung."""

    # figure_has_subplots = has_subplots(fig)  # Variable hat jetzt einen eindeutigen Namen
    # axes = ["xaxis", "yaxis"] if not figure_has_subplots else [f"xaxis{i}" for i in range(1, 10)] + [f"yaxis{i}" for i
    #                                                                                                  in range(1, 10)]
    # for axis in axes:
    #     axis_obj = getattr(fig.layout, axis, None)
    #
    #     if not axis_obj:
    #         continue  # Falls die Achse nicht existiert, überspringen
    #
    #     tick_vals = getattr(axis_obj, "tickvals", None)
    #
    #     # Falls keine tickvals gesetzt sind, berechne sie basierend auf dem Achsenbereich
    #     if tick_vals is None and hasattr(axis_obj, "range") and axis_obj.range:
    #         tick_min, tick_max = axis_obj.range
    #         num_ticks = 10 # Automatisch ca. 6 Ticks setzen
    #         tick_vals = np.linspace(tick_min, tick_max, num_ticks)
    #
    #     if tick_vals is not None:
    #         n_dec = n_dec_x if "xaxis" in axis else n_dec_y  # Richtige Dezimalstellen wählen
    #
    #         if language == "de":
    #             tick_texts = [f"{v:.,{n_dec}f}".replace(",", "X").replace(".", ",").replace("X", ".") for v in
    #                           tick_vals]
    #         else:
    #             tick_texts = [f"{v:.,{n_dec}f}" for v in tick_vals]
    #
    #         fig.update_layout({axis: dict(tickvals=tick_vals, ticktext=tick_texts, tickfont=dict(size=font_size))})

    #  Dictionary defining the x-axis tick format based on the language.
    if language == "de":
        xaxis_format = dict(tickformat=f",.{n_dec_x}f", tickprefix="", ticksuffix="")
        yaxis_format = dict(tickformat=f",.{n_dec_y}f", tickprefix="", ticksuffix="")
    else:
        xaxis_format = dict(tickformat=f".,{n_dec_x}f", tickprefix="", ticksuffix="")
        yaxis_format = dict(tickformat=f".,{n_dec_y}f", tickprefix="", ticksuffix="")

    #  Boolean indicating whether the figure contains subplots.
    if has_subplots:
        for i in range(1, 3):  # 2 Subplots
            fig.update_layout({f'xaxis{i}': xaxis_format, f'yaxis{i}': yaxis_format}, separators=",.")
    else:
        fig.update_layout(xaxis=xaxis_format, yaxis=yaxis_format, font_size=font_size,
            separators=",."
        )

    return fig
