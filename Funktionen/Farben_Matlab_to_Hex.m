function HexCode = Farben_Matlab_to_Hex(Matlab_Farben)
% Verändert eine n x 3 Matix mit Matlab - Farben Werten zu einem hex Code, welcher häufig in HTML verwendet wird.
%
% --------- Eingang: -------------
%   Matlab_Farbe
%       n x 3 numerische Matrix im Bereich 0...1
%
% --------- Rückgabe: -------------
%   HexCode
%       x x 1 Cell mit den FarbCodes für HTML
%           z.B. {'FF0000'} für Rot ([1 0 0])
%
% % Beispiel # 1:
% Matlab_Farben = [0 0 0]; % schwarz
% HexCode = Farben_Matlab_to_Hex(Matlab_Farben)
%
% % Beispiel # 2:
% Matlab_Farben = jet(8);
% HexCode = Farben_Matlab_to_Hex(Matlab_Farben)

if nargin < 1 || isempty(Matlab_Farben) || ~isnumeric(Matlab_Farben) || size(Matlab_Farben, 2) ~= 3,
    warning('Keine gültige Matlab Farbe eingegeben. Max. 3 Spalten mit Werten von 0...1')
end

% Für die Umrechnung von Matlab Fabren muss auf 255 hochgerechnet werden:
Farben_num = round(Matlab_Farben .* 255); % dec2hex funktioniert nicht mit Kommastellen !!!

Anzahl_Farben = size(Farben_num, 1);

HexCode = cell(Anzahl_Farben, 1); % vordimensionieren
for cnt_Z = 1 : Anzahl_Farben,
    Hex_String = cell(1, 3); % vordimensionieren
    for cnt_S = 1 : 3,
        Hex_String{cnt_S} = dec2hex(Farben_num(cnt_Z, cnt_S));
        % Matlab gibt nur so vielen Stellen wir nötig zurück, d.h. die Werte 1...16 sind einstellig !!!
        if length(Hex_String{cnt_S}) == 1,
            Hex_String{cnt_S} = ['0',Hex_String{cnt_S}]; % Es wird eine '0' vorangesetzt.
        end
    end
    HexCode{cnt_Z} = [Hex_String{:}];
end   
   



end