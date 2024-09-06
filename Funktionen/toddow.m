function [idx_toddow, toddow_Intervalle, Haeufigkeit_toddow_Intervalle] = toddow( Zeit, Intervall, flag_nur_tod, flag_addiere_10ms, flag_plot_Anzahl )
% Gibt in einem Indexvektor die Zeilen / Spalten eines Zeit-Vektors zurück, in welche Tagesstunde bzw. in welchen Wochentag sie passen.
%
% [idx_toddow, toddow_Intervalle] = toddow( Zeit, Intervall, flag_nur_tod, flag_addiere_10ms, flag_plot_Anzahl )
%
% Eingänge: 
%  Zeit              - Vektor im Matlab Zeit Format (z.B. now)
%  Intervall         - Intervallzeit in Minuten (Standard = 15)
%                      Über die Intervallzeit wird die Woche in gleich große Teile aufgeteilt. Wenn die Intervallzeit 1440 Minuten beträgt, wird nur nach 
%                      Tagen eingeteilt (1440 Minuten = =24 Stunden = 1 Tag).
%  flag_nur_tod      - wenn 1, dann wird nicht nach den Wochentagen unterscheidet, sondern nur nach dem Intervall eines Tages. (Standard = 0)
%  flag_addiere_10ms - Da häufig kleine Rundungsfehler auftreten, wird zu Zeit ein minimaler Wert von 0,1s dazuaddiert.
%                      Das kommt vor allem dann vor, wenn Intervalle eingeteilt werden.
%                      Damit kann es vorkommen, dass 14:00 Uhr zum Intervall 13-14 Uhr dazugerechnet wird, weil die 14 Uhr der Grenzen in
%                      dieser Funktion um 20ms größer als die 14:00 Uhr der eingehenden Zeit ist.
%   flag_plot_Anzahl - Plottet eine Übersicht über die Anzahl der TOD/DOW Intervalle
%
% Ausgabe:
%  idx_toddow        - Vektor mit gleicher Dimension wie Zeit. Der Vektor gibt für jedes Element von Zeit an, in welches Zeitintervall einer Woche die Zeit fällt.
%                      Das erste Intervall (idx_toddow == 1) beginnt immer Montags um 00:00. Das zweite Intervall beginnt dann Montag 0:00 + Intervalldauer.
%  toddow_Intervalle - Gibt die Intervalle der Woche zurück.
%                      toddow_Intervalle = 3 : 1/24/60 * Intervall : 9.99999999;
%  Haeufigkeit_toddow_Intervalle
%                    - Gibt für jedes "toddow_Intervalle", die Anzahl der Intervalle zurück.
%
%
% -------------------------------------------
%      Beispiel:
%
%  Zeit = now + rand(5000,1)*49; % 2000 Zeiteinträge aus den nächsten 7 Wochen.
%  Intervall = 60; % 60 Minuten, d.h. es wird jede Stunde der Woche betrachtet.
%
%  [idx_toddow, toddow_Intervalle] = toddow( Zeit, Intervall );
%
%  % Wenn Reisezeit ein Vektor mit gleicher Dimension wie Zeit existiert, können für alle Stundengruppen einer Woche die Mittelwerte gebildet werden:
%  Reisezeit = rand(5000,1)*20 + 100; % zufällige Reisezeit zwischen 80 und 120 Minuten.
%
%  Reisezeit_toddow = arrayfun(@(x) mean(Reisezeit(idx_toddow == x)), 1:length(toddow_Intervalle));
%  plot(toddow_Intervalle, Reisezeit_toddow, 'LineWidth', 2);
%  xlabel('ToD DoW', 'FontSize', 14), 
%  datetickzoom('x', 'ddd HH:MM')
%  ylabel('Reisezeit [min]', 'FontSize', 14)
%





% benötigte Funktion: wo_wert_im_vektor

if nargin < 2 || isempty(Intervall),            Intervall           = 15;       end
if nargin < 3 || isempty(flag_nur_tod),         flag_nur_tod        = 15;       end
if nargin < 4 || isempty(flag_addiere_10ms),    flag_addiere_10ms   = false;    end
if nargin < 5 || isempty(flag_plot_Anzahl),     flag_plot_Anzahl    = false;    end

% Da häufig kleine Rundungsfehler auftreten, wird zu Zeit ein minimaler Wert von 0,1s dazuaddiert.
% Das kommt vor allem dann vor, wenn Intervalle eingeteilt werden.
% Damit kann es vorkommen, dass 14:00 Uhr zum Intervall 13-14 Uhr dazugerechnet wird, weil die 14 Uhr der Grenzen in
% dieser Funktion um 20ms größer als die 14:00 Uhr der eingehenden Zeit ist.
if flag_addiere_10ms,
    Zeit = Zeit + 1/24/60/60/10;
end

if flag_nur_tod == 1,
    % Es wird unabhängig von dem Wochentag unterschieden. Nur die Tageszeiten sind ausschlaggebend.
    toddow_Intervalle = 0 : 1/24/60 * Intervall : 0.999999; 
    
    Zeit = rem(Zeit,1); % Nur die Tageszeit ist entscheidend (Tageszeit = Nachkommastelle).

else
    % Es wird nach Tageszeiten UND Wochentag unterschieden:
    
    toddow_Intervalle = 3 : 1/24/60 * Intervall : 9.99999999; % von Montag Jahr 0000 (3.1.0000) bis Sonntag (9.1.0000)
    
    Variante_zur_Wochentagsbestimmung = 2; % 2 ist neuer und schneller.

    switch Variante_zur_Wochentagsbestimmung
        
        case 1, %datestr & ismember
            
            % Tage ermitteln, die in den DOW stehen:
            Wochentage = arrayfun(@(x) datestr(x,'ddd'), Zeit, 'UniformOutput', false);
            % Zuordnung der Tage :
            Wochentage_Jahr_0 = datestr(3:9,'ddd'); % Tag 3 ist ein Montag: "datestr(3,'ddd')"
            
            % Wochentage bestimmen:
            [~, idx_Tage] = ismember(Wochentage, Wochentage_Jahr_0); %  1 == Montag, 2 == Dienstag, ..., 7 == Sonntag
            
            % Alle Daten auf die Woche 3.1.0000 bis 9.1.0000 setzten.
            Zeit = rem(Zeit,1) + idx_Tage + 2; % Damit 3 == Montag (datestr(3))
            
        case 2, %numerisch über Rest nach Division.
            idx_Tage = rem((floor(Zeit) - 3), 7); % Durch die - 3 ist 0 == Montag, 1 == Dienstag, ..., 6 == Sonntag.
            
            % Alle Daten auf die Woche 3.1.0000 bis 9.1.0000 setzten.
            Zeit = rem(Zeit,1) + idx_Tage + 3; % Damit 3 == Montag (datestr(3))
            
    end
    
end % if flag_nur_tod == 1,

% Bestimmen zwischen welchen Intervallen die Zeiten liegen:
[~, idx_toddow] = histc(Zeit, [toddow_Intervalle, ceil(max(toddow_Intervalle))]); % Die 1 muss am Ende stehen | oder bei Wochentagen die 10

% Funktioniert bei Zeitumstellung nicht:
% idx_toddow = wo_wert_im_vektor(toddow_Intervalle, Zeit, 2);

if nargout > 2 || flag_plot_Anzahl,
    Haeufigkeit_toddow_Intervalle = hist(idx_toddow, 1 : length(toddow_Intervalle));
end



if flag_plot_Anzahl,
    
    flag_relative_Haeufigkeit = true;
    
    if flag_relative_Haeufigkeit,
        plot_Haeufigkeit_toddow_Intervalle = Haeufigkeit_toddow_Intervalle ./ sum(Haeufigkeit_toddow_Intervalle) .* 100;
        yText = 'relative Häufigkeit [%]';
    else
        plot_Haeufigkeit_toddow_Intervalle = Haeufigkeit_toddow_Intervalle;
        yText = 'absolute Häufigkeit';
    end
    
    h_bar = bar(toddow_Intervalle, plot_Haeufigkeit_toddow_Intervalle);
    set(gca ...
        ,'XLim', [3 10] ...
        ,'XTick', 3.5 : 1 : 10 ...
        ,'XTickLabel', {'Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So', ''} ...
        );
    Lohmiller_Standard_plot_Format('TOD / DOW', yText)
    grid off
    ES.Linienart       = ':';
    ES.Linienstaerke   = 0.5;
    ES.axis_handle     = gca;
    ES.Farbe           = [0,0,0];
    ES.DisplayName1    = 'Grid';
    ES.Tag1            = 'Grid';
    ES.flag_x_Achse    = true;
    ES.flag_y_Achse    = true;
    ES.xPos = 3 : 1 : 10;
    ES.yPos = get(ES.axis_handle, 'YTick');
    grid_manuell( ES );
    
    
end





