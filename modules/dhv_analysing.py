## @package dhv_analysing
#  @brief This module provides functionality for analyzing design hourly volumes (DHV).
#
#  The `dhv_analysing` module includes the `DHVAnalysing` class, which performs
#  filtering, calculation, and visualization of design hourly volumes for traffic data.
#  It supports different DHV concepts like nth hour and percentile-based approaches.
#
#  **Main functionalities:**
#  - **Data Filtering:**
#    - `apply_filter()`: Applies filters to the traffic data based on days, hours, and counting stations.
#    - `update_data_dhv()`: Updates the data used for DHV calculations based on applied filters.
#  - **DHV Calculation:**
#    - `calculate_dhv()`: Calculates design hourly volumes based on different concepts.
#    - `get_dict_name_dhv()`: Creates a dictionary with DHV names and parameters.
#  - **Visualization:**
#    - `plot_sorted_volumes_dhv()`: Creates plots of sorted traffic volumes with DHV indicators.
#    - `update_dhv_in_diagram()`: Updates DHV indicators in existing diagrams.
#
#  @author MaS
#  @date 2025
#
#  @note The module requires a valid clustering object with hourly traffic data.

import plotly.express as px
import logging
import pandas as pd
import math

from openpyxl.styles.builtins import title

from modules import indicators


## @class DHVAnalysing
#  @brief Analyzes and visualizes design hourly volumes (DHV) for traffic data.
#
#  The `DHVAnalysing` class provides methods for filtering traffic data,
#  calculating design hourly volumes using different concepts (nth hour, percentile),
#  and visualizing the results in interactive plots.
class DHVAnalysing:
    ## @brief Initializes the DHVAnalysing object.
    #  @param clusterung_obj A clustering object containing traffic data.
    #  @exception ValueError Raised if the number of count intervals is not 24 (hourly data required).
    def __init__(self, clusterung_obj):
        ## @var num_cols_fig
        #  Number of columns in the figure layout.
        self.num_cols_fig = 3

        ## @var clusterung_obj
        #  Reference to the clustering object containing the traffic data.
        self.clusterung_obj = clusterung_obj

        ## @var data
        #  Original traffic data from the clustering object (not affected by filters).
        self.data = clusterung_obj.data     # not affected by filter

        ## @var n_count_intervals
        #  Number of count intervals per day (must be 24 for hourly data).
        self.n_count_intervals = clusterung_obj.n_count_intervals   # not affected by filter

        ## @var series_cs
        #  Time series data for each counting station.
        self.series_cs = clusterung_obj.series_cs   # not affected by filter

        ## @var filter
        #  Dictionary of filter settings for hours, days, clusters, and counting stations.
        self.filter = {"hours": "all",
                       "days": "all",
                       "cluster": "all",
                       "cs": "all",
                       "peak_hours_only": False,
                       }

        ## @var data_for_dhv
        #  Filtered data used for DHV calculations.
        self.data_for_dhv = None

        ## @var set_day_hours
        #  Set of day-hour combinations used in the analysis.
        self.set_day_hours = None

        ## @var n_hours
        #  Number of hours in the filtered dataset.
        self.n_hours = None

        ## @var n_days
        #  Number of days in the filtered dataset.
        self.n_days = None

        ## @var fig
        #  Plotly figure object for visualization.
        self.fig = None

        ## @var dict_dhv
        #  Dictionary storing calculated DHV values.
        self.dict_dhv = dict()

        # Verify that we have hourly data (24 intervals per day)
        if self.n_count_intervals != 24:
            logging.error("only 24h intervals are supported")
            raise ValueError("only 24h intervals are supported")

    ## @brief Resets all filters to their default values.
    #
    #  Clears all filter settings and cached data, then updates the DHV data
    #  without any filtering applied.
    def reset_filter(self):
        self.data_for_dhv = None
        self.set_day_hours = None
        self.n_hours = None
        self.n_days = None

        self.filter = {"hours": "all",
                       "days": "all",
                       "cluster": "all",
                       "cs": "all",
                       "peak_hours_only": False,
                       }

        self.update_data_dhv() # reformat data for dhv calculation without filtering


    ## @brief Applies the current filter settings to the data.
    #
    #  This method is a wrapper for the update_data_dhv method.
    #  It converts the filter information from the filter dictionary to lists
    #  of indices and columns, then calls update_data_dhv with these parameters.
    def apply_filter(self):
        # List of all days (=dates) that are considered as datetime object
        filter_days = None if isinstance(self.filter["days"], str) and  self.filter["days"] == "all" else self.filter["days"]

        # Hour filter: list of day hours 0 - 23 as int
        filter_hours = None if isinstance(self.filter["hours"], str) and  self.filter["hours"] == "all" else self.filter["hours"]

        # Apply cluster filtering to days
        if self.filter["cluster"] is not None and self.filter["cluster"] != "all":
            cluster_days = self.clusterung_obj.clusters[self.filter["cluster"]].index.tolist()

            if filter_days is None:
                filter_days = cluster_days
            else:
                # Combine existing day filter with cluster days (intersection or union depending on requirements)
                filter_days = list(set(filter_days) & set(cluster_days))  # intersection
                # Alternative: filter_days = list(set(filter_days) | set(cluster_days))  # union

        # List of count stations to be included
        filter_cs = None if isinstance(self.filter["cs"], str) and self.filter["cs"] == "all" else self.filter["cs"]

        # Update the data with applied filters
        self.update_data_dhv(
            filter_days=filter_days,
            filter_hours=filter_hours,
            filter_cs=filter_cs
        )


    ## @brief Updates the data used for DHV calculations based on filters.
    #
    #  This method filters the traffic data based on specified days, hours,
    #  and counting stations, then restructures it for DHV calculations.
    #
    #  @param filter_days Optional list of days (as datetime objects) to include.
    #  @param filter_hours Optional list of hours (0-23) to include.
    #  @param filter_cs Optional list of counting station names to include.
    def update_data_dhv(self,
                        filter_days: list = None, filter_hours: list = None,
                        # filter_cluster: list = None,
                        filter_cs: list = None
                        ):
        if not hasattr(self, "series_cs"):
            self.clusterung_obj.calc_cluster_series()
            self.series_cs = self.clusterung_obj.series_cs

        filtered_data = self.data.copy()

        # filtering before restructuring data
        if filter_days is not None:
            filtered_data = filtered_data[filtered_data.index.isin(filter_days)]

        self.n_days = len(filtered_data)

        # if filter_cluster is not None: # included in filter_days
        #     filtered_data = filtered_data[filtered_data.index.isin(filter_cluster)]

        # preparation reformatting data and mapping to count station
        # Alte Spaltennamen merken
        original_columns = filtered_data.columns.tolist()

        # Neue Spaltennamen setzen: 1-based Index
        filtered_data.columns = range(1, len(original_columns) + 1)

        # Neues Mapping: numerischer Spaltenindex → Zählstelle
        # (indem wir den umgekehrten Weg von series_cs gehen)

        # Beispiel: series_cs = pd.Series([['colA', 'colB'], ['colC']], index=['cs1', 'cs2'])
        # → Ziel: {1: 'cs1', 2: 'cs1', 3: 'cs2'}

        # 1. Explodieren mit alter Spaltennamen-Referenz
        exploded = self.series_cs.explode()

        # 2. Mapping: alter Spaltenname → cs
        colname_to_cs = pd.Series(exploded.index.values, index=exploded.values)

        # 3. Jetzt umbenannt: neue Spaltennamen sind 1, 2, ...
        #    Erzeuge neues Mapping: neue Index → cs, über den alten Spaltennamen
        index_to_cs = pd.Series([
            colname_to_cs.get(old_colname) for old_colname in original_columns
        ], index=range(1, len(original_columns) + 1))

        self.data_for_dhv = filtered_data.stack().to_frame(name="value").reset_index(names=["datum", "idx_col"])
        self.data_for_dhv.loc[:, "cs"] =  self.data_for_dhv.idx_col.map(index_to_cs)
        self.data_for_dhv.loc[:, "hour"] = (self.data_for_dhv.idx_col - 1) % self.n_count_intervals

        # filtering after restructuring data
        if filter_hours is not None:
            self.data_for_dhv = self.data_for_dhv.loc[self.data_for_dhv.hour.isin(filter_hours), :]

        self.set_day_hours = set(self.data_for_dhv.hour.unique().tolist())
        self.n_hours = len(self.set_day_hours) * self.n_days

        if filter_cs is not None:
            self.data_for_dhv = self.data_for_dhv.loc[self.data_for_dhv.cs.isin(filter_cs), :]

        self.n_cs = len(self.data_for_dhv.cs.unique())

        # add n for each value
        self.data_for_dhv.sort_values(["value"], ascending=[False], inplace=True)
        self.data_for_dhv.loc[:, "n"] = self.data_for_dhv.groupby(["cs"]).cumcount() + 1
        self.data_for_dhv.loc[:, "cluster"] = self.data_for_dhv.datum.map(self.clusterung_obj.clusters).astype("category")


    def plot_sorted_volumes_dhv(self, min_height_cm: int=5, plot_height=None):
        """Plot design hourly volumes"""

        if self.data_for_dhv is None:
            self.update_data_dhv()

        min_height_px = min_height_cm * 37.8
        height_px = min_height_px * math.ceil(self.n_cs / self.num_cols_fig)
        if plot_height is not None:
            height_px = max(plot_height, height_px)

        color_map = self.clusterung_obj._get_cluster_colors()
        # color_map = {str(k): v for k, v in  self.clusterung_obj._get_cluster_colors().items()}

        self.data_for_dhv.sort_values(["cluster", "cs"], inplace=True)

        self.fig = px.scatter(self.data_for_dhv, x = "n", y="value", facet_col="cs",
                           color="cluster", color_discrete_map=color_map,
                                facet_col_wrap=self.num_cols_fig, facet_row_spacing=0.025, facet_col_spacing=0.025,
                           height= height_px)

        # Anpassung der Logarithmischen X-Achse und der Layout-Einstellungen
        # Definiere die Haupttickwerte (1, 10, 100, 1000, 10000)
        main_ticks = [1, 10, 100, 1000, 10000]

        # Definiere die Zwischenwerte (2-9, 20-90, etc.)
        intermediate_ticks = [2, 3, 4, 5, 6, 7, 8, 9,
                              20, 30, 40, 50, 60, 70, 80, 90,
                              200, 300, 400, 500, 600, 700, 800, 900,
                              2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000]

        # Alle Tick-Werte zusammenfügen (beschriftete und unbeschriftete)
        all_ticks = main_ticks + intermediate_ticks
        all_ticks.sort()

        # Beschriftung nur für Hauptticks
        tick_labels = [f"{t}" if t in main_ticks else "" for t in all_ticks]

        self.fig.update_layout(template="plotly_white",
                               title="Dauerlinien gefilterte Stunden",
                          separators=",.")

        # X-Achse anpassen (logarithmisch) mit Hauptticks und unbeschrifteten Zwischenticks
        self.fig.update_xaxes(
            type="log",  # Logarithmische Skala
            tickvals=all_ticks,
            ticktext=tick_labels,  # Nur Hauptticks werden beschriftet
            showgrid=True, gridwidth=1, gridcolor='lightgray',
            showline=True, linewidth=2, linecolor='black',
        )
        self.fig.update_yaxes(
            title = "Wert",
            showgrid=True, gridwidth=1, gridcolor='lightgray',
            showline=True, linewidth=2, linecolor='black',
        )

        self.fig.for_each_annotation(lambda a: a.update(text=a.text.split("=")[-1]))
        self.fig.for_each_xaxis(lambda xaxis: xaxis.update(showticklabels=True))

        # self.fig.show()



    def update_dhv_in_diagram(self, list_dhv: list=None, **kwargs):

        # bisherige shapes löschen, um doppelte Linien zu vermeiden
        self.delete_hlines_dhv()

        if list_dhv is None:
            list_dhv = self.dict_dhv.keys()

        for dhv in list_dhv:
            if dhv in self.dict_dhv.keys():
                logging.info(f"dhv {dhv} already exists")
            else:
                dhv = self.calculate_dhv(dhv, **kwargs)

            if dhv is None:
                continue

            for idx_cs, cs in enumerate(self.data_for_dhv.cs.unique()):
                # idx_cs = idx_cs + 1
                # row = ((idx_cs - 1) // self.num_cols_fig) + 1
                # col = ((idx_cs - 1) % self.num_cols_fig) + 1
                row = int(math.ceil(self.n_cs / self.num_cols_fig)) - int(math.floor(idx_cs / self.num_cols_fig))
                col = int(idx_cs % self.num_cols_fig) + 1
                try:
                    q = self.dict_dhv[dhv].loc[cs]
                except KeyError:
                    logging.error(f"cs {cs} not found in dhv {dhv}")
                    continue
                self.fig.add_hline(y=q, row=row, col=col,
                                   annotation_text=f"{', '.join(dhv)}: q={q:.0f}",
                                   annotation_position="top left",
                                   line_color="black", line_width=1, name=f"{dhv}_{cs}",
                                   annotation=dict(font=dict(size=10))
                                   )
        logging.info(f"{list_dhv} im Diagramm hinzugefügt")

    def calculate_dhv(self, name_dhv_concept, **kwargs):

        name_tup = self.get_dict_name_dhv(name_dhv_concept, **kwargs)

        if name_tup in self.dict_dhv.keys():
            logging.warning(f"{','.join(name_tup)} existiert bereits, wird überschrieben")

        # series_dhv_cs = pd.Series(index=self.series_cs.index)
        if name_dhv_concept in ["n-th_hour", "n. Stunde", "n-te Stunde"]:
            if "n" in kwargs.keys():
                series_dhv_cs = self.data_for_dhv.groupby("cs").apply(indicators.q_nth_hour, kwargs["n"])
            else:
                series_dhv_cs = self.data_for_dhv.groupby("cs").apply(indicators.q_nth_hour)
        # elif name_dhv_concept in ["mean_peak_hour"]:
        elif name_dhv_concept in ["Perzentil", "percentile"]:
            if "p" in kwargs.keys():
                series_dhv_cs = self.data_for_dhv.groupby("cs").apply(indicators.q_percentile, kwargs["p"])
            else:
                series_dhv_cs = self.data_for_dhv.groupby("cs").apply(indicators.q_percentile)

        else:
            logging.error(f"{name_dhv_concept} ist nicht implementiert")
            return

        self.dict_dhv[name_tup] = series_dhv_cs.sort_index()
        return name_tup

    def delete_hlines_dhv(self, dhv: str = None):
        """
        Löscht horizontale Linien (Shapes vom Typ 'line') aus der Figur.
        Wenn 'dhv' spezifiziert ist, werden nur Linien gelöscht, deren Name
        mit dem Muster 'hline_{dhv}_*' beginnt.
        Wenn 'dhv' None ist, werden alle Shapes vom Typ 'line' gelöscht.
        """
        shapes_to_keep = []
        for shape in self.fig.layout.shapes:
            if (dhv is None) or (hasattr(shape, 'name') and shape.name.startswith(f"{dhv}")):
                # löschen = nicht behalten
                continue
            else:
                shapes_to_keep.append(shape)

        # Annotations (Texte) löschen
        annotations_to_keep = []
        for annotation in self.fig.layout.annotations:
            # Prüfen ob die Annotation zu einer DHV-Linie gehört
            # (Plotly erstellt automatisch Annotationen für add_hline mit annotation_text)
            if (hasattr(annotation, 'text') and annotation.text and f"{dhv}=" in annotation.text):
            # DHV-spezifische Annotation über Text-Inhalt identifizieren
                continue
            elif (hasattr(annotation, 'name') and annotation.name and annotation.name.startswith(f"{dhv}")):
            # DHV-spezifische Annotation über Name identifizieren
                continue
            else:
                annotations_to_keep.append(annotation)

        # Listen aktualisieren
        self.fig.layout.shapes = shapes_to_keep
        self.fig.layout.annotations = annotations_to_keep

    def get_dict_name_dhv(self, name_dhv_concept, **kwargs):
        # series_dhv_cs = pd.Series(index=self.series_cs.index)
        if name_dhv_concept in ["n-th_hour", "n. Stunde", "n-te Stunde"]:
            if "n" in kwargs.keys():
                name_tup = (name_dhv_concept, f"n={kwargs['n']}", f"#h={self.n_hours}")
            else:
                name_tup = (name_dhv_concept, f"n={50}", f"#h={self.n_hours}")
        elif name_dhv_concept in ["Perzentil", "percentile"]:
            if "p" in kwargs.keys():
                name_tup = (name_dhv_concept, f"p={kwargs['p']}", f"#h={self.n_hours}")
            else:
                name_tup = (name_dhv_concept, f"p={99.4}", f"#h={self.n_hours}")
        else:
            logging.error(f"dhv concept {name_dhv_concept} not supported")
            return

        return name_tup
