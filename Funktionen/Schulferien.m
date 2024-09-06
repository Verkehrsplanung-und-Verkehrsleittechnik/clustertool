function [idx_Ferien, Ferien_Name, idx_einzelne_Ferien] = Schulferien(Tage, Bundesland, flag_Ferien_anzeigen, flag_alle_Ferien_speichern, force_reload, flag_Woe_auch_Ferien, flag_plot)
% Gibt eine boolean - Vektor zurück mit true an den Tagen an denen einen Ferientag vorliegt.
% Quelle sind die Daten auf http://www.schulferien.org.
%
% Eingänge:
%   - Tage                              n  x 1 Vektor mit Matlab - Zeit (ganze Tage; zur Not: Tage = floor(Tage);)
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
% -----------------------------------------------------------------------------------------------------------------------
% Rückgabe:
%   - idx_Ferien                        n  x 1 boolean Vektor mit true bei einem Ferientag
%   - Ferien_Name                       n  x 1 Cell mit den Namen der Ferien (sofern Ferien sind)
%   - idx_einzelne_Ferien               Struct mit den Felder der vorkommenden Ferien (z.B. Herbstferien, Osterferien, ...)
%                                       in jedem Feld (z.B. "Pfingstferien") gibt ein boolean Vektor an, ob diese Ferien vorliegen.
%
% % Beispiel #1:
% StartTag = datenum('16.07.2012', 'dd.mm.yyyy');
% EndeTag  = datenum('27.10.2014', 'dd.mm.yyyy');
% Tage = StartTag:EndeTag;
% Bundesland = 'BW';
% flag_Ferien_anzeigen = true;
% flag_alle_Ferien_speichern = false;
% force_reload = false;
% flag_Woe_auch_Ferien = true;
% flag_plot = true;
% [idx_Ferien, Ferien_Name, idx_einzelne_Ferien] = Schulferien(Tage, Bundesland, flag_Ferien_anzeigen, flag_alle_Ferien_speichern, force_reload, flag_Woe_auch_Ferien, flag_plot);
%
% % Beispiel #2 (nur Samstage):
% StartTag = datenum('14.07.2012', 'dd.mm.yyyy');
% EndeTag  = datenum('27.10.2014', 'dd.mm.yyyy');
% Tage = StartTag:7:EndeTag;
% Bundesland = 'BW';
% flag_Ferien_anzeigen = true;
% flag_alle_Ferien_speichern = false;
% force_reload = false;
% flag_Woe_auch_Ferien = true;
% flag_plot = true;
% [idx_Ferien, Ferien_Name, idx_einzelne_Ferien] = Schulferien(Tage, Bundesland, flag_Ferien_anzeigen, flag_alle_Ferien_speichern, force_reload, flag_Woe_auch_Ferien, flag_plot);
%
% ------------------------------------------------------
% % Matix mit allen Ferientagen:
% StartTag = datenum('01.01.2012', 'dd.mm.yyyy');
% EndeTag  = datenum('31.12.2012', 'dd.mm.yyyy');
% Tage = StartTag:EndeTag;
% Bundeslaender = {'BW', 'BY', 'BE', 'BB', 'HB', 'HH', 'HE', 'MV', 'NI', 'NW', 'RP', 'SL', 'SN', 'ST', 'SH', 'TH' };
% idx_Ferien  = false(length(Tage), length(Bundeslaender)); % vordimensionieren
% Ferien_Name = cell(length(Tage), length(Bundeslaender));  % vordimensionieren
% flag_Ferien_anzeigen = false;
% flag_alle_Ferien_speichern = false;
% force_reload = false;
% flag_Woe_auch_Ferien = true;
% flag_plot = false;
% for cnt_BL = 1 : length(Bundeslaender),
%     [idx_Ferien(:, cnt_BL), Ferien_Name(:, cnt_BL)] = Schulferien(Tage, Bundeslaender{cnt_BL}, flag_Ferien_anzeigen, flag_alle_Ferien_speichern, force_reload, flag_Woe_auch_Ferien, flag_plot);
% end



if nargin < 1 || isempty(Tage),                         error('Ein Eingang wird benötigt.'),    end
if nargin < 2 || isempty(Bundesland),                   Bundesland = 'BW';                      end
if nargin < 3 || isempty(flag_Ferien_anzeigen),         flag_Ferien_anzeigen = true;            end
if nargin < 4 || isempty(flag_alle_Ferien_speichern),   flag_alle_Ferien_speichern = false;     end
if nargin < 5 || isempty(force_reload),                 force_reload = false;                   end
if nargin < 6 || isempty(flag_Woe_auch_Ferien),         flag_Woe_auch_Ferien = false;           end
if nargin < 7 || isempty(flag_plot),                    flag_plot = true;                       end

% if flag_alle_Ferien_speichern && flag_Woe_auch_Ferien,
%     warning('Wochentage werden beim berechnen (flag_alle_Ferien_speichern = true) nicht als Ferien zurückgegeben.')
% end
% if force_reload && flag_Woe_auch_Ferien,
%     warning('Wochentage werden beim berechnen (force_reload = true) nicht als Ferien zurückgegeben.')
% end


% Diese Funktion kann nur mit ganzen Tagen rechnen.
Tage = floor(Tage);
% Tage als Spaltenvektor schreiben:
Tage_neu = zeros(numel(Tage), 1); % vordimensionieren
Tage_neu(1:end) = Tage(1:end);
Tage = Tage_neu;


% if flag_alle_Ferien_speichern,
%     % Zur Sicherheit
%     warning('"flag_alle_Ferien_speichern" zur Sicherheit im Code nochmals extra auskommentieren (Zeile 29)')
%     flag_alle_Ferien_speichern = false;
% end

if flag_alle_Ferien_speichern,
    ALLE_Ferien_Speichen;
else
    
    
    % Die Daten wurden für die Jahre von 1991 - 2019 lokal gespeichert (siehe Unterfunktion "ALLE_Ferien_Speichen")
    % 727199 => 01.01.1991    737425 => 31.12.2018
    if (isstruct(force_reload) || ~force_reload) && min(Tage) >= 727199 && max(Tage) <= 737425; % Prüfen ob gespeicherte Daten verwendet werden können
        flag_saved_as_Struct = true; % In einer früheren Version wurden die Schulferien als Cell gespeichert.
        % Als Struct können die Daten um den Faktor 768 schneller geladen werden (1.5s gegenüber 0.002s bei der Struct)
        if flag_saved_as_Struct,
            
            if isstruct(force_reload),
                Ferien = force_reload;
            else
                Laender_gespeichert = {'BW', 'BY', 'BE', 'BB', 'HB', 'HH', 'HE', 'MV', 'NI', 'NW', 'RP', 'SL', 'SN', 'ST', 'SH', 'TH' }; %Liste dt Budnesländer
                if ~ismember(Bundesland, Laender_gespeichert), 
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
                % Wenn das Bundesland nicht existiert kommt eine Fehlermeldung.
            end
            
            
            Tage_Alle = Ferien.Datum;
            idx_Ferien_Alle = Ferien.(Bundesland) ~= 0;
            Ferien_Name_Alle = cell(size(Tage));
            Ferien_Name_Alle(idx_Ferien_Alle) = Ferien.FerienName(Ferien.(Bundesland)(idx_Ferien_Alle));
            if flag_Woe_auch_Ferien,
                [idx_Ferien_Alle, Ferien_Name_Alle] = Woe_auch_Ferien(Tage_Alle, idx_Ferien_Alle, Ferien_Name_Alle, Bundesland);
            end
            
            
            
            % Zeile zu jedem Tag:
            %[~, idx_Tag] = ismember(Tage, Ferien.Datum);
            idx_Tag = ismember(Ferien.Datum, Tage);
            
            idx_Ferien = idx_Ferien_Alle(idx_Tag);
            Ferien_Name = Ferien_Name_Alle(idx_Tag);
            
        else
            
            if isstruct(force_reload),
                Ferien.Schulferien_saved = force_reload;
            else
                Ferien = load('Schulferien_saved_Cell');
            end
            
            % Bundesland suchen:
            [~, idx_Spalte] = ismember({Bundesland}, Ferien.Schulferien_saved(1,2:end));
            if ~any(idx_Spalte),
                warning('Bundesland falsch eingegeben. Es werden keine Schulferien zurückgegeben');
                idx_Ferien = false(size(Tage));
                Ferien_Name = cell(size(Tage));
                idx_einzelne_Ferien = struct();
                return,
            end
            
            % Tage auswählen:
            Tage_gespeichert = cell2mat(Ferien.Schulferien_saved(2:end, 1));
            
            % Zeile zu jedem Tag:
            [~, idx_Tag] = ismember(Tage, Tage_gespeichert);
            
            % Ferien Bezeichnung auslesen:
            Ferien_Name = Ferien.Schulferien_saved(idx_Tag + 1, idx_Spalte + 1);
            idx_Ferien = cellfun(@any, Ferien_Name);
            
        end
                 
    else % Falls Ferien nicht gespeichert sind
        
        % Bestimmen der Jahre von denen die Ferien ausgelesen werden müssen:
        [Year, ~] = datevec(Tage);
        einzelne_Jahre = unique(Year);
        
        % Das naechste Jahre wird auch immer noch ausgelesen, da die Weihnachtsferien (welche ins neue Jahre hineinreichen) dort gelistet sind
        einzelne_Jahre = [einzelne_Jahre; max(einzelne_Jahre) + 1];
        
        alle_FerienTage = cell(length(einzelne_Jahre), 1); % vordimensionieren
        alle_FerienTage_Name = cell(length(einzelne_Jahre), 1); % vordimensionieren
        for cnt_J = 1 : length(einzelne_Jahre),
            akt_Jahr = einzelne_Jahre(cnt_J);
            [alle_FerienTage{cnt_J}, alle_FerienTage_Name{cnt_J}] = Ferien_eines_Jahres(akt_Jahr, Bundesland);
        end
        
        % Alle Jahre zusammenfassen:
        alle_FerienTage_Vektor = vertcat(alle_FerienTage{:});
        alle_FerienTage_Name_Vektor = vertcat(alle_FerienTage_Name{:});
        
        [idx_Ferien, zeile_Ferien] = ismember(Tage, alle_FerienTage_Vektor);
        Ferien_Name = cell(size(Tage)); % vordimensionieren
        Ferien_Name(zeile_Ferien ~= 0) = alle_FerienTage_Name_Vektor(zeile_Ferien(zeile_Ferien ~= 0));
        
    end % if ~force_reload && min(Tage) >= 727199 && max(Tage) <= 735964, % Prüfen ob gespeicherte Daten verwendet werden können
    
    
    if flag_Ferien_anzeigen,
        disp([cellstr(datestr(Tage, 'ddd dd.mm.yyyy')); Ferien_Name])
    end
    
    if nargout > 2,
        % Namen der einzelnen Ferien speichern:
        Einzelne_Ferien = unique(Ferien_Name(idx_Ferien));
        if isempty(Einzelne_Ferien),
            idx_einzelne_Ferien = struct(); % leere Struct
        else
            for cnt_EF = 1 : length(Einzelne_Ferien),
                akt_Ferien = Einzelne_Ferien{cnt_EF};
                idx_akt_Ferien = false(size(idx_Ferien)); % vordimensionieren
                idx_akt_Ferien(idx_Ferien) = ismember(Ferien_Name(idx_Ferien), akt_Ferien);
                idx_einzelne_Ferien.(akt_Ferien) = idx_akt_Ferien;
            end
        end
    end
    
end % if flag_alle_Ferien_speichern,

% PLotten der Ferien:
if ishandle(flag_plot) || flag_plot,
    if ishandle(flag_plot),
        h_axes = flag_plot;
    else
        h_axes = gca;
    end
    plot_Schulferien(Tage, idx_Ferien, Ferien_Name, h_axes);
end






end % MAIN function


function [FerienTage, FerienTage_Name] = Ferien_eines_Jahres(Jahr, Bundesland)

% Die Funktion laedt die Ferien von dem gewaehlten und dem naechsten Jahr,
% ersetzt dann die Weihnachtsferien des momentanen Jahres, die an erster
% Stelle der Ferientabelle stehen und fuegt die Weihnachtsferien des naechsten Jahres ans
% Ende hinzu.
% Der Grund dafuer ist, dass der alte Code die Ferien von Schulferien.org
% geladen hat. Die Seite ist so aufgebaut, dass die Weihnachtsferien angezeigt werden,
% die am Ende des Jahres anstehen und ins naechste Jahr uebergehen.
% Bei der neuen Seite werden die Weihnachtsferien, die letztes Jahr
% begannen und ins diese Jahr uebergehen angezeigt.

Jahr_str = num2str(Jahr);

% HTML_Text = urlread(['http://www.schulferien.org/Schulferien_nach_Jahren/',Jahr_str,'/schulferien_',Jahr_str,'.html']);
options=weboptions;
options.Timeout=5000; % in Sekunden
HTML_Text = webread(['http://schulferien.kfz-auskunft.de/schulferien_',Jahr_str,'.html'], options);

HTML_Text_Cell = String_teilen(HTML_Text,'<tr valign="top">')';

Bundesland_HTML = Bundesland__wie_in_der_URL(Bundesland);

idx_Bundesland = strfind(HTML_Text, Bundesland_HTML);
idx_Start_Bundesland = idx_Bundesland(end); % Manchmal tauchen die Namen vor der ferientabelle auf. Workaround: letztes Auftauchen ist Zeile in Tabelle

% Reihenfolgedb der Ferien:
Ferienreihenfolge = {'Weihnachten'; 'Winterferien'; 'Osterferien'; 'Pfingstferien'; 'Sommerferien'; 'Herbstferien'};

[~, Zeile_Bundesland] = histc(idx_Start_Bundesland, cumsum(cellfun(@numel, HTML_Text_Cell)));

% Die Ferientabelle befindet sich immer eine Cell nach dem Bundesland:
% Ferien_Bundesland = HTML_Text_Cell{Zeile_Bundesland(end) + 1};
Ferien_Bundesland = HTML_Text_Cell{Zeile_Bundesland(1)+1};

% Wenn die Zeile zu Ende ist kann abgebrochen werden:
% Loescht alles was hiter '</tr>' kommt
idx_Zeilenende = strfind(Ferien_Bundesland, '</tr>');

if any(idx_Zeilenende),
    Ferien_Bundesland(idx_Zeilenende:end) = [];
end

% lösche falsche Umbrüche/Formatierungen
% Fall 1: s. BW 2021 -> zeilenumbruch in Spalte
Ferien_Bundesland =  erase(Ferien_Bundesland, "<br />")

Trennzeichen = {'<td align="center">'};

Einzelne_Ferien = regexp(Ferien_Bundesland, Trennzeichen, 'split');

Einzelne_Ferien{1}(1) = []; % Strings{1}{1} beinhaltet noch den Bundeslandnamen;
% </td> aus Einzelne_Ferien löschen:
for cnt_F = 1 : length(Einzelne_Ferien{1}),
    idx_loeschen = strfind(Einzelne_Ferien{1}{cnt_F}, '</td>');
    if any(idx_loeschen),
        Einzelne_Ferien{1}{cnt_F}(idx_loeschen:idx_loeschen + 4) = [];
    end
end


% 1. Spalte: von Tag
% 2. Spalte: bis Tag
% 3. Spalte: zusätzlicher und/oder einzelner Tag
FerienZeitraum_Str = cell(length(Einzelne_Ferien{1}), 4); % vordimensionieren

for cnt_F = 1 : length(Einzelne_Ferien{1}),
    % Falls Anmerkungen vorkommen, diese rauslöschen:
    if any(strfind(Einzelne_Ferien{1}{cnt_F},'<SUP>')),
        idx_Beginn = strfind(Einzelne_Ferien{1}{cnt_F},'<SUP>');
        idx_Ende   = strfind(Einzelne_Ferien{1}{cnt_F},'</SUP>') + 5;
        Einzelne_Ferien{1}{cnt_F}(idx_Beginn:idx_Ende) = [];
    end
    
    Einzelne_Ferien{1}{cnt_F} = strtrim(Einzelne_Ferien{1}{cnt_F});
    
    if length(Einzelne_Ferien{1}{cnt_F}) < 6 || Einzelne_Ferien{1}{cnt_F}(1) == '-', % length 6 wegen xx.xx.
        % Diese Ferien gibt es in dem Bundesland nicht.
    else
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
        % Add: 9. Leerzeichen am Ende im Format "dd.mm,dd.mm - dd.mm " CASE
        % 21
        switch length(Einzelne_Ferien{1}{cnt_F}),
            
            case 13, % 1. und 2.
                
                % 1. Standard: dd.mm.-dd.mm.
                if Einzelne_Ferien{1}{cnt_F}(7) == '-';
                    FerienZeitraum_Str{cnt_F, 1} = Einzelne_Ferien{1}{cnt_F}( 1 : 6);
                    FerienZeitraum_Str{cnt_F, 2} = Einzelne_Ferien{1}{cnt_F}( 8 :13);
                end
                % 2. Zwei Tage: dd.mm.+dd.mm.
                if Einzelne_Ferien{1}{cnt_F}(7) == '+';
                    FerienZeitraum_Str{cnt_F, 1} = Einzelne_Ferien{1}{cnt_F}( 1 : 6); % gleiche Zeit bei Spalte 1 & 2
                    FerienZeitraum_Str{cnt_F, 2} = Einzelne_Ferien{1}{cnt_F}( 1 : 6); % gleiche Zeit bei Spalte 1 & 2
                    FerienZeitraum_Str{cnt_F, 3} = Einzelne_Ferien{1}{cnt_F}( 8 : 13); % die zusätzliche Zeit in Spalte 3
                end
                
            case  6, % 3. Ein Tag: dd.mm.
                FerienZeitraum_Str{cnt_F, 3} = Einzelne_Ferien{1}{cnt_F}( 1 : 6);
                
            case 20, % 4. und 5. und 6.
                % 4. Standard plus extra Tag: dd.mm.-dd.mm.,dd.mm.
                if (Einzelne_Ferien{1}{cnt_F}(7) == '-' && Einzelne_Ferien{1}{cnt_F}(14) == ',') || (Einzelne_Ferien{1}{cnt_F}(7) == '-' && Einzelne_Ferien{1}{cnt_F}(14) == '+')
                    FerienZeitraum_Str{cnt_F, 1} = Einzelne_Ferien{1}{cnt_F}( 1 : 6); % gleiche Zeit bei Spalte 1 & 2
                    FerienZeitraum_Str{cnt_F, 2} = Einzelne_Ferien{1}{cnt_F}( 8 :13); % gleiche Zeit bei Spalte 1 & 2
                    FerienZeitraum_Str{cnt_F, 3} = Einzelne_Ferien{1}{cnt_F}(15 :20); % die zusätzliche Zeit in Spalte 3
                end
                % 5. Extra Tag plus Standard: dd.mm.,dd.mm.-dd.mm.
                if (Einzelne_Ferien{1}{cnt_F}(7) == ',' && Einzelne_Ferien{1}{cnt_F}(14) == '-') || ((Einzelne_Ferien{1}{cnt_F}(7) == '+' && Einzelne_Ferien{1}{cnt_F}(14) == '-'))
                    FerienZeitraum_Str{cnt_F, 1} = Einzelne_Ferien{1}{cnt_F}( 1 :6); % gleiche Zeit bei Spalte 1 & 2
                    FerienZeitraum_Str{cnt_F, 2} = Einzelne_Ferien{1}{cnt_F}(end-5 :end); % gleiche Zeit bei Spalte 1 & 2
                   % FerienZeitraum_Str{cnt_F, 3} = Einzelne_Ferien{1}{cnt_F}( 1 : 6); % die zusätzliche Zeit in Spalte 3
                end
                % 6. Einzelne Tage: dd.mm.+dd.mm.+dd.mm.
                if Einzelne_Ferien{1}{cnt_F}(7) == '+' && Einzelne_Ferien{1}{cnt_F}(14) == '+'
                    FerienZeitraum_Str{cnt_F, 1} = Einzelne_Ferien{1}{cnt_F}( 1: 6); % gleiche Zeit bei Spalte 1 & 2
                    FerienZeitraum_Str{cnt_F, 2} = Einzelne_Ferien{1}{cnt_F}( 1: 6); % gleiche Zeit bei Spalte 1 & 2
                    FerienZeitraum_Str{cnt_F, 3} = Einzelne_Ferien{1}{cnt_F}( 8:13); % die zusätzliche Zeit in Spalte 3
                    FerienZeitraum_Str{cnt_F, 4} = Einzelne_Ferien{1}{cnt_F}(15:20); % die zusätzliche Zeit in Spalte 3
                end
            case 27
                % dd.mm.,dd.mm.,dd.mm.-dd.mm.
                FerienZeitraum_Str{cnt_F, 1} = Einzelne_Ferien{1}{cnt_F}(15:20);
                FerienZeitraum_Str{cnt_F, 2} = Einzelne_Ferien{1}{cnt_F}(22:27);
                FerienZeitraum_Str{cnt_F, 3} = Einzelne_Ferien{1}{cnt_F}( 1: 6);
                FerienZeitraum_Str{cnt_F, 4} = Einzelne_Ferien{1}{cnt_F}( 8:13);
            case 12
                %                 dd.mm.-dd.mm.
                FerienZeitraum_Str{cnt_F, 1} = Einzelne_Ferien{1}{cnt_F}( 1 : 6);
                FerienZeitraum_Str{cnt_F, 2} = Einzelne_Ferien{1}{cnt_F}( 7 :12);
            case 26 
                % dd.mm., <br/> dd.mm-dd.mm
                FerienZeitraum_Str{cnt_F, 1} = Einzelne_Ferien{1}{cnt_F}( 1 : 6);
                FerienZeitraum_Str{cnt_F, 2} = Einzelne_Ferien{1}{cnt_F}( end-5 :end);
            case 21
                % Leerzeichen am Ende Extra Tag plus Standard:
                % "dd.mm.,dd.mm.-dd.mm. "
                
                % Fall 1: Leerzeichen am Ende
                if strcmp(Einzelne_Ferien{1}{cnt_F}(end), " ")
                    FerienZeitraum_Str{cnt_F, 1} = Einzelne_Ferien{1}{cnt_F}( 1 : 6);
                    FerienZeitraum_Str{cnt_F, 2} = Einzelne_Ferien{1}{cnt_F}( end-6 :end-1);
                end
                % Leerzeichen nach - 
                if strcmp(Einzelne_Ferien{1}{cnt_F}(end-6), " ")
                    FerienZeitraum_Str{cnt_F, 1} = Einzelne_Ferien{1}{cnt_F}( 1 : 6);
                    FerienZeitraum_Str{cnt_F, 2} = Einzelne_Ferien{1}{cnt_F}( end-5 :end);                    
                end
            otherwise
                error('Unbekanntes Format')
        end
    end
end
% Zeilen mit keinen Ferien ausfiltern:
idx_Ferien = any(cellfun(@any, FerienZeitraum_Str),2);
FerienZeitraum_Str(~idx_Ferien, :) = [];
Ferienreihenfolge(~idx_Ferien) = [];


% In eine Matlab-Zeit umrechnen:
FerienTage_cell = cell(size(FerienZeitraum_Str,1), 2); % vordimensionieren
for cnt_F = 1 : size(FerienZeitraum_Str,1),
    if any(FerienZeitraum_Str{cnt_F, 1}) && any(FerienZeitraum_Str{cnt_F, 2}),
        % Fall wenn FerienZeitraum_Str{cnt_F, 1} und FerienZeitraum_Str{cnt_F, 2} besetzt sind, d.h. es einen Zeitraum gibt:
        FerienEnde = datenum([FerienZeitraum_Str{cnt_F,2},Jahr_str], 'dd.mm.yyyy');
        if isequal(Ferienreihenfolge{cnt_F}, 'Weihnachten') && isequal(FerienZeitraum_Str{cnt_F,2}(4:5), '01'),
            letztes_Jahr_str = num2str(str2double(Jahr_str)-1); % Die Weihnachtsferien von letzes Jahr.
            FerienBeginn = datenum([FerienZeitraum_Str{cnt_F,1},letztes_Jahr_str], 'dd.mm.yyyy');
        else
            FerienBeginn = datenum([FerienZeitraum_Str{cnt_F,1},Jahr_str], 'dd.mm.yyyy');
        end
        FerienTage_cell{cnt_F,1} = ctranspose(FerienBeginn : FerienEnde);
        FerienTage_cell{cnt_F,2} = cell(size(FerienTage_cell{cnt_F,1})); % vordimensionieren
        [FerienTage_cell{cnt_F,2}{:}] = deal(Ferienreihenfolge{cnt_F});
    end
    
    if any(FerienZeitraum_Str{cnt_F, 3}),
        if isequal(Ferienreihenfolge{cnt_F}, 'Weihnachten') && isequal(FerienZeitraum_Str{cnt_F,3}(4:5), '12'),
            letztes_Jahr_str = num2str(str2double(Jahr_str)-1); % Die Weihnachtsferien reichen ins nächste Jahr.
            FerienTag = datenum([FerienZeitraum_Str{cnt_F,3},letztes_Jahr_str], 'dd.mm.yyyy');
        else
            FerienTag = datenum([FerienZeitraum_Str{cnt_F,3},Jahr_str], 'dd.mm.yyyy');
        end
        FerienTage_cell{cnt_F,1}(end + 1,1) = FerienTag;
        FerienTage_cell{cnt_F,2}{end + 1,1} = Ferienreihenfolge{cnt_F};
    end
    if any(FerienZeitraum_Str{cnt_F, 4}),
        if isequal(Ferienreihenfolge{cnt_F}, 'Weihnachten') && isequal(FerienZeitraum_Str{cnt_F,4}(4:5), '12'),
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


end % function
function Bundesland_HTML = Bundesland__wie_in_der_URL(Bundesland)

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
        error('Kein Bundesland eingegeben.')
        
end % switch Bundesland

end

function ALLE_Ferien_Speichen
% Speichert alle Ferien in einer mat-Datei:

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

flag_ferien_additiv_speichern = true;

Bundeslaender = {'BW', 'BY', 'BE', 'BB', 'HB', 'HH', 'HE', 'MV', 'NI', 'NW', 'RP', 'SL', 'SN', 'ST', 'SH', 'TH' };

Von_Tag = datenum('01.01.2015', 'dd.mm.yyyy');
Bis_Tag = datenum('31.12.2016', 'dd.mm.yyyy');

Tage = Von_Tag : Bis_Tag;
flag_Ferien_anzeigen = false;
flag_alle_Ferien_speichern = false;
force_reload = true;

Schulferien_saved = cell(length(Tage) + 1, length(Bundeslaender) + 1); % vordimensionieren
for cnt_BL = 1 : length(Bundeslaender),
    Bundesland = Bundeslaender{cnt_BL};
    [idx_Ferien, Ferien_Name] = Schulferien(Tage, Bundesland, flag_Ferien_anzeigen, flag_alle_Ferien_speichern, force_reload);
    
    Schulferien_saved{1,     cnt_BL + 1} = Bundesland;
    Schulferien_saved(2:end, cnt_BL + 1) = Ferien_Name;
end

% Tage eintragen:
Schulferien_saved(2:end, 1) = num2cell(Tage)';

if flag_ferien_additiv_speichern
    Schulferien_saved_20152016 = load('Schulferien_saved.mat');
    Schulferien_saved_20152016.Datum = [Schulferien_saved_20152016.Datum;Tage'];
    
    Namen_Ferien = Schulferien_saved(2:end,2:end);
    einzelne_Ferien = unique(Namen_Ferien(cellfun(@any, Namen_Ferien)));
    
    for cnt_BL = 1: length(Bundeslaender)
        Bundesland = Bundeslaender{cnt_BL};
        spalte_BL = find(ismember(Bundesland, Schulferien_saved(1,2:end)));
        Ferien_akt_BL = Schulferien_saved(2:end, spalte_BL + 1);
        idx_Ferien = cellfun(@any, Ferien_akt_BL);
        
        [~, hallo(idx_Ferien)] = ismember(Ferien_akt_BL(idx_Ferien), einzelne_Ferien);
        Schulferien_saved_20152016.(Bundesland) = [Schulferien_saved_20152016.(Bundesland);hallo'];
    end
    
    save Schulferien_saved2015_2016 Schulferien_saved_20152016
else
    % Cell umformatieren, als Struct:
    Schulferien_saved_Cell = Schulferien_saved;
    Namen_Ferien = Schulferien_saved_Cell(2:end,2:end);
    einzelne_Ferien = unique(Namen_Ferien(cellfun(@any, Namen_Ferien)));
    Schulferien_saved = struct();
    Schulferien_saved.FerienName = einzelne_Ferien;
    Schulferien_saved.Datum = cell2mat(Schulferien_saved_Cell(2:end, 1));
    Schulferien_saved.Hilfe = ['Für jedes Bundesland gibt es ein Unterfeld. Das Feld ist numerisch. Eine 0 bedeutet, dass keine Schulferien sind.',char(10), ...
        'Die unterschiedlichen Nummern geben die verschiedenen Ferien zurück. Die Zuordnung der Nummern zu den Ferien erfolgt über Schulferien_saved.FerienName.',char(10), ...
        'Die Nummer 3 bedeutet z.B., dass die Ferien: Schulferien_saved.FerienName{3} sind.'];
    for cnt_BL = 1 : length(Bundeslaender),
        Bundesland = Bundeslaender{cnt_BL};
        spalte_BL = find(ismember(Bundesland, Schulferien_saved_Cell(1,2:end)));
        Ferien_akt_BL = Schulferien_saved_Cell(2:end, spalte_BL + 1);
        idx_Ferien = cellfun(@any, Ferien_akt_BL);
        Schulferien_saved.(Bundesland) = zeros(size(Schulferien_saved.Datum)); % vordimensionieren mit "keine Ferien".
        [~, Schulferien_saved.(Bundesland)(idx_Ferien)] = ismember(Ferien_akt_BL(idx_Ferien), Schulferien_saved.FerienName);
    end
    
    save Schulferien_saved -struct Schulferien_saved
end
end % function

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
if any(idx_Ferien_kein_Name),
    idx_Ferien2(idx_Ferien_kein_Name) = length(einz_Ferien) + 1;
    einz_Ferien(end + 1) = {'unb. Ferien'};
end

hold on;
Farben = idx_Ferien2;
for cnt_F = 1 : length(einz_Ferien),
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

if ~idx_jeder_Tag,
    warning('Woe_auch_Ferien konnte nicht durchgeführt werden,')
    return,
end

% Feiertage werden abgerufen:
flag_Feiertage_anzeigen = false;
flag_plot_Feiertage = false;
idx_Feiertag = Feiertage(Tage, Bundesland, flag_Feiertage_anzeigen, flag_plot_Feiertage);

% Prüfung vor dem Ferienbeginn
idx_Ferienbeginn = find(diff(idx_Ferien) == 1); % Die hier zurückgegebenen Tage sind die jeweils letzten Tage VOR den Ferien =>  idx_Ferienbeginn + 1 == Ferienbeginn (erster Ferientag)
for cnt_FB = 1 : length(idx_Ferienbeginn),
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
for cnt_FE = 1 : length(idx_Ferienende),
    akt_Tag = idx_Ferienende(cnt_FE) + 1; % + 1, da das der erste Tag NACH den Ferien ist, dieser soll geprüft werden.
    akt_Ferien = Ferien_Name{akt_Tag - 1};
    if akt_Tag <= length(idx_Ferien),
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















