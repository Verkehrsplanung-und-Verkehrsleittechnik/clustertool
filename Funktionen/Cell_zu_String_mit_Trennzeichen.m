function String = Cell_zu_String_mit_Trennzeichen(Cell, Trennzeichen)
% Macht aus einer Cell ein String mit einem Trennzeichen dazwischen.
%
% Eingänge:
%   - Cell          - Cell mit Charakter oder Strings. Die Dimension ist egal.
%   - Trennzeichen  - String, mit welchem die Einträge getrennt werden sollen.
%
% % Beispiel:
% Cell = {'Das', 1, 'mit', 'Spalten'; 'ist', 'Test', 2, '.'};
% Trennzeichen = ' ';
% String = Cell_zu_String_mit_Trennzeichen(Cell, Trennzeichen)

if nargin < 1 || ~iscell(Cell),
    error('Fehlerhafter oder nicht vorhanderer Eingang "Cell".')
end

if nargin < 2,
    Trennzeichen = '';
end

% "Trennzeichen" muss ein String sein.
if iscell(Trennzeichen),
    Trennzeichen = Trennzeichen{1};
end
if isnumeric(Trennzeichen),
    Trennzeichen = num2str(Trennzeichen);
end

% Numerische Einträge zu einer String umwandeln:
idx_num = cellfun(@isnumeric, Cell);
if ~isempty(idx_num),
    Cell(idx_num) = cellfun(@num2str, Cell(idx_num), 'UniformOutput', false);
end

Cell_mit_Trennzeichen = cell(1, numel(Cell)*2 - 1); % vordimensionieren


Cell_mit_Trennzeichen(1 : 2 : end) = Cell;
[Cell_mit_Trennzeichen{2 : 2 : end}] = deal(Trennzeichen);

String = [Cell_mit_Trennzeichen{:}];

end % MAIN function