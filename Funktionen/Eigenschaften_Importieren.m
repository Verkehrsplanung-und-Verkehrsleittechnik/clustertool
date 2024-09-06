function [Daten, Bezeichnung_Eigenschaft] = Eigenschaften_Importieren(Dateiname)
%EIGENSCHAFTEN_IMPORTIEREN 
% Fall zus�tzliche Eigenschaften laden -> wenn m�glich in Datei importieren
% integrieren

% Die Daten m�ssen die Form habe:
% 1.    Zeile:     �berschrift der Eigenschaft (2.-n. Spalte)
% 1.    Spalte:    Zeit des Tages im Matlab-Zeit Format ODER Unix-Zeit
% 2.-n. Spalte:    Auspr�gung der Eigenschaft

% Datei �ffnen:
[Daten] = Datei_Oeffnen(Dateiname);

if isempty(Daten)
    % Es wurde auf abbrechen geklickt.
    return
end

if isnumeric(Daten)
    % Zu Cell �ndern:
    Daten = num2cell(Daten);
elseif iscell(Daten)
    % Alles OK.
else
    error('Fehler: zus�tzliche Eigenschaft Fehlerhaft. Keine Daten eingelesen.')
end

% Pr�fen, ob �berschriften vergeben sind:
if isempty(Daten{1,1}) || (length(Daten{1,1}) == 1 && isnan(Daten{1,1}))
    Bezeichnung_Eigenschaft = Daten(1,2:end);
    Daten(1,:) = [];
else
    Anzahl_Eigenschaften = size(Daten, 2) - 1;
    Bezeichnung_Eigenschaft = cell(1, Anzahl_Eigenschaften); % vordimensionieren
    for cnt_E = 1 : Anzahl_Eigenschaften
        Bezeichnung_Eigenschaft{cnt_E} = ['Zusatz_Eigenschaft_',num2str(cnt_E)];
    end
end

% Zeiten unterschiedlicher Format zur Matlab-Zeit umformen:
Zeiten = richtige_zeit(Daten(:,1));
Daten(:,1) = num2cell(Zeiten);

% Wenn die Eigenschaften numerisch sind, wird daraus ein Text:
Daten_ohne_Zeit = Daten(:,2:end);
idx_nan = cellfun(@(x) isnumeric(x) && isnan(x), Daten_ohne_Zeit);
idx_num = cellfun(@isnumeric, Daten_ohne_Zeit);
Daten_ohne_Zeit(idx_num) = cellfun(@(x) num2str(x), Daten_ohne_Zeit(idx_num), 'UniformOutput', false);
[Daten_ohne_Zeit{idx_nan}] = deal([]);
Daten(:,2:end) = Daten_ohne_Zeit;

end
