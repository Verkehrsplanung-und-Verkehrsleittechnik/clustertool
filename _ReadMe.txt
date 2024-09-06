Anleitung des Clustertools:

--------------------------------------
!!! KEINE GARANTIE AUF RICHTIGKEIT !!!
--------------------------------------
Es wird keine Haftung bei Fehlern �bernommen.

Das Tool kann verwendet werden um beliebige Objekte zu Clustern.
Optimiert ist die Clusterung auf Verkehrsst�rkeganglinien. 

------------------------------------------------------------------------------------------------------------------------
SCHNELLANLEITUNG
------------------------------------------------------------------------------------------------------------------------
	1.) Daten einlesen -> Button "Clusterdata Datei �ffnen"
	2.) Einstellungen vornehmen (Clustermethode, Distanzfunktion, Kalenderdaten, ...)
	3.) Clusterung anlegen -> Button "Neue Clusterung anlegen"
			Die eingelesenen Daten und die Einstellungen werden gespeichert und k�nnen in dieser angelegten Clusterung nicht mehr ver�ndert werden.
	4.) Clusterung starten -> Button "...starten"

------------------------------------------------------------------------------------------------------------------------
EINSTELLUNG CLUSTERUNG
------------------------------------------------------------------------------------------------------------------------
-|| Clustermethode ||-
	Es stehen verschiedene Methoden zur Auswahl. 
	- Kmeans
	- Single Linkage
	- Complete Linkage
	- Average Linkage  (wird f�r Verkehrsst�rken empfohlen)
	- Weighted Linkage
	- Median Linkage
	- Ward - Verfahren 
	F�r weitere Informationen zu den Verfahren bitte bei Wikipedia oder Fachliteratur nachschauen.

-|| Distanzfunktion ||-
	F�r die Berechnung der Distanzen von den unterschiedlichen Objekten (Tagesganglinien)
	muss ein Distanzma� definiert werden. Zur Auswahl stehen
	- GEH (wird f�r Verkehrsst�rken in der Einheit Kfz/h empfohlen)
	- Euklidische Distanz

Weiter muss eine eingestellt werden, wie detailliert die Clusterung sein soll, d.h.
ob sehr grob oder fein geclustert werden soll.
Mithilfe der beiden Radiobuttons auf der rechten Seite im Feld "Einstellung Clusterung" kann eingestellt werden, ob 
	1.) eine Anzahl an Clustern vorgegeben werden soll; oberer  Button (wird bei Tagesganglinien NICHT empfohlen)
	2.) ein maximales Distanzma� verwendet werden soll; unterer Button 

-|| Maximale Anzahl Cluster ||-  (wird bei Tagesganglinien NICHT empfohlen, da die Anzahl i.d.R. nicht vorab bekannt ist)
	Hier kann die Anzahl der Cluster vorgegeben werden.

-|| Maximale Distanz in einem Cluster ||-  (empfohlen, aber nicht m�glich bei KMEANS)
	Es wird eingestellt, welche maximale Distanz (Tagesganglinien) innerhalb eines Clusters vorliegen darf.
	Bei "Average Linkage" z.B. wird eine Tagesganglinien dann noch einem Cluster zugeordent, wenn die Distanz 
	der mittleren Tagesganglinien aller Tage im Cluster zu einem noch nicht zugeordneten Cluster kleiner als die maximale Distanz ist.
	!!! Achtung: die Gr��enordnung bei der Euklidische Distanz und dem GEH unterscheiden sich stark !!!


-|| Kmeans Anzahl Wiederholungen ||- (nur aktiv, wenn KMEANS ausgew�hlt wurde)
	Bei Kmeans wird das Verfahren mehrfach durchgef�hrt (da die Startbelegung idR zuf�llig ist) und am Ende das beste Ergebnis verwendet.

-|| Kmeans Startbelegung ||-  (nur aktiv, wenn KMEANS ausgew�hlt wurde)
	Welche Methode soll verwendet werden um die Startcluster zu verwendet:
		- Zufall 	 (Matlab: sample)  - W�hlt zuf�llige Objekte (Tagesganglinien) als Startcluster
		- Uniform Zufall (Matlab: uniform) - W�hlt zuf�llige Startcluster (unabh�ngig von den Objekten (Tagesganglinien))
		- Vorclusterung  (Matlab: cluster) - Macht eine Vorclusterung mit 10% der Objekte (Tagesganglinien) => Startcluster

------------------------------------------------------------------------------------------------------------------------
KALENDERDATEN
------------------------------------------------------------------------------------------------------------------------
In diesem Feld kann die Zeitraum gefiltert werden, der geclustert werden soll.
Zum einen k�nnen �ber verschiedene Checkboxen Wochentage oder weitere besondere Tage (Ferien, Feiertage, ...) ausgefiltert werden.
Das wird gemacht indem die entsprechende Checkbox deaktiviert wird.

Wenn Daten eingelesen wurden (siehe "Clusterdata Datei �ffnen"), entstehen zwei Felder, die den Start und Endzeitpunkt der Clusterung bestimmten.
Durch Klick auf die Felder k�nnen diese Zeitpunkte festgelegt werden.

Da die Ferientermine nur eine begrenzte Zeit im Voraus feststehen, endet der Kalender am 30.10.2017. F�r Daten danach k�nnen keine Clusterungen 
vorgenommen werden bzw. Datens�tze mit entsprechenden Daten k�nnen gar nicht geladen werden.

 ------------------------------------------------------------------------------------------------------------------------
DATENAUSWAHL
------------------------------------------------------------------------------------------------------------------------
Es gibt 2 Buttons in Feld "Datenauswahl":
	A.) Clusterdata Datei �ffnen
	B.) Eigenschaften laden (optional, !!! Die Eigenschaften haben KEINEN Einfluss auf das Clusterergebnis !!!)

------------------------------------------------ 
	A.) Clusterdata Datei �ffnen 
------------------------------------------------
"Clusterdata Datei �ffnen" muss gew�hlt werden. Es �ffnet sich ein Dialog mit dem eine Datei ausgew�hlt werden soll, in der die zu clusternde
Objekte enthalten sind. Es kann wahlweise eine *.mat (Matlab) Datei oder eine *.xlsx (Excel) Datei verwendet werden.
Es wird ein bestimmtes Datenformat gefodert:
Die erste Spalte muss das Datum enthalten. Es werden folgenden Datumsformate unterst�tzt:
	1.) Matlab-Serial-Zeit 				(z.B. 735600 f�r 01.01.2014)
	2.) Unix-Zeit          					(z.B. 1388530800 f�r 01.01.2014)
	3.) Excel-Serial-Zeit  					(z.B. 41640 f�r 01.01.2014)
	4.) Datum in folgenden Formaten: 
			dd.mm.yyyy 					(01.01.2014)
			dd.mm.yyyy HH:MM			(01.01.2014 00:00)
			dd.mm.yyyy HH:MM:SS	(01.01.2014 00:00:00)
			dd.mm.yy							(01.01.14)
			dd.mm.yy HH:MM				(01.01.14 00:00)
			dd.mm.yy HH:MM:SS		(01.01.14 00:00:00)

F�r die Verkehrsst�rken gibt es 2 M�glichkeiten:
	1) Eingabe als Netzgangline (damit sind mehrere Detektoren m�glich):
		Pro Tag darf nur eine Zeile verwendet werden. Alle Verkehrsst�rken eines Tages m�ssen in verschiedenen Spalten in einer Zeile stehen.

		Die weiteren Spalten k�nnen beliebige numerische Werte enthalten. Wichtig ist nur, dass innerhalb einer Spalte die Werte gleicher Zeitbez�ge innerhalb des Tages stehen.
		Ein richtiges Beispiel:
		01.01.2014	1500	2000	3000 (1. Spalte: Zeit, 2. Spalte Verkehrsst�rke an diesem Tag um 01:00 Uhr, 3. Spalte um 02:00 Uhr, 4. Spalte um 03:00 Uhr)
		02.01.2014	1700	1800	2400 (1. Spalte: Zeit, 2. Spalte Verkehrsst�rke an diesem Tag um 01:00 Uhr, 3. Spalte um 02:00 Uhr, 4. Spalte um 03:00 Uhr)
		Bei der Berechnung der Distanz werden die gleichen Spalten der unterschiedlichen Tage verwendet, d.h. die Verkehrsst�rken gleicher Zeitbez�ge werden miteinander vergleichen. 

		Ein falsches Beispiel:
		01.01.2014	1500	2000	3000 (1. Spalte: Zeit, 2. Spalte Verkehrsst�rke an diesem Tag um 01:00 Uhr, 3. Spalte um 02:00 Uhr, 4. Spalte um 03:00 Uhr)
		02.01.2014	1700	2400 	1200 (1. Spalte: Zeit, 2. Spalte Verkehrsst�rke an diesem Tag um 01:00 Uhr, 3. Spalte um 03:00 Uhr, 4. Spalte um 04:00 Uhr)
		In diesem Fall werden in der zweiten und dritten Spalte Verkehrsst�rken unterschiedlicher Zeitintervalle miteinander verglichen (bei der Berechnung der Distanz).

		Nochmals: Die Anzahl der Spalten ist beliebig.
		
		Beispiel: ClusterData_Excel_verschiedene_Zeitformate.xlsx | Tabellenbl�tter: normale Zeit,  Excel Serial Zeit, Matlab Serial Zeit, Unix Zeit


	2) Eingabe in Zeilen (damit kann nur ein Detektor geclustert werden):
		Hierbei werden nur 2 Spalten ber�cksichtigt: 1. Spalte: Zeit, 2. Spalte: Verkehrsst�rken zur Zeit.

		Beispiel: ClusterData_Excel_verschiedene_Zeitformate.xlsx | Tabellenblatt: Werte in Zeilen


Einlesen der Daten von Excel:
	Wenn eine Excel Datei ausgew�hlt wird, welche mehrere Tabellenbl�tter (Sheets) mit Daten enth�lt, �ffnet sich ein kleines Fenster mit der Auflistung der 
	Tabellenbl�tter (Sheets) in dieser Excel Datei. Es muss nun ausgew�hlt werden, in welchem Tabellenblatt die Daten (UND NICHTS ANDERES) enthalten sind.
	!!! Die Daten m�ssen in der ersten Zeile beginnen. Die erste Spalte A muss das Datum enthalten !!!

Einlesen der Daten von Matlab:
	Die Daten k�nnen auch von einer Matlab Datei (*.mat) geselen werden. 
	Enth�lt die Matlab Datei (*.mat) mehrere Vatriablen, �ffnet sich eine Fenster und es soll die zu verwendete Variable ausgew�hlt werden.
	Ansonsten gleten die gleichen Anforderungen wie bei der Excel-Datei.

Beispiele f�r die Eingnagsdaten sind in den Dateien:
	- ClusterData_Excel_verschiedene_Zeitformate.xlsx
	- ClusterData.mat
	- ClusterData_2008_bis_2013_versch_Intervalldauer.mat
	- ClusterData_Netzganglinie.xlsx 
	- ClusterData_Netzganglinie.mat

Es k�nnen auch fr�here Clusterungen geladen werden. Durchgef�hrte Clusterungen lassen sich mit dem Button "Export nach Matlab" speichern. 
Dabei werden sowohl die Inputdaten als auch die Cluster gespeichert.
Beim Laden einer Outputdatei gibt es zwei Optionen:
	1.) Es sollen nur die Inputdaten der Clusterung geladen werden
		Hierbei werden nur die einzelnen Tagesganglinien, welche in der Clusterung verwendet wurden geladen.
		Das Auslesen der Daten aus Excel kann unter Umst�nden viel Zeit in Anspruch nehmen. Wird eine Clusterung mir diesen Daten exportiert, k�nnen diese Daten
		sp�ter �ber das Laden der Clusterung deutlich schneller eingelesen werden.
	
	2.) Vollst�ndige Clusterung laden
		Hierbei wird eine Clusterung angelegt (zu sehen in der Tabelle: Lister der Clusterungen).
		Es werden alle Daten und Clusterergebnisse geladen und die geladene Clusterung wird direkt visuell dargestellt.

Hinweis: Es gibt die M�glichkeit eine Clusterung auch nach Excel zu exportierten. Leider k�nnen diese Dateien nicht wieder geladen werden. 

------------------------------------------------
	B.) Eigenschaften laden (optional)
------------------------------------------------
Es k�nnen zus�tzliche Eigenschaften zu den einzelnen Tagen geladen werden.
!!! Die Eigenschaften haben KEINEN Einfluss auf das Clusterergebnis !!!
Die Daten m�ssen folgenderma�en aufgebaut sein:
	1. Spalte: Datum (es werden die gleichen Formate wie bei " A.) Clusterdata Datei �ffnen" unterst�tzt).
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
	
Diese Eigenschaften m�ssen nicht numerisch sein (es ist sogar besser wenn ein Text drin steht).
Weiter k�nnen den einzelnen Tagen beliebige Eigenschaften hinzugef�gt werden (z.B. Baustelle, Unfall oder auch Fu�ballspiel, Gro�veranstaltung)
Die Bezeichnungen der Eigenschaften muss so ver�ndert werden, damit Matlab ein Feld f�r eine Struct machen kann: D.h. die Zeichen
�,�,�, � und Leerzeichen sind nicht erlaubt und werden in ae, oe, ue, ss und _ umgewandelt.

Zus�tzlich gibt es die Option der Eigenschaft eine �berschrift zu geben. In diesem Fall beginnt das Datum erst in der zweiten Zeile.
						Wetter
	01.01.2008	nicht zugeordnet
	02.01.2008	Mittelwetter
	03.01.2008	Mittelwetter
	04.01.2008	Mittelwetter
	05.01.2008	Schlechtes Wetter
	06.01.2008	Schlechtes Wetter

Beispiele f�r die Eingangsdaten sind in den Dateien:
	- Eigenschaft_Wetter.xlsx
	- Eigenschaft_Wetter.mat

Die Eigenschaften k�nnen sp�ter visuell oder als Tabelle f�r die einzelnen Cluster angezeigt werden.

------------------------------------------------------------------------------------------------------------------------
BUTTONS (rechte Seite)
------------------------------------------------------------------------------------------------------------------------
Oben rechts gibt es 2 Button:
	- 1 - Hilfe 			Damit �ffnet sich dieses Dokument :)
	- 2 - Weitere Einstellungen	Es �ffnet sich ein Fenster mit Einstellungen.
				Es kann ausgew�hlt werden, ob das Protokoll-Fenster angezeigt werden soll und / oder ob der Vorgang in eine Protokolldaten "Protokoll.txt" 
				geschrieben werden soll.
				Es kann auch eingestellt werden, welche Eigenschaften verwendet werden sollen und von welchem Bundesland die Feiertage und Schulferien 
				bestimmt werden sollen. Einmal hier get�tigte Einstellungen werden in der Datei "Zusatz_ES_Clusterung.mat". gespeichert und bleiben erhalten.
				!!! In der Compelierten Version k�nnen nach dem Beenden die Einstellungen nicht gespeichert werden. !!!
				Alle get�tigten �nderungen werden sofort gespeichert. Nach der Einstellung kann das Fenster �ber das "x" geschlossen werden.

Es gibt auf der rechten Seite noch 9 Buttons:
	- 1 - Neue Clusterung anlegen
	- 2 - ...starten
	- 3 - ...l�schen
	- 4 - Eigenschaften der Cluster
	- 5 - Clusterungskalender
	- 6 - Silhouette-Werte
	- 7 - Abstandsmatrix (experimentell)
	- 8 - Export nach Excel
	- 9 - Export nach Matlab

Die jeweiligen Buttons werden nur aktiv, wenn sie auch verwendet werden k�nnen. Zu Beginn ist keiner der Buttons aktiv, da zuerst Clusterdata geladen werden muss.

	- 1 - Neue Clusterung anlegen
		Wenn dieser Button gedr�ckt wird, werden die oben durchgef�hrten Einstellungen (Clustermethode, Distanzfunktion, Kalenderdaten, und Datenauswahl) gespeichert.
		Es wird ein Eintrag in der Tabelle "Liste der Clusterungen" erzeugt. 
		In diesem Schritt werden die Daten "ClusterData" und zus�tzliche Eigenschaften geladen.

	- 2 - ...starten
		Die aktive Clusterung (in der Tabelle "Liste der Clusterungen" werden die Clusterungen aktiviert) wird gestartet.
		Gibt es keine aktive Clusterung, passiert nicht. Es muss erst eine Clusterung angelegt werden (vgl. - 1 - Neue Clusterung anlegen).
		Die Ausf�hrung kann je nach Datenmenge einige Zeit in Anspruch nehmen. 
		Ist man sich unsicher, ob die Berechnun noch l�uft hilft ein Blick in den Task-Manager um zu schauen, ob das Programm noch CPU-Rechenzeit in Anspruch nimmt.
		Nach Abschluss der Clusterung wird das Ergebnis in den unteren Schaubildern visuell dargestellt.
	
	- 3 - ...l�schen
		Die aktive Clusterung wird gel�scht.

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
		Mithilfe des Zoom (Lupe im Men� oben linke), k�nnen verschieden Eigenschaften des Tages angezeigt werden:
			TagTypNr:			ist die Zuordnung zum Cluster (TagTypNr: 0 sind Tage, welche ausgefiltert wurden == nicht in der Clusterung enthalten sind).
			Clustergr��e:		Anzahl der Tage in diesem Cluster
			Abstand zum Cl:	Abstand zwischen dem einzelnen Tag und des Clusters, welchem der Tag zugeordnet ist in der Einheit entsprechend des Distanzma�es.
			AvgQ:					mittlerer Wert des Tages
			AvgQCluster:		mittlerer Wert des Clusters, welchem der Tag zugeordnet ist
			weitere Eigenschaften des Tages und dahinter die Eigenschaften des Clusters (C:).

	- 6 - Silhouette-Werte
		Zeigt die Silhouette Werte der Clusterung. 
		Keine tolle Beschriebung, f�r mehr Hintergr�nde bitte Silhouette Werte oder Silhouettenkoeffizient googeln.

	- 7 - Abstandsmatrix (experimentell)
		Zeit die Abst�nde zwischen den einzelnen Tagen.
		Im oberen Schaubild sind die Tage nach dem Datum sortiert.
		Im unteren Schaubild sind die Tage nach ihrer Cluster - Zugeh�rigkeit sortiert.

	- 8 - Export nach Excel
		Die Ergebnisse der Clusterung werden in eine Excel-Datei (*.xlsx oder *.xls) geschrieben.
		Es werden 4 Tabellenbl�tter erzeugt:
		1.)	ClusterLinien							- darin enthalten sind die Verl�ufe der entstandenen Cluster
		2.)	ClusterData							- hier sind nochmals die Inputdaten (Tagesganglinien) jedoch ist in der zweiten Spalte die Zuordnung zum Cluster enthalten.
		3.)	Eigenschaften						- die Eigenschaften der Cluster wie bei "- 4 - Eigenschaften der Cluster"
		4.)	Eigenschaften_ClusterData	- die Eigenschaften der Inputdaten (Tagesganglinien)
		siehe Beispieldatei: Export_Clusterung_1.xlsx

	- 9 - Export nach Matlab
		Die Ergebnisse der Clusterung werden in eine *.mat Datei geschrieben.
		Die in der Datei gespeicherte Variable "Clusterung" ist vom Typ "class_Clusterung".
		In dieser Variable sind alle Daten enthalten (Einstellungen, Inputdaten, Einstellungen, ClusterLinien, uvm.).
		Mehr Infos zum Aufbau der Klasse findet man in der Datei "class_Clusterung.m".
		Eine Exportierte Clusterung nach Matlab kann wieder mit "Clusterdata Datei �ffnen" geladen werden.
		Es kann dabei die gesamte Clsuterung geladen werden oder nur die Inputdaten. Dieses Feature kann z.B. auch dann verwendet werden, wenn das Laden von gr��eren 
		Datenmengen von Excel sehr viel Zeit in Anspruch nimmt. Das Laden von Matlab-Daten ist deutlich schneller.
		Siehe dazu auch "Clusterdata Datei �ffnen " bei Datenauswahl.	

------------------------------------------------------------------------------------------------------------------------
VISUELLE DARSTELLUNG
------------------------------------------------------------------------------------------------------------------------
Im unteren Bereich von des Fensters beginden sich 3 Diagramme:
	1.) Werte der Cluster 				Position: rechts oben
	2.) Werte der einzelnen Tage		Position: rechts unten
	3.) Cluster 								Position: links

Neben jedem der 3 Diagramme (rechts unten) ist ein kleiner Button ">". Dieser verg��ert den Inhalt der Diagramme in ein neues Fenster in dem man sich den Inhalt 
vergr��ert anschauen kann und z.B. auch als Matlab-Figure oder Bild (png, jpeg) speichern kann.
Der Button "Undock/Copy" (ganz unten rechts im Fenster) bringt die beiden rechten Diagramme zusammen in ein neues Fenster.
Weiter kann man mithile der drei Symbole im Men� des Fensters (ganz ober unter "MatNetClusterung") die Darstellung vergr��ern / verkleinern und verschieben.
 
	1.) Werte der Cluster (Position: rechts oben)
		Hier sind die resultierende Cluster dargestellt. 
		Der Verlauf ergibt sich aus dem Mittelwert aller Tageswerte, die dem Cluster zugeordnet sind.
		Die breite der Linien ist abh�ngig von der Anzahl der Tage, welche diesem Cluster zugeordnet wurde.
		Durch den Klick auf eine Linie wird die Clusternummer der Linie gezeigt.
		Die Clusternummer kann wieder entfernt werden, wenn auf die gezeigte Clusternummer geklickt wird.  	

	2.) Werte der einzelnen Tage (Position: rechts unten)
		Hier werden die Inputdaten (Tagesganglinien) dargestellt. Die Farbe der Linien zeigt die Zugeh�rigkeit zum Cluster.
		Durch den Klick auf eine Linie wird das Datum der Linie gezeigt.
		Das Datum wird im Format ddd dd.mm.yyyy angezeigt. ddd entspricht der englischen Wochentagsabk�rzungen:
		Sun: Sonntag, Mon: Montag, Tue: Dienstag, Wed: Mittwoch, Thu: Donnerstag, Fri: Freitag, Sat: Samstag
		Das Datum kann wieder entfernt werden, wenn auf das gezeigte Datum geklickt wird. 

	3.) Cluster (Position: links)
		Hier werden die Clustereigenschaften dargestellt.
		�ber dem Diagramm ist ein Pop-Up Men� mit dem die verschiednen Eigenschaften ausgew�hlt werden k�nnen (Ferien, Wochentag, ...).
		F�r jedes Cluster wird ein Balken mit den enthaltenen Eigenschaften dargestellt.
		Mit dem Klick auf einen Balken wird dieser Balken gezeigt. Bei erneutem Klick auf den selben Balken wird dieser wieder ausgeblenden.
		Damit ist es m�glich einzelne Cluster direkt miteinander zu vergleichen.
		Tipp: Mit "Undock/Copy" und ">" wird nur die entsprechende Auswahl (rechte Diagramme) ins neue Fenster exportiert.

In der unteren rechten Ecke des Fensters gibt es noch zwei Buttons "Renew" und "Clear".
	- Renew: Zeichnet alle Cluster und die Werte der einzelnen Tage wieder neu.
	- Clear: L�scht die Darstellungen in den rechten beiden Diagrammen.