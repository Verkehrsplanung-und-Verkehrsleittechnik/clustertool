function Feldname = Struct_Feldname_richtig(Sting_IN)
% Felder von Structs haben in Matlab bestimmte Anforderungen:
%  - Es dürfen nur Buchstaben (a...z, A...Z und Zahlen 0...9 und ein Unterstrich '_') vorkommen.
%  - Der Name darf nicht mit einer Zahl und dem Unterstrich beginnen.
%   (siehe dazu den Test).
%
% % Beispiel: 
% Sting_IN = '123_Täxt';
% Feldname = Struct_Feldname_richtig(Sting_IN)
%
% % Beispiel #2:
% Sting_IN = {'__ÖÖÖÜÜÜ', 'ßßß', 'Test', 'bla_bla'};
% Feldname = Struct_Feldname_richtig(Sting_IN)



% char(65:90)  => ABCDEFGHIJKLMNOPQRSTUVWXYZ
% char(97:122) => abcdefghijklmnopqrstuvwxyz
% char(48:57)  => 0123456789
% char(95)     => _

%% Falls Sting_IN eine Cell ist muss es mit jedem Element der Cell gemacht werden:
if iscell(Sting_IN),
    Feldname = cell( size(Sting_IN) ); % vordimensionieren
    for cnt_S = 1 : numel(Feldname),
        Feldname{cnt_S} = Struct_Feldname_richtig( Sting_IN{cnt_S} );
    end
    return % Ende der Funktion bei "if iscell(Sting_IN),"
end


Feldname = Sting_IN;

%% Bekannte nicht erlaubte Zeichen ersetzten:
nicht_erlaubte_Zeichen = { 'ä',  'ö',  'ü',  'Ä',  'Ö',  'Ü',  'ß', ' '};
Zeichen_ersetzten      = {'ae', 'oe', 'ue', 'Ae', 'Oe', 'Ue', 'ss', '_'};
for cnt_Z = 1 : length(nicht_erlaubte_Zeichen),
    Feldname = strrep(Feldname, nicht_erlaubte_Zeichen{cnt_Z}, Zeichen_ersetzten{cnt_Z});
end

%% ALLE anderen nicht erlaubten Zeichen werden mit einem Zeichen ersetzt:
Zeichen_ersetzten = ''; % '' => das Zeichen wird gelöscht

Alle_erlaubten_char         = [48:57, 65:90, 95, 97:122];
idx_Pos_nicht_erlaubt = ~ismember(Feldname, char(Alle_erlaubten_char));
if length(Zeichen_ersetzten) == 0,
    Feldname(idx_Pos_nicht_erlaubt) = [];
elseif length(Zeichen_ersetzten) < 1,
    Feldname(idx_Pos_nicht_erlaubt) = Zeichen_ersetzten;
else
    % Zeichen hat ein Länge > 1
    error('Under Construction')
end

%% Prüfen, ob Pos1 ein unerlaubtes Zeichen enthält (kann hier eigentlich nur noch eine Zahl oder Unterstrich sein):
Zeichen_Position_1 = 'o_'; % Diese Zeichen wird vorne dran gehängt, wenn der "Feldname" mit einem unerlaubten Zeichen beginnt.
Alle_erlaubten_char_an_Pos1 = [65:90, 97:122];
idx_Pos1_nicht_erlaubt = ~ismember(Feldname(1), char(Alle_erlaubten_char_an_Pos1));
if idx_Pos1_nicht_erlaubt,
    Feldname = [Zeichen_Position_1, Feldname];
end










%% Test, welche Zeichen erlaubt sind:
flag_run_test_alle_erlaubten_char = false;
if flag_run_test_alle_erlaubten_char,
    Char_Nr = 1 : 2000;
    Char_erlaubt_Pos_egal           = []; cntE  = 0;
    Char_nicht_erlaubt_Pos_egal     = []; cntNE = 0;
    for cnt_Char = 1 : length(Char_Nr),
        akt_char = Char_Nr(cnt_Char);
        Feld = ['A',char(akt_char)];
        try
            A.(Feld) = 1; 
            cntE = cntE + 1;
            Char_erlaubt_Pos_egal(cntE) = akt_char;
        catch
            cntNE = cntNE + 1;
            Char_nicht_erlaubt_Pos_egal(cntNE) = akt_char;
        end
    end
    disp('Folgende Zeichen sind als Feldname erlaubt:')
    disp(char(Char_erlaubt_Pos_egal))

    
    
    Char_erlaubt_Pos_1      = []; cntE  = 0;
    Char_nicht_erlaubt_1    = []; cntNE = 0;
    for cnt_Char = 1 : length(Char_Nr),
        akt_char = Char_Nr(cnt_Char);
        Feld = [char(akt_char),'A'];
        try
            A.(Feld) = 1; 
            cntE = cntE + 1;
            Char_erlaubt_Pos_1(cntE) = akt_char;
        catch
            cntNE = cntNE + 1;
            Char_nicht_erlaubt_1(cntNE) = akt_char;
        end
    end
    disp('Mit folgenden Zeichen darf der Feldname beginnen:')
    disp(char(Char_erlaubt_Pos_1))

    
end






end % MAIN function
