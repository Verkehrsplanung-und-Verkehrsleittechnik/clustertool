function [Daten, Clusterobj] = Daten_Importieren(Dateiname)
%DATEN_IMPORTIEREN
% Die Daten müssen die Form haben:
% 1. Spalte:    Zeit des Tages im Matlab-Zeit Format ODER Unix-Zeit ODER EXCEL Nummer Format
% 2.-n. Spalte: Die Werte für die Clusterung, z.B. die Verkehrsstärken der einzelnen Stunden des Tages (n=25)

MyDisp('ClusterData einlesen')

% Datei öffnen:
MyDisp('Datei öffenen')
[Daten, ~] = Datei_Oeffnen(Dateiname);
Clusterobj = [];
MyDisp('Datei gelesen.')
if isempty(Daten)
    % Es wurde auf abbrechen geklickt.
    return
end

if isa(Daten, 'class_Clusterung')
    MyDisp('Clusterdatei erkannt.')
    Auswahl = { 'Es sollen nur die Inputdaten der Clusterung geladen werden.';
        'Vollständige Clusterung laden'};
    welche_Auswahl = Auswahl_Pushbuttons(Auswahl, 'Wie soll die Clusterung geladen werden:');
    switch welche_Auswahl
        case 1
            % Es werden nur die Inputdaten der Clusterung geladen:
            Daten = Daten.ClusterData;
            MyDisp('Inputdaten der Clusterung erfolgreich geladen.', [0 1 0])
        case 2
            % Vollständige Clusterung laden
            %Laden_einer_Clusterung(Daten, handles);
            Clusterobj = Daten;
            Daten = Daten.ClusterData;
                   
            return % Damit ist alles abgeschlossen
        otherwise
            % Es wurde nichts ausgewählt
            return % Dann wird auch nichts unternommen.
    end % switch
end % if

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
        if any(idx_nicht_numerisch)
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
elseif isnumeric(Daten)
    % Die Daten sind numerisch.
    % Prüfen, ob die Zeiten in Unix-Zeit oder anderem Format vorliegen (falls ja werden die Zeiten in Matlab Zeit umberechnet).
    MyDisp('Zeitformat umwandeln ...')
    Daten(:, 1) = richtige_zeit ( Daten(:, 1) );
    MyDisp('    ... fertig. (Zeitformat umwandeln)')
    
elseif istable(Daten)
    % Datenformat: Tabelle
    % Prüfen, ob die Zeiten als Text oder Zahl vorliegen    
    zeitvektor =  table2array(Daten(:,1));
    data = table2array(Daten(:, 2:end));
    if isdatetime(zeitvektor)         
         zeitvektor = datenum(zeitvektor);
    else
          zeitvektor = richtige_zeit ( zeitvektor );
    end        
    
    % Zusammensetzung der Daten als Matrix, da Datentyp Table bei der Entwicklung des Tools
    % nicht zur Verfügung stand
    Daten = [zeitvektor, data];   
elseif istimetable(Daten)
    % Datenformat: Tabelle mit Zeit als Index
    % Prüfen, ob die Zeiten als Text oder Zahl vorliegen    
    zeitvektor =  Daten.Properties.RowTimes;
    data = table2array(Daten(:, 2:end));
    if isdatetime(zeitvektor)         
         zeitvektor = datenum(zeitvektor);
    else
          zeitvektor = richtige_zeit ( zeitvektor );
    end        
    
    % Zusammensetzung der Daten als Matrix, da Datentyp Table bei der Entwicklung des Tools
    % nicht zur Verfügung stand
    Daten = [zeitvektor, data];  

else
    error('Einlesen der Daten fehlgeschlagen. Format unbekannt.')
end
MyDisp('ClusterData erfolgreich eingelesen.', [0 1 0])

%% Warnung, wenn mehr als 50 % NaN Werte pro Tag
proz_NaN_pro_Tag = 50; % in Prozent [%]
Anzahl_NaN_Werte = sum(isnan(Daten(:,2:end)),2);
Anzahl_Intervalle_pro_Tag = size(Daten, 2) - 1; 

idx_zu_viel_NaN = Anzahl_NaN_Werte > Anzahl_Intervalle_pro_Tag * proz_NaN_pro_Tag/100;
%Daten(idx_zu_viel_NaN, :) = [];

% if sum(idx_zu_viel_NaN) > 50
%     warndlg("Achtung: " + num2str(sum(idx_zu_viel_NaN)) + " Tage haben mehr als 50% ungültige Werte")
% end

%MyDisp(num2str(sum(idx_zu_viel_NaN)) + ' Tage haben mehr als 50% ungültige Werte')
end 
function zeit_aus = richtige_zeit ( zeit_ein, flag_unterschiedliche_Zeitformate )
%zeit_aus = richtige_zeit ( zeit_ein )
%   Gibt aus einer Zeit eine Matlab-Zeit wieder.
%   Folgende Eingaben werden automatisch erkannt und untzerstützt:
%   - Unix-Zeit
%   - Excel-Serial-Zeit
%   - Folgende String-Formate: (wird über die Länge des Stings entschieden)
%       - dd.mm.yyyy HH:MM:SS (20)
%       - dd.mm.yyyy HH:MM (17)
%       - dd.mm.yyyy (10)
%       - dd.mm.yy HH:MM:SS (16)
%       - dd.mm.yy HH:MM (13)
%       - dd.mm.yy (8)
%       - ddmm (4)
%       - dd.mm (5)
%       - ddmmyy (6)
%
% zeit_ein kann numerisch, ein Charakter oder eine Cell sein.
% Die Zeiten können auch innerhalb einer Cell unterschiedliche Zeit-Formate enthalten.
% Bei numerischem Eingang, wird angebnommen, dass die Zeitformate gleich sind.
% Falls diese nicht der Fall sein sollte (z.B. Unix, Excel und Matlab-Zeit gemischt), muss der zweite Eingang
% "flag_unterschiedliche_Zeitformate" zu true gesetzt werden.
if nargin < 2 || isempty(flag_unterschiedliche_Zeitformate),
    flag_unterschiedliche_Zeitformate = false;
end


% Auch eine Unix -Zeit wird zur Matlab-Zeit umgewandelt (25.05.2012; JL)
% Auch eine Excel-Zeit wird zur Matlab-Zeit umgewandelt (10.03.2014; JL)


%% Wenn alle Zeiten numerisch sind:
if ~flag_unterschiedliche_Zeitformate && isnumeric(zeit_ein),
    % Prüfen, ob die Zeiten in Unix-Zeit vorliegen (falls ja werden die Zeiten in Matlab Zeit umberechnet).
    if sum(zeit_ein > 1e6 | zeit_ein < 0) > length(zeit_ein) / 2
        % Wenn mehr als die Hälfte der Zeit-Werte größer als 1.000.000 oder kleiner als 0 (Zeit vor 1970) sind, dann ist es eine Unix-Zeit.
        % Unix-Zeit 1.000.000   => 11.01.1970
        % Matlab-Zeit 1.000.000 => 27.11.2737
        zeit_aus = unix_Zeit(zeit_ein, 2);
    elseif sum(zeit_ein < 100000) > length(zeit_ein) / 2
        % Wenn mehr als die Hälfte der Zeit-Werte kleiner als 100.000 sind, dann ist es eine Excel-Zeit.
        % Excel Zeit  (100.000) => Donnerstag, 14. Oktober 2173
        % Matlab Zeit (100.000) => 15-Oct-0273
        % welche_Richtung
        %   1: von Excel-Zeit in Matlab-Zeit
        %   2: von Matlab-Zeit in Excel-Zeit
        welche_Richtung = 1;
        zeit_aus = excel_zeitumrechnung( zeit_ein, welche_Richtung );
    else
        % Zeit ist vermutlich Matlabzeit:
        zeit_aus = zeit_ein;
        return % Funktion beendet.
    end
end



%% Wenn die Zeiten nicht numerische sind, kann einzeln durchgegangen werden, der Zeitgewinn ist in diesem Fall nicht mehr so groß:
if ~iscell(zeit_ein), zeit_ein = {zeit_ein}; end % zeit_ein wird zu einer Cell umformatiert.

zeit_aus = nan(size(zeit_ein)); % vordimensionieren

for cnt_zeit_zeile = 1 : size(zeit_ein, 1),         % Für jede Zeile von "zeit_ein"
    for cnt_zeit_spalte = 1 : size(zeit_ein, 2),    % Für jede Spalte von "zeit_ein"
        akt_zeit = zeit_ein{cnt_zeit_zeile, cnt_zeit_spalte};
        clear zeit_num
        
        if isnumeric(akt_zeit),
            % wenn "akt_zeit" nummerisch ist, dann wird untersucht, ob das Datum im Bereich der Unix-Zeit liegt:
            if akt_zeit > 1e6 || akt_zeit < 0, % Prüfen, ob die Zeiten in Unix-Zeit vorliegen (falls ja werden die Zeiten in Matlab Zeit umberechnet).
                % Wenn der Zeit-Wert größer als 1.000.000 oder kleiner als 0 (Zeit vor 1970) sind, dann ist es eine Unix-Zeit.
                % Unix-Zeit 1.000.000   => 11.01.1970
                % Matlab-Zeit 1.000.000 => 27.11.2737
                zeit_num = unix_Zeit(akt_zeit, 2);
            elseif akt_zeit < 100000,
                % Wenn der Zeit-Werte kleiner als 100.000 sind, dann ist es eine Excel-Zeit.
                % Excel Zeit  (100.000) => Donnerstag, 14. Oktober 2173
                % Matlab Zeit (100.000) => 15-Oct-0273
                % welche_Richtung
                %   1: von Excel-Zeit in Matlab-Zeit
                %   2: von Matlab-Zeit in Excel-Zeit
                welche_Richtung = 1;
                zeit_num = excel_zeitumrechnung( akt_zeit, welche_Richtung );
            else
                % Wenn die Zahl kleiner als 1e6 wird angenommen, dass die eingehende Zeit bereits im Matlab - Zeit Format vorliegt.
                zeit_num = akt_zeit;
            end
        else
            % "akt_zeit" ist nicht numerisch:
            if strfind(akt_zeit,'-'), Datumstrennzeichen='-'; else  Datumstrennzeichen='.'; end
            
            if ischar(akt_zeit), %kann nur durchgeführt werden, wenn "akt_zeit" char ist. 
                switch length(akt_zeit),
                    case 17,
                        zeit_num=datenum(akt_zeit,['dd',Datumstrennzeichen,'mm',Datumstrennzeichen,'yy HH:MM:SS']);
                    case 14,
                        zeit_num=datenum(akt_zeit,['dd',Datumstrennzeichen,'mm',Datumstrennzeichen,'yy HH:MM']);
                    case 16,
                        zeit_num=datenum(akt_zeit,['dd',Datumstrennzeichen,'mm',Datumstrennzeichen,'yyyy HH:MM']);
                    case 20,
                        zeit_num=datenum(akt_zeit,['dd',Datumstrennzeichen,'mmm',Datumstrennzeichen,'yyyy HH:MM:SS']);                    
                    case 19,
                        zeit_num=datenum(akt_zeit,['dd',Datumstrennzeichen,'mm',Datumstrennzeichen,'yyyy HH:MM:SS']);
                    case 10,
                        zeit_num=datenum(akt_zeit,['dd',Datumstrennzeichen,'mm',Datumstrennzeichen,'yyyy']);                    
                    case 11,
                        zeit_num=datenum(akt_zeit,['dd',Datumstrennzeichen,'mmm',Datumstrennzeichen,'yyyy']);
                    case 8,
                        zeit_num=datenum(akt_zeit,['dd',Datumstrennzeichen,'mm',Datumstrennzeichen,'yy']);
                    case 4,
                        zeit_num=datenum(akt_zeit,'ddmm');
                    case 5,
                        zeit_num=datenum(akt_zeit,['dd',Datumstrennzeichen,'mm']);
                    case 6,
                        zeit_num=datenum(akt_zeit,'ddmmyy');                        
                    otherwise,
                        msgbox(sprintf('Bitte "Zeit von" und "Zeit bis" korrekt angeben !!!\n\n z.B. dd.mm.yy HH:MM:SS'))
                end
            else
                msgbox(sprintf('Bitte "Zeit von" und "Zeit bis" korrekt angeben !!!\n\n z.B. dd.mm.yy HH:MM:SS'))
            end
        end
        if exist('zeit_num','var'),
            if length(zeit_num)>1,
                zeit_aus=zeit_num;
            else
                zeit_aus(cnt_zeit_zeile,cnt_zeit_spalte)=zeit_num;
            end
        end
    end
end
end
function [ Zeit_AUS ] = excel_zeitumrechnung( Zeit_IN, welche_Richtung )
%Rechnet die Zeit zwischen Excel-Zeit und Matlab-Zeiten um.
%
% welche_Richtung
%   1: von Excel-Zeit in Matlab-Zeit
%   2: von Matlab-Zeit in Excel-Zeit
%

% Excel hält 1900 fälschlicherweise für ein Schaltjahr. 
% Tag 60 von Excel ist in Excel der 29.02.1900
%   => excel_zeitumrechnung( 60 ) ergibt => 694020 => datestr(694020) => 28-Feb-1900
if nargin < 2 || isempty(welche_Richtung),
    if Zeit_IN > 600000, % datestr(600000) => 28-Sep-1642
        welche_Richtung = 2;
    else
        welche_Richtung = 1;
    end
end

Zeit_AUS = nan(size(Zeit_IN));

switch welche_Richtung,
    case 1,
        %Excel hält 1900 fälschlicherweise für ein Schaltjahr. 
        idx_Zeit_nach_1900 = Zeit_IN > 59;
        Zeit_AUS( idx_Zeit_nach_1900) = Zeit_IN( idx_Zeit_nach_1900) + 693960;
        Zeit_AUS(~idx_Zeit_nach_1900) = Zeit_IN(~idx_Zeit_nach_1900) + 693961;
        
    case 2,
        %Excel hält 1900 fälschlicherweise für ein Schaltjahr. 
        idx_Zeit_nach_1900 = Zeit_IN > 694020; % datestr(694020) => 28-Feb-1900
        Zeit_AUS( idx_Zeit_nach_1900) = Zeit_IN( idx_Zeit_nach_1900) - 693960;
        Zeit_AUS(~idx_Zeit_nach_1900) = Zeit_IN(~idx_Zeit_nach_1900) - 693961;        
end




end