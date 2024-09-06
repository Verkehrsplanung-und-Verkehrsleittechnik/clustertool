function [Daten, Dateiendung] = Datei_Oeffnen(Dateiname)
%DATEI_OEFFNEN Ließt Daten entweder von einer Excel Tabelle oder einer Mat Datei ein.
%   Diese Funktion kümmert sich nur um das möglichs effiziente Öffnen/Laden
%   von Daten. Die Fallunterscheidung der Formate findet in der Funktion
%   "Daten_Importieren.m" statt
%
%   Bedingung: Die Daten müssen als Clusterobjekt oder Matrix/Tabelle vorliegen, die als .mat,
%   .xlsx oder .csv vorliegt.

if nargin < 1 || isempty(Dateiname)
    error('Import Daten: keine Datei ausgewählt')
end

% Die Dateiendung auslesen:
Dateiendung = lower(fliplr(strtok(fliplr(Dateiname), '.')));

switch Dateiendung
    case 'mat'
        Daten = load(Dateiname);
        if isstruct(Daten)
            Felder = fieldnames(Daten);
            if length(Felder) > 1
                Nr_Variable = Auswahl_Pushbuttons(Felder', 'Auswahl der Variable:');
            else
                % Es gibt nur eine Variable:
                Nr_Variable = 1; 
            end
            Daten = Daten.(Felder{Nr_Variable});
        else
           error('Dieser Fehler sollte eigentlich nie auftreten.') 
        end
        
    case {'xls', 'xlsx'}
        [~,sheets] = xlsfinfo(Dateiname);        
        if length(sheets) > 1            
            Datei = dir(Dateiname);
            Dateigroesse_MB = Datei.bytes/1024/1024; % Dateigröße in MB (Megabyte)
            
            Grenze_zum_Schnelloeffnen_MB = 3; % Dateien mit kleiner als hier angegeben werden geöffenen und untersucht, welche Sheets Daten enthalten:
            if Dateigroesse_MB < Grenze_zum_Schnelloeffnen_MB
                Daten_Sheets = cell(1, length(sheets)); % vordimensionieren
                for cnt_S = 1 : length(sheets)
                    [~, ~, Daten_Sheets{cnt_S}] = xlsread(Dateiname, sheets{cnt_S});
                end
                Anzahl_Daten_in_den_Sheets = cellfun(@numel, Daten_Sheets);
                % Sheets mit nur einem Eintrag (1x1) sind leer.
                sheets(Anzahl_Daten_in_den_Sheets == 1) = [];
                Daten_Sheets(Anzahl_Daten_in_den_Sheets == 1) = []; % Weil diese Daten später nicht erneut geladen werden müssen und die Zuordnung erhalten bleiben soll.
            end
            
            if length(sheets) > 1
                % Auswahl des Sheets:
                Nr_Sheet = Auswahl_Pushbuttons(sheets', 'Auswahl des Sheets:');
                % Mit der -1 wird aktiviert, dass man den Bereich selbst auswählen soll.
                % [~, ~, Daten] = xlsread(Dateiname, -1);
            else
                Nr_Sheet = 1;
            end
        else
            Nr_Sheet = 1;
        end
        
        if exist('Daten_Sheets', 'var')
            Daten = Daten_Sheets{Nr_Sheet};
        else
            [~, ~, Daten] = xlsread(Dateiname, sheets{Nr_Sheet});
        end
    case 'csv'
        % Import im Tabellenformat, nachträgliches Untersuchen des Datums
        % in Skript Daten_Importieren
        Daten = readtable(Dateiname);
        % todo Test
        warndlg('Achtung: Import von .csv Dateien ist nicht ausreichend getestet')
    otherwise
        error('Diese Dateiendung wird (noch) nicht unterstützt.')
end

end % function

