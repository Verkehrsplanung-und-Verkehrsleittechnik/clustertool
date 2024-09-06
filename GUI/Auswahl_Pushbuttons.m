function [idx_Auswahl, Name_Auswahl] = Auswahl_Pushbuttons(Namen_Buttons, Titel_Figure)
% Es wird ein Figure mit Pushbuttons erzeugt auf dem man eine Auswahl treffen kann.
% Es werden so viele Pushbuttons erzeugt, wie "Namen_Buttons" eingehen.
%
% --------------- Eingang:  ----------------------
%   
% - Namen_Buttons   (n x 1) - Cell mit den Bezeichnungen der Pushbuttons
% - Titel_Figure    String mit der Bezeichung, die oben in der Figure stehen soll (unbedeutend für die Funktion)
%
% --------------- Rückgabe: ----------------------
%
% - idx_Auswahl     (1 x 1) - Nummer mir der Zuordnung des Ausgewählten Namen_Button
% - Name_Auswahl    String mit dem Namen der getroffenen Auswahl (= Namen_Buttons(idx_Auswahl))
%
%       
%                                                                                       JL 14.11.2012
% % ---- Beispiel: --------------------
% Namen_Buttons = {'Currywurst mit Pommes'; 'Spaghetti Bolognese'; 'Steinofenpizza Speziale'; 'Chicken Nuggets mit Pommes'; 
%                  'Alaska-Seelachs in Kräutersoße mit Kartoffeln'; 'Bamigoreng mit Hühnerfleisch'; 'Hühnerfrikassee mit Risibisi'};
% Titel_Figure = 'Wähle ein Mittagsessen';
% [idx_Auswahl, Name_Auswahl] = Auswahl_Pushbuttons(Namen_Buttons, Titel_Figure)

if nargin < 1, error('Bitte "Namen_Buttons" definieren (erster Eingang).'), end
if nargin < 2 || isempty(Titel_Figure), Titel_Figure = 'Bitte auswählen';   end

if isnumeric(Namen_Buttons), Namen_Buttons = num2cell(Namen_Buttons); end
if ischar(Namen_Buttons), Namen_Buttons = {Namen_Buttons}; end

% Allgemeine Einstellungen:
Abstand_zwischen_Spalten = 10; % Pixel
Abstand_am_Rand = 100; % Pixel
MindestBreiteButtons = 100; % Pixel
HoeheEinesButtons = 30; % Pixel
max_Anzahl_Buttons_pro_Spalte = 30; % Anzahl Buttons (könnte auch berechnet werden.)
Breite_eines_Charakters = 10; % Pixel => Die benötigte Breite eines Charakters in Pixel. Sie wird für die Berechnung der Breite der Buttons benötigt.

% Pro Spalte werden 30 Buttons akzeptiert:
Anzahl_Spalten = ceil(numel(Namen_Buttons) / max_Anzahl_Buttons_pro_Spalte); % So viele Spalten werden benötigt.
scr = get(0,'ScreenSize');
Breite_des_Bildschirms = scr(3);

Breite_Button_soll = max(max(cellfun(@length, Namen_Buttons)) * Breite_eines_Charakters, MindestBreiteButtons); % Diese Breite sollten die Buttons haben, damit sie noch voll lesbar sind.
Breite_des_Fensters_soll = Breite_Button_soll * Anzahl_Spalten + 2 * Abstand_am_Rand + (Anzahl_Spalten - 1) * Abstand_zwischen_Spalten;
if Breite_des_Fensters_soll <= Breite_des_Bildschirms,
    % Das Fenster passt problemlos auf den Bildschirm.
    Breite_Button = Breite_Button_soll;
else
    % Das Fenster passt so nicht auf den Bildschrim, die Buttons müssen verkleinert werden:
    Breite_Button = ( (Breite_des_Bildschirms - 2 * Abstand_am_Rand - (Anzahl_Spalten - 1) * Abstand_zwischen_Spalten) / Anzahl_Spalten );
end
Breite_des_Fensters = Breite_Button * Anzahl_Spalten + 2 * Abstand_am_Rand + (Anzahl_Spalten - 1) * Abstand_zwischen_Spalten;
Hoehe_des_Fensters = min(HoeheEinesButtons * numel(Namen_Buttons), HoeheEinesButtons * max_Anzahl_Buttons_pro_Spalte);

% Größe des Fensters:
xy_Pixel_Fenster = [Breite_des_Fensters, Hoehe_des_Fensters];

h = figure('menubar','none', ...
    'numbertitle','off', ...
    'resize','off', ...
    'handlevisibility','on', ...
    'visible','on', ...
    'units', 'pixels', ...
    'Name', Titel_Figure, ...
    'position',[ (scr(3:4)- xy_Pixel_Fenster)/2, xy_Pixel_Fenster ]);

% Problem: Was im Callback ausgeführt wird ist nicht Bestandteil dieser lokalen Funktion!!! Es wird der Umweg über "UserData" gewählt.
for cnt_NB = 1 : numel(Namen_Buttons),
    % Zeile & Spalte bestimmen:
    idx_Spalte = ceil(cnt_NB / max_Anzahl_Buttons_pro_Spalte);
    idx_Zeile = cnt_NB - (idx_Spalte - 1) * max_Anzahl_Buttons_pro_Spalte;
    
    Position_akt_Button_x = Abstand_am_Rand + (idx_Spalte - 1) * (Breite_Button + Abstand_zwischen_Spalten);
    Position_akt_Button_y = xy_Pixel_Fenster(2) - idx_Zeile * HoeheEinesButtons;
    uicontrol(h, 'style','pushbutton', ...
        'position', [Position_akt_Button_x, Position_akt_Button_y, Breite_Button, HoeheEinesButtons], ...
        'visible',  'on', ...
        'Tag',      num2str(cnt_NB), ...
        'String',   Namen_Buttons{cnt_NB}, ...
        'callback', ['set(gcf,''UserData'',',num2str(cnt_NB),'), uiresume'])
end

uiwait % Warte auf Eingabe, wenn ein Button gedrückt wird, wird uiresume ausgeführt und es geht hier weiter:

% Prüfen, ob das Fenster ohne Auswahl geschlossen wurde:
if ~ishandle(h),
    % Das Fenster wurde ohne Auswahl geschlossen.
    idx_Auswahl = [];
    Namen_Buttons = '';
    return;
else
    % Es wurde eine Auswahl getroffen
    % Verändertes obj wird ausgelesen:
    idx_Auswahl = get(h,'UserData');
    close(h) %h (= figure) wird geschlossen.
    pause(0.01) %damit das Fenster geschlossen wird
    
    if nargout > 1,
        Name_Auswahl = Namen_Buttons{idx_Auswahl};
    end
end

end %function