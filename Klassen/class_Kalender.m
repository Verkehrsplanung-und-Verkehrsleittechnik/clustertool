%% class_Kalender
classdef class_Kalender < handle
    % Klasse die Kalenderdaten verwaltet und darstellt (zur Darstellung der Clusterung und Vorklassifizierung geeignet)
    %%
    properties (GetAccess=public,SetAccess=public)
        % TagTypen - struct die die verschiedenen TagTypen/Cluster auflistet
        % (ist bevorzugt aber über die jeweiligen Methoden zu manipulieren/setzen)
        %    Kategorien     Beschreibungstext der Zusammenfassung
        %    Nr             1xn Nummer des jeweiligen "Clusters"
        %    AnzahlTage     1xn Anzahl Elemente in diesem Cluster
        %    color          nx3 RGB Farbe mit der dieser Cluster gezeichnet werden soll
        %    TextData       1xn Cell - Name/Beschreibung des Clusters
        TagTypen=struct('Kategorien',{},'Nr',[],'AnzahlTage',[],'color',[],'TextData',{});
        
        
        % Beides Matlab serial date number - über den Konstruktor festgelegt oder über die Initialisieren-Methode veränderlich
        % Datumsformate können hier i.A. auch als string 'dd.mm.yyyy' an die Methoden übergeben werden
        Anfang=0;
        Ende=1;
        
        % KalenderData - struct die für jeden Tag zwischen Anfang und Ende alle notwendigen Daten bereithält - alle Felder haben size(Anfang:Ende)
        KalenderData = struct('Datum',[] ...
            ,'Wochentag',[] ...
            ,'IstMontag',[] ,'IstDienstag',[] ,'IstMittwoch',[] ,'IstDonnerstag',[] ,'IstFreitag',[] ,'IstSamstag',[] ,'IstSonntag',[] ...
            ,'Werktag',[],'Ferientag',[],'Feiertag',[],'Brueckentag',[],'WerktagVorFeiertag',[],'Spezialtag',[],'TagTypNr',[],'TextData',[]);
                    % Datum: als Matlab Serial Date Number
                    % Wochentag: von 1..7 Mo-So
                    % Werktag: true/false (Mo-Fr, wenn kein Feiertag)
                    % Ferientag: true/false (Schulferien)
                    % Feiertag: true/false (kann kein Werktag sein)
                    % Brueckentag: true/false (Werktag zwischen zwei NichtWerktagen) => wird vom Kalender ausgerechnet
                    % WerktagVorFeiertag: true/false (Werktag vor Feiertag) => wird vom Kalender ausgerechnet
                    % Spezialtag: true/false (Platzhalter für sonstige Ereignisse, die in keine Kategorie passen - Volksfest, Fußballspiel, Überflutung,...)
                    % TagTypNr: die jeweilige Nr aus TagTypen (wird i.A. automatisch gesetzt, wenn TagTypen von außen manipuliert wird muss selbst darauf geachtet werden)
                    % TextData: cell in der jedes Element eine 1-by-n cell enthält 
                    %           wobei n der Anzahl zusätzlicher Textzeilen in der Kalenderdarstellung entspricht - die tatsächliche Darstellung hängt vom Zoom ab
                    %           die Inhalte können nur über die Methode TagTypenSetzen gesetzt werden
                    %           Tipp - mehr als ~20 Zeichen in einer Zeile sieht in der Standardgröße nicht mehr gut aus

        % Structs die die jeweiligen "Extra-Daten" speichert - diese können auch außerhalb Anfang und Ende des Kalenders liegen, haben dann aber keine Auswirkung
        % Die Daten können einzeln über die jeweilige Methode angefügt werden oder komplett aus einer ExcelDatei eingelesen werden (Konstruktor-Parameter oder Initialisieren-Methode)
        Feiertage=struct('Datum',[],'Name',[]);                     % Feiertage müssen eindeutig sein (nicht mehrere Feiertage am selben Tag)
        Ferien=struct('DatumBeginn',[],'DatumEnde',[],'Name',[]);   % DatumBeginn und DatumEnde darf gleich sein (eintägige Ferien), Ferien dürfen sich überlappen (mehrer Bundesländer z.B.)
        Spezialtage=struct('Datum',[],'Name',[]);                   % Für sonst nicht einzuordnende Events die eine verkehrliche Auswirkung haben        
        Jahreszeit = struct('Fruehling', [], 'Sommer', [], 'Herbst', [], 'Winter', []); % Ordnet die Tage einer der 4 Jahreszeiten zu (logischer Vektor je Jahreszeit)
    end
    
    %%
    properties (GetAccess=public,SetAccess=private)

    end
    
    %%
    methods (Access=public)
        %% Konstruktor
        % Anfang und Ende sind Pflichtattribute
        function obj=class_Kalender(Anfang, Ende, Land, Gespeicherter_Kalender, flag_2412_und_3112_auch_Feiertage)
            if nargin >= 2               
                if Anfang<=Ende && Anfang ~= 0 && Ende ~= 0
                    obj.Anfang = floor(Anfang);
                    obj.Ende  =  floor(Ende);
                else
                    %MyDisp('Fehler! Das Enddatum des Kalenders darf nicht vor dem Anfangsdatum liegen!',true)
                    %MyDisp('Kalender mit Standardwerten erzeugt.',true)
                end
                if nargin < 3 || isempty(Land), Land = 'BW'; end
                % Es kann ein gespeicherter Kalender übergeben werden, das ist vor allem bei einer Vielzahl von Aufrufen sinnvoll, damit der Kalender (für die Zuordnung der Ferien & Feiertage) nicht jedesmal geladen werden muss.
                if nargin < 4 || isempty(Gespeicherter_Kalender), Gespeicherter_Kalender = []; end
                if nargin < 5 || isempty(flag_2412_und_3112_auch_Feiertage), flag_2412_und_3112_auch_Feiertage = false; end
                
                obj.Initialisieren(Land, Gespeicherter_Kalender, flag_2412_und_3112_auch_Feiertage);

            else
                %MyDisp('(leeren) Kalender mit Standardwerten erzeugt.',true)
            end
        end
        %% Initialisieren
        % setzt Anfang und Ende des Kalenders neu und aktualisiert Feiertage, Ferien usw.
        % dies erfolgt entweder anhand der dem Kalender bekannten Feiertage, Ferien usw.
        function Initialisieren(obj, Land, Gespeicherter_Kalender, flag_2412_und_3112_auch_Feiertage)
            %MyDisp('Initialisieren des Kalenders...',true)
            if ~length(obj)==1
                %MyDisp(' ...Fehler! Methode funktioniert nur für einzelne Kalender!',true)
            else
                % alle Platzhalter zurücksetzen
                obj.KalenderData.Datum = obj.Anfang : obj.Ende;
                obj.KalenderData.Wochentag = mod(weekday(obj.KalenderData.Datum)+5,7)+1;
                
                % Wochentag: von 1..7 Mo-So
                Felder_Tage = {'IstMontag','IstDienstag','IstMittwoch','IstDonnerstag','IstFreitag','IstSamstag','IstSonntag'};
                
                % für jeden Wochentag wird ein Boolscher Vektor erstellt
                for cnt_FT = 1 : 7
                    obj.KalenderData.(Felder_Tage{cnt_FT}) = obj.KalenderData.Wochentag == cnt_FT;
                end
                
                % Init Tageseigenschaften
                obj.KalenderData.Werktag            = obj.KalenderData.Wochentag < 6; % Mo-Fr
                obj.KalenderData.Ferientag          = false(size(obj.KalenderData.Datum)); % keine Ferientage
                obj.KalenderData.Feiertag           = false(size(obj.KalenderData.Datum)); % keine Feiertage
                obj.KalenderData.Brueckentag        = false(size(obj.KalenderData.Datum)); % keine Brückentage
                obj.KalenderData.WerktagVorFeiertag = false(size(obj.KalenderData.Datum)); % keine Werktage vor Feiertage
                obj.KalenderData.Spezialtag         = false(size(obj.KalenderData.Datum)); % keine Spezialtage
                obj.KalenderData.TagTypNr           = zeros(size(obj.KalenderData.Datum)); % Tagtyp = 0
                obj.KalenderData.TextData           = cell(size(obj.KalenderData.Datum));
                             
                % Einlesen der Ferien
                Tage = obj.KalenderData.Datum';
                Kalender = Kalender_erzeugen( Tage, Land, Gespeicherter_Kalender, flag_2412_und_3112_auch_Feiertage);
                
                % Übertragen der Feriendaten in Kalenderklasse
                if isfield(Kalender, 'Ferien')
                    obj.Ferien = Kalender.Ferien;
                else
                    % Falls keine feriendaten existieren, wird die Struktur
                    % nachgebaut
                    obj.Ferien.Ferien = false(size(obj.KalenderData.Datum))'; % keine Ferien;
                    obj.Ferien.Ferien_Name = cell(size(obj.KalenderData.Datum))';
                end
                
                obj.KalenderData.Ferientag = obj.Ferien.Ferien';
                
                %MyDisp(['  ...',num2str(sum(obj.KalenderData.Ferientag)),' Ferien(datensätze) eingelesen'],true)
                
                % Übertragen der Feiertagdaten in Kalenderklasse
                if isfield(Kalender, 'Feiertage')
                    obj.Feiertage = Kalender.Feiertage;
                else
                    % Falls keine feriendaten existieren, wird die Struktur
                    % nachgebaut
                    obj.Feiertage.Feiertag = false(size(obj.KalenderData.Datum))'; % keine Feiertage;
                    obj.Feiertage.Feiertage_Name = cell(size(obj.KalenderData.Datum))';
                end

                % Übertragen der Jahreszeiten
                if isfield(Kalender, 'Jahreszeit')
                    obj.Jahreszeit = Kalender.Jahreszeit;
                else
                    % Falls keine Jahreszeiten existieren, wird die mit
                    % Nullvektoren initialisiert
                    obj.Jahreszeit.Fruehling = false(size(obj.KalenderData.Datum))';
                    obj.Jahreszeit.Sommer = false(size(obj.KalenderData.Datum))'; 
                    obj.Jahreszeit.Herbst = false(size(obj.KalenderData.Datum))'; 
                    obj.Jahreszeit.Winter = false(size(obj.KalenderData.Datum))';                     
                end
                
                obj.KalenderData.Feiertag = obj.Feiertage.Feiertag';
                
                % Werktage, die Feiertage sind, werden auf falsch gesetzt
                obj.KalenderData.Werktag(obj.Feiertage.Feiertag) = false;
                
                %MyDisp(['  ...',num2str(sum(obj.KalenderData.Feiertag)),' Feiertage eingelesen'],true)
                
                % Einlesen der Spezialtage
                obj.Spezialtage = Kalender.Sonstige_Tage;
                %MyDisp(['  ...',num2str(sum(obj.KalenderData.Spezialtag)),' Spezialtage eingelesen'],true)
                
                % Tage, die kein Besonderer sind:
                obj.KalenderData.kein_Besonderer_Tag = ~obj.KalenderData.Werktag & ~obj.KalenderData.Ferientag & ~obj.KalenderData.Feiertag & ~obj.KalenderData.Brueckentag & ~obj.KalenderData.WerktagVorFeiertag  & ~obj.KalenderData.Spezialtag;
                
                % Tag Typ 0 setzten mit allen Tagen
                Farbe_TagTyp0 = [0.7, 0.7, 0.7];
                obj.TagTypen = struct( ...
                     'Kategorien',{''} ...
                    ,'Nr',0 ...
                    ,'AnzahlTage',numel(obj.KalenderData.Datum) ...
                    ,'color', Farbe_TagTyp0 ...
                    ,'TextData',{''} ...
                    );

            end
            %MyDisp(' ...Kalender initialisiert.',true)
        end

        %% TagTypenSetzen
        % setzt für die übergebenen Tage den jeweiligen TagTyp und erzeugt einen zusätzlichen Eintrag in TagTypen
        % TagTypNr muss eindeutig in obj.TagTypen.Nr sein, und sollte ~=0 sein
        % Dies sollte für den jeweiligen TagTyp nur einmal (also für alle betroffenen Tage auf einmal) gemacht werden
        % Diese Zuordnung kann beim Initialisieren (zum DatumBeginn/Ende ändern) nicht wieder hergestellt werden
        % Vor der ersten Durchführung empfielt sich ein Reset der TagTypen mit obj.TagTypenAktualisieren({})
        % Wird die Methode mit mehreren sich überlappenden Tagen durchgeführt, dann entstehen u.U. unerwartete Fehler
        %
        % Eingangsdaten vgl TagTypen:
        % Tage          1xn Vektor mit Matlab serial date number (ganztagig also gerundet) für die Tage die zu dem neuen TagTyp gehören
        % TagTypNr      Nr des neuen Tagtyps
        % color         Farbe mit der dieser Tagtyp gezeichnet werden soll
        % KategorieText Beschreibungstext dieses Tagtyps
        % TagTexte      (optional) 1xn cell mit strings in einer 1xk cell, die den Kalendertagen als Beschreibungstext zugewiesen werden (vgl. KalenderData)
        function TagTypenSetzen(obj,Tage,TagTypNr,color,KategorieText,TagTexte)
            if ~length(obj)==1
                %MyDisp('  ...Fehler! Methode funktioniert nur für einzelne Kalender!',true)
            else
                % Neuen TagTyp anlegen und speichern
                obj.TagTypen.Kategorien = {'Benutzerdefiniert'};
                if isempty(obj.TagTypen.Nr)
                    obj.TagTypen.Nr=TagTypNr;
                    obj.TagTypen.AnzahlTage=length(Tage);
                    obj.TagTypen.color = color;
                    obj.TagTypen.TextData{1}=KategorieText;
                else
                    % Prüfen ob der TagTyp bereits existiert:
                    idx_member = ismember(TagTypNr, obj.TagTypen.Nr);
                    if any(idx_member)
                        % Der bisherige TagTyp wird ersetzt.
                        idx_akt_TygTyp = obj.TagTypen.Nr == TagTypNr;
                        obj.TagTypen.AnzahlTage(idx_akt_TygTyp)=length(Tage);
                        obj.TagTypen.color(idx_akt_TygTyp,:) = color;
                        obj.TagTypen.TextData{idx_akt_TygTyp}=KategorieText;
                    else
                        % Neuer TagTyp wird hinzugefügt.
                        AnzahlTagTypen = length(obj.TagTypen.Nr);
                        obj.TagTypen.Nr(AnzahlTagTypen+1)=TagTypNr;
                        obj.TagTypen.AnzahlTage(AnzahlTagTypen+1)=length(Tage);
                        obj.TagTypen.color(AnzahlTagTypen + 1,:) = color;
                        obj.TagTypen.TextData{(AnzahlTagTypen+1)} = KategorieText;                        
                    end
                end
                % Kalenderdaten setzen
                obj.KalenderData.TagTypNr(ismember(obj.KalenderData.Datum,Tage))=TagTypNr;
                if nargin>=6
                    [obj.KalenderData.TextData{ismember(obj.KalenderData.Datum,Tage)}]=deal(TagTexte{:});
                end
                % Anzahl in jeder TagTypGruppe aktualisieren
                for TagTypIndex=1:length(obj.TagTypen.Nr)
                    obj.TagTypen.AnzahlTage(TagTypIndex)=sum(obj.TagTypen.Nr(TagTypIndex)==obj.KalenderData.TagTypNr);
                end
            end
        end
        %% Draw
        % zeichnet den Kalender zwischen Beginn und Ende und ergänzt Texte und Farben entsprechend der aktuellen TagTypen
        % figHandle ist die figure die den Kalender enthält
        function figHandle=Draw(obj)
            if ~length(obj)==1
                %MyDisp('  ...Fehler! Methode funktioniert nur für einzelne Kalender!',true)
            else
                % Stellt Hintergrund und Textfarbe für alle nicht Kalendertage/Buttons ein
                MainTextColor = 'k';
                MainBackColor = 'w';
                
                % Figure erzeugen und ein bischen anpassen
                figHandle = figure('Name','Kalenderübersicht','ToolBar','figure','MenuBar','none','numbertitle','off', 'units','normalized','color',MainBackColor,'position',[0.1 0.1 0.8 0.8],'Tag','Kalender','PaperPositionMode','auto','InvertHardCopy','off');
                delete(findall(figHandle,'type','uipushtool'))
                delete(findall(figHandle,'tag','Annotation.InsertLegend'))
                delete(findall(figHandle,'tag','Annotation.InsertColorbar'))
                delete(findall(figHandle,'tag','DataManager.Linking'))
                delete(findall(figHandle,'tag','Exploration.DataCursor'))
                delete(findall(figHandle,'tag','Standard.EditPlot'))
                delete(findall(figHandle,'tag','Exploration.Brushing'))
                delete(findall(figHandle,'tag','Exploration.Rotate'))
                
                % Diverse Werte auslesen/festlegen
                WochenNr = floor((obj.KalenderData.Datum-obj.Anfang+obj.KalenderData.Wochentag(1)-0.1/86400)/7)+1;
                Wochen = max(WochenNr)-min(WochenNr)+1;

                [~,WochenStartTagIndex]=unique(WochenNr);
                DateVec=datevec(obj.KalenderData.Datum(WochenStartTagIndex)');
                KalenderWochen=floor((obj.KalenderData.Datum(WochenStartTagIndex)'-datenum([DateVec(:,1) ones(size(DateVec,1),2) DateVec(:,4:6)])+(mod(weekday(datenum([DateVec(:,1) ones(size(DateVec,1),2) DateVec(:,4:6)]))+5,7)))/7);

                ButtonHoeheCal=1/Wochen;
                ButtonBreiteCal=1/7;
                
                AbstandLinks=0.05;
                if length(obj.TagTypen.Nr)>120
                    AbstandUnten=0.4;
                elseif length(obj.TagTypen.Nr)>80
                    AbstandUnten=0.3;
                else
                    AbstandUnten=0.2;
                end
                AbstandOben=0.025;

                % erzeugen der Achsensysteme für die Darstellung
                axHandleCalendar=axes('position',[AbstandLinks AbstandUnten 1-AbstandLinks 1-AbstandUnten-AbstandOben]...
                    ,'Parent',figHandle,'Xtick',[],'YTick',[],'box','off','Color','none','visible','off','tag','axHandleCalendar');
                axHandleLinks=axes('position',[0 AbstandUnten AbstandLinks 1-AbstandUnten-AbstandOben]...
                    ,'Parent',figHandle,'Xtick',[],'YTick',[],'box','off','Color','none','visible','off');
                axHandleOben=axes('position',[AbstandLinks 1-AbstandOben 1-AbstandLinks AbstandOben]...
                    ,'Parent',figHandle,'Xtick',[],'YTick',[],'box','off','Color','none','visible','off');

                % X/Y-Achsen der jeweiligen Achsen miteinander verknüpfen
                L1=linkprop([axHandleCalendar axHandleLinks],'YLim');
                L2=linkprop([axHandleCalendar axHandleOben],'XLim');
                set(figHandle,'UserData',[L1 L2])
                
                % Platzhalter für die CallbackFunktion
                TextLevels=cell(1,length(obj.KalenderData.Datum));
                % Platzhalte für die Textfarbe
                TextWhite=false(1,length(obj.KalenderData.Datum));
                for TagIndex=1:length(obj.KalenderData.Datum)
                    if TagIndex==1
                        tmp = {'Montag' 'Dienstag' 'Mittwoch' 'Donnerstag' 'Freitag' 'Samstag' 'Sonntag'};
                        for HeaderZeile=1:7
                            x1=ButtonBreiteCal*(HeaderZeile-1);
                            y1=0;
                            x2=x1+ButtonBreiteCal;
                            y2=1;
                            patch([x1 x2 x2 x1],[y1 y1 y2 y2],MainBackColor,'Parent',axHandleOben)
                            text((x1+x2)/2,(y1+y2)/2,tmp{HeaderZeile}...
                                ,'Color',MainTextColor...
                                ,'Tag','HeaderZeile'...
                                ,'HorizontalAlignment','center','VerticalAlignment','middle','FontUnits','normalized'...
                                ,'Parent',axHandleOben,'clipping','on')
                        end
                        for HeaderSpalte=1:Wochen
                            x1=0;
                            y1=1-ButtonHoeheCal*HeaderSpalte;
                            x2=1;
                            y2=y1+ButtonHoeheCal;
                            patch([x1 x2 x2 x1],[y1 y1 y2 y2],MainBackColor,'Tag','HeaderSpalte','Parent',axHandleLinks)
                            text((x1+x2)/2,(y1+y2)/2,['KW ',num2str(KalenderWochen(HeaderSpalte))]...
                                ,'Color',MainTextColor...
                                ,'Tag','HeaderSpalte'...
                                ,'HorizontalAlignment','center','VerticalAlignment','middle','FontUnits','normalized'...
                                ,'Parent',axHandleLinks,'clipping','on')
                        end
                        % Im Falle eines Jahreswechsels die Patches für die Jahre bereit halten
                        if any(diff(KalenderWochen)<0)
                            JahreswechselIndizes=[0 find(diff(KalenderWochen)<0)' length(KalenderWochen)];
                            Jahre=unique(DateVec(:,1));
                            for JahresIndex=1:length(JahreswechselIndizes)-1
                                x1=0;
                                y1=1-JahreswechselIndizes(JahresIndex+1)/JahreswechselIndizes(end);
                                x2=1;
                                y2=1-JahreswechselIndizes(JahresIndex)/JahreswechselIndizes(end);
                                patch([x1 x2 x2 x1],[y1 y1 y2 y2],MainBackColor,'Tag','HeaderSpalteJahr','Parent',axHandleLinks)
                                text((x1+x2)/2,(y1+y2)/2,num2str(Jahre(JahresIndex))...
                                    ,'Color',MainTextColor...
                                    ,'Tag','HeaderSpalteJahr'...
                                    ,'HorizontalAlignment','center','VerticalAlignment','middle','FontUnits','normalized'...
                                    ,'FontSize',0.03 ...
                                    ,'Parent',axHandleLinks,'clipping','on','Rotation',90)
                            end
                        end
                    end % if TagIndex==1

                    % die eigentlichen Kalendertage zeichnen
                    x1=ButtonBreiteCal*(obj.KalenderData.Wochentag(TagIndex)-1);
                    y1=1-ButtonHoeheCal*WochenNr(TagIndex);
                    x2=x1+ButtonBreiteCal;
                    y2=y1+ButtonHoeheCal;

                    patch([x1 x2 x2 x1],[y1 y1 y2 y2],obj.TagTypen.color(obj.KalenderData.TagTypNr(TagIndex)==obj.TagTypen.Nr,:),'Parent',axHandleCalendar,'Tag',['KalenderKlasse',num2str(obj.KalenderData.TagTypNr(TagIndex))],'UserData',obj.KalenderData.Datum(TagIndex))
                    TextWhite(TagIndex)=sum(obj.TagTypen.color(obj.KalenderData.TagTypNr(TagIndex)==obj.TagTypen.Nr,:).*[0.299 0.587 0.114])<0.5;
               
                    % die verschiedenen Textlevel speichern - 1..3 sind Default alle weiteren kommen ggfs. aus KalenderData.TextData
                    TextLevel = cell(1,3+length(obj.KalenderData.TextData{TagIndex}));
                    TextLevel{1,1}=datestr(obj.KalenderData.Datum(TagIndex),'dd.mm.yyyy');
                    TextLevel{1,2}=['TagTypNr: ',num2str(obj.KalenderData.TagTypNr(TagIndex))];
                    if obj.KalenderData.Feiertag(TagIndex)
                        TextLevel{1,3} = obj.Feiertage.Feiertage_Name{TagIndex};
                    else
                        TextLevel{1,3}='';
                    end
                    % ggfs. weitere Textinformationen übernehmen
                    for i = 1:length(obj.KalenderData.TextData{TagIndex})
                        TextLevel{1,i+3} = obj.KalenderData.TextData{TagIndex}{i};
                    end
                    TextLevels{1,TagIndex}=TextLevel;
                end

                % Zeichnen aller Textfelder auf einmal (schneller) - zunächst alle ohne Text - am Ende wird von ZoomLimit die passende Darstellung gewählt
                TextXKoords=ButtonBreiteCal*(2*obj.KalenderData.Wochentag-1)/2;
                TextYKoords=(2-2*ButtonHoeheCal*WochenNr+ButtonHoeheCal)/2;

                TextHandles=text(TextXKoords,TextYKoords,{''},'color','k','parent',axHandleCalendar,'HorizontalAlignment','center','VerticalAlignment','middle','FontUnits','normalized','clipping','on');
                % Setzen der weißen Textfarbe
                set(TextHandles(TextWhite),'color','w')
                % Setzen der tags und Userdata
                cellfun(@(x,y,z) set(x,'Tag',['KalenderKlasse',num2str(y)],'UserData',z), num2cell(TextHandles'), num2cell(obj.KalenderData.TagTypNr), num2cell(obj.KalenderData.Datum));

                % Legende einfügen
                Rows=min(ceil(8*AbstandUnten/0.2),16);
                Columns=4;
                % Text reduzieren und Anzahl Spalten erhöhen
                if length(obj.TagTypen.Nr)>Rows*Columns
                    Columns=10;
                end
                ButtonHoehe=AbstandUnten/Rows;
                ButtonBreite=(1-AbstandLinks)/Columns;
                for TagTypIndex=1:min(Rows*Columns,length(obj.TagTypen.Nr))
                    if TagTypIndex<min(Rows*Columns,length(obj.TagTypen.Nr)) || TagTypIndex==length(obj.TagTypen.Nr)
                        if Columns>4 % reduzierter Text mit ToolTip
                            uicontrol(figHandle,'Style','pushbutton','units','normalized'...
                                    ,'position',[AbstandLinks+ButtonBreite*floor((TagTypIndex-1)/Rows)...
                                                 AbstandUnten-ButtonHoehe*(mod(TagTypIndex-1,Rows)+1)...
                                                 ButtonBreite...
                                                 ButtonHoehe]...
                                     ,'BackgroundColor',obj.TagTypen.color(TagTypIndex,:)...
                                     ,'ForegroundColor',sum(obj.TagTypen.color(TagTypIndex,:).*[0.299 0.587 0.114])<0.5*[1 1 1]...
                                     ,'Tag',['KalenderKlasse',num2str(obj.TagTypen.Nr(TagTypIndex))]...
                                     ,'Callback',@ToggleMarkKlasse...
                                     ,'string',['TagTyp ',num2str(obj.TagTypen.Nr(TagTypIndex)),' (',num2str(obj.TagTypen.AnzahlTage(TagTypIndex)),' Tage)']...
                                     ,'TooltipString',sprintf(['TagTypBezeichnung:\n',obj.TagTypen.TextData{TagTypIndex}]))
                        else
                            uicontrol(figHandle,'Style','pushbutton','units','normalized'...
                                    ,'position',[AbstandLinks+ButtonBreite*floor((TagTypIndex-1)/Rows)...
                                                 AbstandUnten-ButtonHoehe*(mod(TagTypIndex-1,Rows)+1)...
                                                 ButtonBreite...
                                                 ButtonHoehe]...
                                     ,'BackgroundColor',obj.TagTypen.color(TagTypIndex,:)...
                                     ,'ForegroundColor',sum(obj.TagTypen.color(TagTypIndex,:).*[0.299 0.587 0.114])<0.5*[1 1 1]...
                                     ,'Tag',['KalenderKlasse',num2str(obj.TagTypen.Nr(TagTypIndex))]...
                                     ,'Callback',@ToggleMarkKlasse...
                                     ,'string',['TagTyp ',num2str(obj.TagTypen.Nr(TagTypIndex)),' (',num2str(obj.TagTypen.AnzahlTage(TagTypIndex)),' Tage): ',obj.TagTypen.TextData{TagTypIndex}])
                        end
                    else
                        uicontrol(figHandle,'Style','pushbutton','units','normalized'...
                                ,'position',[AbstandLinks+ButtonBreite*floor((TagTypIndex-1)/Rows)...
                                             AbstandUnten-ButtonHoehe*(mod(TagTypIndex-1,Rows)+1)...
                                             ButtonBreite...
                                             ButtonHoehe]...
                                 ,'BackgroundColor','w'...
                                 ,'ForegroundColor','k'...
                                 ,'enable','inactive'...
                                 ,'string',['... (zu viele Klassen ',num2str(Rows-Columns-1),' bis ',num2str(Rows*Columns-1),' von ',num2str(length(obj.TagTypen.Nr)),')'])
                    end
                end

                % Anpassen der Darstellung und aktivieren aller CallbackFunktionen
                set(pan(figHandle),'ActionPostCallback',@ZoomLimit)
                set(zoom(figHandle),'ActionPostCallback',@ZoomLimit)
                set(figHandle,'ResizeFcn',@ZoomLimit)
                
                % Aktivierung des Mausrads zum vertikalen Scrollen.
                set(figHandle,'WindowScrollWheelFcn',@WheelCallback)
            end
            
            
            
            % (nested function)
            % Kontrolliert das Scrollen via Mousewheel
            function WheelCallback(~,ScrollData)
                YLim=get(axHandleCalendar,'YLim');
                % gescrolled wird nur, wenn nicht voll rausgezommt ist
                if diff(YLim)<1
                    % Blockieren der Bewegungen über den Kalenderrand hinaus
                    if ~(YLim(1)<=0 && ScrollData.VerticalScrollCount>0) && ~(YLim(2)>=1 && ScrollData.VerticalScrollCount<0)
                        set(axHandleCalendar,'YLim',min(max(YLim-0.1*diff(YLim)*sign(ScrollData.VerticalScrollCount),[0 0]),[1 1]))
                    end
                end
            end
            
            
            
            % (nested function)
            % Kontrolliert die Darstellung der Textinhalte (callback von Zoom, Resize, Pan)
            function ZoomLimit(~,~)
                FrameImprovement=0.001;
                % Blockieren der Bewegungen über den Kalenderrand hinaus
                set(axHandleCalendar,'XLim',[0-FrameImprovement 1+FrameImprovement]...
                                    ,'YLim',min(max(get(axHandleCalendar,'YLim'),[0 0]),[1 1]))
                set(axHandleLinks   ,'XLim',[0-FrameImprovement 1+FrameImprovement]...
                                    ,'YLim',min(max(get(axHandleLinks,'YLim'),[0 0]),[1 1]))
                set(axHandleOben    ,'XLim',[0-FrameImprovement 1+FrameImprovement]...
                                    ,'YLim',min(max(get(axHandleOben,'YLim'),[0 0]),[1 1]))

                % Berechnen der Anzahl Pixel für Zeilen und Spalten
                ScreenSize=get(0,'ScreenSize');
                figHandlePosition=get(figHandle,'position');
                axHandleCalendarPosition=get(axHandleCalendar,'position');
                axHandleCalendarXLim=get(axHandleCalendar,'XLim');
                axHandleCalendarYLim=get(axHandleCalendar,'YLim');
                PixelsPerRow=ScreenSize(4)*figHandlePosition(4)*axHandleCalendarPosition(4)/(Wochen*diff(axHandleCalendarYLim));
                PixelsPerColumn=ScreenSize(3)*figHandlePosition(3)*axHandleCalendarPosition(3)/(7*diff(axHandleCalendarXLim));

                % KalenderText anpassen
                MaxRows=min(floor(PixelsPerRow/18),size(TextLevels{1,1},2));
                if MaxRows==0
                    set(TextHandles,'String','')
                else
                    EvalString='cellfun(@(x,y) set(x,''String'',sprintf([y{1,min(end,1)}';
                    for TextRow=2:MaxRows
                        EvalString=[EvalString,',''\n'',y{1,min(end,',num2str(TextRow),')}']; %#ok<AGROW>
                    end
                    EvalString=[EvalString,'])),num2cell(TextHandles''),TextLevels);'];
                    eval(EvalString);
                end
                
                % HeaderZeile/Spalte anpassen
                if PixelsPerRow<=20
                    set(findall(figHandle,'Tag','HeaderSpalte'),'Visible','off')
                    set(findall(figHandle,'Tag','HeaderSpalteJahr'),'Visible','on')
                else
                    set(findall(figHandle,'Tag','HeaderSpalte'),'Visible','on')
                    set(findall(figHandle,'Tag','HeaderSpalteJahr'),'Visible','off')
                end
                if PixelsPerColumn<=67
                    set(findall(figHandle,'Tag','HeaderZeile'),'Visible','off')
                else
                    set(findall(figHandle,'Tag','HeaderZeile'),'Visible','on')
                end
                
                % ggfs Rahmenlinien ausblenden (max-Ansicht) - allerdings nur die, die nicht hervorgehoben sind
                if diff(axHandleCalendarYLim)>=1
                    set(findall(figHandle,'-regexp','tag','KalenderKlasse*','-and','type','patch','-and','LineWidth',0.5),'LineStyle','none')
                    % Sondereinstellungen beim maximalen Rauszoomen
                    set(axHandleCalendar,'YLim',[0-FrameImprovement 1+FrameImprovement])
                    set(axHandleLinks,'YLim',[0-FrameImprovement 1+FrameImprovement])
                    set(axHandleOben,'YLim',[0-FrameImprovement 1+FrameImprovement])
                else
                    set(findall(figHandle,'-regexp','tag','KalenderKlasse*','-and','type','patch','-and','LineStyle','none'),'LineStyle','-')
                end
            end
            
            % (nested function)
            % Kontrolliert die Hervorhebung eines angeclickten TagTyps
            function ToggleMarkKlasse(hObject, ~)
                ClusterNr = get(hObject, 'UserData');
                if strcmpi(get(hObject,'FontWeight'),'bold')
                    set(findall(figHandle,'tag',get(hObject,'tag'),'-and','type','text'),'FontWeight','normal')
                    if diff(get(axHandleCalendar,'YLim'))>=1
                        set(findall(figHandle,'tag',get(hObject,'tag'),'-and','type','patch'),'LineWidth',0.5,'LineStyle','none')
                    else
                        set(findall(figHandle,'tag',get(hObject,'tag'),'-and','type','patch'),'LineWidth',0.5)
                    end
                    set(hObject,'FontWeight','normal')
                else
                    set(findall(figHandle,'tag',get(hObject,'tag'),'-and','type','text'),'FontWeight','bold')
                    set(findall(figHandle,'tag',get(hObject,'tag'),'-and','type','patch'),'LineWidth',2,'LineStyle','-')
                    set(hObject,'FontWeight','bold')
                end
            end
        end
        function figHandle=Draw3(obj, obj2, obj3)
            if ~length(obj)==1
                %MyDisp('  ...Fehler! Methode funktioniert nur für einzelne Kalender!',true)
            else
                
                
                % obj2 und obj3 sind Kalender mit den gleichen Tagen !!!
                Tage_obj    = obj.KalenderData.Datum';
                TagTyp_obj  = obj.KalenderData.TagTypNr;
                [~, idx_TagTyp] = ismember(TagTyp_obj, obj.TagTypen.Nr);
                Farben_obj  = obj.TagTypen.color(idx_TagTyp, :); 
                
                Tage_obj2    = obj2.KalenderData.Datum';
                TagTyp_obj2  = obj2.KalenderData.TagTypNr;
                [~, idx_TagTyp] = ismember(TagTyp_obj2, obj2.TagTypen.Nr);
                Farben_obj2  = obj2.TagTypen.color(idx_TagTyp, :); 
                
                Tage_obj3    = obj3.KalenderData.Datum';
                TagTyp_obj3  = obj3.KalenderData.TagTypNr;
                [~, idx_TagTyp] = ismember(TagTyp_obj3, obj3.TagTypen.Nr);
                Farben_obj3  = obj3.TagTypen.color(idx_TagTyp, :);                 
                
                [~, M,  D ] = datevec(Tage_obj);  DM  = M *100 + D;
                [~, M2, D2] = datevec(Tage_obj2); DM2 = M2 *100 + D2;
                [~, M3, D3] = datevec(Tage_obj3); DM3 = M3 *100 + D3;
                
                Zuordnung.TagTyp2 = zeros(size(TagTyp_obj));
                Zuordnung.TagTyp3 = zeros(size(TagTyp_obj));
                Zuordnung.Farben2 = zeros(size(TagTyp_obj), 3); 
                Zuordnung.Farben3 = zeros(size(TagTyp_obj), 3); 
                
                [idx_kommt_vor, idx_Tag2] = ismember(DM2, DM);
                Zuordnung.TagTyp2(idx_Tag2) = TagTyp_obj2(idx_kommt_vor);
                Zuordnung.Farben2(idx_Tag2, :) = Farben_obj2(idx_kommt_vor, :);
                
                [idx_kommt_vor, idx_Tag3] = ismember(DM3, DM);
                Zuordnung.TagTyp3(idx_Tag3) = TagTyp_obj3(idx_kommt_vor);                
                Zuordnung.Farben3(idx_Tag3, :) = Farben_obj3(idx_kommt_vor, :);
                
                % Stellt Hintergrund und Textfarbe für alle nicht Kalendertage/Buttons ein
                MainTextColor = 'k';
                MainBackColor = 'w';
                
                % Figure erzeugen und ein bischen anpassen
                figHandle = figure('Name','Kalenderübersicht','ToolBar','figure','MenuBar','none','numbertitle','off', 'units','normalized','color',MainBackColor,'position',[0.1 0.1 0.8 0.8],'Tag','Kalender','PaperPositionMode','auto','InvertHardCopy','off');
                delete(findall(figHandle,'type','uipushtool'))
                delete(findall(figHandle,'tag','Annotation.InsertLegend'))
                delete(findall(figHandle,'tag','Annotation.InsertColorbar'))
                delete(findall(figHandle,'tag','DataManager.Linking'))
                delete(findall(figHandle,'tag','Exploration.DataCursor'))
                delete(findall(figHandle,'tag','Standard.EditPlot'))
                delete(findall(figHandle,'tag','Exploration.Brushing'))
                delete(findall(figHandle,'tag','Exploration.Rotate'))
                
                % Diverse Werte auslesen/festlegen
                WochenNr = floor((obj.KalenderData.Datum-obj.Anfang+obj.KalenderData.Wochentag(1)-0.1/86400)/7)+1;
                Wochen = max(WochenNr)-min(WochenNr)+1;

                [~,WochenStartTagIndex]=unique(WochenNr);
                DateVec=datevec(obj.KalenderData.Datum(WochenStartTagIndex)');
                KalenderWochen=floor((obj.KalenderData.Datum(WochenStartTagIndex)'-datenum([DateVec(:,1) ones(size(DateVec,1),2) DateVec(:,4:6)])+(mod(weekday(datenum([DateVec(:,1) ones(size(DateVec,1),2) DateVec(:,4:6)]))+5,7)))/7);

                ButtonHoeheCal=1/Wochen;
                ButtonBreiteCal=1/7;
                
                AbstandLinks=0.05;
                if length(obj.TagTypen.Nr)>120
                    AbstandUnten=0.4;
                elseif length(obj.TagTypen.Nr)>80
                    AbstandUnten=0.3;
                else
                    AbstandUnten=0.2;
                end
                AbstandOben=0.025;

                % erzeugen der Achsensysteme für die Darstellung
                axHandleCalendar=axes('position',[AbstandLinks AbstandUnten 1-AbstandLinks 1-AbstandUnten-AbstandOben]...
                    ,'Parent',figHandle,'Xtick',[],'YTick',[],'box','off','Color','none','visible','off','tag','axHandleCalendar');
                axHandleLinks=axes('position',[0 AbstandUnten AbstandLinks 1-AbstandUnten-AbstandOben]...
                    ,'Parent',figHandle,'Xtick',[],'YTick',[],'box','off','Color','none','visible','off');
                axHandleOben=axes('position',[AbstandLinks 1-AbstandOben 1-AbstandLinks AbstandOben]...
                    ,'Parent',figHandle,'Xtick',[],'YTick',[],'box','off','Color','none','visible','off');

                % X/Y-Achsen der jeweiligen Achsen miteinander verknüpfen
                L1=linkprop([axHandleCalendar axHandleLinks],'YLim');
                L2=linkprop([axHandleCalendar axHandleOben],'XLim');
                % set(figHandle,'UserData',[L1 L2])
                
                % Platzhalter für die CallbackFunktion
                TextLevels=cell(1,length(obj.KalenderData.Datum));
                % Platzhalte für die Textfarbe
                TextWhite=false(1,length(obj.KalenderData.Datum));
                for TagIndex=1:length(obj.KalenderData.Datum)
                    if TagIndex==1
                        tmp = {'Montag' 'Dienstag' 'Mittwoch' 'Donnerstag' 'Freitag' 'Samstag' 'Sonntag'};
                        for HeaderZeile=1:7
                            x1=ButtonBreiteCal*(HeaderZeile-1);
                            y1=0;
                            x2=x1+ButtonBreiteCal;
                            y2=1;
                            patch([x1 x2 x2 x1],[y1 y1 y2 y2],MainBackColor,'Parent',axHandleOben)
                            text((x1+x2)/2,(y1+y2)/2,tmp{HeaderZeile}...
                                ,'Color',MainTextColor...
                                ,'Tag','HeaderZeile'...
                                ,'HorizontalAlignment','center','VerticalAlignment','middle','FontUnits','normalized'...
                                ,'Parent',axHandleOben,'clipping','on')
                        end
                        for HeaderSpalte=1:Wochen
                            x1=0;
                            y1=1-ButtonHoeheCal*HeaderSpalte;
                            x2=1;
                            y2=y1+ButtonHoeheCal;
                            patch([x1 x2 x2 x1],[y1 y1 y2 y2],MainBackColor,'Tag','HeaderSpalte','Parent',axHandleLinks)
                            text((x1+x2)/2,(y1+y2)/2,['KW ',num2str(KalenderWochen(HeaderSpalte))]...
                                ,'Color',MainTextColor...
                                ,'Tag','HeaderSpalte'...
                                ,'HorizontalAlignment','center','VerticalAlignment','middle','FontUnits','normalized'...
                                ,'Parent',axHandleLinks,'clipping','on')
                        end
                        % Im Falle eines Jahreswechsels die Patches für die Jahre bereit halten
                        if any(diff(KalenderWochen)<0)
                            JahreswechselIndizes=[0 find(diff(KalenderWochen)<0)' length(KalenderWochen)];
                            Jahre=unique(DateVec(:,1));
                            for JahresIndex=1:length(JahreswechselIndizes)-1
                                x1=0;
                                y1=1-JahreswechselIndizes(JahresIndex+1)/JahreswechselIndizes(end);
                                x2=1;
                                y2=1-JahreswechselIndizes(JahresIndex)/JahreswechselIndizes(end);
                                patch([x1 x2 x2 x1],[y1 y1 y2 y2],MainBackColor,'Tag','HeaderSpalteJahr','Parent',axHandleLinks)
                                text((x1+x2)/2,(y1+y2)/2,num2str(Jahre(JahresIndex))...
                                    ,'Color',MainTextColor...
                                    ,'Tag','HeaderSpalteJahr'...
                                    ,'HorizontalAlignment','center','VerticalAlignment','middle','FontUnits','normalized'...
                                    ,'FontSize',0.03 ...
                                    ,'Parent',axHandleLinks,'clipping','on','Rotation',90)
                            end
                        end
                    end

                    % die eigentlichen Kalendertage zeichnen
                    x1=ButtonBreiteCal*(obj.KalenderData.Wochentag(TagIndex)-1);
                    y1=1-ButtonHoeheCal*WochenNr(TagIndex);
                    x2=x1+ButtonBreiteCal;
                    y2=y1+ButtonHoeheCal;
                    
                    x1_1 = x1;
                    x2_1 = x1 + ButtonBreiteCal/3;
                    x1_2 = x2_1;
                    x2_2 = x1 + 2*ButtonBreiteCal/3;
                    x1_3 = x2_2;
                    x2_3 = x1 + ButtonBreiteCal;
                    patch([x1_1 x2_1 x2_1 x1_1],[y1 y1 y2 y2], Farben_obj(TagIndex, :)       ,'Parent',axHandleCalendar,'Tag',['KalenderKlasse',num2str(obj.KalenderData.TagTypNr(TagIndex))],'UserData',obj.KalenderData.Datum(TagIndex))
                    patch([x1_2 x2_2 x2_2 x1_2],[y1 y1 y2 y2], Zuordnung.Farben2(TagIndex, :),'Parent',axHandleCalendar,'Tag',['KalenderKlasse',num2str(obj.KalenderData.TagTypNr(TagIndex))],'UserData',obj.KalenderData.Datum(TagIndex))
                    patch([x1_3 x2_3 x2_3 x1_3],[y1 y1 y2 y2], Zuordnung.Farben3(TagIndex, :),'Parent',axHandleCalendar,'Tag',['KalenderKlasse',num2str(obj.KalenderData.TagTypNr(TagIndex))],'UserData',obj.KalenderData.Datum(TagIndex))
                    % patch([x1 x2 x2 x1],[y1 y1 y2 y2],obj.TagTypen.color(obj.KalenderData.TagTypNr(TagIndex)==obj.TagTypen.Nr,:),'Parent',axHandleCalendar,'Tag',['KalenderKlasse',num2str(obj.KalenderData.TagTypNr(TagIndex))],'UserData',obj.KalenderData.Datum(TagIndex))
                    TextWhite(TagIndex)=sum(obj.TagTypen.color(obj.KalenderData.TagTypNr(TagIndex)==obj.TagTypen.Nr,:).*[0.299 0.587 0.114])<0.5;
                    
                    % die verschiedenen Textlevel speichern - 1..3 sind Default alle weiteren kommen ggfs. aus KalenderData.TextData
                    TextLevel = cell(1,3+length(obj.KalenderData.TextData{TagIndex}));
                    TextLevel{1,1}=datestr(obj.KalenderData.Datum(TagIndex),'dd.mm.yyyy');
                    TextLevel{1,2}=['TagTypNr: ',num2str(obj.KalenderData.TagTypNr(TagIndex))];
                    if obj.KalenderData.Feiertag(TagIndex)
                        TextLevel{1,3} = obj.Feiertage.Feiertage_Name{TagIndex};
                    else
                        TextLevel{1,3}='';
                    end
                    % ggfs. weitere Textinformationen übernehmen
                    for i = 1:length(obj.KalenderData.TextData{TagIndex})
                        TextLevel{1,i+3} = obj.KalenderData.TextData{TagIndex}{i};
                    end
                    TextLevels{1,TagIndex}=TextLevel;
                end

                % Zeichnen aller Textfelder auf einmal (schneller) - zunächst alle ohne Text - am Ende wird von ZoomLimit die passende Darstellung gewählt
                TextXKoords=ButtonBreiteCal*(2*obj.KalenderData.Wochentag-1)/2;
                TextYKoords=(2-2*ButtonHoeheCal*WochenNr+ButtonHoeheCal)/2;

                TextHandles=text(TextXKoords,TextYKoords,{''},'color','k','parent',axHandleCalendar,'HorizontalAlignment','center','VerticalAlignment','middle','FontUnits','normalized','clipping','on');
                % Setzen der weißen Textfarbe
                set(TextHandles(TextWhite),'color','w')
                % Setzen der tags und Userdata
                cellfun(@(x,y,z) set(x,'Tag',['KalenderKlasse',num2str(y)],'UserData',z),num2cell(TextHandles'),num2cell(obj.KalenderData.TagTypNr),num2cell(obj.KalenderData.Datum));

                % Legende einfügen
                Rows=min(ceil(8*AbstandUnten/0.2),16);
                Columns=4;
                % Text reduzieren und Anzahl Spalten erhöhen
                if length(obj.TagTypen.Nr)>Rows*Columns
                    Columns=10;
                end
                ButtonHoehe=AbstandUnten/Rows;
                ButtonBreite=(1-AbstandLinks)/Columns;
                for TagTypIndex=1:min(Rows*Columns,length(obj.TagTypen.Nr))
                    if TagTypIndex<min(Rows*Columns,length(obj.TagTypen.Nr)) || TagTypIndex==length(obj.TagTypen.Nr)
                        akt_Cluster_num = [];
                        if Columns>4 % reduzierter Text mit ToolTip
                            uicontrol(figHandle,'Style','pushbutton','units','normalized'...
                                    ,'position',[AbstandLinks+ButtonBreite*floor((TagTypIndex-1)/Rows)...
                                                 AbstandUnten-ButtonHoehe*(mod(TagTypIndex-1,Rows)+1)...
                                                 ButtonBreite...
                                                 ButtonHoehe]...
                                     ,'BackgroundColor',obj.TagTypen.color(TagTypIndex,:)...
                                     ,'ForegroundColor',sum(obj.TagTypen.color(TagTypIndex,:).*[0.299 0.587 0.114])<0.5*[1 1 1]...
                                     ,'Tag',['KalenderKlasse',num2str(obj.TagTypen.Nr(TagTypIndex))]...
                                     ,'Callback',@ToggleMarkKlasse...
                                     ,'string',['TagTyp ',num2str(obj.TagTypen.Nr(TagTypIndex)),' (',num2str(obj.TagTypen.AnzahlTage(TagTypIndex)),' Tage)']...
                                     ,'TooltipString',sprintf(['TagTypBezeichnung:\n',obj.TagTypen.TextData{TagTypIndex}]) ...
                                     ,'UnserData', akt_Cluster_num)
                        else
                            uicontrol(figHandle,'Style','pushbutton','units','normalized'...
                                    ,'position',[AbstandLinks+ButtonBreite*floor((TagTypIndex-1)/Rows)...
                                                 AbstandUnten-ButtonHoehe*(mod(TagTypIndex-1,Rows)+1)...
                                                 ButtonBreite...
                                                 ButtonHoehe]...
                                     ,'BackgroundColor',obj.TagTypen.color(TagTypIndex,:)...
                                     ,'ForegroundColor',sum(obj.TagTypen.color(TagTypIndex,:).*[0.299 0.587 0.114])<0.5*[1 1 1]...
                                     ,'Tag',['KalenderKlasse',num2str(obj.TagTypen.Nr(TagTypIndex))]...
                                     ,'Callback',@ToggleMarkKlasse...
                                     ,'string',['TagTyp ',num2str(obj.TagTypen.Nr(TagTypIndex)),' (',num2str(obj.TagTypen.AnzahlTage(TagTypIndex)),' Tage): ',obj.TagTypen.TextData{TagTypIndex}] ...
                                     ,'UnserData', akt_Cluster_num)
                        end
                    else
                        uicontrol(figHandle,'Style','pushbutton','units','normalized'...
                                ,'position',[AbstandLinks+ButtonBreite*floor((TagTypIndex-1)/Rows)...
                                             AbstandUnten-ButtonHoehe*(mod(TagTypIndex-1,Rows)+1)...
                                             ButtonBreite...
                                             ButtonHoehe]...
                                 ,'BackgroundColor','w'...
                                 ,'ForegroundColor','k'...
                                 ,'enable','inactive'...
                                 ,'string',['... (zu viele Klassen ',num2str(Rows-Columns-1),' bis ',num2str(Rows*Columns-1),' von ',num2str(length(obj.TagTypen.Nr)),')'] ...
                                 ,'UnserData', akt_Cluster_num)
                    end
                end

                % Anpassen der Darstellung und aktivieren aller CallbackFunktionen
                set(pan(figHandle),'ActionPostCallback',@ZoomLimit)
                set(zoom(figHandle),'ActionPostCallback',@ZoomLimit)
                set(figHandle,'ResizeFcn',@ZoomLimit)
                
                % Aktivierung des Mausrads zum vertikalen Scrollen.
                set(figHandle,'WindowScrollWheelFcn',@WheelCallback)
            end
            
            
            
            % (nested function)
            % Kontrolliert das Scrollen via Mousewheel
            function WheelCallback(~,ScrollData)
                YLim=get(axHandleCalendar,'YLim');
                % gescrolled wird nur, wenn nicht voll rausgezommt ist
                if diff(YLim)<1
                    % Blockieren der Bewegungen über den Kalenderrand hinaus
                    if ~(YLim(1)<=0 && ScrollData.VerticalScrollCount>0) && ~(YLim(2)>=1 && ScrollData.VerticalScrollCount<0)
                        set(axHandleCalendar,'YLim',min(max(YLim-0.1*diff(YLim)*sign(ScrollData.VerticalScrollCount),[0 0]),[1 1]))
                    end
                end
            end
            
            
            
            % (nested function)
            % Kontrolliert die Darstellung der Textinhalte (callback von Zoom, Resize, Pan)
            function ZoomLimit(~,~)
                FrameImprovement=0.001;
                % Blockieren der Bewegungen über den Kalenderrand hinaus
                set(axHandleCalendar,'XLim',[0-FrameImprovement 1+FrameImprovement]...
                                    ,'YLim',min(max(get(axHandleCalendar,'YLim'),[0 0]),[1 1]))
                set(axHandleLinks   ,'XLim',[0-FrameImprovement 1+FrameImprovement]...
                                    ,'YLim',min(max(get(axHandleLinks,'YLim'),[0 0]),[1 1]))
                set(axHandleOben    ,'XLim',[0-FrameImprovement 1+FrameImprovement]...
                                    ,'YLim',min(max(get(axHandleOben,'YLim'),[0 0]),[1 1]))

                % Berechnen der Anzahl Pixel für Zeilen und Spalten
                ScreenSize=get(0,'ScreenSize');
                figHandlePosition=get(figHandle,'position');
                axHandleCalendarPosition=get(axHandleCalendar,'position');
                axHandleCalendarXLim=get(axHandleCalendar,'XLim');
                axHandleCalendarYLim=get(axHandleCalendar,'YLim');
                PixelsPerRow=ScreenSize(4)*figHandlePosition(4)*axHandleCalendarPosition(4)/(Wochen*diff(axHandleCalendarYLim));
                PixelsPerColumn=ScreenSize(3)*figHandlePosition(3)*axHandleCalendarPosition(3)/(7*diff(axHandleCalendarXLim));

                % KalenderText anpassen
                MaxRows=min(floor(PixelsPerRow/18),size(TextLevels{1,1},2));
                if MaxRows==0
                    set(TextHandles,'String','')
                else
                    EvalString='cellfun(@(x,y) set(x,''String'',sprintf([y{1,min(end,1)}';
                    for TextRow=2:MaxRows
                        EvalString=[EvalString,',''\n'',y{1,min(end,',num2str(TextRow),')}']; %#ok<AGROW>
                    end
                    EvalString=[EvalString,'])),num2cell(TextHandles''),TextLevels);'];
                    eval(EvalString);
                end
                
                % HeaderZeile/Spalte anpassen
                if PixelsPerRow<=20
                    set(findall(figHandle,'Tag','HeaderSpalte'),'Visible','off')
                    set(findall(figHandle,'Tag','HeaderSpalteJahr'),'Visible','on')
                else
                    set(findall(figHandle,'Tag','HeaderSpalte'),'Visible','on')
                    set(findall(figHandle,'Tag','HeaderSpalteJahr'),'Visible','off')
                end
                if PixelsPerColumn<=67
                    set(findall(figHandle,'Tag','HeaderZeile'),'Visible','off')
                else
                    set(findall(figHandle,'Tag','HeaderZeile'),'Visible','on')
                end
                
                % ggfs Rahmenlinien ausblenden (max-Ansicht) - allerdings nur die, die nicht hervorgehoben sind
                if diff(axHandleCalendarYLim)>=1
                    set(findall(figHandle,'-regexp','tag','KalenderKlasse*','-and','type','patch','-and','LineWidth',0.5),'LineStyle','none')
                    % Sondereinstellungen beim maximalen Rauszoomen
                    set(axHandleCalendar,'YLim',[0-FrameImprovement 1+FrameImprovement])
                    set(axHandleLinks,'YLim',[0-FrameImprovement 1+FrameImprovement])
                    set(axHandleOben,'YLim',[0-FrameImprovement 1+FrameImprovement])
                else
                    set(findall(figHandle,'-regexp','tag','KalenderKlasse*','-and','type','patch','-and','LineStyle','none'),'LineStyle','-')
                end
            end
            
            % (nested function)
            % Kontrolliert die Hervorhebung eines angeclickten TagTyps
            function ToggleMarkKlasse(hObject, ~)
                if strcmpi(get(hObject,'FontWeight'),'bold')
                    set(findall(figHandle,'tag',get(hObject,'tag'),'-and','type','text'),'FontWeight','normal')
                    if diff(get(axHandleCalendar,'YLim'))>=1
                        set(findall(figHandle,'tag',get(hObject,'tag'),'-and','type','patch'),'LineWidth',0.5,'LineStyle','none')
                    else
                        set(findall(figHandle,'tag',get(hObject,'tag'),'-and','type','patch'),'LineWidth',0.5)
                    end
                    set(hObject,'FontWeight','normal')
                else
                    set(findall(figHandle,'tag',get(hObject,'tag'),'-and','type','text'),'FontWeight','bold')
                    set(findall(figHandle,'tag',get(hObject,'tag'),'-and','type','patch'),'LineWidth',2,'LineStyle','-')
                    set(hObject,'FontWeight','bold')
                end
            end
        end        
    end
end