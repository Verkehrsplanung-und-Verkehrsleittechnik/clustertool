function disp_Matrix( Matrix, Spaltenbeschriftung, Zeilenbeschriftung, Position_figure, Titel )
% disp_Matrix( Matrix, Spaltenbeschriftung, Zeilenbeschriftung, Position_figure, Titel ) zeigt eine Matrix in einer Figure.
%
% Zeigt eine Tabelle mit den Daten aus "Matrix".
%
% NEU 30.05.2011: Matrix kann auch ein Struct sein. Dabei müssen alle Felder die gleiche Länge (length) haben. 
% Die Spaltenüberschrift entspricht dabei den Feldern des Structs.
%
% Beispiel:
% Personen.Name = {'A. SoundSo', 'B. Lalala', 'C. TestTestTest'};
% Personen.Alter = [34, 38, 43];
% Personen.Adresse = {'Weg 17, Stuttgart', 'Straßestr. 24, Filderstadt', 'Gasse 5, Bad Cannstatt'};
%
% disp_Matrix(Personen)

    if nargin == 0, error('Matrix muss angegeben werden.'), end
    if isstruct(Matrix),
        % Matrix ist ein Struct:
        
        % Prüfen, ob alle Felder die gleiche Dimension haben:
        Size_Matrix = [structfun(@(x) size(x,1), Matrix), structfun(@(x) size(x,2), Matrix)];
        
        % Prüfen, ob die maximale Dimension überall gleich ist.
        if length(unique(max(Size_Matrix,[],2))) == 1,
            
            % Spaltenüberschriften vordimensionieren:
            dim_min_size = min(Size_Matrix,[],2); 
            Spaltenbeschriftung = cell(1,sum(dim_min_size));
            cum_dim = cumsum(dim_min_size);
            
            % Felder mit unterschiedlicher Orientierung in der Dimension transponieren:
            idx_transponieren = Size_Matrix(:,2) == unique(max(Size_Matrix,[],2));
            
            % Cell Matrix zusammenbauen:
            Felder = fieldnames(Matrix);
            for cnt_F = 1 : length(Felder),
                if idx_transponieren(cnt_F) == true,
                    Matrix.(Felder{cnt_F}) = Matrix.(Felder{cnt_F})';
                end
                % Datenstructur des Feldes:
                if iscell(Matrix.(Felder{cnt_F})),
                    % Cell
                    % kann so bleiben.
                elseif isnumeric(Matrix.(Felder{cnt_F})),
                    % Numerisch
                    % In Cell umwandeln:
                    Matrix.(Felder{cnt_F}) = num2cell(Matrix.(Felder{cnt_F}));
                else
                    % Anderes Format ???
                    error(['Das Format vom Feld',32,Felder{cnt_F},32,'ist weder CELL noch NUM.'])
                end
                
                if cnt_F == 1, cnt = 1; else cnt = cum_dim(cnt_F - 1) + 1; end
                Spaltenbeschriftung(cnt : cum_dim(cnt_F)) = Felder(cnt_F);
                
            end % for cnt_F = 1 : length(Felder),
            
            % Alle Felder zusammen:
            CELL1 = struct2cell(Matrix);
            Matrix = [CELL1{:}];
            
        else
            % Felder haben nicht die selbe Dimension.
            error('Struct kann nicht dargestellt werden. Felder haben unterschiedliche Dimensionen.');
        end %  if length(unique(max(Size_Matrix,[],2))) == 1,
        
        
    end
    
    
    if nargin < 4 || isempty(Position_figure), 
        % Position des Figures:
        Position_figure = [400 200 800 600];
    end
    
    if nargin < 5 || isempty(Titel), 
        % Position des Figures:
        Titel = ['disp_Matrix (Anzahl Zeilen x Spalten:', 32, num2str(size(Matrix,1)),'x',num2str(size(Matrix,2)),')'];
    end
    
    
    h.units = 'pixels';
    h.parent = figure(h,'menubar','none', ...
        'numbertitle','off', ...
        'resize','on', ...
        'handlevisibility','on', ...
        'visible','on', ...
        'Name', Titel, ...
        'Tag', Titel, ...
        'position', Position_figure);
      
    % Tabelle einfügen:
    h_table = uitable;
    % Größe der Tabelle soll immer der Figuregröße entsprechen:
    set(h_table,'Units',     'normalized', ...
                'Position',  [0 0 1 1]     ...
                )
    
    % Falls eingegeben: Beschriftung der Spalten eintragen:
    if exist('Spaltenbeschriftung','var') && ~isempty(Spaltenbeschriftung),
        set(h_table, 'ColumnName', Spaltenbeschriftung);
    end
    
    % Falls eingegeben: Beschriftung der Zeilen eintragen:
    if nargin >= 3 && ~isempty(Zeilenbeschriftung),
        set(h_table, 'RowName', Zeilenbeschriftung);
    end
    
    % Daten eingeben:
    set(h_table, 'Data', Matrix);
    


end

