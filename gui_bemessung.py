## @package gui_bemessung
#  @brief GUI window for analyzing and visualizing design hourly volumes (DHV).
#
#  This module implements the interactive interface for configuring, executing, and visualizing
#  design hourly volume (DHV) analyses using wxPython and Plotly. It connects clustering results
#  and calendar-based filtering with calculation logic from the `dhv_analysing` module.
#
#  It offers a workflow that enables users to:
#  - Select data subsets (time periods, clusters, stations)
#  - Choose DHV calculation methods (nth hour or percentile)
#  - Visualize and export DHV results
#
#  The GUI logic is encapsulated in the `DesignHourlyVolumeWindow` class.
#
#  @author MaS
#  @date 2025
#
#  @note Requires a clustering object containing calendar and traffic volume data. It is called in gui_clustering.py


from pathlib import Path

import numpy as np
import wx
from wx.html2 import WebView
import wx.adv
import wx.dataview as dv
import plotly.graph_objects as go

import os
import logging
import pandas as pd

from modules import clustering, dhv_analysing

## @class DesignHourlyVolumeWindow
#  @brief A wxPython-based GUI for calculating and visualizing design hourly volumes (DHV).
#
#  The `DesignHourlyVolumeWindow` class provides an interactive interface for analyzing traffic data
#  using design hourly volume concepts. It allows users to select time periods, clusters,
#  counting stations, and calculation methods (e.g., nth hour or percentile).
#
#  This class integrates the DHV analysis logic from the `dhv_analysing` module and displays
#  the resulting plots using Plotly inside a WebView (HTML-rendered).
#
#  **Key features:**
#  - Parameter configuration for different DHV methods (nth hour or percentile)
#  - Data filtering by day, hour, calendar properties, and cluster membership
#  - Interactive diagram rendering using Plotly and HTML
#  - Export of DHV results to CSV or Excel
#
#  @see dhv_analysing.DHVAnalysing
class DesignHourlyVolumeWindow(wx.Frame):
    ## @brief Initializes the window PopUp about design hourly volumes.
    #  @param parent The parent wx object.
    #  @param clusterobj The clustering object containing the indicators.
    #  @param title The title of the window.
    def __init__(self, parent, clusterobj: clustering.Clusterung=None,
                 dhv_analysis_obj: dhv_analysing.DHVAnalysing=None,
                 title="Analyse Dauerlinien und Bemessungsverkehrsstärken", cluster_id=None,
                 num_decimal_places=0):
        # Update title with cluster_id if provided
        if cluster_id is not None:
            title = f"{title} (ID: {cluster_id})"
        super(DesignHourlyVolumeWindow, self).__init__(parent, title=title, size=(900, 600))

        logging.info(f"Fenster für Dauerlinien und Bemessungsverkehrsstärken wird initialisiert")

        ## @var clusterobj
        #  The clustering object containing the indicators.
        if clusterobj is not None:
            self.clusterobj = clusterobj
            logging.info(f"Clusterobjekt mit {len(clusterobj.data)} Datenpunkten geladen")

        if dhv_analysis_obj is None:
            if self.clusterobj is not None:
                self.dhv_analysis = dhv_analysing.DHVAnalysing(clusterobj)
                logging.info("Bemessungsverkehrsstärke-Analyseobjekt wurde erstellt")
            else:
                logging.error("Kein Clusterobjekt vorhanden, Bemessungsverkehrsstärke-Analyseobjekt kann nicht erstellt werden")
        else:
            self.dhv_analysis = dhv_analysis_obj
            logging.info("Bestehendes Bemessungsverkehrsstärke-Analyseobjekt wird verwendet")

        ## @var num_decimal_places
        #  Number of decimal places to use when rounding values in tables.
        self.num_decimal_places = num_decimal_places

        self.__set_layout()
        self.__bind_events()

        self._set_default()

        self._on_update_plot()

    def __set_layout(self):
        panel = wx.Panel(self)  # Correct: panel is a child of the frame (self)

        # These panels must be children of `panel`
        self.top_panel = wx.Panel(panel)
        self.plot_panel = wx.Panel(panel)

        ## Define padding for spacing between elements
        padding = 2

        default_flags = wx.ALL | wx.EXPAND  # | wx.SHRINK

        # ==== Top Panel ====
        self.dhv_settings_panel = wx.Panel(self.top_panel)
        data_choice_panel = wx.Panel(self.top_panel)
        control_panel = wx.Panel(self.top_panel)

        # -----------------------------------
        # Group 1: Bemessungskonzepte
        # -----------------------------------

        settings_sizer = wx.StaticBoxSizer(wx.VERTICAL, self.dhv_settings_panel, "Einstellungen Ermittlung Bemessungsverkehrsstärken")
        params_sizer = wx.StaticBoxSizer(wx.VERTICAL, self.dhv_settings_panel, "Parameter Bemessungskonzept")

        method_choices = ["n. Stunde", "Perzentil"]
        self.method_radiobox = wx.RadioBox(
            self.dhv_settings_panel,
            label="Bemessungskonzept",
            choices=method_choices,
            majorDimension=0,  # 0 bedeutet, alle Elemente in einer Reihe/Spalte basierend auf dem Stil
            style=wx.RA_SPECIFY_COLS  # Anordnung in Zeilen (horizontal für majorDimension=0)
        )

        self.choice_n = wx.SpinCtrl(self.dhv_settings_panel, min=1, max=8784, initial=50)
        self.share_1toN_in_dataset = wx.SpinCtrlDouble(self.dhv_settings_panel, min=0, max=1.0, initial=0.5,
                                                       inc=0.01, style=wx.ALIGN_RIGHT)
        self.percentile = wx.SpinCtrlDouble(self.dhv_settings_panel, min=0, max=100, initial=99.4,
                                                       inc=0.1, style=wx.ALIGN_RIGHT)
        self.calc_percentile_button = wx.Button(self.dhv_settings_panel, label="Perzentil berechnen")
        self.text_number_data = wx.StaticText(self.dhv_settings_panel)

        params_r1 = wx.BoxSizer(wx.HORIZONTAL)
        params_r1.Add(wx.StaticText(self.dhv_settings_panel, label="Auswahl n"), 0, wx.ALL | wx.EXPAND, padding)
        params_r1.Add(self.choice_n, 0, wx.ALL | wx.EXPAND, padding)
        params_r1.AddSpacer(20)
        # params_r2 = wx.BoxSizer(wx.HORIZONTAL)
        params_r1.Add(wx.StaticText(self.dhv_settings_panel, label="Bemessungsperzentil"), 0, wx.ALL | wx.EXPAND, padding)
        params_r1.Add(self.percentile, 0, wx.ALL | wx.EXPAND, padding)
        params_r1.AddSpacer(40)
        params_r1.Add(self.calc_percentile_button, 1, wx.ALL | wx.EXPAND, padding)

        params_r3 = wx.StaticBoxSizer(wx.HORIZONTAL, self.dhv_settings_panel, "Weitere Parameter Perzentilberechnung")
        params_r3.Add(wx.StaticText(self.dhv_settings_panel, label="Annahme Anteil Stunden 1-n \n in der Datenmenge"), 0, wx.ALL | wx.EXPAND, padding)
        params_r3.Add(self.share_1toN_in_dataset, 0, wx.ALL | wx.EXPAND, padding)
        params_r3.AddSpacer(40)
        params_r3.Add(self.text_number_data, 1, wx.ALL | wx.EXPAND, padding)

        params_sizer.Add(params_r1, 0, wx.ALL | wx.EXPAND, padding)
        # params_sizer.Add(params_r2, 0, wx.ALL | wx.EXPAND, padding)
        params_sizer.Add(params_r3, 0, wx.ALL | wx.EXPAND, padding)

        settings_sizer.Add(self.method_radiobox,0, wx.ALL | wx.EXPAND, padding)
        settings_sizer.Add(params_sizer, 0, wx.ALL | wx.EXPAND, padding)


        self.dhv_settings_panel.SetSizer(settings_sizer)

        # -----------------------------------
        # Group 2: Filter days & cs
        # -----------------------------------
        # self.filter_data_button = wx.Button(data_choice_panel, label="Update Datenfilter")

        ## @var start_date
        #  DatePicker for selecting the start date
        self.start_date = wx.adv.DatePickerCtrl(data_choice_panel)

        ## @var end_date
        #  DatePicker for selecting the end date
        self.end_date = wx.adv.DatePickerCtrl(data_choice_panel)

        ## @var choice_state
        #  Dropdown for selecting a German federal state for holiday data
        self.choice_state = wx.Choice(data_choice_panel, choices=['BW', 'BY', 'BE',
                                                                    'BB', 'HB', 'HH', 'HE', 'MV',
                                                                    'NI', 'NW', 'RP', 'SL', 'SN',
                                                                    'ST', 'SH', 'TH'])

        # Anzahl der gewünschten sichtbaren Zeilen für die ListBox
        desired_visible_lines = 5  # Sie können diesen Wert anpassen

        # Berechnen Sie die Höhe basierend auf der Schriftgröße und der gewünschten Zeilenanzahl
        # Ein Multiplikator von 1.2 berücksichtigt den Zeilenabstand und ist ein guter Startwert
        item_height = wx.SystemSettings.GetFont(wx.SYS_DEFAULT_GUI_FONT).GetPixelSize().height * 1.2

        self.choice_cs = wx.ListBox(
            data_choice_panel,
            choices=self.dhv_analysis.series_cs.index.to_list(),
            style=wx.LB_EXTENDED | wx.LB_NEEDED_SB | wx.LB_SORT,  # Mehrfachauswahl und Scrollbalken bei Bedarf
            size=(wx.DefaultSize.width, int(desired_visible_lines * item_height))  # Explizite Höhe setzen
        )

        self.choice_hours = wx.ListBox(
            data_choice_panel,
            choices = [str(x) for x in range(0,24)], #+ ["SP", "SP am", "SP pm"],
            style=wx.LB_EXTENDED | wx.LB_NEEDED_SB, # Mehrfachauswahl und Scrollbalken bei Bedarf
            size=(wx.DefaultSize.width, int(desired_visible_lines * item_height))  # Explizite Höhe setzen
        )

        self.choice_clusters = wx.ListBox(
            data_choice_panel,
            choices = [str(x) for x in self.clusterobj.clusters.unique()], #
            style=wx.LB_EXTENDED | wx.LB_NEEDED_SB | wx.LB_SORT, # Mehrfachauswahl und Scrollbalken bei Bedarf
            size=(wx.DefaultSize.width, int(desired_visible_lines * item_height))  # Explizite Höhe setzen
        )

        ## @var checkboxes_calendar
        #  List of checkboxes for selecting calendar-related filters (e.g., weekdays, holidays)
        check_cal = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So", "Ferien", "Feiertage"]
        self.checkboxes_calendar = []
        cal_checkboxes = wx.BoxSizer(wx.HORIZONTAL)
        for label in check_cal:
            checkbox = wx.CheckBox(data_choice_panel, label=label)
            cal_checkboxes.Add(checkbox, 0, default_flags, padding)
            self.checkboxes_calendar.append(checkbox)

        data_choice_sizer = wx.StaticBoxSizer(wx.VERTICAL, data_choice_panel, "Einstellungen Datenauswahl")

        # calendar_sizer_r1 = wx.BoxSizer(wx.HORIZONTAL)
        calendar_sizer_r2 = wx.BoxSizer(wx.HORIZONTAL)
        data_choice_r3 = wx.BoxSizer(wx.HORIZONTAL)

        calendar_sizer_r2.Add(wx.StaticText(data_choice_panel, label="Erster Tag"), 0,
                              wx.ALIGN_CENTER_VERTICAL | wx.ALL, padding)
        calendar_sizer_r2.Add(self.start_date, 0, default_flags, padding)
        calendar_sizer_r2.AddSpacer(40)
        calendar_sizer_r2.Add(wx.StaticText(data_choice_panel, label="Letzter Tag"), 0,
                              wx.ALIGN_CENTER_VERTICAL | wx.ALL, padding)
        calendar_sizer_r2.Add(self.end_date, 0, default_flags, padding)
        calendar_sizer_r2.AddSpacer(40)
        calendar_sizer_r2.Add(wx.StaticText(data_choice_panel, label="Ferien Land"), 0,
                              wx.ALIGN_CENTER_VERTICAL | wx.ALL, padding)
        calendar_sizer_r2.Add(self.choice_state, 0, default_flags, padding)

        data_choice_sizer.Add(calendar_sizer_r2, 0, default_flags, padding)
        data_choice_sizer.Add(cal_checkboxes, 0, default_flags, padding)

        data_choice_r3.Add(wx.StaticText(data_choice_panel, label="Zählstellen"), 0,)
        data_choice_r3.Add(self.choice_cs, 1, default_flags, padding)
        data_choice_r3.AddSpacer(40)
        data_choice_r3.Add(wx.StaticText(data_choice_panel, label="Stunden"), 0,)
        data_choice_r3.Add(self.choice_hours, 1, default_flags, padding)
        data_choice_r3.AddSpacer(40)

        data_choice_r3.Add(wx.StaticText(data_choice_panel, label="Cluster"), 0,)
        data_choice_r3.Add(self.choice_clusters, 1, default_flags, padding)

        # data_choice_r3.Add(self.filter_data_button, 1, default_flags, padding) # in Button Block auslagern

        data_choice_sizer.Add(data_choice_r3, 0, default_flags, padding)

        # data_choice_sizer.Add(calendar_sizer_r1, 1, default_flags, padding)

        data_choice_panel.SetSizer(data_choice_sizer)

        # Control buttons Update diagrams
        self.update_button = wx.Button(control_panel, label="Update Dauerlinien")
        self.calculate_dhv_button = wx.Button(control_panel, label="Ermittlung der Bemessungsverkehrsstärken")
        self.update_dhv_button = wx.Button(control_panel, label="Update Bemessungsverkehrsstärken in Dauerlinien")
        self.reset_dhv_button =wx.Button(control_panel, label="Reset Bemessungsverkehrsstärken")
        self.export_button = wx.Button(control_panel, label="Export Bemessungsverkehrsstärken")
        self.filter_data_button = wx.Button(control_panel, label="Update Datenfilter")

        control_sizer = wx.BoxSizer(wx.HORIZONTAL)
        control_c1 = wx.BoxSizer(wx.VERTICAL)
        control_c2 = wx.BoxSizer(wx.VERTICAL)

        control_c1.Add(self.filter_data_button, 1, default_flags, padding)
        control_c2.Add(self.update_button, 1, default_flags, padding)
        control_c1.Add(self.calculate_dhv_button, 1, default_flags, padding)
        control_c1.Add(self.update_dhv_button, 1, default_flags, padding)
        control_c2.Add(self.export_button, 1, default_flags, padding)
        control_c2.Add(self.reset_dhv_button, 1, default_flags, padding)

        control_sizer.Add(control_c1, 1, wx.EXPAND | wx.ALL, padding)
        control_sizer.Add(control_c2, 1, wx.EXPAND | wx.ALL, padding)
        control_panel.SetSizer(control_sizer)

        top_sizer = wx.BoxSizer(wx.HORIZONTAL)
        top_sizer.Add(self.dhv_settings_panel, 0, wx.EXPAND | wx.ALL, padding)
        top_sizer.Add(data_choice_panel, 0, wx.EXPAND | wx.ALL, 5)
        top_sizer.Add(control_panel, 1, wx.EXPAND | wx.ALL, 5)
        self.top_panel.SetSizer(top_sizer)  # Set top_sizer on self.top_panel

        # ==== Plot Panel ====
        plot_sizer = wx.BoxSizer(wx.VERTICAL)
        ## @var web_view
        #  A WebView widget to render the Plotly figure as an HTML page.
        # self.web_view must be a child of self.plot_panel
        self.web_view = wx.html2.WebView.New(self.plot_panel, backend=wx.html2.WebViewBackendEdge)

        plot_sizer.Add(self.web_view, 1, wx.EXPAND, 10)
        self.plot_panel.SetSizer(plot_sizer)  # Set plot_sizer on self.plot_panel

        ## @var main_sizer
        #  Main vertical sizer for the entire layout
        main_sizer = wx.BoxSizer(wx.VERTICAL)
        main_sizer.Add(self.top_panel, 1, default_flags, padding)  # self.top_panel is now a child of panel
        main_sizer.Add(self.plot_panel, 4, default_flags, padding)  # self.plot_panel is now a child of panel

        panel.SetSizer(main_sizer)  # main_sizer is set on panel (correct)
        panel.Layout()  # Ensures the layout is updated for the panel
        self.Layout()  # Ensures the frame layout is updated
        self.Maximize()


    def __bind_events(self):
        # Events für Haupt-Buttons
        self.update_button.Bind(wx.EVT_BUTTON, self._on_update_plot)
        self.calculate_dhv_button.Bind(wx.EVT_BUTTON, self._on_calculate_dhv)
        self.update_dhv_button.Bind(wx.EVT_BUTTON, self._on_update_dhv_in_diagram)
        self.reset_dhv_button.Bind(wx.EVT_BUTTON, self._on_reset_dhv)
        self.export_button.Bind(wx.EVT_BUTTON, self.on_export_dhv_data)

        # Event für Perzentil berechnen Button
        self.calc_percentile_button.Bind(wx.EVT_BUTTON, self._on_calculate_percentile)

        self.filter_data_button.Bind(wx.EVT_BUTTON, self._on_filter_data)

        self.Bind(wx.EVT_SIZE, self._on_change_size_plot) # Größenänderung


    ## @brief Calculates design hourly volumes based on the selected method.
    #
    #  This method is called when the DHV calculation method (nth hour/percentile) is changed.
    #  It retrieves the selected method and parameters, then calculates the design hourly volumes.
    #
    #  @param event The wxPython event object.
    def _on_calculate_dhv(self, event):
        selection = self.method_radiobox.GetStringSelection()
        logging.info(f"Berechnung der Bemessungsverkehrsstärken mit Methode: {selection}")

        if selection == "n. Stunde":
            n_value = int(self.choice_n.GetValue())
            logging.info(f"Parameter: n = {n_value}")
            self.dhv_analysis.calculate_dhv(selection, n=n_value)
        elif selection == "Perzentil":
            p_value = float(self.percentile.GetValue())
            logging.info(f"Parameter: Perzentil = {p_value}%")
            self.dhv_analysis.calculate_dhv(selection, p=p_value)
        else:
            logging.warning("Bemessungskonzept nicht implementiert")
            return

        logging.info("Bemessungsverkehrsstärken wurden erfolgreich berechnet")





    ## @brief Calculates the percentile value based on the nth hour and share parameters.
    #
    #  This method is called when the 'Calculate Percentile' button is clicked.
    #  It calculates the percentile value that corresponds to the specified nth hour
    #  and the share of hours from 1 to n in the dataset.
    #
    #  @param event The wxPython event object.
    def _on_calculate_percentile(self, event):
        try:
            n_value = int(self.choice_n.GetValue())
            share_hours_1_n = float(self.share_1toN_in_dataset.GetValue())
            num_hours = self.dhv_analysis.data_for_dhv.groupby('cs').idx_col.count().max()

            logging.info(f"Berechnung des Perzentilwerts mit n = {n_value} und Anteil = {share_hours_1_n}")
            logging.info(f"Gesamtanzahl der Stunden im Datensatz: {num_hours}")

            p = (1 - (share_hours_1_n * n_value / num_hours) )*100
            self.percentile.SetValue(p)
            self.text_number_data.SetLabel(f"Anzahl Stunden: {num_hours}")

            logging.info(f"Berechneter Perzentilwert: {p:.2f}%")

        except ValueError:
            logging.error("Berechnung des Perzentilwerts nicht möglich - ungültige Eingabewerte")
        except Exception as e:
            logging.error(f"Fehler bei der Berechnung des Perzentilwerts: {e}")


    ## @brief Updates the plot display in the WebView control.
    #
    #  This method updates the plot of sorted volumes and design hourly volumes.
    #  It can either recalculate the plot or just update its size. The plot is saved
    #  as an HTML file and then loaded into the WebView control.
    #
    #  @param event The wxPython event object (optional).
    #  @param recalculate Boolean flag indicating whether to recalculate the plot (default: True).
    def _on_update_plot(self, event=None, recalculate=True):
        # Save the figure as an HTML file
        plotly_html = "temp_plot_dhv.html"

        # Direkte Größe der WebView verwenden
        available_height = self.web_view.GetSize().height

        try:
            if recalculate:
                logging.info("Neuberechnung des Dauerlinien-Diagramms")
                self.dhv_analysis.fig = None
                self.dhv_analysis.plot_sorted_volumes_dhv(plot_height=available_height)
            else:
                logging.info("Aktualisierung der Diagrammgröße")
                height = max(self.dhv_analysis.fig.layout.height, available_height)
                self.dhv_analysis.fig.update_layout(height=height)

            self.dhv_analysis.fig.write_html(plotly_html)
            logging.info(f"Diagramm als HTML-Datei gespeichert: {plotly_html}")

            # Load the HTML file into the WebView
            wx.CallAfter(self.web_view.LoadURL, f"file:///{os.path.abspath(plotly_html)}")
            logging.info("Diagramm in WebView geladen")
        except Exception as e:
            logging.error(f"Fehler beim Aktualisieren des Diagramms: {e}")


    ## @brief Handles window resize events to update the plot size.
    #
    #  This method is called when the window is resized. It updates the plot
    #  to fit the new window size without recalculating the data.
    #
    #  @param event The wxPython size event object.
    def _on_change_size_plot(self, event):
        event.Skip()
        try:
            # Plot mit neuer Größe aktualisieren
            self._on_update_plot(recalculate=False)
        except Exception as e:
            print(f"Fehler bei Plot-Aktualisierung nach Größenänderung: {e}")


    ## @brief Updates the design hourly volumes in the diagram.
    #
    #  This method updates the display of design hourly volumes in the plot.
    #  It saves the updated figure as an HTML file and reloads it in the WebView control.
    #
    #  @param event The wxPython event object.
    def _on_update_dhv_in_diagram(self, event):

        self.dhv_analysis.update_dhv_in_diagram()

        # Save the figure as an HTML file
        plotly_html = "temp_plot_dhv.html"
        self.dhv_analysis.fig.write_html(plotly_html)

        # Load the HTML file into the WebView
        wx.CallAfter(self.web_view.LoadURL, f"file:///{os.path.abspath(plotly_html)}")

        logging.info("Update Verkehrsstärken in Diagramm erfolgreich abgeschlossen.")


    ## @brief Filters the data based on user selections.
    #
    #  This method applies filters to the data based on the user's selections for
    #  counting stations, hours, and days. It uses the apply_filter wrapper method
    #  instead of calling update_data_dhv directly.
    #
    #  @param event The wxPython event object.
    def _on_filter_data(self, event):
        logging.info("Anwendung von Datenfiltern gestartet")

        # Get filter selections from GUI
        list_cs = None if len(self.get_selected_cs()) < 1 else self.get_selected_cs()
        list_hours = None if len(self.get_selected_hours()) < 1 else self.get_selected_hours()
        list_days = None if len(self.get_selected_days()) < 1 else self.get_selected_days()

        # Log filter selections
        if list_cs is None:
            logging.info("Filter Zählstellen: Alle")
        else:
            logging.info(f"Filter Zählstellen: {list_cs}")

        if list_hours is None:
            logging.info("Filter Stunden: Alle")
        else:
            logging.info(f"Filter Stunden: {list_hours}")

        if list_days is None:
            logging.info("Filter Tage: Alle")
        else:
            logging.info(f"Filter Tage: {len(list_days)} Tage ausgewählt")

        # Update the filter dictionary in dhv_analysis instance
        self.dhv_analysis.filter["cs"] = "all" if list_cs is None else list_cs
        self.dhv_analysis.filter["hours"] = "all" if list_hours is None else list_hours
        self.dhv_analysis.filter["days"] = "all" if list_days is None else list_days

        try:
            # Use the wrapper method instead of calling update_data_dhv directly
            self.dhv_analysis.apply_filter()

            # Update GUI display
            num_hours = self.dhv_analysis.data_for_dhv.groupby('cs').idx_col.count().max()
            self.text_number_data.SetLabel(f"Anzahl Stunden: {num_hours}")
            logging.info(f"Datenfilter erfolgreich angewendet. Anzahl verbleibender Stunden: {num_hours}")
        except Exception as e:
            logging.error(f"Fehler beim Anwenden der Datenfilter: {e}")


    ## @brief Resets the design hourly volumes and clears the diagram.
    #
    #  This method removes all annotations and shapes from the plot and clears
    #  the dictionary of design hourly volumes. It then updates the display.
    #
    #  @param event The wxPython event object.
    def _on_reset_dhv(self, event):

        self.dhv_analysis.fig.layout.annotations = []
        self.dhv_analysis.fig.layout.shapes = []

        self.dhv_analysis.dict_dhv = dict()

        # Save the figure as an HTML file
        plotly_html = "temp_plot_dhv.html"
        self.dhv_analysis.fig.write_html(plotly_html)

        # Load the HTML file into the WebView
        wx.CallAfter(self.web_view.LoadURL, f"file:///{os.path.abspath(plotly_html)}")
        logging.info("Alle Bemessungsverkehrsstärken wurden gelöscht")


    ## @brief Resets all filters to their default values.
    #
    #  This method resets all filter selections to their default values and
    #  updates the DHV analysis object accordingly.
    #
    #  @param event The wxPython event object.
    def _on_reset_filter(self, event):
        self._set_default()
        self.dhv_analysis.reset_filter()

    ## @brief Sets all GUI controls to their default values.
    #
    #  This method resets all GUI controls to their default values, including
    #  calendar checkboxes, state selection, date range, and counting station selection.
    def _set_default(self):

        # Enable all calendar-related checkboxes by default.
        for checkbox in self.checkboxes_calendar:
            checkbox.SetValue(True)

        if self.clusterobj is not None:
            if hasattr(self.clusterobj, 'calendar') and hasattr(self.clusterobj.calendar, 'state'):
                state_string = self.clusterobj.calendar.state
                # Finden Sie den Index des Strings in den Choice-Optionen
                index = self.choice_state.FindString(state_string)
                if index != wx.NOT_FOUND:
                    self.choice_state.SetSelection(index)
                else:
                    logging.warning(f"Bundesland '{state_string}' nicht in den Auswahlmöglichkeiten gefunden.")
            else:
                logging.warning("calendar-Objekt oder 'state'-Attribut nicht in clusterobj gefunden.")

        self.start_date.SetValue(self.dhv_analysis.data.index.min())
        self.end_date.SetValue(self.dhv_analysis.data.index.max())

        #Setzt die Zählstellen-Auswahl auf 'keine Auswahl' zurück
        self.choice_cs.SetSelection(wx.NOT_FOUND)
        self.choice_hours.SetSelection(wx.NOT_FOUND)


    ## @brief Gets the list of selected counting stations.
    #
    #  @return List of selected counting station names.
    def get_selected_cs(self):
        selected_indices = self.choice_cs.GetSelections()
        return [self.choice_cs.GetString(i) for i in selected_indices]

    ## @brief Gets the list of selected hours.
    #
    #  @return List of selected hours as integers.
    def get_selected_hours(self):
        selected_indices = self.choice_hours.GetSelections()
        return [int(self.choice_hours.GetString(i)) for i in selected_indices]

    ## @brief Gets the list of selected clusters.
    #
    #  @return List of selected cluster IDs as integers.
    def get_selected_clusters(self):
        selected_indices = self.choice_clusters.GetSelections()
        return [int(self.choice_clusters.GetString(i)) for i in selected_indices]


    ## @brief Gets the list of selected days based on calendar filters.
    #
    #  This method filters days based on selected weekdays, holidays, school holidays,
    #  date range, and optionally cluster membership.
    #
    #  @return List of filtered date indices.
    def get_selected_days(self):
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

        filtered_indices = self.clusterobj.calendar._get_filtered_indices_data(pd.to_datetime(self.dhv_analysis.data.index),
                                                                        days_to_include=day_short,
                                                                        include_bank_holidays= True if len(bank_holidays) > 0 else False,
                                                                        include_school_holidays= True if len(school_holidays) > 0 else False,
                                                                        start_date = pd.to_datetime(self.start_date.GetValue().FormatISODate()),
                                                                        end_date = pd.to_datetime(self.end_date.GetValue().FormatISODate()))
        list_cluster = self.get_selected_clusters()
        if len(list_cluster) > 0 and self.clusterobj is not None:
            cluster_dates = self.clusterobj.clusters.loc[self.clusterobj.clusters.isin(list_cluster)].index.date
            # Schnittmenge der gefilterten Tage und der Tage der Cluster
            filtered_indices = np.intersect1d(cluster_dates, filtered_indices)

        return filtered_indices


    ## @brief Exports the design hourly volume (DHV) data to a file.
    #
    #  This method allows the user to save the calculated design hourly volume data
    #  to either a CSV or Excel file. The data is exported from the DHV analysis object.
    #
    #  @param event The wxPython event object.
    def on_export_dhv_data(self, event):
        # Prompt the user to select a file location for saving.
        filepath = self._select_file2save()

        # If no file was selected, abort the export process.
        if filepath is None:
            logging.info("Der Exportvorgang wurde abgebrochen.")
            return

        df_dhv = pd.DataFrame.from_dict(self.dhv_analysis.dict_dhv, orient="index")

        # Determine the file format and save the data accordingly.
        if filepath.suffix == ".csv":
            df_dhv.astype(int).to_csv(filepath, header=True, index=True)
        elif filepath.suffix == ".xlsx":
            df_dhv.to_excel(filepath, header=True, index=True, float_format="%.0f")
        else:
            logging.error("Dieses Dateiformat wird aktuell nicht unterstützt")
            return

        logging.info("Datei ist erfolgreich gespeichert")


    ## @brief Opens a file dialog for saving data in CSV, Excel, or JSON format.
    #
    #  This method prompts the user to select a file location for saving clustering data.
    #  It allows only specific formats: CSV, Excel (`.xlsx`).
    #
    #  @return Path object of the selected file or None if the user cancels.
    def _select_file2save(self):
        # Define allowed file formats.
        wildcard = "CSV-Datei (*.csv)|*.csv|Excel-Datei (*.xlsx)|*.xlsx|JSON-Datei (*.json)|*.json"

        # Default directory for saving data files.
        default_dir = Path(__file__).parent / "data"

        # Define allowed file formats.
        wildcard = "CSV-Datei (*.csv)|*.csv|Excel-Datei (*.xlsx)|*.xlsx"

        # Default directory for saving data files.
        default_dir = Path(__file__).parent / "data"

        # Open a file dialog for selecting a save location.
        with wx.FileDialog(self, "Datei speichern", defaultDir=str(default_dir),
                           wildcard=wildcard,
                           style=wx.FD_SAVE | wx.FD_OVERWRITE_PROMPT) as fileDialog:

            # If the user cancels, return None.
            if fileDialog.ShowModal() == wx.ID_CANCEL:
                return None

            # Retrieve the selected file path.
            data_file = Path(fileDialog.GetPath())

            return data_file
