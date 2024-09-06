function Struct_IN = Struct_Felder_filtern(Struct_IN, idx_Filter)
% Ändert alle Felder einer Struct (auch alle "UnterStructs") so, dass aus allen Zeilenvektoren => Spaltenvektoren gemacht werden.
% Ist ein Feld eine Matrix, wird nichts unternommen:
% 
%   Hinweis:    Es werden nur die Felder gefiltert, die die gleiche Dimension wie "idx_Filter" haben.
%               Beispiel: 
%                   Wenn der Filter die Dimension (n x 1) hat, 
%                       werden alle Felder mit Dimension (n x m) gefiltert (m ist beliebig).
%                       NICHT gefiltert werden Felder der Dimension (m x n); also auch nicht (1 x n) !!!
%                       => falls doch gewünscht: siehe Funktion "Struct_Felder_als_Spaltenvektoren"
%
% Mit dieser Funktion können die Felder auch sortiert werden.
% % idx_Filter = [2 3 4 1 5 6 7 10 9 8];
%
% Eingänge:
%   - Struct_IN                 beliebige Struct
%   - idx_Filter                boolean - Wert      true  => Werte bleiben, 
%                                                   false => Werte werden ausgefiltert.
%                                                   Alle Felder der Struct mit der identischen Dimension der Ausrichtung (Spalten ODER Zeilenvektr)
%                                                   wie "idx_Filter" werden gefiltert.
%
%
%
%                                                               JL 04.12.2012
%   See also Struct_Felder_als_Spaltenvektoren.
%
% % Beispiel:
% BSP_Struct(2).a1 = 1:10;        % Zeilenvektor
% BSP_Struct(2).a2 = (1:10)';     % Spaltenvektor
% BSP_Struct(2).a3 = ones(10,10); % Matrix
% BSP_Struct(2).a4.a1 = 1:10;        % Zeilenvektor
% BSP_Struct(2).a4.a2 = (1:10)';     % Spaltenvektor
% BSP_Struct(2).a4.a3 = ones(10,10); % Matrix
% BSP_Struct(2).a5(2,2).a6.a7(3).a1 = 1:10;        % Zeilenvektor
% BSP_Struct(2).a5(2,2).a6.a7(3).a2 = (1:10)';     % Spaltenvektor
% BSP_Struct(2).a5(2,2).a6.a7(3).a3 = ones(10,10); % Matrix
% idx_Filter = false(10, 1); idx_Filter([2, 5, 8]) = true;
% BSP_Struct2 = Struct_Felder_filtern(BSP_Struct, idx_Filter);

if nargin < 2 || isempty(idx_Filter), 
    warning('Kein Filter eingehend => Es wird nichts gefiltert.'), 
    return, 
end

SIZE_Filter = size(idx_Filter);
Laenge_Filter    = max(SIZE_Filter);
if SIZE_Filter(1) == 1,
    Dimension_Filter = 2;
else
    Dimension_Filter = 1;
end

for cnt = 1 : numel(Struct_IN),
    Struct_IN(cnt) = MAIN_fuer_Single_Struct(Struct_IN(cnt));
end

    function Struct_IN_single = MAIN_fuer_Single_Struct(Struct_IN_single)
        Felder = fieldnames(Struct_IN_single);
        idx_UnterStruct = cellfun(@(x) isstruct(Struct_IN_single.(x)), Felder);
        
        % Felder mit UnterStruct:
        Felder_UnterStruct = Felder(idx_UnterStruct);
        for cnt_FU = 1 : length(Felder_UnterStruct),
            AKT_Struct = Struct_IN_single.(Felder_UnterStruct{cnt_FU});
            % Die Funktion wird nochmals mit der UnterStruct aufgerufen. Da innerhalb jeder Funktion alle UnterStructs mit wieder der Funktion aufgerufen werden,
            % werden alle UnterStructs berücksichtigt.
            Struct_IN_single.(Felder_UnterStruct{cnt_FU}) = Struct_Felder_filtern( AKT_Struct, idx_Filter );
        end
        
        % Felder keine UnterStruct:
        if any(~idx_UnterStruct),
            Felder_keine_UnterStruct = Felder(~idx_UnterStruct);
            % Felder mit der selben Dimension (in die Richtung) wie idx_Filter:
            idx_Filter_anwenden = cellfun(@(x) size(Struct_IN_single.(x), Dimension_Filter) == Laenge_Filter, Felder_keine_UnterStruct);
            
            if any(idx_Filter_anwenden),
                Felder_Filter_anwenden = Felder_keine_UnterStruct(idx_Filter_anwenden);
                for cnt_FS = 1 : length(Felder_Filter_anwenden),
                    % Hier muss unterschieden werden, ob Zeilen, oder Spalten gefiltert werden:
                    if Dimension_Filter == 1,
                        Struct_IN_single.(Felder_Filter_anwenden{cnt_FS}) = Struct_IN_single.(Felder_Filter_anwenden{cnt_FS})(idx_Filter, :); % Filter anwenden.
                    else
                        Struct_IN_single.(Felder_Filter_anwenden{cnt_FS}) = Struct_IN_single.(Felder_Filter_anwenden{cnt_FS})(:, idx_Filter); % Filter anwenden.
                    end
                end
            end
        end
        
    end
end % function Struct_Felder_filtern




