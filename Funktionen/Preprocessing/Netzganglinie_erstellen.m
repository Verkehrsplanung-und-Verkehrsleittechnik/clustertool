function [Netzganglinie, IDs, Tageszeit, Zeit_plus_ID] = Netzganglinie_erstellen(Daten_Matrix, Reihenfolge_ID, einzelne_Obj_ID, Intervallgroesse)
% Erstellt eine Netzganglinie
%
%   Eingang: ----------------------------------------------
% - Daten_Matrix
%       Daten_Matrix ist ...
%           1. Spalte  | 2.-n.te Spalte  (je nach Anzahl Detektoren (einzelne_Obj_ID))
%               Zeit   |   Zählwert eines Detektors
% - Reihenfolge_ID
%       Die Reihenfolge in der die IDs zur Netzganglinie zusammengesetzt werden soll.
% - einzelne_Obj_ID
%       Alle ID, welche in "Daten_Matrix" vorkommen. 
%       Die Zählwerte von einzelne_Obj_ID{1} müssen in der Spalte Daten_Matrix(:, 1 + 1) stehen. 
%       Die Zählwerte von einzelne_Obj_ID{n} müssen in der Spalte Daten_Matrix(:, 1 + n) stehen.
% - Intervallgroesse
%       In Minuten [min]
%
%   Rückgabe: ----------------------------------------------
% - Netzganglinie   
%       n x m Matrix mit n = Anzahl der Tage, m = Anzahl der Zeitintervalle eines Tages * Anzahl Objekte (Detektoren) + 1 (erste Spalte steht der Tage)
%       1. Spalte: Zeit im Matlab Format (ganze Tage)
%       2.- m-te Spalte: Verkehrsstärken an diesem Tag, geordnet zuerst nach den Objekten (Detektoren), dann nach der
%       Zeit 
%           => 2.  Spalte ID 123 Zeit 00:00,  3. Spalte ID 123 Zeit 01:00,  4. Spalte ID 123 Zeit 02:00
%              25. Spalte ID 123 Zeit 23:00, 26. Spalte ID 777 Zeit 00:00, 27. Spalte ID 777 Zeit 01:00
% - IDs
%       1 x (m-1)   Cell mit der     ID    für jede Spalte von "Netzganglinie" in der eine Verkehrsstärke enthalten ist.
% - Tageszeit
%       1 x (m-1) Vektor mit der Tageszeit für jede Spalte von "Netzganglinie" in der eine Verkehrsstärke enthalten ist.
% - Zeit_plus_ID
%       1 x (m-1)   Cell mit einer zusammengefassten Bezeichnung für jede Spalte von "Netzganglinie" in der eine Verkehrsstärke enthalten ist.
%       z.B. {'00:00 ID: 123', '01:00 ID: 123', ..., '23:00 ID: 123', '00:00 ID: 777', '01:00 ID: 777', ..., '23:00 ID: 777'}


Zeit = Daten_Matrix(:,1);

%% Alle Tage welche vorkommen:
[Alle_Tage, ~, idx_Tag] = unique(floor(Zeit));

%% TOD Zeiten berechnen:
flag_nur_tod        = true;
flag_addiere_10ms   = true; % Zur Zeit wird jeweils 10ms hinzuaddiert, damit Rundungsfehler vermieden werden können.
[idx_toddow, toddow_Intervalle] = toddow( Zeit, Intervallgroesse, flag_nur_tod, flag_addiere_10ms );

Anzahl_Tage                     = max(idx_Tag);
Anzahl_Zeitintervalle_ein_Tag   = max(idx_toddow);

Anzahl_Obj_in_NGLM = length(Reihenfolge_ID); % Anzahl der Objekte (Detektoren) in der NetzganglinienMatrix

% Hier wird die Reihenfolge der Spalten festgelegt, wie die Netzganglinien zusammengesetzt wird.
[~, Reihenfolge_Spalten] = ismember(Reihenfolge_ID, einzelne_Obj_ID);

%% GMatrix == GanglinienMatrix (ohne Zeit in der ersten Spalte).
% Es wird für jedes Objekt (Detektor) eine seperate GanglinienMatrix gebildet.
GMatrix = cell(1, Anzahl_Obj_in_NGLM); % vordimensionieren
for cnt_Spalte = 1 : Anzahl_Obj_in_NGLM,
    akt_Spalte = Reihenfolge_Spalten(cnt_Spalte) + 1; % +1, da in der ersten Spalte von "Daten_Matrix" die Zeit steht.
    
    GMatrix{cnt_Spalte}       = nan(Anzahl_Tage, Anzahl_Zeitintervalle_ein_Tag); % vordimensionieren
    
    welche_Methode = 2; % Methode 2 ist schneller. Ergenis natürlich identisch :).
    switch welche_Methode,
        case 1,
            % Werte in die Matrix eintragen:
            % Für jeden Tag machen:
            for cnt_Tag = 1 : length(Alle_Tage),
                idx_Zeile_akt_Tag = idx_Tag == cnt_Tag;
                GMatrix{cnt_Spalte}(cnt_Tag, idx_toddow(idx_Zeile_akt_Tag)) = Daten_Matrix(idx_Zeile_akt_Tag, akt_Spalte);
            end
            
        case 2,
            % Werte in die Matrix eintragen:
            % Für jedes Element machen:
            for cnt_i = 1 : size(Daten_Matrix, 1),
                GMatrix{cnt_Spalte}(idx_Tag(cnt_i), idx_toddow(cnt_i)) = Daten_Matrix(cnt_i, akt_Spalte);
            end
    end
end

%% Jetzt die einzelnen GMatrix (= GanglinienMatrix) zur NetzGangLinienMatrix zusammenpacken:
Netzganglinie = nan(Anzahl_Tage, Anzahl_Zeitintervalle_ein_Tag * Anzahl_Obj_in_NGLM + 1); % vordimensionieren

% Erste GanglinienMatrix übergeben:
Netzganglinie(:, 1)     = Alle_Tage;
Netzganglinie(:, 2:end) = horzcat(GMatrix{:});


%% Weitere Ausgänge:

if nargout > 1,
    %% - IDs
    %       1 x (m-1)   Cell mit der     ID    für jede Spalte von "Netzganglinie" in der eine Verkehrsstärke enthalten ist.
    
    welcher_Vektor = 1;
    %   1: Vektor der Form: [1,1,1,1,               2,2,2,2,                3,3,3,3, ...,           max_Wert, max_Wert, max_Wert, max_Wert] bei Hauefigkeit = 4;
    %   2: Vektor der Form: [1,2,3,...,max_Wert,    1,2,3,...,max_Wert,     1,2,3,...,max_Wert,     1,2,3,...,max_Wert                    ] bei Hauefigkeit = 4;    
    Haeufigkeit = Anzahl_Zeitintervalle_ein_Tag;
    max_Wert    = Anzahl_Obj_in_NGLM;
    idx_IDs     = idx_Vektor_generieren(welcher_Vektor, Haeufigkeit, max_Wert);
    IDs         = cell(1, length(idx_IDs)); % Als Spaltenvektor vordimensionieren
    IDs(1:end)  = Reihenfolge_ID(idx_IDs);
end

if nargout > 2,
%% - Tageszeit
    %       1 x (m-1) Vektor mit der Tageszeit für jede Spalte von "Netzganglinie" in der eine Verkehrsstärke enthalten ist.
    
    welcher_Vektor      = 2;
    %   1: Vektor der Form: [1,1,1,1,               2,2,2,2,                3,3,3,3, ...,           max_Wert, max_Wert, max_Wert, max_Wert] bei Hauefigkeit = 4;
    %   2: Vektor der Form: [1,2,3,...,max_Wert,    1,2,3,...,max_Wert,     1,2,3,...,max_Wert,     1,2,3,...,max_Wert                    ] bei Hauefigkeit = 4;    
    Haeufigkeit         = Anzahl_Obj_in_NGLM;
    max_Wert            = Anzahl_Zeitintervalle_ein_Tag;
    idx_Tageszeit       = idx_Vektor_generieren(welcher_Vektor, Haeufigkeit, max_Wert);
    Tageszeit           = nan(1, length(idx_Tageszeit)); % Als Spaltenvektor vordimensionieren
    Tageszeit(1:end)    = toddow_Intervalle(idx_Tageszeit);
end

if nargout > 3,
    %% - Zeit_plus_ID
    %       1 x (m-1)   Cell mit einer zusammengefassten Bezeichnung für jede Spalte von "Netzganglinie" in der eine Verkehrsstärke enthalten ist.
    %       z.B. {'00:00 ID: 123', '01:00 ID: 123', ..., '23:00 ID: 123', '00:00 ID: 777', '01:00 ID: 777', ..., '23:00 ID: 777'}
    % Zeit_plus_ID = cell(1, Anzahl_Zeitintervalle_ein_Tag * Anzahl_Obj_in_NGLM); % Als Spaltenvektor vordimensionieren
    Zeit_plus_ID = cellfun(@(x,y) [datestr(x, 'HH:MM'),32,'ID:',32,y], num2cell(Tageszeit), IDs, 'UniformOutput', false);
    
    
end

end




















