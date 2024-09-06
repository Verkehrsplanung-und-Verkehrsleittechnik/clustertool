% Berechnet den euklidschen Abstands zwischen allen Elementen eines Objekts - nach den distfun-Rahmenbedingungen (siehe unten)
% NaN-Werte sind erlaubt und werden als MaxWerte anteilsmäßig dazu gezählt
% komplette NaN-Paarungen werden auf den doppelten maximalen Abstand aller anderen Objekte gesetzt
%
% Euclidean=(M-C)^2   (sum of all)^0.5
%
% A distance function must be of form 
% d2 = distfun(XI,XJ)
% taking as arguments a 1-by-n vector XI, corresponding to a single row of X, 
% and an m2-by-n matrix XJ, corresponding to multiple rows of X. distfun must accept a matrix XJ with an arbitrary number of rows. 
% distfun must return an m2-by-1 vector of distances d2, whose kth element is the distance between XI and XJ(k,:).

% Für kmeans-Clusterung wurde Input/Output erweiter auf
% Vec = m3-by-n
% Mat = m2-by-n
% Euclideans = m3-by-m2 (Abstände zwischen allen Objekten in Vec und Mat)
function Euclideans=Euclidean_mit_NaN(Vec,Mat)

% Berechnen von Distanzen zwischen mehreren Objekten (für kmeans)...
if size(Vec,1)>1
    % ...(zeilenweiser) Aufruf der Abstands-Funktion (die dann den "else"-Teil auswertet
    Euclideans=-ones(size(Vec,1),size(Mat,1));
    for i=1:size(Vec,1)
        Euclideans(i,:) = Euclidean_mit_NaN(Vec(i,:),Mat);
    end
else
    % Start(Fehl)wert setzen
    Euclideans=-ones(size(Mat,1),1);

    % Bestimmen wo beide Objekte Zahlen enthalten
    NoNaNs=bsxfun(@and,~isnan(Vec),~isnan(Mat));

    % Abstände ausrechnen
    for i=1:size(Mat,1)
        if any(NoNaNs(i,:))
            tmp=(Vec(NoNaNs(i,:))-Mat(i,NoNaNs(i,:))).^2;
            Euclideans(i)=(sum(tmp)+sum(~NoNaNs(i,:))*max(tmp))^0.5;
        end
    end

    % alle die keinen Abstand bekommen haben, bekommen den doppelten Max-Wert
    Euclideans(Euclideans==-1)=max(Euclideans)*2;
end