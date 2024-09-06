function Cell2Excel( CELL, Excel_Dateinamen, Sheet_Name )
%Cell2Excel Exportiert eine Cell in eine Excel-Datei.
%
%    Cell2Excel( CELL, Excel_Dateinamen, Sheet_Name )
% 
% Eine Cell kann aus Buchstaben und Zahlen bestehen, daher wird dieses
% Format gew‰hlt.
% Sollen mehrere Tabellenbl‰tter in Excel beschrieben werden muss aus den
% einzelnen Cells eine Groﬂe Cell generiert werden:
% BSP:
% 1. Tabellenblatt:
% TB1 = num2cell(eye(5));
%
% 2. Tabellenblatt:
% TB2 = {'erster Eintrag','erster Eintrag'};
%
% Funktionsaufruf: 
%
% Cell2Excel({TB1,TB2},'from_Matlab',{'TabName1','TabName1'})
% 
% 


if nargin < 1 || isempty(CELL) || ~iscell(CELL), disp('Die Function Cell2Excel benˆtigt eine Cell als Eingang. Export nicht durchgef¸hrt.'), end 
if nargin < 2 || isempty(Excel_Dateinamen), Excel_Dateinamen = 'from_Matlab.xls'; end

% Bestimmung der Anzahl an Tabellenbl‰tter:
Anzahl_Sheets = sum(sum(cellfun(@iscell,CELL)));

% Wenn nur ein Tabellenblatt eingef¸gt werden soll, muss die Cell umgebaut
% werden:
if Anzahl_Sheets == 0, CELL={CELL}; end

if nargin < 3 || isempty(Sheet_Name),
    % jedes SheetName Element leer machen.
    Sheet_Name = cell(1,max(1,Anzahl_Sheets));
end


%÷ffnet Excel Arbeitsmappe ¸ber ActivX Server
h=actxserver('Excel.Application');
hWBs=h.Workbooks;
%Excel sichtbar machen:
h.Visible=1;

%neue xls-Datei:
Mappe=hWBs.Add;

worksheets=Mappe.Sheets;
%Erzeugt ein neues Sheet
worksheets.Add; %neues Sheet wird immer gleich aktiv
%bei ersten mal alle leeren Tabellenbl‰tter lˆschen:
    for cnt_sheets=1:(worksheets.Count-1)
        worksheets.get('Item', 2).Delete
    end
    
    % Jedes Tabellenblatt erstellen:
    for cnt_AS = max(1,Anzahl_Sheets): -1 : 1
        
        %Erzeugt ein neues Sheet
        worksheets.Add; %neues Sheet wird immer gleich aktiv
        
        Tabelle=h.Activesheet;
        
        % Sheet Name ver‰ndern:
        if any(Sheet_Name{cnt_AS}),
            set(Tabelle,'Name',Sheet_Name{cnt_AS})
        end
        
        % Farbe des Sheet (unten bei den Tabs) ‰ndern.
        Tabelle.Tab.Color=5296274;
        
        if ~ismember(0, size(CELL{cnt_AS})),
            % Bereich ermitteln in den die CELL in Excel eingef¸gt wird:
            letzte_Zeile_str=num2str(size(CELL{cnt_AS},1));
            bis_Spalte=Umrechnung_Spaltennummer2Spaltestring_Excel(size(CELL{cnt_AS},2));
            
            %Daten in Excel eintragen:
            x_Bereich=h.Activesheet.get('Range', strcat('A1:',char(bis_Spalte),letzte_Zeile_str));
            x_Bereich.Value = CELL{cnt_AS};
        end
        
%         %Ausrichtung:
%         Bereich_Ausrichten = h.Activesheet.get('Range', strcat('A1:',char(bis_Spalte),letzte_Zeile_str));
%         set(Bereich_Ausrichten,'HorizontalAlignment',-4152) %rechtsb¸ndig
%         
%         % Ersetzen:
%         welches_Zeichen_ersetzten = '-';
%         neues_Zeichen = '';
%         x_Bereich.Replace(welches_Zeichen_ersetzten,neues_Zeichen);
        
%         %Fenster fixieren:
%         b=h.Activesheet.get('Range', 'B2');
%         h.FreezePanes('True');
%         
%         %Spalten mit Zahlen formatieren (Anzahl Nachkommastellen, Zahlenformat):
%         Spaltennummern_Zahlen=[];
%         clear auswahl_Bereich
%         Spalten_FZ=Umrechnung_Spaltennummer2Spaltestring_Excel(Spaltennummern_Zahlen);
%         auswahl_Bereich=cell(1,length(Spalten_FZ));
%         
%         for cnt=1:length(Spalten_FZ),
%             auswahl_Bereich{cnt}=[Spalten_FZ{cnt},'2:',Spalten_FZ{cnt},letzte_Zeile_str];
%         end
%         for cnt_ausw=1:length(auswahl_Bereich),
%             Fahrzeiten_Bereich=h.Activesheet.get('Range', auswahl_Bereich{cnt_ausw});
%             set(Fahrzeiten_Bereich,'NumberFormatLocal','0,00')
%             set(Fahrzeiten_Bereich,'NumberFormat','0,00')
%         end
%         
%         % Zellenbreite der Spalten:
%         ALLES_Bereich=h.Activesheet.get('Range', ['A:',char(bis_Spalte{1})]);
%         set(ALLES_Bereich,'ColumnWidth','16')
%         
%         % ‹berschrift formatieren: %Farbe dunkelgrau: 12566463, hellgrau: 15921906
%         erste_Zeile_Bereich=h.Activesheet.get('Rows', '1:1');
%         set(erste_Zeile_Bereich,'HorizontalAlignment',-4108) %zentriert.
%         Schrift_Bereich=get(erste_Zeile_Bereich,'Font');
%         set(Schrift_Bereich,'Size',16)
%         set(Schrift_Bereich,'Bold',1)
%         %F‰rbung ‰ndern:
%         innen_erste_Zeile_Bereich=get(erste_Zeile_Bereich,'Interior');
%         set(innen_erste_Zeile_Bereich,'Color',12566463) %dunkelgrau
%         
%         
%         %Kommentar einf¸gen (geht nicht)
%         
%         % %Zusammengehˆrige Spalten farblich markieren:
%         % clear auswahl_Bereich2
%         % Spalten_FZ1=Umrechnung_Spaltennummer2Spaltestring_Excel([5:4:size(neue_Cell,2)]);
%         % Spalten_FZ2=Umrechnung_Spaltennummer2Spaltestring_Excel([5:4:size(neue_Cell,2)]+1);
%         % auswahl_Bereich2=cell(1,length(Spalten_FZ1));
%         % for cnt=1:length(Spalten_FZ1), auswahl_Bereich2{cnt}=[Spalten_FZ1{cnt},'2:',Spalten_FZ2{cnt},letzte_Zeile_str]; end
%         %
%         % for cnt_ausw2=1:length(auswahl_Bereich2),
%         %     Bereich=h.Activesheet.get('Range', auswahl_Bereich2{cnt_ausw2});
%         %     BereichInterior=get(Bereich,'Interior');
%         %     set(BereichInterior,'Color',15921906) %hellgrau
%         % end
%         
%         %Summen f¸r Plot hinzuf¸gen:
%         clear auswahl_Anzahl_Spur
%         Spalten_FZ=Umrechnung_Spaltennummer2Spaltestring_Excel([6:2:size(neue_Cell,2)]);
%         auswahl_Anzahl_Spur=cell(1,length(Spalten_FZ));
%         for cnt=1:length(Spalten_FZ), auswahl_Anzahl_Spur{cnt}=[Spalten_FZ{cnt},letzte_Zeile_str]; end
%         Summe_str_zeile{cnt_i}=num2str(str2num(letzte_Zeile_str)+2);
%         
%         for cnt_ausw3=1:length(auswahl_Anzahl_Spur),
%             
%             %Auswahl Summen ¸ber Felder_Bereich zuordnen !!!!
%             auswahl_Summen{cnt_i,cnt_ausw3}=strcat(Spalten_FZ{cnt_ausw3},Summe_str_zeile{cnt_i});
%             
%             Bereich=h.Activesheet.get('Range', strcat(Spalten_FZ{cnt_ausw3}, Summe_str_zeile{cnt_i}));
%             Bereich.Value = strcat('=SUMME(', Spalten_FZ{cnt_ausw3},'2:', auswahl_Anzahl_Spur{cnt_ausw3},')');
%         end
%         
        
        
    end
    
    %Excel Arbeitsmappe speichern:
    
    % Pr¸fen, ob in "Excel_Dateinamen" ein Pfadname eingegeben wurde.
    % Falls nicht wird das cd gesetzt.
    [PATHSTR,NAME,EXT] = fileparts(Excel_Dateinamen);
    if isequal(PATHSTR, ''),
        PATHSTR = cd;
    end
    Excel_Dateinamen = fullfile(PATHSTR, [NAME,EXT]);
    Mappe.SaveAs(Excel_Dateinamen);
    
    %und schlieﬂen:
    Mappe.Close;
  
h.Quit;    
h.release;   
% h.delete;
    
    