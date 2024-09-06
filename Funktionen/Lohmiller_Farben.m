function Farben = Lohmiller_Farben(welche_Farben, Anzahl_benoetigter_Farben, flag_Farben_zeigen, hanlde_axes_bereits_verwendete_Farben_entfernen)
% Vordefinierte Farben
%
%   Farben = Lohmiller_Farben(welche_Farben, Anzahl_benoetigter_Farben, flag_Farben_zeigen, hanlde_axes_bereits_verwendete_Farben_entfernen)
%
% ----- Eingänge: -----------------------------
% 1.) welche_Farben (numerisch, eine Dimension)
%       1: Gute Erkennbarkeit, jedoch häßlich
%       2: Themenpalette "Larissa" von Microsoft
%       3: Linienfarben von Excel 2010
%       4: Farben von Apple Diagrammen (Numbers)
%       5: Farbverlauf von grün nach rot
%       6: Lange Farbenreihenfolge (erst 4: Apple, dann 3: Excel, dann 2: Larissa )
%       7: Grün Gelb Rot (Ampelfarben)
%
% ALTERNATIV können auch Farben direkt eingegeben werden. Dann plottet diese Funktion die Farben nur.
%       Die Rückgabe ist in diesem Fall gleich der Eingabe.
% 2.) Anzahl_benoetigter_Farben (numerisch), die Anzahl der benötigten unterschiedlichen Farben. (kann auch leer bleiben)
% 3.) flag_Farben_zeigen | wenn "true" werden die Farben dargestellt.
% 4.) hanlde_axes_bereits_verwendete_Farben_entfernen
%       Mit diesem Eingang werden nur Farben, welche NICHT im "hanlde_axes_bereits_verwendete_Farben_entfernen"
%       vorkommen zurückgegeben.


if nargin < 1 || isempty(welche_Farben) || ~isnumeric(welche_Farben), 
    welche_Farben = 6; 
end
    
if nargin < 3 || isempty(flag_Farben_zeigen), flag_Farben_zeigen = false; end

if size(welche_Farben,2) == 3,
    Farben = welche_Farben; % Eingabe ist bereits eine Farben-Matrix
else
    switch welche_Farben
        case 1,
            Farben = [0.396078431372549,0,0.603921568627451;
                0,0,1;0,1,1;
                0,1,0;
                1,1,0;
                1,0.470588235294118,0;
                1,0,0;
                0,0,0];
        case 2,
            Farben = [0.121568627450980,0.270588235294118,0.517647058823530;
                0.909803921568627,0.925490196078431,0.866666666666667;
                0.301960784313725,0.517647058823530,0.741176470588235;
                0.768627450980392,0.309803921568627,0.274509803921569;
                0.600000000000000,0.733333333333333,0.360784313725490;
                0.529411764705882,0.396078431372549,0.635294117647059;
                0.294117647058824,0.666666666666667,0.792156862745098;
                0.952941176470588,0.607843137254902,0.258823529411765;
                0,0,0];
        case 3,
            % Standard Farben für Excel Diagramme
            Farben = [79, 129, 189;
                168,  66,  63;
                134, 164,  74;
                110,  84, 141;
                61, 150, 174;
                218, 129,  55;
                142, 165, 203;
                206, 142, 141;
                181, 202, 146];
            Farben = Farben ./ 255;
        case 4,
            % Standard Farben von Apple Diagrammen (Numbers)
            Farben = [242, 126, 0;
                83, 133, 222;
                192, 127, 126;
                246, 86, 57;
                16, 121, 16;
                168, 114, 5;
                0, 177, 243];
            Farben = Farben ./ 255;
        case 5, % Farbverlauf von Grün nach Rot:
            Farbverlauf = (0:1/Anzahl_benoetigter_Farben:1)';
            Farben = [Farbverlauf, flipud(Farbverlauf), zeros(length(Farbverlauf),1)];
        case 6,
            % Standard Farben von Apple Diagrammen (Numbers)
            flag_Farben_zeigen1 = false;
            Farben = [  Lohmiller_Farben(4, [], flag_Farben_zeigen1);
                        Lohmiller_Farben(3, [], flag_Farben_zeigen1);
                        Lohmiller_Farben(2, [], flag_Farben_zeigen1);
                        Lohmiller_Farben(7, [], flag_Farben_zeigen1);
                     ];
            Farben(8,:) = []; % Diese Farbe ist zu ähnlich mit Farben(2,:) 
            Farben([12,13,14],:) = []; % Diese Farbe ist zu ähnlich mit anderen Farben
            Farben(15:20,:) = []; % Diese Farbe ist zu ähnlich mit anderen Farben
            
            
            
        case 7,
            % Grün Gelb Rot 
            Farben = [155 187 89;
                255 192  0;
                192  80 77] ./ 255;
            
        case 8,
            % Reihenfolge für Ursachen von Verspätungen (Q, Q+Unfall, Q+Regen, alle, Unfall, ...) 
            Farben = [128 100 162; % 'nichts von den genannten'       
                      247 150  70; % 'Regen'
                      155 187  89; % 'Unfall & Regen'
                      192  80  77; % 'Unfall'
                       23  55  94; % 'hohes Verkehrsaufkommen & Unfall & Regen'
                       85 142 213; % 'hohes Verkehrsaufkommen & Regen'
                      142 180 227; % 'hohes Verkehrsaufkommen & Unfall'
                      198 217 241] ./ 255; % 'hohes Verkehrsaufkommen'
        case 9,
            % Farben für Wochentage # 1: http://www.gabrielelenz.de/wp-content/uploads/2010/08/Wochentage_Farben2.jpg
            Farben = [184 35 39; % Sonntag
                      71 128 158; % Montag
                      255 216 0; % Dienstag
                      168 207 56; % Mittwoch
                      122 103 86 ; % Donnerstag
                      165 183 223; % Freitag
                      237 0 140] ./ 255; % Samstag     
        case 10,
            % Farben für Wochentage # 2: http://3.bp.blogspot.com/-FqO-9Mgpkok/UHwvNjeEckI/AAAAAAAAAXo/d1bOqpAvkFA/s1600/Wochenkreis.jpg
            Farben = [253 36 1; % Sonntag
                      255 122 1; % Montag
                      255 223 0; % Dienstag
                      207 240 0; % Mittwoch
                      118 196 196; % Donnerstag
                      82 45 62; % Freitag
                      148 14 3] ./ 255; % Samstag                         
        case 11,
            % Farben für Wochentage # 3: http://3.bp.blogspot.com/-FqO-9Mgpkok/UHwvNjeEckI/AAAAAAAAAXo/d1bOqpAvkFA/s1600/Wochenkreis.jpg
            % Ein Tag verschoben
            Farben = [148 14 3; % Sonntag
                      253 36 1; % Montag
                      255 122 1; % Dienstag
                      255 223 0; % Mittwoch
                      207 240 0; % Donnerstag
                      118 196 196; % Freitag
                      82 45 62] ./ 255; % Samstag
        case 12,
            % Farben für Wochentage # 3: http://3.bp.blogspot.com/-FqO-9Mgpkok/UHwvNjeEckI/AAAAAAAAAXo/d1bOqpAvkFA/s1600/Wochenkreis.jpg
            % Ein Tag verschoben + Anpassung.
            Farben = [148 14 3; % Sonntag
                253 36 1; % Montag
                255 122 1; % Dienstag
                255 223 0; % Mittwoch
                207 240 0; % Donnerstag
                118 196 196; % Freitag
                46 13 202] ./ 255; % Samstag
    end
end

% Bereits verwendete Farben werden nicht mehr zurückgegeben:
if nargin >= 4 && ~isempty(hanlde_axes_bereits_verwendete_Farben_entfernen) && ishandle(hanlde_axes_bereits_verwendete_Farben_entfernen),
    
    % Bereits verwendete Farben:
    h_plot = get(hanlde_axes_bereits_verwendete_Farben_entfernen,'Children');
    if ~isempty(h_plot),
        Type = get(h_plot, 'Type');
        if ~iscell(Type), Type = {Type}; end
        % Nur die vom Typ "line":
        h_bars = h_plot(ismember(Type, 'hggroup'));
        h_line = h_plot(ismember(Type, 'line'));
        if ~isempty(h_bars),
            Bereits_verwendete_Farben_bars = get(h_bars, 'FaceColor');
            if iscell(Bereits_verwendete_Farben_bars),
                % Farbenbezeichnung welche nicht numerisch sind rausnehmen:
                Bereits_verwendete_Farben_bars(~cellfun(@isnumeric, Bereits_verwendete_Farben_bars)) = []; 
                Bereits_verwendete_Farben_bars = vertcat(Bereits_verwendete_Farben_bars{:}); % Als Matrix schreiben
            end
        else
            Bereits_verwendete_Farben_bars = [];
        end
        if ~isempty(h_line),
            Bereits_verwendete_Farben_line = get(h_line, 'Color');
            if iscell(Bereits_verwendete_Farben_line),
                Bereits_verwendete_Farben_line = vertcat(Bereits_verwendete_Farben_line{:}); % Als Matrix schreiben:
            end
        else
            Bereits_verwendete_Farben_line  = [];
        end
        % Alle verwendeten Farben zusammen:
        Bereits_verwendete_Farben = [Bereits_verwendete_Farben_bars; Bereits_verwendete_Farben_line]; 
        
        % Bereits verwendete Farben ausfiltern:
        Farben(ismember(Farben, Bereits_verwendete_Farben, 'rows'), :) = [];
        
        % Hinweis: Wenn bereits alle ausgewählten Farben verwendet wurden, werden die jet - Farben verwendet.
        % Dabei wird nicht überprüft, ob welche bereits verwendet worden sind.
    end
end



%% Wenn mehr Farben angefordert werden, als verfügbar sind, werden die Farben mit Matlab Farben erweitert:
if nargin >= 2 && any(Anzahl_benoetigter_Farben),
    if size(Farben,1) < Anzahl_benoetigter_Farben,
        Farben(end + 1 : Anzahl_benoetigter_Farben, :) = jet(Anzahl_benoetigter_Farben - size(Farben,1));
    end    
end



%% Farben bei gg. plotten:
if flag_Farben_zeigen,
    Farben_darstellen(Farben)
end

end % MAIN function









