function Zeit_aus = unix_Zeit ( Zeit_ein, welche_Richtung, datetick_format )
%
% Zeit_aus = unix_Zeit ( Zeit_ein, welche_Richtung, datetick_format )
%
% Berechnet aus der Unix Zeit die Matlab Zeit oder umgekehrt.
% Sommer / Winterzeit wird berücksichtigt. 
%
% Bei der Umstellung von Sommerzeit (MESZ) auf Winterzeit (MEZ) gibt es die Tagesstunde 02:00 - 03:00 doppelt.
% Die Funktion kann anhand der Matlab-Zeit nicht unterschieden, ob es die erste Stunde von 02:00 - 03:00 Uhr war oder die zweite.
% Die Unix-Zeit gibt IMMER die zweite Stunde aus !!!!
%
% Beispiel: Zeitumstellung von SZ auf WZ am 30.11.2011 03:00 Uhr.
% num2str(unix_Zeit(datenum('10-30-2011 01:59:59'))) => 1319932799
% num2str(unix_Zeit(datenum('10-30-2011 02:00:00'))) => 1319936400 (Sprung von 3600s)
%
% Eingänge:
%  - Zeit_ein (Zeit als Matlab Zeit ODER Unix-Zeit)
%  - welche_Richtung (1: Von Matlab-Zeit zu Unix-Zeit, sonst: Von Unix zu Matlab-Zeit, 3: von Unix-Zeit zu String (dd.mm.yyyy HH:MM:SS))
%
% Ausgabe:
%  - Zeit_aus (in Unix bzw. Matlab-Zeit Format).
%
% Benötigte externe Funktionen:
%  - Sommerzeit

if nargin < 2 || isempty(welche_Richtung),
    % bestimmen, welche Zeit eingegeben wurde:
    if sum(Zeit_ein > 1e6 | Zeit_ein < 0) > length(Zeit_ein) / 2
        % Wenn der mehr als die Hälfte der Zeit-Werte größer als 1.000.000 oder kleiner als 0 sind, dann ist es eine Unix-Zeit.
        % Unix-Zeit 1.000.000   => 11.01.1970
        % Matlab-Zeit 1.000.000 => 27.11.2737
        welche_Richtung = 0;
    else
        welche_Richtung = 1;
    end
end

% Matlab Zeit am 01.01.1970 um 00:00 Uhr (= Unix Zeit 0)
matlab_zeit_1970 = 719529;

if welche_Richtung == 1, 
    % Umrechnung von Matlab-Zeit in Unix-Zeit.
  
    % Matlab Zeit auf UTC umstellen. Bei Winterzeit wird eine Stunde, bei Sommerzeit 2 Stunden abgezogen.
    Zeit_UTC = Zeit_ein - 1/24 - (Sommerzeit(Zeit_ein) * 1/24); 
    
    
    % Mitteleuropäische Unix Zeit:
     Zeit_aus = (Zeit_UTC - matlab_zeit_1970) * 86400;  % 86400 ist die Zahl der Sekunden an einem Tag (24*60*60).
   
else
    
    % Von der Unix-Zeit zur Matlab Zeit:

    % UTC Unix Zeit: 
    Zeit_aus_UTC = matlab_zeit_1970 + Zeit_ein /60/60/24;
    
    % MEZ Zeit (UTC +1) Winterzeit
    Zeit_MEZ = Zeit_aus_UTC + 1/24;
    
    % Bei der Sommerzeit muss eine Stunde zusätzlich addiert werden: MESZ (UTC +2)
    Zeit_aus = Zeit_MEZ + (Sommerzeit(Zeit_MEZ) * 1/24); % Zeit_aus_UTC + 1/24 == Winterzeit (MEZ)
    
end

% Zeit als Sting: 
if welche_Richtung == 3, 
    if nargin < 3 || isempty(datetick_format), datetick_format = 'dd.mm.yyyy HH:MM:SS'; end
    Zeit_aus = datestr(Zeit_aus, datetick_format);
end
end

function IstSommerzeit = Sommerzeit(Zeitpunkt)
%
% IstSommerzeit = Sommerzeit(Zeitpunkt)
%
% Gibt "true" zurück, wenn "Zeitpunkt" innerhalb der Sommerzeit liegt
% "Zeitpunkt" muss für eine korrekte Bestimmung eine Normal-(Winterzeit) sein (datevec, datestr oder datenum)
% => d.h. ist Sommerzeit=true, dann sollte man zu "Zeitpunkt" 1h addieren
% Diese Funktion ist ab 1981 in Deutschland korrekt und berücksichtigt 2 Sommerzeitregelungen:
% 1981-1995
% 1996 bis heute (Stand 2010) ...in die Zukunft erfolgt keine Prüfung, ob die Umstellungsregeln bekannt sind
%
% Es darf keine Matrix mit Zeitpunkten im Matlab-Zeit Format eingehen, nur Vektoren (1xn oder nx1).
%
% Beispiel: 
%
% Zeitpunkt = [datenum('03-27-2011 02:00:00'), datenum('03-27-2011 02:00:01'), datenum('10-30-2011 01:59:59'), datenum('10-30-2011 02:00:00')];
% IstSommerzeit = Sommerzeit(Zeitpunkt); 
% IstSommerzeit =
%
%     0     1     1     0
% % (wobei die Zeit 27.03.2011 02:00:01 eigentlich nicht existiert)

if ischar(Zeitpunkt) || min(size(Zeitpunkt))==1, % wenn Zeitpunkt ein Charakter ist oder als Vektor eingeht.
    ZeitpunktVec = datevec(Zeitpunkt);
else
    ZeitpunktVec = Zeitpunkt;
end
ZeitpunktNum = datenum(ZeitpunktVec);

IstSommerzeit = false(size(Zeitpunkt));

%% Feste Sommerzeit: 
% April...August >=1981 => SZ
IstSommerzeit(ZeitpunktVec(:,1)>=1981 & ZeitpunktVec(:,2)>=4 & ZeitpunktVec(:,2)<=8)=true;
% Sept >=1996 => SZ
IstSommerzeit(ZeitpunktVec(:,1)>=1996 & ZeitpunktVec(:,2)>=4 & ZeitpunktVec(:,2)<=9)=true;

%% letzte Sonntage im März nach 1981 um 2 Uhr bestimmen
idx_Mar_nach_1981 = ZeitpunktVec(:,1)>=1981 & ZeitpunktVec(:,2)==3; 
if any(idx_Mar_nach_1981),
    EINSEN = ones(sum(idx_Mar_nach_1981),1); 
    Sonntage = datenum( [ ZeitpunktVec(idx_Mar_nach_1981,1), EINSEN.*3, EINSEN .* 31-(weekday(datenum([ZeitpunktVec(idx_Mar_nach_1981,1) EINSEN*[3 31 2 0 0]]))-1) EINSEN*[2 0 0]]);
    % alle die danach liegen => SZ
    IstSommerzeit(idx_Mar_nach_1981) = ZeitpunktNum(ZeitpunktVec(:,1)>=1981 & ZeitpunktVec(:,2)==3)>Sonntage;
end

%% letzte Sonntage im Sept vor 1996 um 3 Uhr bestimmen
idx_Sep_nach_1981_vor_1995 = ZeitpunktVec(:,1)>=1981 & ZeitpunktVec(:,1)<=1995 & ZeitpunktVec(:,2)==9; 
if any(idx_Sep_nach_1981_vor_1995), 
    EINSEN = ones(sum(idx_Sep_nach_1981_vor_1995),1); 
    Sonntage = datenum( [ ZeitpunktVec(idx_Sep_nach_1981_vor_1995,1), EINSEN.*9, EINSEN.*30 - (weekday(datenum([ZeitpunktVec(idx_Sep_nach_1981_vor_1995,1) EINSEN*[9 30 3 0 0]]))-1), EINSEN*[3 0 0]]);
    % alle die davor liegen => SZ
    IstSommerzeit(idx_Sep_nach_1981_vor_1995) = ZeitpunktNum(ZeitpunktVec(:,1)>=1981 & ZeitpunktVec(:,1)<=1995 & ZeitpunktVec(:,2)==9)<Sonntage;
end

%% letzte Sonntage im Okt nach 1996 um 3 Uhr bestimmen
idx_Okt_nach_1996 = ZeitpunktVec(:,1)>=1996 & ZeitpunktVec(:,2)==10; 
if any(idx_Okt_nach_1996),
    EINSEN = ones(sum(idx_Okt_nach_1996),1); 
    Sonntage = datenum( [ ZeitpunktVec(idx_Okt_nach_1996,1), EINSEN.*10, EINSEN.*31 - (weekday(datenum([ZeitpunktVec(idx_Okt_nach_1996,1) EINSEN*[10 31 3 0 0]]))-1), EINSEN*[3 0 0]]);
    % alle die davor liegen => SZ
    IstSommerzeit(idx_Okt_nach_1996) = ZeitpunktNum(ZeitpunktVec(:,1)>=1996 & ZeitpunktVec(:,2)==10)<Sonntage;
end
  
%% Zeiten vor 1981:
if min(ZeitpunktVec(:,1))<1981
%     disp('Achtung! Die Sommer-/Winterzeitprüfung funktioniert vor 1981 nicht!')
end


end




















