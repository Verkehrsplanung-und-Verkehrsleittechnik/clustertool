function [Struct_Felder_dazu, Felder_hinzufuegen] = Struct_nicht_vorhandene_Felder_uebernehmen(Struct_Felder_dazu, Struct_Felder_von)
% Diese Funktion fügt alle nicht vorhandenen Felder von "Struct_Felder_von" zur Struct "Struct_Felder_dazu" hinzu.
% Bei Felder, welche selbst wieder Struct sind. Wie wieder überprüft, welche "Unterfelder" vorhanden sind (siehe
% Beispiel #2).
%
%
% -- Eingang: ---------------------------------
%   - Struct_Felder_dazu
%           1x1 Struct mit beliebigen Feldern
%   - Struct_Felder_von
%           1x1 Struct mit beliebigen Feldern
%
% -- Rückgabe: --------------------------------
%   - Struct_Felder_dazu
%           1x1 Struct mit allen Feldern von "Struct_Felder_dazu" und "Struct_Felder_von".
%           Wenn in beiden Structs Felder mit gleichem Feldname eingehen, wird das Feld von "Struct_Felder_dazu"
%           behalten.
%   - Felder_hinzufuegen
%           Diese Felder wurden "Struct_Felder_dazu" hinzugefügt.
%
% %                                         JL 27.11.2013  (Version #1 ohne Unterstructs: 16.04.2013)
% % Beispiel #1:
% Struct_Felder_dazu = struct('Feld1', [1,2,3], 'Feld3', 'lala');
% Struct_Felder_von  = struct('Feld1', 'sumsum', 'Feld2', 'blablabla', 'Feld4', {'Cell1'});
% [Struct_Felder_dazu, Felder_hinzufuegen] = Struct_nicht_vorhandene_Felder_uebernehmen(Struct_Felder_dazu, Struct_Felder_von)
%
% % Struct_Felder_dazu = 
% %     Feld1: [1 2 3]      % "Feld1" von "Struct_Felder_von" wird nicht übernommen, das "Feld1" in "Struct_Felder_dazu" existiert.
% %     Feld3: 'lala'
% %     Feld2: 'blablabla'  % wurde von "Struct_Felder_von" übernommen
% %     Feld4: 'Cell1'      % wurde von "Struct_Felder_von" übernommen
% % 
% % Felder_hinzufuegen = 
% %     'Feld2'
% %     'Feld4'
% %     
% 
% % Beispiel #2:
% Struct_Felder_dazu                = struct('Feld1',  [1, 2, 3], 'Feld3',  'lala');
% Struct_Felder_dazu.UnterStruct    = struct('Feld11', [4, 5, 6], 'Feld13', 'lala2');
% Struct_Felder_dazu.UnterStruct.A2 = struct('xFeld',  132);
% Struct_Felder_von                 = struct('Feld1',  'sumsum',  'Feld2',  'blablabla');
% Struct_Felder_von.UnterStruct     = struct('Feld11', 'sumsum2', 'Feld12', 'blablabla2');
% Struct_Felder_von.UnterStruct.A1 = [12];
% Struct_Felder_von.UnterStruct.A2 = 456;   % Das Feld wird nicht übernommen, da bereits ein solches Feld in "Struct_Felder_dazu.UnterStruct" besteht.
% [Struct_Felder_dazu, Felder_hinzufuegen] = Struct_nicht_vorhandene_Felder_uebernehmen(Struct_Felder_dazu, Struct_Felder_von);
%
% 
if nargin < 1 || ~isstruct(Struct_Felder_dazu),
    error('Der erste Eingang muss eine Struct sein.')
elseif isempty(Struct_Felder_dazu),
    Struct_Felder_dazu = struct(); % Falls eine 0x0 struct übergeben wird. Hier wird eine 1x1 benötigt.
end
if nargin < 2 || ~isstruct(Struct_Felder_von),
    warning('Der zweite Eingang ist nicht vorhanden ODER keine Struct. In dieser Funktion wird nichts geändert.')
    return;
end

% Standardeinstellungen für fehlende Einstellungen übernehmen:
Vorhandene_Felder_Struct_Felder_dazu    = fieldnames(Struct_Felder_dazu);
Alle_Felder_Struct_Felder_von           = fieldnames(Struct_Felder_von);
Felder_hinzufuegen                      = Alle_Felder_Struct_Felder_von(~ismember(Alle_Felder_Struct_Felder_von, Vorhandene_Felder_Struct_Felder_dazu));


%% Jedes Feld, welches noch nicht in "Struct_Felder_dazu" vorhanden ist hinzufügen:
for cnt_Fh = 1 : length(Felder_hinzufuegen),
    
    akt_Feld = Felder_hinzufuegen{cnt_Fh};
    Struct_Felder_dazu.(akt_Feld) = Struct_Felder_von.(akt_Feld);

end % for cnt_Fh = 1 : length(Felder_hinzufuegen),



%% Felder, welche selsbt Struct sind müssen untersucht werden:
idx_Feld_Unterstruct = cellfun(@(x) isstruct(Struct_Felder_dazu.(x)), Vorhandene_Felder_Struct_Felder_dazu);
Felder_UnterStuct = Vorhandene_Felder_Struct_Felder_dazu(idx_Feld_Unterstruct);

% Prüfen, ob diese Felder auch in "Struct_Felder_von" existieren:
idx_Unterstruct_existiert = ismember(Felder_UnterStuct, Alle_Felder_Struct_Felder_von);
Felder_UnterStuct_existiert = Felder_UnterStuct(idx_Unterstruct_existiert);

% Prüfen, ob das Feld in "Struct_Felder_von" auch eine Struct ist:
idx_Feld_Unterstruct = cellfun(@(x) isstruct(Struct_Felder_von.(x)), Felder_UnterStuct_existiert);
Felder_UnterStuct_ist_Struct = Felder_UnterStuct_existiert(idx_Feld_Unterstruct);

for cnt_F = 1 : length(Felder_UnterStuct_ist_Struct),
    akt_Feld = Felder_UnterStuct_ist_Struct{cnt_F};
    % Funktion wird mit der UnterStruct erneut aufgerufen:
    Struct_Felder_dazu.(akt_Feld) = Struct_nicht_vorhandene_Felder_uebernehmen(Struct_Felder_dazu.(akt_Feld), Struct_Felder_von.(akt_Feld));
end



end % MAIN function


















