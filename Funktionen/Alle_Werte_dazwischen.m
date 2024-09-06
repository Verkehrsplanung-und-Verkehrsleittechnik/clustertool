function Alle_Werte = Alle_Werte_dazwischen(Matrix, flag_jeder_Werte_einmal, flag_letzte_Werte_nicht)
% Gibt von einer n x 2 Matrix alle Ganzzahligen Werte dazwischen an.
% Wenn flag_jeder_Werte_einmal = true, wird jeder Wert nur einmal wiedergegeben (und das schneller als unique(Alle_Werte) :)
% Wenn Matrix mehr als 2 Spalten halt, wird nur die erste und letzte betrachtet.
% Ist Matrix nicht Gangzahlig werden alle Werte abgerundet.
%
% Z.B: mit (flag_jeder_Werte_einmal = true & flag_letzte_Werte_nicht = false)
% Matrix = [1 3; 5 10; 8 15];
% Damit ergibt sich für die erste  Zeile: 1, 2, 3
%                           zweite Zeile: 5, 6, 7, 8, 9, 10
%                           dritte Zeile: 8, 9, 10, 11, 12, 13, 14, 15, 16
% Alle_Werte gibt jeden Wert nur einmal zurück, daher:
% Alle_Werte = [1; 2; 3; 5; 6; 7; 8; 9; 10; 11; 12; 13; 14; 15; 16];
%
% Mit "flag_letzte_Werte_nicht" werden die jeweils letzten Werte einer Zeile nicht verwendet.
% z.B.:
% Matrix = [1 3; 4 10; 14 18; 18 20];
% Damit ergibt sich für die erste  Zeile: 1, 2
%                           zweite Zeile: 4, 5, 6, 7, 8, 9
%                           dritte Zeile: 14, 15, 16, 17
%                           vierte Zeile: 18, 19
% jeweils die (3), (10), (18) und (20) werden nicht verwendet.
% Die (18) ist am Ende dennoch mit dabei, da sie in der letzten Spalte nochmals vorkommt.
%
% Eingang: 
%   - Matrix        n x 2
%       1. Spalte: kleiner Wert
%       2. Spalte: großer Wert
%   - flag_jeder_Werte_einmal   Boolean
%   - flag_letzte_Werte_nicht   Boolean
%
% Ausgabe: 
%   - Alle_Werte    m x 1 - Vektor
% 
%
% JL 15.03.2012 // Update: 18.07.2012

%% Prüfen des Eingangs:
if nargin < 1 || isempty(Matrix),
    Alle_Werte = [];
elseif ~isnumeric(Matrix),
    error('Eingang muss numerisch sein !!!')
elseif size(Matrix,2) < 2,
    error('Der Eingang braucht 2 Spalten.')
else
    if nargin < 2 || isempty(flag_jeder_Werte_einmal), flag_jeder_Werte_einmal = true; end
    if nargin < 3 || isempty(flag_letzte_Werte_nicht), flag_letzte_Werte_nicht = true; end
    
    % Spalten zwischen der ersten und der letzten werden ausgefiltert.
    if size(Matrix,2) > 2, Matrix(:,2:end-1) = []; end
    
    if flag_jeder_Werte_einmal,
        Matrix = Matrix_mit_zusammengefassten_Intervallen(Matrix);
    end
    
    if flag_letzte_Werte_nicht,
        % Die Anzahl der Werte, die den Bereich darstellen:
        Anz_Werte = Matrix(:,2) - Matrix(:,1); % der letzte Wert ist nun nicht mehr dabei.
        Alle_Werte = zeros(sum(Anz_Werte), 1); % vordimensionieren
        
        idx = [0; cumsum(double(Anz_Werte))]; % Für die Indexierung des Vektors "Alle_Werte"
        % Vektor "Alle_Werte" wird nun zusammengebaut.
        for cnt_AZ = 1 : size(Matrix, 1),
            Alle_Werte(idx(cnt_AZ) + 1 : idx(cnt_AZ+1)) = Matrix(cnt_AZ,1) : Matrix(cnt_AZ,2) - 1; % Jeder Ganzzahlige Wert zwischen Startwert und (Endwert-1) eines Bereiches
        end        
    else
        % Die Anzahl der Werte, die den Bereich darstellen:
        Anz_Werte = Matrix(:,2) - Matrix(:,1) + 1; % +1: erste und letzte Wert sind auch immer dabei.
        Alle_Werte = zeros(sum(Anz_Werte), 1); % vordimensionieren
        
        idx = [0; cumsum(double(Anz_Werte))]; % Für die Indexierung des Vektors "Alle_Werte"
        % Vektor "Alle_Werte" wird nun zusammengebaut.
        for cnt_AZ = 1 : size(Matrix, 1),
            Alle_Werte(idx(cnt_AZ) + 1 : idx(cnt_AZ+1)) = Matrix(cnt_AZ,1) : Matrix(cnt_AZ,2); % Jeder Ganzzahlige Wert zwischen Startwert und Endwert eines Bereiches
        end
    end
    
end % function






