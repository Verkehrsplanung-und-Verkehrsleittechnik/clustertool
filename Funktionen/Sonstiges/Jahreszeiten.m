function [Jahreszeiten, Jahreszeiten_Bezeichnung] = Jahreszeiten(Zeit_Matlab, wie_Jahreszeit, Zusatz_Bezeichnung)
% Gibt für eine Matrix von Zeiten im Matlab-Zeit Format, die Jahreszeit wieder.
% Mit Hilfe von "wie_Jahreszeit" kann bestimmt werden, nach welchen Regeln die Jahreszeiten bestimmt werden sollen.
%
% wie_Jahreszeit:
%   1: meteorologische Jahreszeit
%   2: kalendarisch Jahreszeit
%   3: meteorologische Jahreszeit mit 1 Monat Extra Sommer (Septeber => Sommer)
%   4: Jeder Monat für sich (keine eigentlichen Jahrezeiten)
%   5: Kalenderwoche
%
% ---- Eingänge: ------------------
%
%   - Zeit_Matlab 
%       n x m Matrix im Matlab-Zeit Format
%   - wie_Jahreszeit
%       1: meteorologische Jahreszeit
%         1. Frühling: 01. März        - 31. Mai
%         2. Sommer:   01. Juni        - 31. August
%         3. Herbst:   01. September   - 30. November
%         4. Winter:   01. Dezember    - 28. / 29. Februar       
%       2: kalendarisch Jahreszeit
%         1. Frühling: 21. März        - 20. Juni
%         2. Sommer:   21. Juni        - 22. September
%         3. Herbst:   23. September   - 20. Dezember
%         4. Winter:   21. Dezember    - 20. März
%       3: meteorologische Jahreszeit mit 1 Monat Extra Sommer (für Bundesland BW, da hier im September noch Sommerferien sind:)
%         1. Frühling: 01. März        - 31. Mai
%         2. Sommer:   01. Juni        - 30. September
%         3. Herbst:   01. Oktober     - 30. November
%         4. Winter:   01. Dezember    - 28. / 29. Februar  
%       4: Jeder Monat für sich (keine eigentlichen Jahrezeiten)
%         1.-12. Januar - Dezember
%       5: Kalenderwoche
%         1.-53.
%
%   - Zusatz_Bezeichnung
%       String, welche an die Jahreszeiten_Bezeichnung hinzugehängt wird:
%       z.B. Zusatz_Bezeichnung = '_metrologisch';
%       ==> Jahreszeiten_Bezeichnung = {'Frühling_metrologisch', 'Sommer_metrologisch', 'Herbst_metrologisch', 'Winter_metrologisch'};
% ---- Rückgabe: ------------------
%   - Jahreszeiten
%       n x m Matrix mit den Werten von 1...4 (entsprechend den Jahreszeiten)
%       1. Frühling, 2. Sommer, 3. Herbst, 4. Winter
%   - Jahreszeiten_Bezeichnung
%       ist immer gleich: Jahreszeiten_Bezeichnung = {'Frühling', 'Sommer', 'Herbst', 'Winter'};
%
%
% %                                                                             01.07.2013 JL
%
% % Beispiel #1: -----------------------------------------
% Zeit_Matlab = now + rand(7,7) .* 365;
% wie_Jahreszeit = 1; % 1: meteorologische Jahreszeit
% Zusatz_Bezeichnung = '';
% Jahreszeiten = Jahreszeiten(Zeit_Matlab, wie_Jahreszeit, Zusatz_Bezeichnung)
%
% % Beispiel #2: KalenderWoche ----------------------------------------- 
% Zeit_Matlab = datenum('01.01.2013', 'dd.mm.yyyy'):datenum('31.12.2013', 'dd.mm.yyyy');
% wie_Jahreszeit = 5; % 5: Kalenderwoche
% Zusatz_Bezeichnung = '';
% Jahreszeiten = Jahreszeiten(Zeit_Matlab, wie_Jahreszeit, Zusatz_Bezeichnung);
% plot(Zeit_Matlab, Jahreszeiten); datetickzoom('x');

if nargin < 2 || isempty(wie_Jahreszeit), wie_Jahreszeit = 1; end
if nargin < 3 || isempty(Zusatz_Bezeichnung), Zusatz_Bezeichnung = ''; end

[~, Monat, Tag] = datevec(Zeit_Matlab);
Jahreszeiten = ones(size(Zeit_Matlab)) * 4; % Vordimensionieren. Alle werden auf Winter gesetzt.

switch(wie_Jahreszeit),
    %% meteorologische Jahreszeit
    case 1, 
        Jahreszeiten(ismember(Monat, [3,4,5]))      = 1;
        Jahreszeiten(ismember(Monat, [6,7,8]))      = 2;
        Jahreszeiten(ismember(Monat, [9,10,11]))    = 3;
        
        Jahreszeiten_Bezeichnung = {['Frühling',Zusatz_Bezeichnung], ['Sommer',Zusatz_Bezeichnung], ['Herbst',Zusatz_Bezeichnung], ['Winter',Zusatz_Bezeichnung]};
        
    %% kalendarisch Jahreszeit
    case 2,
        % Winter (bereits vordefiniert)
        % Jahreszeiten(Monat == 12 & Tag >= 21)     = 4;
        % Jahreszeiten(ismember(Monat, [1,2]))      = 4;
        % Jahreszeiten(Monat == 3 & Tag <= 20)      = 4;
        
        % Frühling
        Jahreszeiten(Monat == 3 & Tag >= 21)        = 1;
        Jahreszeiten(ismember(Monat, [4,5]))        = 1;
        Jahreszeiten(Monat == 6 & Tag <= 20)        = 1;
        
        % Sommer
        Jahreszeiten(Monat == 6 & Tag >= 21)        = 2;
        Jahreszeiten(ismember(Monat, [7,8]))        = 2;
        Jahreszeiten(Monat == 9 & Tag <= 22)        = 2;
        
        % Herbst
        Jahreszeiten(Monat == 9 & Tag >= 23)        = 3;
        Jahreszeiten(ismember(Monat, [10,11]))      = 3;
        Jahreszeiten(Monat == 12 & Tag <= 20)       = 3;
        
        Jahreszeiten_Bezeichnung = {['Frühling',Zusatz_Bezeichnung], ['Sommer',Zusatz_Bezeichnung], ['Herbst',Zusatz_Bezeichnung], ['Winter',Zusatz_Bezeichnung]};
        
    %% meteorologische Jahreszeit mit 1 Monat Extra Sommer    
    case 3,
        Jahreszeiten(ismember(Monat, [3,4,5]))      = 1;
        Jahreszeiten(ismember(Monat, [6,7,8,9]))    = 2;
        Jahreszeiten(ismember(Monat, [10,11]))      = 3;
        
        Jahreszeiten_Bezeichnung = {['Frühling',Zusatz_Bezeichnung], ['Sommer',Zusatz_Bezeichnung], ['Herbst',Zusatz_Bezeichnung], ['Winter',Zusatz_Bezeichnung]};
        
    %% Monat des Jahres 
    case 4,
        Jahreszeiten = Monat;
        
        Jahreszeiten_Bezeichnung = {['Januar',Zusatz_Bezeichnung'], ['Februar',Zusatz_Bezeichnung'], ['Maerz',Zusatz_Bezeichnung'], ['April',Zusatz_Bezeichnung'], ['Mai',Zusatz_Bezeichnung'], ['Juni',Zusatz_Bezeichnung'], ['Juli',Zusatz_Bezeichnung'], ['August',Zusatz_Bezeichnung'], ['September',Zusatz_Bezeichnung'], ['Oktober',Zusatz_Bezeichnung'], ['November',Zusatz_Bezeichnung'], ['Dezember',Zusatz_Bezeichnung']};
        
    %% Kalenderwoche nach ISO 8601 (https://de.wikipedia.org/wiki/Woche)
    % Das Jahr umfasst mindestens 52 durchnummerierte Kalenderwochen (KW), wobei es bei den Wochen-Nummerierungen verschiedene Variationen gibt. 
    % Je nach angewandter Regel ist die erste Woche des Jahres ISO (DIN/ÖNORM/SN): 
    %   die Woche, die den ersten Donnerstag des Jahres enthält (ISO 8601, früher DIN 1355-1); 
    % äquivalent dazu
    %   die Woche, die den 4. Januar enthält
    %   die erste Woche, in die mindestens vier Tage des neuen Jahres fallen
    case 5,

        [KalenderWoche, KalenderWoche_String] = Kalenderwoche(Zeit_Matlab);
        Jahreszeiten = KalenderWoche;
        Jahreszeiten_Bezeichnung = KalenderWoche_String;
        
end % switch(wie_Jahreszeit),



end % function

function [KalenderWoche, KalenderWoche_String] = Kalenderwoche(Datum)
% Gibt die Kalenderwoche eines Jahres zurück.
%
% Eingang: 
%   - Datum 
%       n x m Matrix im Matlab-Zeit Format
% Rückgabe:
%   - KalenderWoche
%       n x m Matrix (numerisch) mit den Kalenderwochen
%   - KalenderWoche_String
%       n x m cell (charakter) mit den Kalenderwochen (z.B. 'KW 34')
%

% Kalenderwoche nach ISO 8601 (https://de.wikipedia.org/wiki/Woche)
% Das Jahr umfasst mindestens 52 durchnummerierte Kalenderwochen (KW), wobei es bei den Wochen-Nummerierungen verschiedene Variationen gibt.
% Je nach angewandter Regel ist die erste Woche des Jahres ISO (DIN/ÖNORM/SN):
%   die Woche, die den ersten Donnerstag des Jahres enthält (ISO 8601, früher DIN 1355-1);
% äquivalent dazu
%   die Woche, die den 4. Januar enthält
%   die erste Woche, in die mindestens vier Tage des neuen Jahres fallen

% Der Donnerstag der Woche:
Datum = floor(Datum); % floor(Datum) => Der Tag um 0:00 Uhr. Das ist später bei "KalenderWoche = ((Donnerstag_dieser_Woche - erster_Donnerstag_des_Jahres) ./ 7) + 1;" wichtig.
Donnerstag_dieser_Woche = Donnerstag_der_Woche(Datum); 
% Das Jahr in dem das Datum ist:
[Jahr, ~] = datevec(Datum);
% Der erste Donnerstag der Jahre:
Januar4_des_Jahres = datenum(Jahr, ones(size(Jahr)), ones(size(Jahr)).*4); % Immer der 4. Januar des Jahres, das ist die erste Kalenderwoche.
% datestr(Januar4_des_Jahres,'ddd dd.mm.yyyy') % Test
erster_Donnerstag_des_Jahres = Donnerstag_der_Woche(Januar4_des_Jahres);

KalenderWoche = ((Donnerstag_dieser_Woche - erster_Donnerstag_des_Jahres) ./ 7) + 1;

KW_Cell = num2cell(KalenderWoche);
KW_Zusatz = 'KW_';
KW_Cell_Zusatz = cell(size(KW_Cell)); % vordimensionieren
[KW_Cell_Zusatz{:}] = deal(KW_Zusatz);

KalenderWoche_String = cellfun(@(x,y) [x, num2str(y)], KW_Cell_Zusatz, KW_Cell, 'UniformOutput', false);

    function Donnerstag_dieser_Woche = Donnerstag_der_Woche(Datum1)
        % gibt als Datumsobjekt den Donnerstag der Woche
        % zurück, in der das übergebene "Datum" liegt.
        
        Wochentag = weekday(Datum1); % 1: Sun, 2: Mon, ... 6: Fri, 7: Sat
        % Einem Sonntag  (1) muss +4 addiert werden um auf den Donnerstag zu kommen.
        % Einem Montag   (2) muss +3 addiert werden um auf den Donnerstag zu kommen.
        % Einem Dienstag (3) muss +2 addiert werden um auf den Donnerstag zu kommen.
        % ...
        % Einem Freitag  (6) muss -1 addiert werden um auf den Donnerstag zu kommen.
        % Einem Samstag  (7) muss -2 addiert werden um auf den Donnerstag zu kommen.
        if size(Datum1,1) == 1,
            Addition_zu_Donnerstag = [4 3 2 1 0 -1 -2];
        else
            Addition_zu_Donnerstag = [4 3 2 1 0 -1 -2]';
        end
        Donnerstag_dieser_Woche = Datum1 + Addition_zu_Donnerstag(Wochentag);
        
        % Test:
        % [datestr(Datum, 'ddd dd.mm.yyyy >= '), datestr(Donnerstag_dieser_Woche, 'ddd dd.mm.yyyy')]
        
    end

end % function KalenderWoche















