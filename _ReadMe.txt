Anleitung des Clustertools:

--------------------------------------
!!! KEINE GARANTIE AUF RICHTIGKEIT !!!
--------------------------------------
Es wird keine Haftung bei Fehlern übernommen.

Das Tool kann verwendet werden um beliebige Objekte zu Clustern.
Optimiert ist die Clusterung auf Verkehrsstärkeganglinien. 

------------------------------------------------------------------------------------------------------------------------
SCHNELLANLEITUNG
------------------------------------------------------------------------------------------------------------------------
	1.) Daten einlesen -> Button "Clusterdata Datei öffnen"
	2.) Einstellungen vornehmen (Clustermethode, Distanzfunktion, Kalenderdaten, ...)
	3.) Clusterung anlegen -> Button "Neue Clusterung anlegen"
			Die eingelesenen Daten und die Einstellungen werden gespeichert und können in dieser angelegten Clusterung nicht mehr verändert werden.
	4.) Clusterung starten -> Button "...starten"

------------------------------------------------------------------------------------------------------------------------
EINSTELLUNG CLUSTERUNG
------------------------------------------------------------------------------------------------------------------------
-|| Clustermethode ||-
	Es stehen verschiedene Methoden zur Auswahl. 
	- Kmeans
	- Single Linkage
	- Complete Linkage
	- Average Linkage  (wird für Verkehrsstärken empfohlen)
	- Weighted Linkage
	- Median Linkage
	- Ward - Verfahren 
	Für weitere Informationen zu den Verfahren bitte bei Wikipedia oder Fachliteratur nachschauen.

-|| Distanzfunktion ||-
	Für die Berechnung der Distanzen von den unterschiedlichen Objekten (Tagesganglinien)
	muss ein Distanzmaß definiert werden. Zur Auswahl stehen
	- GEH (wird für Verkehrsstärken in der Einheit Kfz/h empfohlen)
	- Euklidische Distanz

Weiter muss eine eingestellt werden, wie detailliert die Clusterung sein soll, d.h.
ob sehr grob oder fein geclustert werden soll.
Mithilfe der beiden Radiobuttons auf der rechten Seite im Feld "Einstellung Clusterung" kann eingestellt werden, ob 
	1.) eine Anzahl an Clustern vorgegeben werden soll; oberer  Button (wird bei Tagesganglinien NICHT empfohlen)
	2.) ein maximales Distanzmaß verwendet werden soll; unterer Button 

-|| Maximale Anzahl Cluster ||-  (wird bei Tagesganglinien NICHT empfohlen, da die Anzahl i.d.R. nicht vorab bekannt ist)
	Hier kann die Anzahl der Cluster vorgegeben werden.

-|| Maximale Distanz in einem Cluster ||-  (empfohlen, aber nicht möglich bei KMEANS)
	Es wird eingestellt, welche maximale Distanz (Tagesganglinien) innerhalb eines Clusters vorliegen darf.
	Bei "Average Linkage" z.B. wird eine Tagesganglinien dann noch einem Cluster zugeordent, wenn die Distanz 
	der mittleren Tagesganglinien aller Tage im Cluster zu einem noch nicht zugeordneten Cluster kleiner als die maximale Distanz ist.
	!!! Achtung: die Größenordnung bei der Euklidische Distanz und dem GEH unterscheiden sich stark !!!


-|| Kmeans Anzahl Wiederholungen ||- (nur aktiv, wenn KMEANS ausgewählt wurde)
	Bei Kmeans wird das Verfahren mehrfach durchgeführt (da die Startbelegung idR zufüllig ist) und am Ende das beste Ergebnis verwendet.

-|| Kmeans Startbelegung ||-  (nur aktiv, wenn KMEANS ausgewählt wurde)
	Welche Methode soll verwendet werden um die Startcluster zu verwendet:
		- Zufall 	 (Matlab: sample)  - Wählt zufällige Objekte (Tagesganglinien) als Startcluster
		- Uniform Zufall (Matlab: uniform) - Wählt zufällige Startcluster (unabhängig von den Objekten (Tagesganglinien))
		- Vorclusterung  (Matlab: cluster) - Macht eine Vorclusterung mit 10% der Objekte (Tagesganglinien) => Startcluster

------------------------------------------------------------------------------------------------------------------------
KALENDERDATEN
------------------------------------------------------------------------------------------------------------------------
In diesem Feld kann die Zeitraum gefiltert werden, der geclustert werden soll.
Zum einen können über verschiedene Checkboxen Wochentage oder weitere besondere Tage (Ferien, Feiertage, ...) ausgefiltert werden.
Das wird gemacht indem die entsprechende Checkbox deaktiviert wird.

Wenn Daten eingelesen wurden (siehe "Clusterdata Datei öffnen"), entstehen zwei Felder, die den Start und Endzeitpunkt der Clusterung bestimmten.
Durch Klick auf die Felder können diese Zeitpunkte festgelegt werden.

Da die Ferientermine nur eine begrenzte Zeit im Voraus feststehen, endet der Kalender am 30.10.2017. Für Daten danach können keine Clusterungen 
vorgenommen werden bzw. Datensätze mit entsprechenden Daten können gar nicht geladen werden.

 ------------------------------------------------------------------------------------------------------------------------
DATENAUSWAHL
------------------------------------------------------------------------------------------------------------------------
Es gibt 2 Buttons in Feld "Datenauswahl":
	A.) Clusterdata Datei öffnen
	B.) Eigenschaften laden (optional, !!! Die Eigenschaften haben KEINEN Einfluss auf das Clusterergebnis !!!)

------------------------------------------------ 
	A.) Clusterdata Datei öffnen 
------------------------------------------------
"Clusterdata Datei öffnen" muss gewählt werden. Es öffnet sich ein Dialog mit dem eine Datei ausgewählt werden soll, in der die zu clusternde
Objekte enthalten sind. Es kann wahlweise eine *.mat (Matlab) Datei oder eine *.xlsx (Excel) Datei verwendet werden.
Es wird ein bestimmtes Datenformat gefodert:
Die erste Spalte muss das Datum enthalten. Es werden folgenden Datumsformate unterstützt:
	1.) Matlab-Serial-Zeit 				(z.B. 735600 für 01.01.2014)
	2.) Unix-Zeit          					(z.B. 1388530800 für 01.01.2014)
	3.) Excel-Serial-Zeit  					(z.B. 41640 für 01.01.2014)
	4.) Datum in folgenden Formaten: 
			dd.mm.yyyy 					(01.01.2014)
			dd.mm.yyyy HH:MM			(01.01.2014 00:00)
			dd.mm.yyyy HH:MM:SS	(01.01.2014 00:00:00)
			dd.mm.yy							(01.01.14)
			dd.mm.yy HH:MM				(01.01.14 00:00)
			dd.mm.yy HH:MM:SS		(01.01.14 00:00:00)

Für die Verkehrsstärken gibt es 2 Möglichkeiten:
	1) Eingabe als Netzgangline (damit sind mehrere Detektoren möglich):
		Pro Tag darf nur eine Zeile verwendet werden. Alle Verkehrsstärken eines Tages müssen in verschiedenen Spalten in einer Zeile stehen.

		Die weiteren Spalten können beliebige numerische Werte enthalten. Wichtig ist nur, dass innerhalb einer Spalte die Werte gleicher Zeitbezüge innerhalb des Tages stehen.
		Ein richtiges Beispiel:
		01.01.2014	1500	2000	3000 (1. Spalte: Zeit, 2. Spalte Verkehrsstärke an diesem Tag um 01:00 Uhr, 3. Spalte um 02:00 Uhr, 4. Spalte um 03:00 Uhr)
		02.01.2014	1700	1800	2400 (1. Spalte: Zeit, 2. Spalte Verkehrsstärke an diesem Tag um 01:00 Uhr, 3. Spalte um 02:00 Uhr, 4. Spalte um 03:00 Uhr)
		Bei der Berechnung der Distanz werden die gleichen Spalten der unterschiedlichen Tage verwendet, d.h. die Verkehrsstärken gleicher Zeitbezüge werden miteinander vergleichen. 

		Ein falsches Beispiel:
		01.01.2014	1500	2000	3000 (1. Spalte: Zeit, 2. Spalte Verkehrsstärke an diesem Tag um 01:00 Uhr, 3. Spalte um 02:00 Uhr, 4. Spalte um 03:00 Uhr)
		02.01.2014	1700	2400 	1200 (1. Spalte: Zeit, 2. Spalte Verkehrsstärke an diesem Tag um 01:00 Uhr, 3. Spalte um 03:00 Uhr, 4. Spalte um 04:00 Uhr)
		In diesem Fall werden in der zweiten und dritten Spalte Verkehrsstärken unterschiedlicher Zeitintervalle miteinander verglichen (bei der Berechnung der Distanz).

		Nochmals: Die Anzahl der Spalten ist beliebig.
		
		Beispiel: ClusterData_Excel_verschiedene_Zeitformate.xlsx | Tabellenblätter: normale Zeit,  Excel Serial Zeit, Matlab Serial Zeit, Unix Zeit


	2) Eingabe in Zeilen (damit kann nur ein Detektor geclustert werden):
		Hierbei werden nur 2 Spalten berücksichtigt: 1. Spalte: Zeit, 2. Spalte: Verkehrsstärken zur Zeit.

		Beispiel: ClusterData_Excel_verschiedene_Zeitformate.xlsx | Tabellenblatt: Werte in Zeilen


Einlesen der Daten von Excel:
	Wenn eine Excel Datei ausgewählt wird, welche mehrere Tabellenblätter (Sheets) mit Daten enthält, öffnet sich ein kleines Fenster mit der Auflistung der 
	Tabellenblätter (Sheets) in dieser Excel Datei. Es muss nun ausgewählt werden, in welchem Tabellenblatt die Daten (UND NICHTS ANDERES) enthalten sind.
	!!! Die Daten müssen in der ersten Zeile beginnen. Die erste Spalte A muss das Datum enthalten !!!

Einlesen der Daten von Matlab:
	Die Daten können auch von einer Matlab Datei (*.mat) geselen werden. 
	Enthält die Matlab Datei (*.mat) mehrere Vatriablen, öffnet sich eine Fenster und es soll die zu verwendete Variable ausgewählt werden.
	Ansonsten gleten die gleichen Anforderungen wie bei der Excel-Datei.

Beispiele für die Eingnagsdaten sind in den Dateien:
	- ClusterData_Excel_verschiedene_Zeitformate.xlsx
	- ClusterData.mat
	- ClusterData_2008_bis_2013_versch_Intervalldauer.mat
	- ClusterData_Netzganglinie.xlsx 
	- ClusterData_Netzganglinie.mat

Es können auch frühere Clusterungen geladen werden. Durchgeführte Clusterungen lassen sich mit dem Button "Export nach Matlab" speichern. 
Dabei werden sowohl die Inputdaten als auch die Cluster gespeichert.
Beim Laden einer Outputdatei gibt es zwei Optionen:
	1.) Es sollen nur die Inputdaten der Clusterung geladen werden
		Hierbei werden nur die einzelnen Tagesganglinien, welche in der Clusterung verwendet wurden geladen.
		Das Auslesen der Daten aus Excel kann unter Umständen viel Zeit in Anspruch nehmen. Wird eine Clusterung mir diesen Daten exportiert, können diese Daten
		später über das Laden der Clusterung deutlich schneller eingelesen werden.
	
	2.) Vollständige Clusterung laden
		Hierbei wird eine Clusterung angelegt (zu sehen in der Tabelle: Lister der Clusterungen).
		Es werden alle Daten und Clusterergebnisse geladen und die geladene Clusterung wird direkt visuell dargestellt.

Hinweis: Es gibt die Möglichkeit eine Clusterung auch nach Excel zu exportierten. Leider können diese Dateien nicht wieder geladen werden. 

------------------------------------------------
	B.) Eigenschaften laden (optional)
------------------------------------------------
Es können zusätzliche Eigenschaften zu den einzelnen Tagen geladen werden.
!!! Die Eigenschaften haben KEINEN Einfluss auf das Clusterergebnis !!!
Die Daten müssen folgendermaßen aufgebaut sein:
	1. Spalte: Datum (es werden die gleichen Formate wie bei " A.) Clusterdata Datei öffnen" unterstützt).
	n. Spalte beliebige Eigenschaften.
	
In jeder einzelnen Spalte sollte eine Eigenschaft eingetragen sein.
Z.B. Eigenschaft Wetter (siehe Beispieldatei: "Eigenschaft_Wetter.xlsx"):
	01.01.2008	nicht zugeordnet
	02.01.2008	Mittelwetter
	03.01.2008	Mittelwetter
	04.01.2008	Mittelwetter
	05.01.2008	Schlechtes Wetter
	06.01.2008	Schlechtes Wetter
	
	1. Spalte: Datum
	2. Spalte: Wetter
	
Diese Eigenschaften müssen nicht numerisch sein (es ist sogar besser wenn ein Text drin steht).
Weiter können den einzelnen Tagen beliebige Eigenschaften hinzugefügt werden (z.B. Baustelle, Unfall oder auch Fußballspiel, Großveranstaltung)
Die Bezeichnungen der Eigenschaften muss so verändert werden, damit Matlab ein Feld für eine Struct machen kann: D.h. die Zeichen
ä,ö,ü, ß und Leerzeichen sind nicht erlaubt und werden in ae, oe, ue, ss und _ umgewandelt.

Zusätzlich gibt es die Option der Eigenschaft eine Überschrift zu geben. In diesem Fall beginnt das Datum erst in der zweiten Zeile.
						Wetter
	01.01.2008	nicht zugeordnet
	02.01.2008	Mittelwetter
	03.01.2008	Mittelwetter
	04.01.2008	Mittelwetter
	05.01.2008	Schlechtes Wetter
	06.01.2008	Schlechtes Wetter

Beispiele für die Eingangsdaten sind in den Dateien:
	- Eigenschaft_Wetter.xlsx
	- Eigenschaft_Wetter.mat

Die Eigenschaften können später visuell oder als Tabelle für die einzelnen Cluster angezeigt werden.

------------------------------------------------------------------------------------------------------------------------
BUTTONS (rechte Seite)
------------------------------------------------------------------------------------------------------------------------
Oben rechts gibt es 2 Button:
	- 1 - Hilfe 			Damit öffnet sich dieses Dokument :)
	- 2 - Weitere Einstellungen	Es öffnet sich ein Fenster mit Einstellungen.
				Es kann ausgewählt werden, ob das Protokoll-Fenster angezeigt werden soll und / oder ob der Vorgang in eine Protokolldaten "Protokoll.txt" 
				geschrieben werden soll.
				Es kann auch eingestellt werden, welche Eigenschaften verwendet werden sollen und von welchem Bundesland die Feiertage und Schulferien 
				bestimmt werden sollen. Einmal hier getätigte Einstellungen werden in der Datei "Zusatz_ES_Clusterung.mat". gespeichert und bleiben erhalten.
				!!! In der Compelierten Version können nach dem Beenden die Einstellungen nicht gespeichert werden. !!!
				Alle getätigten Änderungen werden sofort gespeichert. Nach der Einstellung kann das Fenster über das "x" geschlossen werden.

Es gibt auf der rechten Seite noch 9 Buttons:
	- 1 - Neue Clusterung anlegen
	- 2 - ...starten
	- 3 - ...löschen
	- 4 - Eigenschaften der Cluster
	- 5 - Clusterungskalender
	- 6 - Silhouette-Werte
	- 7 - Abstandsmatrix (experimentell)
	- 8 - Export nach Excel
	- 9 - Export nach Matlab

Die jeweiligen Buttons werden nur aktiv, wenn sie auch verwendet werden können. Zu Beginn ist keiner der Buttons aktiv, da zuerst Clusterdata geladen werden muss.

	- 1 - Neue Clusterung anlegen
		Wenn dieser Button gedrückt wird, werden die oben durchgeführten Einstellungen (Clustermethode, Distanzfunktion, Kalenderdaten, und Datenauswahl) gespeichert.
		Es wird ein Eintrag in der Tabelle "Liste der Clusterungen" erzeugt. 
		In diesem Schritt werden die Daten "ClusterData" und zusätzliche Eigenschaften geladen.

	- 2 - ...starten
		Die aktive Clusterung (in der Tabelle "Liste der Clusterungen" werden die Clusterungen aktiviert) wird gestartet.
		Gibt es keine aktive Clusterung, passiert nicht. Es muss erst eine Clusterung angelegt werden (vgl. - 1 - Neue Clusterung anlegen).
		Die Ausführung kann je nach Datenmenge einige Zeit in Anspruch nehmen. 
		Ist man sich unsicher, ob die Berechnun noch läuft hilft ein Blick in den Task-Manager um zu schauen, ob das Programm noch CPU-Rechenzeit in Anspruch nimmt.
		Nach Abschluss der Clusterung wird das Ergebnis in den unteren Schaubildern visuell dargestellt.
	
	- 3 - ...löschen
		Die aktive Clusterung wird gelöscht.

	- 4 - Eigenschaften der Cluster
		Zeigt eine Tabelle mit den Eigenschaftswerten der entstandenen Cluster. 
		Der Eigenschaftswert liegt zwischen 0 und 1:
			0: in diesem Cluster ist kein Tag mit dieser Eigenschaft enthalten
			1: alle Tage in diesem Cluster haben diese Eigenschaft
			>0 und <0 => der Anteil der Tage mit dieser Eigenschaft 

	- 5 - Clusterungskalender
		Zeigt den Kalender der Clusterung. Die einzelnen Tage sind entsprechend der Cluster farblich markiert (gleiche Farben wie bei den 
		Schaubildern "mittlerer Clusterganglinien" und "Tagesganglinien").
		durch Klick auf die Buttons im unteren Bereich werden die Tage der Cluster fett markiert.
		Werden einzelne Tage angeklickt wird der entprechende Tag markiert.
		Mithilfe des Zoom (Lupe im Menü oben linke), können verschieden Eigenschaften des Tages angezeigt werden:
			TagTypNr:			ist die Zuordnung zum Cluster (TagTypNr: 0 sind Tage, welche ausgefiltert wurden == nicht in der Clusterung enthalten sind).
			Clustergröße:		Anzahl der Tage in diesem Cluster
			Abstand zum Cl:	Abstand zwischen dem einzelnen Tag und des Clusters, welchem der Tag zugeordnet ist in der Einheit entsprechend des Distanzmaßes.
			AvgQ:					mittlerer Wert des Tages
			AvgQCluster:		mittlerer Wert des Clusters, welchem der Tag zugeordnet ist
			weitere Eigenschaften des Tages und dahinter die Eigenschaften des Clusters (C:).

	- 6 - Silhouette-Werte
		Zeigt die Silhouette Werte der Clusterung. 
		Keine tolle Beschriebung, für mehr Hintergründe bitte Silhouette Werte oder Silhouettenkoeffizient googeln.

	- 7 - Abstandsmatrix (experimentell)
		Zeit die Abstände zwischen den einzelnen Tagen.
		Im oberen Schaubild sind die Tage nach dem Datum sortiert.
		Im unteren Schaubild sind die Tage nach ihrer Cluster - Zugehörigkeit sortiert.

	- 8 - Export nach Excel
		Die Ergebnisse der Clusterung werden in eine Excel-Datei (*.xlsx oder *.xls) geschrieben.
		Es werden 4 Tabellenblätter erzeugt:
		1.)	ClusterLinien							- darin enthalten sind die Verläufe der entstandenen Cluster
		2.)	ClusterData							- hier sind nochmals die Inputdaten (Tagesganglinien) jedoch ist in der zweiten Spalte die Zuordnung zum Cluster enthalten.
		3.)	Eigenschaften						- die Eigenschaften der Cluster wie bei "- 4 - Eigenschaften der Cluster"
		4.)	Eigenschaften_ClusterData	- die Eigenschaften der Inputdaten (Tagesganglinien)
		siehe Beispieldatei: Export_Clusterung_1.xlsx

	- 9 - Export nach Matlab
		Die Ergebnisse der Clusterung werden in eine *.mat Datei geschrieben.
		Die in der Datei gespeicherte Variable "Clusterung" ist vom Typ "class_Clusterung".
		In dieser Variable sind alle Daten enthalten (Einstellungen, Inputdaten, Einstellungen, ClusterLinien, uvm.).
		Mehr Infos zum Aufbau der Klasse findet man in der Datei "class_Clusterung.m".
		Eine Exportierte Clusterung nach Matlab kann wieder mit "Clusterdata Datei öffnen" geladen werden.
		Es kann dabei die gesamte Clsuterung geladen werden oder nur die Inputdaten. Dieses Feature kann z.B. auch dann verwendet werden, wenn das Laden von größeren 
		Datenmengen von Excel sehr viel Zeit in Anspruch nimmt. Das Laden von Matlab-Daten ist deutlich schneller.
		Siehe dazu auch "Clusterdata Datei öffnen " bei Datenauswahl.	

------------------------------------------------------------------------------------------------------------------------
VISUELLE DARSTELLUNG
------------------------------------------------------------------------------------------------------------------------
Im unteren Bereich von des Fensters beginden sich 3 Diagramme:
	1.) Werte der Cluster 				Position: rechts oben
	2.) Werte der einzelnen Tage		Position: rechts unten
	3.) Cluster 								Position: links

Neben jedem der 3 Diagramme (rechts unten) ist ein kleiner Button ">". Dieser vergößert den Inhalt der Diagramme in ein neues Fenster in dem man sich den Inhalt 
vergrößert anschauen kann und z.B. auch als Matlab-Figure oder Bild (png, jpeg) speichern kann.
Der Button "Undock/Copy" (ganz unten rechts im Fenster) bringt die beiden rechten Diagramme zusammen in ein neues Fenster.
Weiter kann man mithile der drei Symbole im Menü des Fensters (ganz ober unter "MatNetClusterung") die Darstellung vergrößern / verkleinern und verschieben.
 
	1.) Werte der Cluster (Position: rechts oben)
		Hier sind die resultierende Cluster dargestellt. 
		Der Verlauf ergibt sich aus dem Mittelwert aller Tageswerte, die dem Cluster zugeordnet sind.
		Die breite der Linien ist abhängig von der Anzahl der Tage, welche diesem Cluster zugeordnet wurde.
		Durch den Klick auf eine Linie wird die Clusternummer der Linie gezeigt.
		Die Clusternummer kann wieder entfernt werden, wenn auf die gezeigte Clusternummer geklickt wird.  	

	2.) Werte der einzelnen Tage (Position: rechts unten)
		Hier werden die Inputdaten (Tagesganglinien) dargestellt. Die Farbe der Linien zeigt die Zugehörigkeit zum Cluster.
		Durch den Klick auf eine Linie wird das Datum der Linie gezeigt.
		Das Datum wird im Format ddd dd.mm.yyyy angezeigt. ddd entspricht der englischen Wochentagsabkürzungen:
		Sun: Sonntag, Mon: Montag, Tue: Dienstag, Wed: Mittwoch, Thu: Donnerstag, Fri: Freitag, Sat: Samstag
		Das Datum kann wieder entfernt werden, wenn auf das gezeigte Datum geklickt wird. 

	3.) Cluster (Position: links)
		Hier werden die Clustereigenschaften dargestellt.
		Über dem Diagramm ist ein Pop-Up Menü mit dem die verschiednen Eigenschaften ausgewählt werden können (Ferien, Wochentag, ...).
		Für jedes Cluster wird ein Balken mit den enthaltenen Eigenschaften dargestellt.
		Mit dem Klick auf einen Balken wird dieser Balken gezeigt. Bei erneutem Klick auf den selben Balken wird dieser wieder ausgeblenden.
		Damit ist es möglich einzelne Cluster direkt miteinander zu vergleichen.
		Tipp: Mit "Undock/Copy" und ">" wird nur die entsprechende Auswahl (rechte Diagramme) ins neue Fenster exportiert.

In der unteren rechten Ecke des Fensters gibt es noch zwei Buttons "Renew" und "Clear".
	- Renew: Zeichnet alle Cluster und die Werte der einzelnen Tage wieder neu.
	- Clear: Löscht die Darstellungen in den rechten beiden Diagrammen.