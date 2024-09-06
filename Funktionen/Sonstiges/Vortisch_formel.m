% Vortisch Formel 
% Vortisch
% Berechnet den mittleren Wert zwischen allen Elementen eines Objekts - nach den distfun-Rahmenbedingungen (siehe unten)
% Die Werte sollten >= 0 sein
% NaN-Werte sind erlaubt und werden aus der Mittelwertbildung ausgeschlossen
% komplette NaN-Paarungen werden auf den doppelten maximalen Abstand aller anderen Objekte gesetzt
%
% Formel siehe Vorlesungsskript Verkehrstechnik & Verkehrsleittechnik 2011 Ilias Seite 149, 150
%
% A distance function must be of form 
% d2 = distfun(XI,XJ)
% taking as arguments a 1-by-n vector XI, corresponding to a single row of X, 
% and an m2-by-n matrix XJ, corresponding to multiple rows of X. distfun must accept a matrix XJ with an arbitrary number of rows. 
% distfun must return an m2-by-1 vector of distances d2, whose kth element is the distance between XI and XJ(k,:).

% Für kmeans-Clusterung wurde Input/Output erweiter auf
% Vec = m3-by-n
% Mat = m2-by-n
% Distanz = m3-by-m2 (Abstände zwischen allen Objekten in Vec und Mat)

function Distanz = Vortisch_formel(Vec,Mat)

    % Vortisch_formel(Vec, Mat) ist identisch zu ctranspose(Vortisch_formel(Mat, Vec)) !!!

    % Korrelationskoeffizient bestimmen:
    % Matlab rechnet jeweils die Korrelation zwischen Spalten aus. Hier sol aber die Korrelation zwischen Zeilen bestimmt werden, daher muss transponiert werden:
    
    % um ein Divide-By-Zero zu vermeiden, wird ein kleines bisschen d.h. 1e-308 dazugezählt
    
    % Parameter, der angibt, wie start die Form im Vergleich zur Distanz gewichtet wird.
    alpha = 0.5;
    
    
    Vec = Vec+1e-308;
    Mat = Mat+1e-308;
    
    wie_korrelation = 1; 
    switch wie_korrelation
        case 1, % mit Matlabfunktion
            KORRELATION = corrcoef([Vec; Mat]');
            
            % corrcoef bestimmt immer alle Kombinationen von Spalten miteinander.
            Distanz_Form = KORRELATION(1:size(Vec,1), size(Vec,1) + 1 : end);
            
            % 1 bedeutet eine identische Form, 0 eine sehr abweichende Form
                        
        case 2, % selbst programmiert
            
            % Für jede Zeile der Mittelwert der Zeile abziehen:
            Vec_diff = bsxfun(@minus, Vec, mean(Vec,2));
            Mat_diff = bsxfun(@minus, Mat, mean(Mat,2));
            Distanz_Form = zeros(size(Vec,1), size(Mat,1));
            for cnt_V = 1 : size(Vec,1),
                for cnt_M = 1 : size(Mat,1),
                    Distanz_Form(cnt_V, cnt_M) = sum(Vec_diff(cnt_V, :) .* Mat_diff(cnt_M ,:)) ./ sqrt( sum( Vec_diff(cnt_V, :).^2 ) .* sum( Mat_diff(cnt_M ,:).^2 ) );
                end
            end
    end
    
    % Für die Bestimmtung der Lageähnlichkeit wird die so genannte mittlere relative Ähnlichkeit definiert.
    Distanz_Lage = zeros(size(Vec,1), size(Mat,1));
    for cnt_V = 1 : size(Vec,1),
        for cnt_M = 1 : size(Mat,1),
            minmax = sort([Vec(cnt_V,:); Mat(cnt_M,:)]);
            Distanz_Lage(cnt_V, cnt_M) = mean(minmax(1,:) ./ minmax(2,:));
        end
    end
    % 1 bedeutet eine identische Lage, 0 eine sehr abweichende Lage
    
    Distanz = 1 - (alpha .* Distanz_Form + (1-alpha) .* Distanz_Lage);

    % alle die keinen Wert bekommen haben, bekommen den doppelten Max-Wert
    Distanz(isnan(Distanz))=2*max(max(Distanz));    

end % function Vortisch_formel(X,Y)










