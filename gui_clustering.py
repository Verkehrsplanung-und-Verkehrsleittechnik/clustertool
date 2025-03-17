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
        self.default_property = "Wochentag"

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
            "Datei öffnen": self.on_open_properties
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
        self.SetSize((1400, 1000))  # Startgröße setzen

    ## @brief Defines the layout of the GUI components.
    #
    #  This method initializes and arranges the GUI elements, including:
    #  - Control panels for clustering settings
    #  - Date selection fields for calendar-based filtering
    #  - Data selection buttons
    #  - Result visualization areas
    #  - Action buttons for clustering and export functions
    def __set_layout(self):

        ## Define padding for spacing between elements
        padding = 2

        ## @var panel
        #  Main container panel for the GUI
        self.panel = wx.Panel(self)

        ## @var top_panel
        #  Panel containing control buttons and tabs
        self.top_panel = wx.Panel(self.panel)

        ## @var controls_panel
        #  Panel containing clustering settings and calendar controls
        self.controls_panel = wx.Panel(self.top_panel, size=(-1, 150))

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
        cluster_group = wx.StaticBoxSizer(wx.VERTICAL, self.controls_panel, "Einstellung Clustering")

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
        cluster_sizer_r1 = wx.BoxSizer(wx.HORIZONTAL)
        cluster_sizer_r1.Add(wx.StaticText(self.controls_panel, label="Methode"), 0,
                             wx.ALIGN_CENTER_VERTICAL | wx.ALL, 5)
        cluster_sizer_r1.Add(self.cluster_method_choice, 1, wx.EXPAND | wx.ALL, 5)
        cluster_sizer_r1.AddSpacer(10)
        cluster_sizer_r1.Add(wx.StaticText(self.controls_panel, label="Distanzfunktion"), 0,
                             wx.ALIGN_CENTER_VERTICAL | wx.ALL, 5)
        cluster_sizer_r1.Add(self.cluster_distance_choice, 1, wx.EXPAND | wx.ALL, 5)

        cluster_sizer_r2 = wx.BoxSizer(wx.HORIZONTAL)
        cluster_sizer_r2.Add(self.use_max_clusters, wx.ALIGN_CENTER_VERTICAL | wx.ALL, 5)
        cluster_sizer_r2.Add(self.max_clusters, 0, wx.ALIGN_CENTER_VERTICAL | wx.ALL, 5)
        # Spacer für zusätzlichen Abstand
        cluster_sizer_r2.AddSpacer(20)
        cluster_sizer_r2.Add(self.use_max_distance, wx.ALIGN_CENTER_VERTICAL | wx.ALL, 5)
        cluster_sizer_r2.Add(self.max_distance, 0, wx.ALIGN_CENTER_VERTICAL | wx.ALL, 5)

        cluster_sizer_r3 = wx.BoxSizer(wx.HORIZONTAL)
        cluster_sizer_r3.AddSpacer(10)
        cluster_sizer_r3.Add(wx.StaticText(self.controls_panel, label="Kmeans Wiederholungen"), 0,
                             wx.ALIGN_CENTER_VERTICAL | wx.ALL, 5)
        cluster_sizer_r3.Add(self.kmeans_repeats, 0, wx.ALIGN_CENTER_VERTICAL | wx.ALL, 5)
        cluster_sizer_r3.AddSpacer(20)
        cluster_sizer_r3.Add(wx.StaticText(self.controls_panel, label="Kmeans Startbelegung"), 0,
                             wx.ALIGN_CENTER_VERTICAL | wx.ALL, 5)
        cluster_sizer_r3.Add(self.kmeans_preselect, 0, wx.ALIGN_CENTER_VERTICAL | wx.ALL, 5)

        cluster_group.Add(cluster_sizer_r1, 0, wx.EXPAND | wx.ALL, padding)
        cluster_group.Add(cluster_sizer_r2, 0, wx.EXPAND | wx.ALL, padding)
        cluster_group.Add(cluster_sizer_r3, 0, wx.EXPAND | wx.ALL, padding)

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
            cal_checkboxes.Add(checkbox, 0, wx.ALL, 2)
            self.checkboxes_calendar.append(checkbox)

        calendar_sizer_r1 = wx.BoxSizer(wx.HORIZONTAL)
        calendar_sizer_r2 = wx.BoxSizer(wx.HORIZONTAL)
        calendar_sizer_r1.Add(self.use_calendar_properties, 0, wx.ALL | wx.EXPAND, 5)

        calendar_sizer_r1.Add(wx.StaticText(self.controls_panel, label="Ferien Land"), 0,
                              wx.ALIGN_CENTER_VERTICAL | wx.ALL, 5)
        calendar_sizer_r1.Add(self.choice_state, 0, wx.ALL | wx.EXPAND, 5)

        calendar_sizer_r2.Add(wx.StaticText(self.controls_panel, label="Erster Tag"), 0, wx.ALL | wx.EXPAND, 5)
        calendar_sizer_r2.Add(self.start_date, 0, wx.ALL | wx.EXPAND, 2)
        calendar_sizer_r2.Add(wx.StaticText(self.controls_panel, label="Letzter Tag"), 0, wx.ALL | wx.EXPAND, 5)
        calendar_sizer_r2.Add(self.end_date, 0, wx.ALL | wx.EXPAND, 2)
        calendar_group.Add(calendar_sizer_r2, 0, wx.ALL | wx.EXPAND, 5)
        calendar_group.Add(cal_checkboxes, 0, wx.ALL | wx.EXPAND, 5)
        calendar_group.Add(calendar_sizer_r1, 0, wx.ALL | wx.EXPAND, 5)

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
        data_sizer_r1.Add(wx.StaticText(self.controls_panel, label="Daten für die Clusterung"), 0, wx.ALL | wx.EXPAND,
                          5)
        data_sizer_r1.Add(data_button)
        data_sizer_r3 = wx.BoxSizer(wx.HORIZONTAL)
        data_sizer_r3.Add(self.use_properties, 0, wx.ALL | wx.EXPAND, 5)
        data_sizer_r3.Add(properties_data_button)

        data_group.Add(data_sizer_r1, 0, wx.ALL | wx.EXPAND, 5)
        data_group.Add(self.text_data, 0, wx.ALL | wx.EXPAND, 5)
        # data_group.Add(self.use_properties, 0, wx.ALL | wx.EXPAND, 5)
        data_group.Add(data_sizer_r3)
        data_group.Add(self.text_properties, 0, wx.ALL | wx.EXPAND, 5)

        # Hinzufügen der Gruppen zur Steuerleiste
        controls_sizer.Add(data_group, 1, wx.EXPAND | wx.ALL, 5)
        controls_sizer.Add(calendar_group, 1, wx.EXPAND | wx.ALL, 5)
        controls_sizer.Add(cluster_group, 1, wx.EXPAND | wx.ALL, 5)

        self.controls_panel.SetSizer(controls_sizer)
        vertical_sizer.Add(self.controls_panel, 0, wx.EXPAND | wx.ALL, 5)

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
        notebook_sizer.Add(self.notebook, 1, wx.EXPAND)
        # notebook_sizer.Add(self.btn_extra, 0, wx.ALIGN_CENTER_VERTICAL | wx.LEFT, 10)

        # Den neuen Sizer in den vertikalen Hauptsizer einfügen
        vertical_sizer.Add(notebook_sizer, 1, wx.EXPAND | wx.ALL, 5)

        # -----------------------------------
        # Right Panel: Action Buttons
        # -----------------------------------
        ## @var right_panel
        #  Panel containing action buttons
        self.right_panel = wx.Panel(self.top_panel)
        right_sizer = wx.BoxSizer(wx.VERTICAL)
        self.right_panel.SetSizer(right_sizer)

        ## @var buttons_right
        #  List of button labels for clustering actions
        buttons_right = ["Hilfe", "Clusterung ausführen", "Clusterung löschen",
                         "Silhouettendiagramm", "Dendrogramm",
                         "Distanzmatrix der Ganglinien",
                         "Clusterkalender", "Export Clusterung", "Export alle Clusterungen", "Export Diagramme"]

        for label in buttons_right:
            button = wx.Button(self.right_panel, label=label)
            if label == "Clusterung ausführen":
                right_sizer.Add(button, 2, wx.ALL | wx.EXPAND, 5)
            else:
                right_sizer.Add(button, 1, wx.ALL | wx.EXPAND, 5)
            self.buttons.append(button)

        horizontal_sizer.Add(vertical_sizer, 1, wx.EXPAND)
        horizontal_sizer.Add(self.right_panel, 0, wx.EXPAND | wx.ALL, 5)

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

        ## @var plot_view_left
        #  WebView for displaying left-side plots
        self.plot_view_left = WebView.New(self.plot_panel, backend=wx.html2.WebViewBackendEdge)
        ## @var plot_view_right
        #  WebView for displaying right-side plots
        self.plot_view_right = WebView.New(self.plot_panel, backend=wx.html2.WebViewBackendEdge)

        ## @var choice_property_plot
        #  Dropdown for selecting the property to be visualized in the left plot
        self.choice_property_plot = wx.Choice(self.plot_panel)

        plot_left_r1.Add(wx.StaticText(self.plot_panel, label="Auswahl Eigenschaft"), 1, wx.ALL | wx.EXPAND, 5)
        plot_left_r1.Add(self.choice_property_plot, 1, wx.ALL, 5)
        plot_left_sizer.Add(plot_left_r1, 0, wx.EXPAND | wx.ALL, 5)
        plot_left_sizer.Add(self.plot_view_left, 1, wx.EXPAND | wx.ALL, 5)
        plot_sizer.Add(plot_left_sizer, 1, wx.EXPAND | wx.ALL, 5)
        plot_sizer.Add(self.plot_view_right, 2, wx.EXPAND | wx.ALL, 5)

        self.plot_panel.SetSizer(plot_sizer)

        # -----------------------------------
        # Apply Layouts
        # -----------------------------------
        main_sizer.Add(self.top_panel, 2, wx.EXPAND | wx.ALL, 5)
        main_sizer.Add(self.plot_panel, 3, wx.EXPAND | wx.ALL, 5)
        self.panel.SetSizer(main_sizer)

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

        # Set the default selection for the clustering distance function.
        self.cluster_distance_choice.SetStringSelection("GEH")

        # Set the default clustering method to "Average Linkage".
        self.cluster_method_choice.SetStringSelection("Average Linkage")

        # Enable the cutoff distance setting.
        self.use_max_distance.SetValue(True)

        # Set the default cutoff distance to 5.
        self.max_distance.SetValue(5)

        # Set the default federal state for holiday-based clustering to Baden-Württemberg ("BW").
        self.choice_state.SetStringSelection("BW")

        # Display default messages indicating that no data has been loaded.
        self.text_data.SetLabel("keine Ganglinien geladen")
        self.text_properties.SetLabel("keine Eigenschaften geladen")

        ## Set the default number of k-means iterations to 10.
        self.kmeans_repeats.SetValue(10)

        ## Set the default k-means initialization method to "++ Algorithmus".
        self.kmeans_preselect.SetStringSelection("++ Algorithmus")

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
                clusterer = modules.data_handler.load_clusterung_from_json(data_file)

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

                # Generate plots for the loaded clustering result.
                clusterer.plots_results()

                # Add the loaded clustering result to the analysis.
                self._add_clusterung(clusterer)

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

        # Ensure that k-means clustering has a valid cluster count.
        if method == "kmeans" and max_clusters is None:
            logging.error("Parameterkombination ist ungültig: Bei kmeans muss die Anzahl an Clustern definiert werden")
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
                distance_function=self.cluster_distance_choice.GetString(
                    self.cluster_distance_choice.GetCurrentSelection()
                ),
                cutoff=max_distance,
                max_clusters=max_clusters,
                kmeans_iter=self.kmeans_repeats.GetValue() if method == "kmeans" else None,
                kmeans_preset=self.kmeans_preselect.GetString(
                    self.kmeans_preselect.GetCurrentSelection()
                ) if method == "kmeans" else None,
                calendar_obj=self.calendar_obj,
                use_calendar=self.use_calendar_properties.IsChecked()
            )
            logging.info("Clusterobjekt erfolgreich angelegt")

            # Execute the clustering process.
            clusteranalysis.perform_clustering()

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
        except KeyError:
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
            popup = PlotPopup(self, fig=fig, title=f"Dendrogramm Ganglinien {clusterobj.method}")
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
        except KeyError:
            logging.error("Kein gültiges Clusterobjekt ausgewählt")
            return

        try:
            # Generate the distance matrix plot.
            fig = clusterobj.plot_distances()

            # Create a popup window to display the distance matrix.
            popup = PlotPopup(self, fig=fig, title="Distanzen Ganglinien")
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
        except KeyError:
            logging.error("Kein gültiges Clusterobjekt ausgewählt")
            return

        try:
            # Generate the silhouette plot.
            fig = clusterobj.plot_silhouette()

            # Create a popup window to display the silhouette diagram.
            popup = PlotPopup(self, fig=fig, title="Silhouettendiagramm Ganglinien")
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
        except KeyError:
            logging.error("Kein gültiges Clusterobjekt ausgewählt")
            return

        try:
            # Generate the calendar cluster plot.
            fig = clusterobj.plot_calendar_cluster()

            # Create a popup window to display the calendar visualization.
            popup = PlotPopup(self, fig=fig, title="Kalender Cluster")
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
        except KeyError:
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

        # 4. Initiale Liste der Datetime-Indizes im Dataset
        filtered_indices = pd.to_datetime(self.cluster_data.index)

        # 5. Filtern der Wochentage
        if len(day_short) < 7:
            num_char_day = len(day_short[0])
            weekdays = getattr(self.calendar_obj, "wochentag", getattr(self.calendar_obj, "weekday", {}))
            dict_keys = {key[:num_char_day]: key for key in weekdays.keys()}
            day_short = [dict_keys[day] for day in day_short]
            days = [date for day in day_short for date in
                    (weekdays[day].date.tolist() if isinstance(weekdays[day], pd.DatetimeIndex) else weekdays[day])]
            days = pd.to_datetime(days)
            #list(itertools.chain.from_iterable([date for day in day_short for date in weekdays[day]]))
            days = pd.to_datetime(days)
            filtered_indices = filtered_indices[filtered_indices.isin(days)]

        # 6. Filtern der Feiertage und Ferien
        holidays = set()
        if len(bank_holidays | school_holidays) == 2:
            pass
        elif len(bank_holidays | school_holidays) < 1:
            feiertage = getattr(self.calendar_obj, "feiertage", getattr(self.calendar_obj, "bank_holidays", {}))
            ferien = getattr(self.calendar_obj, "ferien",
                                 getattr(self.calendar_obj, "school_holidays", []))
            if len(feiertage) > 0:
                holidays.update({date for dates in feiertage.values() for date in dates})
            if len(ferien) > 0:
                holidays.update({date for dates in ferien.values() for date in dates})

        elif len(bank_holidays) < 1:
            feiertage = getattr(self.calendar_obj, "feiertage", getattr(self.calendar_obj, "bank_holidays", {}))
            if len(feiertage) > 0:
                holidays.update({date for dates in feiertage.values() for date in dates})
        elif len(school_holidays) < 1:
            ferien = getattr(self.calendar_obj, "ferien",
                                 getattr(self.calendar_obj, "school_holidays", []))
            if len(ferien) > 0:
                holidays.update({date for dates in ferien.values() for date in dates})
        else:
            logging.error("Unvorhergesehener Fall beim Filtern von Feiertagen und Ferien.")

        # Falls Feiertage vorhanden sind, diese herausfiltern
        if len(holidays) > 0:
            holidays = pd.to_datetime(list(holidays))
            filtered_indices = filtered_indices[~filtered_indices.isin(holidays)]

        # 7. Filtern nach Datumsbereich
        start_date = pd.to_datetime(self.start_date.GetValue().FormatISODate())
        end_date = pd.to_datetime(self.end_date.GetValue().FormatISODate())
        filtered_indices = filtered_indices[(filtered_indices >= start_date) & (filtered_indices <= end_date)].date

        # Logging der gefilterten Daten
        logging.info(f"Es werden {len(filtered_indices)} von {len(self.cluster_data)} Ganglinien berücksichtigt")

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
        # Add new entry to the table
        self.cluster_table.AppendItem(["True", str(id)] + clustering_obj.get_info().astype(str).values.tolist())

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
    def __init__(self, parent, fig, title):
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
        self.fig.update_layout(width=width * 0.93, height=height * 0.93,
                               margin=dict(l=20, r=20, t=30, b=20))

        # Save the figure as an HTML file
        plotly_html = "temp_plot.html"
        self.fig.write_html(plotly_html)

        # Load the HTML file into the WebView
        wx.CallAfter(self.web_view.LoadURL, f"file:///{os.path.abspath(plotly_html)}")


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
