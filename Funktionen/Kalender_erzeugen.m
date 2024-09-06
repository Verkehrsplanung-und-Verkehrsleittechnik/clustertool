function Kalender = Kalender_erzeugen( Tage, Land, flag_gespeicherter_Kalender, flag_2412_und_3112_auch_Feiertage )
% Gibt einen Kalender zurück
% Tage im Matlab - Zeit als Spaltenvektor n x 1

flag_Ferien_einzeln     = true; % Ferien werden getrennt nach "Winterferien", "Osterferien", "Pfingstferien", usw.
flag_Feiertage_einzeln  = true; % Feiertage werden getrennt nach den einzelnen Feiertagen "Neujahr", "3 Könige", usw. 

if nargin < 1 || isempty(Tage) %todo falls keine Tage übergeben werden -> leerer Kalender
    StartTag = datenum('01.01.2008', 'dd.mm.yyyy');
    EndeTag  = datenum('31.12.2013', 'dd.mm.yyyy');
    Tage = (StartTag:EndeTag)'; % als Spaltenvektor
end
if nargin < 2 || isempty(Land), Land = 'BY'; end
if nargin < 3 || isempty(flag_gespeicherter_Kalender), flag_gespeicherter_Kalender = true; end
if nargin < 4 || exist('flag_2412_und_3112_auch_Feiertage','var')==0, flag_2412_und_3112_auch_Feiertage = false; end

Kalender.Datum = Tage;
flag_plot = false;

%% Schulferien:
force_reload = false;
flag_Woe_auch_Ferien = true;

[idx_Ferien, Ferien_Name, idx_einzelne_Ferien] = Schulferien(Tage, Land, force_reload, flag_Woe_auch_Ferien, flag_plot);
idx_member = true(size(idx_Ferien)); % Hier müssen keine Zeiten ausgefiltert werden.

Kalender.Ferien.Ferien = idx_Ferien(idx_member);
Kalender.Ferien.Ferien_Name = Ferien_Name(idx_member);

if flag_Ferien_einzeln
    Felder_Ferien = fieldnames(idx_einzelne_Ferien);
    for cnt_FF = 1 : length(Felder_Ferien)
        akt_Feld = Felder_Ferien{cnt_FF};
        Kalender.Ferien.(akt_Feld) = idx_einzelne_Ferien.(akt_Feld)(idx_member);
    end
end


%% Feiertage:
flag_Feiertage_anzeigen = false;

[idx_Feiertag, Feiertage_Name, idx_einzelne_Feiertage] = Feiertage(Tage, Land, flag_Feiertage_anzeigen, flag_plot, flag_2412_und_3112_auch_Feiertage);

Kalender.Feiertage.Feiertag       = idx_Feiertag;
Kalender.Feiertage.Feiertage_Name = Feiertage_Name;

if flag_Feiertage_einzeln
    Felder_Feiertage = fieldnames(idx_einzelne_Feiertage);
    for cnt_FF = 1 : length(Felder_Feiertage)
        akt_Feld = Felder_Feiertage{cnt_FF};
        Kalender.Feiertage.(akt_Feld) = idx_einzelne_Feiertage.(akt_Feld);
    end
end

% Ausnahme Reformationstag 2017
idx_Ref17 = (Tage == 736999);
if nnz(idx_Ref17) > 0 % Tag innerhalb dem Zeitraum
    Kalender.Feiertage.Feiertag(idx_Ref17) = 1;
    Kalender.Feiertage.Feiertage_Name(idx_Ref17) = {'Reformationstag'};
end

%% Wochentag:
Wochentag = weekday(Kalender.Datum);
Wochentage = {'Sonntag', 'Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag'};
for cnt = 1 : 7
    Kalender.Wochentag.(Wochentage{cnt}) = Wochentag == cnt;
end

% Werktage sind Mo,Di, ... Fr und KEIN Feiertag
idx_Werktag = ismember(Wochentag, 2:6) & ~Kalender.Feiertage.Feiertag; % 1: Sonntag, 7: Samstag

%% Brueckentag
% d.h. Vorgänger ist kein Werktag, der Tag selbst ist ein Werktag und der Nachfolger ist kein Werktag
% (der erste/letzte Tag im Kalender ist kein Brückentag)
if length(Wochentag) == 1
    Kalender.Sonstige_Tage.Brueckentag = false;
elseif length(Wochentag) == 2
    Kalender.Sonstige_Tage.Brueckentag = [false; false];
else
    Kalender.Sonstige_Tage.Brueckentag = [false; ~idx_Werktag(1:end-2) & idx_Werktag(2:end-1) & ~idx_Werktag(3:end); false];
end

%% WerktagVorFeiertag
% d.h. Nachfolger ist ein Feiertag und der Tag selbst ein Werktag (der kein Feiertag sein kann und automatisch Mo-Fr ist)
% (der letzte Tag im Kalender ist kein WerktagVorFeiertag)
if length(Wochentag) == 1
    Kalender.Sonstige_Tage.WerktagVorFeiertag = false;
else
    Kalender.Sonstige_Tage.WerktagVorFeiertag = [Kalender.Feiertage.Feiertag(2:end) & idx_Werktag(1:end-1); false];
end


%% Ferienbeginn (letzter Tag vor den Ferien + erste beiden Ferientage)
Kalender.Ferien.erster_Ferientag = [false; diff(Kalender.Ferien.Ferien) == 1];
Kalender.Ferien.letzer_Tage_vor_Ferien = [Kalender.Ferien.erster_Ferientag(2:end); false]; % Ein Tag früher
idx_zweiter_Ferientag = [false; Kalender.Ferien.erster_Ferientag(1:end - 1)]; % Ein Tag später
Kalender.Ferien.Ferienbeginn = Kalender.Ferien.erster_Ferientag | Kalender.Ferien.letzer_Tage_vor_Ferien | idx_zweiter_Ferientag;

%% Untersuchung Ferienende
Kalender.Ferien.letzter_Ferientag = [diff(Kalender.Ferien.Ferien) == -1; false];

%% Jahreszeiten:
% 1: meteorologische Jahreszeit      
% 2: kalendarisch Jahreszeit
% 3: meteorologische Jahreszeit mit 1 Monat Extra Sommer (für Bundesland BW, da hier im September noch Sommerferien sind:)
% 4: Jeder Monat für sich (keine eigentlichen Jahrezeiten)
% 5: Kalenderwoche
wie_Jahreszeit = 1; 
Feld_Jahreszeit = 'Jahreszeit';
Zusatz_Bezeichnung = '';
[Jahreszeiten_num, Jahreszeiten_Bezeichnung] = Jahreszeiten( Tage, wie_Jahreszeit, Zusatz_Bezeichnung );

for cnt_JZ = 1 : length(Jahreszeiten_Bezeichnung)
    akt_Jahreszeit = Jahreszeiten_Bezeichnung{cnt_JZ};
    akt_Jahreszeit = strrep(akt_Jahreszeit, 'ü', 'ue');

    Kalender.(Feld_Jahreszeit).(akt_Jahreszeit) = Jahreszeiten_num == cnt_JZ;
end

%% Jahreszeit kalendarisch:
wie_Jahreszeit = 2; 
Feld_Jahreszeit = 'Jahreszeit_kalendarisch';
Zusatz_Bezeichnung = '_kalendarisch';
[Jahreszeiten_num, Jahreszeiten_Bezeichnung] = Jahreszeiten( Tage, wie_Jahreszeit, Zusatz_Bezeichnung );

for cnt_JZ = 1 : length(Jahreszeiten_Bezeichnung)
    akt_Jahreszeit = Jahreszeiten_Bezeichnung{cnt_JZ};
    akt_Jahreszeit = strrep(akt_Jahreszeit, 'ü', 'ue');

    Kalender.(Feld_Jahreszeit).(akt_Jahreszeit) = Jahreszeiten_num == cnt_JZ;
end

%% Jahreszeit kalendarisch:
wie_Jahreszeit = 3; 
Feld_Jahreszeit = 'Jahreszeit_extra';
Zusatz_Bezeichnung = '_extra';
[Jahreszeiten_num, Jahreszeiten_Bezeichnung] = Jahreszeiten( Tage, wie_Jahreszeit, Zusatz_Bezeichnung );

for cnt_JZ = 1 : length(Jahreszeiten_Bezeichnung)
    akt_Jahreszeit = Jahreszeiten_Bezeichnung{cnt_JZ};
    akt_Jahreszeit = strrep(akt_Jahreszeit, 'ü', 'ue');

    Kalender.(Feld_Jahreszeit).(akt_Jahreszeit) = Jahreszeiten_num == cnt_JZ;
end
    
% Alle Felder als Spaltenvektoren:
flag_als_Zeilenvektor = false;
Kalender = Struct_Felder_als_Spaltenvektoren(Kalender, flag_als_Zeilenvektor);
end % function

%% Schulferien
function [idx_Ferien, Ferien_Name, idx_einzelne_Ferien] = Schulferien(Tage, Bundesland, force_reload, flag_Woe_auch_Ferien, flag_plot)
% Gibt eine boolean - Vektor zurück mit true an den Tagen an denen einen Ferientag vorliegt.
% Quelle sind die Daten auf http://www.schulferien.org.
%
% Eingänge:
%   - Tage                              n  x 1 Vektor mit Matlab - Zeit (ganze Tage; zur Not: Tage = floor(Tage);)
%   - Bundesland                        1  x 2 char mit dem Namen des Bundeslandes
%   - flag_Feiertage_anzeigen           1  x 1 boolean: true: Es wird angezeigt, welche Tage als Ferientage markiert worden sind.
%   - flag_alle_Ferien_speichern        Ruft alle Ferien 1991 bis 2014 für alle Bundesländer ab und speichert sie in einer *.mat Datei
%   - force_reload                      Die Daten werden von "http://www.schulferien.org" neu abgefragt (und keine bereits gespeicherten Daten verwendet).
%                                       Für "force_reload" kann auch direkt die Struct "Schulferien_saved" eingegeben werden. Gerade bei häufiger Nutzung der Funktion
%                                       wird die Rechenzeit leicht beschleunigt. Das Laden von "Schulferien_saved" dauert ca. 0.002 Sekunden.
%   - flag_Woe_auch_Ferien              Die Wochenenden von % nach den Ferien werden jeweils auch zum Ferienzeitraum hinzugefügt.
%                                           Das schließt auch Feiertage wie Karfreitag oder Pfingstmontag mit ein. D.h. wenn der Oster-Ferienbeginn am Dienstag nach Ostern ist,
%                                           beginnen die Osterferien bereits am Karfreitag.
%   - flag_plot                         Plottet die einzelnen Ferien in unterschiedlichen Farben. Anstaatt einem flag (true / false - Wert) kann auch die Axes-handle eingegeben werden.
%
% Rückgabe:
%   - idx_Ferien                        n  x 1 boolean Vektor mit true bei einem Ferientag
%   - Ferien_Name                       n  x 1 Cell mit den Namen der Ferien (sofern Ferien sind)
%   - idx_einzelne_Ferien               Struct mit den Felder der vorkommenden Ferien (z.B. Herbstferien, Osterferien, ...)
%                                       in jedem Feld (z.B. "Pfingstferien") gibt ein boolean Vektor an, ob diese Ferien vorliegen.
%

if nargin < 1 || isempty(Tage),                         error('Ein Eingang wird benötigt.'),    end
if nargin < 2 || isempty(Bundesland),                   Bundesland = 'BW';                      end
if nargin < 3 || isempty(force_reload),                 force_reload = false;                   end
if nargin < 4 || isempty(flag_Woe_auch_Ferien),         flag_Woe_auch_Ferien = false;           end
if nargin < 5 || isempty(flag_plot),                    flag_plot = true;                       end

% Diese Funktion kann nur mit ganzen Tagen rechnen.
Tage = floor(Tage);
% Tage als Spaltenvektor schreiben:
Tage_neu = zeros(numel(Tage), 1); % vordimensionieren
Tage_neu(1:end) = Tage(1:end);
Tage = Tage_neu;

% Die Daten wurden für die Jahre von 1991 - 2019 lokal gespeichert (siehe Unterfunktion "ALLE_Ferien_Speichen")
% todo Werte manuell anpassen bei Update des lokalen Kalenders
% 727199 => 01.01.1991    737425 => 31.12.2018
if (~force_reload) && min(Tage) >= 727199 && max(Tage) <= 737425 % Prüfen ob gespeicherte Daten verwendet werden können
    Laender_gespeichert = {'BW', 'BY', 'BE', 'BB', 'HB', 'HH', 'HE', 'MV', 'NI', 'NW', 'RP', 'SL', 'SN', 'ST', 'SH', 'TH' }; %Liste dt Budnesländer
    if ~ismember(Bundesland, Laender_gespeichert)
        % Das Land existiert nicht:
        % Leere Rückgabe:
        %   - idx_Ferien                        n  x 1 boolean Vektor mit true bei einem Ferientag
        %   - Ferien_Name                       n  x 1 Cell mit den Namen der Ferien (sofern Ferien sind)
        %   - idx_einzelne_Ferien               Struct mit den Felder der vorkommenden Ferien (z.B. Herbstferien, Osterferien, ...)
        %                                       in jedem Feld (z.B. "Pfingstferien") gibt ein boolean Vektor an, ob diese Ferien vorliegen.
        idx_Ferien = false(size(Tage)); % Es gibt keine Ferien.
        Ferien_Name = cell(size(Tage));
        idx_einzelne_Ferien = struct(); % leere Struct
        warning(['Für das Land:',32,Bundesland,32,'gibt es keine Ferieninformationen für den eingegebenen Zeitraum.'])
        return
    else
        % Das Land existiert:
        Ferien = load('Schulferien_saved', 'Datum', 'FerienName', Bundesland);
    end
    


    Tage_Alle = Ferien.Datum;
    idx_Ferien_Alle = Ferien.(Bundesland) ~= 0;
    Ferien_Name_Alle = cell(size(Tage));
    Ferien_Name_Alle(idx_Ferien_Alle) = Ferien.FerienName(Ferien.(Bundesland)(idx_Ferien_Alle));
    if flag_Woe_auch_Ferien
        [idx_Ferien_Alle, Ferien_Name_Alle] = Woe_auch_Ferien(Tage_Alle, idx_Ferien_Alle, Ferien_Name_Alle, Bundesland);
    end

    % Zeile zu jedem Tag:
    idx_Tag = ismember(Ferien.Datum, Tage);

    idx_Ferien = idx_Ferien_Alle(idx_Tag);
    Ferien_Name = Ferien_Name_Alle(idx_Tag);    
else 
    % Abfrage der Ferien von Schulferien.org
    
    % Bestimmen der Jahre von denen die Ferien ausgelesen werden müssen:
    [Year, ~] = datevec(Tage);
    einzelne_Jahre = unique(Year);
    
    % Das naechste Jahre wird auch immer noch ausgelesen, da die Weihnachtsferien (welche ins neue Jahre hineinreichen) dort gelistet sind
    einzelne_Jahre = [einzelne_Jahre; max(einzelne_Jahre) + 1];
    
    alle_FerienTage = cell(length(einzelne_Jahre), 1); % vordimensionieren
    alle_FerienTage_Name = cell(length(einzelne_Jahre), 1); % vordimensionieren
    for cnt_J = 1 : length(einzelne_Jahre)
        akt_Jahr = einzelne_Jahre(cnt_J);
        [alle_FerienTage{cnt_J}, alle_FerienTage_Name{cnt_J}] = Abfrage_Ferien_eines_Jahres(akt_Jahr, Bundesland);
    end
    
    % Alle Jahre zusammenfassen:
    alle_FerienTage_Vektor = vertcat(alle_FerienTage{:});
    alle_FerienTage_Name_Vektor = vertcat(alle_FerienTage_Name{:});
    
    [idx_Ferien, zeile_Ferien] = ismember(Tage, alle_FerienTage_Vektor);
    Ferien_Name = cell(size(Tage)); % vordimensionieren
    Ferien_Name(zeile_Ferien ~= 0) = alle_FerienTage_Name_Vektor(zeile_Ferien(zeile_Ferien ~= 0));
    
end 

if nargout > 2
    % Namen der einzelnen Ferien speichern:
    Einzelne_Ferien = unique(Ferien_Name(idx_Ferien));
    if isempty(Einzelne_Ferien)
        idx_einzelne_Ferien = struct(); % leere Struct
    else
        for cnt_EF = 1 : length(Einzelne_Ferien)
            akt_Ferien = Einzelne_Ferien{cnt_EF};
            idx_akt_Ferien = false(size(idx_Ferien)); % vordimensionieren
            idx_akt_Ferien(idx_Ferien) = ismember(Ferien_Name(idx_Ferien), akt_Ferien);
            idx_einzelne_Ferien.(akt_Ferien) = idx_akt_Ferien;
        end
    end
end

 % PLotten der Ferien:
if ishandle(flag_plot) || flag_plot
    if ishandle(flag_plot)
        h_axes = flag_plot;
    else
        h_axes = gca;
    end
    plot_Schulferien(Tage, idx_Ferien, Ferien_Name, h_axes);
end
end % MAIN function

function [FerienTage, FerienTage_Name] = Abfrage_Ferien_eines_Jahres(Jahr, Bundesland)
% Die Funktion laedt die Ferien von dem gewaehlten und dem naechsten Jahr,
% ersetzt dann die Weihnachtsferien des momentanen Jahres, die an erster
% Stelle der Ferientabelle stehen und fuegt die Weihnachtsferien des naechsten Jahres ans
% Ende hinzu.
% Der Grund dafuer ist, dass der alte Code die Ferien von Schulferien.org
% geladen hat. Die Seite ist so aufgebaut, dass die Weihnachtsferien angezeigt werden,
% die am Ende des Jahres anstehen und ins naechste Jahr uebergehen.
% Bei der neuen Seite werden die Weihnachtsferien, die letztes Jahr
% begannen und ins diese Jahr uebergehen angezeigt.
% Rückgabe:
%   * FerienTage:
%   * FerienTage_Name:

Jahr_str = num2str(Jahr);

MyDisp('Webabfrage der Ferien ... ')

% Webabfrage
options=weboptions;
options.Timeout=5000; % in Sekunden
options.ContentType = 'text';
HTML_Text = webread(['http://schulferien.kfz-auskunft.de/schulferien_',Jahr_str,'.html'], options);

% Parsen der Ferien
HTML_Text_Cell = split(HTML_Text,'<tr ');
Bundesland_HTML = Bundesland_wie_in_der_URL(Bundesland);

% Identifiziere Tabelle in html String
% Merkmal Zeile in Tabelle: 'valign="top">'
idx_is_Tabellenzeile = strfind(HTML_Text_Cell,'valign="top">'); % out: cell vector
idx_is_Tabellenzeile(cellfun('isempty', idx_is_Tabellenzeile)) = {0}; % [] -> 0
idx_is_Tabellenzeile = cell2mat(idx_is_Tabellenzeile);
HTML_Text_Cell = HTML_Text_Cell(idx_is_Tabellenzeile == 1);

Zeile_Bundesland = find(contains(HTML_Text_Cell, Bundesland_HTML)); 
if ~isempty(Zeile_Bundesland)
    % Reihenfolge der Ferien:
    Ferienreihenfolge = {'Weihnachten'; 'Winterferien'; 'Osterferien'; 'Pfingstferien'; 'Sommerferien'; 'Herbstferien'};

    Trennzeichen = {'<td align="center">'};
    
    % Init string array
    Ferien_Bundesland = strings(length(Zeile_Bundesland),1);
    for k=1:length(Zeile_Bundesland)
        zeile_bundesland_text = HTML_Text_Cell{Zeile_Bundesland(k)};
        
        % Aufbereiten des html textes
        zeile_bundesland_text = strip(zeile_bundesland_text);
        zeile_bundesland_text = strrep(zeile_bundesland_text, newline, '');

        % Wenn die Zeile zu Ende ist kann abgebrochen werden:
        % Loescht alles was hinter '</tr>' kommt
        idx_Zeilenende = strfind(zeile_bundesland_text, '</tr>');

        if any(idx_Zeilenende)
            zeile_bundesland_text(idx_Zeilenende:end) = [];
        end
          
        Ferien_Bundesland(k) = zeile_bundesland_text;
        
    end

    Einzelne_Ferien = arrayfun(@(x) strsplit(x, Trennzeichen),Ferien_Bundesland,'UniformOutput',false);
    
    % Formatierung: ein Spaltenarray
    Einzelne_Ferien = cat(2, Einzelne_Ferien{:});

    % lösche falsche Umbrüche/Formatierungen
    % Fall 1: s. BW 2021 -> zeilenumbruch in Spalte
    Einzelne_Ferien =  arrayfun(@(x) erase(x, "<br />"), Einzelne_Ferien);
    Einzelne_Ferien =  arrayfun(@(x) strip(x), Einzelne_Ferien);
    Einzelne_Ferien =  arrayfun(@(x) strrep(x, '</td>', ''), Einzelne_Ferien);
    Einzelne_Ferien =  arrayfun(@(x) strrep(x, ' ', ''), Einzelne_Ferien);
    Einzelne_Ferien =  arrayfun(@(x) strtrim(x), Einzelne_Ferien);

    % Lösche Einträge ohne Ferien (enthalten Bundesland)
    Einzelne_Ferien = Einzelne_Ferien(~contains(Einzelne_Ferien,Bundesland_HTML));
    
    % Test: Anzahl Einträge == ANzahl Ferien?
    if length(Einzelne_Ferien) ~= length(Ferienreihenfolge)
        warndlg('Schulferienabfrage: \n Anzahl identifizierter Zeilen entspricht nicht der Anzahl an Ferien')
    end
    
    % Umwandlung in Cellarray um Indizierung via {Ferienindex}(Stringindex)
    % zu ermöglichen (historisch bedingt)
    Einzelne_Ferien = cellstr(Einzelne_Ferien);
    
    % 1. Spalte: von Tag
    % 2. Spalte: bis Tag
    % 3. Spalte: zusätzlicher und/oder einzelner Tag
    % Verschiedene Fälle über die Länge der Strings:
            % 1. Standard: dd.mm.-dd.mm. ========================== CASE 13
            % 2. Zwei Tage: dd.mm+dd.mm. ========================== CASE 13
            % 3. Ein Tag: dd.mm. ================================== CASE  6
            % 4. Standard plus extra Tag: dd.mm.-dd.mm./dd.mm. ==== CASE 20
            % 5. Extra Tag plus Standard: dd.mm.+dd.mm.-dd.mm. ==== CASE 20
            % 6. Drei einzelne Tage: dd.mm.+dd.mm.+dd.mm. ========= CASE 20
            % ADD: 7. Fehler im Standardformat (Bindestrich fehlt)= CASE 12
            % ADD: 8. Fehler? im Standardformat (Jahr 2021, Osterferien BW),
            % Wochenende exkludiert mit Zeilenumbruch============== CASE 26
            
    FerienZeitraum_Str = cell(length(Einzelne_Ferien), 4); % vordimensionieren

    for cnt_F = 1 : length(Einzelne_Ferien)
        
        % Falls Anmerkungen vorkommen, diese rauslöschen:
        if any(strfind(Einzelne_Ferien{cnt_F},'<SUP>'))
            idx_Beginn = strfind(Einzelne_Ferien{cnt_F},'<SUP>');
            idx_Ende   = strfind(Einzelne_Ferien{cnt_F},'</SUP>') + 5;
            Einzelne_Ferien{cnt_F}(idx_Beginn:idx_Ende) = [];
        end

        Einzelne_Ferien{cnt_F} = strtrim(Einzelne_Ferien{cnt_F});

        if length(Einzelne_Ferien{cnt_F}) < 6 || Einzelne_Ferien{cnt_F}(1) == '-' % length 6 wegen xx.xx.
            % Diese Ferien gibt es in dem Bundesland nicht.
        else
           
            switch length(Einzelne_Ferien{cnt_F})
                case 13 % 1. und 2.
                    % 1. Standard: dd.mm.-dd.mm.
                    if Einzelne_Ferien{cnt_F}(7) == '-'
                        FerienZeitraum_Str{cnt_F, 1} = Einzelne_Ferien{cnt_F}( 1 : 6);
                        FerienZeitraum_Str{cnt_F, 2} = Einzelne_Ferien{cnt_F}( 8 :13);
                    % 2. Zwei Tage: dd.mm.+dd.mm.
                    elseif Einzelne_Ferien{cnt_F}(7) == '+'
                        FerienZeitraum_Str{cnt_F, 1} = Einzelne_Ferien{cnt_F}( 1 : 6); % gleiche Zeit bei Spalte 1 & 2
                        FerienZeitraum_Str{cnt_F, 2} = Einzelne_Ferien{cnt_F}( 1 : 6); % gleiche Zeit bei Spalte 1 & 2
                        FerienZeitraum_Str{cnt_F, 3} = Einzelne_Ferien{cnt_F}( 8 : 13); % die zusätzliche Zeit in Spalte 3
                    end

                case  6 % 3. Ein Tag: dd.mm.
                    FerienZeitraum_Str{cnt_F, 3} = Einzelne_Ferien{cnt_F}( 1 : 6);

                case 20 % 4. und 5. und 6.
                    % 4. Standard plus extra Tag: dd.mm.-dd.mm.,dd.mm.
                    if (Einzelne_Ferien{1}{cnt_F}(7) == '-' && Einzelne_Ferien{cnt_F}(14) == ',') || ...
                        (Einzelne_Ferien{cnt_F}(7) == '-' && Einzelne_Ferien{cnt_F}(14) == '+')
                        FerienZeitraum_Str{cnt_F, 1} = Einzelne_Ferien{cnt_F}( 1 : 6); % gleiche Zeit bei Spalte 1 & 2
                        FerienZeitraum_Str{cnt_F, 2} = Einzelne_Ferien{cnt_F}( 8 :13); % gleiche Zeit bei Spalte 1 & 2
                        FerienZeitraum_Str{cnt_F, 3} = Einzelne_Ferien{cnt_F}(15 :20); % die zusätzliche Zeit in Spalte 3
                    % 5. Extra Tag plus Standard: dd.mm.,dd.mm.-dd.mm.
                    elseif (Einzelne_Ferien{cnt_F}(7) == ',' && Einzelne_Ferien{cnt_F}(14) == '-') || ...
                            ((Einzelne_Ferien{cnt_F}(7) == '+' && Einzelne_Ferien{cnt_F}(14) == '-'))
                        FerienZeitraum_Str{cnt_F, 1} = Einzelne_Ferien{cnt_F}( 1 :6); % gleiche Zeit bei Spalte 1 & 2
                        FerienZeitraum_Str{cnt_F, 2} = Einzelne_Ferien{cnt_F}(end-5 :end); % gleiche Zeit bei Spalte 1 & 2
                       % FerienZeitraum_Str{cnt_F, 3} = Einzelne_Ferien{1}{cnt_F}( 1 : 6); % die zusätzliche Zeit in Spalte 3
                    end
                    % 6. Einzelne Tage: dd.mm.+dd.mm.+dd.mm.
                    if Einzelne_Ferien{cnt_F}(7) == '+' && Einzelne_Ferien{cnt_F}(14) == '+'
                        FerienZeitraum_Str{cnt_F, 1} = Einzelne_Ferien{cnt_F}( 1: 6); % gleiche Zeit bei Spalte 1 & 2
                        FerienZeitraum_Str{cnt_F, 2} = Einzelne_Ferien{cnt_F}( 1: 6); % gleiche Zeit bei Spalte 1 & 2
                        FerienZeitraum_Str{cnt_F, 3} = Einzelne_Ferien{cnt_F}( 8:13); % die zusätzliche Zeit in Spalte 3
                        FerienZeitraum_Str{cnt_F, 4} = Einzelne_Ferien{cnt_F}(15:20); % die zusätzliche Zeit in Spalte 3
                    end
                case 27
                    % dd.mm.,dd.mm.,dd.mm.-dd.mm.
                    FerienZeitraum_Str{cnt_F, 1} = Einzelne_Ferien{cnt_F}(15:20);
                    FerienZeitraum_Str{cnt_F, 2} = Einzelne_Ferien{cnt_F}(22:27);
                    FerienZeitraum_Str{cnt_F, 3} = Einzelne_Ferien{cnt_F}( 1: 6);
                    FerienZeitraum_Str{cnt_F, 4} = Einzelne_Ferien{cnt_F}( 8:13);
                case 12
                    %                 dd.mm.-dd.mm.
                    FerienZeitraum_Str{cnt_F, 1} = Einzelne_Ferien{cnt_F}( 1 : 6);
                    FerienZeitraum_Str{cnt_F, 2} = Einzelne_Ferien{cnt_F}( 7 :12);
                case 26 
                    % dd.mm., <br/> dd.mm-dd.mm
                    FerienZeitraum_Str{cnt_F, 1} = Einzelne_Ferien{cnt_F}( 1 : 6);
                    FerienZeitraum_Str{cnt_F, 2} = Einzelne_Ferien{cnt_F}( end-5 :end);
                case 21
                    % dd.mm.,dd.mm.-dd.mm. mit Zeilenumbruch?
                    if (Einzelne_Ferien{cnt_F}(7) == ',' && Einzelne_Ferien{cnt_F}(16) == '-') %|| ((Einzelne_Ferien{1}{cnt_F}(7) == '+' && Einzelne_Ferien{1}{cnt_F}(14) == '-'))
                        FerienZeitraum_Str{cnt_F, 1} = Einzelne_Ferien{cnt_F}( 1 :6); % gleiche Zeit bei Spalte 1 & 2
                        FerienZeitraum_Str{cnt_F, 2} = Einzelne_Ferien{cnt_F}(end-5 :end); % gleiche Zeit bei Spalte 1 & 2
                       % FerienZeitraum_Str{cnt_F, 3} = Einzelne_Ferien{1}{cnt_F}( 1 : 6); % die zusätzliche Zeit in Spalte 3
                    end
                otherwise
                    warndlg(join(['Formatierungsfehler Webabfrage Ferien: ', Bundesland, ", ", Jahr_str, ", ", Ferienreihenfolge(cnt_F)]))
            end
        end
    end
    
    % Zeilen mit keinen Ferien ausfiltern:
    idx_Ferien = any(cellfun(@any, FerienZeitraum_Str),2);
    FerienZeitraum_Str(~idx_Ferien, :) = [];
    Ferienreihenfolge(~idx_Ferien) = [];

    % In eine Matlab-Zeit umrechnen:
    FerienTage_cell = cell(size(FerienZeitraum_Str,1), 2); % vordimensionieren
    for cnt_F = 1 : size(FerienZeitraum_Str,1)
        if any(FerienZeitraum_Str{cnt_F, 1}) && any(FerienZeitraum_Str{cnt_F, 2})
            % Fall wenn FerienZeitraum_Str{cnt_F, 1} und FerienZeitraum_Str{cnt_F, 2} besetzt sind, d.h. es einen Zeitraum gibt:
            FerienEnde = datenum([FerienZeitraum_Str{cnt_F,2},Jahr_str], 'dd.mm.yyyy');
            if isequal(Ferienreihenfolge{cnt_F}, 'Weihnachten') && isequal(FerienZeitraum_Str{cnt_F,2}(4:5), '01')
                letztes_Jahr_str = num2str(str2double(Jahr_str)-1); % Die Weihnachtsferien von letzes Jahr.
                FerienBeginn = datenum([FerienZeitraum_Str{cnt_F,1},letztes_Jahr_str], 'dd.mm.yyyy');
            else
                FerienBeginn = datenum([FerienZeitraum_Str{cnt_F,1},Jahr_str], 'dd.mm.yyyy');
            end
            FerienTage_cell{cnt_F,1} = ctranspose(FerienBeginn : FerienEnde);
            FerienTage_cell{cnt_F,2} = cell(size(FerienTage_cell{cnt_F,1})); % vordimensionieren
            [FerienTage_cell{cnt_F,2}{:}] = deal(Ferienreihenfolge{cnt_F});
        end

        if any(FerienZeitraum_Str{cnt_F, 3})
            if isequal(Ferienreihenfolge{cnt_F}, 'Weihnachten') && isequal(FerienZeitraum_Str{cnt_F,3}(4:5), '12')
                letztes_Jahr_str = num2str(str2double(Jahr_str)-1); % Die Weihnachtsferien reichen ins nächste Jahr.
                FerienTag = datenum([FerienZeitraum_Str{cnt_F,3},letztes_Jahr_str], 'dd.mm.yyyy');
            else
                FerienTag = datenum([FerienZeitraum_Str{cnt_F,3},Jahr_str], 'dd.mm.yyyy');
            end
            FerienTage_cell{cnt_F,1}(end + 1,1) = FerienTag;
            FerienTage_cell{cnt_F,2}{end + 1,1} = Ferienreihenfolge{cnt_F};
        end
        if any(FerienZeitraum_Str{cnt_F, 4})
            if isequal(Ferienreihenfolge{cnt_F}, 'Weihnachten') && isequal(FerienZeitraum_Str{cnt_F,4}(4:5), '12')
                letztes_Jahr_str = num2str(str2double(Jahr_str)-1); % Die Weihnachtsferien reichen ins nächste Jahr.
                FerienTag = datenum([FerienZeitraum_Str{cnt_F,4},letztes_Jahr_str], 'dd.mm.yyyy');
            else
                FerienTag = datenum([FerienZeitraum_Str{cnt_F,4},Jahr_str], 'dd.mm.yyyy');
            end
            FerienTage_cell{cnt_F,1}(end + 1,1) = FerienTag;
            FerienTage_cell{cnt_F,2}{end + 1,1} = Ferienreihenfolge{cnt_F};
        end
    end

    % Alle Ferientage
    FerienTage = vertcat(FerienTage_cell{:,1});
    FerienTage_Name = vertcat(FerienTage_cell{:,2});
   
else
    %
    warndlg(['Abfrage Ferien erfolglos: ', Bundesland, ", ", Jahr_str])
    % Rückgabe leerer Arrays
    FerienTage = [];
    FerienTage_Name = {};
end

MyDisp('   ... Webabfrage der Ferien abgeschlossen.')
end % function

function Bundesland_HTML = Bundesland_wie_in_der_URL(Bundesland)
switch Bundesland
    case 'BW' % BW = Baden-Württemberg
        Bundesland_HTML = 'Baden-W&uuml;rttemberg'; % Ist als Link so gespeichert.
        % http://www.schulferien.org/Kalender_mit_Ferien/kalender_2013_ferien_Baden_Wuerttemberg.html
    case 'BY' % BY = Bayern
        Bundesland_HTML = 'Bayern'; % Ist als Link so gespeichert.
        % http://www.schulferien.org/Kalender_mit_Ferien/kalender_2013_ferien_Bayern.html
    case 'BE' % BE = Berlin
        Bundesland_HTML = 'Berlin'; % Ist als Link so gespeichert.
        % http://www.schulferien.org/Kalender_mit_Ferien/kalender_2013_ferien_Berlin.html
    case 'BB' % BB = Brandenburg
        Bundesland_HTML = 'Brandenburg'; % Ist als Link so gespeichert.
        % http://www.schulferien.org/Kalender_mit_Ferien/kalender_2013_ferien_Brandenburg.html
    case 'HB' % HB = Bremen
        Bundesland_HTML = 'Bremen'; % Ist als Link so gespeichert.
        % http://www.schulferien.org/Kalender_mit_Ferien/kalender_2013_ferien_Bremen.html
    case 'HH' % HH = Hamburg
        Bundesland_HTML = 'Hamburg'; % Ist als Link so gespeichert.
        % http://www.schulferien.org/Kalender_mit_Ferien/kalender_2013_ferien_Hamburg.html
    case 'HE' % HE = Hessen
        Bundesland_HTML = 'Hessen'; % Ist als Link so gespeichert.
        % http://www.schulferien.org/Kalender_mit_Ferien/kalender_2013_ferien_Hessen.html
    case 'MV' % MV = Mecklenburg-Vorpommern
        Bundesland_HTML = 'Meckl.-Vorpommern'; % Ist als Link so gespeichert.
        % http://www.schulferien.org/Kalender_mit_Ferien/kalender_2013_ferien_Mecklenburg_Vorpommern.html
    case 'NI' % NI = Niedersachsen
        Bundesland_HTML = 'Niedersachsen'; % Ist als Link so gespeichert.
        % http://www.schulferien.org/Kalender_mit_Ferien/kalender_2013_ferien_Niedersachsen.html
    case 'NW' % NW = Nordrhein-Westfalen
        Bundesland_HTML = 'Nordrhein-Westfalen'; % Ist als Link so gespeichert.
        % http://www.schulferien.org/Kalender_mit_Ferien/kalender_2013_ferien_Nordrhein_Westfalen.html
    case 'RP' % RP = Rheinland-Pfalz
        Bundesland_HTML = 'Rheinland-Pfalz'; % Ist als Link so gespeichert.
        % http://www.schulferien.org/Kalender_mit_Ferien/kalender_2013_ferien_Rheinland_Pfalz.html
    case 'SL' % SL = Saarland
        Bundesland_HTML = 'Saarland'; % Ist als Link so gespeichert.
        % http://www.schulferien.org/Kalender_mit_Ferien/kalender_2013_ferien_Saarland.html
    case 'SN' % SN = Sachsen
        Bundesland_HTML = 'Sachsen'; % Ist als Link so gespeichert. Der Punkt und Unterstrich, da sonst Sachsen_Anhalt und Niedersachsen auch erkannt werden
        % http://www.schulferien.org/Kalender_mit_Ferien/kalender_2013_ferien_Sachsen.html
    case 'ST' % ST = Sachsen-Anhalt
        Bundesland_HTML = 'Sachsen-Anhalt'; % Ist als Link so gespeichert.
        % http://www.schulferien.org/Kalender_mit_Ferien/kalender_2013_ferien_Sachsen_Anhalt.html
    case 'SH' % SH = Schleswig-Holstein
        Bundesland_HTML = 'Schleswig-Holstein'; % Ist als Link so gespeichert.
        % http://www.schulferien.org/Kalender_mit_Ferien/kalender_2013_ferien_Schleswig_Holstein.html
    case 'TH' % TH = Thüringen
        Bundesland_HTML = 'Th&uuml;ringen'; % Ist als Link so gespeichert.
        % http://www.schulferien.org/Kalender_mit_Ferien/kalender_2013_ferien_Thueringen.html
    otherwise
        error('Webabfrage Kalender: Kein Bundesland eingegeben.')
        
end % switch Bundesland

end
function plot_Schulferien(Tage, idx_Ferien, Ferien_Name, h_axes)

YLim = get(h_axes, 'YLim');
y_unten = YLim(1);
y_oben  = YLim(2);

set(0, 'CurrentFigure', get(h_axes, 'Parent'));     % Das Figure als das aktuelle setzten
set(get(h_axes, 'Parent'), 'CurrentAxes', h_axes);  % Die Axes   als die aktuelle setzten

% Zuordnung von Farben zu den einzelnen  Ferien:
einz_Ferien = {'Winterferien'; 'Osterferien'; 'Pfingstferien'; 'Sommerferien'; 'Herbstferien'; 'Weihnachten'};

Tage_trans = Tage';
x_Matrix = [Tage_trans; [Tage_trans(2:end), Tage_trans(end) + 1]; [Tage_trans(2:end), Tage_trans(end) + 1]; Tage_trans];
y_Matrix = [ones(2,length(Tage)) .* y_unten; ones(2,length(Tage)) .* y_oben];


idx_FerienName = cellfun(@any, Ferien_Name); % Es gibt einen Ferienname
[~, idx_Ferien_mit] = ismember(Ferien_Name(idx_FerienName), einz_Ferien);
idx_Ferien2 = zeros(size(idx_FerienName)); %ones(size(idx_FerienName)) * (max(idx_Ferien) + 1);
idx_Ferien2(idx_FerienName) = idx_Ferien_mit;

% Ferien, die nicht einem Namen zugeordnet werden können:
idx_Ferien_kein_Name = idx_Ferien & idx_Ferien2 == 0;
if any(idx_Ferien_kein_Name)
    idx_Ferien2(idx_Ferien_kein_Name) = length(einz_Ferien) + 1;
    einz_Ferien(end + 1) = {'unb. Ferien'};
end

hold on;
Farben = idx_Ferien2;
for cnt_F = 1 : length(einz_Ferien)
    idx_hier = idx_Ferien2 == cnt_F;
    
    patch(x_Matrix(:,idx_hier), y_Matrix(:,idx_hier), 'w', ...
        'EdgeColor',       'none', ...
        'FaceColor',       'flat', ...
        'FaceVertexCData', Farben(idx_hier), ...
        'FaceAlpha', 0.5, ...
        'DisplayName', einz_Ferien{cnt_F});
end

text_xlabel_str = 'Zeit';
text_ylabel_str = []; % bereits bestehendes lassen.
text_title_str  = [];
flag_x_datetick = true;
datetick_format = [];
font_size       = [];
handle_axes     = [];
flag_keeplimits = [];
Lohmiller_Standard_plot_Format( text_xlabel_str, text_ylabel_str, text_title_str , flag_x_datetick, datetick_format, font_size, handle_axes, flag_keeplimits)

end % function plot_Schulferien
function  [idx_Ferien, Ferien_Name] = Woe_auch_Ferien(Tage, idx_Ferien, Ferien_Name, Bundesland)
% Die Wochenenden von % nach den Ferien werden jeweils auch zum Ferienzeitraum hinzugefügt.
% Das schließt auch Feiertage wie Karfreitag oder Pfingstmontag mit ein.
% D.h. wenn der Oster-Ferienbeginn am Dienstag nach Ostern ist, beginnen die Osterferien bereits am Karfreitag
% Mit der Funktion ist diese Funktion nur möglich, wenn keine Tage fehlen:

idx_jeder_Tag = all(diff(Tage) == 1);

if ~idx_jeder_Tag
    warning('Woe_auch_Ferien konnte nicht durchgeführt werden,')
    return,
end

% Feiertage werden abgerufen:
flag_Feiertage_anzeigen = false;
flag_plot_Feiertage = false;
idx_Feiertag = Feiertage(Tage, Bundesland, flag_Feiertage_anzeigen, flag_plot_Feiertage);

% Prüfung vor dem Ferienbeginn
idx_Ferienbeginn = find(diff(idx_Ferien) == 1); % Die hier zurückgegebenen Tage sind die jeweils letzten Tage VOR den Ferien =>  idx_Ferienbeginn + 1 == Ferienbeginn (erster Ferientag)
for cnt_FB = 1 : length(idx_Ferienbeginn)
    akt_Tag = idx_Ferienbeginn(cnt_FB);
    akt_Ferien = Ferien_Name{akt_Tag + 1};
    while ismember(weekday(Tage(akt_Tag)), [1, 7]) || idx_Feiertag(akt_Tag) % 1: Sonntag, 7: Samstag
        % Wenn der vorherige Tage ein Sonntag, Samstag oder Feiertag ist, wird er als Ferientag deklariert.
        idx_Ferien(akt_Tag) = true;
        Ferien_Name{akt_Tag} = akt_Ferien;
        akt_Tag = akt_Tag - 1; % Ein Tag zurück.
        if akt_Tag == 0, break, end
    end
end

% Prüfung nach dem Ferienende
idx_Ferienende = find(diff(idx_Ferien) == -1); % Die hier zurückgegebenen Tage sind die letzten Ferientage
for cnt_FE = 1 : length(idx_Ferienende)
    akt_Tag = idx_Ferienende(cnt_FE) + 1; % + 1, da das der erste Tag NACH den Ferien ist, dieser soll geprüft werden.
    akt_Ferien = Ferien_Name{akt_Tag - 1};
    if akt_Tag <= length(idx_Ferien)
        while ismember(weekday(Tage(akt_Tag)), [1, 7]) || idx_Feiertag(akt_Tag) % 1: Sonntag, 7: Samstag
            % Wenn der vorherige Tage ein Sonntag, Samstag oder Feiertag ist, wird er als Ferientag deklariert.
            idx_Ferien(akt_Tag) = true;
            Ferien_Name{akt_Tag} = akt_Ferien;
            akt_Tag = akt_Tag + 1; % Ein Tag vorwärts (nächster Tag).
            if akt_Tag > length(idx_Ferien), break, end
        end
    else
        % Der aktuelle Tag ist bereits der letzte Tag des Untersuchungszeitraumes.
    end
end
end

%% Feiertage
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
if nargin < 2 || isempty(Bundesland)
    Bundesland = 'BW';
    idx_welche_Feiertage_anwenden = Einstellungen_fuer_Bundesland(Bundesland);
elseif islogical(Bundesland) && all(size(Bundesland) == [17,1])
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

if flag_Ostersonntag_berechnen
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
if idx_welche_Feiertage_anwenden(1) == true
    idx_NeuJahr = DateVec(:,2) ==  1 & DateVec(:,3) ==  1;
    idx_Feiertag(idx_NeuJahr) = true;
    [Feiertage_Name{idx_NeuJahr}] = deal('Neujahr');
end

% 3 Könige 06.01. | BW, BY, ST
if idx_welche_Feiertage_anwenden(2) == true
    idx_3_Koenige = DateVec(:,2) ==  1 & DateVec(:,3) ==  6;
    idx_Feiertag(idx_3_Koenige) = true;
    [Feiertage_Name{idx_3_Koenige}] = deal('Hl. 3 Könige');
end

% Karfreitag (2 Tag vor Ostern) | bundesweit
if idx_welche_Feiertage_anwenden(3) == true
    idx_Karfreitag = ismember(Tage, Ostersonntag_mat - 2);
    idx_Feiertag(idx_Karfreitag) = true;
    [Feiertage_Name{idx_Karfreitag}] = deal('Karfreitag');
end

% Ostersonntag | bundesweit
if idx_welche_Feiertage_anwenden(4) == true
    idx_Ostersonntag = ismember(Tage, Ostersonntag_mat);
    idx_Feiertag(idx_Ostersonntag) = true;
    [Feiertage_Name{idx_Ostersonntag}] = deal('Ostersonntag');
end

% Ostermontag (1 Tag nach Ostern) | bundesweit
if idx_welche_Feiertage_anwenden(5) == true
    idx_Ostermontag = ismember(Tage, Ostersonntag_mat + 1);
    idx_Feiertag(idx_Ostermontag) = true;
    [Feiertage_Name{idx_Ostermontag}] = deal('Ostermontag');
end

% Tag der Arbeit 01.05. | bundesweit
if idx_welche_Feiertage_anwenden(6) == true
    idx_Tag_der_Arbeit = DateVec(:,2) ==  5 & DateVec(:,3) ==  1;
    idx_Feiertag(idx_Tag_der_Arbeit) = true;
    [Feiertage_Name{idx_Tag_der_Arbeit}] = deal('Tag der Arbeit');
end

% Christi Himmelfahrt (39 Tage nach dem Ostersonntag) | bundesweit
if idx_welche_Feiertage_anwenden(7) == true
    idx_Chr_Himmelfahrt = ismember(Tage, Ostersonntag_mat + 39);
    idx_Feiertag(idx_Chr_Himmelfahrt) = true;
    [Feiertage_Name{idx_Chr_Himmelfahrt}] = deal('Christi Himmelfahrt');
end

% Pfingstsonntag (Es wird am 49 Tag nach Ostern begangen) | bundesweit
if idx_welche_Feiertage_anwenden(8) == true
    idx_Pfingstsonntag = ismember(Tage, Ostersonntag_mat + 49);
    idx_Feiertag(idx_Pfingstsonntag) = true;
    [Feiertage_Name{idx_Pfingstsonntag}] = deal('Pfingstsonntag');
end

% Pfingstmontag (Es wird am fünfzigsten Tag nach Ostern begangen) | bundesweit
if idx_welche_Feiertage_anwenden(9) == true
    idx_Pfingsmontag = ismember(Tage, Ostersonntag_mat + 50);
    idx_Feiertag(idx_Pfingsmontag) = true;
    [Feiertage_Name{idx_Pfingsmontag}] = deal('Pfingstmontag');
end

% Fronleichnam (am 60. Tag nach dem Ostersonntag) | BW, BY, HE, NW, RP, SL, SN*, TH* (* kein gesetzlicher Feiertag in diesen BL, nur in manchen Gemeinden)
if idx_welche_Feiertage_anwenden(10) == true
    idx_Fronleichnam = ismember(Tage, Ostersonntag_mat + 60);
    idx_Feiertag(idx_Fronleichnam) = true;
    [Feiertage_Name{idx_Fronleichnam}] = deal('Fronleichnam');
end

% % Mariä Himmelfahrt 15.08. | BY*, SL (nicht in allen, aber den meisten Gemeinden; schulfrei für alle)
if idx_welche_Feiertage_anwenden(11) == true
    idx_Maria_Himmelfahrt = DateVec(:,2) ==  8 & DateVec(:,3) == 15;
    idx_Feiertag(idx_Maria_Himmelfahrt) = true;
    [Feiertage_Name{idx_Maria_Himmelfahrt}] = deal('Mariä Himmelfahrt');
end

% Tag der dt. Einheit 03.10. | bundesweit
if idx_welche_Feiertage_anwenden(12) == true
    idx_Tag_der_dt_Einheit = DateVec(:,2) == 10 & DateVec(:,3) ==  3;
    idx_Feiertag(idx_Tag_der_dt_Einheit) = true;
    [Feiertage_Name{idx_Tag_der_dt_Einheit}] = deal('Tag der dt. Einheit');
end

% Reformationstag 31.10. | BB, MV, SN, ST, TH
if idx_welche_Feiertage_anwenden(13) == true
    idx_Reformationstag = DateVec(:,2) == 10 & DateVec(:,3) == 31;
    idx_Feiertag(idx_Reformationstag) = true;
    [Feiertage_Name{idx_Reformationstag}] = deal('Reformationstag');
end

% Allerheiligen 01.11. | BW, BY, NW, RP, SL
if idx_welche_Feiertage_anwenden(14) == true
    idx_Allerheiligen = DateVec(:,2) == 11 & DateVec(:,3) ==  1;
    idx_Feiertag(idx_Allerheiligen) = true;
    [Feiertage_Name{idx_Allerheiligen}] = deal('Allerheiligen');
end

% Buß- und Bettag (Regel: am Mittwoch vor dem 23. November) | BY, SN
if idx_welche_Feiertage_anwenden(15) == true
    idx_Bus_und_Bettag = DateVec(:,2) == 11 & ismember(DateVec(:,3), 16:22) & Wochentag ==  4;
    idx_Feiertag(idx_Bus_und_Bettag) = true;
    [Feiertage_Name{idx_Bus_und_Bettag}] = deal('Buß- und Bettag');
end

% 1. Weihnachtsfeiertag 25.12. | bundesweit
if idx_welche_Feiertage_anwenden(16) == true
    idx_1_Weihnachtsfeiertag = DateVec(:,2) == 12 & DateVec(:,3) == 25;
    idx_Feiertag(idx_1_Weihnachtsfeiertag) = true;
    [Feiertage_Name{idx_1_Weihnachtsfeiertag}] = deal('1. Weihnachtsfeiertag');
end

% 2. Weihnachtsfeiertag 26.12. | bundesweit
if idx_welche_Feiertage_anwenden(17) == true
    idx_2_Weihnachtsfeiertag = DateVec(:,2) == 12 & DateVec(:,3) == 26;
    idx_Feiertag(idx_2_Weihnachtsfeiertag) = true;
    [Feiertage_Name{idx_2_Weihnachtsfeiertag}] = deal('2. Weihnachtsfeiertag');
end

if flag_2412_und_3112_auch_Feiertage
    idx_2412 = DateVec(:,2) == 12 & DateVec(:,3) == 24;
    idx_Feiertag(idx_2412) = true;
    [Feiertage_Name{idx_2412}] = deal('Heiligabend');   
    
    idx_3112 = DateVec(:,2) == 12 & DateVec(:,3) == 31;
    idx_Feiertag(idx_3112) = true;
    [Feiertage_Name{idx_3112}] = deal('Silvester');      
end


% Feiertage anzeigen:
if flag_Feiertage_anzeigen == true
    disp([cellstr(datestr(Tage, 'ddd dd.mm.yyyy')); Feiertage_Name])
end


if nargout > 2
    % Namen der einzelnen Feiertage speichern:
    Einzelne_Feiertage = unique(Feiertage_Name(idx_Feiertag));
    if isempty(Einzelne_Feiertage)
        idx_einzelne_Feiertage = struct(); % leere Struct
    else
        for cnt_EF = 1 : length(Einzelne_Feiertage)
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
    if exist('idx_Tag_der_Arbeit', 'var') && any(idx_Tag_der_Arbeit)
        % Es kommt vor. In diesem Fall wurde der Tag der Arbeit überschrieben:
        idx_einzelne_Feiertage.Tag_der_Arbeit = idx_Tag_der_Arbeit;
    end
end

% PLotten der Feiertage:
if ishandle(flag_plot) || flag_plot
    if ishandle(flag_plot)
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

%% Jahreszeiten
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

switch(wie_Jahreszeit)
    %% meteorologische Jahreszeit
    case 1
        Jahreszeiten(ismember(Monat, [3,4,5]))      = 1;
        Jahreszeiten(ismember(Monat, [6,7,8]))      = 2;
        Jahreszeiten(ismember(Monat, [9,10,11]))    = 3;
        
        Jahreszeiten_Bezeichnung = {['Frühling',Zusatz_Bezeichnung], ['Sommer',Zusatz_Bezeichnung], ['Herbst',Zusatz_Bezeichnung], ['Winter',Zusatz_Bezeichnung]};
        
    %% kalendarisch Jahreszeit
    case 2
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
    case 3
        Jahreszeiten(ismember(Monat, [3,4,5]))      = 1;
        Jahreszeiten(ismember(Monat, [6,7,8,9]))    = 2;
        Jahreszeiten(ismember(Monat, [10,11]))      = 3;
        
        Jahreszeiten_Bezeichnung = {['Frühling',Zusatz_Bezeichnung], ['Sommer',Zusatz_Bezeichnung], ['Herbst',Zusatz_Bezeichnung], ['Winter',Zusatz_Bezeichnung]};
        
    %% Monat des Jahres 
    case 4
        Jahreszeiten = Monat;
        
        Jahreszeiten_Bezeichnung = {['Januar',Zusatz_Bezeichnung'], ['Februar',Zusatz_Bezeichnung'], ['Maerz',Zusatz_Bezeichnung'], ['April',Zusatz_Bezeichnung'], ['Mai',Zusatz_Bezeichnung'], ['Juni',Zusatz_Bezeichnung'], ['Juli',Zusatz_Bezeichnung'], ['August',Zusatz_Bezeichnung'], ['September',Zusatz_Bezeichnung'], ['Oktober',Zusatz_Bezeichnung'], ['November',Zusatz_Bezeichnung'], ['Dezember',Zusatz_Bezeichnung']};
        
    %% Kalenderwoche nach ISO 8601 (https://de.wikipedia.org/wiki/Woche)
    % Das Jahr umfasst mindestens 52 durchnummerierte Kalenderwochen (KW), wobei es bei den Wochen-Nummerierungen verschiedene Variationen gibt. 
    % Je nach angewandter Regel ist die erste Woche des Jahres ISO (DIN/ÖNORM/SN): 
    %   die Woche, die den ersten Donnerstag des Jahres enthält (ISO 8601, früher DIN 1355-1); 
    % äquivalent dazu
    %   die Woche, die den 4. Januar enthält
    %   die erste Woche, in die mindestens vier Tage des neuen Jahres fallen
    case 5

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
        if size(Datum1,1) == 1
            Addition_zu_Donnerstag = [4 3 2 1 0 -1 -2];
        else
            Addition_zu_Donnerstag = [4 3 2 1 0 -1 -2]';
        end
        Donnerstag_dieser_Woche = Datum1 + Addition_zu_Donnerstag(Wochentag);
        
        % Test:
        % [datestr(Datum, 'ddd dd.mm.yyyy >= '), datestr(Donnerstag_dieser_Woche, 'ddd dd.mm.yyyy')]
        
    end

end % function KalenderWoche

























































