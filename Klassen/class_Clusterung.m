%% class_Clusterung
classdef class_Clusterung < handle
    % Klasse die die Clusterung steuert
    %  ...deren Ergebnis findet sich dann in KalenderClusterung und in den jeweiligen Cluster... Vektoren/Matrizen
    %%
    properties (GetAccess = public, SetAccess = public)
        NetzGanglinie = struct('Q',[],'Datum',[]);  % Struct die alle notwendigen Daten bereithält
        ClusterData = [];                           % ClusterData = Daten, die geclustert werden sollen. Form: 1. Spalte: Tag/Zeit, 2.-n. Spalte: Clusterdaten (z.B. die Verkehrsstärken eines Tages)
        % in der ersten Spalte stehen die Datumswerte und in den nachfolgenden Spalten die Belastungen
        % (bei Speicherproblemen, kann diese Matrix immer nur für die Clusterung erstellt und dann gleich wieder gelöscht werden)
        
        KalenderClusterung = [];                    % Kalender der die Ergebnisse der Clusterung enthält (basierend auf der Vorklassifizierung)
        
        Initialisiert = false;                      % dient als interne Prüf- und Kontrollvariable
        
        ClusterIndizes = [];                        % enthält für alle Tage (nach Kalender) eine Zurodnung zum jeweiligen Cluster (0 == Tag ohne Zähldaten => nicht geclustert)
        ClusterLinien = [];                         % enthält die mittleren Clusterganglinien aller Cluster
        ClusterDistanzen = [];                      % enthält die Abstände zwischen allen mittleren Clusterganglinien und allen Tagen
        ClusterIndexLookup = [];                    % LookUpTabelle in der Form [ClusterIndizes(i), passender Index für => ClusterLinien/ClusterDistanzen]
                                                    % z.B. ClusterIndizes = 501; Index für => ClusterLinien/ClusterDistanzen = 1 => [501, 1]
        
        SilhouetteDataClusterung = [];              % n-by-2 Matrix (n==volle Anzahl Tage), die in der ersten Spalte die ClusterNr enthält und in der
        % zweiten Spalte den silhouette-Wert enthält (dieser wird nur innerhalb jeder Vorklassifizierung berechnet)
        % Die Werte sind dabei sortiert, sodass direkt ein aussagekräftiger silhouette-plot erfolgen kann
        SilhouetteDataVorklassifizierung = [];      % Analog für die Vorklassifizierung
        
        % Parameter für den Zeitraum der Clusterung
        ZeitBeginn                                  % Matlab serial date number - Startzeitpunkt für die Clusterung, wird vom Netz übernommen
        ZeitEnde                                    % Matlab serial date number - Endzeitpunkt für die Clusterung, wird vom Netz übernommen
        Nr = 0;                                     % Nr der Clusterung, zum Suchen in der Liste/Vektor der Clusterungen im Netz
        Eigenschaften = [];
        
        % Es können beliebig viele Eigenschaften angegeben werden. Standard sind die Wochentage und die Jahreszeit (diese werden selbst generiert.)
        % Das Feld "Eigenschaften" ist eine Struct. Der Name der Felder ist der Name der Eigenschaft. Inhalt der Felder muss ein boolean - Vektor mit genau so viel Elementen, wie Zeilen von
        % ClusterData sein.
        % Z.B.:
        % Eigenschaften = struct('Montag', [true, false flase], 'Dienstag', [false, true, true], 'Schoenes_Wetter', [false, true, true], 'Viele_Hollaender', [true, false, false]);
        ClusterEigenschaften = [];
        % ParamSet - struct das die Parameter für verschiedenen Clusterverfahren enthält
        ParamSet = struct( ...
             'Methode',                 'average' ...   % Methode={'Kmeans', 'single', 'complete', 'average', 'weighted', 'median', 'ward'}
            ,'Distanzfunktion',         'GEH' ...       % Distanzfunktion={'GEH', 'Euclidean_mit_NaN'}
            ,'ClusterAnzahlAbs',        10 ...          % ClusterAnzahlAbs/ClusterAnzahlRel - legt die Anzahl der Cluster fest, wobei diese auch von der Anzahl Tage der Gruppe der Vorklassifizierung abhängt
            ,'ClusterAnzahlRel',        0.25 ...        %	   es wird der kleinere Wert aus ClusterAnzahlAbs und ClusterAnzahlRel*AnzahlTage gewählt
            ,'CutOff',                  [] ...          % CutOff - Für Methoden~=kmeans steht der Wert CutOff zur Bestimmung der Anzahl cluster zur Verfügung (ist dieser nicht [] haben ClusterAnzahlAbs/ClusterAnzahlRel keine Bedeutung
            ,'Auswahl_Startcluster',    'sample' ...    % Auswahl_Startcluster = {'sample', 'uniform', 'cluster'} - steht nur für Kmeans zur Verfügung und bestimmt die Belegung der Startcluster (siehe Matlab-Doku)
            ,'Replicates',              10 ...          % Replicates = long - steht nur für Kmeans zur Verfügung und bestimmt die Anzahl Iterationen/Wiederholungen der Clusterung um ein globales Minimum zu finden
            ,'Auswahl_Tage',            [] ...          % Auswahl_Tage = eine manuelle Auswahl an Tagen, für die geclustert werden soll (wird im Konstruktor nochmals initialisiert)
            ,'Tage_filtern',            [] ...          % Tage_filtern = zusätzlich zu "Auswahl_Tage", können Tage angegeben werden, die ausgefiltert werden sollen
            ,'flag_2412_und_3112_auch_Feiertage', false ... % Sollen der 24.12. und der 31.12. auch als Feiertage festgelegt werden?
            );        
    end
    
    %%
    methods (Access=public)
        function obj = class_Clusterung(ClusterData, ParamSet, Eigenschaften, Zusaetzliche_Eigenschaften)
        %% Konstruktor
        %  Der Konstruktor speichert ggfs. die neue Clusterung beim Netzobjekt und führt die Initialisierung durch      
        %
        %   -----------------------------------------------------------
        %       Eingänge:
        %   -----------------------------------------------------------
        %       - ClusterData   
        %           Daten, die geclustert werden sollen. Form: 1. Spalte: Tag/Zeit, 2.-n. Spalte: Clusterdaten (z.B. die Verkehrsstärken eines Tages)
        %           in der ersten Spalte stehen die Datumswerte und in den nachfolgenden Spalten die Belastungen
        %           (bei Speicherproblemen, kann diese Matrix immer nur für die Clusterung erstellt und dann gleich wieder gelöscht werden)
        %       - ParamSet
        %           struct das die Parameter für verschiedenen Clusterverfahren enthält (weiter Infos: siehe ParamSet bei den properties)
        %       - Eigenschaften
        %           Es können beliebig viele Eigenschaften angegeben werden. Standard sind die Wochentage und die Jahreszeit 
        %           (diese können selbst innerhalb der class_Clusterung generiert werden => siehe Eingang "Zusaetzliche_Eigenschaften")
        %           Das Feld "Eigenschaften" ist eine Struct. Der Name der Felder ist der Name der Eigenschaft. 
        %           Inhalt der Felder muss ein boolean - Vektor mit genau so viel Elementen, wie Zeilen von ClusterData sein.
        %           Z.B.:
        %           Eigenschaften = struct('Montag', [true, false flase], 'Dienstag', [false, true, true], 'Schoenes_Wetter', [false, true, true], 'Viele_Hollaender', [true, false, false]);
        %       - Zusaetzliche_Eigenschaften
        %           Die Einstellung ermöglich dass die Eigenschaften "Wochentag", "Feiertag" und "Ferien" automatisch (falls nicht vorhanden) hinzugefügt werden.
        %           Zusaetzliche_Eigenschaften kann entweder ein boolean Wert sein => bei true werden die Eigenschaften hinzugefügt, bei false nicht.
        %           ODER Zusaetzliche_Eigenschaften kann auch eine Struct mit den Feldern:
        %               flag_Wochentage_als_Eigenschaft
        %               flag_Wochentage_als_Eigenschaft
        %               flag_Wochentage_als_Eigenschaft
        %               Bundesland
        %           sein. Jedes Feld ist ein boolean Feld über das ausgewählt werden kann, welche Eigenschaft geladen werden soll.
        %           "Bundesland" entscheidet, für welches Bundesland die Feiertage und die Ferien ausgelesen werden.
        %           Es dürfen nur diese Kürzel für die Bundesländer als STRING eingegeben werden:
        %           Bundeslaender = {'BW', 'BY', 'BE', 'BB', 'HB', 'HH', 'HE', 'MV', 'NI', 'NW', 'RP', 'SL', 'SN', 'ST', 'SH', 'TH' }; 
        %           siehe auch "function Tag_Typen_als_Eigenschaft"
            %MyDisp('Erzeugen einer Clusterung...', true)
        
            % Check Übergabeparameter
            if nargin == 0
                return; % Zum vordimensionieren
            end
            if nargin >= 1
                obj.ClusterData = ClusterData;
            else
                error('Es müssen ClusterDaten eingehen !!!')
            end
            if nargin >= 2, obj.ParamSet = ParamSet; end
            if isempty(obj.ParamSet.Auswahl_Tage)
                obj.ParamSet.Auswahl_Tage = struct(   ...
                     'Montag',                  true ...
                    ,'Dienstag',                true ...
                    ,'Mittwoch',                true ...
                    ,'Donnerstag',              true ...
                    ,'Freitag',                 true ...
                    ,'Samstag',                 true ...
                    ,'Sonntag',                 true ...
                    ,'Werktag',                 true ...
                    ,'Ferientag',               true ...
                    ,'Feiertag',                true ...
                    ,'Brueckentag',             true ...
                    ,'Werktage_vor_Feiertag',   true ...
                    ,'Spezialtag',              true ...
                    ,'Sonstige_Tage',           true ...
                    );
            end
            if ~isfield(obj.ParamSet, 'flag_2412_und_3112_auch_Feiertage') || isempty(obj.ParamSet.flag_2412_und_3112_auch_Feiertage)
                obj.ParamSet.flag_2412_und_3112_auch_Feiertage = false;
            end
            
            
            if nargin >= 3, obj.Eigenschaften = Eigenschaften; end
            
            if nargin < 4 || isempty(Zusaetzliche_Eigenschaften)
                Zusaetzliche_Eigenschaften.flag_Wochentage_als_Eigenschaft      = true; 
                Zusaetzliche_Eigenschaften.flag_Ferien_als_Eigenschaft          = true; 
                Zusaetzliche_Eigenschaften.flag_Feiertage_als_Eigenschaft       = true; 
                Zusaetzliche_Eigenschaften.flag_Jahreszeiten_als_Eigenschaft    = false;
                Zusaetzliche_Eigenschaften.Bundesland                           = 'BW';
            else
                if isstruct(Zusaetzliche_Eigenschaften)
                    if ~isfield(Zusaetzliche_Eigenschaften, 'flag_Wochentage_als_Eigenschaft')
                        Zusaetzliche_Eigenschaften.flag_Wochentage_als_Eigenschaft      = true;
                    end
                    if ~isfield(Zusaetzliche_Eigenschaften, 'flag_Ferien_als_Eigenschaft')
                        Zusaetzliche_Eigenschaften.flag_Ferien_als_Eigenschaft          = true;
                    end
                    if ~isfield(Zusaetzliche_Eigenschaften, 'flag_Feiertage_als_Eigenschaft')
                        Zusaetzliche_Eigenschaften.flag_Feiertage_als_Eigenschaft       = true;
                    end    
                    if ~isfield(Zusaetzliche_Eigenschaften, 'flag_Jahreszeiten_als_Eigenschaft')
                        Zusaetzliche_Eigenschaften.flag_Jahreszeiten_als_Eigenschaft    = false;
                    end                        
                    if ~isfield(Zusaetzliche_Eigenschaften, 'Bundesland')
                        Zusaetzliche_Eigenschaften.Bundesland                           = 'BW';
                    end                      
                elseif Zusaetzliche_Eigenschaften % Wenn Zusaetzliche_Eigenschaften == true ODER Zusaetzliche_Eigenschaften == 1,
                    Zusaetzliche_Eigenschaften.flag_Wochentage_als_Eigenschaft      = true; 
                    Zusaetzliche_Eigenschaften.flag_Ferien_als_Eigenschaft          = true; 
                    Zusaetzliche_Eigenschaften.flag_Feiertage_als_Eigenschaft       = true;
                    Zusaetzliche_Eigenschaften.flag_Jahreszeiten_als_Eigenschaft    = false;
                    Zusaetzliche_Eigenschaften.Bundesland                           = 'BW';
                else
                    % Zusaetzliche_Eigenschaften == false ODER Zusaetzliche_Eigenschaften == 0,
                    Zusaetzliche_Eigenschaften.flag_Wochentage_als_Eigenschaft      = false; 
                    Zusaetzliche_Eigenschaften.flag_Ferien_als_Eigenschaft          = false; 
                    Zusaetzliche_Eigenschaften.flag_Feiertage_als_Eigenschaft       = false;
                    Zusaetzliche_Eigenschaften.flag_Jahreszeiten_als_Eigenschaft    = false;
                    Zusaetzliche_Eigenschaften.Bundesland                           = 'BW'; % wird eigentlich nicht benötigt.
                end
            end
            
%------------------------------------------------------------------------------------------------------------------            
%   ___         _  _    _         _  _       _                                  
%  |_ _| _ __  (_)| |_ (_)  __ _ | |(_) ___ (_)  ___  _ __  _   _  _ __    __ _ 
%   | | | '_ \ | || __|| | / _` || || |/ __|| | / _ \| '__|| | | || '_ \  / _` |
%   | | | | | || || |_ | || (_| || || |\__ \| ||  __/| |   | |_| || | | || (_| |
%  |___||_| |_||_| \__||_| \__,_||_||_||___/|_| \___||_|    \__,_||_| |_| \__, |
%                                                                         |___/      
%------------------------------------------------------------------------------------------------------------------
            obj.Initialisieren(Zusaetzliche_Eigenschaften);
            
            % ggfs. die Clusterung beim Netz speichern (also bei erfolgreicher Initialisierung)
            if obj.Initialisiert
                MyDisp(' ...erzeugen der Klasse Clusterung abgeschlossen')
            else
                MyDisp(' ...erzeugen der Klasse Clusterung nicht erfolgreich', [1 0 0])
            end
            
        end % function obj = class_Clusterung(ClusterData, ParamSet, Eigenschaften, Zusaetzliche_Eigenschaften)
        function Initialisieren(obj, Zusaetzliche_Eigenschaften)
        %% Initialisieren
        % passt die Clusterung auf geänderte Analysezeitintervalle an bzw. setzt alles zurück            
            obj.Initialisiert = false;
            
            if length(obj) ~= 1
                MyDisp('  ...Fehler! Methode funktioniert nur für einzelne Clusterungen!', [0 1 0])
            else
                MyDisp('Initialisieren der Clusterung...')
                
                % ClusterData nach der Zeit sortieren:
                sortieren_nach_Spalte = 1;
                obj.ClusterData = sortrows(obj.ClusterData, sortieren_nach_Spalte);
                
                obj.ZeitBeginn = obj.ClusterData(1,1);
                obj.ZeitEnde   = obj.ClusterData(end,1);
                Zeit_Start = obj.ClusterData(1,1);
                Zeit_Ende  = obj.ClusterData(end,1);
                
                % Kalender mit Feiertagen usw. generieren:
                if nargin >= 2 && isstruct(Zusaetzliche_Eigenschaften) && isfield(Zusaetzliche_Eigenschaften, 'Bundesland')
                    Land = Zusaetzliche_Eigenschaften.Bundesland;
                else
                    Land = 'BY'; % Bayern
                end
                MyDisp('Anlegen eines Kalenders für die Clusterung.')
                obj.KalenderClusterung = class_Kalender(Zeit_Start, Zeit_Ende, Land, [], obj.ParamSet.flag_2412_und_3112_auch_Feiertage);
                
                % Filtern der Tage:
                Namen_Tage = fieldnames(obj.ParamSet.Auswahl_Tage);
                idx_Feld_true = structfun(@any, obj.ParamSet.Auswahl_Tage);
                
                Namen_Tage_Wochentag  = Namen_Tage(1:7);
                Namen_Tage_Spezialtag = Namen_Tage(8:end);
                
                Namen_Tage_Wochentag_ausfiltern = Namen_Tage_Wochentag (~idx_Feld_true(1:7));
                Namen_Tage_Spezialtag_behalten  = Namen_Tage_Spezialtag(idx_Feld_true(8:end));
                
                % Die Tage, die ausgewählt wurden werden nicht gefiltert.
                % In die andere Richtung ist es bei den "Spezialtagen" nicht möglich, da z.B. in Brückentagen auch Werktage enthalten sind.
                % Das geht nur, wenn alle Tage mindestens einmal ein den "Spezialtagen" vorkommen !!!
                % Aus diesem Grund gibt es das Feld: "kein_Besonderer_Tag".
                % Sonst würde, wenn alle Kästchen aktiviert sind, trotzdem nicht alle Tage enthalten sein.
                idx_filter_spez = true(size(obj.ClusterData,1),1); %vordimensionieren
                
                % Ausfiltern der "Spezialtage":
                Tage_Name =     {'Werktag', 'Ferientag', 'Feiertag', 'Brueckentag', 'Werktage_vor_Feiertag', 'Spezialtag', 'Sonstige_Tage'};
                Felder_Name =   {'Werktag', 'Ferientag', 'Feiertag', 'Brueckentag', 'WerktagVorFeiertag',    'Spezialtag', 'kein_Besonderer_Tag'};
                for cnt_TN = 1 : length(Tage_Name)
                    % Wenn der Tag nicht ausgewählt wurde, werden die zutreffenden Tage auf diesen "Spezialtag" ausgefiltert.
                    if ismember(Tage_Name{cnt_TN}, Namen_Tage_Spezialtag_behalten) 
                        idx = obj.KalenderClusterung.KalenderData.(Felder_Name{cnt_TN});
                        idx_filter_spez(ismember(floor(obj.ClusterData(:,1)), obj.KalenderClusterung.KalenderData.Datum(idx))) = false;
                    end
                end

                % Bei den Wochentagen werden die Wochentage ausgefiltert, welche nicht gewählt wurden.
                % Hier ist es egal, ob Tage behalten oder ausgefiltert werden, da alle Tage enthalten sind und es keine Überschneidungen gibt.
                idx_filter_WT = false(size(obj.ClusterData,1),1); %vordimensionieren
                for cnt_NTf = 1 : length(Namen_Tage_Wochentag_ausfiltern)
                    % prüfen, was gefiltert werden muss:
                    switch Namen_Tage_Wochentag_ausfiltern{cnt_NTf}
                        case 'Montag'
                            idx_filter_WT(weekday(obj.ClusterData(:,1)) == 2) = true;
                        case 'Dienstag'
                            idx_filter_WT(weekday(obj.ClusterData(:,1)) == 3) = true;
                        case 'Mittwoch'
                            idx_filter_WT(weekday(obj.ClusterData(:,1)) == 4) = true;
                        case 'Donnerstag'
                            idx_filter_WT(weekday(obj.ClusterData(:,1)) == 5) = true;
                        case 'Freitag'
                            idx_filter_WT(weekday(obj.ClusterData(:,1)) == 6) = true;
                        case 'Samstag'
                            idx_filter_WT(weekday(obj.ClusterData(:,1)) == 7) = true;
                        case 'Sonntag'
                            idx_filter_WT(weekday(obj.ClusterData(:,1)) == 1) = true;
                    end
                end

                % Prüfen, ob bestimmte Tage nicht dabei sein sollen:
                if any(obj.ParamSet.Tage_filtern)
                    idx_filter_WT(ismember(floor(obj.ClusterData(:,1)), floor(obj.ParamSet.Tage_filtern))) = true;
                end
                
                % Filtern:
                
                idx_filter = idx_filter_WT | idx_filter_spez;
                if any(idx_filter)
                    MyDisp('ClusterData filtern aufgrund der Ausgewählten Tage.')
                    obj.ClusterData(idx_filter, :) = [];
                end
                
                % Filter auf alle eingehenden Eigenschaften anwenden:
                % Bei Eigenschaften können auch Hauptfelder existieren:
                if ~isempty(obj.Eigenschaften) && isstruct(obj.Eigenschaften)
                    % Alle Eigenschaften auf die gleiche Dimension | Ordnung muss sein :)
                    Felder_Eigenschaften = fieldnames(obj.Eigenschaften);
                    for cnt_FE = 1 : length(Felder_Eigenschaften)
                        akt_Feld = Felder_Eigenschaften{cnt_FE};
                        if isstruct(obj.Eigenschaften.(akt_Feld))
                            Unter_Felder = fieldnames(obj.Eigenschaften.(akt_Feld));
                            for cnt_UF = 1 : length(Unter_Felder)
                                akt_U_Feld = Unter_Felder{cnt_UF};
                                if size(obj.Eigenschaften.(akt_Feld).(akt_U_Feld), 1) ~= length(idx_filter)
                                    obj.Eigenschaften.(akt_Feld).(akt_U_Feld) = obj.Eigenschaften.(akt_Feld).(akt_U_Feld)(~idx_filter)';
                                else
                                    obj.Eigenschaften.(akt_Feld).(akt_U_Feld) = obj.Eigenschaften.(akt_Feld).(akt_U_Feld)(~idx_filter);
                                end
                            end
                        else % Feld ist kein Struct
                            if size(obj.Eigenschaften.(akt_Feld), 1) ~= length(~idx_filter)
                                obj.Eigenschaften.(akt_Feld) = obj.Eigenschaften.(akt_Feld)(~idx_filter)';
                            else
                                obj.Eigenschaften.(akt_Feld) = obj.Eigenschaften.(akt_Feld)(~idx_filter);
                            end
                        end
                    end
                    
                    % Falls Felder in den Eigenschaften nicht als boolean Vektoren eingehen, werden sie geändert:
                    obj = Eigenschaften_zu_boolean_Felder(obj);
                end
                
                
                if isempty(obj.ClusterData)
                    MyDisp('Keine Daten verfügbar. Es wird keine neue Clusterung angelegt.',[1 0 0])
                    return
                end
                
                
                % Vordimensionieren und ggfs. löschen aller Datenplatzhalter
                obj.SilhouetteDataClusterung            = [];
                obj.SilhouetteDataVorklassifizierung    = [];
                
                
                % MyDisp('Eigenschaften der Tage auslesen ...',true)
                
                
                
                % Tag Typen als Eigenschaft auslesen:
                obj = obj.Tag_Typen_als_Eigenschaft(Zusaetzliche_Eigenschaften);
                
                % Alle Eigenschaften als Spaltenvektoren:
                
                
                
                % ParamSet anpassen:
                if isequal(obj.ParamSet.Methode, 'Kmeans')
                    % Hier gibt es nur eine Anzahl an Clustern:
                    obj.ParamSet.CutOff = [];
                else
                    % Linkage:
                    if isempty(obj.ParamSet.CutOff)
                        % vorgegebene Zahl von Clustern (relativ oder absolut)
                    else
                        % Cutoff Kriterium
                        obj.ParamSet.ClusterAnzahlAbs = [];
                        obj.ParamSet.ClusterAnzahlRel = [];
                    end
                end
                
                
                obj.Initialisiert = true;
            end
            MyDisp(' ...initialisieren der Clusterung abgeschlossen', [0 1 0])
        end
        function obj = Tag_Typen_als_Eigenschaft(obj, Zusaetzliche_Eigenschaften)
            % Schreibt die TagTypen als Eigenschaften
            % Wenn es Felder schon gibt, wird nichts erneut gemacht.
            % Z.B. wenn es bereits ein Feld "Ferien" ODER "Schulferien" gibt, werden Ferien nicht (neu) als Eigenschaft hinzugefügt.
            Tage = floor(obj.ClusterData(:,1));
            
            flag_Wochentage_als_Eigenschaft     = Zusaetzliche_Eigenschaften.flag_Wochentage_als_Eigenschaft;
            flag_Ferien_als_Eigenschaft         = Zusaetzliche_Eigenschaften.flag_Ferien_als_Eigenschaft;
            flag_Feiertage_als_Eigenschaft      = Zusaetzliche_Eigenschaften.flag_Feiertage_als_Eigenschaft;
            flag_Jahreszeiten_als_Eigenschaft   = Zusaetzliche_Eigenschaften.flag_Jahreszeiten_als_Eigenschaft;
            
            % Wochentage:
            if isfield(obj.Eigenschaften, 'Wochentag') || isfield(obj.Eigenschaften, 'Wochentage')
                % Es gibt bereits ein Feld mit Wochentagen.
            elseif flag_Wochentage_als_Eigenschaft
                Wochentage = {'Sonntag', 'Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag'};
                num_Wochentag = weekday(Tage); % 1: Sun, 2: Mon, 3: Tue ... 7: Sat
                for cnt_W = 1 : 7
                    akt_Wochentag = Wochentage{cnt_W};
                    obj.Eigenschaften.Wochentag.(akt_Wochentag) = num_Wochentag == cnt_W;
                end
            end
            
            % Check: Tage sind eine Teilmenge der Tage des Kalenderobjektes
            if Tage(1) < obj.KalenderClusterung.Anfang || Tage(end) > obj.KalenderClusterung.Ende
                error("Datum außerhalb Kalenderzeitraum")
            end
            
            % Entsprechender Index der Clustertage in den Kalendertagen
            % Nachfolgend werden für die gewünschten Eigenschaften die
            % Zeiträume der Clusterung im Kalender identifiziert
            tage_kalender = obj.KalenderClusterung.KalenderData.Datum;
            [~, idx_tag_in_kalender] = intersect(tage_kalender, Tage);

            % Feiertage:
            if isfield(obj.Eigenschaften, 'Feiertag') || isfield(obj.Eigenschaften, 'Feiertage')
                % Es gibt bereits ein Feld mit Feiertage.
            elseif flag_Feiertage_als_Eigenschaft
                % Filtere relevante Tage aus Kalender
                obj.Eigenschaften.Feiertag = obj.KalenderClusterung.KalenderData.Feiertag(idx_tag_in_kalender)';                
                Felder_eF = fieldnames(obj.KalenderClusterung.Feiertage);
                for cnt_F = 1 : length(Felder_eF)
                    akt_Feiertag = Felder_eF{cnt_F};
                    % Überspringe Felder, die keinen einzelnen Feiertag
                    % repräsentieren
                    if strcmp(akt_Feiertag, "Feiertag") || strcmp(akt_Feiertag, "Feiertage_Name")
                        continue
                    end
                    obj.Eigenschaften.(akt_Feiertag) = obj.KalenderClusterung.Feiertage.(akt_Feiertag)(idx_tag_in_kalender);
                end
            end
            
            % Schulferien:
            if isfield(obj.Eigenschaften, 'Ferien') || isfield(obj.Eigenschaften, 'Schulferien')
                % Es gibt bereits ein Feld mit Ferien.
            elseif flag_Ferien_als_Eigenschaft
                obj.Eigenschaften.Ferien = obj.KalenderClusterung.KalenderData.Ferientag(idx_tag_in_kalender)';
                
                Felder_eF = fieldnames(obj.KalenderClusterung.Ferien);
                for cnt_F = 1 : length(Felder_eF)
                    akt_Ferien = Felder_eF{cnt_F}; 
                    
                    % Überspringe Felder, die keinen Ferientyp repräsentieren
                    if strcmp(akt_Ferien, "Ferien") || strcmp(akt_Ferien, "Ferien_Name")
                        continue
                    end
                    obj.Eigenschaften.(akt_Ferien) = obj.KalenderClusterung.Ferien.(akt_Ferien)(idx_tag_in_kalender);
                end
            end
            
            % Jahreszeiten:
            if isfield(obj.Eigenschaften, 'Jahreszeiten') || isfield(obj.Eigenschaften, 'Jahreszeit')
                % Es gibt bereits ein Feld mit Jahreszeiten.
            elseif flag_Jahreszeiten_als_Eigenschaft              
                Jahreszeiten_Bezeichnung = fieldnames(obj.KalenderClusterung.Jahreszeit);
                for cnt_JZ = 1: 4
                    akt_Jahreszeit = Jahreszeiten_Bezeichnung{cnt_JZ};
                    obj.Eigenschaften.Jahreszeit.(akt_Jahreszeit) = obj.KalenderClusterung.Jahreszeit.(akt_Jahreszeit)(idx_tag_in_kalender);
                end
            end
        end % function
        function obj = Eigenschaften_zu_boolean_Felder(obj)
            % Falls Felder in den Eigenschaften nicht als boolean Vektoren eingehen, werden sie geändert:
            
            Felder_Eig = fieldnames(obj.Eigenschaften);
            for cnt_F = 1 : length(Felder_Eig)
                akt_Feld = Felder_Eig{cnt_F};
                
                if ~islogical(obj.Eigenschaften.(akt_Feld)) && ~isstruct(obj.Eigenschaften.(akt_Feld))
                    % Das Feld muss geändert werden:
                    [Einz_Elemente, ~, idx_Zuordnung] = unique(obj.Eigenschaften.(akt_Feld));
                    
                    % Diese Feld löschen:
                    obj.Eigenschaften = rmfield(obj.Eigenschaften, akt_Feld);                    
                    
                    if isnumeric(Einz_Elemente)
                        % Wenn die Einzelnen Elemente numerisch sind, wird der Name des Feldes "akt_Feld" + "_" + Die Zahl als neue Eigenschaft verwendet.
                        Einz_Elemente = cellfun(@(x) [akt_Feld,'_',num2str(x)], num2cell(Einz_Elemente), 'UniformOutput', false);
                    end
                    
                    for cnt_EE = 1 : length(Einz_Elemente)
                        akt_Element = Einz_Elemente{cnt_EE};
                        % Ein Feld hat gewisse Anforderungen:
                        % Die Felder der Struct dürfen keine Punkte und Leerzeichen enthalten:
                        akt_Element = strrep(akt_Element, '/', '_'); % Punkte werden entfernt
                        akt_Element = strrep(akt_Element, '''', ''); % Punkte werden entfernt
                        akt_Element = strrep(akt_Element, '.', ''); % Punkte werden entfernt
                        akt_Element = strrep(akt_Element, '-', ''); % Bindestriche werden entfernt
                        akt_Element = strrep(akt_Element, ' ', '_'); % Leerzeichen werden zu Unterstrichen "_"
                        if any(strfind('0123456789', akt_Element(1)))
                            % Wenn das Feld mit einer Zahl beginnt, wird ein "i_" vorangestellt.
                            akt_Element = ['i_',akt_Element]; 
                        end
                        akt_Element = strrep(akt_Element, 'ß', 'ss');
                        akt_Element = strrep(akt_Element, 'ä', 'ae');
                        akt_Element = strrep(akt_Element, 'ö', 'oe');
                        akt_Element = strrep(akt_Element, 'ü', 'ue');
                        akt_Element = strrep(akt_Element, 'Ä', 'Ae');
                        akt_Element = strrep(akt_Element, 'Ö', 'Oe');
                        akt_Element = strrep(akt_Element, 'Ü', 'Ue');
                        
                        obj.Eigenschaften.(akt_Feld).(akt_Element) = idx_Zuordnung == cnt_EE;
                        
                    end
                    
                    
                end % if ~islogical(obj.Eigenschaften.(akt_Feld)),
            end
        end % function
        function Eigenschaften = flatten_struct(obj, Eigenschaften)
            % Verschiebt die Einträge in eventuellen Substructures auf die oberste
            % Ebene
            % Input obj wird nicht verwendet, ist als Klassenmethode
            % vorgeschrieben
            if nargin < 1 || ~isstruct(Eigenschaften)
                % warning('Keine Eigenschaften vorhanden.')
                Eigenschaften = struct();
            end
            
            Zusatz_Name = '_dummy345';
            alle_Felder = fieldnames(Eigenschaften);
            for cnt_F2 = 1 : length(alle_Felder)
                akt_Feld = alle_Felder{cnt_F2};
                % Unter Eigenschaften kann sich wiederum eine neue Struct befinden, diese müssen verändert werden:
                if isstruct(Eigenschaften.(akt_Feld))
                    Sub_Felder = fieldnames(Eigenschaften.(akt_Feld));
                    for cnt_SF = 1 : length(Sub_Felder)
                        Zusatz = '';
                        if isequal(Sub_Felder{cnt_SF}, akt_Feld)
                            Zusatz = Zusatz_Name; % Wenn die Felder gleich heißen musst erst ein dummy eingebaut werden, damit das Feld nicht überschrieben wird (und auch hinterher nicht gelöscht wird)
                        end
                        Eigenschaften.([Sub_Felder{cnt_SF},Zusatz]) = Eigenschaften.(akt_Feld).(Sub_Felder{cnt_SF});
                    end
                    Eigenschaften = rmfield(Eigenschaften, akt_Feld); % Das Hauptfeld löschen.
                end
            end
            % Die Felder mit _dummy wieder ändern:
            alle_Felder = fieldnames(Eigenschaften);
            idx_Zusatz = cellfun(@(x) any(strfind(x, Zusatz_Name)), alle_Felder);
            if any(idx_Zusatz)
                Felder_mit_Zusatz = alle_Felder(idx_Zusatz);
                FeldName_ohne_Zusatz = cellfun(@(x) strrep(x, Zusatz_Name, ''), Felder_mit_Zusatz, 'UniformOutput', false);
                for cnt_F2 = 1 : length(Felder_mit_Zusatz)
                    Eigenschaften.(FeldName_ohne_Zusatz{cnt_F2}) = Eigenschaften.(Felder_mit_Zusatz{cnt_F2});
                    Eigenschaften = rmfield(Eigenschaften, Felder_mit_Zusatz{cnt_F2}); % Altes Feld mit "Zusatz_Name" löschen.
                end
                
            end
        end
        function Clustern(obj,ParamSet)
        %% Clustern
        %  führt für alle Tagtypen der Vorklassifizierung eine Clusterung durch            
            if ~length(obj)==1
                MyDisp('  ...Fehler! Methode funktioniert nur für einzelne Clusterungen!',[1 0 0])
            elseif ~obj.Initialisiert
                MyDisp('  ...Fehler! Clusterung ist nicht initialisiert!',[1 0 0])
            elseif nargin > 2
                MyDisp('  ...Fehler! Falsche Anzahl Argumente!',[1 0 0])
            else
                if nargin == 1
                    ParamSet=obj.ParamSet;
                elseif nargin == 2
                    MyDisp('  ...Achtung! Die Verwendung eines anderen Parametersatzes als beim Erzeugen der Clusterung sorgt dafür, dass die Silhouette-Werte der Vorklassifizierung nicht mehr stimmen!',[1 0.7 0])
                    if ~isstruct(ParamSet) % ggfs. gründlichere Prüfung
                        MyDisp('  ...Fehler! Falsche Argumente!',[1 0 0])
                        return % Abbruch
                    end
                    obj.ParamSet=ParamSet;
                end
                
                MyDisp('Clusterung wird durchgeführt...')
                
                % Platzhalter löschen und vordimensioneren (zunächst auf 1000 Cluster)
                Anzahl_Tage                     = size(obj.ClusterData, 1);
                Anzahl_Daten_pro_Tag            = size(obj.ClusterData, 2) - 1;
                AktAnzahlCluster                = 0;            
                obj.ClusterIndizes              = zeros(Anzahl_Tage, 1);
                obj.ClusterLinien               = zeros(1000, Anzahl_Daten_pro_Tag);
                obj.ClusterDistanzen            = zeros(Anzahl_Tage, 1000);
                obj.ClusterIndexLookup          = zeros(300, 2);
                obj.SilhouetteDataClusterung    = [zeros(Anzahl_Tage, 1) ones(Anzahl_Tage, 1)];
                SilhouetteDataClusterungIndex   = 0;
                
                % Clusterung(en) durchführen
                % Bestimmen der Indizes der Ganglinien in der Clusterung für diesen TagTypen
                TagIndizes = true(Anzahl_Tage, 1); % Alle Tage zum Clustern auswählen
                MyDisp(['   ...Clusterung von wird berechnet (',num2str(Anzahl_Tage),'Tagen)'])
                
                if any(TagIndizes)
                    if strcmp(ParamSet.Methode, 'Kmeans')
                        Anzahl_Cluster = min(ParamSet.ClusterAnzahlAbs,ceil(length(TagIndizes)*ParamSet.ClusterAnzahlRel));
                        MyDisp('   ... Clusterungverfahren kmeans gestartet')
                        tmpClusterIndex = kmeans_adjusted(obj.ClusterData(TagIndizes,2:end)...
                            ,Anzahl_Cluster ...
                            ,'Distance',ParamSet.Distanzfunktion...
                            ,'Start',ParamSet.Auswahl_Startcluster...
                            ,'Replicates',ParamSet.Replicates ...
                            ,'EmptyAction', 'drop');
                        MyDisp('   ... Clusterungverfahren kmeans abgeschlossen.')
                        % Wenn es leere Cluster gibt, wird die Nummerierung wieder so geändert, dass sie immer von 1 bis Anzahl Cluster geht:
                        einzelneIndices = unique(tmpClusterIndex);
                        for cnt_eT = 1 : numel(einzelneIndices)
                            tmpClusterIndex(tmpClusterIndex == einzelneIndices(cnt_eT)) = cnt_eT;
                        end
                    else % KEIN kmeans sondern LINKAGE
                        if Anzahl_Tage == 1
                            % linkage funktioniert auch nur für mindestens 2 Tage !!!
                            tmpClusterIndex = 1;
                        else

                            Dist_Funktion = ParamSet.Distanzfunktion;

                            MyDisp('   ... Distanzen zwischen den einzelnen Tagen wird berechnet (kann etwas länger dauern ...)')
                            % Berechnung paarweiser Distanzen mit
                            % vorgegebener Abstandsfunktion
                            Distances = pdist(obj.ClusterData(TagIndizes,2:end), Dist_Funktion);
                            MyDisp('   ... Berechnung der Distanzen zwischen den einzelnen Tagen abgeschlossen.')
                            try
                                % Es kann in ganz außergewöhnlichen
                                % Situationen vorkommen, dass die Funktion
                                % Linage versagt 
                                % z.B. bei Variante: [15   125     4     0
                                % 19     0    17     3     6] und
                                % Vorklassifizoierung cnt_vk == 4
                                MyDisp(['   ... ',ParamSet.Methode,32,'Linkage gestartet'])
                                Linkages  = linkage(Distances, ParamSet.Methode);
                                MyDisp(['   ... ',ParamSet.Methode,32,'Linkage abgeschlossen.'])
                            catch
                                MyDisp(' Clusterung fehlgeschlagen, es muss eine andere Distanz Funktion verwendet werden (Ersatz: GEH).', [1 0.7 0])
                                Dist_Funktion = @(x,y)GEH(x,y);
                                Distances2 = pdist(obj.ClusterData(TagIndizes,2:end), Dist_Funktion);
                                Linkages  = linkage(Distances2,ParamSet.Methode);
                                MyDisp(['   ... ',ParamSet.Methode,32,'Linkage abgeschlossen.'])
                            end
                            
                            % dendrogram(Linkages, size(obj.ClusterData,1))
                            
                            % Bildung der Cluster (Auswertung des
                            % hierarchischen Clusterbaums, als Output
                            % linkage()
                            if ~isempty(ParamSet.CutOff)
                                MyDisp(['   ... Zuordnung zu Cluster wird ermittelt (CutOff:',32,ParamSet.Distanzfunktion,32,num2str(ParamSet.CutOff(1)),')'])
                                tmpClusterIndex = cluster(Linkages, 'CutOff', ParamSet.CutOff(1), 'Criterion', 'Distance');
                                MyDisp('   ... Zuordnung zu Cluster abgeschlossen.')
                            
                            else
                                Anzahl_Cluster = min(ParamSet.ClusterAnzahlAbs,ceil(length(TagIndizes)*ParamSet.ClusterAnzahlRel));
                                MyDisp(['   ... Zuordnung zu Cluster wird ermittelt (Anzahl Cluster:',32,num2str(Anzahl_Cluster),')'])
                                tmpClusterIndex = cluster(Linkages, 'MaxClust', Anzahl_Cluster, 'Criterion','Distance');
                                MyDisp('   ... Zuordnung zu Cluster abgeschlossen.')
                            end
                        end
                    end % Fallunterscheidung kmeans/linkage
                    
                    MyDisp('   ... Berechnen der ClusterLinien (Mittelwert aus den zugeordneten Tage)')
                    
                    % "Nach"berechnung von tmpClusterLines (gibt es bei kmeans zwar auch als Rückgabewert - der bei nan-Werten allerdings scheitert)
                    tmpClusterIndices = unique(tmpClusterIndex);
                    Anzahl_Cluster = length(tmpClusterIndices);
                    MyDisp(['   ...',32,num2str(Anzahl_Cluster),32,'Cluster ermittelt.'])
                    
                    tmpClusterLines = zeros(Anzahl_Cluster, Anzahl_Daten_pro_Tag);
                    for cnt_C = 1 : Anzahl_Cluster
                        idx_Zeilen_akt_Cluster = tmpClusterIndex == tmpClusterIndices(cnt_C);
                        if sum(idx_Zeilen_akt_Cluster) > 1
                            tmpGl = obj.ClusterData(idx_Zeilen_akt_Cluster, 2:end);
                            tmpGlNoNaN = tmpGl;
                            tmpGlNoNaN(isnan(tmpGl)) = 0;
                            tmpClusterLines(tmpClusterIndices(cnt_C),:) = sum(tmpGlNoNaN)./(size(tmpGl,1)-sum(isnan(tmpGl)));
                        else
                            tmpClusterLines(tmpClusterIndices(cnt_C),:) = obj.ClusterData(idx_Zeilen_akt_Cluster, 2:end);
                        end
                    end
                    MyDisp('   ... Berechnen der ClusterLinien abgeschlossen.')

                    % Berechnung der Distanzen:
                    MyDisp('   ... Berechnen der Distanzen der Tage zu den Clustern.')
                    switch lower(ParamSet.Distanzfunktion)
                        case 'geh'
                            tmpClusterDistanzen = GEH(obj.ClusterData(TagIndizes,2:end),tmpClusterLines);
                            Dist = GEH(obj.ClusterData(TagIndizes,2:end),obj.ClusterData(TagIndizes,2:end));
                        case 'euclidean_mit_nan'
                            tmpClusterDistanzen = Euclidean_mit_NaN(obj.ClusterData(TagIndizes,2:end),tmpClusterLines);
                            Dist = Euclidean_mit_NaN(obj.ClusterData(TagIndizes,2:end),obj.ClusterData(TagIndizes,2:end));
                        otherwise
                            % Bei Bedarf neue Abstandsfunktion als case
                            % einfügen 
                            errordlg('Abstandsfunktion ist unbekannt')
                    end
                    MyDisp('   ... Berechnen der Distanzen der Tage zu den Clustern abgeschlossen.')
                    
                    % Ergebnisse der aktuellen Clusterung übernehmen
                    % ClusterIndizes
                    obj.ClusterIndizes = tmpClusterIndex;
                    obj.ClusterLinien   (  AktAnzahlCluster + 1 : AktAnzahlCluster + Anzahl_Cluster,:) = tmpClusterLines;
                    obj.ClusterDistanzen(:,AktAnzahlCluster + 1 : AktAnzahlCluster + Anzahl_Cluster)   = tmpClusterDistanzen;
                    Index = (1 : Anzahl_Cluster)';
                    obj.ClusterIndexLookup = [Index, Index];
                                        
                    % ...berechnen der Silhouette-Werte
                    MyDisp('   ... Berechnen der Silhouette-Werte')
                    for i=1:length(tmpClusterIndex)
                        ClusterId = tmpClusterIndex(i);
                        if ClusterId==0 || sum(tmpClusterIndex == ClusterId) == 1
                            DistZuCluster = 0;
                        else
                            DistZuCluster  = mean(Dist(i,tmpClusterIndex==ClusterId))*sum(tmpClusterIndex==ClusterId)/(1+sum(tmpClusterIndex==ClusterId));
                        end
                        
                        AndereCluster = unique(tmpClusterIndex(tmpClusterIndex ~= ClusterId));
                        DistZuAnderen = zeros(size(AndereCluster));
                        for AndererCluster = 1 : numel(DistZuAnderen)
                            DistZuAnderen(AndererCluster) = mean(Dist(i,tmpClusterIndex==AndereCluster(AndererCluster)));
                        end
                        
                        SilhouetteDataClusterungIndex = SilhouetteDataClusterungIndex + 1;
                        obj.SilhouetteDataClusterung(SilhouetteDataClusterungIndex,1) = ClusterId;
                    end
                    MyDisp('   ... Berechnen der Silhouette-Werte abgeschlossen.')
                    
                    % Anzahl Cluster mitzählen
                    AktAnzahlCluster = AktAnzahlCluster + length(unique(tmpClusterIndex));
                end

                % Silhouette-Werte sortieren
                obj.SilhouetteDataClusterung = sortrows(obj.SilhouetteDataClusterung,[1 2]);
                
                % Überzählige Vordimensionierung abschneiden
                obj.ClusterLinien(AktAnzahlCluster+1:end,:)    = [];
                obj.ClusterDistanzen(:,AktAnzahlCluster+1:end) = [];
                
                % Eigenschaften der Cluster berechnen.
                MyDisp('   ... Berechnen der Cluster Eigenschaften')
                obj.ClusterEigenschaften = obj.ClusterEigenschaften_berechnen;                
                MyDisp('   ... Cluster Eigenschaften berechnet.')
                
                MyDisp('   ... KalenderClusterung aktualisieren')
                obj.KalenderClusterung_aktualisieren;
                MyDisp('   ... KalenderClusterung aktualisiert.')
                MyDisp('Clusterung abgeschlossen', [0 1 0])
            end
        end
        
        function obj = Cluster_Index_entfernen(obj, ClusterIndex, flag_Tage_Netzganglinie_auch_ausfiltern)
            % Entfernt Cluster mit dem Index "ClusterIndex"
            % Wenn "flag_Tage_Netzganglinie_auch_ausfiltern" = true. Werden die Tage, die die Cluster bilden auch ausgefiltern (sowohl im Kalender wie auch bei ClusterData)
            
            if nargin < 3 || isempty(flag_Tage_Netzganglinie_auch_ausfiltern), flag_Tage_Netzganglinie_auch_ausfiltern = true; end
            
            idx_Filter = ismember(obj.ClusterIndexLookup(:, 1), ClusterIndex); % Muss bleiben, da idx_Filter boolean sein muss.
            
            obj.ClusterLinien(idx_Filter, :) = [];
            obj.ClusterDistanzen(:, idx_Filter) = [];
            obj.ClusterIndexLookup(idx_Filter, :) = [];
            
            obj.ClusterEigenschaften = Struct_Felder_filtern(obj.ClusterEigenschaften, ~idx_Filter');
            
            idx_filter_Kalender = ismember(obj.KalenderClusterung.TagTypen.Nr, ClusterIndex);
            % Hier kann "Struct_Felder_filtern" nicht angewandt werden, da bei 3 Cluster, die Farben gefiltert werden würden
            obj.KalenderClusterung.TagTypen.Nr(idx_filter_Kalender) = [];
            obj.KalenderClusterung.TagTypen.AnzahlTage(idx_filter_Kalender) = [];
            obj.KalenderClusterung.TagTypen.color(idx_filter_Kalender, :) = [];
            obj.KalenderClusterung.TagTypen.TextData(idx_filter_Kalender) = [];
            
            if flag_Tage_Netzganglinie_auch_ausfiltern
                idx_filter_Tage = ismember(obj.ClusterIndizes, ClusterIndex);
                obj.ClusterData(idx_filter_Tage, :) = [];
                obj.ClusterIndizes(idx_filter_Tage, :) = [];
                obj.ClusterDistanzen(idx_filter_Tage, :) = [];
                if size(obj.SilhouetteDataClusterung, 1) == length(idx_filter_Tage)
                    obj.SilhouetteDataClusterung(idx_filter_Tage, :) = [];
                end
                obj.Eigenschaften = Struct_Felder_filtern(obj.Eigenschaften, ~idx_filter_Tage);
            else
                idx_filter_Tage = ismember(obj.ClusterIndizes, ClusterIndex);
                % obj.ClusterData(idx_filter_Tage, :) = [];
                obj.ClusterIndizes(idx_filter_Tage, :) = 0;
                % obj.ClusterDistanzen(idx_filter_Tage, :) = [];
                % obj.SilhouetteDataClusterung(idx_filter_Tage, :) = [];
                % obj.Eigenschaften = Struct_Felder_filtern(obj.Eigenschaften, ~idx_filter_Tage);                
            end
            
        end % function
        function idx_Cluster_nach_lookup = LookUp(obj, ClusterTagIndizes, flag_reverse_lookup)
            % flag_reverse_lookup == true  => Von ClusterNummer (2. Spalte) zu ClusterIndex  (1. Spalte)
            % flag_reverse_lookup == false => Von ClusterIndex  (1. Spalte) zu ClusterNummer (2. Spalte)   (Standard)
            
            if nargin < 3 || isempty(flag_reverse_lookup), flag_reverse_lookup = false; end
                
            if flag_reverse_lookup,
                [~, idx_Zeile_LookUP] = ismember(ClusterTagIndizes, obj.ClusterIndexLookup(:,2));
                idx_Cluster_nach_lookup = obj.ClusterIndexLookup(idx_Zeile_LookUP, 1);
            else
                [~, idx_Zeile_LookUP] = ismember(ClusterTagIndizes, obj.ClusterIndexLookup(:,1));
                idx_Cluster_nach_lookup = obj.ClusterIndexLookup(idx_Zeile_LookUP, 2);                
            end
            
        end % function 
        function obj = KalenderClusterung_aktualisieren(obj)
            
            AktAnzahlCluster = size(obj.ClusterLinien, 1); 
            % Clusterfarben ausrechnen
            % ClusterColor = jet(AktAnzahlCluster+1);
            ClusterColor = Lohmiller_Farben(6, AktAnzahlCluster+1);
            uniqueClusterIndizes = unique(obj.ClusterIndizes);

            % Eigenschaften aller Tage
            Eig_hier = flatten_struct(obj, obj.Eigenschaften);
            Felder_Eig = fieldnames(Eig_hier);

            % Schleife über alle Cluster
            for ClusterIndex = 1 : length(uniqueClusterIndizes)
                if uniqueClusterIndizes(ClusterIndex)~=0
                    ClusterTagIndizes = find(uniqueClusterIndizes(ClusterIndex) == obj.ClusterIndizes);
                    TagTexte = cell(1,length(ClusterTagIndizes));

                    [TagTexte{:}] = deal({['Clustergröße: ',num2str(length(TagTexte))],'Abstand zum Cl.: ','AvgQ: ','AvgQCluster: '});
                    for i = 1 : length(ClusterTagIndizes),
                        % Jeder Tag einzeln:
                        idx_Cluster_nach_lookup = obj.LookUp(obj.ClusterIndizes(ClusterTagIndizes(i)));
                        TagTexte{i}{1,2} = [TagTexte{i}{1,2},num2str(obj.ClusterDistanzen(ClusterTagIndizes(i), idx_Cluster_nach_lookup),'%0.2f')];
                        Mittlere_Verkehrsstaerke_im_Cluster = mean_ohne_nan(obj.ClusterData(ClusterTagIndizes(i), 2:end), 2);
                        TagTexte{i}{1,3} = [TagTexte{i}{1,3},num2str(round(Mittlere_Verkehrsstaerke_im_Cluster))];
                        Mittlere_Verkehrsstaerke_im_Cluster = mean_ohne_nan(mean(obj.ClusterData(ClusterTagIndizes, 2:end)), 2);
                        TagTexte{i}{1,4} = [TagTexte{i}{1,4},num2str(round(Mittlere_Verkehrsstaerke_im_Cluster))];
                        % ALLE Eigenschaften eintragen: Die Eigenschaft des einzelnen Tages UND die Eigenschaft des Clusters (C:)
                        for cnt_F = 1 : length(Felder_Eig),
                            akt_Feld = Felder_Eig{cnt_F};
                            TagTexte{i}{1, cnt_F + 5} = [akt_Feld,32, num2str(Eig_hier.(akt_Feld)(ClusterTagIndizes(i))),32,'(C:',32,num2str(obj.ClusterEigenschaften.(akt_Feld)(ClusterIndex)),')'];
                        end
                    end
                    % VorklassifizierungsNr=(uniqueClusterIndizes(ClusterIndex)-mod(uniqueClusterIndizes(ClusterIndex),100))/100;
                    obj.KalenderClusterung.TagTypenSetzen(...
                        obj.ClusterData(ClusterTagIndizes, 1)...
                        ,uniqueClusterIndizes(ClusterIndex),ClusterColor(ClusterIndex,:)...
                        ,[' Cluster: ',num2str(mod(uniqueClusterIndizes(ClusterIndex),100))]...
                        ,TagTexte) % setzt die jeweilige Gruppe
                else
                    % Beschriftung/Namen für Cluster 0 ändern
                    obj.KalenderClusterung.TagTypen.TextData{1}='Keine Daten/nicht vorklassifiziert';
                end
            end            
            
        end
        
        %% DrawEigenschaftsverteilung
        % plottet die Verteilung der Cluster auf die Wochentage in eine neue axes (wird erstellt und zurückgegeben) oder die übergebene axes
        function axHandle = DrawEigenschaft(obj, axHandle, Eigenschaft1)
            if ~length(obj) == 1
                MyDisp('  ...Fehler! Methode funktioniert nur für einzelne Clusterungen!',[1 0 0])
            else
                if isempty(obj.KalenderClusterung)
                    MyDisp('  ...es liegt keine Clusterung vor - die Ergebnisse können nicht gezeichnet werden!',[1 0 0])
                else
                    if nargin < 3 || isempty(Eigenschaft1), Eigenschaft1 = 'Wochentag'; end
                    if isfield(obj.Eigenschaften, Eigenschaft1),
                        
                        if nargin < 2 || isempty(axHandle) || ~ishandle(axHandle)
                            % ggfs. erstellen einer neuen Figure/Axes
                            figHandle = VuVFigure(figure('Paperpositionmode','Auto'));
                            axHandle = axes('parent',figHandle,'FontSize',8);
                        end
                        hold(axHandle,'on')
                        
                        % Bestimmen der Indizes der Tage in dieser Vorklassifizierung und Auslesen von Wochentagen und Clusterindizes
                        Anzahl_Tage  = size(obj.ClusterData,1);
                        ClusterIndex = obj.ClusterIndizes;
                        
                        % Daten ermitteln:
                        % OUTOUT: 
                        %   Eig_Daten: 1,2...Anzahl unterschiedlicher Eigenschaften - Vektor
                        %   Bez_Eig  : für jede Eig_Daten eine Bezeichnung (length(Bez_Eig) = Anzahl unterschiedlicher Eigenschaften)
                        if isstruct(obj.Eigenschaften.(Eigenschaft1))
                            Bez_Eig = fieldnames(obj.Eigenschaften.(Eigenschaft1));
                            Eig_Daten = zeros(Anzahl_Tage, 1); % vordimensionieren
                            for cnt_SF = 1 : length(Bez_Eig)
                                Eig_Daten = Eig_Daten + obj.Eigenschaften.(Eigenschaft1).(Bez_Eig{cnt_SF}) * cnt_SF;
                            end
                        else
                            Eig_Daten = obj.Eigenschaften.(Eigenschaft1);
                            if isnumeric(Eig_Daten)
                                % numerische Daten:
                                [Bez_num_Eig, ~, Eig_Daten] = unique(Eig_Daten);
                                Bez_Eig_Str(1:length(Bez_num_Eig)) = {Eigenschaft1};
                                Bez_Eig = cellfun(@(x,y) [x,32,num2str(y)], Bez_Eig_Str, num2cell(Bez_num_Eig), 'UniformOutput', false);
                            end
                            
                            if islogical(Eig_Daten)
                                % Wenn das Feld Eigenschaft "logical" ist, wird es in eine Zahl umgewandelt:
                                Eig_Daten = double(Eig_Daten) + 1; % +1 damit false => 1 und true => 2 (damit indiziert werden kann)
                                Bez_Eig = {[Eigenschaft1, 32, 'false'], [Eigenschaft1, 32, 'true']};
                            end
                            if iscell(Eig_Daten)
                                % Bei der Cell werden in Inhalte als Bezeichung verwendet.
                                [Bez_Eig, ~, Eig_Daten] = unique(Eig_Daten);
                            end
                        end
                        max_idx_Eigenschafen = max(Eig_Daten); 
   
                        % Schleife über alle verschiedenen Clusterindizes und zusammenzählen aller Eig_Daten der Tage mit diesem Clusterindex
                        uniClusterIndex = unique(ClusterIndex(ClusterIndex~=0));
                        plotVec = zeros(size(uniClusterIndex,2), max_idx_Eigenschafen); % vordimensionieren
                        for cnt_CI = 1  : length(uniClusterIndex)
                            plotVec(cnt_CI,:) = histc(Eig_Daten(ClusterIndex == uniClusterIndex(cnt_CI)), 1:max_idx_Eigenschafen);
                        end
                        Anzahl_Tage = sum(plotVec); % pro Eigenschaft (z.B. bei Wochentag: Montag)
                        
                        % Farben = Lohmiller_Farben(1, size(plotVec,1));
                        if size(plotVec,1) == 1
                            % Bei nur einem einzigen Cluster einen weiteren Zeilenvektor vorgaukeln (da C nicht weiter erhöht wird, wird dieser Balken mit Höhe 0 wieder übermalt)
                            h_bars = barh(axHandle, 1 : size(plotVec,1)+1, [plotVec;zeros(size(plotVec))], 'stacked');
                        else
                            % Plot von der Verteilung aller Cluster
                            h_bars = barh(axHandle, 1 : size(plotVec,1), plotVec, 'stacked');
                        end
                        % Neu und schöner einfärben:
                        Anzahl_Balken = length(h_bars);
                        if isequal(Eigenschaft1, 'Wochentag')
                            Farben = Lohmiller_Farben(12);
                        else
                            switch Anzahl_Balken
                                case 2
                                    Farben = Lohmiller_Farben(6);
                                    Farben = Farben([18,16],:); % bei false ein Rot, bei true ein grün
                                otherwise
                                    Farben = jet(length(h_bars));
                            end
                        end
                        for cnt_hb = 1 : Anzahl_Balken
                            set(h_bars(cnt_hb), 'FaceColor', Farben(cnt_hb, :), 'DisplayName', Bez_Eig{cnt_hb});
                            if Anzahl_Tage(cnt_hb) == 0,
                                % Wenn keine Tage geplottet werden, sollen diese auch nicht in der Legende vorkommen:
                                set(get(get(h_bars(cnt_hb), 'Annotation'), 'LegendInformation'), 'IconDisplayStyle','off')
                            end
                        end
                        
                        % Maximale Anzahl der Tage in einem Cluster (für die x-Achsen skalierung später)
                        maximale_x_Ausdehnung = max(sum(plotVec,2));

                        % beim ersten Mal eine Legend einfügen
                        legHandle = legend(axHandle, 'show', 'Location', 'NorthEast');
                        set(legHandle,'FontSize',8, 'Interpreter', 'none')
                        
                        % Formatieren und Beschriften
                        %                     YTickLabel = cell(1,1);
                        %                     for ClusterIndex = 2 : length(obj.KalenderClusterung.TagTypen.Nr)
                        %                         YTickLabel{ClusterIndex-1,1} = num2str(obj.KalenderClusterung.TagTypen.Nr(ClusterIndex));
                        %                     end
                        
                        %set(axHandle,'YLim', [0, C+1],'YTickLabel',YTickLabel,'YTick',1:C,'XLim',[0 max(obj.KalenderClusterung.TagTypen.AnzahlTage)*1.3])
                        set(axHandle ...
                            ,'YLim', [0, size(plotVec,1) + 1] ...
                            ,'YTickLabel', uniClusterIndex ...
                            ,'YTick',1 : size(plotVec,1) ...
                            ,'XLim',[0 maximale_x_Ausdehnung * 1.3] ...
                            ,'XTickMode', 'auto');
                        xlabel(axHandle, 'Anzahl Tage')
                        ylabel(axHandle, 'Cluster')
                        % set(legHandle,'location','NorthEast') % ...beim ersten Draw fehlen noch viele Balken, sodass die Positionierung wahrscheinlich verbesserungswürdig ist
                    else
                        % MyDisp(['  ...Fehler! Die Eigenschaft "',Eigenschaft1,'" existiert nicht!'],[1 0 0])
                        % Verteilung ohne Eigenschaft plotten:
                        Anzahl_Cluster = size(obj.ClusterLinien, 1); 
                        Anzahl_Tage_pro_Cluster = histogramm(obj.ClusterIndizes, 1:Anzahl_Cluster);
                        barh(axHandle, 1 : Anzahl_Cluster, Anzahl_Tage_pro_Cluster, 'stacked');
                        xlabel(axHandle, 'Anzahl Tage')
                        ylabel(axHandle, 'Cluster')   
                        set(axHandle ...
                            ,'XLimMode', 'auto' ...
                            ,'YLim', [0, Anzahl_Cluster + 1] ...
                            )
                        
                    end
                end
            end
        end        

        %% DrawCluster
        % plottet die mittleren Clusterganglinien oder die der einzelnen Tage in eine neue axes (wenn axHandle=[]) oder die übergebene axes
        % ClusterNr - die Nrn der Cluster (wie in KalenderClusterung.TagTypen.Nr) die geplottet werden sollen. Es können mehrere übergeben werden [...]
        % Datum     - [] oder ~[] in diesem Fall wird nur der eine (Wochen)Tag geplottet
        % MeanClusterLine   =true/False - plottet jeweils die mittlere und/oder nur die einzelnen Netzganglinien aller Tage im Cluster
        % SingleClusterLine =true/False
        function axHandle = DrawCluster(obj, axHandle, ClusterNr, Datum, MeanClusterLine, SingleClusterLine)

            if ~length(obj)==1
                MyDisp('  ...Fehler! Methode funktioniert nur für einzelne Clusterungen!',[1 0 0])
            else
                if nargin >= 4 && ~isempty(Datum)
                    ClusterNr = obj.KalenderClusterung.KalenderData.TagTypNr(obj.KalenderClusterung.KalenderData.Datum == Datum);
                    if isempty(ClusterNr)
                        MyDisp(['  ...Fehler! Der Tag ',datestr(Datum,'dd.mm.yyyy'),' ist nicht im Kalender enthalten!'],[1 0 0])
                        return
                    elseif ClusterNr==0
                        MyDisp(['  ...Fehler! Der Tag ',datestr(Datum,'dd.mm.yyyy'),' hat keine Zähldaten und wurde nicht geclustert!'],[1 0 0])
                        return
                    end
                end
                if nargin < 2 || isempty(axHandle) || ~ishandle(axHandle)
                    % ggfs. erstellen einer neuen Figure/Axes
                    figHandle=VuVFigure(figure('Paperpositionmode','Auto'));
                    axHandle=axes('parent',figHandle,'FontSize',8);
                end
                if nargin < 3 || isempty(ClusterNr),
                    % Alle Cluster:
                    ClusterNr = 1 : size(obj.ClusterLinien,1);
                end
                if nargin < 4 || isempty(MeanClusterLine), MeanClusterLine = true; end
                if nargin < 5 || isempty(SingleClusterLine), SingleClusterLine = false; end                    
                
                Cluster_Index_org   = obj.ClusterIndizes;
                alle_Cluster_NR_org = unique(Cluster_Index_org);
                alle_Cluster_NR     = obj.LookUp(alle_Cluster_NR_org);
                % alle_Cluster_NR     = obj.ClusterIndexLookup(alle_Cluster_NR_org);
                Cluster_Index       = obj.LookUp(Cluster_Index_org);
                % Cluster_Index       = obj.ClusterIndexLookup(Cluster_Index_org);
                
                Anzahl_im_Cluster = hist(Cluster_Index, alle_Cluster_NR);
                
                xlabel(axHandle,'Zählintervallnummer der Netzganglinie [-]');
                ylabel(axHandle,'Verkehrsstärke [Fz/h]');
                hold(axHandle,'on')
                set(axHandle,'XLim',[0 size(obj.ClusterData,2)-1],'YLim',[0 max(max(obj.ClusterData(:,2:end)))*1.05])
                
                MainLineWidth = 7;
                MaxAnzahlTage = max(Anzahl_im_Cluster);
                
                % Die ClusterNR, die geplottet werden sollen:
                %ClusterNr = Cluster_NR;
                
                % Farben = Lohmiller_Farben(4, length(alle_Cluster_NR));
                Farben = obj.KalenderClusterung.TagTypen.color(2:end, :); % 1 ist immer TagTyp 0
                
                LegendString = cell(1,numel(ClusterNr));
                for ClusterNrIndex = 1 : numel(ClusterNr)
                    % Tage (in NetzGanglinie, nicht in Kalender) und Farbe der ClusterNr auslesen
                    akt_Cluster_org = ClusterNr(ClusterNrIndex);
                    akt_Cluster     = obj.LookUp(akt_Cluster_org);
                    % akt_Cluster = obj.ClusterIndexLookup(akt_Cluster_org);
                    idx_Cluster = Cluster_Index == akt_Cluster;
                    akt_Anzahl_im_Cluster = Anzahl_im_Cluster(akt_Cluster);
                    
                    %TagIndizes = find(ismember([obj.NetzGanglinie.Datum],obj.KalenderClusterung.KalenderData.Datum(obj.KalenderClusterung.KalenderData.TagTypNr==akt_Cluster)));
                    ClusterColor = Farben(akt_Cluster, :);
                    
                    % ClusterLine zeichnen (also den Mittelpunkt des Clusters)
                    Tag = ['ClusterId ',num2str(akt_Cluster_org),' (n=',num2str(sum(idx_Cluster)),')'];
                    DisplayName = [Tag,32,'AvgQ: ',num2str(round(mean_ohne_nan(obj.ClusterLinien(akt_Cluster,:))))];
                    
                    LineHandle = plot(axHandle, obj.ClusterLinien(akt_Cluster, :) ...
                        ,'Color', ClusterColor ...
                        ,'Linewidth', MainLineWidth * akt_Anzahl_im_Cluster / MaxAnzahlTage ...
                        ,'UserData', akt_Cluster ...
                        ,'DisplayName',DisplayName ...
                        ,'Tag', Tag ...
                        ,'ButtonDownFcn',@(src,event) ClusterNrZeigen(src, event) ...
                        );
                    % ggfs. auf unsichtar schalten (geplottet wird die Linie immer um einen Bezug für die Legend darzustellen)
                    if ~MeanClusterLine
                        set(LineHandle,'visible','off');
                    end
                    
                    % Legend-Text erzeugen
                    LegendString{1,ClusterNrIndex} = DisplayName;
                    
                    if SingleClusterLine
                        % und ggfs. die Linien der einzelnen Tage zeichnen...
                        idx_einz_Zeilen_akt_Cluster = find(idx_Cluster);
                        for cTagIndex = 1 : length(idx_einz_Zeilen_akt_Cluster),
                            akt_Zeile = idx_einz_Zeilen_akt_Cluster(cTagIndex);
                            hLine = plot(axHandle, obj.ClusterData(akt_Zeile, 2:end) ...
                                ,'Color', ClusterColor ...
                                ,'UserData', akt_Cluster ...
                                ,'Tag',       num2str(obj.ClusterData(akt_Zeile, 1)) ...
                                ,'DisplayName', [datestr(obj.ClusterData(akt_Zeile, 1), 'ddd dd.mm.yyyy'),32,'(Cluster',32,num2str(akt_Cluster),')'] ...
                                ,'ButtonDownFcn',@(src,event) DatumZeigen(src, event) ...
                                );
                            % ...wobei diese aus der legende entfernt werden
                            set(get(get(hLine,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
                        end
                    end
                end
                
                % die Legend der neu erzeugten Linien entweder an eine bestehende Legend anfügen oder eine neue erzeugen
                tmpLegend = legend(axHandle);
                if isempty(tmpLegend) || length(get(axHandle, 'Children')) == 1, % wenn nur ein Cluster geplottet ist:
                    legHandle = legend(axHandle,LegendString,'location','best','interpreter','none');
                else
                    OldLegendString = get(tmpLegend,'string');
                    legHandle = legend(axHandle,[OldLegendString LegendString],'location','best','interpreter','none');
                end
                set(legHandle,'FontSize',8)
                
            end
            
            function DatumZeigen(src,~)
                currentPoint=get(get(src,'parent'),'CurrentPoint');
                text(currentPoint(1,1), currentPoint(1,2) ...
                    ,get(src,'DisplayName') ...
                    ,'parent', get(src,'parent') ...
                    ,'ButtonDownFcn',@(src,event) delete(src) ...
                    ,'BackgroundColor',[.95 .95 .95] ...
                    );
            end
            function ClusterNrZeigen(src,~)
                currentPoint = get(get(src,'parent'),'CurrentPoint');
                text(currentPoint(1,1),currentPoint(1,2) ...
                    ,get(src,'tag') ...
                    ,'parent', get(src,'parent') ...
                    ,'ButtonDownFcn',@(src,event) delete(src) ...
                    ,'BackgroundColor',[.95 .95 .95] ...
                    );
            end            
            
        end
        %% DrawSilhouette
        % plottet die DrawSilhouette-Werte der Vorklassifizieruung und ggfs. der Clusterung in eine neue figure (wird erstellt und zurückgegeben) oder die übergebene figure
        function figHandle = DrawSilhouette(obj,figHandle)
            % ggfs. erstellen einer neuen Figure
            if nargin<2 || isempty(figHandle) || ~ishandle(figHandle)
                figHandle=VuVFigure(figure);
            end
            
            % alte Axes löschen und neue anlegen
            set(figHandle,'tag','silhouette')
            delete(get(figHandle,'children'))

            axHandle = gca;
            hold(axHandle,'on');
            ylabel(axHandle,'Cluster')
            title(axHandle,'Clusterung')
            
            if isempty(obj.SilhouetteDataClusterung)
                text(0.5,0.5,sprintf('Clusterung ist noch\nnicht durchgeführt'),'Parent',axHandle,'HorizontalAlignment','Center');
                set(axHandle,'XTick',[],'YTick',[])
                return
            end
            

            % passendes Auslesen der Daten
            GroupVec = obj.SilhouetteDataClusterung(:,1);
            SilhouetteVec=obj.SilhouetteDataClusterung(:,2);
            
                % Bestimmen der jeweiligen Cluster/Tagtypen...
                uniqueGroupVec = unique(GroupVec);
                idx_TagTyp = ismember(obj.KalenderClusterung.TagTypen.Nr, uniqueGroupVec);
                Farben = obj.KalenderClusterung.TagTypen.color(idx_TagTyp, :);
                
                BarStartPosition = 0;
                LabelPosition = zeros(size(uniqueGroupVec));
                LabelString = cell(size(uniqueGroupVec));
                barHandles = zeros(size(uniqueGroupVec));
                % ...und zeichnen aller Cluster/Tagtypen
                for CurrentGroup = 1 : numel(uniqueGroupVec)
                    if uniqueGroupVec(CurrentGroup)~=0 % für Tage ohne Zähldaten wird kein silhouette-Wert gezeichnet (dieser ist per Definition ohnehin 1)
                        y=SilhouetteVec(GroupVec==uniqueGroupVec(CurrentGroup));
                        x=BarStartPosition+1:BarStartPosition+sum(GroupVec==uniqueGroupVec(CurrentGroup));
                        barHandles(CurrentGroup)=barh(axHandle,x,y,'edgecolor','none','barwidth',1,'FaceColor',Farben(CurrentGroup,:));
                        
                        LabelPosition(CurrentGroup)=(BarStartPosition*2+1+sum(GroupVec==uniqueGroupVec(CurrentGroup)))/2;
                        LabelString{CurrentGroup}=num2str(uniqueGroupVec(CurrentGroup));
                        
                        BarStartPosition=5+BarStartPosition+sum(GroupVec==uniqueGroupVec(CurrentGroup));
                        
                        % zwischen den Vorklassifizierungsgruppen wird für die Cluster-Silhouette-Werte eine Trennlinien gezogen
                        if CurrentGroup<numel(uniqueGroupVec) && floor(uniqueGroupVec(CurrentGroup)/100)<floor(uniqueGroupVec(CurrentGroup+1)/100)
                            plot(axHandle,[-0.9 0.9],[BarStartPosition-2.5 BarStartPosition-2.5],'k','linewidth',0.5)
                        end
                    end
                end
                set(axHandle,'YTick',LabelPosition,'YTickLabel',LabelString,'XLim',[-1 1])
                xlabel(axHandle,'Silhouette-Wert')
                
        end
  
        %% Eigenschaften der Cluster:
        % Berechnet die Eigenschaften der Clusterergebnisse im Bezug auf Kalender, Wetter, Unfälle, Qualität & Baustellen
        function ClusterEigenschaften = ClusterEigenschaften_berechnen(obj)
            if isstruct(obj.Eigenschaften)
                % Nur die ClusterIndizes ohne 0:
                % Damit hat ClusterIndex die gleiche Dimension wie die Felder in "obj.Eigenschaften"
                ClusterIndex = obj.ClusterIndizes(obj.ClusterIndizes ~= 0);
                einzelne_ClusterIndex = unique(ClusterIndex);
                
                for cnt_ClusterIndex = 1 : length(einzelne_ClusterIndex)
                    % Die Zeilen (Tage) mit dem aktuellen Cluster:
                    idx_Cluster = ClusterIndex == einzelne_ClusterIndex(cnt_ClusterIndex);
                    
                    % ClusterIndex eintragen:
                    ClusterEigenschaften.ClusterIndex(cnt_ClusterIndex) = einzelne_ClusterIndex(cnt_ClusterIndex);
                    ClusterEigenschaften.AnzahlTage(cnt_ClusterIndex)   = sum(idx_Cluster);
                    
                    alle_Felder = fieldnames(obj.Eigenschaften);
                    % Feld Datum raus nehmen:
                    alle_Felder(cellfun(@any, strfind(alle_Felder, 'Datum'))) = [];
                    
                    for cnt_F = 1 : length(alle_Felder)
                        akt_Feld = alle_Felder{cnt_F};
                        % Unter Eigenschaften kann sich wiederum eine neue Struct befinden:
                        if isstruct(obj.Eigenschaften.(akt_Feld))
                            Sub_Felder = fieldnames(obj.Eigenschaften.(akt_Feld));
                            for cnt_SF = 1 : length(Sub_Felder)
                                ClusterEigenschaften.(Sub_Felder{cnt_SF})(cnt_ClusterIndex) = mean(obj.Eigenschaften.(akt_Feld).(Sub_Felder{cnt_SF})(idx_Cluster));
                            end
                        else
                            ClusterEigenschaften.(akt_Feld)(cnt_ClusterIndex) = mean(obj.Eigenschaften.(akt_Feld)(idx_Cluster));
                        end
                    end
                end % for cnt_ClusterIndex = 1 : length(einzelne_ClusterIndex),
                
                
            else
                ClusterEigenschaften = [];
            end % if isstruct(obj.Eigenschaften) && isfield(obj.Eigenschaften, 'Datum'),
            
        end % function ClusterEigenschaften(obj)
       
%         function [CELL, Spaltenbeschriftung, Zeilenbeschriftung] = get_Eigenschaften_Tage_eines_Clusters(obj, ClusterIndex, Felder, flag_nur_Felder_mit_ungleichen_Eigenschaften)
%             % ClusterIndex: Nummer der ClusterIndex, die untersucht werden sollen.
%             % Felder:       Namen der Eigenschaften, die zurückgegeben werden sollen.
%             %
%             if nargin < 2 || isempty(ClusterIndex), ClusterIndex = obj.ClusterIndexLookup(:,1); end
%             if nargin < 4 || isempty(flag_nur_Felder_mit_ungleichen_Eigenschaften), flag_nur_Felder_mit_ungleichen_Eigenschaften = false; end
%             
%             ClusterNummer = obj.LookUp(ClusterIndex);
%             
%             Eigenschaften_Tage = flatten_struct(obj, obj.Eigenschaften);
%             Eigenschaften_Cluster = obj.ClusterEigenschaften;
%             
%             if nargin >= 3 && ~isempty(Felder)
%                 Felder_Eig = fieldnames(Eigenschaften_Tage);
%                 Felder_filtern = Felder_Eig(~ismember(Felder_Eig, Felder));
%                 Eigenschaften_Tage      = rmfield(Eigenschaften_Tage,       Felder_filtern);
%                 Eigenschaften_Cluster   = rmfield(Eigenschaften_Cluster,    Felder_filtern); % hier bleiben die Felder ClusterIndex und Anzahl Tage erhalten.
%             end
%             
%             ScrSize = get(0,'ScreenSize');
%             Position_figure = [20, ScrSize(4)/2 - 200, ScrSize(3) - 40, 400];
%             
%             CELL                = cell(1, length(ClusterNummer)); % vordimensionieren
%             Spaltenbeschriftung = cell(1, length(ClusterNummer)); % vordimensionieren
%             Zeilenbeschriftung  = cell(1, length(ClusterNummer)); % vordimensionieren
%             for cnt_CN = 1 : length(ClusterNummer)
%                 
%                 % Tage des Clusters:
%                 idx_Tage = obj.ClusterIndizes == ClusterIndex(cnt_CN);
%                 Anzahl_Tage_im_Cluster = sum(idx_Tage);
%                 Eig_akt_Tage_Cluster = Struct_Felder_filtern(Eigenschaften_Tage, idx_Tage);
%                 Eig_akt_Tage_Cluster.ClusterIndex = nan(Anzahl_Tage_im_Cluster, 1); % vordimensionieren
%                 Eig_akt_Tage_Cluster.AnzahlTage   = nan(Anzahl_Tage_im_Cluster, 1); % vordimensionieren
%                 
%                 % Eigenschaften des Clusters:
%                 idx_akt_Cluster = obj.ClusterIndexLookup(:,1) == ClusterIndex(cnt_CN);
%                 Eig_akt_Cluster = Struct_Felder_filtern(Eigenschaften_Cluster, idx_akt_Cluster);
%                 
%                 % Eine Cell zusammenbauen:
%                 Alle_Felder = fieldnames(Eig_akt_Cluster);
%                 Spaltenbeschriftung{cnt_CN} = ['GEH zum Cluster', Alle_Felder'];
%                 Tage_Cell = cellstr(datestr(obj.ClusterData(idx_Tage,1), 'dd.mm.yyyy'));
%                 Zeilenbeschriftung{cnt_CN}(2:Anzahl_Tage_im_Cluster + 1) = Tage_Cell;
%                 Zeilenbeschriftung{cnt_CN}{1} = 'Cluster'; 
%                 
%                 CELL{cnt_CN} = nan(Anzahl_Tage_im_Cluster + 1, length(Alle_Felder) + 1); % vordimensionieren
%                 for cnt_F = 2 : length(Alle_Felder) + 1
%                     akt_Feld = Alle_Felder{cnt_F - 1};
%                     CELL{cnt_CN}(1, cnt_F) = Eig_akt_Cluster.(akt_Feld);
%                     CELL{cnt_CN}(2:end, cnt_F) = Eig_akt_Tage_Cluster.(akt_Feld);
%                 end
%                 % GEH zum Cluster:
%                 GEH_Tage_zum_Cluster = obj.ClusterDistanzen(idx_Tage, ClusterNummer);
%                 CELL{cnt_CN}(:, 1) = [nan; GEH_Tage_zum_Cluster]; % nan, da keine Distanz von Cluster zu sich selbst gibt
%                 
%                 
%                 % Felder, wo das Cluster und alle Tage identisch sind werden weggelassen
%                 if flag_nur_Felder_mit_ungleichen_Eigenschaften
%                     warning('flag_nur_Felder_mit_ungleichen_Eigenschaften ist noch nicht umgesetzt.')
%                 end
%                 
%             end
%         end            
        
        %% EXPORT ClusterData
        % Gibt die Eingangsdaten weiter
        function Export_ClusterData(obj, Dateiname, flag_mat, flag_xls, flag_csv, Zeit_Format)
            if nargin < 2 || isempty(Dateiname), Dateiname = 'Export_Clusterung_Input'; end
            if nargin < 2 || isempty(flag_mat),  flag_mat = false; end
            if nargin < 3 || isempty(flag_xls),  flag_xls =  true; end
            if nargin < 4 || isempty(flag_csv),  flag_csv = false; end
            if nargin < 5 || isempty(Zeit_Format),  Zeit_Format = 'unix'; end
            
            if length(obj) > 1
                warning('Export wird nur für ein obj unterstützt.');
                obj = obj(1);
            end
            
            if flag_mat
                % Export in eine *.mat Datei
                ClusterData1 = obj.ClusterData;
                save(Dateiname, ClusterData1);
            end
            
            if flag_xls || flag_csv
                % Export in eine Excel Datei UND/ODER csv
                ClusterData1 = num2cell(obj.ClusterData);
                if isequal(lower(Zeit_Format), 'unix')
                    ClusterData1(:,1) = num2cell(unix_Zeit(cell2mat(ClusterData1(:,1))));
                else
                    ClusterData1(:,1) = cellfun(@(x) datestr(x, Zeit_Format), ClusterData1(:,1), 'UniformOutput', false);
                end
                
                if flag_xls
                    % Excel
                    Sheet_Name = {'Daten_von_Matlab'};
                    Cell2Excel( ClusterData1, Dateiname, Sheet_Name );
                end
                
                if flag_csv
                    Trennzeichen = ','; Spalte_mit_Zeit = []; Zeit_Format = [];
                    Cell2csv( ClusterData1, Dateiname, Trennzeichen, Spalte_mit_Zeit, Zeit_Format );
                end
                
            end
            
            MyDisp(['ClusterExport nach',32,Dateiname,32,'erfolgreich exportiert.'],[1 0 0])
        end
        function Export_Clusterungsergebnis(obj, Dateiname, flag_mat, flag_xls, flag_csv, Zeit_Format)
            if nargin < 2 || isempty(Dateiname),    Dateiname = 'Export_Clusterung'; end
            if nargin < 3 || isempty(flag_mat),     flag_mat = false; end
            if nargin < 4 || isempty(flag_xls),     flag_xls =  true; end
            if nargin < 5 || isempty(flag_csv),     flag_csv = false; end
            if nargin < 6 || isempty(Zeit_Format),  Zeit_Format = 'dd.mm.yyyy'; end
            
            if length(obj) > 1
                warning('Export wird nur für ein obj unterstützt.');
                obj = obj(1);
            end
            
            % Prüfen, ob die Clusterung bereits ausgeführt wurde:
            if isempty(obj.ClusterIndizes)
                % Clusterung wurde noch nicht ausgeführt:
                obj.Export_ClusterData(Dateiname, flag_mat, flag_xls, flag_csv, Zeit_Format);
                return
            end
            
            
            if flag_mat
                % Export in eine *.mat Datei
                OUTPUT_Clusterung = struct(  'ClusterLinien', obj.ClusterLinien ...
                    ,'ClusterIndex', obj.ClusterIndizes(obj.ClusterIndizes ~= 0) ...
                    ,'ClusterData', obj.ClusterData ...
                    ,'Eigenschaften', obj.ClusterEigenschaften ...
                    );
                save(Dateiname, OUTPUT_Clusterung);
            end
            
            
            if flag_xls || flag_csv
                % Export in eine Excel Datei UND/ODER csv
                
                % ClusterData:
                ClusterData_cell = cell(size(obj.ClusterData,1) + 1, size(obj.ClusterData,2) + 1);
                ClusterData_cell(1,1:2) = {'Zeit', 'ClusterIndex'};
                
                ClusterData_cell(2:end,3:end) = num2cell(obj.ClusterData(:,2:end));
                if isequal(lower(Zeit_Format), 'unix')
                    ClusterData_cell(2:end,1) = num2cell(unix_Zeit(obj.ClusterData(:,1)));
                else
                    ClusterData_cell(2:end,1) = cellstr(datestr(obj.ClusterData(:,1), Zeit_Format));
                end
                ClusterData_cell(2:end,2) = num2cell(obj.ClusterIndizes(obj.ClusterIndizes ~= 0));
                
                % ClusterLinien:
                ClusterLinien_cell = cell(size(obj.ClusterLinien,1) + 1, size(obj.ClusterLinien,2) + 1);
                ClusterLinien_cell{1,1} = 'ClusterIndex';
                ClusterLinien_cell(2:end,2:end) = num2cell(obj.ClusterLinien);
                ClusterLinien_cell(2:end,1) = num2cell(sort(unique(obj.ClusterIndizes(obj.ClusterIndizes ~= 0))));
                
                % Eigenschaften:
                Felder_Eigenschaften = fieldnames(obj.ClusterEigenschaften);
                Eigenschaften_cell = cell(numel(obj.ClusterEigenschaften.(Felder_Eigenschaften{1})) + 1, length(Felder_Eigenschaften)); % vordimensionieren.
                for cnt_F = 1 : length(Felder_Eigenschaften)
                    Eigenschaften_cell{1, cnt_F}     = Felder_Eigenschaften{cnt_F};
                    Eigenschaften_cell(2:end, cnt_F) = num2cell(obj.ClusterEigenschaften.(Felder_Eigenschaften{cnt_F}));
                end
                
                % Eigenschaften der einzelnen Tage:
                Felder_Eigenschaften = fieldnames(obj.ClusterEigenschaften); Felder_Eigenschaften{1} = 'Datum'; Felder_Eigenschaften{2} = 'ClusterIndex';
                Eigenschaften1 = flatten_struct(obj, obj.Eigenschaften);
                Felder_Eig1 = fieldnames(Eigenschaften1);
                Anzahl_Tage = size(obj.ClusterData,1);
                Eigenschaften_cell_Tage = cell(Anzahl_Tage + 1, length(Felder_Eigenschaften)); % vordimensionieren.
                Eigenschaften_cell_Tage{1, 1}     = Felder_Eigenschaften{1}; % Datum
                if isequal(lower(Zeit_Format), 'unix')
                    Eigenschaften_cell_Tage(2:end, 1) = num2cell(unix_Zeit(obj.ClusterData(:,1)));
                else
                    Eigenschaften_cell_Tage(2:end, 1) = cellstr(datestr(obj.ClusterData(:,1), Zeit_Format));
                end                
                Eigenschaften_cell_Tage{1, 2}     = Felder_Eigenschaften{2}; % ClusterIndex
                Eigenschaften_cell_Tage(2:end, 2) = num2cell(obj.ClusterIndizes);
                for cnt_F = 3 : length(Felder_Eigenschaften)
                    Eigenschaften_cell_Tage{1, cnt_F}     = Felder_Eigenschaften{cnt_F};
                    idx = ismember(Felder_Eig1, Felder_Eigenschaften{cnt_F});
                    Eigenschaften_cell_Tage(2:end, cnt_F) = num2cell(double(Eigenschaften1.(Felder_Eig1{idx})));
                end                
                
                if flag_xls
                    % Excel
                    Sheet_Name = {'ClusterLinien', 'ClusterData', 'Eigenschaften', 'Eigenschaften_ClusterData'};
                    Cell2Excel( {ClusterLinien_cell, ClusterData_cell, Eigenschaften_cell, Eigenschaften_cell_Tage}, Dateiname, Sheet_Name );
                end
                
                if flag_csv
                    Trennzeichen = ','; Spalte_mit_Zeit = []; Zeit_Format = [];
                    Cell2csv( ClusterLinien_cell, Dateiname, Trennzeichen, Spalte_mit_Zeit, Zeit_Format );
                end
                
            end
            
            MyDisp(['Clusterungsergebnis-Export nach',32,Dateiname,32,'erfolgreich exportiert.'],[0 1 0])        
        end
        
        function Schoene_plots_fuer_PP(obj, flag_Cluster, flag_Input_Daten, ClusterNr, Intervallgroesse)
            if length(obj) > 1,
                obj = obj(1);
            end
            if nargin < 2 || isempty(flag_Cluster),     flag_Cluster     = true; end
            if nargin < 3 || isempty(flag_Input_Daten), flag_Input_Daten = true; end
            if nargin < 4 || isempty(ClusterNr)
                % Alle Cluster:
                ClusterNr = 1 : size(obj.ClusterLinien,1);
            end
            if nargin < 5 || isempty(Intervallgroesse), Intervallgroesse = 60; end % in Minuten [min]
            
            
            function schoener_PLot
                figure('Position', [200 200 800 600]); h_axes_Cluster = gca;
                Datum = []; % wird nicht benötigt.
                h_axes_Cluster = obj.DrawCluster(h_axes_Cluster, ClusterNr, Datum, MeanClusterLine, SingleClusterLine);
                legend off
                set(gca, 'YLimMode', 'auto'); set(gca, 'YTickMode', 'auto');            
                
                % Umformatieren:
                Einz_Linien = get(h_axes_Cluster, 'Children');
                %set(Einz_Linien, 'ButtonDownFcn', []) % Button Down Function ("Datum anzeigen") raus nehmen.
                set(h_axes_Cluster, 'UserData', Einz_Linien)
                
                % Das folgende geht nur, wenn 60 Minuten Intervall gewählt wurden.
                flag_Stundenintervall = false;
                if flag_Stundenintervall,
                    % Bei mehreren Detektoren (Netzganglinie):
                    Anzahl_Intervalle_pro_Tag = size(obj.ClusterData,2) - 1; % -1 da die erste Spalte das Datum enthält.
                    Anzahl_Detektoren = round(Anzahl_Intervalle_pro_Tag / (24/(Intervallgroesse/60)));
                    if Anzahl_Detektoren > 1,
                        for cnt_D = 1 : (Anzahl_Detektoren - 1),
                            akt_Grenze_D = (Anzahl_Intervalle_pro_Tag / Anzahl_Detektoren) * cnt_D;
                            hLine = plot([akt_Grenze_D akt_Grenze_D] ,get(gca, 'YLim') ...
                                ,'Color', 'black' ...
                                ,'LineWidth', 1.5 ...
                                ,'LineStyle', '--' ...
                                ,'Tag', 'Grid');
                            set(get(get(hLine,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
                        end
                        ES.flag_x_Achse = false;
                        grid_manuell( ES );
                        
                        Anzahl_Intervalle_pro_Detektor = Anzahl_Intervalle_pro_Tag / Anzahl_Detektoren;
                        set(gca, 'XTick', Anzahl_Intervalle_pro_Detektor/2 : Anzahl_Intervalle_pro_Detektor : Anzahl_Intervalle_pro_Tag)
                        XTICKLABEL = cell(1, Anzahl_Detektoren); % vordimensionieren
                        for cnt_D = 1 : Anzahl_Detektoren,
                            XTICKLABEL{cnt_D} = ['Det. #',num2str(cnt_D)];
                        end
                        set(gca, 'XTickLabel', XTICKLABEL)
                        ES_LSpF.text_xlabel_str = '';
                    else
                        % Tageszeit anzeigen:
                        set(gca, 'XTick', 0:3:24)
                        set(gca, 'XTickLabel', {'00:00', '03:00', '06:00', '09:00', '12:00', '15:00', '18:00', '21:00', '24:00'})
                        ES_LSpF.text_xlabel_str = 'Tageszeit';
                    end
                end
                
                ES_LSpF.text_ylabel_str = 'Verkehrsstärke [Kfz/h]';
                ES_LSpF.datetick_format = false;
                ES_LSpF.handle_axes     = gca;
                ES_LSpF.flag_keeplimits = true;
                Lohmiller_Standard_plot_Format( ES_LSpF )
                if flag_Stundenintervall && Anzahl_Detektoren > 1, grid off, end
                    
                legend show
                
            end
            
            % ----------------------------------------------------------------------------------------------------------
            % Plottet die ClusterLinien:
            % ----------------------------------------------------------------------------------------------------------
            if flag_Cluster % Plottet die ClusterLinien:
                MeanClusterLine = true;
                SingleClusterLine = false;
                schoener_PLot;
            end
            
            % ----------------------------------------------------------------------------------------------------------
            % Plottet die Input-Ganglinien:
            % ----------------------------------------------------------------------------------------------------------
            if flag_Input_Daten % Plottet die Input-Ganglinien:
                MeanClusterLine = false;
                SingleClusterLine = true;
                schoener_PLot;
            end            
            
            
        end % function
        function Schoene_plots_fuer_PP_Eigenschaften(obj, Eigenschaft1)
            if nargin < 2 || isempty(Eigenschaft1), Eigenschaft1 = 'Wochentag'; end
            figure('Position', [200 200 800 600]); h_axes = gca;
            h_axes = obj.DrawEigenschaft(h_axes, Eigenschaft1);
            legend off
            
            ES_LSpF.text_xlabel_str = 'Anzahl Tage';
            ES_LSpF.text_ylabel_str = 'Cluster';
            ES_LSpF.datetick_format = false;
            ES_LSpF.handle_axes     = gca;
            ES_LSpF.flag_keeplimits = true;
            Lohmiller_Standard_plot_Format( ES_LSpF )
            
            set(h_axes, 'XLimMode', 'auto'); set(h_axes, 'XTickMode', 'auto');       
            legend(h_axes, 'Location', 'best')
            box on
            
        end
        
        function plot_Stat_Tagesgang(obj, ClusterIndex)
            
            curr_dir=cd; cd .., path(path,[cd '\m-files']), cd(curr_dir)
            if length(obj) > 1, warning('Es wird nur ein obj unterstützt. Es wird das erste obj verwendet.'), obj = obj(1); end
            if nargin < 2 || isempty(ClusterIndex), ClusterIndex = obj.ClusterIndexLookup(1,1); end
            
            for cnt_CI = 1 : length(ClusterIndex)
                figure('Position', [200 200 800 600])
                idx_akt_Index = obj.ClusterIndizes == ClusterIndex(cnt_CI);
                
                Akt_Data = obj.ClusterData(idx_akt_Index, 2:end);
                Anzahl_Spalten = size(Akt_Data, 2);
                WerteVerteilung = cell(1, Anzahl_Spalten); % vordimensionieren
                for cnt_S = 1 : Anzahl_Spalten
                    WerteVerteilung{cnt_S} = Akt_Data(:, cnt_S);
                end
                xWerte = 0 : 1/Anzahl_Spalten : (1 - 1/Anzahl_Spalten); 
                plot_Stat_Verteilung(WerteVerteilung, xWerte);
                
                text_xlabel_str = 'Tageszeit';
                text_ylabel_str = 'Verkehrsstärke';
                text_title_str  = [];
                flag_x_datetick = [];
                datetick_format = [];
                font_size       = [];
                handle_axes     = [];
                flag_keeplimits = [];
                Lohmiller_Standard_plot_Format( text_xlabel_str, text_ylabel_str, text_title_str , flag_x_datetick, datetick_format, font_size, handle_axes, flag_keeplimits)
                
            end
            
            
            
            
            
            
        end % function 
        
        % Clusterungen zusammenfassen:
%         function Clusterung_ALLE = Mehrere_Clusterungen_Zusammenfassen(obj)
%             
% %             % Prüfen, ob eine Clusterung leer ist:
% %             idx_leere_Clusterung = cellfun(@isempty, {obj.ClusterLinien});
% %             obj(idx_leere_Clusterung) = [];
%             
%             Clusterung_ALLE                 = class_Clusterung; % leeres Cluster
%             
%             if ~isempty(obj),
%             
%             Clusterung_ALLE.ParamSet        = obj(1).ParamSet; % Die sind für alle VK gleich.
%             Clusterung_ALLE.Initialisiert   = 1;
%             
%             ClusterData12 = vertcat(obj.ClusterData);
%             [~, idx_sort] = sort(ClusterData12(:,1));
%             Clusterung_ALLE.ClusterData     = ClusterData12(idx_sort, :);
%             Clusterung_ALLE.ZeitBeginn      = Clusterung_ALLE.ClusterData(1,1);
%             Clusterung_ALLE.ZeitEnde        = Clusterung_ALLE.ClusterData(end,1);
%             Clusterung_ALLE.Nr              = 1;
%             Clusterung_ALLE.ClusterLinien   = vertcat(obj.ClusterLinien); % alle Clusterlinien aus allen Clustern.
%             
%             for cnt_C = 1 : length(obj),
%                 obj(cnt_C).Nr = obj(cnt_C).ClusterIndizes + 1000 * cnt_C;
%             end
%             ALLE_ClusterIndizes = vertcat(obj.Nr);
%             [obj.Nr] = deal(0);
%             Clusterung_ALLE.ClusterIndizes  = ALLE_ClusterIndizes(idx_sort); % vordimensionieren
%             
%             % Alle Eigenschaften zusammenpacken:
%             for cnt_C = length(obj) : -1 : 1,
%                 if ~isempty(obj(cnt_C).Eigenschaften),
%                     Eigenschaften_Struct(cnt_C)         = obj(cnt_C).Eigenschaften;
%                     ClusterEigenschaften_Struct(cnt_C)  = obj(cnt_C).ClusterEigenschaften;
%                 end
%             end
%             % Leere UnterStructs müssen mit den Feldern aufgefüllt werden:
%             
%             Clusterung_ALLE.Eigenschaften           = Struct_mehrdimensional_zu_eindimensional(Eigenschaften_Struct);
%             Clusterung_ALLE.ClusterEigenschaften    = Struct_mehrdimensional_zu_eindimensional(ClusterEigenschaften_Struct);  
%             Clusterung_ALLE.ClusterEigenschaften    = Struct_Felder_als_Spaltenvektoren(Clusterung_ALLE.ClusterEigenschaften);
%             
%             % Alle Eigenschaften sortieren (ClusterEigenschaften müssen nicht sortiert werden):
%             Clusterung_ALLE.Eigenschaften = Struct_Felder_filtern(Clusterung_ALLE.Eigenschaften, idx_sort);
%             
%             % ClusterIndexLookup
%             einz_ClusterIndex = unique(ALLE_ClusterIndizes);
%             Clusterung_ALLE.ClusterIndexLookup = [einz_ClusterIndex, (1:length(einz_ClusterIndex))'];
%             
%             % Zusätzlich müssen die "ClusterIndex" in den ClusterEigenschaften angepasst werden:
%             Clusterung_ALLE.ClusterEigenschaften.ClusterIndex = einz_ClusterIndex;  
%             
%             % ClusterDistanzen:
%             Clusterung_ALLE = Clusterung_ALLE.ClusterDistanzen_berechnen;
%             
%             
%             % Kalender Clusterung
%             Land = 'BY';
%             flag_2412_und_3112_auch_Feiertage = Clusterung_ALLE.ParamSet.flag_2412_und_3112_auch_Feiertage;
%             Clusterung_ALLE.KalenderClusterung = class_Kalender(Clusterung_ALLE.ZeitBeginn, Clusterung_ALLE.ZeitEnde, Land, [], flag_2412_und_3112_auch_Feiertage);
%             Clusterung_ALLE.KalenderClusterung.TagTypen.Kategorien = {'Benutzerdefiniert'}; % hat keine Bedeutung, aber sonst steht "Werktag" da, was nicht stimmt.
%             Clusterung_ALLE = Clusterung_ALLE.KalenderClusterung_aktualisieren;
%             
%             end
%             
%         end
    end
end



















