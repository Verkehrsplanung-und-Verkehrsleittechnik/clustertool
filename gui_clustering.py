## @package gui_clustering
#  @brief Provides a graphical user interface (GUI) for time-series clustering analysis.
#
#  The `gui_clustering` module integrates wxPython for GUI elements and Plotly for visualization.
#  It allows users to load time-series data, configure clustering parameters, run clustering
#  algorithms, and analyze the results interactively.
#
#  **Main functionalities:**
#  - Load time-series data from CSV, Excel, or MATLAB files.
#  - Apply hierarchical clustering or k-means clustering.
#  - Visualize results (dendrograms, silhouette plots, calendar views).
#  - Export clustering results in JSON, CSV, and Excel formats.
#  - Interactive analysis with filters and customizable plots.
#
#  @author MaS, based on Matlab Clustertool, supported by GPT
#  @date 2025
#  @note The module requires `wxPython` and `plotly` for GUI and visualization.


import numpy as np
import wx
from wx.html2 import WebView
import wx.adv
import wx.dataview as dv
import plotly.graph_objects as go

import os
import logging
from pathlib import Path
import markdown

import pandas as pd
import modules
import gui_bemessung

# Instanz ConfigManager
from modules.data_handler import config_manager


## @class ClusterGUI
#  @brief Main application window for clustering analysis.
#
#  The `ClusterGUI` class provides a wxPython-based GUI for loading data, configuring clustering
#  algorithms, running cluster analysis, and visualizing results.
class ClusterGUI(wx.Frame):
    ## @brief Initializes the main GUI window.
    #  @param parent Parent window (default: None).
    def __init__(self, style=wx.DEFAULT_FRAME_STYLE):
        super().__init__(None)

        ## @var config_manager
        #  Reference to the configuration manager.
        self.config_manager = config_manager

        ## @var temp_files
        # tracks temporary file names for deletion
        self.temp_files = []

        ## @var clusterer
        #  Stores the active clustering object.
        self.clusterer = None

        ## @var cluster_data
        #  Stores the loaded time-series data.
        self.cluster_data = None

        ## @var properties_data
        #  Stores additional attributes for clustering.
        self.properties_data = None

        ## @var calendar_obj
        #  Stores the calendar object used for time-based clustering.
        self.calendar_obj = None

        ## @var cluster_analyses
        #  Dictionary to store multiple clustering results.
        self.cluster_analyses = {}

        ## @var default_property
        #  Default property used for cluster visualization (e.g., "Wochentag").
        self.default_property = self.config_manager.config['gui']['default_property']

        ## @var button_handlers
        #  Dictionary that maps button labels to their respective event handlers.
        self.button_handlers = {
            "Hilfe": self.on_help,
            "Clusterung ausführen": self.on_clusteranalysis,
            "Clusterung löschen": self.on_delete_cluster,
            "Distanzmatrix der Ganglinien": self.on_distancematrix,
            "Silhouettendiagramm": self.on_plot_silhouette,
            "Dendrogramm": self.on_plot_dendrogramm,
            "Clusterkalender": self.on_cluster_calendar,
            "Export Clusterung": self.on_export_data,
            "Export alle Clusterungen": self.on_export_all_data,
            "Export Diagramme": self.on_export_diagrams,
            "Datei Clusterung öffnen": self.on_open_data,
            "Datei öffnen": self.on_open_properties,
            "Trennlinien aktualisieren": self.on_update_vertical_lines,
        }

        ## @var buttons
        #  List of all buttons in the GUI.
        self.buttons = []

        ## @var checkboxes_calendar
        #  List of checkboxes for calendar-based filtering.
        self.checkboxes_calendar = []

        # Create & Initialize GUI components
        self.__set_layout()
        self.__set_properties()
        self.__bind_events()
        self.__set_default()

        # Show the GUI window
        self.Show()

    ## @brief Sets the properties of the main application window.
    #
    #  This method configures the window title, minimum size, and initial size.
    def __set_properties(self):
        # Set the window title
        self.SetTitle("Clustertool VuV")

        # Define the minimum window size to prevent excessive shrinking
        self.SetMinSize((1200, 600))

        # Set the initial window size when the application starts
        window_size = config_manager.config['gui']['window_size']
        self.SetSize(window_size)

        # # Set the minimal button size
        # for btn in self.buttons:
        #     if btn.GetParent() != self.right_panel:  # Nur wenn der Button NICHT im right_panel ist
        #         btn.SetMinSize(wx.Size(30, -1))

    ## @brief Defines the layout of the GUI components.
    #
    #  This method initializes and arranges the GUI elements, including:
    #  - Control panels for clustering settings
    #  - Date selection fields for calendar-based filtering
    #  - Data selection buttons
    #  - Result visualization areas
    #  - Action buttons for clustering and export functions
    def __set_layout(self):
        ## Create menubar
        self._create_menubar()

        ## Define padding for spacing between elements
        padding = 2

        default_flags = wx.ALL | wx.EXPAND #| wx.SHRINK

        ## @var panel
        #  Main container panel for the GUI
        self.panel = wx.Panel(self)

        ## @var top_panel
        #  Panel containing control buttons and tabs
        self.top_panel = wx.Panel(self.panel)

        ## @var controls_panel
        #  Panel containing clustering settings and calendar controls
        self.controls_panel = wx.Panel(self.top_panel)#, size=(-1, 130))

        ## @var main_sizer
        #  Main vertical sizer for the entire layout
        main_sizer = wx.BoxSizer(wx.VERTICAL)

        ## @var horizontal_sizer
        #  Horizontal sizer that arranges left and right sections
        horizontal_sizer = wx.BoxSizer(wx.HORIZONTAL)

        ## @var vertical_sizer
        #  Vertical sizer for left-side controls
        vertical_sizer = wx.BoxSizer(wx.VERTICAL)

        ## @var controls_sizer
        #  Horizontal sizer for controls panel (top settings)
        controls_sizer = wx.BoxSizer(wx.HORIZONTAL)

        # -----------------------------------
        # Group 1: Clustering Settings
        # -----------------------------------
        ## @var cluster_group
        #  StaticBoxSizer containing clustering settings
        cluster_group = wx.StaticBoxSizer(wx.HORIZONTAL, self.controls_panel, "Einstellung Clusterung")

        ## @var cluster_method_choice
        #  Dropdown for selecting the clustering method
        self.cluster_method_choice = wx.Choice(self.controls_panel,
                                               choices=["Average Linkage",
                                                        "Centroid Linkage",
                                                        "Complete Linkage",
                                                        "Median Linkage",
                                                        "Single Linkage",
                                                        "Ward",
                                                        "Weighted Linkage",
                                                        "Kmeans"])

        ## @var cluster_distance_choice
        #  Dropdown for selecting the distance function
        self.cluster_distance_choice = wx.Choice(self.controls_panel,
                                                 choices=["GEH", "SQV Counts", "Euclidean"])

        ## @var use_max_clusters
        #  Checkbox to enable maximum cluster count setting
        self.use_max_clusters = wx.CheckBox(self.controls_panel, label="Maximale Anzahl Cluster")

        ## @var max_clusters
        #  Spinner control for selecting the maximum number of clusters
        self.max_clusters = wx.SpinCtrl(self.controls_panel, min=0, max=100, initial=10)

        ## @var use_max_distance
        #  Checkbox to enable a cutoff distance threshold
        self.use_max_distance = wx.CheckBox(self.controls_panel, label="CutOff-Wert Distanz")

        ## @var max_distance
        #  Spinner control for setting the cutoff distance
        self.max_distance = wx.SpinCtrlDouble(self.controls_panel, min=0, max=100, initial=1, inc=0.01)

        ## @var kmeans_repeats
        #  Spinner control for setting the number of k-means iterations
        self.kmeans_repeats = wx.SpinCtrl(self.controls_panel, min=0, max=100, initial=10)

        ## @var kmeans_preselect
        #  Dropdown for selecting k-means initialization method
        self.kmeans_preselect = wx.Choice(self.controls_panel,
                                          choices=["zufällige Auswahl", "Normalverteilung", "++ Algorithmus"])

        # Layout für Clustermethode
        cluster_sizer_col1 = wx.BoxSizer(wx.VERTICAL)
        cluster_sizer_col2 = wx.BoxSizer(wx.VERTICAL)


        cluster_sizer_r1c1 = wx.BoxSizer(wx.HORIZONTAL)
        cluster_sizer_r1c1.Add(wx.StaticText(self.controls_panel, label="Methode"), 1,
                             default_flags, padding)
        cluster_sizer_r1c1.Add(self.cluster_method_choice, 0, default_flags, padding)
        cluster_sizer_r1c2 = wx.BoxSizer(wx.HORIZONTAL)
        cluster_sizer_r1c2.Add(wx.StaticText(self.controls_panel, label="Distanzfunktion"), 1,
                             default_flags, padding)
        cluster_sizer_r1c2.Add(self.cluster_distance_choice, 0, default_flags, padding)
        cluster_sizer_col1.Add(cluster_sizer_r1c1, 1, default_flags, padding)
        cluster_sizer_col2.Add(cluster_sizer_r1c2, 1, default_flags, padding)

        cluster_sizer_r2c1 = wx.BoxSizer(wx.HORIZONTAL)
        cluster_sizer_r2c1.Add(self.use_max_clusters, 1, default_flags, padding)
        cluster_sizer_r2c1.Add(self.max_clusters, 0, default_flags, padding)

        cluster_sizer_r2c2 = wx.BoxSizer(wx.HORIZONTAL)
        cluster_sizer_r2c2.Add(self.use_max_distance, 1, default_flags, padding)
        cluster_sizer_r2c2.Add(self.max_distance, 0, default_flags, padding)

        cluster_sizer_col1.Add(cluster_sizer_r2c2, 1, default_flags, padding)
        cluster_sizer_col2.Add(cluster_sizer_r2c1, 1, default_flags, padding)

        cluster_sizer_r3c1 = wx.BoxSizer(wx.HORIZONTAL)
        cluster_sizer_r3c1.Add(wx.StaticText(self.controls_panel, label="Kmeans Wiederholungen"), 1,
                             default_flags, padding)
        cluster_sizer_r3c1.Add(self.kmeans_repeats, 0, default_flags, padding)
        cluster_sizer_r3c2 = wx.BoxSizer(wx.HORIZONTAL)
        cluster_sizer_r3c2.Add(wx.StaticText(self.controls_panel, label="Kmeans Startbelegung"), 1,
                             default_flags, padding)
        cluster_sizer_r3c2.Add(self.kmeans_preselect, 0, default_flags, padding)

        cluster_sizer_col1.Add(cluster_sizer_r3c1, 1, default_flags, padding)
        cluster_sizer_col2.Add(cluster_sizer_r3c2, 1, default_flags, padding)

        cluster_group.Add(cluster_sizer_col1, 1, default_flags, padding)
        cluster_group.Add(cluster_sizer_col2, 1, default_flags, padding)

        # -----------------------------------
        # Group 2: Calendar Settings
        # -----------------------------------
        ## @var calendar_group
        #  StaticBoxSizer containing calendar-related settings
        calendar_group = wx.StaticBoxSizer(wx.VERTICAL, self.controls_panel, "Kalenderdaten")

        ## @var start_date
        #  DatePicker for selecting the start date
        self.start_date = wx.adv.DatePickerCtrl(self.controls_panel)

        ## @var end_date
        #  DatePicker for selecting the end date
        self.end_date = wx.adv.DatePickerCtrl(self.controls_panel)

        ## @var use_calendar_properties
        #  Checkbox for enabling calendar-based filtering
        self.use_calendar_properties = wx.CheckBox(self.controls_panel,
                                                   label="kalendarische Eigenschaften berücksichtigen")

        ## @var choice_state
        #  Dropdown for selecting a German federal state for holiday data
        self.choice_state = wx.Choice(self.controls_panel, choices=['BW', 'BY', 'BE',
                                                                    'BB', 'HB', 'HH', 'HE', 'MV',
                                                                    'NI', 'NW', 'RP', 'SL', 'SN',
                                                                    'ST', 'SH', 'TH'])

        ## @var checkboxes_calendar
        #  List of checkboxes for selecting calendar-related filters (e.g., weekdays, holidays)
        check_cal = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So", "Ferien", "Feiertage"]
        self.checkboxes_calendar = []
        cal_checkboxes = wx.BoxSizer(wx.HORIZONTAL)
        for label in check_cal:
            checkbox = wx.CheckBox(self.controls_panel, label=label)
            cal_checkboxes.Add(checkbox, 0, default_flags, padding)
            self.checkboxes_calendar.append(checkbox)

        calendar_sizer_r1 = wx.BoxSizer(wx.HORIZONTAL)
        calendar_sizer_r2 = wx.BoxSizer(wx.HORIZONTAL)
        calendar_sizer_r1.Add(self.use_calendar_properties, 0, default_flags, padding)

        calendar_sizer_r1.Add(wx.StaticText(self.controls_panel, label="Ferien Land"), 0,
                              wx.ALIGN_CENTER_VERTICAL | wx.ALL, padding)
        calendar_sizer_r1.Add(self.choice_state, 0, default_flags, padding)

        calendar_sizer_r2.Add(wx.StaticText(self.controls_panel, label="Erster Tag"), 0, wx.ALIGN_CENTER_VERTICAL | wx.ALL, padding)
        calendar_sizer_r2.Add(self.start_date, 0, default_flags, padding)
        calendar_sizer_r2.AddSpacer(40)
        calendar_sizer_r2.Add(wx.StaticText(self.controls_panel, label="Letzter Tag"), 0, wx.ALIGN_CENTER_VERTICAL | wx.ALL, padding)
        calendar_sizer_r2.Add(self.end_date, 0, default_flags, padding)

        calendar_group.Add(calendar_sizer_r2, 1, default_flags, padding)
        calendar_group.Add(cal_checkboxes, 1, default_flags, padding)
        calendar_group.Add(calendar_sizer_r1, 1, default_flags, padding)

        # -----------------------------------
        # Group 3: Data Selection
        # -----------------------------------
        ## @var data_group
        #  StaticBoxSizer containing file selection options
        data_group = wx.StaticBoxSizer(wx.VERTICAL, self.controls_panel, "Datenauswahl")

        ## @var data_button
        #  Button to open a clustering data file
        data_button = wx.Button(self.controls_panel, label="Datei Clusterung öffnen")

        ## @var use_properties
        #  Checkbox to enable additional data properties
        self.use_properties = wx.CheckBox(self.controls_panel, label="zusätzliche Eigenschaften")

        ## @var properties_data_button
        #  Button to open an additional properties data file
        properties_data_button = wx.Button(self.controls_panel, label="Datei öffnen")

        self.buttons += [data_button, properties_data_button]

        ## @var text_data
        #  StaticText for displaying the selected data file name
        self.text_data = wx.StaticText(self.controls_panel)

        ## @var text_properties
        #  StaticText for displaying the selected properties file name
        self.text_properties = wx.StaticText(self.controls_panel)

        data_sizer_r1 = wx.BoxSizer(wx.HORIZONTAL)
        data_sizer_r1.Add(wx.StaticText(self.controls_panel, label="Daten für die Clusterung"), 1,
                          default_flags,
                          padding)
        data_sizer_r1.Add(data_button,  1, default_flags, padding)
        data_sizer_r3 = wx.BoxSizer(wx.HORIZONTAL)
        data_sizer_r3.Add(self.use_properties, 1, default_flags, padding)
        data_sizer_r3.Add(properties_data_button, 1, default_flags, padding)

        data_group.Add(data_sizer_r1, 1, default_flags, padding)
        data_group.Add(self.text_data, 1, default_flags, padding)
        # data_group.Add(self.use_properties, 0, wx.ALL | wx.EXPAND, 5)
        data_group.Add(data_sizer_r3, 1, default_flags, padding)
        data_group.Add(self.text_properties, 1, default_flags, padding)

        # Hinzufügen der Gruppen zur Steuerleiste
        controls_sizer.Add(data_group, 1, default_flags, padding)
        controls_sizer.Add(calendar_group, 1, default_flags, padding)
        controls_sizer.Add(cluster_group, 1, default_flags, padding)

        self.controls_panel.SetSizer(controls_sizer)
        vertical_sizer.Add(self.controls_panel, 0, default_flags, padding)

        # -----------------------------------
        # Middle Panel: Notebook with 2 Pages
        # -----------------------------------
        notebook_sizer = wx.BoxSizer(wx.HORIZONTAL)  # Neuer Sizer für Notebook + Button
        self.notebook = wx.Notebook(self.top_panel)
        self.tabMain = MainTab(self.notebook)
        self.tabLog = LogTab(self.notebook)

        self.notebook.AddPage(self.tabMain, "Übersichtstabelle Clusterungen (Rechtsklick: Export)")
        self.notebook.AddPage(self.tabLog, "Log")

        # # Neuen Button erstellen
        # self.btn_extra = wx.Button(self.top_panel, label="Optionen")

        # Notebook und Button in den neuen Sizer einfügen
        notebook_sizer.Add(self.notebook, 1, default_flags, padding)
        # notebook_sizer.Add(self.btn_extra, 0, wx.ALIGN_CENTER_VERTICAL | wx.LEFT, 10)

        # Den neuen Sizer in den vertikalen Hauptsizer einfügen
        vertical_sizer.Add(notebook_sizer, 1, default_flags, padding)

        # -----------------------------------
        # Right Panel: Action Buttons
        # -----------------------------------
        ## @var right_panel
        #  Panel containing action buttons
        self.right_panel = wx.Panel(self.top_panel)
        right_sizer = wx.BoxSizer(wx.VERTICAL)

        ## @var buttons_right
        #  List of button labels for clustering actions
        buttons_right = ["Hilfe", "Clusterung ausführen", "Clusterung löschen",
                         "Silhouettendiagramm", "Dendrogramm",
                         "Distanzmatrix der Ganglinien",
                         "Clusterkalender", "Export Clusterung", "Export alle Clusterungen", "Export Diagramme"]

        # button_width = 160  # Hier die gewünschte feste Breite festlegen

        for label in buttons_right:
            button = wx.Button(self.right_panel, label=label)
            # button.SetInitialSize(wx.Size(button_width, -1))  # Setze die feste Breite
            if label == "Clusterung ausführen":
                right_sizer.Add(button, 2, wx.ALL | wx.EXPAND, padding)
            else:
                right_sizer.Add(button, 1, wx.ALL | wx.EXPAND, padding)
            self.buttons.append(button)

        self.right_panel.SetSizer(right_sizer)

        horizontal_sizer.Add(vertical_sizer, 1, default_flags, padding)
        horizontal_sizer.Add(self.right_panel, 0, wx.ALL | wx.EXPAND, padding)

        self.top_panel.SetSizer(horizontal_sizer)

        # -----------------------------------
        # Plot Panel (Visualizations)
        # -----------------------------------

        ## @var plot_panel
        #  Panel containing interactive Plotly visualizations
        self.plot_panel = wx.Panel(self.panel)
        plot_sizer = wx.BoxSizer(wx.HORIZONTAL)
        plot_left_sizer = wx.BoxSizer(wx.VERTICAL)
        plot_left_r1 = wx.BoxSizer(wx.HORIZONTAL)
        plot_right_sizer = wx.BoxSizer(wx.VERTICAL)
        plot_right_r1 = wx.BoxSizer(wx.HORIZONTAL)

        ## @var plot_view_left
        #  WebView for displaying left-side plots
        self.plot_view_left = WebView.New(self.plot_panel, backend=wx.html2.WebViewBackendEdge)
        ## @var plot_view_right
        #  WebView for displaying right-side plots
        self.plot_view_right = WebView.New(self.plot_panel, backend=wx.html2.WebViewBackendEdge)

        ## @var choice_property_plot
        #  Dropdown for selecting the property to be visualized in the left plot
        self.choice_property_plot = wx.Choice(self.plot_panel)

        ## @var vertical_lines
        #  Spinner control for setting the time intervals between vertical lines
        self.vertical_lines = wx.SpinCtrl(self.plot_panel, min=1, initial=24)

        ## @var use_vertical_lines
        #  Checkbox to enable vertical lines in time series plots
        self.use_vertical_lines = wx.CheckBox(self.plot_panel, label="Unterteilung Ganglinien einzelner Messquerschnitte alle")

        btn = wx.Button(self.plot_panel, label="Trennlinien aktualisieren")
        self.buttons.append(btn)

        plot_left_r1.AddSpacer(2)
        plot_left_r1.Add(wx.StaticText(self.plot_panel, label="Auswahl Eigenschaft"), 0, wx.ALL, padding)
        plot_left_r1.AddSpacer(10)
        plot_left_r1.Add(self.choice_property_plot, 0, wx.ALL, padding)
        plot_left_sizer.Add(plot_left_r1, 0, default_flags, padding)
        plot_left_sizer.Add(self.plot_view_left, 1, default_flags, padding)

        plot_right_r1.Add(self.use_vertical_lines, 0, default_flags, padding)
        plot_right_r1.Add(self.vertical_lines, 0, default_flags, padding)
        plot_right_r1.Add(wx.StaticText(self.plot_panel, label=" Zählintervalle"), 0, default_flags, padding)
        plot_right_r1.AddSpacer(20)
        plot_right_r1.Add(btn, 0, default_flags, padding)

        plot_right_sizer.Add(plot_right_r1, 0, default_flags, padding)
        plot_right_sizer.Add(self.plot_view_right, 1, default_flags, padding)

        plot_sizer.Add(plot_left_sizer, 1, default_flags, padding)
        plot_sizer.Add(plot_right_sizer, 2, default_flags, padding)

        self.plot_panel.SetSizer(plot_sizer)

        # -----------------------------------
        # Apply Layouts
        # -----------------------------------
        main_sizer.Add(self.top_panel, 2, default_flags, padding)
        main_sizer.Add(self.plot_panel, 3, default_flags, padding)
        self.panel.SetSizer(main_sizer)

        self.panel.Layout()
        self.Layout()  # Ensures the frame layout is updated
        # self.Maximize()

    ## @brief Binds event handlers to UI components.
    #
    #  This method connects various GUI elements (buttons, dropdowns, web views) to their respective event handlers.
    def __bind_events(self):
        ## Bind the WebView load event to a handler function.
        #  This ensures that when the right-side WebView loads content, the `_on_webview_loaded()` method is triggered.
        self.plot_view_right.Bind(wx.html2.EVT_WEBVIEW_LOADED, self._on_webview_loaded)

        ## Iterate over all buttons and bind their respective event handlers.
        #  Each button label is mapped to a corresponding function stored in `self.button_handlers`.
        for button in self.buttons:
            label = button.GetLabel()
            if label in self.button_handlers:
                button.Bind(wx.EVT_BUTTON, self.button_handlers[label])
            else:
                logging.error(f"Eventhandling für Button {label} nicht vorhanden")

        ## Bind the dropdown menu for plot properties to an event handler.
        #  This triggers `on_choice_change_plot_property()` whenever the user selects a different plot property.
        self.choice_property_plot.Bind(wx.EVT_CHOICE, self.on_choice_change_plot_property)

        ## Bind the right-click context menu event for the notebook (tab control).
        #  This ensures that `on_notebook_context_menu()` is executed when the user right-clicks inside the notebook.
        self.notebook.Bind(wx.EVT_CONTEXT_MENU, self.on_notebook_context_menu)


        # Bind the close event to properly clean up log handlers
        self.Bind(wx.EVT_CLOSE, self._on_close)

    ## @brief Sets default values for GUI elements.
    #
    #  This method initializes the GUI with default selections and values
    #  for checkboxes, dropdown menus, spin controls, and labels.
    def __set_default(self):
        # Enable all calendar-related checkboxes by default.
        for checkbox in self.checkboxes_calendar:
            checkbox.SetValue(True)

        # Enable the checkbox for calendar-based clustering.
        self.use_calendar_properties.SetValue(True)

        # Set the default selection for the clustering distance function from config.
        default_distance = self.config_manager.config['clustering']['default_distance_function']
        self.cluster_distance_choice.SetStringSelection(default_distance)

        # Set the default clustering method from config.
        default_method = self.config_manager.config['clustering']['default_method']
        # Convert to display format (e.g., "average" -> "Average Linkage")
        method_display = default_method.capitalize() + " Linkage"
        self.cluster_method_choice.SetStringSelection(method_display)

        # Enable the cutoff distance setting.
        self.use_max_distance.SetValue(True)

        # Set the default cutoff distance from config.
        default_cutoff = self.config_manager.config['clustering']['default_cutoff']
        self.max_distance.SetValue(default_cutoff)

        # Set the default federal state for holiday-based clustering to Baden-Württemberg ("BW").
        self.choice_state.SetStringSelection(self.config_manager.config['calendar']['default_state'])

        # Display default messages indicating that no data has been loaded.
        self.text_data.SetLabel("keine Ganglinien geladen")
        self.text_properties.SetLabel("keine Eigenschaften geladen")

        ## Set the default number of k-means iterations to 10.
        self.kmeans_repeats.SetValue(10)

        ## Set the default k-means initialization method from config.
        default_kmeans_preset = self.config_manager.config['clustering']['default_kmeans_preset']
        # Convert to display format (e.g., "random" -> "Zufällig", "k-means++" -> "++ Algorithmus")
        # Hinweis: Übersetzung passt nicht 1:1, ist in kmeans2 methode von scipy sehr unglücklich als Bezeichenr gewählt
        kmeans_preset_map = {
            "random": "Zufällige Auswahl",
            "k-means++": "++ Algorithmus",
            "uniform": "Normalverteilung"
        }
        preset_display = kmeans_preset_map.get(default_kmeans_preset, "++ Algorithmus")
        self.kmeans_preselect.SetStringSelection(preset_display)


    def bind_with_args(self, type, instance, handler, *args, **kwargs):
        self.Bind(type, lambda event: handler(event, *args, **kwargs), instance)


    ## @brief Opens a data file and loads time-series data or a clustering result.
    #
    #  This method allows the user to select and import a time-series dataset or a
    #  previously saved clustering result in JSON format.
    #
    #  - If the file is **not** a JSON file, it loads the time-series data and sets the date range.
    #  - If the file **is** a JSON file, it loads a saved clustering result, updates the UI, and initializes the clustering object.
    #
    #  @param event The wxPython event object.
    def on_open_data(self, event):
        # Open file selection dialog and get the selected file path.
        data_file = self._select_file2open()

        # Check if a valid file was selected.
        if data_file is not None:
            # Handle standard time-series data files (non-JSON).
            if data_file.suffix != ".json":
                # Load and preprocess the data.
                data = modules.data_handler.load_and_prepare_data(data_file, sheet="Data Ganglinien")

                # Extract the start and end dates from the dataset.
                start_date = data.index.min()
                end_date = data.index.max()

                # Update the date selection fields in the GUI.
                self.start_date.SetValue(start_date)
                self.end_date.SetValue(end_date)

                # Store the imported dataset.
                self.cluster_data = data

                # Display information about the loaded dataset.
                text_data = f"{len(self.cluster_data)} Ganglinien mit je {len(self.cluster_data.columns)} Elementen importiert"
                self.text_data.SetLabel(text_data)
                logging.info(text_data)

                # Check if calendar-based properties need to be updated.
                self._check_update_calendar()

            # Handle JSON files containing saved clustering results.
            else:
                logging.info("Clusterung wird geöffnet")

                # Load the clustering object from JSON.
                clusterer = modules.data_handler.load_clusterung_from_json(data_file, config_manager=self.config_manager)

                # Store imported data and properties.
                self.cluster_data = clusterer.data
                self.calendar_obj = clusterer.calendar
                self.properties_data = clusterer.properties_dates

                # Display information about the loaded clustering result.
                text_data = f"{len(self.cluster_data)} Ganglinien mit je {len(self.cluster_data.columns)} Elementen importiert"
                self.text_data.SetLabel(text_data)

                text_properties = f"{len(self.properties_data.columns)} Eigenschaften importiert"
                self.text_properties.SetLabel(text_properties)

                # Extract and set the date range from the loaded clustering result.
                start_date = self.cluster_data.index.min()
                end_date = self.cluster_data.index.max()
                self.start_date.SetValue(start_date)
                self.end_date.SetValue(end_date)

                # Add the loaded clustering result to the analysis.
                self._add_clusterung(clusterer)

                # Generate plots for the loaded clustering result.
                clusterer.plots_results()

                logging.info("Clusterdatei importiert")

    ## @brief Opens a file and loads additional properties for clustering.
    #
    #  This method allows the user to import a dataset containing additional
    #  properties (e.g., calendar attributes) that can be used for clustering.
    #
    #  @param event The wxPython event object.
    def on_open_properties(self, event):
        # Open file selection dialog and get the selected file path.
        data_file = self._select_file2open()

        # Check if a valid file was selected.
        if data_file is not None:
            # Load and preprocess the properties dataset.
            data = modules.data_handler.load_and_prepare_data(data_file, sheet="Data Eigenschaften")

            # Store the loaded properties dataset.
            self.properties_data = data

            # Display information about the imported properties.
            text_data = f"{len(self.properties_data.columns)} Eigenschaften importiert"
            self.text_properties.SetLabel(text_data)
            logging.info(text_data)

    ## @brief Opens the help documentation in a new window.
    #
    #  This method loads and displays an HTML help file in a popup window.
    #
    #  @param event The wxPython event object.
    def on_help(self, event):
        # Define the directory containing the documentation files.

        documentation_dir = Path(__file__).parent/ "documentation"

        logging.info(f"Dateien Dokumentation: {documentation_dir}")

        # Open the help popup window and display the help file.
        docu = HelpPopUp(self, documentation_dir)
        docu.Show()

    def on_info_import(self, event):
        # Define the message content.
        message = (
            "- CSV: Ganglinien, erste Zeile Index, mit oder ohne Spaltennamen\n"
            "- Excel: bei mehreren Tabellenblättern wird das mit dem Namen 'Data Ganglinien' oder, falls nicht vorhanden, das erste Tabellenblatt eingelesen\n"
            "- JSON: Exportobjekt einer vorherigen Clusterung"
        )

        # Display the message box.
        wx.MessageBox(message, "Informationen Dateiformate Import", wx.OK | wx.ICON_INFORMATION)

    ## @brief Executes the clustering process based on user settings.
    #
    #  This method retrieves user-selected clustering parameters, validates them,
    #  applies optional calendar-based filtering, and performs the clustering.
    #
    #  If an invalid parameter combination is detected, a message box is displayed
    #  and the clustering is not executed.
    #
    #  @param event The wxPython event object.
    def on_clusteranalysis(self, event):

        # Check if data has been loaded before attempting clustering.
        if self.cluster_data is None:
            wx.MessageBox('Clusterung nicht möglich - es sind keine Daten importiert',
                          'Clusterung ausführen',
                          wx.OK | wx.ICON_INFORMATION)
            return

        # Retrieve the selected clustering method from the dropdown menu.
        method = self.cluster_method_choice.GetString(self.cluster_method_choice.GetCurrentSelection()).lower()

        # Determine whether the user selected maximum clusters or a cutoff distance.
        if self.use_max_clusters.IsChecked() and not self.use_max_distance.IsChecked():
            max_clusters = self.max_clusters.GetValue()
            max_distance = None
        elif self.use_max_distance.IsChecked() and not self.use_max_clusters.IsChecked():
            max_distance = self.max_distance.GetValue()
            max_clusters = None
        else:
            logging.error(
                "Parameterkombination ist ungültig: Es können nicht die Anzahl an Clustern UND die maximale Distanz angegeben sein")
            wx.MessageBox('Clusterung nicht möglich - Parameterkombination ungültig',
                          'Clusterung ausführen',
                          wx.OK | wx.ICON_INFORMATION)
            return

        distance_fcn = self.cluster_distance_choice.GetString(
                    self.cluster_distance_choice.GetCurrentSelection()
                )

        # Ensure that k-means clustering has a valid cluster count.
        if ((method == "kmeans" and max_clusters is None)
                or (method == "kmeans" and distance_fcn != "Euclidean")):
            logging.error("Parameterkombination ist ungültig: Bei kmeans muss die Anzahl an Clustern definiert werden")
            wx.MessageBox('Clusterung nicht möglich - Parameterkombination ungültig',
                          'Clusterung ausführen',
                          wx.OK | wx.ICON_INFORMATION)
            return


        if method != "kmeans" and distance_fcn == "SQV Counts" and max_distance > 1:
            logging.error("Parameterkombination ist ungültig: Wertebereich SQV zwischen 0 und 1")
            wx.MessageBox('Clusterung nicht möglich - Wertebereich CutOff ungültig',
                          'Clusterung ausführen',
                          wx.OK | wx.ICON_INFORMATION)
            return


        # Update calendar-based properties if required.
        self._check_update_calendar()

        # Apply calendar-based filtering to select relevant data indices.
        logging.info("Start Filter Ganglinien")
        filtered_ind = self._get_filtered_indices_data()

        # Extract the filtered dataset.
        data = self.cluster_data.loc[filtered_ind, :]

        # Extract additional properties if enabled by the user.
        if self.properties_data is not None and self.use_properties.IsChecked():
            try:
                data_properties = self.properties_data.loc[filtered_ind, :]
            except Exception as e:
                logging.error("Indizes der Eigenschaften überlappen nicht mit den Ganglinien. Eigenschaften werden ignoriert")
                data_properties = None
        else:
            data_properties = None

        # Create and configure the clustering object.
        try:
            clusteranalysis = modules.clustering.Clusterung(
                data,
                attr_data=data_properties,
                method=method,
                distance_function=distance_fcn,
                cutoff=max_distance,
                max_clusters=max_clusters,
                kmeans_iter=self.kmeans_repeats.GetValue() if method == "kmeans" else None,
                kmeans_preset=self.kmeans_preselect.GetString(
                    self.kmeans_preselect.GetCurrentSelection()
                ) if method == "kmeans" else None,
                calendar_obj=self.calendar_obj,
                use_calendar=self.use_calendar_properties.IsChecked(),
                config_manager=self.config_manager
            )
            logging.info("Clusterobjekt erfolgreich angelegt")

            # Execute the clustering process.
            clusteranalysis.perform_clustering()
            clusteranalysis.calculate_indicators_cs()

        except Exception as e:
            logging.error("%s", e)
            return

        # Add the newly created clustering object to the list of analyses.
        self._add_clusterung(clusteranalysis)

    ## @brief Plots the dendrogram of the active cluster.
    #
    #  This method retrieves the currently selected cluster and plots a hierarchical
    #  clustering dendrogram. If the selected clustering method is k-means, no dendrogram
    #  is available.
    #
    #  @param event The wxPython event object.
    def on_plot_dendrogramm(self, event):
        try:
            # Retrieve the active cluster object.
            clusterobj = self.cluster_analyses[self.active_cluster]["Clusterobjekt"]
        except:
            logging.error("Kein gültiges Clusterobjekt ausgewählt")
            return

        # Check if the clustering method supports hierarchical clustering.
        if clusterobj.method == "kmeans":
            logging.warning("Keine hierarchische Clustermethode, Dendrogramm nicht vorhanden")
            return

        try:
            # Generate the dendrogram plot.
            fig = clusterobj.plot_dendrogramm()

            # Create a popup window to display the dendrogram.
            popup = PlotPopup(self, fig=fig, title=f"Dendrogramm Ganglinien",
                              cluster_id=self.active_cluster)
            popup.Show()
        except Exception as e:
            logging.error("%s", e)
            return

    ## @brief Deletes the currently active cluster.
    #
    #  This method removes the selected cluster from the GUI table, the internal storage,
    #  and resets the active cluster selection.
    #
    #  @param event The wxPython event object.
    def on_delete_cluster(self, event):
        try:
            # Ensure that a valid cluster is selected before deletion.
            if self.active_cluster == -1:
                wx.MessageBox("Kein aktives Cluster ausgewählt.", "Löschen fehlgeschlagen", wx.OK | wx.ICON_WARNING)
                return

            # Store the cluster ID before deletion.
            cluster_id = self.active_cluster

            # Remove the cluster from the GUI table.
            self.tabMain.delete_selection(str(cluster_id))

            # Remove the cluster from internal storage.
            if cluster_id in self.cluster_analyses:
                del self.cluster_analyses[cluster_id]
                logging.info(f"Cluster {cluster_id} erfolgreich gelöscht.")
            else:
                logging.warning(f"Cluster {cluster_id} war nicht in der internen Liste.")

            # Reset the active cluster selection.
            self.active_cluster = -1

            # Clear any displayed plots.
            wx.CallAfter(self.plot_view_left.LoadURL, "data:text/html,")
            wx.CallAfter(self.plot_view_right.LoadURL, "data:text/html,")
        except Exception as e:
            logging.error("%s", e)
            return

    ## @brief Plots the distance matrix of the active cluster.
    #
    #  This method retrieves the selected cluster and generates a heatmap showing the
    #  distances between time-series data points.
    #
    #  @param event The wxPython event object.
    def on_distancematrix(self, event):
        try:
            # Retrieve the active cluster object.
            clusterobj = self.cluster_analyses[self.active_cluster]["Clusterobjekt"]
        except:
            logging.error("Kein gültiges Clusterobjekt ausgewählt")
            return

        try:
            # Generate the distance matrix plot.
            fig = clusterobj.plot_distances()

            # Create a popup window to display the distance matrix.
            popup = PlotPopup(self, fig=fig, title="Distanzen Ganglinien", cluster_id=self.active_cluster)
            popup.Show()
        except Exception as e:
            logging.error("%s", e)
            return

    ## @brief Plots the silhouette diagram of the active cluster.
    #
    #  This method generates a silhouette plot, which visualizes how well-separated
    #  the clusters are. The silhouette score indicates cluster cohesion and separation.
    #
    #  @param event The wxPython event object.
    def on_plot_silhouette(self, event):
        try:
            # Retrieve the active cluster object.
            clusterobj = self.cluster_analyses[self.active_cluster]["Clusterobjekt"]
        except:
            logging.error("Kein gültiges Clusterobjekt ausgewählt")
            return

        try:
            # Generate the silhouette plot.
            fig = clusterobj.plot_silhouette()

            # Create a popup window to display the silhouette diagram.
            popup = PlotPopup(self, fig=fig, title="Silhouettendiagramm Ganglinien", cluster_id=self.active_cluster)
            popup.Show()
        except Exception as e:
            logging.error("%s", e)
            return

    ## @brief Plots the calendar-based cluster visualization.
    #
    #  This method retrieves the active cluster object and generates a calendar
    #  heatmap that visualizes how clusters are distributed over time.
    #
    #  @param event The wxPython event object.
    def on_cluster_calendar(self, event):
        try:
            # Retrieve the active cluster object.
            clusterobj = self.cluster_analyses[self.active_cluster]["Clusterobjekt"]
        except:
            logging.error("Kein gültiges Clusterobjekt ausgewählt")
            return

        try:
            # Generate the calendar cluster plot.
            fig = clusterobj.plot_calendar_cluster()

            # Create a popup window to display the calendar visualization.
            popup = ButtonPlotPopup(self, fig=fig, title="Kalender Cluster", 
                                   checkboxes={ # attribute name : display text for checkbox
                                       "flag_show_value": "Anzeigen der Werte",
                                       "flag_show_border": "Anzeigen der Zellenbegrenzungen"
                                   },
                                    clustering=clusterobj,
                                    str_plot_function="plot_calendar_cluster",
                                    cluster_id=self.active_cluster)
            popup.Show()
        except Exception as e:
            logging.error("%s", e)
            return

    ## @brief Exports the currently active cluster to a file.
    #
    #  This method allows the user to export the active cluster object in various formats
    #  (JSON, CSV, or Excel). The user selects a file location, and the corresponding
    #  save function is executed based on the file extension.
    #
    #  @param event The wxPython event object.
    def on_export_data(self, event):
        # Prompt the user to select a file location for saving.
        filepath = self._select_file2save()

        try:
            # Retrieve the active cluster object.
            clusterobj = self.cluster_analyses[self.active_cluster]["Clusterobjekt"]
        except:
            logging.error("Kein gültiges Clusterobjekt ausgewählt")
            return

        # If no file was selected, abort the export process.
        if filepath is None:
            logging.info("Der Exportvorgang wurde abgebrochen.")
            return

        # Determine the file format and save the data accordingly.
        if filepath.suffix == ".json":
            modules.data_handler.save_clusterung_to_json(clusterobj, filepath)
        elif filepath.suffix == ".csv":
            modules.data_handler.save_clusterung_to_csv(clusterobj, filepath)
        elif filepath.suffix == ".xlsx":
            modules.data_handler.save_clusterung_to_excel(clusterobj, filepath)
        else:
            logging.error("Dieses Dateiformat wird aktuell nicht unterstützt")
            return

        logging.info("Datei ist erfolgreich gespeichert")

    ## @brief Exports all clustering analyses to a selected folder.
    #
    #  The user selects a folder and chooses the desired file format (CSV, Excel, or JSON).
    #  Each cluster object is then saved in the chosen format with a filename indicating
    #  the clustering method and parameters used.
    #
    #  @param event The wxPython event object.
    def on_export_all_data(self, event):
        # Prompt the user to select a folder and file format.
        folder_path, selected_format = self._select_folder2save(["CSV", "Excel", "JSON"])

        # If no folder was selected, abort the export process.
        if folder_path is None:
            logging.info("Der Exportvorgang wurde abgebrochen.")
            return

        try:
            # Iterate over all stored clustering analyses and export them.
            for index, cluster in self.cluster_analyses.items():
                clusterobj = cluster["Clusterobjekt"]

                # Generate the filename based on clustering parameters.
                if clusterobj.cutoff is None:
                    filename = f"{index}_{clusterobj.method}_{clusterobj.distance_function}_n_max_{clusterobj.max_clusters}.{selected_format.lower()}"
                else:
                    filename = f"{index}_{clusterobj.method}_{clusterobj.distance_function}_CutOff_{clusterobj.cutoff}.{selected_format.lower()}"

                # Define the full file path.
                filepath = folder_path / filename

                # Save the cluster object in the selected format.
                if selected_format == ".json":
                    modules.data_handler.save_clusterung_to_json(clusterobj, filepath)
                elif filepath.suffix == ".csv":
                    modules.data_handler.save_clusterung_to_csv(clusterobj, filepath)
                elif filepath.suffix == ".xlsx":
                    modules.data_handler.save_clusterung_to_excel(clusterobj, filepath)
                else:
                    logging.error("Dieses Dateiformat wird aktuell nicht unterstützt")
                    return

            logging.info("Alle Clusterobjekte wurden erfolgreich gespeichert.")
        except Exception as e:
            logging.error("%s", e)
            return

    ## @brief Exports all clustering result diagrams to a selected folder.
    #
    #  The user selects a folder and chooses a file format (HTML, PNG, JPG, SVG, PDF, or JSON).
    #  The function then saves all plots (time-series plots and cluster property plots)
    #  in the chosen format.
    #
    #  @param event The wxPython event object.
    def on_export_diagrams(self, event):
        # Prompt the user to select a folder and file format.
        folder_path, selected_format = self._select_folder2save(sorted(["html", "png", "jpg", "svg", "pdf", "json"]),
                                                                flag_info_button=False)

        # If no folder was selected, abort the export process.
        if folder_path is None:
            logging.info("Der Exportvorgang wurde abgebrochen.")
            return

        # Convert the selected format to lowercase.
        selected_format = selected_format.lower()

        try:
            # Iterate over all stored clustering analyses and export their plots.
            for index, cluster in self.cluster_analyses.items():
                clusterobj = cluster["Clusterobjekt"]
                plot_series = cluster["Plot Ganglinien"]
                dict_plot_properties = cluster["Plots Eigenschaften"]

                # Generate the filename based on clustering parameters.
                if clusterobj.cutoff is None:
                    filename = f"{index}_{clusterobj.method}_{clusterobj.distance_function}_n_max_{clusterobj.max_clusters}"
                else:
                    filename = f"{index}_{clusterobj.method}_{clusterobj.distance_function}_CutOff_{clusterobj.cutoff}"

                # Define the full file path.
                filepath = folder_path / filename

                # Save the time-series plot.
                if selected_format == "html":
                    plot_series.write_html(str(filepath.parent / (filepath.name + f"_Ganglinien.html")))
                else:
                    plot_series.write_image(str(filepath.parent / (filepath.name + f"_Ganglinien.{selected_format}")))

                # Save the property plots.
                for prop, fig in dict_plot_properties.items():
                    if selected_format == "html":
                        fig.write_html(str(filepath.parent / (filepath.name + f"_{prop}.html")))
                    else:
                        fig.write_image(str(filepath.parent / (filepath.name + f"_{prop}.{selected_format}")))

            logging.info("Alle Diagramme wurden erfolgreich gespeichert.")
        except Exception as e:
            logging.error("%s", e)
            return

    ## @brief Exports or sets default color configurations.
    #
    #  This method either creates default colors or writes the current color configuration
    #  to the configuration file, depending on the 'how' parameter.
    #
    #  @param event The wxPython event object.
    #  @param how A string parameter that determines the action to take. If "set_default",
    #         creates default colors; otherwise, writes current colors to configuration.
    def on_export_colors(self, event, how: str=""):

        if how == "set_default":
            self.config_manager._create_default_colors()
        else:
            self.config_manager.write_colors()


    ## @brief Displays indicators for the active cluster in a popup window.
    #
    #  This method retrieves the active cluster object and creates a popup window
    #  that displays indicator tables for the time series data. The indicators provide
    #  statistical information about the clusters.
    #
    #  @param event The wxPython event object.
    def on_show_indicator(self, event):
        try:
            # Retrieve the active cluster object.
            clusterobj = self.cluster_analyses[self.active_cluster]["Clusterobjekt"]
        except:
            logging.error("Kein gültiges Clusterobjekt ausgewählt")
            return

        # Create and show the popup window with indicator tables
        num_decimal_places = self.config_manager.config['gui'].get('num_decimal_places', 0)
        popup = PopUpIndicatorWindow(self, clusterobj, title="Kenngrößen Ganglinien",
                                     cluster_id=self.active_cluster,
                                     num_decimal_places=num_decimal_places)
        popup.Show()





    ## @brief Updates the color maps for all diagrams without recreating them.
    #
    #  This method is called when the user selects the "Import & Update Farben Diagramme" 
    #  menu item. It loads the colors from the configuration and updates all diagrams
    #  with the new colors.
    #
    #  @param event The wxPython event object.
    def on_update_colormaps(self, event):
        # Load colors from configuration
        self.config_manager._load_colors()

        try:
            # Retrieve the active cluster object.
            clusterobj = self.cluster_analyses[self.active_cluster]["Clusterobjekt"]
        except:
            logging.error("Kein gültiges Clusterobjekt ausgewählt")
            return

        try:
            # Update the time series plot
            fig_series = self.cluster_analyses[self.active_cluster]["Plot Ganglinien"]
            fig_series = clusterobj.update_colors_diagram(fig=fig_series, plottype="series")
            self.cluster_analyses[self.active_cluster]["Plot Ganglinien"] = fig_series

            # Update the property plots
            for prop, fig in self.cluster_analyses[self.active_cluster]["Plots Eigenschaften"].items():
                updated_fig = clusterobj.update_colors_diagram(fig=fig, plottype="property", name=prop)
                self.cluster_analyses[self.active_cluster]["Plots Eigenschaften"][prop] = updated_fig

            # Nachfolgender Code wird aktuell nicht verwendet, da die Diagramme nicht gespeichert werden
            # # Update the silhouette plot if it exists
            # if "Plot Silhouette" in self.cluster_analyses[self.active_cluster]:
            #     fig_silhouette = self.cluster_analyses[self.active_cluster]["Plot Silhouette"]
            #     fig_silhouette = clusterobj.update_colors_diagram(fig=fig_silhouette, plottype="silhouette")
            #     self.cluster_analyses[self.active_cluster]["Plot Silhouette"] = fig_silhouette
            #
            # # Update the dendrogram if it exists
            # if "Plot Dendrogramm" in self.cluster_analyses[self.active_cluster]:
            #     fig_dendrogram = self.cluster_analyses[self.active_cluster]["Plot Dendrogramm"]
            #     fig_dendrogram = clusterobj.update_colors_diagram(fig=fig_dendrogram, plottype="dendrogram")
            #     self.cluster_analyses[self.active_cluster]["Plot Dendrogramm"] = fig_dendrogram
            #
            # # Update the distance matrix if it exists
            # if "Plot Distanzmatrix" in self.cluster_analyses[self.active_cluster]:
            #     fig_distances = self.cluster_analyses[self.active_cluster]["Plot Distanzmatrix"]
            #     fig_distances = clusterobj.update_colors_diagram(fig=fig_distances, plottype="distances")
            #     self.cluster_analyses[self.active_cluster]["Plot Distanzmatrix"] = fig_distances
            #
            # # Update the calendar if it exists
            # if "Plot Kalender" in self.cluster_analyses[self.active_cluster]:
            #     fig_calendar = self.cluster_analyses[self.active_cluster]["Plot Kalender"]
            #     fig_calendar = clusterobj.update_colors_diagram(fig=fig_calendar, plottype="calendar")
            #     self.cluster_analyses[self.active_cluster]["Plot Kalender"] = fig_calendar

            # Update the displayed plots
            self._update_plot_right(self.active_cluster)
            property = self.choice_property_plot.GetStringSelection()
            self._update_plot_left(int(self.active_cluster), property)

            logging.info("Farbzuweisungen wurden erfolgreich aktualisiert.")

        except Exception as e:
            logging.error("%s", e)
            return


    ## @brief Updates the indicators for the active cluster.
    #
    #  This method clears and recalculates the indicators for the active cluster.
    #  Indicators provide statistical information about the time series data in each cluster.
    #
    #  @param event The wxPython event object.
    def on_update_indicator(self, event):
        try:
            clusterobj = self.cluster_analyses[self.active_cluster]["Clusterobjekt"]
        except:
            logging.error("Kein gültiges Clusterobjekt ausgewählt")
            return

        try:
            clusterobj.indicators_data = {}
            clusterobj.indicators_clusters = {}
            clusterobj.calculate_indicators_cs()
        except Exception as e:
            logging.error("%s", e)
            return

    ## @brief Updates the global indicators for the active cluster.
    #
    #  This method initializes and calculates global indicators for the active cluster.
    #  Global indicators provide statistical information about the entire dataset
    #  rather than individual clusters.
    #
    #  @param event The wxPython event object.
    def on_update_global_indicators(self, event):
        try:
            clusterobj = self.cluster_analyses[self.active_cluster]["Clusterobjekt"]
        except:
            logging.error("Kein gültiges Clusterobjekt ausgewählt")
            return

        try:
            # Initialize global indicators dictionaries if they don't exist
            if not hasattr(clusterobj, 'indicators_global_data'):
                clusterobj.indicators_global_data = {}
            if not hasattr(clusterobj, 'indicators_global_cluster'):
                clusterobj.indicators_global_cluster = {}

            clusterobj.calculate_indicators_global()

            logging.info("Globale Kenngrößen wurden erfolgreich aktualisiert.")
        except Exception as e:
            logging.error("%s", e)
            return


    ## @brief Updates the left-side plot when a new cluster property is selected.
    #
    #  This method is triggered when the user selects a new property in the `wx.Choice` widget.
    #  It retrieves the selected property and updates the left-side plot accordingly.
    #
    #  @param event The wxPython event object.
    def on_choice_change_plot_property(self, event):
        # Retrieve the selected property from the dropdown menu.
        property = self.choice_property_plot.GetStringSelection()

        # Convert the active cluster index to an integer.
        active = int(self.active_cluster)

        # Update the left-side plot based on the selected property.
        self._update_plot_left(active, property)

    ## @brief Displays a context menu for exporting the clustering table.
    #
    #  This method creates a right-click context menu that allows the user to export
    #  the displayed clustering table.
    #
    #  @param event The wxPython event object.
    def on_notebook_context_menu(self, event):
        # Create the context menu.
        menu = wx.Menu()

        # Add an export option to the menu.
        export_item = menu.Append(wx.ID_ANY, "Exportieren", "Export der Tabelle")

        # Bind the export action to the corresponding method.
        self.Bind(wx.EVT_MENU, self.tabMain.export_table(), export_item)

        # Show the context menu.
        self.PopupMenu(menu)

        # Destroy the menu after selection.
        menu.Destroy()


    ## @brief Handles the events when the value of the spin control for vertical lines ore the checkbox are changed.
    #
    # This method retrieves the state of the checkbox and the value of the spin control.
    # If the checkbox is checked, the value of the spin control is used to update the plot.
    # If the checkbox is unchecked, None is used to remove the vertical lines from the plot.
    #
    # @return None
    def on_update_vertical_lines(self, event=None):
        try:
            # Retrieve the active cluster object.
            clusterobj = self.cluster_analyses[self.active_cluster]["Clusterobjekt"]
            fig = self.cluster_analyses[self.active_cluster]["Plot Ganglinien"]
        except:
            logging.error("Kein gültiges Clusterobjekt ausgewählt")
            return

        is_checked = self.use_vertical_lines.GetValue()

        if is_checked:
            vertical_lines_value = self.vertical_lines.GetValue()
            clusterobj.add_vertical_lines_series(fig, vertical_lines_value)

            self._update_plot_right(self.active_cluster)

        else:
            fig.layout.shapes = () # delete vertical lines and other shapes
            return


    ## @brief Opens a window for designing hourly volumes based on the active cluster.
    #
    #  This method creates a popup window that allows the user to design hourly volumes
    #  using the data from the active cluster. The window is implemented in the gui_bemessung
    #  module as DesignHourlyVolumeWindow.
    #
    #  @param event The wxPython event object.
    def on_design_hourly_volumes(self, event):
        try:
            # Retrieve the active cluster object.
            clusterobj = self.cluster_analyses[self.active_cluster]["Clusterobjekt"]
        except:
            logging.error("Kein gültiges Clusterobjekt ausgewählt")
            return

        try:
            # Create a popup window
            popup = gui_bemessung.DesignHourlyVolumeWindow(None, clusterobj=clusterobj,
                                                           cluster_id=self.active_cluster )
            popup.Show()
        except Exception as e:
            logging.error("%s", e)
            return







    ## @brief Opens a file dialog for selecting a data file.
    #
    #  This method allows the user to select a file for loading clustering data.
    #  It defaults to the "data" directory and ensures that only existing files can be selected.
    #
    #  @return Path object of the selected file or None if the user cancels.
    def _select_file2open(self):
        # Default directory where data files are stored.
        default_dir = Path(__file__).parent / "data"

        # Open a file dialog for selecting a data file.
        with wx.FileDialog(self, "Datei öffnen", defaultDir=str(default_dir),
                           wildcard="Alle Dateien (*.*)|*.*",
                           style=wx.FD_OPEN | wx.FD_FILE_MUST_EXIST) as fileDialog:
            # If the user cancels, return None.
            if fileDialog.ShowModal() == wx.ID_CANCEL:
                return None

            # Retrieve the selected file path.
            data_file = Path(fileDialog.GetPath())

            return data_file

    ## @brief Opens a file dialog for saving data in CSV, Excel, or JSON format.
    #
    #  This method prompts the user to select a file location for saving clustering data.
    #  It allows only specific formats: CSV, Excel (`.xlsx`), and JSON.
    #
    #  @return Path object of the selected file or None if the user cancels.
    def _select_file2save(self):
        # Define allowed file formats.
        wildcard = "CSV-Datei (*.csv)|*.csv|Excel-Datei (*.xlsx)|*.xlsx|JSON-Datei (*.json)|*.json"

        # Default directory for saving data files.
        default_dir = Path(__file__).parent / "data"

        # Open a file dialog for selecting a save location.
        with wx.FileDialog(self, "Datei speichern", defaultDir=str(default_dir),
                           wildcard=wildcard,
                           style=wx.FD_SAVE | wx.FD_OVERWRITE_PROMPT) as fileDialog:
            # Ein manuelles Panel für den Info-Button
            dlg_panel = wx.Panel(fileDialog)

            # Info-Button erstellen
            info_button = wx.Button(dlg_panel, label="Info zu Dateiformaten", pos=(10, 10))
            info_button.Bind(wx.EVT_BUTTON, self._show_file_format_info)

            # Layout für das Panel
            sizer = wx.BoxSizer(wx.VERTICAL)
            sizer.Add(info_button, 0, wx.ALL, 5)
            dlg_panel.SetSizer(sizer)

            # Dialog anpassen, um Panel zu enthalten
            sizer = wx.BoxSizer(wx.VERTICAL)
            sizer.Add(dlg_panel, 0, wx.EXPAND | wx.ALL, 5)
            fileDialog.SetSizer(sizer)
            fileDialog.Layout()

            # If the user cancels, return None.
            if fileDialog.ShowModal() == wx.ID_CANCEL:
                return None

            # Return the selected file path.
            return Path(fileDialog.GetPath())

    ## @brief Opens a folder selection dialog for saving multiple files.
    #
    #  The user can select a folder and specify a file format (CSV, Excel, JSON).
    #  An optional information button provides guidance on file formats.
    #
    #  @param format_choices List of allowed file formats.
    #  @param flag_info_button Boolean flag to display an info button.
    #  @return Tuple containing the selected folder path and format.
    def _select_folder2save(self, format_choices, flag_info_button=True):
        # Create a dialog for folder selection.
        dialog = wx.Dialog(self, title="Ordner zum Speichern auswählen", size=(350, 250))

        # Default directory for saving files.
        default_dir = Path(__file__).parent / "data"

        # Create a directory picker control.
        dir_picker = wx.DirPickerCtrl(dialog, message="Ordner auswählen", path=str(default_dir))

        # Create a vertical box sizer for layout management.
        sizer = wx.BoxSizer(wx.VERTICAL)

        # Add the directory picker to the sizer.
        dir_sizer = wx.BoxSizer(wx.HORIZONTAL)
        dir_sizer.Add(dir_picker, 1, wx.EXPAND | wx.ALL, 5)
        sizer.Add(dir_sizer, 0, wx.EXPAND | wx.ALL, 5)

        # Create a choice dropdown for selecting the file format.
        choice_format = wx.Choice(dialog, choices=format_choices)
        choice_format.SetSelection(0)

        # Layout for format selection row.
        row_2 = wx.BoxSizer(wx.HORIZONTAL)
        row_2.Add(wx.StaticText(dialog, label="Dateiformat wählen"), 0, wx.ALL | wx.EXPAND, 5)
        row_2.Add(choice_format, 1, wx.ALL | wx.EXPAND, 5)
        sizer.Add(row_2, 0, wx.EXPAND | wx.ALL, 5)

        # Create a row for buttons.
        row_4 = wx.BoxSizer(wx.HORIZONTAL)

        # Add an optional info button.
        if flag_info_button:
            info_button = wx.Button(dialog, label="Info zu Dateiformaten")
            info_button.Bind(wx.EVT_BUTTON, self._show_file_format_info)
            row_4.Add(info_button, 0, wx.ALL, 5)

        # OK button to confirm selection.
        ok_button = wx.Button(dialog, label="OK")
        ok_button.Bind(wx.EVT_BUTTON, lambda evt: dialog.EndModal(wx.ID_OK))
        row_4.Add(ok_button, 0, wx.ALL, 5)

        # Cancel button to abort.
        cancel_button = wx.Button(dialog, label="Abbrechen")
        cancel_button.Bind(wx.EVT_BUTTON, lambda evt: dialog.EndModal(wx.ID_CANCEL))
        row_4.Add(cancel_button, 0, wx.ALL, 5)

        # Add button row to the layout.
        sizer.Add(row_4, 0, wx.ALL | wx.ALIGN_CENTER_HORIZONTAL, 5)

        # Set and display the dialog layout.
        dialog.SetSizer(sizer)
        dialog.CentreOnScreen()
        result = dialog.ShowModal()

        # If the user cancels, return None.
        if result == wx.ID_CANCEL:
            return None, None

        # Retrieve the selected folder path and file format.
        folder_path = Path(dir_picker.GetPath())
        selected_format = format_choices[choice_format.GetSelection()]

        return folder_path, selected_format

    ## @brief Displays a message box explaining available file formats.
    #
    #  This method provides an overview of the supported file formats for exporting
    #  clustering results, including CSV, Excel, and JSON.
    #
    #  @param event The wxPython event object.
    def _show_file_format_info(self, event):
        # Define the message content.
        message = (
            "Bitte wählen Sie ein Dateiformat:\n\n"
            "- CSV: Nur repräsentative Ganglinien\n"
            "- Excel: Input-Daten, repräsentative Clusterganglinien und Eigenschaften\n"
            "- JSON: Clustering-Objekt"
        )

        # Display the message box.
        wx.MessageBox(message, "Speicherformat-Informationen", wx.OK | wx.ICON_INFORMATION)

    ## @brief Handles window close event to clean up log handlers.
    #  @param event The wx event triggered when closing the tab.
    def _on_close(self, event):

        to_del = [
            "temp_plot_left.html",
            "temp_plot_right.html",
            "temp_plot.html",
        ]
        for file in to_del:
            file = Path(file)
            # Lösche die Datei, wenn sie existiert
            if file.exists():
                file.unlink()  # Löscht die Datei
            else:
                continue

        self.Destroy()

    ## @brief Creates the menubar with all menus and menu items.
    #
    #  This method creates a menubar with the following menus:
    #  - Datenimport: For importing data
    #  - Export: For exporting data and diagrams
    #  - Diagramme: For displaying different diagrams
    #  - Kenngrößen Ganglinien: For calculating and displaying indicators
    #  - Bemessung: For dimensioning
    def _create_menubar(self):
        # Create standard menubar
        menubar = wx.MenuBar()

        # Create menus
        menu_data_import = wx.Menu()
        menu_export = wx.Menu()
        menu_diagrams = wx.Menu()
        menu_indicators = wx.Menu()
        menu_dimensioning = wx.Menu()

        # Add items to Datenimport menu
        item_info_data = menu_data_import.Append(wx.ID_ANY, "Info Dateiformate",
                                                 "Informationen zu dem Umgang mit Dateiformaten beim Import")
        menu_data_import.AppendSeparator()
        item_open_data = menu_data_import.Append(wx.ID_OPEN, "Ganglinien öffnen", "Öffnet eine Datei mit Ganglinien")
        item_open_properties = menu_data_import.Append(wx.ID_ANY, "Eigenschaften öffnen",
                                                       "Öffnet eine Datei mit Eigenschaften")
        menu_data_import.AppendSeparator()
        item_reset_data = menu_data_import.Append(wx.ID_ANY, "Daten Ganglinien löschen",)
        item_reset_properties = menu_data_import.Append(wx.ID_ANY, "Daten Eigenschaften löschen",)
        self.Bind(wx.EVT_MENU, self.on_info_import, item_info_data)
        self.Bind(wx.EVT_MENU, self.on_open_data, item_open_data)
        self.Bind(wx.EVT_MENU, self.on_open_properties, item_open_properties)
        self.bind_with_args(wx.EVT_MENU, item_reset_data,self.on_reset_attr_data,"cluster_data")
        self.bind_with_args(wx.EVT_MENU, item_reset_properties,self.on_reset_attr_data,"properties_data")

        # Add items to Export menu
        item_export_data = menu_export.Append(wx.ID_SAVE, "Aktive Clusterung exportieren", "Exportiert die aktuelle Clusterung")
        item_export_all_data = menu_export.Append(wx.ID_ANY, "Alle Clusterungen exportieren", "Exportiert alle Clusterungen")
        item_export_diagrams = menu_export.Append(wx.ID_ANY, "Diagramme der aktiven Clusterung exportieren", "Exportiert die Diagramme")
        self.Bind(wx.EVT_MENU, self.on_export_data, item_export_data)
        self.Bind(wx.EVT_MENU, self.on_export_all_data, item_export_all_data)
        self.Bind(wx.EVT_MENU, self.on_export_diagrams, item_export_diagrams)

        # Add items to Diagramme menu
        item_export_colors = menu_diagrams.Append(wx.ID_ANY, "Export Farbzuweisungen als colors.json")
        item_update_colors = menu_diagrams.Append(wx.ID_ANY, "Import & Update Farben Diagramme (aktive Clusterung)")
        item_reset_colors = menu_diagrams.Append(wx.ID_ANY, "Default Farbzuweisungen als colors.json")
        menu_diagrams.AppendSeparator()
        item_distance_matrix = menu_diagrams.Append(wx.ID_ANY, "Distanzmatrix", "Zeigt die Distanzmatrix der Ganglinien")
        item_silhouette = menu_diagrams.Append(wx.ID_ANY, "Silhouettendiagramm", "Zeigt das Silhouettendiagramm")
        item_dendrogram = menu_diagrams.Append(wx.ID_ANY, "Dendrogramm", "Zeigt das Dendrogramm")
        item_calendar = menu_diagrams.Append(wx.ID_ANY, "Clusterkalender", "Zeigt den Clusterkalender")

        self.Bind(wx.EVT_MENU, self.on_distancematrix, item_distance_matrix)
        self.Bind(wx.EVT_MENU, self.on_plot_silhouette, item_silhouette)
        self.Bind(wx.EVT_MENU, self.on_plot_dendrogramm, item_dendrogram)
        self.Bind(wx.EVT_MENU, self.on_cluster_calendar, item_calendar)
        self.Bind(wx.EVT_MENU, self.on_export_colors, item_export_colors)
        # self.Bind(wx.EVT_MENU, self.config_manager._load_colors, item_import_colors)
        self.Bind(wx.EVT_MENU, self.on_update_colormaps, item_update_colors)
        self.bind_with_args(wx.EVT_MENU, item_reset_colors, self.on_export_colors,"set_default")

        # Add items to Kenngrößen Ganglinien menu
        # Placeholder for future implementation
        item_indicators = menu_indicators.Append(wx.ID_ANY, "Kenngrößen aktualisieren (aktive Clusterung)", "Berechnet Kenngrößen für Ganglinien")
        item_global_indicators = menu_indicators.Append(wx.ID_ANY, "Globale Kenngrößen aktualisieren (aktive Clusterung)", "Berechnet globale Kenngrößen für Ganglinien")
        item_indicator_table = menu_indicators.Append(wx.ID_ANY, "Kenngrößen Ganglinien (aktive Clusterung)")
        self.Bind(wx.EVT_MENU, self.on_update_indicator, item_indicators)
        self.Bind(wx.EVT_MENU, self.on_update_global_indicators, item_global_indicators)
        self.Bind(wx.EVT_MENU, self.on_show_indicator, item_indicator_table)

        # Add items to Bemessung menu
        # Placeholder for future implementation
        item_dimensioning = menu_dimensioning.Append(wx.ID_ANY, "Dauerlinien und Bemessung", "Öffnet ein Fenster zur Anzeige der Dauerlinien")
        self.Bind(wx.EVT_MENU, self.on_design_hourly_volumes, item_dimensioning)

        # Add menus to menubar
        menubar.Append(menu_data_import, "Datenimport")
        menubar.Append(menu_export, "Export")
        menubar.Append(menu_diagrams, "Diagramme")
        menubar.Append(menu_indicators, "Kenngrößen Ganglinien")
        menubar.Append(menu_dimensioning, "Dauerlinien/Bemessung")

        # Set menubar
        self.SetMenuBar(menubar)
        self.Layout()


    ## @brief Placeholder for menu items that are not yet implemented.
    #
    #  This method displays a message box indicating that the selected feature is not yet implemented.
    #
    #  @param event The wxPython event object.
    def on_placeholder(self, event):
        wx.MessageBox("Diese Funktion ist noch nicht implementiert.", "Information", wx.OK | wx.ICON_INFORMATION)

    ## @brief Logs the event when a WebView finishes loading.
    #
    #  This method is triggered when the WebView component completes loading a webpage.
    #  It logs the loaded URL for debugging purposes.
    #
    #  @param event The wxPython event object containing the loaded URL.
    def _on_webview_loaded(self, event):
        # Log the loaded URL for debugging.
        logging.info(f"WebView geladen: {event.GetURL()}")

    ## @brief Updates the right plot in the WebView with the active cluster's time series plot.
    #
    #  This method resizes and updates the right-side Plotly figure based on the current
    #  WebView widget size. It then saves the figure as an HTML file and loads it into
    #  the WebView.
    #
    #  @param id_active The ID of the active cluster.
    def _update_plot_right(self, id_active):
        ## Scaling factor for adjusting the figure size.
        factor = 0.95

        ## Retrieve the stored Plotly figure for the selected cluster.
        fig_right = self.cluster_analyses[id_active]["Plot Ganglinien"]

        ## Get the current WebView size.
        size_right = self.plot_view_right.GetSize()

        # Adjust the figure size dynamically
        fig_right.update_layout(width=max(size_right[0] * factor, 100),
                                height=max(size_right[1] * factor, 100))

        plotly_html = "temp_plot_right.html"

        # Neue Datei schreiben
        fig_right.write_html(plotly_html)

        try:
            if self.plot_view_right:
                wx.CallAfter(self.plot_view_right.LoadURL, f"file://{os.path.abspath(plotly_html)}")
                logging.info(f"Plot erfolgreich in {plotly_html} gespeichert und geladen")
        except Exception as e:
            logging.error(f"Fehler beim Laden der URL: {e}")

    ## @brief Updates the left plot in the WebView with the selected cluster property.
    #
    #  This method retrieves the specified property plot for the active cluster, resizes it
    #  based on the WebView widget size, and then loads it into the WebView.
    #
    #  @param id_active The ID of the active cluster.
    #  @param property The property to be visualized in the left plot.
    def _update_plot_left(self, id_active, property):
        if property in self.cluster_analyses[id_active]["Plots Eigenschaften"]:
            ## Retrieve the stored Plotly figure for the selected property.
            fig = self.cluster_analyses[id_active]["Plots Eigenschaften"][property]
        else:
            logging.error(f"Diagramm {property} nicht vorhanden")
            fig = go.Figure()

        ## Get the current WebView size.
        size_left = self.plot_view_left.GetSize()

        ## Scaling factor for adjusting the figure size.
        factor = 0.95

        # Adjust the figure size dynamically
        fig.update_layout(width=max(size_left[0] * factor, 100),
                               height=max(size_left[1] * factor, 100))

        plotly_html = "temp_plot_left.html"

        # Neue Datei schreiben
        fig.write_html(plotly_html)

        try:
            if self.plot_view_right:
                wx.CallAfter(self.plot_view_left.LoadURL, f"file://{os.path.abspath(plotly_html)}")
                logging.info(f"Plot erfolgreich in {plotly_html} gespeichert und geladen")
        except Exception as e:
            logging.error(f"Fehler beim Laden der URL: {e}")

    ## @brief Filters the data indices based on selected calendar properties.
    #
    #  This method applies filtering criteria such as weekdays, holidays, and date range
    #  to determine which time-series data should be included in the clustering process.
    #
    #  @return A list of filtered datetime indices that match the selected criteria.
    def _get_filtered_indices_data(self):
        ## @var incl_properties
        #  List of selected calendar properties (e.g., weekdays, holidays).
        incl_properties = [item.Label for item in self.checkboxes_calendar if item.IsChecked()]
        logging.info(f"Berücksichtige Eigenschaften {incl_properties}")

        ## @var day_short
        #  List of selected weekdays (both English and German abbreviations).
        day_short = list(set(incl_properties) & {'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Son',
                                                 "Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"})

        # 3. Feiertage und Schulferien
        bank_holidays = set(incl_properties) & {"Feiertage", "bank holidays"}
        school_holidays = set(incl_properties) & {"Ferien", "school holidays"}

        filtered_indices = self.calendar_obj._get_filtered_indices_data(pd.to_datetime(self.cluster_data.index),
                                                                        days_to_include=day_short,
                                                                        include_bank_holidays= True if len(bank_holidays) > 0 else False,
                                                                        include_school_holidays= True if len(school_holidays) > 0 else False,
                                                                        start_date = pd.to_datetime(self.start_date.GetValue().FormatISODate()),
                                                                        end_date = pd.to_datetime(self.end_date.GetValue().FormatISODate()))

        return filtered_indices

    ## @brief Checks if the calendar object needs to be updated.
    #
    #  If the selected years or state do not match the existing calendar object, this method
    #  updates the calendar attributes by creating a new calendar object.
    def _check_update_calendar(self):
        ## @var years
        #  Unique years present in the dataset index.
        years = self.cluster_data.index.year.unique()

        ## @var state
        #  The selected state for determining holidays.
        state = self.choice_state.GetString(self.choice_state.GetCurrentSelection())

        # Update calendar object if necessary
        if self.calendar_obj is None \
                or not set(years).issubset(self.calendar_obj.years) \
                or state != self.calendar_obj.state:
            logging.info("Start Update Kalender-Objekt")
            self.calendar_obj = modules.calendar_attributes.CalendarAttributes(
                self.cluster_data.index.tolist(),
                dir_data_holidays=Path(__file__).parent / "data",
                state=state
            )
            logging.info("Kalender-Objekt aktualisiert")
        else:
            logging.info("Kein Update Kalender-Objekt notwendig")

    ## @brief Adds a clustering analysis result to the internal storage.
    #
    #  This method stores a new clustering result, generates associated plots,
    #  and updates the main table in the GUI.
    #
    #  @param clusteranalysis The clustering analysis object to add.
    def _add_clusterung(self, clusteranalysis):
        ## @var id
        #  Unique identifier for the new clustering result.
        id = 1 if len(self.cluster_analyses) < 1 else max(self.cluster_analyses.keys()) + 1

        ## Store the clustering object
        self.cluster_analyses[id] = {"Clusterobjekt": clusteranalysis}

        # Generate plots
        ## @var fig_series
        #  The main time-series plot of the clustering results.
        ## @var dict_fig_properties
        #  Dictionary containing property-based plots.
        fig_series, dict_fig_properties = clusteranalysis.plots_results()
        self.cluster_analyses[id]["Plot Ganglinien"] = fig_series
        self.cluster_analyses[id]["Plots Eigenschaften"] = dict_fig_properties

        # Add the clustering result to the main GUI table
        self.tabMain.add_row(id, clusteranalysis)

        # Update Plots if necessary
        self.on_update_vertical_lines()

    def on_reset_attr_data(self, event, attr_name):
        setattr(self, attr_name, pd.DataFrame())
        df = getattr(self, attr_name, pd.DataFrame())
        # Display information about the loaded dataset.
        text_data = f"{len(df)} Ganglinien mit je {len(df.columns)} Elementen importiert"
        if attr_name == "cluster_data":
            self.text_data.SetLabel(text_data)
        elif attr_name == "properties_data":
            self.text_properties.SetLabel(text_data)
        logging.info(f"{attr_name} als leere Tabelle initialisiert")



## @class MainTab
#  @brief A wxPython-based tab for managing clustering analyses.
#
#  The `MainTab` class provides a table (DataViewListCtrl) that displays details about
#  performed clustering analyses, allows selection of active clusters, and enables exporting data.
class MainTab(wx.ScrolledWindow):

    ## @brief Initializes the MainTab window.
    #  @param parent The parent wx object.
    def __init__(self, parent):
        wx.ScrolledWindow.__init__(self, parent)

        ## @var cluster_table
        #  The table (DataViewListCtrl) displaying clustering analyses.
        self.cluster_table = None

        self.SetScrollRate(20, 20)
        self.SetSizer(wx.BoxSizer(wx.VERTICAL))
        self.__set_layout()
        self.__bind_events()

    ## @brief Sets up the layout and initializes the clustering table.
    def __set_layout(self):
        # Create a DataViewListCtrl for displaying clustering results
        self.cluster_table = dv.DataViewListCtrl(self, style=wx.BORDER_SUNKEN | dv.DV_ROW_LINES)

        # Add a checkbox column to activate/deactivate cluster analyses
        self.cluster_table.AppendToggleColumn("Aktiv", width=40)

        # Add remaining columns for cluster metadata
        self.cluster_table.AppendTextColumn("ID", width=25)
        self.cluster_table.AppendTextColumn("Methode", width=100)
        self.cluster_table.AppendTextColumn("Distanz", width=50)
        self.cluster_table.AppendTextColumn("Startdatum", width=100)
        self.cluster_table.AppendTextColumn("Enddatum", width=100)
        self.cluster_table.AppendTextColumn("Max. Anz Cluster", width=80)
        self.cluster_table.AppendTextColumn("CutOff", width=50)
        self.cluster_table.AppendTextColumn("Wdh. kmeans", width=80)
        self.cluster_table.AppendTextColumn("Start kmeans", width=100)
        self.cluster_table.AppendTextColumn("Anz. Datensätze", width=80)
        self.cluster_table.AppendTextColumn("Anz. Cluster", width=80)
        self.cluster_table.AppendTextColumn("max. Clustergröße", width=100)
        self.cluster_table.AppendTextColumn("max. interne Distanz", width=100)

        # Add the table to the layout
        self.GetSizer().Add(self.cluster_table, 1, wx.EXPAND | wx.ALL, 5)

    ## @brief Binds event handlers for user interactions.
    def __bind_events(self):
        # Bind the checkbox column to update active cluster selection
        self.cluster_table.Bind(dv.EVT_DATAVIEW_ITEM_VALUE_CHANGED, self.on_select_active)

    ## @brief Handles the activation of a cluster in the table.
    #  @param event The wx event triggered by clicking a checkbox.
    def on_select_active(self, event):
        item = event.GetItem()
        changed_row = self.cluster_table.ItemToRow(item)

        ## @var active
        #  The ID of the currently active cluster.
        active = int(self.cluster_table.GetTextValue(changed_row, 1))
        self.TopLevelParent.active_cluster = active

        # Temporarily unbind event handler to avoid recursion
        self.cluster_table.Unbind(dv.EVT_DATAVIEW_ITEM_VALUE_CHANGED, handler=self.on_select_active)

        # Ensure only one cluster is active at a time
        for row in range(self.cluster_table.GetItemCount()):
            self.cluster_table.SetToggleValue(row == changed_row, row, 0)

        # Rebind the event handler
        self.cluster_table.Bind(dv.EVT_DATAVIEW_ITEM_VALUE_CHANGED, self.on_select_active)

        # Update the property choice list and plots
        choice_items = self.TopLevelParent.cluster_analyses[active]["Clusterobjekt"].cluster_properties.columns.tolist()
        choice_items.remove("counts")
        self.TopLevelParent.choice_property_plot.SetItems(choice_items)
        self.TopLevelParent.choice_property_plot.SetStringSelection(self.TopLevelParent.default_property)
        self.TopLevelParent._update_plot_left(active, self.TopLevelParent.default_property)
        self.TopLevelParent._update_plot_right(active)

    ## @brief Adds a new row to the cluster table.
    #  @param id The unique ID of the clustering analysis.
    #  @param clustering_obj The clustering object containing analysis results.
    def add_row(self, id, clustering_obj):
        cluster_info = clustering_obj.get_info()

        # Add new entry to the table
        self.cluster_table.AppendItem(["True", str(id)] + [
            cluster_info.Methode.title(),
            cluster_info.Distanz.upper(),
            cluster_info.Startdatum.strftime("%d.%m.%Y"),
            cluster_info.Enddatum.strftime("%d.%m.%Y"),
            str(int(cluster_info["Max. Anz Cluster"])) if cluster_info["Max. Anz Cluster"] is not None else "",
            str(cluster_info["CutOff"]).replace(".",",") if cluster_info["CutOff"] is not None else "",
            str(int(cluster_info["Wdh. kmeans"])) if cluster_info["Wdh. kmeans"] is not None else "",
            cluster_info["Start kmeans"] if cluster_info["Start kmeans"] is not None else "",
            str(cluster_info["Anz. Daten"]),
            str(cluster_info["Anz. Cluster"]),
            str(int(cluster_info["max. Clustergröße"])),  # Kein None Check notwendig, da bereits weiter oben überprüft
            str(cluster_info["max. interne Distanz"]).replace(".", ","),
        ])

        ## @var new_row
        #  The index of the newly added row.
        new_row = self.cluster_table.GetItemCount() - 1  # Last row

        # Set the new cluster as active
        self.TopLevelParent.active_cluster = id

        # Temporarily unbind event handler to prevent recursion
        self.cluster_table.Unbind(dv.EVT_DATAVIEW_ITEM_VALUE_CHANGED, handler=self.on_select_active)

        # Ensure only one cluster is active at a time
        for row in range(self.cluster_table.GetItemCount()):
            self.cluster_table.SetToggleValue(row == new_row, row, 0)

        # Rebind the event handler
        self.cluster_table.Bind(dv.EVT_DATAVIEW_ITEM_VALUE_CHANGED, self.on_select_active)

        # Update plots and property selection
        choice_items = self.TopLevelParent.cluster_analyses[id]["Clusterobjekt"].cluster_properties.columns.tolist()
        choice_items.remove("counts")
        self.TopLevelParent.choice_property_plot.SetItems(choice_items)
        self.TopLevelParent.choice_property_plot.SetStringSelection(self.TopLevelParent.default_property)
        self.TopLevelParent._update_plot_left(id, self.TopLevelParent.choice_property_plot.GetStringSelection())
        self.TopLevelParent._update_plot_right(id)

    ## @brief Returns the ID of the currently selected cluster.
    #  @return The ID of the active cluster, or None if no cluster is active.
    def get_id_selection(self):
        for row in range(self.cluster_table.GetItemCount()):
            if self.cluster_table.GetToggleValue(row, 0):
                return self.cluster_table.GetTextValue(row, 1)
        return None

    ## @brief Retrieves the row index corresponding to a given cluster ID.
    #  @param id The cluster ID to find.
    #  @return The row index of the cluster, or logs an error if not found.
    def get_row_given_index(self, id):
        for row in range(self.cluster_table.GetItemCount()):
            if self.cluster_table.GetTextValue(row, 1) == id:
                return row

        logging.error("ID ist nicht in Tabelle vorhanden")

    ## @brief Deletes the selected cluster row from the table.
    #  @param id The cluster ID to delete. If None, deletes the active cluster.
    def delete_selection(self, id=None):
        row_to_delete = self.get_row_given_index(id if id else self.get_id_selection())

        if row_to_delete is not None and 0 <= row_to_delete < self.cluster_table.GetItemCount():
            self.cluster_table.DeleteItem(row_to_delete)

            # Reset active cluster if the deleted row was active
            if row_to_delete == self.TopLevelParent.active_cluster:
                self.TopLevelParent.active_cluster = -1

    ## @brief Exports the table data to a CSV or Excel file.
    def export_table(self):
        filepath = self._select_file2safe()

        if filepath is None:
            logging.info("Der Exportvorgang wurde abgebrochen.")
            return

        # Extract table data
        data = []
        for row in range(self.cluster_table.GetItemCount()):
            row_data = [self.cluster_table.GetTextValue(row, col) for col in range(self.cluster_table.GetColumnCount())]
            data.append(row_data)

        # Convert to DataFrame
        df = pd.DataFrame(data, columns=[column.GetTitle() for column in self.cluster_table.GetColumns()]).set_index(
            "ID")
        df.drop(columns=["Aktiv"])

        # Save the data
        if filepath.suffix == ".csv":
            df.to_csv(filepath)
        elif filepath.suffix == ".xlsx":
            df.to_excel(filepath)
        else:
            ValueError(f"Export-Methode für {filepath.suffix} ist nicht implementiert")

        logging.info("Clusterung Tabelle exportiert")

    ## @brief Opens a file save dialog for exporting table data.
    #  @return The selected file path or None if the user cancels.
    def _select_file2safe(self):
        default_dir = Path(__file__) / "data"

        with wx.FileDialog(self, "Datei speichern", defaultDir=str(default_dir),
                           wildcard="CSV-Datei (*.csv)|*.csv|Excel-Datei (*.xlsx)|*.xlsx",
                           style=wx.FD_SAVE | wx.FD_OVERWRITE_PROMPT) as fileDialog:
            if fileDialog.ShowModal() == wx.ID_CANCEL:
                return None  # User canceled

            return Path(fileDialog.GetPath())


## @class LogTab
#  @brief A wxPython-based log tab for displaying application messages.
#
#  The `LogTab` class provides a message log within the GUI, capturing logs from the application.
#  It displays log messages in a `wx.TextCtrl` and also writes them to a log file.
class LogTab(wx.ScrolledWindow):

    ## @brief Initializes the LogTab.
    #  @param parent The parent wx object.
    def __init__(self, parent):
        wx.ScrolledWindow.__init__(self, parent)

        self.SetScrollRate(20, 20)

        ## @var logger
        #  The logging object for capturing log messages.
        self.logger = logging.getLogger()
        self.logger.setLevel(logging.INFO)

        ## @var path_logfile
        #  The file path for saving log messages.
        path_logfile = Path(__file__).parent / "Logfile.log"

        ## @var log
        #  A wx.TextCtrl widget for displaying log messages in the GUI.
        self.log = wx.TextCtrl(self, wx.ID_ANY, size=(700, 200),
                               style=wx.TE_MULTILINE | wx.TE_READONLY | wx.HSCROLL | wx.EXPAND)

        # Set up logging format
        logger_format = logging.Formatter("%(asctime)s %(levelname)s: %(message)s", datefmt="%d.%m.%Y %I:%M:%S %p")

        # Stream handler (console output)
        stream_handler = logging.StreamHandler()
        stream_handler.setFormatter(logger_format)

        # File handler (logfile)
        file_handler = logging.FileHandler(path_logfile, mode="w")
        file_handler.setFormatter(logger_format)

        # Add handlers to the logger
        self.logger.addHandler(file_handler)
        self.logger.addHandler(stream_handler)

        ## @var handler
        #  A custom logging handler that writes log messages to `wx.TextCtrl`.
        self.handler = WxTextCtrlHandler(self.log)
        self.handler.setFormatter(logger_format)
        self.logger.addHandler(self.handler)

        # Create layout
        vbox = wx.BoxSizer(wx.VERTICAL)
        vbox.Add(wx.StaticText(self, -1, "Message-Log"), 0, wx.ALL | wx.CENTER, 5)
        vbox.Add(self.log, 1, wx.ALL | wx.EXPAND, 5)
        self.SetSizer(vbox)

        # Bind the close event to properly clean up log handlers
        self.Bind(wx.EVT_WINDOW_DESTROY, self.on_close)

    ## @brief Handles window close event to clean up log handlers.
    #  @param event The wx event triggered when closing the tab.
    def on_close(self, event):
        # Remove the custom handler
        self.logger.removeHandler(self.handler)
        self.handler.close()

        # Remove and close all logging handlers (file and stream handlers)
        for handler in self.logger.handlers[:]:
            if isinstance(handler, (logging.FileHandler, logging.StreamHandler)):
                self.logger.removeHandler(handler)
                handler.close()

        event.Skip()


## @class WxTextCtrlHandler
#  @brief A logging handler that outputs log messages to a wx.TextCtrl widget.
#
#  The `WxTextCtrlHandler` class captures log messages and writes them to a `wx.TextCtrl`,
#  allowing real-time logging display in the GUI.
class WxTextCtrlHandler(logging.Handler):

    ## @brief Initializes the custom logging handler.
    #  @param ctrl The `wx.TextCtrl` widget where log messages will be displayed.
    def __init__(self, ctrl):
        logging.Handler.__init__(self)

        ## @var ctrl
        #  The wx.TextCtrl widget used to display log messages.
        self.ctrl = ctrl

    ## @brief Emits a log record to the wx.TextCtrl.
    #  @param record The log record to process.
    def emit(self, record):
        log_message = self.format(record) + '\n'
        wx.CallAfter(self.update_log, log_message)

    ## @brief Updates the wx.TextCtrl with a new log message and scrolls automatically.
    #  @param log_message The formatted log message to be displayed.
    def update_log(self, log_message):
        if self.ctrl:
            self.ctrl.WriteText(log_message)
            self.ctrl.ShowPosition(self.ctrl.GetLastPosition())  # Auto-scroll to the latest entry


## @class PlotPopup
#  @brief A popup window for displaying Plotly visualizations.
#
#  The `PlotPopup` class creates a wxPython-based window that embeds a Plotly figure.
#  The figure is displayed using `wx.html2.WebView`, allowing interactive visualization.
class PlotPopup(wx.Frame):

    ## @brief Initializes the PlotPopup window.
    #  @param parent The parent wx object.
    #  @param fig The Plotly figure to display.
    #  @param title The title of the window.
    #  @param cluster_id The ID of the cluster (optional).
    def __init__(self, parent, fig, title, cluster_id=None):
        # Update title with cluster_id if provided
        if cluster_id is not None:
            title = f"{title} (ID Clusterung: {cluster_id})"
        super(PlotPopup, self).__init__(parent, title=title, size=(900, 900))

        ## @var fig
        #  The Plotly figure to be displayed.
        self.fig = fig

        ## @var web_view
        #  A WebView widget to render the Plotly figure as an HTML page.
        self.web_view = wx.html2.WebView.New(self, backend=wx.html2.WebViewBackendEdge)

        # Bind the size event to dynamically update the figure
        self.Bind(wx.EVT_SIZE, self.on_size)

        # Display the initial HTML representation of the Plotly figure
        self.update_figure()

        # Layout setup
        sizer = wx.BoxSizer(wx.VERTICAL)
        sizer.Add(self.web_view, 1, wx.EXPAND, 10)
        self.SetSizer(sizer)

    ## @brief Handles resizing events to update the figure.
    #  @param event The wx size event.
    def on_size(self, event):
        # Update the figure on resizing
        self.update_figure()
        event.Skip()  # Ensure the event is processed further

    ## @brief Updates and resizes the Plotly figure.
    #
    #  This method adjusts the figure's layout based on the current window size,
    #  saves it as an HTML file, and loads it in the WebView.
    def update_figure(self):
        # Get the current window size
        width, height = self.GetSize().Get()

        # Adjust Plotly figure layout
        self.fig.update_layout(width=width * 0.93, height=height * 0.90,
                               margin=dict(l=20, r=20, t=30, b=20))

        # Save the figure as an HTML file
        plotly_html = "temp_plot.html"
        self.fig.write_html(plotly_html)

        # Load the HTML file into the WebView
        wx.CallAfter(self.web_view.LoadURL, f"file:///{os.path.abspath(plotly_html)}")


## @class ButtonPlotPopup
#  @brief A popup window for displaying Plotly visualizations with buttons and checkboxes at the top.
#
#  The `ButtonPlotPopup` class extends the `PlotPopup` class by adding a row of buttons
#  at the top of the window, including a button to update the diagram.
class ButtonPlotPopup(PlotPopup):
    ## @brief Initializes the ButtonPlotPopup window.
    #  @param parent The parent wx object.
    #  @param clustering The clustering object.
    #  @param fig The Plotly figure to display.
    #  @param title The title of the window.
    #  @param checkboxes Dictionary of checkboxes to display.
    #  @param str_plot_function Name of the plot function to call.
    #  @param cluster_id The ID of the cluster (optional).
    def __init__(self, parent, clustering, fig, title, checkboxes: dict={}, str_plot_function: str="", cluster_id=None):
        super(ButtonPlotPopup, self).__init__(parent, fig, title, cluster_id)

        self.clustering = clustering
        self.plot_fcn = str_plot_function

        # Create a button panel at the top
        self.button_panel = wx.Panel(self)
        button_sizer = wx.BoxSizer(wx.HORIZONTAL)

        # Add a spacer to push content to center
        button_sizer.AddStretchSpacer()

        # Create the update button
        self.update_button = wx.Button(self.button_panel, label="Diagramm aktualisieren")
        self.update_button.Bind(wx.EVT_BUTTON, self.on_update_diagram)
        button_sizer.Add(self.update_button, 0, wx.ALL | wx.ALIGN_CENTER_VERTICAL, 5)

        self.attr_list = list(checkboxes.keys())

        for attr, text in checkboxes.items():
            setattr(self, attr, wx.CheckBox(self.button_panel, label=text))
            button_sizer.Add(getattr(self, attr), 0, wx.ALL | wx.ALIGN_CENTER_VERTICAL, 5)

        # Add another spacer to push content to center
        button_sizer.AddStretchSpacer()

        # Set the button panel sizer
        self.button_panel.SetSizer(button_sizer)

        # Update the main sizer to include the button panel
        main_sizer = self.GetSizer()
        main_sizer.Insert(0, self.button_panel, 0, wx.EXPAND, 5)
        self.Layout()

    ## @brief Handles the update diagram button click.
    #  @param event The wx event.
    def on_update_diagram(self, event):

        # Get the checkbox values (checked/unchecked state)
        kwargs = {key: getattr(self, key).GetValue() for key in self.attr_list}
        self.fig = getattr(self.clustering, self.plot_fcn)(**kwargs)

        # Update the figure
        self.update_figure()

## @class PopUpIndicatorWindow
#  @brief A popup window for displaying indicator tables.
#
#  The `PopUpIndicatorWindow` class creates a wxPython-based window that displays tables
#  for indicators in a clustering object. It includes a list control to select which
#  indicator to display and tables for both cluster indicators and data indicators.
class PopUpIndicatorWindow(wx.Frame):
    ## @brief Initializes the indicator table popup.
    #  @param parent The parent wx object.
    #  @param clusterobj The clustering object containing the indicators.
    #  @param title The title of the window.
    def __init__(self, parent, clusterobj, title="Kenngrößen Ganglinien", cluster_id=None, num_decimal_places=0):
        # Update title with cluster_id if provided
        if cluster_id is not None:
            title = f"{title} (ID: {cluster_id})"
        super(PopUpIndicatorWindow, self).__init__(parent, title=title, size=(900, 600))

        ## @var clusterobj
        #  The clustering object containing the indicators.
        self.clusterobj = clusterobj

        ## @var num_decimal_places
        #  Number of decimal places to use when rounding values in tables.
        self.num_decimal_places = num_decimal_places

        ## @var indicators
        #  List of available indicators.
        self.indicators = list(self.clusterobj.indicators_clusters.keys())

        ## @var current_indicator
        #  The currently selected indicator.
        self.current_indicator = self.indicators[0] if self.indicators else None

        # Create the main panel and sizer
        panel = wx.Panel(self)
        main_sizer = wx.BoxSizer(wx.VERTICAL)

        # Create the indicator selection control
        indicator_sizer = wx.BoxSizer(wx.HORIZONTAL)
        indicator_label = wx.StaticText(panel, label="Kenngröße auswählen:")
        self.indicator_choice = wx.Choice(panel, choices=self.indicators)
        self.indicator_choice.SetSelection(0)
        self.indicator_choice.Bind(wx.EVT_CHOICE, self.on_indicator_selected)

        # Add filter checkbox
        self.filter_checkbox = wx.CheckBox(panel, label="Nur aktives Cluster anzeigen")
        self.filter_checkbox.Bind(wx.EVT_CHECKBOX, self.on_filter_changed)

        # Add cluster selection for filtering
        cluster_label = wx.StaticText(panel, label="Cluster:")
        self.cluster_choice = wx.Choice(panel, choices=[str(c) for c in sorted(self.clusterobj.clusters.unique())])
        self.cluster_choice.SetSelection(0)
        self.cluster_choice.Bind(wx.EVT_CHOICE, self.on_filter_changed)
        self.cluster_choice.Enable(False)  # Disabled by default

        indicator_sizer.Add(indicator_label, 0, wx.ALL | wx.ALIGN_CENTER_VERTICAL, 5)
        indicator_sizer.Add(self.indicator_choice, 1, wx.ALL | wx.EXPAND, 5)
        indicator_sizer.Add(self.filter_checkbox, 0, wx.ALL | wx.ALIGN_CENTER_VERTICAL, 5)
        indicator_sizer.Add(cluster_label, 0, wx.ALL | wx.ALIGN_CENTER_VERTICAL, 5)
        indicator_sizer.Add(self.cluster_choice, 0, wx.ALL | wx.EXPAND, 5)
        main_sizer.Add(indicator_sizer, 0, wx.EXPAND, 5)

        # Create a notebook for the tables
        self.notebook = wx.Notebook(panel)

        # Create pages for cluster indicators and data indicators
        self.cluster_panel = wx.Panel(self.notebook)
        self.data_panel = wx.Panel(self.notebook)

        # Create tables for cluster indicators and data indicators
        self.create_cluster_table()
        self.create_data_table()

        # Add pages to the notebook
        self.notebook.AddPage(self.cluster_panel, "Cluster Kenngrößen")
        self.notebook.AddPage(self.data_panel, "Daten Kenngrößen")

        main_sizer.Add(self.notebook, 1, wx.EXPAND | wx.ALL, 5)

        panel.SetSizer(main_sizer)
        self.Centre()

        # Initialize the tables with the first indicator
        self.update_tables()

    ## @brief Creates the table for cluster indicators.
    def create_cluster_table(self):
        sizer = wx.BoxSizer(wx.VERTICAL)

        # Create a DataViewListCtrl for displaying cluster indicators
        self.cluster_table = dv.DataViewListCtrl(self.cluster_panel, style=wx.BORDER_SUNKEN | dv.DV_ROW_LINES)

        # Add columns for the table
        self.cluster_table.AppendTextColumn("Cluster", width=80)

        # Add a column for global indicators if they exist
        # if hasattr(self.clusterobj, 'indicators_global_cluster') and self.clusterobj.indicators_global_cluster:
        self.cluster_table.AppendTextColumn("Global", width=80)

        # Add columns for each count station
        for col in self.clusterobj.series_cs.keys():
            self.cluster_table.AppendTextColumn(col, width=100)

        sizer.Add(self.cluster_table, 1, wx.EXPAND | wx.ALL, 5)
        self.cluster_panel.SetSizer(sizer)

    ## @brief Creates the table for data indicators.
    def create_data_table(self):
        sizer = wx.BoxSizer(wx.VERTICAL)

        # Create a DataViewListCtrl for displaying data indicators
        self.data_table = dv.DataViewListCtrl(self.data_panel, style=wx.BORDER_SUNKEN | dv.DV_ROW_LINES)

        # Add columns for the table
        self.data_table.AppendTextColumn("Datum", width=120)
        self.data_table.AppendTextColumn("Cluster", width=80)

        # # Add a column for global indicators if they exist
        # if hasattr(self.clusterobj, 'indicators_global_data') and self.clusterobj.indicators_global_data:
        self.data_table.AppendTextColumn("Global", width=80)

        # Add columns for each count station
        for col in self.clusterobj.series_cs.keys():
            self.data_table.AppendTextColumn(col, width=100)

        sizer.Add(self.data_table, 1, wx.EXPAND | wx.ALL, 5)
        self.data_panel.SetSizer(sizer)

    def update_table(
            self,
            table,
            data_df,
            global_data=None,
            is_cluster=False,
            filter_cluster=None,
            cluster_assignments=None
    ):
        """
        Aktualisiert eine wx.DataViewListCtrl-Tabelle mit den übergebenen Daten.
        - table: wx.DataViewListCtrl-Objekt
        - data_df: DataFrame mit den darzustellenden Daten
        - global_data: Series/DataFrame mit globalen Indikatorwerten (optional)
        - is_cluster: True, wenn Cluster-Tabelle (für spezielle Regeln)
        - filter_cluster: Cluster-ID für Filter (optional)
        - cluster_assignments: Series zum Zuordnen von Clustern zu Zeilen (optional)
        """
        try:
            table.DeleteAllItems()

            # Optional: Cluster-IDs als erste Spalte
            if not is_cluster and cluster_assignments is not None:
                cluster_assignments = cluster_assignments.to_frame(name=("cluster", ''))
                df_numeric = pd.concat([cluster_assignments, data_df], axis=1)
                # timestamps to string --> in Formatierungsmethode ausgelagert
                # if isinstance(df_numeric.index, pd.DatetimeIndex):
                #     df_numeric.index = df_numeric.index.strftime("%d.%m.%Y")
                # else:
                #     df_numeric.index = df_numeric.index.astype(str)
            else:
                # Optional: Cluster-Filter anwenden
                df_numeric = data_df.copy()
                # df_numeric.index = df_numeric.index.astype(str)

            if filter_cluster is not None:
                df_numeric = df_numeric[df_numeric[('cluster','')] == filter_cluster]

            df_numeric.reset_index(inplace=True, names="true_index")

            # insert global column if it doesn't exist

            if is_cluster:
                df_numeric.insert(1, 'global', np.nan)
            else:
                df_numeric.insert(2, "global", np.nan)

            if global_data is not None and hasattr(self, "current_indicator"):
                if "SP" not in self.current_indicator:
                    df_numeric.loc[:, 'global'] = df_numeric['true_index'].map(global_data[self.current_indicator])
                else:
                    df_numeric.loc[:, 'global'] = df_numeric['true_index'].map(global_data["sp"])

            # Initialize df_text
            if isinstance(df_numeric.columns, pd.MultiIndex):
                first_level_names = df_numeric.columns.get_level_values(0).unique()
                df_text = pd.DataFrame({
                    rmq: df_numeric.xs(rmq, axis=1, level=0)
                    .map(self.format_val)
                    .agg(';'.join, axis=1)
                    for rmq in first_level_names
                })
            else:
                # If not a MultiIndex, use the DataFrame directly
                df_text = df_numeric.map(self.format_val)

            for row in df_text.values.tolist():
                if len(row) != table.GetColumnCount():
                    logging.warning("Spaltenanzahl passt nicht zur Tabelle, Zeile wird ignoriert")
                else:
                    table.AppendItem(row)

            # Statistikzeilen (Minimum, Maximum, Durchschnitt)
            if not df_text.empty:
                df_stats = pd.DataFrame({"Minimum": df_numeric.min(),
                                         "Maximum": df_numeric.max(),
                                         "Durchschnitt":df_numeric.mean()}).T

                # Für SP: nur q_max-Spalten
                if hasattr(self, "current_indicator") and "SP" in self.current_indicator and isinstance(df_numeric.columns, pd.MultiIndex):
                    delete_cols = [col for col in df_numeric.columns if "sp" in col[1]]
                    df_stats.drop(delete_cols, axis=1, inplace=True)

                df_stats.drop(columns=df_stats.columns[0], axis=1,  inplace=True)
                df_stats.reset_index(inplace=True)
                df_stats = df_stats.map(self.format_val)

                for row in df_stats.values.tolist():
                    if len(row) != table.GetColumnCount():
                        logging.warning("Spaltenanzahl passt nicht zur Tabelle, Zeile wird ignoriert")
                    else:
                        table.AppendItem(row)

        except Exception as e:
            logging.error(f"Update table failed: {e}")

    def format_val(self, val):
        if isinstance(val, str):
            return val
        elif isinstance(val, pd.Timestamp):
            return val.strftime("%d.%m.%Y")
        elif pd.isna(val):
            return "-"
        elif isinstance(val, (float, int)):
            if self.num_decimal_places == 0:
                return str(int(round(val)))
            else:
                return f"{val:,{self.num_decimal_places}f}"
        else:
            return str(val)

    ## @brief Updates the tables with the selected indicator.
    def update_tables(self):
        if not self.current_indicator or not self.indicators:
            return


        # Get the indicator data
        cluster_data = self.clusterobj.indicators_clusters[self.current_indicator]
        data_data = self.clusterobj.indicators_data[self.current_indicator]

        # Check if global indicators exist
        if hasattr(self.clusterobj, 'indicators_cluster_global'):
            global_cluster = self.clusterobj.indicators_cluster_global[self.current_indicator]
        else:
            global_cluster = None

        if hasattr(self.clusterobj, 'indicators_data_global'):
            global_data = self.clusterobj.indicators_data_global[self.current_indicator]
        else:
            global_data = None


        # Apply filter if enabled
        if self.filter_checkbox.IsChecked():
            selected_cluster = int(self.cluster_choice.GetStringSelection())

        else:
            selected_cluster = None

        series_cluster = self.clusterobj.clusters

        self.update_table(self.cluster_table, cluster_data, global_data=global_cluster,
                          is_cluster=True, filter_cluster=None, cluster_assignments=None)

        self.update_table(self.data_table, data_data, global_data=global_data,
                          is_cluster=False, filter_cluster=selected_cluster, cluster_assignments=series_cluster)



    ## @brief Handles changes to the filter settings.
    #  @param event The wx event.
    def on_filter_changed(self, event):
        # Enable/disable the cluster choice based on the filter checkbox
        self.cluster_choice.Enable(self.filter_checkbox.IsChecked())

        # Update the tables with the new filter settings
        self.update_tables()

    ## @brief Handles the selection of an indicator.
    #  @param event The wx event.
    def on_indicator_selected(self, event):
        self.current_indicator = self.indicator_choice.GetStringSelection()
        try:
            self.update_tables()
        except:
            logging.error(f"Update Tabelle {self.current_indicator} fehlgeschlagen")

## @class HelpPopUp
#  @brief A popup window for displaying documentation pages.
#
#  The `HelpPopUp` class creates a wxPython-based window that embeds multiple documentation
#  pages in a tabbed interface using `wx.Notebook` and `wx.html2.WebView`. It supports Markdown (`.md`) files
#  by converting them to HTML before rendering.
class HelpPopUp(wx.Frame):
    ## @brief Initializes the documentation popup.
    #  @param parent The parent wx object.
    #  @param file_dir The directory containing the documentation files.
    def __init__(self, parent, file_dir: Path):
        super(HelpPopUp, self).__init__(parent, title="Help", size=(900, 900))

        ## @var notebook
        #  A wx.Notebook widget containing different documentation tabs.
        notebook = wx.Notebook(self)

        ## @var dict_docu
        #  A dictionary mapping tab names to documentation file paths.
        dict_docu = {
            "Anwendung Clustertool GUI ": file_dir / "Anwendung_GUI.md",
            "Grundlagen Clusteranalyse": file_dir / "Grundlagen_Clusteranalyse.html",
            "Dokumentation Code": file_dir / "doxygen" / "html" / "index.html"
        }

        # Create tabs with embedded WebView for each documentation page
        for page_name, file_path in dict_docu.items():
            panel = wx.Panel(notebook)
            sizer = wx.BoxSizer(wx.VERTICAL)

            ## @var html_view
            #  A WebView widget to render the documentation content.
            html_view = wx.html2.WebView.New(panel, backend=wx.html2.WebViewBackendEdge)

            # Convert Markdown to HTML dynamically (no file is saved)
            if file_path.suffix == ".md":
                html_content = self._convert_md_to_html(file_path, file_dir)
                html_view.SetPage(html_content, "")
            elif file_path.suffix == ".html":
                if file_path.exists():
                    wx.CallAfter(html_view.LoadURL, str(file_path.resolve()))
                else:
                    html_view.SetPage(f"<h3>Error: File {file_path.name} not found!</h3>", "")
            else:
                html_view.SetPage("<h3>Error: Unsupported file format.</h3>", "")

            sizer.Add(html_view, 1, wx.EXPAND | wx.ALL, 5)
            panel.SetSizer(sizer)

            # Add the panel as a new tab
            notebook.AddPage(panel, page_name)

        ## @var main_sizer
        #  The main layout container for the popup window.
        main_sizer = wx.BoxSizer(wx.VERTICAL)
        main_sizer.Add(notebook, 1, wx.EXPAND)
        self.SetSizer(main_sizer)
        self.Show()

    ## @brief Converts a Markdown file to an HTML string and updates image paths.
    #  @param md_file The path to the Markdown file.
    #  @param base_dir The base directory where the images are stored.
    #  @return An HTML string with proper formatting.
    def _convert_md_to_html(self, md_file: Path, base_dir: Path) -> str:
        """Converts a Markdown file to an HTML string for rendering in WebView."""
        if not md_file.exists():
            return "<h3>Error: Markdown file not found.</h3>"

        try:
            with open(md_file, "r", encoding="utf-8") as f:
                md_content = f.read()

            # Setze das Bildverzeichnis korrekt für WebView
            image_dir = base_dir / "pictures"
            md_content = md_content.replace("](pictures/", f"](file:///{image_dir.resolve().as_posix()}/")

            # Convert Markdown to HTML with extra features enabled
            html_content = markdown.markdown(md_content, extensions=[
                "extra",  # Fügt Unterstützung für Listen, Tabellen und mehr hinzu
                "admonition",  # Ermöglicht erweiterte Blöcke wie Notizen oder Warnungen
                "tables",  # Unterstützt Markdown-Tabellen
                "fenced_code",  # Erlaubt ```python``` Codeblöcke
                "toc"  # Erzeugt ein automatisches Inhaltsverzeichnis
            ])

            # Inject MathJax for LaTeX support
            html_output = f"""
            <html>
            <head>
                <meta charset="utf-8">
                <title>{md_file.stem}</title>
                <script type="text/javascript" async
                  src="https://cdnjs.cloudflare.com/ajax/libs/mathjax/3.2.0/es5/tex-mml-chtml.js">
                </script>
                <style>
                    body {{
                        font-family: Arial, sans-serif;
                        margin: 20px;
                        padding: 20px;
                        line-height: 1.6;
                    }}
                    h1, h2, h3 {{
                        color: #333;
                    }}
                    pre {{
                        background: #f4f4f4;
                        padding: 10px;
                        border-radius: 5px;
                        overflow-x: auto;
                    }}
                    img {{
                        max-width: 100%;
                        height: auto;
                        display: block;
                        margin: 10px 0;
                    }}
                    table {{
                        width: 100%;
                        border-collapse: collapse;
                        margin: 10px 0;
                    }}
                    th, td {{
                        border: 1px solid #ddd;
                        padding: 8px;
                        text-align: left;
                    }}
                    th {{
                        background-color: #f4f4f4;
                    }}
                </style>
            </head>
            <body>
                {html_content}
            </body>
            </html>
            """

            return html_output
        except Exception as e:
            print(f"Error converting Markdown to HTML: {e}")
            return "<h3>Error: Markdown processing failed.</h3>"



if __name__ == "__main__":
    app = wx.App(False)
    frame = ClusterGUI()
    app.MainLoop()
