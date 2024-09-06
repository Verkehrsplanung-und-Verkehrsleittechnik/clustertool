function MyDisp(Message, ES_Input)
% Funktion zum Fehlerfeedback / Protokollieren
% Öffnet ein Fenster in dem Warnungen, Fehler, Hinweise oder nur der Bearbeitungsstand angezeigt werden können.
% Dazu kann der die "Message" in eine Protokolldatei geschrieben werden.
%
% ---- Eingänge ----------
%   -1- Message         - Cell oder String mit der Nachricht, welche protokolliert / ausgegeben werden soll.
%                         Bei einer Cell müssen die einzelnen Elemente Strings sind.
%   -2- ES_Input        - Struct mit verschiedenen Einstellungen
%                         Siehe hierzu die Funktion "Standardeinstellungen"
%               Da häufig nur die Farbe verändert wird, kann anstatt ES_Input auch direkt die Farbe eingehen:
%               ES_Input = [1 0 0]; % für Rot.
%               Für alle anderen Einstellungen werden die Standardeinstellungen verwendet.
%
% Das Fenster kann mit dem Befehl: delete(findobj('tag', 'FeedbackFenster')); geschlossen werden.
% Das Handle der Listbox bekommt man so:
%
% h_Listbox = findobj('tag', 'FeedbackFenster_Listbox'); % Vorausgesetzt der Tag der Listbox wurde über die ES nicht verändert.
%
% % Beispiel:
% clear ES_Input
% ES_Input.flag_schreibe_in_Datei = false;
% ES_Input.mit_Datum = true;
% Message = {'1. Zeile'; '2. Zeile: Hier steht ein Text'};
% MyDisp(Message, ES_Input)
% ES_Input.Farbe = [0.8 0 0]; % rot
% Message = 'Dieser Text ist Rot.';
% MyDisp(Message, ES_Input)
%





if nargin < 1 || isempty(Message), warning('Keine Message als Eingang definiert.'), end
if nargin < 2 || isempty(ES_Input),
    ES_Input = struct();
elseif ~isstruct(ES_Input),
    if isnumeric(ES_Input) && size(ES_Input, 2) == 3,
        Farbe_hier = ES_Input(1, :);
        clear ES_Input
        ES_Input.Farbe = Farbe_hier;
    else
        ES_Input = struct();
    end
end

% Prüfen, welche Einstellungen mit eingehen:
Standard_ES = Standardeinstellungen;
ES          = Struct_nicht_vorhandene_Felder_uebernehmen(ES_Input, Standard_ES);

% Mithilfe einer globalen Varibalen kann bestimmt werden, ob Protokoll im Fenster gemacht werden soll:
% Diese Einstellungen werden über "ES_Input" gesetzt !!!
global Einstellungen_Protokoll
if ~isempty(Einstellungen_Protokoll) && isstruct(Einstellungen_Protokoll), 
    if isfield(Einstellungen_Protokoll, 'flag_DispOut'),
        ES.flag_DispOut = Einstellungen_Protokoll.flag_DispOut;
    end
    if isfield(Einstellungen_Protokoll, 'flag_schreibe_in_Datei'),
        ES.flag_schreibe_in_Datei = Einstellungen_Protokoll.flag_schreibe_in_Datei;
    end    
end

if ~iscell(Message), Message = {Message}; end

if ES.flag_DispOut,
    % prüfen ob die FeedbackFenster_Listbox existiert
    h_FeedbackFenster_Listbox = findobj('Style', 'listbox', 'Tag', ES.Tag_Listbox);
    if isempty(h_FeedbackFenster_Listbox),
        % Neues Fenster öffnen:
        FeedbackFenster(ES);
        h_FeedbackFenster_Listbox = findobj('Style', 'listbox', 'Tag', ES.Tag_Listbox);
    end
    
    if get(h_FeedbackFenster_Listbox, 'Value') < ES.Max_Anzahl_Eintraege % sicherstellen, dass nicht zu viele Protokolleinträge auflaufen (performance-Problem => Umleitung in die Textdatei)
        
        Text_des_Feedback_Fenster   = get(h_FeedbackFenster_Listbox, 'String');
        Anzahl_Eintraege            = length(Text_des_Feedback_Fenster);

        Farbencode = Farben_Matlab_to_Hex(ES.Farbe);
        Message_disp = Message;
        for cnt_C = 1 : numel(Message_disp),
            if ES.mit_Datum,
                Message_disp{cnt_C} = [datestr(now, ES.Datum_Format),32, Message{cnt_C}];
            end
            Text_des_Feedback_Fenster{Anzahl_Eintraege + cnt_C} = ['<html><b><font color="',Farbencode{1},'">',Message_disp{cnt_C},'</font></b></html>'];
        end
        
    end
    if get(h_FeedbackFenster_Listbox, 'Value') >= ES.Max_Anzahl_Eintraege,
        Text_des_Feedback_Fenster = get(h_FeedbackFenster_Listbox, 'String');
        Text_des_Feedback_Fenster{length(Text_des_Feedback_Fenster)+1}=['<html><b><font color="#c80000">','ACHTUNG!!! Es sind zuviele Protokolleinträge aufgelaufen, die Meldungen werden nur noch in der Protokolldatei gespeichert und nicht mehr angezeigt!!!','</font></b></html>'];
    end
    
    set(h_FeedbackFenster_Listbox ...
        ,'String', Text_des_Feedback_Fenster ...
        ,'Value', length(Text_des_Feedback_Fenster) ...
        )
    
    drawnow('expose')   
    
    if ES.flag_Fenster_Vordergrund
        % Fenster in den Vordergrund bringen:
        set(get(h_FeedbackFenster_Listbox, 'Parent'), 'visible', 'on')
    end
end

if ES.flag_schreibe_in_Datei,
    % IN die Datei wird immer das Datum mitgeschrieben:
    Fid = fopen(ES.Dateiname,'a');
    for cnt_C = 1 : numel(Message),
        fprintf(Fid, [datestr(now,'dd.mm.yyyy HH:MM:SS'),'\t',regexprep(Message{cnt_C},'\','\\\'),'\r\n']);
    end
    fclose(Fid);
end

end % MAIN Function



%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ``_____`_```````````_```````_`_``````````````````````````````
% `|`____(_)_`__``___|`|_`___|`|`|_```_`_`__```__`_``___`_`__``
% `|``_|`|`|`'_`\/`__|`__/`_`\`|`|`|`|`|`'_`\`/`_``|/`_`\`'_`\`
% `|`|___|`|`|`|`\__`\`|_``__/`|`|`|_|`|`|`|`|`(_|`|``__/`|`|`|
% `|_____|_|_|`|_|___/\__\___|_|_|\__,_|_|`|_|\__,`|\___|_|`|_|
% ````````````````````````````````````````````|___/````````````
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Standard_ES = Standardeinstellungen

% Maximale Anzahl Einträge, die in der Gui-Verwendung in einem Fenster ausgegeben wird
Standard_ES.Max_Anzahl_Eintraege    = 1000;
Standard_ES.flag_DispOut            = true;
Standard_ES.flag_schreibe_in_Datei  = true;  
Standard_ES.Dateiname               = 'Protokoll.txt';    
Standard_ES.Tag_Listbox             = 'FeedbackFenster_Listbox';
Standard_ES.Farbe                   = [0.1 0.1 0.1]; % Schwarz
Standard_ES.mit_Datum               = true; % Schwarz
Standard_ES.Datum_Format            = 'dd.mm.yyyy HH:MM:SS';
Standard_ES.flag_Fenster_Vordergrund = true;

%% Hier können auch die Einstellungen des Feedbackfensters getroffen werden:
Scr_Size                         = get(0, 'ScreenSize');
% Die Position des Feedbackfenster wird festgelegt:
Standard_ES.Breite_Fenster       = min(800, Scr_Size(3)-200); % mindestens 100 Pixel Rand auf beiden Seiten lassen
Standard_ES.Hoehe_Fenster        = min(600, Scr_Size(4)-200); % mindestens 100 Pixel Rand lassen

% Die Position kann auch anhand von einem anderen Figure ausgerichtet werden:
Standard_ES.Tag_Fenster          = 'MatNetClusterung';

% Soll in dem Fenster einen Button (untere 10% des Fensters) eingefügt werden:
Standard_ES.flag_mit_pushbotton  = true;
Standard_ES.Titel_Fenster        = 'Protokoll';
Standard_ES.FontName             = 'MS Sans Serif';
Standard_ES.FontSize             = 8;

end % MAIN function




function FeedbackFenster( ES )

% Öffnet ein FeedbackFenster:
Position_Fenster = get(findall(0, 'Tag', ES.Tag_Fenster), 'position');
if isempty(Position_Fenster),
    Scr_Size                         = get(0, 'ScreenSize');
    Postition_Fenster   = [(Scr_Size(3) - ES.Breite_Fenster)/2,  (Scr_Size(4) - ES.Hoehe_Fenster)/2, ES.Breite_Fenster, ES.Hoehe_Fenster];
else
    % Wenn ein Fenster mit existiert an dem das FeedbackFenster ausgerichtet werden soll:
    Postition_Fenster   = Position_Fenster + [100 100 -200 -200];
end

% Wartefenster und Text erstellen und positionieren
h_FeedbackFenster = figure(  'menubar',          'none', ...
    'numbertitle',      'off', ...
    'resize',           'on', ...
    'units',            'pixels',...
    'handlevisibility', 'on', ...
    'visible',          'on', ...
    ... %'WindowStyle','modal', ...
    ... %'CloseRequestFcn','',...
    'ToolBar',          'none',...
    'Tag',              'FeedbackFenster',...
    'Color',            'w',...
    'Name',             ES.Titel_Fenster, ...
    'Position',         Postition_Fenster);


if ES.flag_mit_pushbotton,
    Position_Listbox = [0 0.1 1 0.9];
    uicontrol(  'parent',       h_FeedbackFenster ...
        ,'style',       'pushbutton' ...
        ,'units',       'normalized' ...
        ,'position',    [0 0 1 0.1] ...
        ,'visible',     'on'...
        ,'String',      'Fenster schließen' ...
        ,'enable',      'on' ...
        ,'tag',         'FeedbackFenster_Button' ...
        ,'callback',    @FeedbackFenster_schliessen ...
        ,'FontWeight',  'bold' ...
        );
else
    Position_Listbox = [0 0 1 1];
end

%% Die Listbox erzeugen:
uicontrol(  'Parent',           h_FeedbackFenster ...
    ,'style',           'listbox' ...
    ,'units',           'normalized' ...
    ,'position',        Position_Listbox ...
    ,'visible',         'on'...
    ,'Tag',             ES.Tag_Listbox ...
    ,'BackGroundColor', 'w' ...
    ,'FontName',        ES.FontName ...
    ,'FontSize',        ES.FontSize ...
    );



% kurz warten, damit die Figure gezeigt wird:
pause(0.01)

    function FeedbackFenster_schliessen(~,~,~)
        delete(findobj('tag', 'FeedbackFenster'));
        pause(0.01)
    end
end













