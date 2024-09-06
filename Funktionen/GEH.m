% Berechnet den mittleren GEH zwischen allen Elementen eines Objekts - nach den distfun-Rahmenbedingungen (siehe unten)
% Die Werte sollten Verkehrsstärken sein - also >=0
% NaN-Werte sind erlaubt und werden aus der Mittelwertbildung ausgeschlossen
% komplette NaN-Paarungen werden auf den doppelten maximalen Abstand aller anderen Objekte gesetzt
%
% GEH=(2*(M-C)^2/(M+C))^0.5   (mean of all)
%
% A distance function must be of form 
% d2 = distfun(XI,XJ)
% taking as arguments a 1-by-n vector XI, corresponding to a single row of X, 
% and an m2-by-n matrix XJ, corresponding to multiple rows of X. distfun must accept a matrix XJ with an arbitrary number of rows. 
% distfun must return an m2-by-1 vector of distances d2, whose kth element is the distance between XI and XJ(k,:).

% Für kmeans-Clusterung wurde Input/Output erweiter auf
% Vec = m3-by-n
% Mat = m2-by-n
% GEH = m3-by-m2 (Abstände zwischen allen Objekten in Vec und Mat)
function GEHs=GEH(Vec,Mat)
    
    % GEH(Vec, Mat) ist identisch zu ctranspose(GEH(Mat, Vec)) !!!
    % Da die einzelnen Zeilen von Vec in einer for-Schleife abgearbeitet werden, ist es besser, wenn Vec, weniger Zeilen hat als Mat.
    % Ist dies nicht der Fall (d.h. size(Vec,1) > size(Mat,1)), werden die beiden Variablen vertauscht und am Ende das Ergebnis transponiert.
    % So arbeitet die Funktion in diesem Fall schneller.
    if size(Vec,1) > size(Mat,1),
        flag_tauschen = true;
        Mat2 = Mat;
        Mat = Vec; Vec = Mat2;
    else
        flag_tauschen = false;
    end

    % um ein Divide-By-Zero zu vermeiden, wird ein kleines bisschen d.h. 1e-308 dazugezählt
    Vec=Vec+1e-308;

    % vordimensionieren
    GEHs=zeros(size(Vec,1),size(Mat,1));
    
    % Schleife zur Berechnung von Distanzen zwischen mehreren Objekten in Vec (wird von Kmeans verwendet)
    for i=1:size(Vec,1)
        GEHs(i,:)=GEHFcn(Vec(i,:));
    end
                            
    % alle die keinen GEH bekommen haben, bekommen den doppelten Max-Wert
    GEHs(isnan(GEHs))=2*max(max(GEHs));

    % nested function für die eigentliche Berechnung der GEH-Werte
    function GEHis=GEHFcn(VecFcn)
        % Start(Fehl)wert setzen
        allGEHis=-ones(size(Mat));

        % Bestimmen wo beide Objekte Zahlen enthalten
        NoNaNs=bsxfun(@and,~isnan(VecFcn),~isnan(Mat));
        
        % Das Vergleichsobjekt(Vec) auf die Größe aller Objekte(Mat) hochskalieren
        VecFcn=repmat(VecFcn,size(Mat,1),1);
        
        % den GEH zwischen allen Wertepaaren, die nicht NaN sind berechnen
        allGEHis(NoNaNs)=(2*((VecFcn(NoNaNs)-Mat(NoNaNs)).^2)./(VecFcn(NoNaNs)+Mat(NoNaNs))).^0.5;
        
        % den Mittelwert aller Nicht-NaNs berechnen und dabei den -1 Start(Fehl)wert rausrechnen
        GEHis=(sum(allGEHis,2)+sum(~NoNaNs,2))./(size(Mat,2)-sum(~NoNaNs,2));
    end

    if flag_tauschen,
        % Wenn die Eingänge getauscht wurden, muss das Ergebnis transponiert werden.
        GEHs = GEHs';
    end
end






