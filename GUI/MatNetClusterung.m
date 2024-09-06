%% MatNetClusterung - MAIN
%
% benötigte externe Funktionen:
% * class_Clusterung
% * class_Kalender
% * findjobj 

function varargout = MatNetClusterung(varargin)
%MATNETCLUSTERUNG MATLAB code for MatNetClusterung.fig
%      MATNETCLUSTERUNG, by itself, creates a new MATNETCLUSTERUNG or raises the existing
%      singleton*.
%
%      H = MATNETCLUSTERUNG returns the handle to a new MATNETCLUSTERUNG or the handle to
%      the existing singleton*.
%
%      MATNETCLUSTERUNG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MATNETCLUSTERUNG.M with the given input arguments.
%
%      MATNETCLUSTERUNG('Property','Value',...) creates a new MATNETCLUSTERUNG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before MatNetClusterung_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to MatNetClusterung_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help MatNetClusterung

% Last Modified by GUIDE v2.5 12-Mar-2014 13:32:53

% add pathes with code 
addpath(genpath('../'))

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @MatNetClusterung_OpeningFcn, ...
    'gui_OutputFcn',  @MatNetClusterung_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT
end
function MatNetClusterung_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to MatNetClusterung (see VARARGIN)

% Choose default command line output for MatNetClusterung
handles.output = hObject;

handles.ClusterKalenderFigure = [];

% Zeiten aus dem Netz übernehmen
Standard_Startzeit = 734504;  % 01. Januar 2011
Standard_Endzeit   = 734868;  % 31. Dezember 2011

set(handles.ZeitBeginnCluster,'UserData',Standard_Startzeit,'String',datestr(Standard_Startzeit,'dd.mm.yyyy HH:MM:SS'))
set(handles.ZeitEndeCluster,'UserData',Standard_Endzeit,'String',datestr(Standard_Endzeit,'dd.mm.yyyy HH:MM:SS'))

% vorhandene Protokolle auslesen und darstellen
UpdateClusterungenTabelle(handles);

% Checkboxen für Kalender setzten:
set(handles.chkbox_Kalender_Montag, 'Value', true)
set(handles.chkbox_Kalender_Dienstag, 'Value', true)
set(handles.chkbox_Kalender_Mittwoch, 'Value', true)
set(handles.chkbox_Kalender_Donnerstag, 'Value', true)
set(handles.chkbox_Kalender_Freitag, 'Value', true)
set(handles.chkbox_Kalender_Samstag, 'Value', true)
set(handles.chkbox_Kalender_Sonntag, 'Value', true)
set(handles.chkbox_Kalender_Werktag, 'Value', true)
set(handles.chkbox_Kalender_Ferientag, 'Value', true)
set(handles.chkbox_Kalender_Feiertag, 'Value', true)
set(handles.chkbox_Kalender_Brueckentag, 'Value', true)
set(handles.chkbox_Kalender_Werktage_vor_Feiertag, 'Value', true)
set(handles.chkbox_Kalender_Spezialtag, 'Value', true)
set(handles.chkbox_Kalender_Sonstige_Tage, 'Value', true)

% Toolbar anpassen
delete(findall(handles.MatNetClusterung,'type','uipushtool'))
delete(findall(handles.MatNetClusterung,'tag','Annotation.InsertLegend'))
delete(findall(handles.MatNetClusterung,'tag','Annotation.InsertColorbar'))
delete(findall(handles.MatNetClusterung,'tag','DataManager.Linking'))
delete(findall(handles.MatNetClusterung,'tag','Exploration.DataCursor'))
delete(findall(handles.MatNetClusterung,'tag','Standard.EditPlot'))
delete(findall(handles.MatNetClusterung,'tag','Exploration.Brushing'))
delete(findall(handles.MatNetClusterung,'tag','Exploration.Rotate'))

handles.jtable=[]; % Platzhalter für JavaTabelle erzeugen

% das oberste YTickLabel der unteren Axes löschen (wegen Überlappung der Beschriftung)
YTick=get(handles.ClusterungMainLines,'Ytick');
set(handles.ClusterungSingleLines,'Ytick',YTick(1:end-1))

% Update handles structure
guidata(hObject, handles);

% leere Diagramme vorbereiten
UpdatePlots(handles);
% uistack(handles.EinstellungVorklassifizierungText,'top')
uistack(handles.AnalyseZeitintervalleText,'top')
uistack(handles.EinstellungClusterungText,'top')

% 1: Daten wurden eingelesen        => Clusterung kann angelegt werden.
% 2: Clusterung wurde eingelesen    => Clusterung kann gestart oder gelöscht werden
% 3: Clusterung wurdw gestartet     => Es können verschiedene Analysen durchgeführt werden
wie_Schalten = 'off';
welche_Buttons = [1, 2, 3]; % alle Buttons deaktivieren, da noch keine Daten eingelesen wurden
Buttons_Clusterung_an_aus(handles, wie_Schalten, welche_Buttons);

% Einstellungen zur Protokolldatei laden:
Dateiname_gespeicherte_ES = 'Zusatz_ES_Clusterung.mat';
Gespeicherte_Einstellungen = Lade_gespeicherte_Einstellungen(Dateiname_gespeicherte_ES);
% Globle Varibale definieren / aktualisieren:
global Einstellungen_Protokoll
Einstellungen_Protokoll.flag_DispOut            = Gespeicherte_Einstellungen.flag_Protokollfenster_anzeigen;
Einstellungen_Protokoll.flag_schreibe_in_Datei  = Gespeicherte_Einstellungen.flag_ProtokollDatei_fuehren;

end
function varargout = MatNetClusterung_OutputFcn(~, ~, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end
function JavaTableAktivieren() %#ok<DEFNU>
% Funktion die die Sortierfunktion für Spalten ind er Clusterungentabelle aktiviert
% muss extern und nach dem Erzeugen der gui aufgerufen werden
hObject=findall(0,'name','MatNetClusterung');
handles=guidata(hObject);
jscrollpane = findjobj(handles.ClusterungenTabelle);
jtable = jscrollpane.getViewport.getView;
jtable.setSortable(true);
jtable.setAutoResort(true);
jtable.setMultiColumnSortable(true);
jtable.setPreserveSelectionsAfterSorting(true);
jtable.setRowSelectionAllowed(0);
jtable.setColumnSelectionAllowed(0);
% WidthVec=[40 30 60 60 100 60 80 80 80 60 60 60 75 75 200];
WidthVec=[40 30 60 60 80 80 80 60 60 60 75 75 200];
for i=1:length(WidthVec)
    col=jtable.getColumnModel().getColumn(i-1);
    col.setPreferredWidth(WidthVec(i));
end
handles.jtable=jtable;
% Update handles structure
guidata(hObject, handles);
end

%% -------- KALENDER -----------
function ZeitBeginnCluster_CreateFcn(~, ~, ~) %#ok<DEFNU>
end
function ZeitEndeCluster_CreateFcn(~, ~, ~) %#ok<DEFNU>
end
function ExcelKalenderData_CreateFcn(hObject, ~, ~) %#ok<DEFNU>
% hObject    handle to ExcelKalenderData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
if exist('FerienFeierUndSpezialtage.xlsx','file')==2
    set(hObject,'string','FerienFeierUndSpezialtage.xlsx','UserData','FerienFeierUndSpezialtage.xlsx')
else
    set(hObject,'string',[],'UserData',[])
end
end
function WochentagButton_Callback(~, ~, ~) %#ok<DEFNU>
% hObject    handle to WochentagButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of WochentagButton
end
function WerktagButton_Callback(~, ~, ~) %#ok<DEFNU>
% hObject    handle to WerktagButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of WerktagButton
end
function FeiertagButton_Callback(~, ~, ~) %#ok<DEFNU>
% hObject    handle to FeiertagButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of FeiertagButton
end
function BrueckentagButton_Callback(~, ~, ~) %#ok<DEFNU>
% hObject    handle to BrueckentagButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of BrueckentagButton
end
function WerktagVorFeiertagButton_Callback(~, ~, ~) %#ok<DEFNU>
% hObject    handle to WerktagVorFeiertagButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of WerktagVorFeiertagButton
end
function SpezialtagButton_Callback(~, ~, ~) %#ok<DEFNU>
% hObject    handle to SpezialtagButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of SpezialtagButton
end
function FerientagButton_Callback(~, ~, ~) %#ok<DEFNU>
% hObject    handle to FerientagButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of FerientagButton
end
function ZeitEndeCluster_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    handle to ZeitEndeCluster (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
Zeit_Format = 'dd.mm.yyyy';
aktuelle_Zeit = datenum(get(hObject, 'String'), Zeit_Format);
SelectDate = uigetdate( aktuelle_Zeit );
set(hObject,'String',datestr(floor(SelectDate), Zeit_Format))

if SelectDate > get(handles.ZeitEndeText, 'UserData'),
    set(handles.ZeitEndeText, 'ForegroundColor', [1 0 0])
else
    set(handles.ZeitEndeText, 'ForegroundColor', [0 0 0])
end

end
function ZeitBeginnCluster_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    handle to ZeitBeginnCluster (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
Zeit_Format = 'dd.mm.yyyy';
aktuelle_Zeit = datenum(get(hObject, 'String'), Zeit_Format);
SelectDate = uigetdate( aktuelle_Zeit );
set(hObject,'String',datestr(floor(SelectDate), Zeit_Format))

if SelectDate < get(handles.ZeitBeginnText, 'UserData'),
    set(handles.ZeitBeginnText, 'ForegroundColor', [1 0 0])
else
    set(handles.ZeitBeginnText, 'ForegroundColor', [0 0 0])
end

end
function chkbox_Kalender_Montag_Callback(~, ~, ~),end
function chkbox_Kalender_Dienstag_Callback(~, ~, ~),end
function chkbox_Kalender_Mittwoch_Callback(~, ~, ~),end
function chkbox_Kalender_Donnerstag_Callback(~, ~, ~),end
function chkbox_Kalender_Freitag_Callback(~, ~, ~),end
function chkbox_Kalender_Samstag_Callback(~, ~, ~),end
function chkbox_Kalender_Sonntag_Callback(~, ~, ~),end
function chkbox_Kalender_Werktag_Callback(~, ~, ~),end
function chkbox_Kalender_Ferientag_Callback(~, ~, ~),end
function chkbox_Kalender_Feiertag_Callback(~, ~, ~),end
function chkbox_Kalender_Brueckentag_Callback(~, ~, ~),end
function chkbox_Kalender_Werktage_vor_Feiertag_Callback(~, ~, ~),end
function chkbox_Kalender_Sonstige_Tage_Callback(~, ~, ~),end
function chkbox_Kalender_Spezialtag_Callback(~, ~, ~), end
function push_Tage_filtern_Callback(hObject, ~, ~)
% Hier kann ausgewählt werden, welche einzelne Tage NICHT zur Clusteranalyse verwendet werden sollen.
% Die ausgewählten Tage werden in der UserData dieses pushbuttons gespeichert (hObject)

% Bisherige "Tage filtern":
Tage_filtern = get(hObject, 'UserData');
if any(Tage_filtern) && isnumeric(Tage_filtern)
    Tage_filtern_cell               = cell(1, length(Tage_filtern)*2 - 1); % vordimensionieren
    Tage_filtern_cell(1:2:end)      = num2cell(Tage_filtern); % Tage reinschreiben
    Tage_filtern_cell(1:2:end)      = cellfun(@num2str, Tage_filtern_cell(1:2:end), 'UniformOutput', false);
    [Tage_filtern_cell{2:2:end-1}]  = deal(', ');
    Tage_filtern_str                = [Tage_filtern_cell{:}];
else
    Tage_filtern_str = '';
end

h_fig = figure('Position', [600 500 500 200] ...
    ,'ToolBar','none' ...
    ,'NumberTitle','off' ...
    ,'MenuBar','none' ...
    ,'CloseRequestFcn','' ...
    );

h_txt1 = uicontrol(h_fig, 'Style', 'Text' ...
    ,'String', 'Zeitpunkte als Matlab-Zeit eingeben und als Trennzeichen der Tage ein Komma "," benutzen: Z.B.: "734811, 734812, 734813"' ...
    ,'Units', 'normalized' ...
    ,'Position', [0.05 0.51 0.9 0.1] ...
    ,'HorizontalAlignment', 'left' ...
    ,'BackgroundColor', get(h_fig, 'Color') ...
    );
h_txt2 = uicontrol(h_fig, 'Style', 'Text' ...
    ,'String', '' ...
    ,'Units', 'normalized' ...
    ,'Position', [0.05 0.8 0.4 0.1] ...
    ,'HorizontalAlignment', 'left' ...
    ,'BackgroundColor', get(h_fig, 'Color') ...
    );
h_edit = uicontrol(h_fig, 'Style', 'Edit' ...
    ,'String', Tage_filtern_str ...
    ,'Units', 'normalized' ...
    ,'Position', [0.05 0.45 0.9 0.1] ...
    ,'HorizontalAlignment', 'left' ...
    );
h_push_laden = uicontrol(h_fig, 'Style', 'PushButton' ...
    ,'String', 'Aus Datei laden' ...
    ,'Units', 'normalized' ...
    ,'Position', [0.7 0.7 0.25 0.2] ...
    ,'Callback', 'set(gcf,''UserData'',true), uiresume' ...
    );
h_push_Beenden = uicontrol(h_fig, 'Style', 'PushButton' ...
    ,'String', 'Beenden' ...
    ,'Units', 'normalized' ...
    ,'Position', [0.3 0.1 0.4 0.2] ...
    ,'Callback', 'set(gcf,''UserData'',false), uiresume' ...
    );

uiwait % warte auf eingabe

while 1
    if get(h_fig,'UserData') == true
        % Datei laden:
        [filename, pathname] = uigetfile( ...
            {'*.mat','MAT-files (*.mat)'; ...
            '*.*',  'All Files (*.*)'}, ...
            'Datei auswählen', ...
            'MultiSelect', 'off');
        Daten = load(fullfile(pathname,filename));
        Felder = fieldnames(Daten); Daten = Daten.(Felder{1});
        if isnumeric(Daten)
            % Daten in das Edit Feld eintragen:
            Daten_eine_Zeile = cell(1, numel(Daten)*2 - 1);
            Daten_eine_Zeile(2:2:end-1) = {', '};
            Daten_eine_Zeile(1:2:end) = cellfun(@num2str, num2cell(Daten), 'UniformOutput', false);
            
            set(h_edit, 'String', [Daten_eine_Zeile{:}]);
            set(h_txt2, 'String', '');
        else
            set(h_txt2, 'String', 'Fehler beim Einlesen !!!');
        end
        uiwait
    else
        try
            % Daten zu handles Schreiben:
            Tage_String = get(h_edit, 'String');
            %todo: replace string_teilen mit split
            Tage_String = String_teilen(Tage_String,',');
            if iscell(Tage_String)
                Tage_filtern = cellfun(@str2double, Tage_String);
            else
                Tage_filtern = str2double(Tage_String);
            end
            set(hObject, 'UserData', floor(Tage_filtern));
            
            delete(h_fig)
            break
        catch
            disp('Tage filtern fehlgeschlagen')
            delete(h_fig)
            break
        end
        
    end
end % while




end

%% Clusterung - Hauptteil
function ClusterungNeu_Callback(hObject, ~, handles) %#ok<DEFNU>
try
    if ishandle(handles.ClusterKalenderFigure)
        close(handles.ClusterKalenderFigure) % Der bisherige Clusterkalender wird geschlossen.
        handles.ClusterKalenderFigure = [];
    end
    
    MyDisp('Clusterung wird angelegt')
    Data = get(handles.Data_ClusterData, 'UserData');
    
    if isempty(Data) || ~isstruct(Data) || ~isfield(Data, 'Daten')
        MyDisp('Fehler: Noch keine Cluster Daten ausgewählt.', [0 1 0])
    else
        % Daten sind vorhanden:
        % Bei Bedarf Zeitlich filtern:
        Zeit_Format = 'dd.mm.yyyy';
        Zeit_von = datenum(get(handles.ZeitBeginnCluster, 'String'), Zeit_Format);
        Zeit_bis = datenum(get(handles.ZeitEndeCluster  , 'String'), Zeit_Format) + 1; % Der Tag selbst soll auch noch mitgeclustert werden.
        
        idx_ausfiltern = Data.Daten(:,1) < Zeit_von | Data.Daten(:,1) > Zeit_bis;
        Data.Daten(idx_ausfiltern, :) = []; % Es werden nur ganze "Zeilen" ausgefiltert.
        ClusterData = Data.Daten;
        MyDisp('ClusterData übernommen.')
        
        %% Prüfen ob zusätzliche Eigenschaften vorhanden sind:
        MyDisp('Prüfen ob zusätzliche Eigenschaften vorhanden sind.')
        zus_Eigenschaften = get(handles.Datei_zus_Eigenschaften, 'UserData');
        if ~isempty(zus_Eigenschaften) && isstruct(zus_Eigenschaften) && isfield(zus_Eigenschaften, 'Daten') && iscell(zus_Eigenschaften.Daten)
            % zus_Eigenschaften ist vorhanden
            Zeiten_zus_Eig = cell2mat(zus_Eigenschaften.Daten(:,1));
            
            % Zuordnung der Eigenschaften zu den ClusterDaten:
            [~, idx_Zuordnung] = ismember(floor(Zeiten_zus_Eig), floor(ClusterData(:,1)));
            
            Anzahl_Eigenschaften = length(zus_Eigenschaften.Bezeichnung_der_Eigenschaft);
            
            for cnt_zus_Eig = 1 : Anzahl_Eigenschaften
                
                Bez_akt_zus_Eig = zus_Eigenschaften.Bezeichnung_der_Eigenschaft{cnt_zus_Eig};
                % Falls Sonderzeichen o.Ä. enthalten sind müssen diese verändert werden, da manche Zeichen nicht als
                % Feldname erlaubt sind:
                Bez_akt_zus_Eig = Struct_Feldname_richtig(Bez_akt_zus_Eig);
                
                zus_Eig_zu_Clusterdata = cell(size(ClusterData,1),1);    % vordimensionieren
                [zus_Eig_zu_Clusterdata{:}] = deal('nicht zugeordnet');  % vordimensionieren
                Spalte_akt_zus_Eig = cnt_zus_Eig + 1;
                zus_Eig_zu_Clusterdata(idx_Zuordnung(idx_Zuordnung ~= 0)) = zus_Eigenschaften.Daten(idx_Zuordnung ~= 0, Spalte_akt_zus_Eig);
                % Falls Felder leer oder numerisch sind, müssen diese auf mit Strings gefüllt werden:
                idx_Feld_leer = cellfun(@isempty, zus_Eig_zu_Clusterdata) | cellfun(@isnumeric, zus_Eig_zu_Clusterdata);
                zus_Eig_zu_Clusterdata(idx_Feld_leer) = {'leer'};
                
                Eigenschaften.(Bez_akt_zus_Eig) = zus_Eig_zu_Clusterdata;
                
            end
            MyDisp('Zusätzliche Eigenschaften übernommen.')
        else
            % keine zusätzliche Eigenschaften vorhanden
            MyDisp('Keine zusätzliche Eigenschaften ausgewählt.')
            Eigenschaften = [];
        end
        
        % Erstellen des ParamSets aus der gui
        Methoden                = {'Kmeans', 'single', 'complete', 'average', 'weighted', 'median', 'ward'};
        Distanzfunktionen       = {'GEH', 'Euclidean_mit_NaN'}; %, 'Vortisch_formel', 'Pillat_formel'}; 
        Auswahl_Startcluster    = {'sample', 'uniform', 'cluster'};
        
        % Die Auswahl der Tage in ParamSet übergeben:
        Auswahl_Tage = struct(   ...
            'Montag',                  get(handles.chkbox_Kalender_Montag, 'Value') ...
            ,'Dienstag',                get(handles.chkbox_Kalender_Dienstag, 'Value') ...
            ,'Mittwoch',                get(handles.chkbox_Kalender_Mittwoch, 'Value') ...
            ,'Donnerstag',              get(handles.chkbox_Kalender_Donnerstag, 'Value') ...
            ,'Freitag',                 get(handles.chkbox_Kalender_Freitag, 'Value') ...
            ,'Samstag',                 get(handles.chkbox_Kalender_Samstag, 'Value') ...
            ,'Sonntag',                 get(handles.chkbox_Kalender_Sonntag, 'Value') ...
            ,'Werktag',                 get(handles.chkbox_Kalender_Werktag, 'Value') ...
            ,'Ferientag',               get(handles.chkbox_Kalender_Ferientag, 'Value') ...
            ,'Feiertag',                get(handles.chkbox_Kalender_Feiertag, 'Value') ...
            ,'Brueckentag',             get(handles.chkbox_Kalender_Brueckentag, 'Value') ...
            ,'Werktage_vor_Feiertag',   get(handles.chkbox_Kalender_Werktage_vor_Feiertag, 'Value') ...
            ,'Spezialtag',              get(handles.chkbox_Kalender_Spezialtag, 'Value') ...
            ,'Sonstige_Tage',           get(handles.chkbox_Kalender_Sonstige_Tage, 'Value') ...
            );
        
        MyDisp('Auslesen der Cluster Parameter.')
        ParamSet = struct('Methode',Methoden{get(handles.ClusterMethodeList,'Value')} ...
            ,'Distanzfunktion',Distanzfunktionen{get(handles.DistanzMethodeList,'Value')} ...
            ,'ClusterAnzahlAbs',get(handles.ClusterZahlAbs,'UserData') ...
            ,'ClusterAnzahlRel', 1 ... %get(handles.ClusterZahlRel,'UserData')/100 ... % es wird der kleinere Wert aus ClusterAnzahlAbs und ClusterAnzahlRel*AnzahlTage gewählt
            ,'CutOff',get(handles.CutOff,'UserData')*ones(get(handles.CutOff,'UserData')~=0) ...
            ,'Auswahl_Startcluster',Auswahl_Startcluster{get(handles.KmeansStartList,'Value')} ...
            ,'Replicates',get(handles.KmeansReplicates,'UserData') ...
            ,'Auswahl_Tage', Auswahl_Tage ...
            ,'Tage_filtern', []);
        
        %% Zusatz Einstellungen laden:
        MyDisp('Zusatz Einstellungen laden.')
        Dateiname_gespeicherte_ES = 'Zusatz_ES_Clusterung.mat';
        Zusaetzliche_Eigenschaften = Lade_gespeicherte_Einstellungen(Dateiname_gespeicherte_ES);
        
        % neue Clusterung anlegen (mit ParamSet)
        MyDisp('Klasse Clusterung wird angelegt.')
        Clusterung = class_Clusterung(ClusterData, ParamSet, Eigenschaften, Zusaetzliche_Eigenschaften);
        
        % wo speichere ich die Clusterungen?
        Clusterungen = get(handles.ClusterungNeu, 'UserData');
        if isempty(Clusterungen) || ~isa(Clusterung, 'class_Clusterung')
            Clusterungen = Clusterung;
        else
            Clusterungen(end + 1) = Clusterung;
        end
        Clusterungen(end).Nr = max([Clusterungen.Nr]) + 1; %length(Clusterungen);  % Die Nr der Clusterung setzten.
        set(handles.ClusterungNeu, 'UserData', Clusterungen);
        
        % Das Folgende wird nur durchgeführt, wenn das Erzeugen einer Clusterung erfolgreich war.
        if Clusterung.Initialisiert,
            % Berechnen der Silhouette-Werte der Vorklassifizierung
            % Clusterung.SilhouetteVorklassifizierungBerechnen;
            
            MyDisp('Vorhandenen Plots löschen.')
            % alte Zeichnungen löschen, neue Clusterung auf aktiv setzen und vorhandene Clusterungen neu darstellen
            set(handles.ClusterungenTabelle,'UserData',Clusterung.Nr)
            
            MyDisp('Clusterung wird in die Tabelle eingetragen.')
            UpdateClusterungenTabelle(handles);
            UpdatePlots(handles)
        end
        
        MyDisp('div. Buttons aktivieren.')
        % Die Buttons zum Starten der Clusterung und löschen können aktiviert werden.
        wie_Schalten = 'on';
        welche_Buttons = 2;
        Buttons_Clusterung_an_aus(handles, wie_Schalten, welche_Buttons);
        % Die Buttons zur Auswertung werden deaktiviert, weil die Clusterung noch nicht gestartet wurde.
        wie_Schalten = 'off';
        welche_Buttons = 3;
        Buttons_Clusterung_an_aus(handles, wie_Schalten, welche_Buttons);
        MyDisp('Anlegen der Clusterung erfolgreich.', [0 1 0])
        
    end
catch
    MyDisp('Anlegen der Clusterung nicht erfolgreich.', [1 0 0])
end
end
function ClusterungStarten_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    handle to ClusterungStarten (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    if ishandle(handles.ClusterKalenderFigure)
        close(handles.ClusterKalenderFigure) % Der bisherige Clusterkalender wird geschlossen.
        handles.ClusterKalenderFigure = [];
    end
Clusterungen = get(handles.ClusterungNeu, 'UserData');
if get(handles.ClusterungenTabelle,'UserData')~=0
    MyDisp('Clusterung wird gestartet.')
    try
    Clusterungen([Clusterungen.Nr] == get(handles.ClusterungenTabelle,'UserData')).Clustern(); % Hier sind eigene MyDisps beinhaltet.
    
    
    MyDisp('Clusterung Tabelle wird aktualisiert.')
    UpdateClusterungenTabelle(handles);
    UpdatePlots(handles); % Hier sind eigene MyDisps beinhaltet.
    
    % Clusterung wurde gestartet     => Es können verschiedene Analysen durchgeführt werden
    wie_Schalten = 'on';
    welche_Buttons = [1, 2, 3];
    Buttons_Clusterung_an_aus(handles, wie_Schalten, welche_Buttons);
    catch
        MyDisp('Clusterung fehlgeschlagen.', [1 0 0])
    end
else
    MyDisp('Keine Clusterung zum starten ausgewählt.')
end
end

%% Auswertungen (Buttons)
function DrawClusterKalender_Callback(hObject, ~, handles) %#ok<DEFNU>
Clusterungen = get(handles.ClusterungNeu, 'UserData');
% --- Executes on button press in DrawClusterKalender.
% hObject    handle to DrawClusterKalender (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(handles.ClusterungenTabelle,'UserData')~=0
    if ~isempty(Clusterungen([Clusterungen.Nr]==get(handles.ClusterungenTabelle,'UserData')).KalenderClusterung)
        if ishandle(handles.ClusterKalenderFigure),
            close(handles.ClusterKalenderFigure) % Der bisherige Clusterkalender wird geschlossen.
            handles.ClusterKalenderFigure = [];
        end
        
        handles.ClusterKalenderFigure = Clusterungen([Clusterungen.Nr]==get(handles.ClusterungenTabelle,'UserData')).KalenderClusterung.Draw;
        % Update handles structure
        guidata(hObject, handles);
        % Umbenennen...
        set(handles.ClusterKalenderFigure,'name',['Kalenderdarstellung Clusterung Nr: ',num2str(get(handles.ClusterungenTabelle,'UserData'))],'tag',['KalenderClusterung',num2str(get(handles.ClusterungenTabelle,'UserData'))])
        % ...und ButtonDownFcns aktivieren
        % ggfs. buttondownFcn des Kalenders aktivieren
        if ~isempty(handles.ClusterKalenderFigure)
            if ~ishandle(handles.ClusterKalenderFigure),
                handles.ClusterKalenderFigure = [];
                % Update handles structure
                guidata(hObject, handles);
            else
                set(findall(handles.ClusterKalenderFigure,'parent',findall(handles.ClusterKalenderFigure,'tag','axHandleCalendar'),'-and','type','text'),'ButtonDownFcn',@(src,event) ClusterButtonDownCallback(src,event,handles))
                set(findall(handles.ClusterKalenderFigure,'parent',findall(handles.ClusterKalenderFigure,'tag','axHandleCalendar'),'-and','type','patch'),'ButtonDownFcn',@(src,event) ClusterButtonDownCallback(src,event,handles))
            end
        end
        
    end
    set(handles.ClusterKalenderFigure, 'UserData', handles)
end
end
function CopyAxesClusterungAxes_Callback(~, ~, handles) %#ok<DEFNU>
% --- Executes on button press in CopyAxesClusterungAxes.
% hObject    handle to CopyAxesClusterungAxes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
figHandle=figure;
set(findall(handles.MatNetClusterung,'type','axes'),'units','normalized')
copyobj([handles.ClusterungAxes legend(handles.ClusterungAxes)],figHandle);
set(findall(figHandle,'type','axes','-and','tag','ClusterungAxes'),'units','normalized','position',[0.13 0.14 0.675 0.8])
% Legend nach vorne bringen und positionieren
uistack(findall(figHandle,'tag','legend'),'top');
LegPos=get(findall(figHandle,'tag','legend'),'position');
if ~isempty(LegPos)
    set(findall(figHandle,'tag','legend'),'position',[0.82 LegPos(2:4)]);
end
VuVFigure(figHandle);
set(figHandle,'Name','Clusterungsdaten')
end
function UpdatePlots(handles)
% Axes für neue Plots vorbereiten/löschen
try
cla(handles.ClusterungAxes); legend(handles.ClusterungAxes, 'off');
cla(handles.ClusterungMainLines)
cla(handles.ClusterungSingleLines)
delete(findall(handles.MatNetClusterung,'tag','legend'))

Clusterungen = get(handles.ClusterungNeu, 'UserData');

flag_Clusterung_angelegt = get(handles.ClusterungenTabelle,'UserData')~=0; % Es gibt eine angelegte Clusterung
if flag_Clusterung_angelegt,
    idx_Clusterung = [Clusterungen.Nr]==get(handles.ClusterungenTabelle,'UserData');
    flag_Clusterung_gestartet = ~isempty(Clusterungen(idx_Clusterung).ClusterLinien);
end

% wenn eine ClusterNr markiert ist und diese gestartet wurde dann die Clusterlinien und die Wochentagsübersicht zeichnen...
if flag_Clusterung_angelegt && flag_Clusterung_gestartet
    
    Name_keine_Eigenschaft = '-1';
    % Update popup_plot_Eigenschaft:
    if isstruct(Clusterungen(idx_Clusterung).Eigenschaften)
        Felder_Eigenschaften = fieldnames(Clusterungen(idx_Clusterung).Eigenschaften);
        set(handles.popup_plot_Eigenschaft ...
            ,'String', Felder_Eigenschaften ...
            ,'Enable', 'on' ...
            );
    else
        % Es gibt keine Eigenschaften.
        set(handles.popup_plot_Eigenschaft, 'Value', 1)
        set(handles.popup_plot_Eigenschaft ,'Enable', 'off')
        set(handles.popup_plot_Eigenschaft ,'String', Name_keine_Eigenschaft)
    end
    
    Eintraege_Eigenschaft = get(handles.popup_plot_Eigenschaft, 'String');
    if iscell(Eintraege_Eigenschaft),
        idx_Wochentag = find(ismember(Eintraege_Eigenschaft, 'Wochentag'));
    else
        idx_Wochentag = isequal(Eintraege_Eigenschaft, 'Wochentag');
    end
    if any(idx_Wochentag),
        Eigenschaft1 = 'Wochentag';
        set(handles.popup_plot_Eigenschaft, 'Value', idx_Wochentag)
    else
        Eigenschaften_ALLE = get(handles.popup_plot_Eigenschaft, 'String');
        if isequal(Eigenschaften_ALLE, Name_keine_Eigenschaft)
            Eigenschaft1 = ''; % Es gibt keine Eigenschaft
        else
            Eigenschaft1 = Eigenschaften_ALLE(get(handles.popup_plot_Eigenschaft, 'Value'));
        end
    end
    MyDisp('Eigenschaften der Cluster werden dargestellt.')
    Clusterungen(idx_Clusterung).DrawEigenschaft(handles.ClusterungAxes, Eigenschaft1);
    MyDisp('Cluster Linien werden dargestellt.')
    Clusterungen(idx_Clusterung).DrawCluster(handles.ClusterungMainLines,Clusterungen([Clusterungen.Nr]==get(handles.ClusterungenTabelle,'UserData')).KalenderClusterung.TagTypen.Nr(2:end),[],true,false);
    MyDisp('Einzelne Tage werden dargestellt.')
    Clusterungen(idx_Clusterung).DrawCluster(handles.ClusterungSingleLines,Clusterungen([Clusterungen.Nr]==get(handles.ClusterungenTabelle,'UserData')).KalenderClusterung.TagTypen.Nr(2:end),[],false,true);
    % Legends der Clusterlinien-Axes löschen (diese sind i.A. zu viele)
    legend(handles.ClusterungMainLines,'off')
    legend(handles.ClusterungSingleLines,'off')
    % Achsenlabels ggfs. wieder aktivieren
    set(handles.ClusterungAxes,'XTickMode','auto','XTickLabelMode','auto')
    set(handles.ClusterungMainLines,'XTick',[],'YTickMode','auto','YTickLabelMode','auto')
    set(handles.ClusterungSingleLines,'XTickMode','auto','XTickLabelMode','auto','YTickMode','auto','YTickLabelMode','auto')
    
    % buttondownFcn aktivieren
    % Sowohl für die Balken, als auch für die Axes:
    set(findobj(get(handles.ClusterungAxes,'children'),'type','hggroup'),'ButtonDownFcn',@(src,event) ClusterButtonDownCallback(src,event,handles))
    set(handles.ClusterungAxes, 'ButtonDownFcn', @(src,event) ClusterButtonDownCallback(src,event,handles))
    
else
    % ...andernfalls werden die Achsenlabels zurückgesetzt
    set(handles.ClusterungAxes,'XLim',[0 1],'YLim',[0 1],'XTick',[0 1],'XTickLabelMode','auto','YTick',[0 1],'YTickLabelMode','auto')
    set(handles.ClusterungMainLines,'XLim',[0 1],'YLim',[0 1],'XTick',[],'XTickLabelMode','auto','YTick',[0 1],'YTickLabelMode','auto')
    set(handles.ClusterungSingleLines,'XLim',[0 1],'YLim',[0 1],'XTick',[0 1],'XTickLabelMode','auto','YTick',[0 1],'YTickLabelMode','auto')
    text(0.5,0.5,sprintf('Keine Clusterung ausgewählt\noder die ausgewählte Clusterung wurde noch nicht durchgeführt'),'Parent',handles.ClusterungAxes,'HorizontalAlignment','Center','clipping','on');
    text(0.5,0.5,sprintf('Keine Clusterung ausgewählt\noder die ausgewählte Clusterung wurde noch nicht durchgeführt'),'Parent',handles.ClusterungMainLines,'HorizontalAlignment','Center','clipping','on');
    text(0.5,0.5,sprintf('Keine Clusterung ausgewählt\noder die ausgewählte Clusterung wurde noch nicht durchgeführt'),'Parent',handles.ClusterungSingleLines,'HorizontalAlignment','Center','clipping','on');
end

% Diagrammnachbereitung
% das oberste YTickLabel der unteren Axes löschen (wegen Überlappung der Beschriftung)
YTick=get(handles.ClusterungMainLines,'Ytick');
set(handles.ClusterungSingleLines,'Ytick',YTick(1:end-1))
% und die X-Achsenbeschriftung der oberen Axes löschen bzw die Y-Achsen beschriften
delete(get(handles.ClusterungMainLines,'Xlabel'))
set(get(handles.ClusterungMainLines,'Ylabel'),'String',sprintf('Werte der Cluster')) % \n ist Zeilenumbruch
set(get(handles.ClusterungSingleLines,'Ylabel'),'String',sprintf('Werte der einzelnen Tage'))
xlabel(handles.ClusterungAxes,'Anzahl Tage')
ylabel(handles.ClusterungAxes,'Cluster')
% DrawAxes verbinden
linkaxes([handles.ClusterungMainLines handles.ClusterungSingleLines],'xy')
catch
    MyDisp('Fehler bei der Darstellung der Clusterung', [1 0 0])
end
end
function UpdateClusterungenTabelle(handles)
Clusterungen = get(handles.ClusterungNeu, 'UserData');
if isempty(Clusterungen)
    % Leere Cell erzeugen
    data=cell(0,15);
    set(handles.ClusterungenTabelle,'UserData',0)
else
    % Daten auslesen und passend formatieren
    Aktiv = cell(size(Clusterungen,2),1);
    [Aktiv{:}] = deal(false);
    if get(handles.ClusterungenTabelle,'UserData')~=0 % ggfs. ein Protokoll aktiv setzen
        Aktiv{get(handles.ClusterungenTabelle,'UserData')==[Clusterungen.Nr]}=true;
    end
    Nrn={Clusterungen.Nr}';
    ZeitBeginne=cellfun(@(x) datestr(x,'dd.mm.yyyy'),{Clusterungen.ZeitBeginn}','uniformoutput',false);
    ZeitEnden=cellfun(@(x) datestr(x,'dd.mm.yyyy'),{Clusterungen.ZeitEnde}','uniformoutput',false);
    %ZeitSchrittweiten=cellfun(@(x) datestr(x,'HH:MM'),{Clusterungen.ZeitSchrittweite}','uniformoutput',false);
    
    %AnzahlDetektorgruppen = cellfun(@length, {Clusterungen.Detektorgruppen_ID},'uniformoutput',false)';
    
    ParamSets       = [Clusterungen.ParamSet];
    Methoden        = {ParamSets.Methode}';
    Dists           = {ParamSets.Distanzfunktion}';
    MaxClustAbs     = {ParamSets.ClusterAnzahlAbs}';
    MaxClustRel     = cellfun(@(x) 100*x,{ParamSets.ClusterAnzahlRel},'uniformoutput',false)';
    CutOffs         = {ParamSets.CutOff}';
    Startcluster    = {ParamSets.Auswahl_Startcluster}';
    Replicates      = {ParamSets.Replicates}';
    
    %     tmpVorKal=[Clusterungen.KalenderVorklassifizierung];
    %     tmpVorKalTagTypen=[tmpVorKal.TagTypen];
    %     AnzVorklassen=cellfun(@(x) sum(x>0),{tmpVorKalTagTypen.Nr},'uniformoutput',false)';
    
    AnzCluster=cell(size(Aktiv));
    for i=1:size(AnzCluster,1)
        if ~isempty(Clusterungen(i).KalenderClusterung)
            AnzCluster{i,1} = length(Clusterungen(i).KalenderClusterung.TagTypen.Nr)-1;
        end
    end
    
    %     VorklassifizierungText=cellfun(@(x) x{1},{tmpVorKalTagTypen.Kategorien},'uniformoutput',false)';
    
    %     data=[Aktiv,Nrn,ZeitBeginne,ZeitEnden,Methoden,Dists,MaxClustAbs,MaxClustRel,CutOffs,Startcluster,Replicates,AnzVorklassen,AnzCluster,VorklassifizierungText];
    data=[Aktiv,Nrn,ZeitBeginne,ZeitEnden,Methoden,Dists,MaxClustAbs,MaxClustRel,CutOffs,Startcluster,Replicates,AnzCluster];
end
% uitable füllen
set(handles.ClusterungenTabelle,...
    'data',data,...
    ... %'ColumnName',{'Aktiv','Nr','Beginn','Ende','Zeitschrittweite','#DG','Methode','Distfunktion','MaxClustAbs','MaxClustRel','CutOff','Startbel.','Wdhlg.','#Vorklassen','#AnzCluster','Vorklassifizierung nach'},...
    'ColumnName',{'Aktiv','Nr','Beginn','Ende','Methode','Distfunktion','MaxClustAbs','MaxClustRel','CutOff','Startbel.','Wdhlg.','#AnzCluster'},...
    ... %'ColumnFormat',{'logical','char','char','char','char','char','char','char','char','char','char','char','char','char','char','char'},...
    'ColumnFormat',{'logical','char','char','char','char','char','char','char','char','char','char','char'},...
    'ColumnEditable',[true false(1,size(data,2)-1)],...
    ... %'ColumnWidth',{40 30 60 60 100 40 60 80 80 80 60 60 60 75 75 200},...
    'ColumnWidth',{40 30 60 60 60 80 80 80 60 60 60 75},...
    'RowName',[]);
end
function ClusterungenTabelle_CellEditCallback(hObject, eventdata, handles) %#ok<DEFNU>
% hObject    handle to ClusterungenTabelle (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)

if ishandle(handles.ClusterKalenderFigure),
    close(handles.ClusterKalenderFigure) % Der bisherige Clusterkalender wird geschlossen.
    handles.ClusterKalenderFigure = [];
end
if size(eventdata.Indices,1) > 0
    % Nr des ausgewählten Protokolls übernehmen und dafür sorgen, dass immer nur eine Zeile aktiv ist (und die ColumnWidth fest halten, die verstellt sich sonst manchmal)
    tmpData=get(handles.ClusterungenTabelle,'data');
    SetValue=tmpData{eventdata.Indices(1,1),1};
    [tmpData{:,1}]=deal(false);
    tmpData{eventdata.Indices(1,1),1}=SetValue;
    set(handles.ClusterungenTabelle,'data',tmpData,'ColumnWidth',{40 30 60 60 100 40 60 80 80 80 60 60 60 75 75 200});
    
    if SetValue
        set(handles.ClusterungenTabelle,'UserData',tmpData{eventdata.Indices(1,1),2})
    else
        set(handles.ClusterungenTabelle,'UserData',0)
    end
    UpdatePlots(handles)
    
    % Es wurde eine neue Clusterung ausgewählt:
    % Es muss geprüft werden, ob diese Clusterung bereits gestartet wurde.
    if SetValue, % Eine Clusterung wurde auswählt:
        Clusterungen = get(handles.ClusterungNeu, 'UserData');
        idx_Clusterung = [Clusterungen.Nr]==get(handles.ClusterungenTabelle,'UserData');
        % Clusterungen(idx_Clusterung)
        if isempty(Clusterungen(idx_Clusterung).ClusterLinien), % aktuelle Clusterung wurde nocht nicht gestartet = keine ClusterLinien
            % Clusterung wurde noch nicht gestartet => Buttons Clusterung starten und löschen 'on', weitere Auswertung 'off'
            wie_Schalten = 'on';
            welche_Buttons = 2; % alle Buttons
            Buttons_Clusterung_an_aus(handles, wie_Schalten, welche_Buttons);
            wie_Schalten = 'off';
            welche_Buttons = 3; % alle Buttons
            Buttons_Clusterung_an_aus(handles, wie_Schalten, welche_Buttons);
        else
            % Clusterung wurde bereits gestartet => Alle Buttons 'on'
            wie_Schalten = 'on';
            welche_Buttons = [1, 2, 3]; % alle Buttons
            Buttons_Clusterung_an_aus(handles, wie_Schalten, welche_Buttons);
        end
    else
        % Eine Clusterung wurde deselektiert = es gibt keine aktive Clusterung
        wie_Schalten = 'off';
        welche_Buttons = [2, 3]; % alle Buttons
        Buttons_Clusterung_an_aus(handles, wie_Schalten, welche_Buttons);
    end
end
end
function ClusterungDelete_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    handle to ClusterungDelete (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
Clusterungen = get(handles.ClusterungNeu, 'UserData');

if ishandle(handles.ClusterKalenderFigure),
    close(handles.ClusterKalenderFigure) % Der bisherige Clusterkalender wird geschlossen.
    handles.ClusterKalenderFigure = [];
end

if get(handles.ClusterungenTabelle,'UserData')~=0
    if strcmpi('ja',questdlg(sprintf('Clusterung wirklich löschen?'),'Clusterung löschen','Ja','Nein','Nein'))
        Clusterungen([Clusterungen.Nr]==get(handles.ClusterungenTabelle,'UserData')) = [];
        set(handles.ClusterungNeu, 'UserData', Clusterungen);
        set(handles.ClusterungenTabelle,'UserData',0)
        UpdateClusterungenTabelle(handles)
        
        delete(get(handles.ClusterungAxes,'children'))
        delete(get(handles.ClusterungMainLines,'children'))
        delete(get(handles.ClusterungSingleLines,'children'))
        cla(handles.ClusterungAxes); legend(handles.ClusterungAxes, 'off');
        cla(handles.ClusterungMainLines);
        cla(handles.ClusterungSingleLines);
        delete(findall(handles.MatNetClusterung,'tag','legend'));
        UpdatePlots(handles);
    end
    
    % Wenn eine Clusterung gelöscht wird, ist keine Clusterung mehr aktiv =>
    welche_Buttons = [2, 3]; % da keine Clusterung aktiv ist, soll die Buttons 2 deaktiviert werden.
    wie_Schalten = 'off';
    Buttons_Clusterung_an_aus(handles, wie_Schalten, welche_Buttons);
    
end
end
function CopyAxesClusterungLines_Callback(~, ~, handles) %#ok<DEFNU>
% hObject    handle to CopyAxesClusterungLines (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
figHandle=figure;
set(findall(handles.MatNetClusterung,'type','axes'),'units','normalized')
copyobj([handles.ClusterungMainLines handles.ClusterungSingleLines legend(handles.ClusterungMainLines)],figHandle);
ClusterungMainLinesNew=findall(figHandle,'type','axes','-and','tag','ClusterungMainLines');
ClusterungSingleLinesNew=findall(figHandle,'type','axes','-and','tag','ClusterungSingleLines');

% Achsen anpassen und abstimmen
YTick=get(ClusterungMainLinesNew,'Ytick');
set(ClusterungMainLinesNew,'units','normalized','position',[0.13 0.54 0.775 0.4])
set(ClusterungSingleLinesNew,'units','normalized','position',[0.13 0.14 0.775 0.4],'Xtick',[],'Ytick',YTick(1:end-1))
delete(get(ClusterungMainLinesNew,'XLabel'))

% Legend nach vorne bringen und positionieren
if ~isempty(findall(figHandle,'tag','legend'))
    uistack(findall(figHandle,'tag','legend'),'top');
    LegPos=get(findall(figHandle,'tag','legend'),'position');
    set(findall(figHandle,'tag','legend'),'position',[(1-LegPos(3))/2 1-LegPos(4)*1.1 LegPos(3:4)])
end

VuVFigure(figHandle,[]);

set(figHandle,'Name','Clusterung - Netzganglinien')
% DrawAxes verbinden
linkaxes([ClusterungMainLinesNew ClusterungSingleLinesNew],'xy')
end
function ClearAxesClusterungLines_Callback(~, ~, handles) %#ok<DEFNU>
% hObject    handle to ClearAxesClusterungLines (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
cla(handles.ClusterungMainLines)
cla(handles.ClusterungSingleLines)
% Legends der Clusterlinien-Axes
legend(handles.ClusterungMainLines,'off')
legend(handles.ClusterungSingleLines,'off')
end
function DrawSilhouette_Callback(~, ~, handles) %#ok<DEFNU>
% hObject    handle to DrawSilhouette (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
Clusterungen = get(handles.ClusterungNeu, 'UserData');
if get(handles.ClusterungenTabelle,'UserData')~=0
    if isempty(Clusterungen([Clusterungen.Nr]==get(handles.ClusterungenTabelle,'UserData')).SilhouetteDataVorklassifizierung),
        % Wenn die Silhouette der Vorklassifizierung noch nicht berechnet wurde:
        % Clusterungen(end).SilhouetteVorklassifizierungBerechnen;
    end
    
    Clusterungen([Clusterungen.Nr]==get(handles.ClusterungenTabelle,'UserData')).DrawSilhouette();
    set(findall(0,'tag','silhouette','-and','Type','figure'),'name',['Silhouette-Werte Clusterung Nr: ',num2str(get(handles.ClusterungenTabelle,'UserData'))],'tag',['silhouette',num2str(get(handles.ClusterungenTabelle,'UserData'))])
end
end
function DrawDistMatrix_Callback(~, ~, handles) %#ok<DEFNU>
% hObject    handle to DrawDistMatrix (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
Clusterungen = get(handles.ClusterungNeu, 'UserData');
if get(handles.ClusterungenTabelle,'UserData')~=0
    
    %%
    ClusterIndex=find(get(handles.ClusterungenTabelle,'UserData')==[Clusterungen.Nr]);
    if ~isempty(Clusterungen(ClusterIndex).KalenderClusterung)
        
        
        Dist = GEH(Clusterungen(ClusterIndex).ClusterData(:,2:end), Clusterungen(ClusterIndex).ClusterData(:,2:end));
        CIndex  = Clusterungen(ClusterIndex).KalenderClusterung.KalenderData.TagTypNr;
        CIndex(CIndex == 0) = []; % Das sind Tage, die nicht geclustert werden, da sie keine (vernünftigen) Daten haben
        
        
        [~,CSort] = sort(CIndex); % Indizierung der Sortierung
        
        figHandle = VuVFigure(figure);
        Axh(1) = subplot('position',[0.05 0.55 0.95 0.4],'box','on');
        hold(Axh(1),'on')
        Axh(2) = subplot('position',[0.05 0.1 0.95 0.4],'box','on');
        hold(Axh(2),'on')
        
        surf(Axh(1),Dist,'Edgecolor','none','facecolor','interp')
        ylabel(Axh(1),'Kalenderreihenfolge')
        
        surf(Axh(2),Dist(CSort,CSort),'Edgecolor','none','facecolor','interp')
        ylabel(Axh(2),'Clusterungsreihenfolge')
        [~,Labi] = unique(sort(CIndex),'last');
        if size(Labi,2) == 1, Labi = Labi'; end
        surf(Axh(2),[0 Labi],[0 Labi],ones(numel(Labi)+1)*max(max(Dist))*1.1,'facecolor','none','linewidth',1)
        
        % X/Y-Achsen der jeweiligen Achsen miteinander verknüpfen
        L1 = linkprop([Axh(1) Axh(2)],'XLim');
        L2 = linkprop([Axh(1) Axh(2)],'YLim');
        L3 = linkprop([Axh(1) Axh(2)],'ZLim');
        
        % X-Achse Cluster, Cluster NR markieren:
        Mittelwerte_zwischen_Bereich  = filter([1,1], 2, Labi);
        Mittelwerte_zwischen_Bereich(1) = []; % Der erste Wert muss gelöscht werden.
        set(Axh(2), 'XTick', Mittelwerte_zwischen_Bereich)
        set(Axh(2), 'XTickLabel', 1 : max(CIndex))
        set(Axh(2), 'YTick', Mittelwerte_zwischen_Bereich)
        set(Axh(2), 'YTickLabel', 1 : max(CIndex))
        
        set(figHandle,'UserData',[L1 L2 L3],'renderer','zbuffer')
        
        view(Axh(1),0,90)
        colorbar('peer',Axh(1))
        view(Axh(2),0,90)
        colorbar('peer',Axh(2))
        
        set(Axh(1),'Xlim',[1 numel(CSort)],'Ylim',[1 numel(CSort)])
        colormap(Axh(1),jet(6))
        colormap(Axh(2),jet(6))
    end
    
    
end
end
function push_Export_Callback(~, ~, handles)
% aktuell ausgewähltes Cluster:
Clusterungen = get(handles.ClusterungNeu, 'UserData');

ClusterIndex = find(get(handles.ClusterungenTabelle,'UserData')==[Clusterungen.Nr]);

% Speicherort und Dateiname festlegen lassen:
Vorhandene_Dateien = dir('Export_Clusterung*.xls*');
if isempty(Vorhandene_Dateien),
    Vorgeschlagener_Name = 'Export_Clusterung_1';
else
    try
        [~, Dateiname_ohne_ext] = fileparts(Vorhandene_Dateien(end).name);
        max_num = str2double(Dateiname_ohne_ext(19:end));
        Vorgeschlagener_Name = ['Export_Clusterung_',num2str(max_num + 1)];
    catch
        Vorgeschlagener_Name = 'Export_Clusterung_1';
    end
end
[filename, pathname] = uiputfile({'*.xlsx', 'Excel-Datei'; '*.xls', 'Excel 97-2003 Datei'}, 'Export Clusterung nach Excel', Vorgeschlagener_Name);
if isequal(filename, 0),
    % Es wurde auf Abbrechen gedrückt.
    return
end
Dateiname = fullfile(pathname, filename);

flag_mat = false;
flag_xls = true;
flag_csv = false;
Zeit_Format = 'dd.mm.yyyy'; % Unix oder wie bei datestr
Clusterungen(ClusterIndex).Export_Clusterungsergebnis( Dateiname, flag_mat, flag_xls, flag_csv, Zeit_Format)


end
function push_Export_nach_Matlab_Callback(~, ~, handles)
Clusterungen = get(handles.ClusterungNeu, 'UserData');
ClusterIndex = find(get(handles.ClusterungenTabelle,'UserData')==[Clusterungen.Nr]);
Clusterung = Clusterungen(ClusterIndex);

% Speicherort und Dateiname festlegen lassen:
Vorhandene_Dateien = dir('Export_Clusterung*.mat');
if isempty(Vorhandene_Dateien),
    Vorgeschlagener_Name = 'Export_Clusterung_1';
else
    try
        [~, Dateiname_ohne_ext] = fileparts(Vorhandene_Dateien(end).name);
        max_num = str2double(Dateiname_ohne_ext(19:end));
        Vorgeschlagener_Name = ['Export_Clusterung_',num2str(max_num + 1)];
    catch
        Vorgeschlagener_Name = 'Export_Clusterung_1';
    end
end
[filename, pathname] = uiputfile({'*.mat', 'Matlab-Datei'}, 'Export Clusterung nach Matlab', Vorgeschlagener_Name);
if isequal(filename, 0),
    % Es wurde auf Abbrechen gedrückt.
    return
end
Dateiname = fullfile(pathname, filename);

save(Dateiname, 'Clusterung')
end
function popup_plot_Eigenschaft_Callback(~, ~, handles)
Clusterungen = get(handles.ClusterungNeu, 'UserData');
cla(handles.ClusterungAxes); legend(handles.ClusterungAxes, 'off');
if get(handles.ClusterungenTabelle,'UserData')~=0 && ~isempty(Clusterungen([Clusterungen.Nr]==get(handles.ClusterungenTabelle,'UserData')).KalenderClusterung),
    alle_Eig = get(handles.popup_plot_Eigenschaft, 'String');
    gew_Eig  = get(handles.popup_plot_Eigenschaft, 'Value');
    Eigenschaft1 = alle_Eig{gew_Eig};
    Clusterungen([Clusterungen.Nr]==get(handles.ClusterungenTabelle,'UserData')).DrawEigenschaft(handles.ClusterungAxes, Eigenschaft1);
    
    % buttondownFcn aktivieren
    set(findobj(get(handles.ClusterungAxes,'children'),'type','hggroup'),'ButtonDownFcn',@(src,event) ClusterButtonDownCallback(src,event,handles))
    
end
end % function popup_plot_Eigenschaft_Callback(hObject, eventdata, handles)
function push_ClusterEigenschaften_Callback(~, ~, handles)
% aktuelle ausgewählte Clusterung:
Clusterungen = get(handles.ClusterungNeu, 'UserData');
akt_Clusterung = [Clusterungen.Nr]==get(handles.ClusterungenTabelle,'UserData');
Clusterungen(akt_Clusterung).disp_Eigenschaften_der_Cluster;
end % function
function push_PP_Cluster_Callback(~, ~, handles)
Clusterungen = get(handles.ClusterungNeu, 'UserData');
ClusterIndex = get(handles.ClusterungenTabelle,'UserData')==[Clusterungen.Nr];
flag_Cluster = true; flag_Input_Daten = false;
% Welche Clusternummern sind aktuell geplottet:
akt_ClusterNr = cell2mat(get(get(handles.ClusterungMainLines, 'Children'), 'UserData'));
ClusterNr = flipud(akt_ClusterNr); % Reihenfolge ändern.
Intervallgroesse = []; % Standard => 60 Minuten.
Intervallgroesse = []; % Standard => 60 Minuten.
Clusterungen(ClusterIndex).Schoene_plots_fuer_PP(flag_Cluster, flag_Input_Daten, ClusterNr, Intervallgroesse);

% % Auslesen, welche aktuell sichtbar sind:
% neue_Axes = gca; % in diese Axes wurde geplottet
% Tag_akt_sichtbar = get(get(handles.ClusterungMainLines, 'Children'), 'Tag');
%
% handles_ClusterLinien_neue_Axes = get(neue_Axes, 'Children');
% Tag_neue_Axes = get(handles_ClusterLinien_neue_Axes, 'Tag');
% idx_Sichtbar = ismember(Tag_neue_Axes, Tag_akt_sichtbar);
% set(handles_ClusterLinien_neue_Axes(~idx_Sichtbar), 'Visible', 'off')

end
function push_PP_Input_Callback(~, ~, handles)
Clusterungen = get(handles.ClusterungNeu, 'UserData');
ClusterIndex = get(handles.ClusterungenTabelle,'UserData')==[Clusterungen.Nr];
flag_Cluster = false; flag_Input_Daten = true;
% Welche Clusternummern sind aktuell geplottet:
Akt_geplottete_Cluster = get(handles.ClusterungMainLines, 'Children');
akt_ClusterNr          = get(Akt_geplottete_Cluster, 'UserData');
if iscell(akt_ClusterNr),
    akt_ClusterNr = cell2mat(akt_ClusterNr);
end
ClusterNr = flipud(akt_ClusterNr); % Reihenfolge ändern.
Intervallgroesse = []; % Standard => 60 Minuten.
Clusterungen(ClusterIndex).Schoene_plots_fuer_PP(flag_Cluster, flag_Input_Daten, ClusterNr, Intervallgroesse);

% % Auslesen, welche aktuell sichtbar sind:
% neue_Axes = gca; % in diese Axes wurde geplottet
%
%
%
% handles_ClusterLinien_neue_Axes = get(neue_Axes, 'Children');
% ClusterNr_neue_Axes = cell2mat(get(handles_ClusterLinien_neue_Axes, 'UserData'));
% idx_ClusterLinien = cellfun(@any, strfind(get(handles_ClusterLinien_neue_Axes, 'Tag'), 'ClusterId'));
%
% idx_Sichtbar = ismember(ClusterNr_neue_Axes, akt_ClusterNr) & ~idx_ClusterLinien;
% set(handles_ClusterLinien_neue_Axes(~idx_Sichtbar), 'Visible', 'off')


end
function push_PP_Eigenschaft_Callback(~, ~, handles)
Clusterungen = get(handles.ClusterungNeu, 'UserData');
ClusterIndex = get(handles.ClusterungenTabelle,'UserData')==[Clusterungen.Nr];
alle_Eig = get(handles.popup_plot_Eigenschaft, 'String');
gew_Eig  = get(handles.popup_plot_Eigenschaft, 'Value');
Eigenschaft1 = alle_Eig{gew_Eig};
Clusterungen(ClusterIndex).Schoene_plots_fuer_PP_Eigenschaften(Eigenschaft1);
end
function push_renew_Callback(~, ~, handles)
UpdatePlots(handles)
end


%% Einstellungen Clusterung
function ClusterZahlAbs_Callback(hObject, ~, ~) %#ok<DEFNU>
% hObject    handle to ClusterZahlAbs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ClusterZahlAbs as text
%        str2double(get(hObject,'String')) returns contents of ClusterZahlAbs as a double
if ~isnan(str2double(get(hObject,'String')))
    set(hObject,'UserData',max(str2double(get(hObject,'String')),1));
end
set(hObject,'string',num2str(get(hObject,'UserData')));
end
function ClusterZahlAbs_CreateFcn(hObject, ~, ~) %#ok<DEFNU>
% hObject    handle to ClusterZahlAbs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
function ClusterMethodeList_Callback(hObject, ~, handles) %#ok<DEFNU>

contents=cellstr(get(hObject,'String'));
if strcmp('Kmeans',contents{get(hObject,'Value')})
    set(handles.CutOff,'enable','off')
    set(handles.radio_max_Anz_Cluster,'enable','off')
    set(handles.radio_max_Distanz,'enable','off')
    set(handles.ClusterZahlAbs,'enable','on')
    %set(handles.ClusterZahlRel,'enable','on')
    set(handles.KmeansStartList,'enable','on')
    set(handles.KmeansReplicates,'enable','on')
else
    set(handles.CutOff,'enable','on')
    set(handles.radio_max_Anz_Cluster,'enable','on')
    set(handles.radio_max_Distanz,'enable','on')
    if get(handles.radio_max_Anz_Cluster,'Value') == true
        radio_max_Anz_Cluster_Callback(handles.radio_max_Anz_Cluster, [], handles);
    else
        radio_max_Distanz_Callback(handles.radio_max_Distanz, [], handles);
    end
    set(handles.KmeansStartList,'enable','off')
    set(handles.KmeansReplicates,'enable','off')
end
end
function ClusterMethodeList_CreateFcn(hObject, ~, ~) %#ok<DEFNU>
% hObject    handle to ClusterMethodeList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
function radio_max_Anz_Cluster_Callback(hObject, ~, handles)

set(hObject, 'Value', true)
set(handles.radio_max_Distanz, 'Value', false)
set(handles.ClusterZahlAbs,'enable','on')
%set(handles.ClusterZahlRel,'enable','on')
set(handles.CutOff,'enable','off')
set(handles.CutOff,'UserData', 0);

end % function
function radio_max_Distanz_Callback(hObject, ~, handles)

set(hObject, 'Value', true)
set(handles.radio_max_Anz_Cluster, 'Value', false)
set(handles.ClusterZahlAbs,'enable','off')
%set(handles.ClusterZahlRel,'enable','off')
set(handles.CutOff,'enable','on')
set(handles.CutOff,'UserData', str2double(get(handles.CutOff,'String')))

end
function DistanzMethodeList_Callback(~, ~, ~) %#ok<DEFNU>
end
function DistanzMethodeList_CreateFcn(hObject, ~, ~) %#ok<DEFNU>
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% Im Rahmen des Projektes wurden insgesamt 4 Distanzfunktionen untersucht:
%   1: GEH
%   2: Euklidische Distanz
%   3: Vortisch-Formel
%   4: Pillat-Formel
% Der Allgemeinheit werden nur die ersten beiden angezeigt.
flag_zeige_alle_Distanzfunktionen = true;
welche_Distanzfunktionen = [1, 2];
if ~flag_zeige_alle_Distanzfunktionen,
    Alle_Distanzfunktionen = get(hObject, 'String');
    set(hObject, 'String', Alle_Distanzfunktionen(welche_Distanzfunktionen));
end
end
function CutOff_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    handle to CutOff (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of CutOff as text
%        str2double(get(hObject,'String')) returns contents of CutOff as a double
if isempty(get(hObject,'String'))
    set(hObject,'UserData',0)
    set(handles.ClusterZahlAbs,'enable','on')
    %set(handles.ClusterZahlRel,'enable','on')
elseif ~isnan(str2double(get(hObject,'String')))
    set(hObject,'UserData',max(str2double(get(hObject,'String')),0.01));
    set(hObject,'string',num2str(get(hObject,'UserData')));
    set(handles.ClusterZahlAbs,'enable','off')
    %set(handles.ClusterZahlRel,'enable','off')
end
set(hObject,'string',num2str(get(hObject,'UserData')));
end
function CutOff_CreateFcn(hObject, ~, ~) %#ok<DEFNU>
% hObject    handle to CutOff (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
function KmeansStartList_Callback(~, ~, ~) %#ok<DEFNU>
% hObject    handle to KmeansStartList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns KmeansStartList contents as cell array
%        contents{get(hObject,'Value')} returns selected item from KmeansStartList
end
function KmeansStartList_CreateFcn(hObject, ~, ~) %#ok<DEFNU>
% hObject    handle to KmeansStartList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
set(hObject, 'Enable', 'off') % Wird nur aktiviert, wenn KMEANS gewählt wird. Siehe "function ClusterMethodeList_Callback(hObject, ~, handles)"
end
function KmeansReplicates_Callback(hObject, ~, ~) %#ok<DEFNU>
% hObject    handle to KmeansReplicates (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of KmeansReplicates as text
%        str2double(get(hObject,'String')) returns contents of KmeansReplicates as a double
if ~isnan(str2double(get(hObject,'String')))
    set(hObject,'UserData',max(str2double(get(hObject,'String')),1));
end
set(hObject,'string',num2str(get(hObject,'UserData')));
end
function KmeansReplicates_CreateFcn(hObject, ~, ~) %#ok<DEFNU>
% hObject    handle to KmeansReplicates (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
function ClusterButtonDownCallback(src,~,handles)
% speichern der alten Achsenlimits um diese nachher wieder zu setzen (fühlt sich i.A. besser an)

% Falls es eine markierte Linie gibt:
h_Markierung = findobj(handles.ClusterungSingleLines, 'Tag', 'Markierung Datum');
delete(h_Markierung)


Clusterungen = get(handles.ClusterungNeu, 'UserData');
akt_Clusterung_NR = get(handles.ClusterungenTabelle,'UserData');
akt_Clusterung = Clusterungen([Clusterungen.Nr] == akt_Clusterung_NR);
Anzahl_Cluster = size(akt_Clusterung.ClusterLinien,1);
OldX = get(handles.ClusterungMainLines,'XLim');
OldY = get(handles.ClusterungMainLines,'YLim');

% Linien zwischen Objekten (Detektoren) löschen:
delete(findobj(get(handles.ClusterungMainLines,'children'),'Tag','Grid'));
delete(findobj(get(handles.ClusterungSingleLines,'children'),'Tag','Grid'));

% wenn die volle Anzahl mittlerer Clusterlinien gezeichnet ist, dann werden vor dem neu zeichnen alle gelöscht (==beim ersten klicken)
if numel(findobj(get(handles.ClusterungMainLines,'children'),'type','line')) == Anzahl_Cluster,
    cla(handles.ClusterungMainLines)
    cla(handles.ClusterungSingleLines)
end
% aus den Ticklabels die ClusterNr auslesen...
if ~isempty(handles.ClusterKalenderFigure) && strcmp(get(get(src,'parent'),'tag'),'axHandleCalendar')
    Datum = get(src,'UserData');
    % Das Cluster, zu diesem Tag:
    ClusterNr = akt_Clusterung.ClusterIndizes(akt_Clusterung.ClusterData == Datum);
else
    currentPoint = get(handles.ClusterungAxes, 'CurrentPoint');
    % currentPoint = get(src,'CurrentPoint');
    YTickLabels  = get(handles.ClusterungAxes,'YTickLabel');
    if ~iscell(YTickLabels),
        YTickLabels = cellstr(YTickLabels);
    end
    % Die per Maus ausgewählte Cluster Nummer:
    ClusterNr    = str2double(YTickLabels{round(currentPoint(2,2))});
end

% Prüfen ob dieser Cluster bereits gezeichnet ist und ihn dann entfernen und die Legend updaten (andernfalls den Cluster zeichnen)
OldPlots = findall(handles.MatNetClusterung,'type','line','-and','UserData',ClusterNr);


if ~isempty(OldPlots) && ~exist('Datum', 'var'), % Wenn ein Datum im Kalender angeklickt wurde, soll das Cluster gezeigt werden.
    delete(OldPlots)
    legend(handles.ClusterungMainLines,'off')
    if ~isempty(get(handles.ClusterungMainLines, 'Children')), % Wenn keine Linien mehr dargestellt sind, muss keine Legende geplottet werden.
        lh = legend(handles.ClusterungMainLines,'show');
        set(lh,'location','best','interpreter','none','FontSize',8)
    end
else
    % plotten der jeweiligen Linien
    if isempty(OldPlots),
        akt_Clusterung.DrawCluster(handles.ClusterungMainLines,ClusterNr,[],true,false);
        set(handles.ClusterungMainLines, 'XTickLAbel', [])
        akt_Clusterung.DrawCluster(handles.ClusterungSingleLines,ClusterNr,[],false,true);
        
        % löschen einer der beiden Legenden
        legend(handles.ClusterungSingleLines,'off')
        % anpassen der Achsenbeschriftung
        set(handles.ClusterungMainLines,'XLim',OldX,'YLim',OldY);
        set(get(handles.ClusterungMainLines,'Ylabel'),'String',sprintf('Werte der Cluster'))
        set(get(handles.ClusterungSingleLines,'Ylabel'),'String',sprintf('Werte der einzelnen Tage'))
        % das oberste YTickLabel der unteren Axes löschen (wegen Überlappung der Beschriftung)
        YTick=get(handles.ClusterungMainLines,'Ytick');
        set(handles.ClusterungSingleLines,'Ytick',YTick(1:end-1))
    end
    if exist('Datum', 'var'),
        h_Line_Datum = findobj(handles.ClusterungSingleLines, 'Tag', num2str(Datum));
        h_Markierung = copyobj(h_Line_Datum, handles.ClusterungSingleLines);
        set(h_Markierung ...
            ,'LineWidth', 5 ...
            ,'Tag', 'Markierung Datum' ...
            ,'Color', [.9 .9 .9]);
        uistack(h_Markierung, 'top'); uistack(h_Line_Datum, 'top');
    end
        
    
end
end

%% Daten einlesen:
function Data_ClusterData_Callback(hObject, ~, handles)
% Executes on button press in Data_ClusterData

% Angabe zu importierender DAtei
[filename, pathname] = uigetfile( {'*.mat;*.xls*','mat oder Excel-files (*.mat, *.xls*)'; '*.mat','MAT-files (*.mat)'; '*.xls*','Excel-files (*.xls*)'; '*.*',  'All Files (*.*)'}, 'Matrix auswählen ...');
if isequal(filename, 0) && isequal(pathname, 0)
    % Es wurde auf Abbrechen geklickt.
    return
end

Dateiname = fullfile(pathname, filename);
[Daten, Clusterung] = Daten_Importieren(Dateiname);

% Die ClusterDaten werden in die UserData des Pushbuttons geschrieben:
Data.Daten      = Daten;
Data.Dateiname  = Dateiname;

if ~isempty(Clusterung)
    % todo: Rückgabe ist Clusterobjekt
    if ishandle(handles.ClusterKalenderFigure)
        close(handles.ClusterKalenderFigure) % Der bisherige Clusterkalender wird geschlossen.
        handles.ClusterKalenderFigure = [];
    end
    
    % wo speichere ich die Clusterungen?
    Clusterungen = get(handles.ClusterungNeu, 'UserData');
    if isempty(Clusterungen) || ~isa(Clusterung, 'class_Clusterung')
        Clusterungen = Clusterung;
    else
        Clusterungen(end + 1) = Clusterung;
    end
    Clusterungen(end).Nr = max([Clusterungen.Nr]) + 1; %length(Clusterungen);  % Die Nr der Clusterung setzten.
    set(handles.ClusterungNeu, 'UserData', Clusterungen);
    
    % Das Folgende wird nur durchgeführt, wenn das Erzeugen einer Clusterung erfolgreich war.
    if Clusterung.Initialisiert
        % Berechnen der Silhouette-Werte der Vorklassifizierung
        % Clusterung.SilhouetteVorklassifizierungBerechnen;
        
        % alte Zeichnungen löschen, neue Clusterung auf aktiv setzen und vorhandene Clusterungen neu darstellen
        set(handles.ClusterungenTabelle,'UserData',Clusterung.Nr)
        UpdateClusterungenTabelle(handles);
        UpdatePlots(handles)
        
        % Wenn eine Clusterung geladen wird, können alle Buttons aktiviert werden:
        wie_Schalten = 'on';
        welche_Buttons = [1, 2, 3]; % Alle Buttons
        Buttons_Clusterung_an_aus(handles, wie_Schalten, welche_Buttons);
        
        MyDisp('Vollständige Clusterung erfolgreich geladen.', [0 1 0])
    end
end

set(hObject, 'UserData', Data);

set(handles.text_Cluster_Data, 'String', char({'ClusterData';Dateiname}))
Zeit_Format = 'dd.mm.yyyy';
Zeit_Von = datestr(Daten(1,  1), Zeit_Format);
Zeit_Bis = datestr(Daten(end,1), Zeit_Format);
set(handles.ZeitBeginnCluster, 'String', Zeit_Von)
set(handles.ZeitEndeCluster, 'String', Zeit_Bis)

% Felder anzeigen:
set(handles.ZeitBeginnCluster, 'Visible', 'on')
set(handles.ZeitEndeCluster, 'Visible', 'on')

set(handles.ZeitBeginnText, 'String', ['Erster  Tag (min.',32,Zeit_Von,')'])
set(handles.ZeitBeginnText, 'UserData', Daten(1,  1))
set(handles.ZeitEndeText, 'String', ['Letzter Tag (max.',32,Zeit_Bis,')'])
set(handles.ZeitEndeText, 'UserData', Daten(end,1))
set(handles.ZeitBeginnText, 'Visible', 'on')
set(handles.ZeitEndeText, 'Visible', 'on')

% Wenn ClusterData geladen wurde, kann eine Clusterung angelegt werden:
wie_Schalten = 'on';
welche_Buttons = 1; % Alle Buttons
Buttons_Clusterung_an_aus(handles, wie_Schalten, welche_Buttons);

MyDisp('ClusterData eingelesen und erfolgreich formatiert.', [0 1 0])

end
function Datei_zus_Eigenschaften_Callback(~, ~, handles)
% --- Executes on button press in Datei_zus_Eigenschaften

% Die Daten müssen die Form habe:
% 1.    Zeile:     Überschrift der Eigenschaft (2.-n. Spalte)
% 1.    Spalte:    Zeit des Tages im Matlab-Zeit Format ODER Unix-Zeit
% 2.-n. Spalte:    Ausprägung der Eigenschaft

% Angabe zu importierender DAtei
[filename, pathname] = uigetfile( {'*.mat;*.xls*','mat oder Excel-files (*.mat, *.xls*)'; '*.mat','MAT-files (*.mat)'; '*.xls*','Excel-files (*.xls*)'; '*.*',  'All Files (*.*)'}, 'Matrix auswählen ...');
if isequal(filename, 0) && isequal(pathname, 0)
    % Es wurde auf Abbrechen geklickt.
    return
end
Dateiname = fullfile(pathname, filename);
[Daten, Bezeichnung_Eigenschaften] = Eigenschaften_Importieren(Dateiname); %todo Funktionsaufruf

% Die zusätzlichen Eigenschaften werden in die UserData des Pushbuttons geschrieben:
Data.Daten                          = Daten;
Data.Dateiname                      = Dateiname;
Data.Bezeichnung_der_Eigenschaft    = Bezeichnung_Eigenschaften;
set(handles.Datei_zus_Eigenschaften, 'UserData', Data);

set(handles.Datei_zus_Eigenschaften, 'UserData', Data);

set(handles.chkbox_Zusatz_Eigenschaften, 'Value', true)
set(handles.text_zus_Eigenschaften, 'String', Dateiname)

end
function chkbox_Zusatz_Eigenschaften_Callback(hObject, eventdata, handles)
if get(handles.chkbox_Zusatz_Eigenschaften, 'Value') == true
    Datei_zus_Eigenschaften_Callback(hObject, eventdata, handles);
else
    set(handles.text_zus_Eigenschaften, 'String', '')
end
end

function push_Hilfe_Callback(~, ~, ~)

if exist('_ReadMe.txt', 'file'),
    winopen('_ReadMe.txt')
else
    HilfeText = [   32,32,char(10),... % leere Zeile
        32,32,'Hilfe:',char(10),...
        32,32,char(10),... % leere Zeile
        32,32,'Inputdaten:',char(10),...
        32,32,'---- ClusterData -----',char(10),...
        32,32,'Eine beliebig große Matrix mit ',char(10),...
        32,32,'     1. Spalte: Tage / Zeit im Matlab-Zeit Format',char(10),...
        32,32,'     2.-(p-1) Spalte: Einzelne zu Clusternde Werte für jeden Tag',char(10),...
        32,32,'Jede Zeile entspricht einem Element (z.B. Tag), das in Cluster eingeteilt wird.',char(10),...
        32,32,'Beispiel: Siehe ClusterData.mat oder ClusterData.xlsx',char(10),...
        32,32,char(10),... % leere Zeile
        32,32,'---- EigenschaftenData -----',char(10),...
        32,32,'Die Eigenschaften haben KEINEN Einfluss auf das Cluster-Ergebnis.',char(10),...
        32,32,'EigenschaftenData muss als n x 2 Cell mit ',char(10),...
        32,32,'     1. Spalte: Tage / Zeit im Matlab-Zeit Format (ähnlich ClusterData)',char(10),...
        32,32,'     2. Spalte: Bezeichnung der Eigenschaft (z.B. Regen, Sonnenschein, ö.ä.)',char(10),...
        32,32,'Beispiel: Siehe Eigenschaft_Wetter.xlsx',char(10),...
        32,32,char(10),... % leere Zeile
        32,32,char(10),... % leere Zeile
        32,32,'~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~',char(10),...
        32,32,char(10),... % leere Zeile
        32,32,'Bedienung:',char(10),...
        32,32,'1.) ClusterData einlesen.',char(10),...
        32,32,'    Auf "Clusterdata Datei öffnen" klicken und eine *.mat oder *.xls(x) Datei auswählen.',char(10),...
        32,32,'    Wird eine *.xls(x) Datei ausgewählt öffnet Matlab das Excel File und man muss manuell den Bereich markieren, der verwendet werden soll.',char(10),...
        32,32,'    Ist der Bereich markiert muss man das in dem kleinen Matlab - Fenster bestätigen.',char(10),...
        32,32,'    Ist der Bereich markiert muss man das in dem kleinen Matlab - Fenster ("Data Selection Dialog") bestätigen.',char(10),...
        32,32,'2.) Falls gewünscht Eigenschaften einlesen (wie bei Punkt 1.) vorgehen).',char(10),...
        32,32,'3.) Einstellungen Cluster vornehmen (links oben)',char(10),...
        32,32,'4.) Tage, die verwendet werden sollen im Bereich "Kalenderdaten auswählen".',char(10),...
        32,32,'5.) Auf "Neue Clusterung anlegen clicken". Damit werden alle Einstellungen und ausgewählten Daten gespeichert.',char(10),...
        32,32,'    Eine Änderung an der GUI hat keinen Einfluss mehr auf die erstellte Clusterung.',char(10),...
        32,32,'6.) ...starten. Die Clusterung wird durchgeführt und das Ergebnis visuell dargestellt.',char(10),...
        ];
    Pos = [200 200 800 600];
    figure('Position', Pos, 'Name', 'Hilfe Clusterung', 'ToolBar', 'none', 'MenuBar', 'none') % Neues Fenster
    uicontrol(gcf, 'Style', 'text', 'String', HilfeText, 'Position', [Pos - [200 200 0 0]], 'HorizontalAlignment', 'left');
end
end
function push_zusatz_ES_Callback(~, ~, ~)

% Über eine externe Funktion werden die weiteren Einstellungen ausgewählt.
Weitere_Einstellungen;

end

function Buttons_Clusterung_an_aus(handles, wie_Schalten, welche_Buttons)
% Es werden alle Buttons aktiviert oder deaktiviert

% wie_Schalten:
% 'on'  - Ausgewählte Buttons werden aktiv
% 'off' - Ausgewählte Buttons werden deaktiviert
if nargin < 2 || isempty(wie_Schalten) || ~ischar(wie_Schalten) || ~(isequal(wie_Schalten,'on') || isequal(wie_Schalten,'off')),
    warning('"wie_Schalten" muss entwender ''on'' oder ''off'' sein.')
end
% welche_Buttons:
% 1: Daten wurden eingelesen        => Clusterung kann angelegt werden.
% 2: Clusterung wurde eingelesen    => Clusterung kann gestart oder gelöscht werden
% 3: Clusterung wurdw gestartet     => Es können verschiedene Analysen durchgeführt werden
if nargin < 3 || isempty(welche_Buttons) || ~isnumeric(welche_Buttons) || any(~ismember(welche_Buttons, [1,2,3])),
    warning('"welche_Buttons" darf nur die Werte [1, 2, 3] enthalten.')
end


for cnt_wB = 1 : length(welche_Buttons),
    
    akt_welche_Buttons = welche_Buttons(cnt_wB);
    switch akt_welche_Buttons,
        case 1, % 1: Daten wurden eingelesen => Clusterung kann angelegt werden.
            set(handles.ClusterungNeu, 'Enable', wie_Schalten)
        case 2, % 2: Clusterung wurde eingelesen    => Clusterung kann gestart oder gelöscht werden
            set(handles.ClusterungStarten, 'Enable', wie_Schalten)
            set(handles.ClusterungDelete, 'Enable', wie_Schalten)
        case 3, % 3: Clusterung wurd gestartet      => Es können verschiedene Analysen durchgeführt werden
            set(handles.push_ClusterEigenschaften, 'Enable', wie_Schalten)
            set(handles.DrawClusterKalender, 'Enable', wie_Schalten)
            set(handles.DrawSilhouette, 'Enable', wie_Schalten)
            set(handles.DrawDistMatrix, 'Enable', wie_Schalten)
            set(handles.push_Export, 'Enable', wie_Schalten)
            set(handles.push_Export_nach_Matlab, 'Enable', wie_Schalten)
            set(handles.push_PP_Cluster, 'Enable', wie_Schalten)
            set(handles.push_PP_Input, 'Enable', wie_Schalten)
            set(handles.push_renew, 'Enable', wie_Schalten)
            set(handles.ClearAxesClusterungLines, 'Enable', wie_Schalten)
            set(handles.CopyAxesClusterungLines, 'Enable', wie_Schalten)
            set(handles.push_PP_Eigenschaft, 'Enable', wie_Schalten)
            set(handles.CopyAxesClusterungAxes, 'Enable', wie_Schalten)
            % Bei dem Popup plot_Eigenschaft muss untersucht werden, ob eine Eigenschaft vorhanden ist:
            if isequal(wie_Schalten, 'off'),
                set(handles.popup_plot_Eigenschaft, 'Enable', wie_Schalten)
            else
                Clusterungen = get(handles.ClusterungNeu, 'UserData');
                if ~isempty(Clusterungen),
                    akt_Clusterung = Clusterungen([Clusterungen.Nr] == get(handles.ClusterungenTabelle,'UserData'));
                    if isstruct(akt_Clusterung.Eigenschaften),
                        set(handles.popup_plot_Eigenschaft, 'Enable', wie_Schalten)
                    end
                end
            end
            
    end
end

end % function
