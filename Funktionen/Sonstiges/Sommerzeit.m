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








