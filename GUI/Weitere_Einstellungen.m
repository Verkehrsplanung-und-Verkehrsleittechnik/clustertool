function Weitere_Einstellungen(hObject)


Dateiname_gespeicherte_ES = 'Zusatz_ES_Clusterung.mat';

% Lade die gespeicherten Einstellungen
Gespeicherte_Einstellungen = Lade_gespeicherte_Einstellungen(Dateiname_gespeicherte_ES);

% Einstellungen speichern:
if nargin > 0 && ishandle(hObject),
    if isequal(get(hObject, 'Tag'), 'Bundesland'),
        Titel_Figure =  'Bitte Bundesland w�hlen';
        Namen_Buttons = {
            'BW = Baden-W�rttemberg';
            'BY = Bayern';
            'BE = Berlin';
            'BB = Brandenburg';
            'HB = Bremen';
            'HH = Hamburg';
            'HE = Hessen';
            'MV = Mecklenburg-Vorpommern';
            'NI = Niedersachsen';
            'NW = Nordrhein-Westfalen';
            'RP = Rheinland-Pfalz';
            'SL = Saarland';
            'SN = Sachsen';
            'ST = Sachsen-Anhalt';
            'SH = Schleswig-Holstein';
            'TH = Th�ringen';
            };
        [~, Name_Auswahl] = Auswahl_Pushbuttons(Namen_Buttons, Titel_Figure);
        Gespeicherte_Einstellungen.Bundesland = Name_Auswahl(1:2); % Es werden nur die ersten beiden Buchstaben verwendet.
        set(hObject, 'String', ['Bundesland:',32, Gespeicherte_Einstellungen.Bundesland])
        
    else
        Name_Feld = get(hObject, 'Tag');
        Neuer_Wert = get(hObject, 'Value');
        Gespeicherte_Einstellungen.(Name_Feld) = Neuer_Wert;
    end
    
    % Globle Varibale aktualisieren:
    global Einstellungen_Protokoll
    Einstellungen_Protokoll.flag_DispOut            = Gespeicherte_Einstellungen.flag_Protokollfenster_anzeigen;
    Einstellungen_Protokoll.flag_schreibe_in_Datei  = Gespeicherte_Einstellungen.flag_ProtokollDatei_fuehren; 
    
    save(Dateiname_gespeicherte_ES, '-struct', 'Gespeicherte_Einstellungen')
    return % Ende der Funktion.
end




Titel_Figure = 'Weitere Einstellungen der Clusterung';
HoeheEinerCheckbox = 20;
HoeheEinesButtons = 40;
Breite_Button = 300;
Position_x = 30;
Abstand_links_rechts_Pixel  = 30;
Abstand_unten_oben_Pixel    = 30;
Abstand_zwischen_Elementen  = 20;
Anzahl_Checkboxen = 6;
Anzahl_Buttons    = 1; 
xy_Pixel_Fenster = [2*Abstand_links_rechts_Pixel + Breite_Button, 2*Abstand_links_rechts_Pixel + Anzahl_Checkboxen * HoeheEinerCheckbox + Anzahl_Buttons * HoeheEinesButtons + (Anzahl_Checkboxen + Anzahl_Buttons) * Abstand_zwischen_Elementen];
scr = get(0,'ScreenSize');

h_fig = figure('menubar','none', ...
    'numbertitle','off', ...
    'resize','off', ...
    'handlevisibility','on', ...
    'visible','on', ...
    'units', 'pixels', ...
    'Name', Titel_Figure, ...
    'position',[ (scr(3:4)- xy_Pixel_Fenster)/2, xy_Pixel_Fenster ]);

%% Text: Bundesland
Position_y = Abstand_unten_oben_Pixel;
    h_Bundesland_push = uicontrol(h_fig, 'style','pushbutton' ...
        ,'position', [Position_x, Position_y, Breite_Button, HoeheEinesButtons] ...
        ,'visible',  'on' ...
        ,'String',   ['Bundesland:',32,Gespeicherte_Einstellungen.Bundesland] ...
        ,'Tag',      'Bundesland' ...
        ,'callback', 'Weitere_Einstellungen(gco)' ...
    );

%% Checkbox: flag_Feiertage_als_Eigenschaft
Position_y = Position_y + HoeheEinesButtons + Abstand_zwischen_Elementen;
    h_flag_Feiertage_als_Eigenschaft = uicontrol(h_fig, 'style','checkbox' ...
        ,'position', [Position_x, Position_y, Breite_Button, HoeheEinerCheckbox] ...
        ,'visible',  'on' ...
        ,'String',   'Feiertage als Eigenschaft verwenden' ...
        ,'Tag',      'flag_Feiertage_als_Eigenschaft' ... 
        ,'Value',    Gespeicherte_Einstellungen.flag_Feiertage_als_Eigenschaft ...
        ,'callback', 'Weitere_Einstellungen(gco)' ...
    );

%% Checkbox: flag_Jahreszeiten_als_Eigenschaft
Position_y = Position_y + HoeheEinerCheckbox + Abstand_zwischen_Elementen;
    h_flag_Jahreszeiten_als_Eigenschaft = uicontrol(h_fig, 'style','checkbox' ...
        ,'position', [Position_x, Position_y, Breite_Button, HoeheEinerCheckbox] ...
        ,'visible',  'on' ...
        ,'String',   'Jahreszeiten (meterologisch) als Eigenschaft verwenden' ...
        ,'Tag',      'flag_Jahreszeiten_als_Eigenschaft' ... 
        ,'Value',    Gespeicherte_Einstellungen.flag_Jahreszeiten_als_Eigenschaft ...
        ,'callback', 'Weitere_Einstellungen(gco)' ...
    );

%% Checkbox: flag_Ferien_als_Eigenschaft
Position_y = Position_y + HoeheEinerCheckbox + Abstand_zwischen_Elementen;
    h_flag_Ferien_als_Eigenschaft = uicontrol(h_fig, 'style','checkbox' ...
        ,'position', [Position_x, Position_y, Breite_Button, HoeheEinerCheckbox] ...
        ,'visible',  'on' ...
        ,'String',   'Ferien als Eigenschaft verwenden' ...
        ,'Tag',      'flag_Ferien_als_Eigenschaft' ... 
        ,'Value',    Gespeicherte_Einstellungen.flag_Ferien_als_Eigenschaft ...        
        ,'callback', 'Weitere_Einstellungen(gco)' ...
    );

%% Checkbox: flag_Wochentage_als_Eigenschaft
Position_y = Position_y + HoeheEinerCheckbox + Abstand_zwischen_Elementen;
    h_flag_Wochentage_als_Eigenschaft = uicontrol(h_fig, 'style','checkbox' ...
        ,'position', [Position_x, Position_y, Breite_Button, HoeheEinerCheckbox] ...
        ,'visible',  'on' ...
        ,'String',   'Wochentage als Eigenschaft verwenden' ...
        ,'Tag',      'flag_Wochentage_als_Eigenschaft' ...     
        ,'Value',    Gespeicherte_Einstellungen.flag_Wochentage_als_Eigenschaft ...        
        ,'callback', 'Weitere_Einstellungen(gco)' ...
    );

%% Checkbox: ProtokollDatei f�hren
Position_y = Position_y + HoeheEinerCheckbox + Abstand_zwischen_Elementen;
    h_flag_ProtokollDatei_fuehren = uicontrol(h_fig, 'style','checkbox' ...
        ,'position', [Position_x, Position_y, Breite_Button, HoeheEinerCheckbox] ...
        ,'visible',  'on' ...
        ,'String',   'Protokoll in Datei schreiben (Protokoll.txt)' ...
        ,'Tag',      'flag_ProtokollDatei_fuehren' ...     
        ,'Value',    Gespeicherte_Einstellungen.flag_ProtokollDatei_fuehren ...        
        ,'callback', 'Weitere_Einstellungen(gco)' ...
    );

%% Checkbox: Protokollfenster anzeigen
Position_y = Position_y + HoeheEinerCheckbox + Abstand_zwischen_Elementen;
    h_flag_Protokollfenster_anzeigen = uicontrol(h_fig, 'style','checkbox' ...
        ,'position', [Position_x, Position_y, Breite_Button, HoeheEinerCheckbox] ...
        ,'visible',  'on' ...
        ,'String',   'Protokollfenster anzeigen' ...
        ,'Tag',      'flag_Protokollfenster_anzeigen' ...     
        ,'Value',    Gespeicherte_Einstellungen.flag_Protokollfenster_anzeigen ...        
        ,'callback', 'Weitere_Einstellungen(gco)' ...
    );





end % MAIN function





