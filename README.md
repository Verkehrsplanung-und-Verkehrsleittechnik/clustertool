# Clustertool

Das **Clustertool** des Lehrstuhls bietet eine Sammlung von Modulen zur Clusteranalyse und visuellen Analyse von Ergebnissen. Es umfasst mehrere Clusteralgorithmen, Ähnlichkeitsmaße sowie Methoden zur Datenaufbereitung und zur Analyse der resultierenden Cluster. Die Software bietet eine benutzerfreundliche **grafische Benutzeroberfläche (GUI)**, die für Clusteranalysen von Verkehrsstärkeganglinien optimiert ist.

**Hinweis**: Es wird kein Support und keine Haftung von Seiten des Lehrstuhls übernommen.

## Dokumentation

Die **Dokumentation** ist in der GUI unter dem Menüpunkt "Hilfe" verfügbar. Zusätzlich sind die folgenden Dokumente im Ordner `_documentation_` enthalten:

- **Anwendung_GUI.md**: Beschreibung der einzelnen Komponenten der GUI.
- **Grundlagen_Clusteranalyse.md**: Detaillierte Untersuchungen zu Einflussfaktoren der Clusterung und Begrifflichkeiten. Abgeleitet von der Datei _Untersuchung_Clusterung_Ganglinie.ipynb_.
- **doxygen**: Automatisch generierte Dokumentation des Codes. Öffnen per Doppelklick auf eine Datei. Die Startseite befindet sich in _index.html_.

Bilder zu den Markdown-Dateien befinden sich im Unterordner `_pictures_`.

## Komponenten

Das Clustertool ist in **Python** implementiert und verwendet insbesondere die folgenden Bibliotheken:

- **wxPython**: Für die grafische Benutzeroberfläche (GUI).
- **scipy**: Für wissenschaftliche Berechnungen.
- **pandas**: Für die Datenmanipulation und -analyse.
- **numpy**: Für numerische Berechnungen.
- **plotly**: Für interaktive Datenvisualisierungen.

Die wichtigsten Module des Clustertools:

- **calendar_attributes**: Funktionen zur Abfrage und Aufbereitung kalenderbezogener Attribute.
- **clustering**: Clusteranalyse und Visualisierung von Zeitreihen, insbesondere Ganglinien.
- **data_handler**: Datenaufbereitung, Import und Export.
- **gui_clustering**: Grafische Benutzeroberfläche für die Clusteranalyse.
- **metrics**: Implementierung von Distanz- und Ähnlichkeitsmetriken für die Clusteranalyse.

Der Unterordner **`data/`** enthält Beispielsdaten sowie lokal gespeicherte Kalenderinformationen.

## Anwendung

### Anwendung per GUI (kompiliert, ohne Python)

1. Lade das **Clustertool** als kompilierte Version herunter (zu finden unter **Releases**). 
   Die oben beschriebenen Ordner sind in **_internal/** enthalten.
2. Entpacke das ZIP-Archiv.
3. Führe die Datei **`clustertool.exe`** aus.

### Anwendung per GUI (mit Python)

1. Klone oder lade das Projektverzeichnis herunter.
2. Installiere die Abhängigkeiten, die in der Datei **`requirements.txt`** angegeben sind.
   
   > Hinweis: Das Tool wurde mit Python **3.9** getestet. Andere Versionen ab **Python 3.6** sollten ebenfalls kompatibel sein, es gibt jedoch keine Gewähr.
   
3. Führe **`run_gui.py`** oder **`gui_clustering.py`** aus, um die grafische Benutzeroberfläche zu starten.

### Anwendung ohne GUI (mit Python)

1. Klone oder lade das Projektverzeichnis herunter.
2. Installiere die Abhängigkeiten aus der **`requirements.txt`**.
   
   > Hinweis: Das Tool wurde mit Python **3.9** getestet. Andere Versionen ab **Python 3.6** sollten ebenfalls kompatibel sein, es gibt jedoch keine Gewähr.
   
3. Erstelle ein eigenes Anwendungsskript in der oberen Ordnerebene oder passe Dateipfade entsprechend an.

   Beispiel: **`run_clustering.py`**

