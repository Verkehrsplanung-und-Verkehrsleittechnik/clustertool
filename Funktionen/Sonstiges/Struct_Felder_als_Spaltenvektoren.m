function Struct_IN = Struct_Felder_als_Spaltenvektoren(Struct_IN, flag_als_Zeilenvektor)
% Ändert alle Felder einer Struct (auch alle "UnterStructs") so, dass aus allen Zeilenvektoren => Spaltenvektoren gemacht werden.
% Ist ein Feld eine Matrix, wird nichts unternommen:
% 
% Eingänge:
%   - Struct_IN                 beliebige Struct
%   - flag_als_Zeilenvektor     boolean - Wert => Wenn true, werden alle Felder zu Zeilenvektoren.
%
%
%                                                               JL 28.11.2012
%   See also Struct_Felder_filtern.
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
% flag_als_Zeilenvektor = false;
% BSP_Struct2 = Struct_Felder_als_Spaltenvektoren(BSP_Struct, flag_als_Zeilenvektor);

if nargin < 2 || isempty(flag_als_Zeilenvektor), flag_als_Zeilenvektor = false; end

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
            Struct_IN_single.(Felder_UnterStruct{cnt_FU}) = Struct_Felder_als_Spaltenvektoren( AKT_Struct, flag_als_Zeilenvektor );
        end
        
        % Felder keine UnterStruct:
        if any(~idx_UnterStruct),
            Felder_keine_UnterStruct = Felder(~idx_UnterStruct);
            idx_SpaltenVektor = Felder_SpaltenVektoren(Struct_IN_single, Felder_keine_UnterStruct);
            if any(idx_SpaltenVektor),
                Felder_Spaltenvektor = Felder_keine_UnterStruct(idx_SpaltenVektor);
                for cnt_FS = 1 : length(Felder_Spaltenvektor),
                    Struct_IN_single.(Felder_Spaltenvektor{cnt_FS}) = Struct_IN_single.(Felder_Spaltenvektor{cnt_FS})'; % transponieren.
                end
            end
        end
        
        function idx_SpaltenVektor = Felder_SpaltenVektoren(Struct_IN_single, FelderNamen)
            SIZE = cellfun(@(x) size(Struct_IN_single.(x)), FelderNamen, 'UniformOutput', false);
            if flag_als_Zeilenvektor,
                idx_SpaltenVektor = cellfun(@(x) x(1)  > 1 & x(2) == 1, SIZE);
            else
                idx_SpaltenVektor = cellfun(@(x) x(1) == 1 & x(2)  > 1, SIZE);
            end
        end % fucntion
    end
end % function Alle_Felder_als_Spaltenvektoren