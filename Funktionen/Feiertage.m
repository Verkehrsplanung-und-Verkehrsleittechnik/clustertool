function [idx_Feiertag, Feiertage_Name, idx_einzelne_Feiertage] = Feiertage(Tage, Bundesland, flag_Feiertage_anzeigen, flag_plot, flag_2412_und_3112_auch_Feiertage)
% Gibt eine boolean - Vektor zurück mit true an den Tagen an denen einen Feiertag vorliegt.
%
% Eingänge:
%   - Tage                              n  x 1 Vektor mit Matlab - Zeit.
%   - Bundesland                        1  x 2 char mit dem Namen des Bundeslandes
%                                         BW = Baden-Württemberg 
%                                         BY = Bayern
%                                         BE = Berlin
%                                         BB = Brandenburg	
%                                         HB = Bremen 
%                                         HH = Hamburg
%                                         HE = Hessen
%                                         MV = Mecklenburg-Vorpommern	
%                                         NI = Niedersachsen 
%                                         NW = Nordrhein-Westfalen
%                                         RP = Rheinland-Pfalz
%                                         SL = Saarland	
%                                         SN = Sachsen 
%                                         ST = Sachsen-Anhalt
%                                         SH = Schleswig-Holstein
%                                         TH = Thüringen
%                                       weicht der Sting von "Bundesland" ab, werden alle Gesamtdeutschen Feiertage zurückgegeben.
%   ODER
%   - Bundesland                        17 x 1 boolean Vektor ob die Feiertage verwendet werden sollen.
%                                         Bundesland = [
%                                             true;  % 1)  Neujahr 01.01. | bundesweit
%                                             true;  % 2)  3 Könige 06.01. | BW, BY, ST
%                                             true;  % 3)  Karfreitag (2 Tag vor Ostern) | bundesweit
%                                             true;  % 4)  Ostersonntag | bundesweit
%                                             true;  % 5)  Ostermontag (1 Tag nach Ostern) | bundesweit
%                                             true;  % 6)  Tag der Arbeit 01.05. | bundesweit
%                                             true;  % 7)  Christi Himmelfahrt (39 Tage nach dem Ostersonntag) | bundesweit
%                                             true;  % 8)  Pfingstsonntag (Es wird am 49 Tag nach Ostern begangen) | bundesweit
%                                             true;  % 9)  Pfingstmontag (Es wird am 50 Tag nach Ostern begangen) | bundesweit
%                                             true;  % 10) Fronleichnam (am 60. Tag nach dem Ostersonntag) | BW, BY, HE, NW, RP, SL, SN*, TH* (* kein gesetzlicher Feiertag in diesen BL, nur in manchen Gemeinden)
%                                             false; % 11) Mariä Himmelfahrt 15.08. | BY5, SL
%                                             true;  % 12) Tag der dt. Einheit 03.10. | bundesweit
%                                             false; % 13) Reformationstag 31.10. | BB, MV, SN, ST, TH
%                                             true;  % 14) Allerheiligen 01.11. | BW, BY, NW, RP, SL
%                                             false; % 15) Buß- und Bettag (Regel: am Mittwoch vor dem 23. November) | BY, SN
%                                             true;  % 16) 1. Weihnachtsfeiertag 25.12. | bundesweit
%                                             true;  % 17) 2. Weihnachtsfeiertag 26.12. | bundesweit
%                                             ];
%   - flag_Feiertage_anzeigen           1  x 1 boolean: true: Es wird angezeigt, welche Tage als Feiertage markiert worden sind.
%   - flag_plot                         Plottet die einzelnen Ferien in unterschiedlichen Farben. Anstaatt einem flag (true / false - Wert) kann auch die Axes-handle eingegeben werden.
%   - flag_2412_und_3112_auch_Feiertage wenn "true" werden die Tage 24.12. und 31.12. auch als Feiertage zurückgegeben.
%
% -----------------------------------------------------------------------------------------------------------------------
% Rückgabe:
%   - idx_Feiertag                      n  x 1 boolean Vektor mit true bei einem Feiertag
%   - Feiertage_Name                    n  x 1 Cell mit den Namen der Feiertage (sofern es ein Feiertag ist)
%   - idx_einzelne_Feiertage            Struct mit den Felder der vorkommenden Feiertage (z.B. Neujahr, Pfingstsonntag, ...)
%                                       in jedem Feld (z.B. "Tag der dt. Einheit") gibt ein boolean Vektor an, ob diese Ferien vorliegen.
%
% % Beispiel:
% StartTag = datenum('16.07.2013', 'dd.mm.yyyy');
% EndeTag  = datenum('27.10.2015', 'dd.mm.yyyy');
% Tage = StartTag:EndeTag;
% Bundesland = 'BW';
% flag_Feiertage_anzeigen = true;
% flag_plot = true;
% [idx_Feiertag, Feiertage_Name] = Feiertage(Tage, Bundesland, flag_Feiertage_anzeigen, flag_plot);
%
% ------------------------------------------------------
% % Matix mit allen Feiertagen:
% StartTag = datenum('01.01.2012', 'dd.mm.yyyy');
% EndeTag  = datenum('31.12.2012', 'dd.mm.yyyy');
% Tage = StartTag:EndeTag;
% Bundeslaender = {'BW', 'BY', 'BE', 'BB', 'HB', 'HH', 'HE', 'MV', 'NI', 'NW', 'RP', 'SL', 'SN', 'ST', 'SH', 'TH' };
% idx_Feiertag  = false(length(Tage), length(Bundeslaender)); % vordimensionieren
% Feiertage_Name = cell(length(Tage), length(Bundeslaender));  % vordimensionieren
% flag_Feiertage_anzeigen = false;
% flag_plot = false;
% for cnt_BL = 1 : length(Bundeslaender),
%     [idx_Feiertag(:, cnt_BL), Feiertage_Name(:, cnt_BL)] = Feiertage(Tage, Bundeslaender{cnt_BL}, flag_Feiertage_anzeigen, flag_plot);
% end
if nargin < 1 || isempty(Tage),                     error('Ein Eingang wird benötigt.'),    end
if nargin < 2 || isempty(Bundesland),
    Bundesland = 'BW';
    idx_welche_Feiertage_anwenden = Einstellungen_fuer_Bundesland(Bundesland);
elseif islogical(Bundesland) && all(size(Bundesland) == [17,1]),
    idx_welche_Feiertage_anwenden = Bundesland;
else
    idx_welche_Feiertage_anwenden = Einstellungen_fuer_Bundesland(Bundesland);
end
if nargin < 3 || isempty(flag_Feiertage_anzeigen),              flag_Feiertage_anzeigen = true;             end
if nargin < 4 || isempty(flag_plot),                            flag_plot = true;                           end
if nargin < 5 || isempty(flag_2412_und_3112_auch_Feiertage),    flag_2412_und_3112_auch_Feiertage = false;  end

%% --------- Feiertage ----------------

% Diese Funktion kann nur mit ganzen Tagen rechnen.
Tage = floor(Tage);
% Tage als Zeilenvektor schreiben:
Tage_neu = zeros(numel(Tage), 1); % vordimensionieren
Tage_neu(1:end) = Tage(1:end);
Tage = Tage_neu;

% Namen der Feiertage:
DateVec   = datevec(Tage); % Tage als Vektor
% Wochentag soll immer als Spaltenvektor realisiert werden.
Wochentag = zeros(numel(Tage), 1); % Als Spaltenvektor vordimensionieren
Wochentag(:,1) = weekday(Tage); % Wochentag !!! 1: Sonntag, 2: Montag, ...


idx_Feiertag = false(size(Tage));
Feiertage_Name = cell(size(Tage)); % vordimensionieren

flag_Ostersonntag_berechnen = true;

if flag_Ostersonntag_berechnen,
    Jahre = unique(DateVec(:,1));
    Ostersonntag_mat = easter(Jahre);
else
    % Viele Feiertage sind vom Tag des Ostersonntages abhängig. Der Ostersonntag fällt in den westlichen Kirchen auf den Sonntag nach dem Frühlingsvollmond.
    % Quelle: http://de.wikipedia.org/wiki/Osterdatum
    Ostersonntag = {2000, '23.04.2000';
        2001, '15.04.2001';
        2002, '31.03.2002';
        2003, '20.04.2003';
        2004, '11.04.2004';
        2005, '27.03.2005';
        2006, '16.04.2006';
        2007, '08.04.2007';
        2008, '23.03.2008';
        2009, '12.04.2009';
        2010, '04.04.2010';
        2011, '24.04.2011';
        2012, '08.04.2012';
        2013, '31.03.2013';
        2014, '20.04.2014';
        2015, '05.04.2015';
        2016, '27.03.2016';
        2017, '16.04.2017';
        2018, '01.04.2018';
        2019, '21.04.2019';
        2020, '12.04.2020';
        2021, '04.04.2021';
        2022, '17.04.2022';
        2023, '09.04.2023';
        2024, '31.03.2024';
        2025, '20.04.2025';
        2026, '05.04.2026';
        2027, '28.03.2027';
        2028, '16.04.2028';
        2029, '01.04.2029';
        2030, '21.04.2030';
        };
    Ostersonntag_mat = cellfun(@(x) datenum(x, 'dd.mm.yyyy'), Ostersonntag(:,2));
end

% Neujahr 01.01. | bundesweit
if idx_welche_Feiertage_anwenden(1) == true,
    idx_NeuJahr = DateVec(:,2) ==  1 & DateVec(:,3) ==  1;
    idx_Feiertag(idx_NeuJahr) = true;
    [Feiertage_Name{idx_NeuJahr}] = deal('Neujahr');
end

% 3 Könige 06.01. | BW, BY, ST
if idx_welche_Feiertage_anwenden(2) == true,
    idx_3_Koenige = DateVec(:,2) ==  1 & DateVec(:,3) ==  6;
    idx_Feiertag(idx_3_Koenige) = true;
    [Feiertage_Name{idx_3_Koenige}] = deal('Hl. 3 Könige');
end

% Karfreitag (2 Tag vor Ostern) | bundesweit
if idx_welche_Feiertage_anwenden(3) == true,
    idx_Karfreitag = ismember(Tage, Ostersonntag_mat - 2);
    idx_Feiertag(idx_Karfreitag) = true;
    [Feiertage_Name{idx_Karfreitag}] = deal('Karfreitag');
end

% Ostersonntag | bundesweit
if idx_welche_Feiertage_anwenden(4) == true,
    idx_Ostersonntag = ismember(Tage, Ostersonntag_mat);
    idx_Feiertag(idx_Ostersonntag) = true;
    [Feiertage_Name{idx_Ostersonntag}] = deal('Ostersonntag');
end

% Ostermontag (1 Tag nach Ostern) | bundesweit
if idx_welche_Feiertage_anwenden(5) == true,
    idx_Ostermontag = ismember(Tage, Ostersonntag_mat + 1);
    idx_Feiertag(idx_Ostermontag) = true;
    [Feiertage_Name{idx_Ostermontag}] = deal('Ostermontag');
end

% Tag der Arbeit 01.05. | bundesweit
if idx_welche_Feiertage_anwenden(6) == true,
    idx_Tag_der_Arbeit = DateVec(:,2) ==  5 & DateVec(:,3) ==  1;
    idx_Feiertag(idx_Tag_der_Arbeit) = true;
    [Feiertage_Name{idx_Tag_der_Arbeit}] = deal('Tag der Arbeit');
end

% Christi Himmelfahrt (39 Tage nach dem Ostersonntag) | bundesweit
if idx_welche_Feiertage_anwenden(7) == true,
    idx_Chr_Himmelfahrt = ismember(Tage, Ostersonntag_mat + 39);
    idx_Feiertag(idx_Chr_Himmelfahrt) = true;
    [Feiertage_Name{idx_Chr_Himmelfahrt}] = deal('Christi Himmelfahrt');
end

% Pfingstsonntag (Es wird am 49 Tag nach Ostern begangen) | bundesweit
if idx_welche_Feiertage_anwenden(8) == true,
    idx_Pfingstsonntag = ismember(Tage, Ostersonntag_mat + 49);
    idx_Feiertag(idx_Pfingstsonntag) = true;
    [Feiertage_Name{idx_Pfingstsonntag}] = deal('Pfingstsonntag');
end

% Pfingstmontag (Es wird am fünfzigsten Tag nach Ostern begangen) | bundesweit
if idx_welche_Feiertage_anwenden(9) == true,
    idx_Pfingsmontag = ismember(Tage, Ostersonntag_mat + 50);
    idx_Feiertag(idx_Pfingsmontag) = true;
    [Feiertage_Name{idx_Pfingsmontag}] = deal('Pfingstmontag');
end

% Fronleichnam (am 60. Tag nach dem Ostersonntag) | BW, BY, HE, NW, RP, SL, SN*, TH* (* kein gesetzlicher Feiertag in diesen BL, nur in manchen Gemeinden)
if idx_welche_Feiertage_anwenden(10) == true,
    idx_Fronleichnam = ismember(Tage, Ostersonntag_mat + 60);
    idx_Feiertag(idx_Fronleichnam) = true;
    [Feiertage_Name{idx_Fronleichnam}] = deal('Fronleichnam');
end

% % Mariä Himmelfahrt 15.08. | BY*, SL (nicht in allen, aber den meisten Gemeinden; schulfrei für alle)
if idx_welche_Feiertage_anwenden(11) == true,
    idx_Maria_Himmelfahrt = DateVec(:,2) ==  8 & DateVec(:,3) == 15;
    idx_Feiertag(idx_Maria_Himmelfahrt) = true;
    [Feiertage_Name{idx_Maria_Himmelfahrt}] = deal('Mariä Himmelfahrt');
end

% Tag der dt. Einheit 03.10. | bundesweit
if idx_welche_Feiertage_anwenden(12) == true,
    idx_Tag_der_dt_Einheit = DateVec(:,2) == 10 & DateVec(:,3) ==  3;
    idx_Feiertag(idx_Tag_der_dt_Einheit) = true;
    [Feiertage_Name{idx_Tag_der_dt_Einheit}] = deal('Tag der dt. Einheit');
end

% Reformationstag 31.10. | BB, MV, SN, ST, TH
if idx_welche_Feiertage_anwenden(13) == true,
    idx_Reformationstag = DateVec(:,2) == 10 & DateVec(:,3) == 31;
    idx_Feiertag(idx_Reformationstag) = true;
    [Feiertage_Name{idx_Reformationstag}] = deal('Reformationstag');
end

% Allerheiligen 01.11. | BW, BY, NW, RP, SL
if idx_welche_Feiertage_anwenden(14) == true,
    idx_Allerheiligen = DateVec(:,2) == 11 & DateVec(:,3) ==  1;
    idx_Feiertag(idx_Allerheiligen) = true;
    [Feiertage_Name{idx_Allerheiligen}] = deal('Allerheiligen');
end

% Buß- und Bettag (Regel: am Mittwoch vor dem 23. November) | BY, SN
if idx_welche_Feiertage_anwenden(15) == true,
    idx_Bus_und_Bettag = DateVec(:,2) == 11 & ismember(DateVec(:,3), 16:22) & Wochentag ==  4;
    idx_Feiertag(idx_Bus_und_Bettag) = true;
    [Feiertage_Name{idx_Bus_und_Bettag}] = deal('Buß- und Bettag');
end

% 1. Weihnachtsfeiertag 25.12. | bundesweit
if idx_welche_Feiertage_anwenden(16) == true,
    idx_1_Weihnachtsfeiertag = DateVec(:,2) == 12 & DateVec(:,3) == 25;
    idx_Feiertag(idx_1_Weihnachtsfeiertag) = true;
    [Feiertage_Name{idx_1_Weihnachtsfeiertag}] = deal('1. Weihnachtsfeiertag');
end

% 2. Weihnachtsfeiertag 26.12. | bundesweit
if idx_welche_Feiertage_anwenden(17) == true,
    idx_2_Weihnachtsfeiertag = DateVec(:,2) == 12 & DateVec(:,3) == 26;
    idx_Feiertag(idx_2_Weihnachtsfeiertag) = true;
    [Feiertage_Name{idx_2_Weihnachtsfeiertag}] = deal('2. Weihnachtsfeiertag');
end

if flag_2412_und_3112_auch_Feiertage,
    idx_2412 = DateVec(:,2) == 12 & DateVec(:,3) == 24;
    idx_Feiertag(idx_2412) = true;
    [Feiertage_Name{idx_2412}] = deal('Heiligabend');   
    
    idx_3112 = DateVec(:,2) == 12 & DateVec(:,3) == 31;
    idx_Feiertag(idx_3112) = true;
    [Feiertage_Name{idx_3112}] = deal('Silvester');      
end


% Feiertage anzeigen:
if flag_Feiertage_anzeigen == true,
    disp([cellstr(datestr(Tage, 'ddd dd.mm.yyyy')); Feiertage_Name])
end


if nargout > 2,
    % Namen der einzelnen Feiertage speichern:
    Einzelne_Feiertage = unique(Feiertage_Name(idx_Feiertag));
    if isempty(Einzelne_Feiertage),
        idx_einzelne_Feiertage = struct(); % leere Struct
    else
        for cnt_EF = 1 : length(Einzelne_Feiertage),
            akt_Feiertage = Einzelne_Feiertage{cnt_EF};
            % Felder dürfen nicht mit einer Zahl beginnen. Sie müssen mit Buchstaben beginnen:
            akt_Feiertage = strrep(akt_Feiertage, '1.', 'Erster');
            akt_Feiertage = strrep(akt_Feiertage, '2.', 'Zweiter');
            % Die Felder der Struct dürfen keine Punkte und Leerzeichen enthalten:
            akt_Feiertage = strrep(akt_Feiertage, '.', ''); % Punkte werden entfernt
            akt_Feiertage = strrep(akt_Feiertage, '-', ''); % Bindestriche werden entfernt
            akt_Feiertage = strrep(akt_Feiertage, ' ', '_'); % Leerzeichen werden zu Unterstrichen "_"
            akt_Feiertage = strrep(akt_Feiertage, 'ß', 'ss');
            akt_Feiertage = strrep(akt_Feiertage, 'ä', 'ae');
            akt_Feiertage = strrep(akt_Feiertage, 'ö', 'oe');
            akt_Feiertage = strrep(akt_Feiertage, 'ü', 'ue');
            
            idx_akt_Feiertage = false(size(idx_Feiertag)); % vordimensionieren
            idx_akt_Feiertage(idx_Feiertag) = ismember(Feiertage_Name(idx_Feiertag), Einzelne_Feiertage{cnt_EF});
            idx_einzelne_Feiertage.(akt_Feiertage) = idx_akt_Feiertage;
        end
    end
    % Es kann vorkommen, dass Christi Himmelfahrt am 01.05. stattfindet, dann gibt es 2 Feiertage an einem Tag (z.B. 2008) !!! 
    % Daher kann in diesem Fall der Tag der Arbeit nicht vorkommen:
    if exist('idx_Tag_der_Arbeit', 'var') && any(idx_Tag_der_Arbeit),
        % Es kommt vor. In diesem Fall wurde der Tag der Arbeit überschrieben:
        idx_einzelne_Feiertage.Tag_der_Arbeit = idx_Tag_der_Arbeit;
    end
end

% PLotten der Feiertage:
if ishandle(flag_plot) || flag_plot,
    if ishandle(flag_plot),
        h_axes = flag_plot;
    else
        h_axes = gca;
    end
    plot_Feiertage(Tage, idx_Feiertag, Feiertage_Name, h_axes);
end


end % MAIN function



function idx_welche_Feiertage_anwenden = Einstellungen_fuer_Bundesland(Bundesland)

% BW = Baden-Württemberg
% BY = Bayern
% BE = Berlin
% BB = Brandenburg
% HB = Bremen
% HH = Hamburg
% HE = Hessen
% MV = Mecklenburg-Vorpommern
% NI = Niedersachsen
% NW = Nordrhein-Westfalen
% RP = Rheinland-Pfalz
% SL = Saarland
% SN = Sachsen
% ST = Sachsen-Anhalt
% SH = Schleswig-Holstein
% TH = Thüringen


switch Bundesland
    case 'BW' % BW = Baden-Württemberg
        idx_welche_Feiertage_anwenden = [
            true;  % 1)  Neujahr 01.01. | bundesweit
            true;  % 2)  3 Könige 06.01. | BW, BY, ST
            true;  % 3)  Karfreitag (2 Tag vor Ostern) | bundesweit
            true;  % 4)  Ostersonntag | bundesweit
            true;  % 5)  Ostermontag (1 Tag nach Ostern) | bundesweit
            true;  % 6)  Tag der Arbeit 01.05. | bundesweit
            true;  % 7)  Christi Himmelfahrt (39 Tage nach dem Ostersonntag) | bundesweit
            true;  % 8)  Pfingstsonntag (Es wird am 49 Tag nach Ostern begangen) | bundesweit
            true;  % 9)  Pfingstmontag (Es wird am 50 Tag nach Ostern begangen) | bundesweit
            true;  % 10) Fronleichnam (am 60. Tag nach dem Ostersonntag) | BW, BY, HE, NW, RP, SL, SN*, TH* (* kein gesetzlicher Feiertag in diesen BL, nur in manchen Gemeinden)
            false; % 11) Mariä Himmelfahrt 15.08. | BY5, SL
            true;  % 12) Tag der dt. Einheit 03.10. | bundesweit
            false; % 13) Reformationstag 31.10. | BB, MV, SN, ST, TH
            true;  % 14) Allerheiligen 01.11. | BW, BY, NW, RP, SL
            false; % 15) Buß- und Bettag (Regel: am Mittwoch vor dem 23. November) | BY, SN
            true;  % 16) 1. Weihnachtsfeiertag 25.12. | bundesweit
            true;  % 17) 2. Weihnachtsfeiertag 26.12. | bundesweit
            ];
        
    case 'BY' % BY = Bayern
        idx_welche_Feiertage_anwenden = [
            true;  % 1)  Neujahr 01.01. | bundesweit
            true;  % 2)  3 Könige 06.01. | BW, BY, ST
            true;  % 3)  Karfreitag (2 Tag vor Ostern) | bundesweit
            true;  % 4)  Ostersonntag | bundesweit
            true;  % 5)  Ostermontag (1 Tag nach Ostern) | bundesweit
            true;  % 6)  Tag der Arbeit 01.05. | bundesweit
            true;  % 7)  Christi Himmelfahrt (39 Tage nach dem Ostersonntag) | bundesweit
            true;  % 8)  Pfingstsonntag (Es wird am 49 Tag nach Ostern begangen) | bundesweit
            true;  % 9)  Pfingstmontag (Es wird am 50 Tag nach Ostern begangen) | bundesweit
            true;  % 10) Fronleichnam (am 60. Tag nach dem Ostersonntag) | BW, BY, HE, NW, RP, SL, SN*, TH* (* kein gesetzlicher Feiertag in diesen BL, nur in manchen Gemeinden)
            true;  % 11) Mariä Himmelfahrt 15.08. | BY5, SL
            true;  % 12) Tag der dt. Einheit 03.10. | bundesweit
            false; % 13) Reformationstag 31.10. | BB, MV, SN, ST, TH
            true;  % 14) Allerheiligen 01.11. | BW, BY, NW, RP, SL
            true;  % 15) Buß- und Bettag (Regel: am Mittwoch vor dem 23. November) | BY, SN
            true;  % 16) 1. Weihnachtsfeiertag 25.12. | bundesweit
            true;  % 17) 2. Weihnachtsfeiertag 26.12. | bundesweit
            ];
        
    case 'BE' % BE = Berlin
        idx_welche_Feiertage_anwenden = [
            true;  % 1)  Neujahr 01.01. | bundesweit
            false; % 2)  3 Könige 06.01. | BW, BY, ST
            true;  % 3)  Karfreitag (2 Tag vor Ostern) | bundesweit
            true;  % 4)  Ostersonntag | bundesweit
            true;  % 5)  Ostermontag (1 Tag nach Ostern) | bundesweit
            true;  % 6)  Tag der Arbeit 01.05. | bundesweit
            true;  % 7)  Christi Himmelfahrt (39 Tage nach dem Ostersonntag) | bundesweit
            true;  % 8)  Pfingstsonntag (Es wird am 49 Tag nach Ostern begangen) | bundesweit
            true;  % 9)  Pfingstmontag (Es wird am 50 Tag nach Ostern begangen) | bundesweit
            false; % 10) Fronleichnam (am 60. Tag nach dem Ostersonntag) | BW, BY, HE, NW, RP, SL, SN*, TH* (* kein gesetzlicher Feiertag in diesen BL, nur in manchen Gemeinden)
            false; % 11) Mariä Himmelfahrt 15.08. | BY5, SL
            true;  % 12) Tag der dt. Einheit 03.10. | bundesweit
            false; % 13) Reformationstag 31.10. | BB, MV, SN, ST, TH
            false; % 14) Allerheiligen 01.11. | BW, BY, NW, RP, SL
            false; % 15) Buß- und Bettag (Regel: am Mittwoch vor dem 23. November) | BY, SN
            true;  % 16) 1. Weihnachtsfeiertag 25.12. | bundesweit
            true;  % 17) 2. Weihnachtsfeiertag 26.12. | bundesweit
            ];
        
    case 'BB' % BB = Brandenburg
        idx_welche_Feiertage_anwenden = [
            true;  % 1)  Neujahr 01.01. | bundesweit
            false; % 2)  3 Könige 06.01. | BW, BY, ST
            true;  % 3)  Karfreitag (2 Tag vor Ostern) | bundesweit
            true;  % 4)  Ostersonntag | bundesweit
            true;  % 5)  Ostermontag (1 Tag nach Ostern) | bundesweit
            true;  % 6)  Tag der Arbeit 01.05. | bundesweit
            true;  % 7)  Christi Himmelfahrt (39 Tage nach dem Ostersonntag) | bundesweit
            true;  % 8)  Pfingstsonntag (Es wird am 49 Tag nach Ostern begangen) | bundesweit
            true;  % 9)  Pfingstmontag (Es wird am 50 Tag nach Ostern begangen) | bundesweit
            false; % 10) Fronleichnam (am 60. Tag nach dem Ostersonntag) | BW, BY, HE, NW, RP, SL, SN*, TH* (* kein gesetzlicher Feiertag in diesen BL, nur in manchen Gemeinden)
            false; % 11) Mariä Himmelfahrt 15.08. | BY5, SL
            true;  % 12) Tag der dt. Einheit 03.10. | bundesweit
            true;  % 13) Reformationstag 31.10. | BB, MV, SN, ST, TH
            false; % 14) Allerheiligen 01.11. | BW, BY, NW, RP, SL
            false; % 15) Buß- und Bettag (Regel: am Mittwoch vor dem 23. November) | BY, SN
            true;  % 16) 1. Weihnachtsfeiertag 25.12. | bundesweit
            true;  % 17) 2. Weihnachtsfeiertag 26.12. | bundesweit
            ];
        
    case 'HB' % HB = Bremen
        idx_welche_Feiertage_anwenden = [
            true;  % 1)  Neujahr 01.01. | bundesweit
            false; % 2)  3 Könige 06.01. | BW, BY, ST
            true;  % 3)  Karfreitag (2 Tag vor Ostern) | bundesweit
            true;  % 4)  Ostersonntag | bundesweit
            true;  % 5)  Ostermontag (1 Tag nach Ostern) | bundesweit
            true;  % 6)  Tag der Arbeit 01.05. | bundesweit
            true;  % 7)  Christi Himmelfahrt (39 Tage nach dem Ostersonntag) | bundesweit
            true;  % 8)  Pfingstsonntag (Es wird am 49 Tag nach Ostern begangen) | bundesweit
            true;  % 9)  Pfingstmontag (Es wird am 50 Tag nach Ostern begangen) | bundesweit
            false; % 10) Fronleichnam (am 60. Tag nach dem Ostersonntag) | BW, BY, HE, NW, RP, SL, SN*, TH* (* kein gesetzlicher Feiertag in diesen BL, nur in manchen Gemeinden)
            false; % 11) Mariä Himmelfahrt 15.08. | BY5, SL
            true;  % 12) Tag der dt. Einheit 03.10. | bundesweit
            false; % 13) Reformationstag 31.10. | BB, MV, SN, ST, TH
            false; % 14) Allerheiligen 01.11. | BW, BY, NW, RP, SL
            false; % 15) Buß- und Bettag (Regel: am Mittwoch vor dem 23. November) | BY, SN
            true;  % 16) 1. Weihnachtsfeiertag 25.12. | bundesweit
            true;  % 17) 2. Weihnachtsfeiertag 26.12. | bundesweit
            ];
        
    case 'HH' % HH = Hamburg
        idx_welche_Feiertage_anwenden = [
            true;  % 1)  Neujahr 01.01. | bundesweit
            false; % 2)  3 Könige 06.01. | BW, BY, ST
            true;  % 3)  Karfreitag (2 Tag vor Ostern) | bundesweit
            true;  % 4)  Ostersonntag | bundesweit
            true;  % 5)  Ostermontag (1 Tag nach Ostern) | bundesweit
            true;  % 6)  Tag der Arbeit 01.05. | bundesweit
            true;  % 7)  Christi Himmelfahrt (39 Tage nach dem Ostersonntag) | bundesweit
            true;  % 8)  Pfingstsonntag (Es wird am 49 Tag nach Ostern begangen) | bundesweit
            true;  % 9)  Pfingstmontag (Es wird am 50 Tag nach Ostern begangen) | bundesweit
            false; % 10) Fronleichnam (am 60. Tag nach dem Ostersonntag) | BW, BY, HE, NW, RP, SL, SN*, TH* (* kein gesetzlicher Feiertag in diesen BL, nur in manchen Gemeinden)
            false; % 11) Mariä Himmelfahrt 15.08. | BY5, SL
            true;  % 12) Tag der dt. Einheit 03.10. | bundesweit
            false; % 13) Reformationstag 31.10. | BB, MV, SN, ST, TH
            false; % 14) Allerheiligen 01.11. | BW, BY, NW, RP, SL
            false; % 15) Buß- und Bettag (Regel: am Mittwoch vor dem 23. November) | BY, SN
            true;  % 16) 1. Weihnachtsfeiertag 25.12. | bundesweit
            true;  % 17) 2. Weihnachtsfeiertag 26.12. | bundesweit
            ];
        
    case 'HE' % HE = Hessen
        idx_welche_Feiertage_anwenden = [
            true;  % 1)  Neujahr 01.01. | bundesweit
            false; % 2)  3 Könige 06.01. | BW, BY, ST
            true;  % 3)  Karfreitag (2 Tag vor Ostern) | bundesweit
            true;  % 4)  Ostersonntag | bundesweit
            true;  % 5)  Ostermontag (1 Tag nach Ostern) | bundesweit
            true;  % 6)  Tag der Arbeit 01.05. | bundesweit
            true;  % 7)  Christi Himmelfahrt (39 Tage nach dem Ostersonntag) | bundesweit
            true;  % 8)  Pfingstsonntag (Es wird am 49 Tag nach Ostern begangen) | bundesweit
            true;  % 9)  Pfingstmontag (Es wird am 50 Tag nach Ostern begangen) | bundesweit
            true;  % 10) Fronleichnam (am 60. Tag nach dem Ostersonntag) | BW, BY, HE, NW, RP, SL, SN*, TH* (* kein gesetzlicher Feiertag in diesen BL, nur in manchen Gemeinden)
            false; % 11) Mariä Himmelfahrt 15.08. | BY5, SL
            true;  % 12) Tag der dt. Einheit 03.10. | bundesweit
            false; % 13) Reformationstag 31.10. | BB, MV, SN, ST, TH
            false; % 14) Allerheiligen 01.11. | BW, BY, NW, RP, SL
            false; % 15) Buß- und Bettag (Regel: am Mittwoch vor dem 23. November) | BY, SN
            true;  % 16) 1. Weihnachtsfeiertag 25.12. | bundesweit
            true;  % 17) 2. Weihnachtsfeiertag 26.12. | bundesweit
            ];
        
    case 'MV' % MV = Mecklenburg-Vorpommern
        idx_welche_Feiertage_anwenden = [
            true;  % 1)  Neujahr 01.01. | bundesweit
            false; % 2)  3 Könige 06.01. | BW, BY, ST
            true;  % 3)  Karfreitag (2 Tag vor Ostern) | bundesweit
            true;  % 4)  Ostersonntag | bundesweit
            true;  % 5)  Ostermontag (1 Tag nach Ostern) | bundesweit
            true;  % 6)  Tag der Arbeit 01.05. | bundesweit
            true;  % 7)  Christi Himmelfahrt (39 Tage nach dem Ostersonntag) | bundesweit
            true;  % 8)  Pfingstsonntag (Es wird am 49 Tag nach Ostern begangen) | bundesweit
            true;  % 9)  Pfingstmontag (Es wird am 50 Tag nach Ostern begangen) | bundesweit
            false; % 10) Fronleichnam (am 60. Tag nach dem Ostersonntag) | BW, BY, HE, NW, RP, SL, SN*, TH* (* kein gesetzlicher Feiertag in diesen BL, nur in manchen Gemeinden)
            false; % 11) Mariä Himmelfahrt 15.08. | BY5, SL
            true;  % 12) Tag der dt. Einheit 03.10. | bundesweit
            true;  % 13) Reformationstag 31.10. | BB, MV, SN, ST, TH
            false; % 14) Allerheiligen 01.11. | BW, BY, NW, RP, SL
            false; % 15) Buß- und Bettag (Regel: am Mittwoch vor dem 23. November) | BY, SN
            true;  % 16) 1. Weihnachtsfeiertag 25.12. | bundesweit
            true;  % 17) 2. Weihnachtsfeiertag 26.12. | bundesweit
            ];
        
    case 'NI' % NI = Niedersachsen
        idx_welche_Feiertage_anwenden = [
            true;  % 1)  Neujahr 01.01. | bundesweit
            false; % 2)  3 Könige 06.01. | BW, BY, ST
            true;  % 3)  Karfreitag (2 Tag vor Ostern) | bundesweit
            true;  % 4)  Ostersonntag | bundesweit
            true;  % 5)  Ostermontag (1 Tag nach Ostern) | bundesweit
            true;  % 6)  Tag der Arbeit 01.05. | bundesweit
            true;  % 7)  Christi Himmelfahrt (39 Tage nach dem Ostersonntag) | bundesweit
            true;  % 8)  Pfingstsonntag (Es wird am 49 Tag nach Ostern begangen) | bundesweit
            true;  % 9)  Pfingstmontag (Es wird am 50 Tag nach Ostern begangen) | bundesweit
            false; % 10) Fronleichnam (am 60. Tag nach dem Ostersonntag) | BW, BY, HE, NW, RP, SL, SN*, TH* (* kein gesetzlicher Feiertag in diesen BL, nur in manchen Gemeinden)
            false; % 11) Mariä Himmelfahrt 15.08. | BY5, SL
            true;  % 12) Tag der dt. Einheit 03.10. | bundesweit
            false; % 13) Reformationstag 31.10. | BB, MV, SN, ST, TH
            false; % 14) Allerheiligen 01.11. | BW, BY, NW, RP, SL
            false; % 15) Buß- und Bettag (Regel: am Mittwoch vor dem 23. November) | BY, SN
            true;  % 16) 1. Weihnachtsfeiertag 25.12. | bundesweit
            true;  % 17) 2. Weihnachtsfeiertag 26.12. | bundesweit
            ];
        
    case 'NW' % NW = Nordrhein-Westfalen
        idx_welche_Feiertage_anwenden = [
            true;  % 1)  Neujahr 01.01. | bundesweit
            false; % 2)  3 Könige 06.01. | BW, BY, ST
            true;  % 3)  Karfreitag (2 Tag vor Ostern) | bundesweit
            true;  % 4)  Ostersonntag | bundesweit
            true;  % 5)  Ostermontag (1 Tag nach Ostern) | bundesweit
            true;  % 6)  Tag der Arbeit 01.05. | bundesweit
            true;  % 7)  Christi Himmelfahrt (39 Tage nach dem Ostersonntag) | bundesweit
            true;  % 8)  Pfingstsonntag (Es wird am 49 Tag nach Ostern begangen) | bundesweit
            true;  % 9)  Pfingstmontag (Es wird am 50 Tag nach Ostern begangen) | bundesweit
            true;  % 10) Fronleichnam (am 60. Tag nach dem Ostersonntag) | BW, BY, HE, NW, RP, SL, SN*, TH* (* kein gesetzlicher Feiertag in diesen BL, nur in manchen Gemeinden)
            false; % 11) Mariä Himmelfahrt 15.08. | BY5, SL
            true;  % 12) Tag der dt. Einheit 03.10. | bundesweit
            false; % 13) Reformationstag 31.10. | BB, MV, SN, ST, TH
            false; % 14) Allerheiligen 01.11. | BW, BY, NW, RP, SL
            false; % 15) Buß- und Bettag (Regel: am Mittwoch vor dem 23. November) | BY, SN
            true;  % 16) 1. Weihnachtsfeiertag 25.12. | bundesweit
            true;  % 17) 2. Weihnachtsfeiertag 26.12. | bundesweit
            ];
        
    case 'RP' % RP = Rheinland-Pfalz
        idx_welche_Feiertage_anwenden = [
            true;  % 1)  Neujahr 01.01. | bundesweit
            false; % 2)  3 Könige 06.01. | BW, BY, ST
            true;  % 3)  Karfreitag (2 Tag vor Ostern) | bundesweit
            true;  % 4)  Ostersonntag | bundesweit
            true;  % 5)  Ostermontag (1 Tag nach Ostern) | bundesweit
            true;  % 6)  Tag der Arbeit 01.05. | bundesweit
            true;  % 7)  Christi Himmelfahrt (39 Tage nach dem Ostersonntag) | bundesweit
            true;  % 8)  Pfingstsonntag (Es wird am 49 Tag nach Ostern begangen) | bundesweit
            true;  % 9)  Pfingstmontag (Es wird am 50 Tag nach Ostern begangen) | bundesweit
            true;  % 10) Fronleichnam (am 60. Tag nach dem Ostersonntag) | BW, BY, HE, NW, RP, SL, SN*, TH* (* kein gesetzlicher Feiertag in diesen BL, nur in manchen Gemeinden)
            false; % 11) Mariä Himmelfahrt 15.08. | BY5, SL
            true;  % 12) Tag der dt. Einheit 03.10. | bundesweit
            false; % 13) Reformationstag 31.10. | BB, MV, SN, ST, TH
            true;  % 14) Allerheiligen 01.11. | BW, BY, NW, RP, SL
            false; % 15) Buß- und Bettag (Regel: am Mittwoch vor dem 23. November) | BY, SN
            true;  % 16) 1. Weihnachtsfeiertag 25.12. | bundesweit
            true;  % 17) 2. Weihnachtsfeiertag 26.12. | bundesweit
            ];
        
    case 'SL' % SL = Saarland
        idx_welche_Feiertage_anwenden = [
            true;  % 1)  Neujahr 01.01. | bundesweit
            false; % 2)  3 Könige 06.01. | BW, BY, ST
            true;  % 3)  Karfreitag (2 Tag vor Ostern) | bundesweit
            true;  % 4)  Ostersonntag | bundesweit
            true;  % 5)  Ostermontag (1 Tag nach Ostern) | bundesweit
            true;  % 6)  Tag der Arbeit 01.05. | bundesweit
            true;  % 7)  Christi Himmelfahrt (39 Tage nach dem Ostersonntag) | bundesweit
            true;  % 8)  Pfingstsonntag (Es wird am 49 Tag nach Ostern begangen) | bundesweit
            true;  % 9)  Pfingstmontag (Es wird am 50 Tag nach Ostern begangen) | bundesweit
            true;  % 10) Fronleichnam (am 60. Tag nach dem Ostersonntag) | BW, BY, HE, NW, RP, SL, SN*, TH* (* kein gesetzlicher Feiertag in diesen BL, nur in manchen Gemeinden)
            true;  % 11) Mariä Himmelfahrt 15.08. | BY5, SL
            true;  % 12) Tag der dt. Einheit 03.10. | bundesweit
            false; % 13) Reformationstag 31.10. | BB, MV, SN, ST, TH
            true;  % 14) Allerheiligen 01.11. | BW, BY, NW, RP, SL
            false; % 15) Buß- und Bettag (Regel: am Mittwoch vor dem 23. November) | BY, SN
            true;  % 16) 1. Weihnachtsfeiertag 25.12. | bundesweit
            true;  % 17) 2. Weihnachtsfeiertag 26.12. | bundesweit
            ];
        
    case 'SN' % SN = Sachsen
        idx_welche_Feiertage_anwenden = [
            true;  % 1)  Neujahr 01.01. | bundesweit
            false; % 2)  3 Könige 06.01. | BW, BY, ST
            true;  % 3)  Karfreitag (2 Tag vor Ostern) | bundesweit
            true;  % 4)  Ostersonntag | bundesweit
            true;  % 5)  Ostermontag (1 Tag nach Ostern) | bundesweit
            true;  % 6)  Tag der Arbeit 01.05. | bundesweit
            true;  % 7)  Christi Himmelfahrt (39 Tage nach dem Ostersonntag) | bundesweit
            true;  % 8)  Pfingstsonntag (Es wird am 49 Tag nach Ostern begangen) | bundesweit
            true;  % 9)  Pfingstmontag (Es wird am 50 Tag nach Ostern begangen) | bundesweit
            false; % 10) Fronleichnam (am 60. Tag nach dem Ostersonntag) | BW, BY, HE, NW, RP, SL, SN*, TH* (* kein gesetzlicher Feiertag in diesen BL, nur in manchen Gemeinden)
            false; % 11) Mariä Himmelfahrt 15.08. | BY5, SL
            true;  % 12) Tag der dt. Einheit 03.10. | bundesweit
            true;  % 13) Reformationstag 31.10. | BB, MV, SN, ST, TH
            false; % 14) Allerheiligen 01.11. | BW, BY, NW, RP, SL
            true;  % 15) Buß- und Bettag (Regel: am Mittwoch vor dem 23. November) | BY, SN
            true;  % 16) 1. Weihnachtsfeiertag 25.12. | bundesweit
            true;  % 17) 2. Weihnachtsfeiertag 26.12. | bundesweit
            ];
        
    case 'ST' % ST = Sachsen-Anhalt
        idx_welche_Feiertage_anwenden = [
            true;  % 1)  Neujahr 01.01. | bundesweit
            true;  % 2)  3 Könige 06.01. | BW, BY, ST
            true;  % 3)  Karfreitag (2 Tag vor Ostern) | bundesweit
            true;  % 4)  Ostersonntag | bundesweit
            true;  % 5)  Ostermontag (1 Tag nach Ostern) | bundesweit
            true;  % 6)  Tag der Arbeit 01.05. | bundesweit
            true;  % 7)  Christi Himmelfahrt (39 Tage nach dem Ostersonntag) | bundesweit
            true;  % 8)  Pfingstsonntag (Es wird am 49 Tag nach Ostern begangen) | bundesweit
            true;  % 9)  Pfingstmontag (Es wird am 50 Tag nach Ostern begangen) | bundesweit
            false; % 10) Fronleichnam (am 60. Tag nach dem Ostersonntag) | BW, BY, HE, NW, RP, SL, SN*, TH* (* kein gesetzlicher Feiertag in diesen BL, nur in manchen Gemeinden)
            false; % 11) Mariä Himmelfahrt 15.08. | BY5, SL
            true;  % 12) Tag der dt. Einheit 03.10. | bundesweit
            true;  % 13) Reformationstag 31.10. | BB, MV, SN, ST, TH
            false; % 14) Allerheiligen 01.11. | BW, BY, NW, RP, SL
            false; % 15) Buß- und Bettag (Regel: am Mittwoch vor dem 23. November) | BY, SN
            true;  % 16) 1. Weihnachtsfeiertag 25.12. | bundesweit
            true;  % 17) 2. Weihnachtsfeiertag 26.12. | bundesweit
            ];
        
    case 'SH' % SH = Schleswig-Holstein
        idx_welche_Feiertage_anwenden = [
            true;  % 1)  Neujahr 01.01. | bundesweit
            false; % 2)  3 Könige 06.01. | BW, BY, ST
            true;  % 3)  Karfreitag (2 Tag vor Ostern) | bundesweit
            true;  % 4)  Ostersonntag | bundesweit
            true;  % 5)  Ostermontag (1 Tag nach Ostern) | bundesweit
            true;  % 6)  Tag der Arbeit 01.05. | bundesweit
            true;  % 7)  Christi Himmelfahrt (39 Tage nach dem Ostersonntag) | bundesweit
            true;  % 8)  Pfingstsonntag (Es wird am 49 Tag nach Ostern begangen) | bundesweit
            true;  % 9)  Pfingstmontag (Es wird am 50 Tag nach Ostern begangen) | bundesweit
            false; % 10) Fronleichnam (am 60. Tag nach dem Ostersonntag) | BW, BY, HE, NW, RP, SL, SN*, TH* (* kein gesetzlicher Feiertag in diesen BL, nur in manchen Gemeinden)
            false; % 11) Mariä Himmelfahrt 15.08. | BY5, SL
            true;  % 12) Tag der dt. Einheit 03.10. | bundesweit
            false; % 13) Reformationstag 31.10. | BB, MV, SN, ST, TH
            false; % 14) Allerheiligen 01.11. | BW, BY, NW, RP, SL
            false; % 15) Buß- und Bettag (Regel: am Mittwoch vor dem 23. November) | BY, SN
            true;  % 16) 1. Weihnachtsfeiertag 25.12. | bundesweit
            true;  % 17) 2. Weihnachtsfeiertag 26.12. | bundesweit
            ];
        
    case 'TH' % TH = Thüringen
        idx_welche_Feiertage_anwenden = [
            true;  % 1)  Neujahr 01.01. | bundesweit
            false; % 2)  3 Könige 06.01. | BW, BY, ST
            true;  % 3)  Karfreitag (2 Tag vor Ostern) | bundesweit
            true;  % 4)  Ostersonntag | bundesweit
            true;  % 5)  Ostermontag (1 Tag nach Ostern) | bundesweit
            true;  % 6)  Tag der Arbeit 01.05. | bundesweit
            true;  % 7)  Christi Himmelfahrt (39 Tage nach dem Ostersonntag) | bundesweit
            true;  % 8)  Pfingstsonntag (Es wird am 49 Tag nach Ostern begangen) | bundesweit
            true;  % 9)  Pfingstmontag (Es wird am 50 Tag nach Ostern begangen) | bundesweit
            false; % 10) Fronleichnam (am 60. Tag nach dem Ostersonntag) | BW, BY, HE, NW, RP, SL, SN*, TH* (* kein gesetzlicher Feiertag in diesen BL, nur in manchen Gemeinden)
            false; % 11) Mariä Himmelfahrt 15.08. | BY5, SL
            true;  % 12) Tag der dt. Einheit 03.10. | bundesweit
            true;  % 13) Reformationstag 31.10. | BB, MV, SN, ST, TH
            false; % 14) Allerheiligen 01.11. | BW, BY, NW, RP, SL
            false; % 15) Buß- und Bettag (Regel: am Mittwoch vor dem 23. November) | BY, SN
            true;  % 16) 1. Weihnachtsfeiertag 25.12. | bundesweit
            true;  % 17) 2. Weihnachtsfeiertag 26.12. | bundesweit
            ];
        
    otherwise
        disp('Kein Bundesland eingegeben, es werden nur die Gesamtdeutschen Feiertage berücksichtig.')
        idx_welche_Feiertage_anwenden = [
            true;  % 1)  Neujahr 01.01. | bundesweit
            false; % 2)  3 Könige 06.01. | BW, BY, ST
            true;  % 3)  Karfreitag (2 Tag vor Ostern) | bundesweit
            true;  % 4)  Ostersonntag | bundesweit
            true;  % 5)  Ostermontag (1 Tag nach Ostern) | bundesweit
            true;  % 6)  Tag der Arbeit 01.05. | bundesweit
            true;  % 7)  Christi Himmelfahrt (39 Tage nach dem Ostersonntag) | bundesweit
            true;  % 8)  Pfingstsonntag (Es wird am 49 Tag nach Ostern begangen) | bundesweit
            true;  % 9)  Pfingstmontag (Es wird am 50 Tag nach Ostern begangen) | bundesweit
            false; % 10) Fronleichnam (am 60. Tag nach dem Ostersonntag) | BW, BY, HE, NW, RP, SL, SN*, TH* (* kein gesetzlicher Feiertag in diesen BL, nur in manchen Gemeinden)
            false; % 11) Mariä Himmelfahrt 15.08. | BY5, SL
            true;  % 12) Tag der dt. Einheit 03.10. | bundesweit
            false; % 13) Reformationstag 31.10. | BB, MV, SN, ST, TH
            false; % 14) Allerheiligen 01.11. | BW, BY, NW, RP, SL
            false; % 15) Buß- und Bettag (Regel: am Mittwoch vor dem 23. November) | BY, SN
            true;  % 16) 1. Weihnachtsfeiertag 25.12. | bundesweit
            true;  % 17) 2. Weihnachtsfeiertag 26.12. | bundesweit
            ];
        
        
end % switch Bundesland

end % function



function PQ = easter(year)
% EASTER Easter Day
%	EASTER displays the date of Easter Sunday for present year.
%
%	EASTER(YEAR) displays the date of Easter for specific YEAR, which
%	can be scalar or vector.
%
%	E = EASTER(...) returns Easter day(s) in DATENUM format.
%
%	This function computes Easter Day using the Oudin's algorithm [1940],
%	which is valid for Catholic Easter day from 325 AD (beginning of the Julian
%	calendar). Easter day is usefull to calculate other usual christian feasts:
%	   datestr(easter-47) is Mardi Gras
%	   datestr(easter-46) is Ash Wednesday
%	   datestr(easter-24) is Mi-Carme
%	   datestr(easter-2)  is Good Friday
%	   datestr(easter+1)  is Easter Monday
%	   datestr(easter+39) is Ascension Thursday
%	   datestr(easter+49) is Pentecost
%
%	Reference:
%	   Oudin, 1940. Explanatory Supplement to the Astronomical Almanac,
%	      P. Kenneth Seidelmann, editor.
%	   Tondering, C, 2008. http://www.tondering.dk/claus/calendar.html
%
%	Author: Franois Beauducel, <beauducel@ipgp.fr>
%	Created: 2002-12-26
%	Updated: 2009-03-01

%	Copyright (c) 2002-2009 Franois Beauducel, covered by BSD License.
%	All rights reserved.
%
%	Redistribution and use in source and binary forms, with or without 
%	modification, are permitted provided that the following conditions are 
%	met:
%
%	   * Redistributions of source code must retain the above copyright 
%	     notice, this list of conditions and the following disclaimer.
%	   * Redistributions in binary form must reproduce the above copyright 
%	     notice, this list of conditions and the following disclaimer in 
%	     the documentation and/or other materials provided with the distribution
%	                           
%	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
%	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
%	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
%	ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
%	LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
%	CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
%	SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
%	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
%	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
%	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
%	POSSIBILITY OF SUCH DAMAGE.

julian_start = 325;
gregorian_start = 1583;

if nargin < 1
	year = datevec(now);
end

if ~isnumeric(year)
	error('YEAR argument must be numeric.')
end

% takes integer part of YEAR
year = floor(year);

if any(year < julian_start)
	warning('Some dates are unvalid (before Julian calendar %d AD)',julian_start);
end

G = mod(year,19);	% Golden number - 1

if year >= gregorian_start
	C = floor(year/100);
	C_4 = floor(C/4);
	H = mod(19*G + C - C_4 - floor((8*C + 13)/25) + 15,30);
	K = floor(H/28);
	I = (K.*floor(29./(H + 1)).*floor((21 - G)/11) - 1).*K + H;	% days between the full Moon and March 21
	J = mod(floor(year/4) + year + I + 2 + C_4 - C,7);
else
	I = mod(19*G + 15, 30);
	J = mod(year + floor(year/4) + I,7);
end
P = datenum(year,3,28 + I - J);		% Easter Sunday

if nargout
	PQ = P;
else
	display(datestr(P))
end

end % function easter

function plot_Feiertage(Tage, idx_Feiertag, Feiertage_Name, h_axes)

    % Nur die Tage mit einem Feiertag:
    Tage = Tage(idx_Feiertag);
    Feiertage_Name = Feiertage_Name(idx_Feiertag);
    
    % Ferien, die nicht einem Namen zugeordnet werden können:
    idx_Feiertag_kein_Name = ~cellfun(@any, Feiertage_Name);
    [Feiertage_Name{idx_Feiertag_kein_Name}] = deal('unb. Feiertag');

    % Einzelne Feiertage:
    [einz_Feiertage, ~, idx_Feiertag2] = unique(Feiertage_Name);

    XVektor = [Tage, Tage + 1];
    YVektor = []; % keine Angabe
    idx_Farbe = idx_Feiertag2;
    Farben = [];
    Bezeichnung = einz_Feiertage;
    FaceAlpha = [];
    Flaechen_einfaerben(XVektor, YVektor, idx_Farbe, Farben, Bezeichnung, FaceAlpha, h_axes);
    
    text_xlabel_str = 'Zeit';
    text_ylabel_str = [];
    text_title_str  = [];
    flag_x_datetick = true;
    datetick_format = []; 
    font_size       = []; 
    handle_axes     = [];
    flag_keeplimits = [];    
    Lohmiller_Standard_plot_Format( text_xlabel_str, text_ylabel_str, text_title_str , flag_x_datetick, datetick_format, font_size, handle_axes, flag_keeplimits);

end % function plot_Schulferien

















