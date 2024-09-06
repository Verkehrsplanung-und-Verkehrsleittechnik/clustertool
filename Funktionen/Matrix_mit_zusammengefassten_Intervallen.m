function Intervallgrenzen = Matrix_mit_zusammengefassten_Intervallen(Matrix, flag_plot)
% Es wird erst untersucht, welche Werte sich schneiden und diese werden dann zusammengefasst.
% Als Ergebnis enthält die Matrix "Matrix" nur noch unabhängige Bereiche in jeder Zeile (keine Überschneidungen), so dass die
% Funktion "unique" nicht mehr benötigt wird.
%
% % Beispiel:
% Matrix = [-3 19; 14 16.5; 17.5 21; 25 30; 35 47; 47 53; 53 65; 62 71];
% Intervallgrenzen = Matrix_mit_zusammengefassten_Intervallen(Matrix)
%

% Am 19.07.2012 wurde erfolglos versucht die Funktion zu optimieren. Aber nach wie vor ist Variante 1 schneller.
% Variante 1 lässt sich noch leicht optimieren, indem "Matrix(cnt_Z,:) = [];" nicht für jeden Umlauf, sondern diese Info in einem Indexvektor gespeichert wird.
% Nachteil daran ist, das in jedem Umlauf die ganze Matrix mit den verbleibenden Intervallen Indiziert werden muss.
% Der Zeitgewinn ist jedoch nur gering, so dass aus Übersichtlichkeitsgründen die Funktion so belassen wird.

% Wenn true wird das Ergebnis angezeigt.
if nargin < 2 || isempty(flag_plot), flag_plot = false; end

if flag_plot,
    Matrix_speichern = Matrix;
end

welche_Variante = 1;
switch welche_Variante,
    case 1,
        % Mit dieser Variante wird zeilenweise geprüft, ob das aktuelle Intervall ein anderes tangiert.
        % Ist dies der Fall wird eine dieser Zeile so erweitert, dass sie die Grenzen von beiden Intervallen repräsentieren. 
        % Dann wird die aktuelle betrachtete Zeile gelöscht (was viel Zeit in Anspruch nimmt).
        % usw.
        
        for cnt_Z = size(Matrix,1) : -1 : 1,
            % Prüfen, ob der Startwert zwischen andere Bereiche fällt:
            idx_zusammen = Matrix(cnt_Z,1) >= Matrix(:,1) & Matrix(cnt_Z,1) <= Matrix(:,2);
            idx_zusammen(cnt_Z) = false; % die eigene Zeile natürlich nicht !!!
            if any(idx_zusammen),
                % wenn der Startwert in andere Bereiche fällt, wird der andere Bereich ggf. vergößert und der akt. Bereich gelöscht.
                idx_neu = find(idx_zusammen,1); % es wird immer der erste gefundenen Bereich verwendet. Später werden ggf. die restlichen zusammengefasst.
                Matrix(idx_neu,2) = max(Matrix(cnt_Z,2), Matrix(idx_neu,2)); % neuer Endwert des Bereichs.
                Matrix(cnt_Z,:) = [];
            else
                % Entsprechend der Startwert, wird für die Endwert eines Bereichs untersucht, ob es zwischen Start- und Endwert von anderen Bereichen fällt.
                % Ist das der Fall werden die beiden sich schneidenen Bereiche zusammengefügt.
                idx_zusammen = Matrix(cnt_Z,2) >= Matrix(:,1) & Matrix(cnt_Z,2) <= Matrix(:,2);
                idx_zusammen(cnt_Z) = false; % die eigene Zeile natürlich nicht  !!!
                if any(idx_zusammen),
                    idx_neu = find(idx_zusammen,1);
                    Matrix(idx_neu,1) = min(Matrix(cnt_Z,1), Matrix(idx_neu,1));
                    Matrix(cnt_Z,:) = [];
                end
            end
        end
        % Nun sind alle Bereiche in "Matrix" unabhängig voneinander.
        Intervallgrenzen = Matrix;
        
        
    case 2,
        % Neue Variante 19.07.2012 JL
        % Bei dieser Methode wird ausgehend vom Intervall mit der größten Ausdehnung, alle tangierenden Intervalle zusammengefasst. 
        % Dieses Intervall wird schrittweise weiter vergrößert, bis es keine anderen Intervalle tangiert.
        % Die tangierten Intervalle (und damit auch das Ausgangsintervall) werden in einem Boolean-Vektor markiert, dass sich im weiteren Verlauf nicht mehr in
        % Betracht gezogen werden müssen.
        % Tangiert ein Intervall keine anderen Intervalle mehr, wird mit dem nächst-größten noch nicht tangierten Intervall weiter gemacht. So lange, bis alle Intervalle 
        % in Betracht genommen wurden.
        
        % Es wird begonnen mit dem größten Intervall.
        Intervallgroesse = Matrix(:,2) - Matrix(:,1);
        [~, idx_Reihenfolge] = sort(Intervallgroesse);
        
        % "idx_Zeilen_aktiv" markiert die Zeilen die noch nicht in Betracht genommen wurden, und daher berücksichtigt werden müssen.
        idx_Zeilen_aktiv = true(1, size(Matrix,1)); % vordimensionieren
        
        % Intervallgrenzen vordefinieren:
        Intervallgrenzen = zeros(size(Matrix,1), 2); % vordefinieren (dabei werden später die nicht benötigten Zeilen wieder gelöscht).
        
        cnt = 0; % Start des Zählers.
        
        % Solange es noch Zeilen gibt, die noch nicht betrachtet wurden, wird diese Schleife durchlaufen.
        while any(idx_Zeilen_aktiv),    
            cnt = cnt + 1;
            % Die letzte aktive Zeile. Zur Erinnerung, die Zeilen sind sortiert mit aufsteigender Intervallgröße, 
            % d.h. es wird die Zeile von allen noch aktiven gewählt, welche das größte Intervall hat.
            zeilen_nr_aktiv = find(idx_Zeilen_aktiv); % Diese Zeilennummern sind noch aktiv.
            % Die von der Reihenfolge nach letzte aktive wird ausgewählt:
            akt_zeile = idx_Reihenfolge(find(ismember(idx_Reihenfolge, zeilen_nr_aktiv), 1, 'last')); 
            Intervallgrenzen(cnt, :) = Matrix(akt_zeile,:);
            idx_Zeilen_aktiv(akt_zeile) = false; % Die akt. Zeile muss nun nicht mehr weiter in Betracht genommen werden. **1**
            
            % Diese while-Schleife wird so lange durchlaufen bis das neue Intervall keine anderen Intervalle mehr findet, mit denen es sich zusammenschleißen kann.
            % => wenn sich ein Intervall mit keinen anderen mehr zusammenschließen kann ist es unabhängig von den anderen Intervallen.
            
            % Prüft, welche aktiven Intervalle (Zeilen) sich von "Matrix" mit den Intervallgrenzen tangieren.
            [idx_Zeilen_tangieren, idx_Zeilen_aktiv] = tangierende_Intervalle(Matrix(idx_Zeilen_aktiv,:), Intervallgrenzen(cnt,:), idx_Zeilen_aktiv);
            while any(idx_Zeilen_tangieren),

                % Die neuen Intervallgrößen werden aus allen tangierenden Intervallen und den bereits existierenden Intervallgrenzen gebildet:
                Intervallgrenzen(cnt, :) = [min([Matrix(idx_Zeilen_tangieren,1); Intervallgrenzen(cnt, 1)]), max([Matrix(idx_Zeilen_tangieren,2); Intervallgrenzen(cnt, 2)])];
                
                % Prüft, welche aktiven Intervalle sich von "Matrix" mit den Intervallgrenzen tangieren.
                [idx_Zeilen_tangieren, idx_Zeilen_aktiv] = tangierende_Intervalle(Matrix(idx_Zeilen_aktiv,:), Intervallgrenzen(cnt,:), idx_Zeilen_aktiv);
                
            end % while any(idx_Zeilen_tangieren),
        end
        % Alle Zeilen von "Matrix" wurden betrachtet, alle übrigen durch die vordimensionierung erzeugten Zeilen werden gelöscht.
        Intervallgrenzen(cnt + 1 : end, :) = [];
        
        % Zusätzlich werden die Intervallgrenzen der Größe nach sortiert:
        Intervallgrenzen = sortrows(Intervallgrenzen, 1);

end % switch welche_Variante,

if flag_plot,
    figure('Position', [200 200 800 600])
    
    % Plot Intervalle von Matrix
    Werte = 2;
    Farben = rand(size(Matrix_speichern,1),3); % zufällige Farben
    plot_von_bis_Zeit_Matrix( Matrix_speichern, Werte, Farben );
    
    % plot Intervallgrenzen:
    Werte = 1;
    Farben = [0 0 1];
    plot_von_bis_Zeit_Matrix( Intervallgrenzen, Werte, Farben );
    
    set(gca, 'XTick', sort(Intervallgrenzen(:)))
    grid_manuell
    
    
    
end





end % function


function [idx_Zeilen_tangieren, idx_Zeilen_aktiv] = tangierende_Intervalle(Matrix, Intervallgrenzen, idx_Zeilen_aktiv)
% prüft, welche aktiven Intervalle sich von "Matrix" mit den Intervallgrenzen tangieren.

% Es genügt wenn sich der Startwert ODER der Zielwert der anderen Intervall innerhalb der "Intervallgrenzen" (das akt. Intervall ist immer das größte !!!)
% Die Ursprungszeile (akt_zeile) ist NICHT enthalten, da bei **1** die akt_Zeile auf inaktiv gesetzt wird.
idx_Zeilen_tangieren = false(1, length(idx_Zeilen_aktiv)); % vordimensionieren
idx_Zeilen_tangieren(idx_Zeilen_aktiv) = (Matrix(:,1) >=  Intervallgrenzen(1) & Matrix(:,1) <= Intervallgrenzen(2)) | (Matrix(:,2) >=  Intervallgrenzen(1) & Matrix(:,2) <= Intervallgrenzen(2));

% Die Zeilen die gefunden wurden, müssen später nicht mehr in Betracht genommen werden:
idx_Zeilen_aktiv(idx_Zeilen_tangieren) = false;



end % function









