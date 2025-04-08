# Anwendung der GUI

## Einführung
Diese Anleitung beschreibt die Nutzung der GUI des Clustertools zur Analyse von Verkehrsstärkeganglinien und anderen Daten.  
Die Grundlagen für ein vertiefendes Verständnis der Clusteranalyse sind in _Grundlagen Clusteranalyse_ zu finden.  
Details der Implementierung sowie die verwendeten Algorithmen sind im Quellcode bzw. der Dokumentation der Module vorhanden.

## Schnellstartanleitung
1. **Daten einlesen**  
    - Klicke auf „Datei Clusterung öffnen“, um die zu clusternden Objekte zu laden.
    - Optional können zusätzliche Eigenschaften für die Objekte geladen werden. Dazu muss „zusätzliche Eigenschaften“ aktiviert werden und eine Datei via „Datei öffnen“ geladen werden.
2. **Einstellungen vornehmen**  
    - Filtere die zu berücksichtigenden Objekte anhand der Kalendereigenschaften.
    - Optional: kalendarische Eigenschaften berücksichtigen. In diesem Fall muss das Bundesland angegeben werden.
    - Wähle die Clustermethode, Distanzfunktion und die weiteren Clusterparameter aus.
3. **Clusterung ausführen**  
    - Mit „Clusterung ausführen“ wird eine Clusterung mit den aktuellen Eigenschaften ausgeführt.

## Einstellungen der Clusterung

### Clustermethode
Folgende Methoden stehen zur Auswahl:
- **K-Means** (nur für die euklidische Distanz)
- **Average Linkage** (empfohlen für Verkehrsstärken)
- **Centroid Linkage** (nur für die euklidische Distanz)
- **Complete Linkage**
- **Median Linkage** (nur für die euklidische Distanz)
- **Single Linkage**
- **Ward-Verfahren** (nur für die euklidische Distanz)
- **Weighted Linkage**

### Distanzfunktion
Die Distanz zwischen Objekten wird berechnet mit:
- **GEH** (empfohlen für Verkehrsstärken)
- **SQV** (empfohlen für Verkehrsstärken)  
    - Wertebereich \([0, 1]\). Für die Clusterung wird der Wert \(1 - SQV\) verwendet.
    - Es wird ein leicht modifizierter SQV verwendet, bei dem das Maximum der zu vergleichenden Werte im Nenner steht.  
      Damit ist die Symmetrie \(SQV(q_1, q_2) = SQV(q_2, q_1)\) gewährleistet.
- **Euklidische Distanz**  

### Maximale Clusteranzahl & Distanz
- **Clusteranzahl festlegen**  
- **Maximale Distanz in einem Cluster** (empfohlen bei Ganglinien, nicht bei K-Means verfügbar)  
    - Werte sind vom gewählten Distanzmaß abhängig.
    - **SQV**: Wertebereich \([0, 1]\). Es kann der normale SQV-Wert verwendet werden, die Anpassung für die Clusterung erfolgt intern.

### K-Means Parameter (nur bei Auswahl von K-Means)
- **Anzahl Wiederholungen**  
- **Startbelegungsmethode**  
    - Zufällige Auswahl der Startcluster  
    - Normalverteilte Auswahl der Starcluster  
    - ++ Algorithmus (empfohlen)  

## Kalendereinstellungen
- **Zeitraum filtern**  
    - Wähle den Start- und Endzeitpunkt der Clusterung.
    - Damit können die Ganglinien innerhalb eines Intervalls gefiltert werden
- **Tagtypen filtern**  
    - Deaktiviere Wochentage, Feiertage oder Ferien, die ausgeschlossen werden sollen.
    - Für die Filterung der Ferien- und Feiertage muss das Bundesland angegeben werden.
  
- Berücksichtigung kalendarischer Eigenschaften bei der Analyse der Eigenschaften der Cluster. 
    - In diesem Fall muss das Bundesland für die Auswahl der Ferien und Feiertage angegeben werden. 
    - Es erfolgt eine Zuordnung der Daten zu Brückentagen, Wochentagen, Werktage, Monate, Jahreszeiten, Sommerzeit, Ferien und Feiertage
    - Die Berücksichtigung der kalendarischen Eigenschaften hat keine Auswirkung auf die Menge der verwendeten Ganglinien.
  

## Datenauswahl
- **Datei Clusterung öffnen**  
    - Lade eine `.xlsx`, `.csv`, `.mat` oder `.json` Datei mit den zu clusternden Daten als `pandas.DataFrame`.  
        - Die erste Spalte wird als DateTime interpretiert und als Index verwendet.
        - Falls die Daten nur 2 Spalten umfassen, werden Tagesganglinien gebildet.
        - Ansonsten wird jede Zeile als Clusterobjekt (=Ganglinie) interpretiert.
        - Spaltennamen werden erkannt & akzeptiert, wenn sie als Text formatiert sind.
        - Eine `.json` Datei ist nur zulässig, wenn sie das Ergebnis einer vorherigen Clusterung enthält.
        - Bei einer `.xlsx` Datei wird das erste Tabellenblatt eingelesen, es sei denn, sie enthält die Daten einer vorherigen Clusterung.  
          Diese werden automatisch erkannt und importiert.
- **Eigenschaften laden (optional)**  
    - Zusätzliche Informationen wie Wetterdaten, Baustellen oder Events hinzufügen.
    - Die zulässigen Formate & Datenaufbereitung erfolgen analog zum Import der Clusterdaten.  
      Es wird eine Spalte je Eigenschaft angenommen.
    - Die Eigenschaften haben keinen Einfluss auf die Clusterung, sondern können für die Analyse der resultierenden Cluster verwendet werden.  
      Die Eigenschaften können später visuell oder als Tabelle für die einzelnen Cluster angezeigt werden.

## Exportfunktionen
- **Button _Export Clusterung_**  
    - Speichert die aktive Clusterung als `.xlsx`, `.csv` oder `.json`  
        - `.csv`: Nur die repräsentativen Ganglinien der Clusterung  
        - `.xlsx`: Clusterobjekte, repräsentative Ganglinien der Clusterung und die Eigenschaften  
        - `.json`: Clustering-Objekt  
- **Button _Export alle Clusterungen_**  
    - Speichert alle Clusterungen in dem gewählten Format in einem Ordner.  
    - Das Schema der Benennung ist `_ID_Methode_Distanzfunktion_Param_`.
- **Button _Export Diagramme_**  
    - Exportiert alle Diagramme (Ganglinien und Eigenschaften) aller Clusterungen.
    - Dateiformate: `.html`, `.png`, `.jpg`, `.svg` oder `.pdf`
- **Export einzelner Diagramme**  
    - Dafür existiert kein Button, die Diagramme werden allerdings in der GUI in einer WebView-Umgebung angezeigt.  
      Diese ermöglicht einen Export als `.png`, `.html` sowie Screenshot- und Druckmöglichkeiten per Rechtsklick.
- **Export der Übersichtstabelle der Clusterungen**  
    - Rechtsklick auf die Übersichtstabelle  
    - Export als Excel-Tabelle  

## Visualisierungen in der GUI
> Hinweis: Die Cluster-IDs sind mit absteigender Clustergröße vergeben.  
> Eine Cluster-ID von -1 bedeutet, dass die Ganglinie nicht zugeordnet wurde. Ursächlich sind fehlende Daten.

- **Ganglinien** (rechte Grafik)  
    - oben: Clusterobjekte (einzelne Ganglinien)  
    - unten: repräsentative Ganglinien der Cluster  
- **Cluster-Eigenschaften** (linke Grafik)  
    - Balkendiagramm mit den Anteilen der Ausprägungen der gewählten Eigenschaft in den einzelnen Clustern
- **Button _Silhouettendiagramm_**  
    - Öffnet ein neues Fenster mit dem Silhouettendiagramm der aktiven Clusterung  
    - Das Silhouettendiagramm kann zur Bewertung, ob die Clusterung sinnvoll ist, verwendet werden.
- **Button _Dendrogramm_**  
    - Öffnet ein neues Fenster mit dem Dendrogramm der aktiven Clusterung  
    - Das Dendrogramm kann zur Identifikation sinnvoller CutOff-Werte verwendet werden.
- **Button _Distanzmatrix der Ganglinien_**  
    - Öffnet ein neues Fenster mit der Distanzmatrix der aktiven Clusterung.  
    - Die Distanzmatrix enthält die Distanzen zwischen allen Clusterobjektpaaren.  
    - Die Distanzmatrix kann zur Bewertung, ob die Clusterung sinnvoll ist, verwendet werden.
- **Button _Clusterkalender_**  
    - Öffnet ein neues Fenster mit den Kalendertagen der aktiven Clusterung, aufgeteilt nach Wochentagen je Kalenderwoche.  
    - Die Kalendertage sind mit der Farbe des zugeordneten Clusters markiert.  
    - Der Clusterkalender kann bei der Interpretation der resultierenden Cluster hilfreich sein.

## Weitere Funktionen
- **Button _Hilfe_**  
    - Öffnet ein Fenster, das diese Datei, die _Grundlagen Clusteranalyse_ sowie die autogenerierte Dokumentation des Codes enthält.
- **Tab _Log_**  
    - Enthält die Logging-Informationen  
    - Entspricht dem Inhalt von _Logfile.log_
