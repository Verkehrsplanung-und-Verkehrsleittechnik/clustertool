function ALLE_Ferien_Speichen
% Speichert alle Ferien in einer mat-Datei:

%                                         BW = Baden-Württemberg
%                                         BY = Bayern
%                                         BE = Berlin
%                                         BB = Brandenburg
%                                         HB = Bremen
%                                         HH = Hamburg
%                                         HE = Hessen
%                                         MV = Mecklenburg-Vorpommern
%                                         NI = Niedersachsen
%                                         NW = Nordrhein-Westfalen
%                                         RP = Rheinland-Pfalz
%                                         SL = Saarland
%                                         SN = Sachsen
%                                         ST = Sachsen-Anhalt
%                                         SH = Schleswig-Holstein
%                                         TH = Thüringen

flag_ferien_additiv_speichern = true;

Bundeslaender = {'BW', 'BY', 'BE', 'BB', 'HB', 'HH', 'HE', 'MV', 'NI', 'NW', 'RP', 'SL', 'SN', 'ST', 'SH', 'TH' };

Von_Tag = datenum('01.01.2015', 'dd.mm.yyyy');
Bis_Tag = datenum('31.12.2016', 'dd.mm.yyyy');

Tage = Von_Tag : Bis_Tag;
flag_Ferien_anzeigen = false;
flag_alle_Ferien_speichern = false;
force_reload = true;

Schulferien_saved = cell(length(Tage) + 1, length(Bundeslaender) + 1); % vordimensionieren
for cnt_BL = 1 : length(Bundeslaender),
    Bundesland = Bundeslaender{cnt_BL};
    [idx_Ferien, Ferien_Name] = Schulferien(Tage, Bundesland, flag_Ferien_anzeigen, flag_alle_Ferien_speichern, force_reload);
    
    Schulferien_saved{1,     cnt_BL + 1} = Bundesland;
    Schulferien_saved(2:end, cnt_BL + 1) = Ferien_Name;
end

% Tage eintragen:
Schulferien_saved(2:end, 1) = num2cell(Tage)';

if flag_ferien_additiv_speichern
    Schulferien_saved_20152016 = load('Schulferien_saved.mat');
    Schulferien_saved_20152016.Datum = [Schulferien_saved_20152016.Datum;Tage'];
    
    Namen_Ferien = Schulferien_saved(2:end,2:end);
    einzelne_Ferien = unique(Namen_Ferien(cellfun(@any, Namen_Ferien)));
    
    for cnt_BL = 1: length(Bundeslaender)
        Bundesland = Bundeslaender{cnt_BL};
        spalte_BL = find(ismember(Bundesland, Schulferien_saved(1,2:end)));
        Ferien_akt_BL = Schulferien_saved(2:end, spalte_BL + 1);
        idx_Ferien = cellfun(@any, Ferien_akt_BL);
        
        [~, hallo(idx_Ferien)] = ismember(Ferien_akt_BL(idx_Ferien), einzelne_Ferien);
        Schulferien_saved_20152016.(Bundesland) = [Schulferien_saved_20152016.(Bundesland);hallo'];
    end
    
    save Schulferien_saved2015_2016 Schulferien_saved_20152016
else
    % Cell umformatieren, als Struct:
    Schulferien_saved_Cell = Schulferien_saved;
    Namen_Ferien = Schulferien_saved_Cell(2:end,2:end);
    einzelne_Ferien = unique(Namen_Ferien(cellfun(@any, Namen_Ferien)));
    Schulferien_saved = struct();
    Schulferien_saved.FerienName = einzelne_Ferien;
    Schulferien_saved.Datum = cell2mat(Schulferien_saved_Cell(2:end, 1));
    Schulferien_saved.Hilfe = ['Für jedes Bundesland gibt es ein Unterfeld. Das Feld ist numerisch. Eine 0 bedeutet, dass keine Schulferien sind.',char(10), ...
        'Die unterschiedlichen Nummern geben die verschiedenen Ferien zurück. Die Zuordnung der Nummern zu den Ferien erfolgt über Schulferien_saved.FerienName.',char(10), ...
        'Die Nummer 3 bedeutet z.B., dass die Ferien: Schulferien_saved.FerienName{3} sind.'];
    for cnt_BL = 1 : length(Bundeslaender),
        Bundesland = Bundeslaender{cnt_BL};
        spalte_BL = find(ismember(Bundesland, Schulferien_saved_Cell(1,2:end)));
        Ferien_akt_BL = Schulferien_saved_Cell(2:end, spalte_BL + 1);
        idx_Ferien = cellfun(@any, Ferien_akt_BL);
        Schulferien_saved.(Bundesland) = zeros(size(Schulferien_saved.Datum)); % vordimensionieren mit "keine Ferien".
        [~, Schulferien_saved.(Bundesland)(idx_Ferien)] = ismember(Ferien_akt_BL(idx_Ferien), Schulferien_saved.FerienName);
    end
    
    save Schulferien_saved -struct Schulferien_saved
end
end % function
