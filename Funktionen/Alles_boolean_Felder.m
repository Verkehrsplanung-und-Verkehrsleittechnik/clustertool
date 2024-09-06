function Eigenschaften = Alles_boolean_Felder(Eigenschaften)

if nargin < 1 || ~isstruct(Eigenschaften),
    % warning('Keine Eigenschaften vorhanden.')
    Eigenschaften = struct();
end

Zusatz_Name = '_dummy345';
alle_Felder = fieldnames(Eigenschaften);
for cnt_F2 = 1 : length(alle_Felder),
    akt_Feld = alle_Felder{cnt_F2};
    % Unter Eigenschaften kann sich wiederum eine neue Struct befinden, diese müssen verändert werden:
    if isstruct(Eigenschaften.(akt_Feld)),
        Sub_Felder = fieldnames(Eigenschaften.(akt_Feld));
        for cnt_SF = 1 : length(Sub_Felder),
            Zusatz = '';
            if isequal(Sub_Felder{cnt_SF}, akt_Feld),
                Zusatz = Zusatz_Name; % Wenn die Felder gleich heißen musst erst ein dummy eingebaut werden, damit das Feld nicht überschrieben wird (und auch hinterher nicht gelöscht wird)
            end
            Eigenschaften.([Sub_Felder{cnt_SF},Zusatz]) = Eigenschaften.(akt_Feld).(Sub_Felder{cnt_SF});
        end
        Eigenschaften = rmfield(Eigenschaften, akt_Feld); % Das Hauptfeld löschen.
    end
end
% Die Felder mit _dummy wieder ändern:
alle_Felder = fieldnames(Eigenschaften);
idx_Zusatz = cellfun(@(x) any(strfind(x, Zusatz_Name)), alle_Felder);
if any(idx_Zusatz)
    Felder_mit_Zusatz = alle_Felder(idx_Zusatz);
    FeldName_ohne_Zusatz = cellfun(@(x) strrep(x, Zusatz_Name, ''), Felder_mit_Zusatz, 'UniformOutput', false);
    for cnt_F2 = 1 : length(Felder_mit_Zusatz),
        Eigenschaften.(FeldName_ohne_Zusatz{cnt_F2}) = Eigenschaften.(Felder_mit_Zusatz{cnt_F2});
        Eigenschaften = rmfield(Eigenschaften, Felder_mit_Zusatz{cnt_F2}); % Altes Feld mit "Zusatz_Name" löschen.
    end
    
end
end % function Eigenschaften = Alles_boolean_Felder(Eigenschaften)