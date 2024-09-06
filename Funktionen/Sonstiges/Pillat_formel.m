% Pillat Formel 
% Berechnet den mittleren Wert zwischen allen Elementen eines Objekts - nach den distfun-Rahmenbedingungen (siehe unten)
% Die Werte sollten >= 0 sein
% NaN-Werte sind erlaubt und werden aus der Mittelwertbildung ausgeschlossen
% komplette NaN-Paarungen werden auf den doppelten maximalen Abstand aller anderen Objekte gesetzt
%
% delta = ((X-Y)^2)/((X+Y)/2)
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

function Wert = Pillat_formel(Vec,Mat)

    
    % Pillat_formel(Vec, Mat) ist identisch zu ctranspose(Pillat_formel(Mat, Vec)) !!!
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
    Wert = zeros(size(Vec,1),size(Mat,1));
    
    % Schleife zur Berechnung von Distanzen zwischen mehreren Objekten in Vec (wird von Kmeans verwendet)
    for i=1:size(Vec,1)
        Wert(i,:)=GEHFcn(Vec(i,:));
    end
                            
    % alle die keinen Wert bekommen haben, bekommen den doppelten Max-Wert
    Wert(isnan(Wert))=2*max(max(Wert));

    % nested function für die eigentliche Berechnung der GEH-Werte
    function GEHis = GEHFcn(VecFcn)
        % Start(Fehl)wert setzen
        allGEHis = -ones(size(Mat));

        % Bestimmen wo beide Objekte Zahlen enthalten
        NoNaNs = bsxfun(@and,~isnan(VecFcn),~isnan(Mat));
        
        % Das Vergleichsobjekt(Vec) auf die Größe aller Objekte(Mat) hochskalieren
        VecFcn = repmat(VecFcn,size(Mat,1),1);
        
        % den GEH zwischen allen Wertepaaren, die nicht NaN sind berechnen
        allGEHis(NoNaNs) = ( (VecFcn(NoNaNs)-Mat(NoNaNs)).^2 ) ./ ( (VecFcn(NoNaNs)+Mat(NoNaNs))./2 );
        
        % den Mittelwert aller Nicht-NaNs berechnen und dabei den -1 Start(Fehl)wert rausrechnen
        GEHis=(sum(allGEHis,2)+sum(~NoNaNs,2))./(size(Mat,2)-sum(~NoNaNs,2));
    end

    if flag_tauschen,
        % Wenn die Eingänge getauscht wurden, muss das Ergebnis transponiert werden.
        Wert = Wert';
    end






end % function Pillat_formel(X,Y)