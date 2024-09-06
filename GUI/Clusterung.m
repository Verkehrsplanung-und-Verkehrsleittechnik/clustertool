%% Daten einlesen:
function Data_ClusterData_Callback(hObject, ~, handles)
% Executes on button press in Data_ClusterData

% Die Daten müssen die Form haben:
% 1. Spalte:    Zeit des Tages im Matlab-Zeit Format ODER Unix-Zeit ODER EXCEL Nummer Format
% 2.-n. Spalte: Die Werte für die Clusterung, z.B. die Verkehrsstärken der einzelnen Stunden des Tages (n=25)

MyDisp('ClusterData einlesen')

% Datei öffnen:
MyDisp('Datei öffenen')
[Daten, Dateiname] = Daten_Importieren;
MyDisp('Datei gelesen.')
if isempty(Daten)
    % Es wurde auf abbrechen geklickt.
    return
end

if isa(Daten, 'class_Clusterung'),
    MyDisp('Clusterdatei erkannt.')
    Auswahl = { 'Es sollen nur die Inputdaten der Clusterung geladen werden.';
        'Vollständige Clusterung laden'};
    welche_Auswahl = Auswahl_Pushbuttons(Auswahl, 'Wie soll die Clusterung geladen werden:');
    switch welche_Auswahl
        case 1,
            % Es werden nur die Inputdaten der Clusterung geladen:
            Daten = Daten.ClusterData;
            MyDisp('Inputdaten der Clusterung erfolgreich geladen.', [0 1 0])
        case 2,
            % Vollständige Clusterung laden
            Laden_einer_Clusterung(Daten, handles);
            MyDisp('Vollständige Clusterung erfolgreich geladen.', [0 1 0])
            return % Damit ist alles abgeschlossen
        otherwise
            % Es wurde nichts ausgewählt
            return % Dann wird auch nichts unternommen.
    end
    
end

if iscell(Daten)
    Daten_cell = Daten;
    try
        Daten           = nan( size(Daten_cell) ); % vordimensionieren
        MyDisp('Zeitformat umwandeln ...')
        Daten(:,1)      = richtige_zeit( Daten_cell(:,1) );
        MyDisp('    ... fertig. (Zeitformat umwandeln)')
        Daten_Werte_Cell = Daten_cell(:,2:end);
        MyDisp('Prüfen auf nicht numerische Werte ...')
        idx_nicht_numerisch   = ~cellfun(@isnumeric, Daten_Werte_Cell);
        
        % Wenn nicht numerische Werte enthalten sind, werden diese zu NaN ersetzt:
        if any(idx_nicht_numerisch),
            Werte_nicht_numerisch = unique(Daten_Werte_Cell(idx_nicht_numerisch));
            Werte_als_String = Cell_zu_String_mit_Trennzeichen(Werte_nicht_numerisch, ', ');
            MyDisp(['    ... Einige Werte in den Daten sind nicht numerisch (',Werte_als_String,'). Diese werden zu "keine Werte vorhanden" gesetzt.'], [1 0 0])
            [Daten_Werte_Cell{idx_nicht_numerisch}] = deal(NaN);
        end
        Daten(:,2:end)  = cell2mat(Daten_Werte_Cell);
        
    catch
        errordlg('Fehler beim Dateneinlesen. Unbekanntes Format. Es dürfen nur Zahlen enthalten sein.')
        error('Fehler beim Dateneinlesen. Unbekanntes Format. Es dürfen nur Zahlen enthalten sein.')
    end
elseif isnumeric(Daten),
    % Die Daten sind numerisch.
    % Prüfen, ob die Zeiten in Unix-Zeit oder anderem Format vorliegen (falls ja werden die Zeiten in Matlab Zeit umberechnet).
    MyDisp('Zeitformat umwandeln ...')
    Daten(:, 1) = richtige_zeit ( Daten(:, 1) );
    MyDisp('    ... fertig. (Zeitformat umwandeln)')
else
    error('Einlesen der Daten fehlgeschlagen. Format unbekannt.')
end
MyDisp('ClusterData erfolgreich eingelesen.', [0 1 0])

%% Tage an welchen 50 % der Verkehrsstärke keine Daten enthalten werden ausgefiltert:
proz_NaN_pro_Tag = 50; % in Prozent [%]
Anzahl_NaN_Werte = sum(isnan(Daten(:,2:end)),2);
Anzahl_Intervalle_pro_Tag = size(Daten, 2) - 1; 

idx_zu_viel_NaN = Anzahl_NaN_Werte > Anzahl_Intervalle_pro_Tag * proz_NaN_pro_Tag/100;
Daten(idx_zu_viel_NaN, :) = [];

%% Die ClusterDaten werden in die UserData des Pushbuttons geschrieben:
Data.Daten      = Daten;
Data.Dateiname  = Dateiname;


set(hObject, 'UserData', Data);

set(handles.text_Cluster_Data, 'String', char({'ClusterData';Dateiname}))
Zeit_Format = 'dd.mm.yyyy';
Zeit_Von = datestr(Daten(1,  1), Zeit_Format);
Zeit_Bis = datestr(Daten(end,1), Zeit_Format);
set(handles.ZeitBeginnCluster, 'String', Zeit_Von)
set(handles.ZeitEndeCluster, 'String', Zeit_Bis)

% Felder anzeigen:
set(handles.ZeitBeginnCluster, 'Visible', 'on')
set(handles.ZeitEndeCluster, 'Visible', 'on')

set(handles.ZeitBeginnText, 'String', ['Erster  Tag (min.',32,Zeit_Von,')'])
set(handles.ZeitBeginnText, 'UserData', Daten(1,  1))
set(handles.ZeitEndeText, 'String', ['Letzter Tag (max.',32,Zeit_Bis,')'])
set(handles.ZeitEndeText, 'UserData', Daten(end,1))
set(handles.ZeitBeginnText, 'Visible', 'on')
set(handles.ZeitEndeText, 'Visible', 'on')

% Wenn ClusterData geladen wurde, kann eine Clusterung angelegt werden:
wie_Schalten = 'on';
welche_Buttons = 1; % Alle Buttons
Buttons_Clusterung_an_aus(handles, wie_Schalten, welche_Buttons);

MyDisp('ClusterData eingelesen und erfolgreich formatiert.', [0 1 0])

end

function Laden_einer_Clusterung(Clusterung, handles)
% Es wird eine vollständige Clusterung geladen:

if ishandle(handles.ClusterKalenderFigure),
    close(handles.ClusterKalenderFigure) % Der bisherige Clusterkalender wird geschlossen.
    handles.ClusterKalenderFigure = [];
end

% wo speichere ich die Clusterungen?
Clusterungen = get(handles.ClusterungNeu, 'UserData');
if isempty(Clusterungen) || ~isa(Clusterung, 'class_Clusterung'),
    Clusterungen = Clusterung;
else
    Clusterungen(end + 1) = Clusterung;
end
Clusterungen(end).Nr = max([Clusterungen.Nr]) + 1; %length(Clusterungen);  % Die Nr der Clusterung setzten.
set(handles.ClusterungNeu, 'UserData', Clusterungen);

% Das Folgende wird nur durchgeführt, wenn das Erzeugen einer Clusterung erfolgreich war.
if Clusterung.Initialisiert,
    % Berechnen der Silhouette-Werte der Vorklassifizierung
    % Clusterung.SilhouetteVorklassifizierungBerechnen;
    
    % alte Zeichnungen löschen, neue Clusterung auf aktiv setzen und vorhandene Clusterungen neu darstellen
    set(handles.ClusterungenTabelle,'UserData',Clusterung.Nr)
    UpdateClusterungenTabelle(handles);
    UpdatePlots(handles)
    
    % Wenn eine Clusterung geladen wird, können alle Buttons aktiviert werden:
    wie_Schalten = 'on';
    welche_Buttons = [1, 2, 3]; % Alle Buttons
    Buttons_Clusterung_an_aus(handles, wie_Schalten, welche_Buttons);
end
end