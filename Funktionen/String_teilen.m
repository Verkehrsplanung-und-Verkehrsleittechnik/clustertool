function [ Strings ] = String_teilen( String, Trennzeichen, flag_leere_Eintraege_loeschen )
%Teile einen Sting nach dem Trennzeichen
%
% Beispiel:
%name='Mainz-Hechtsheim-Ost';
%Sting_teilen( name, '-' );
%Ergebnis:
% {'Mainz','Hechtsheim','Ost'}
%
%
% Es können auch mehrere Trennzeichen eingegeben werden z.B.
% Trennzeichen={' ','-','/','(',')'};
% Es wird nicht jedes Trennzeichen seperate geprüft sondern die
% Trennzeichen werden mit ODER verknüpft.
%
% Werden als Trennzeichen Absatzzeichen verwendet {char(13),char(10)}, ist es sinnvoll das "flag_leere_Eintraege_loeschen" auf true zu setzten, da damit
% Leere Absätze entfernt werden.

welche_variante = 2;
% 1: ist eine neuere Variante.
% 2: die alte.

if nargin < 2 || isempty(Trennzeichen),                     Trennzeichen                  = {',',';','|'};  end
if nargin < 3 || isempty(flag_leere_Eintraege_loeschen),    flag_leere_Eintraege_loeschen = false;          end


switch welche_variante
    
    case 1,
        %% Neue Variante
        
        % Trennzeichen zusammenpacken in die Form, die regexp braucht:
        if ischar(Trennzeichen),
            Trennzeichen = ['[',Trennzeichen,']'];
        else
            Trennzeichen = ['[',Trennzeichen{:},']'];
        end
        
        Strings = regexp(String, Trennzeichen, 'split');
        
        % Leere Einträge löschen:
        if flag_leere_Eintraege_loeschen
            if iscell(String),
                for cnt_S = 1 : length(Strings),
                    Strings{cnt_S}(cellfun(@isempty, Strings{cnt_S})) = [];
                end
            else
                Strings(cellfun(@isempty, Strings)) = [];
            end
        end
        
    case 2,
        %% Alte Variante
        
        
         if ischar(Trennzeichen) || length(Trennzeichen) == 1,
            %% Neue Variante:
            
            % Trennzeichen richtig formatieren für regexp:
            if iscell(Trennzeichen),
                Trennzeichen = Trennzeichen{1};
            end
            Trennzeichen = ['\',Trennzeichen]; % Bei regexp muss ein '\' vorangestellt werden.
            
            Strings = regexp(String, Trennzeichen, 'split');
            
        else
            
            if ~iscell(Trennzeichen),
                Trennzeichen={Trennzeichen};
            end
            
            % Wenn String ein Cell ist:
            if ~iscell(String),
                String = {String};
            end
            
            % Den Trennzeichen ein '\' vorstellen:
            %Trennzeichen = cellfun(@(x) ['\',x], Trennzeichen, 'UniformOutput', false);
            
            %suche nach dem Trennzeichen, sortiere die gefundenen Zeilen:
            %String_an_Stelle = cell2mat(regexp(String, Trennzeichen));
            String_an_Stelle = cellfun(@(x) sort(cell2mat(regexp(x, Trennzeichen))), String, 'UniformOutput', false);
            
            Strings = cell(size(String)); %vordimensionieren
            
            for cnt_S = 1 : numel(String_an_Stelle),
                if any(String_an_Stelle{cnt_S}), %wird nur durchlaufen, wenn der String auftaucht.
                    %cell vordimensionieren:
                    Strings{cnt_S} = cell(1,length(String_an_Stelle{cnt_S})+1);
                    
                    Strings{cnt_S}{1} = String{cnt_S}(1:String_an_Stelle{cnt_S}(1)-1);
                    for cnt_Anzahl_Stellen = 2 : length(String_an_Stelle{cnt_S}),
                        Strings{cnt_S}{cnt_Anzahl_Stellen} = String{cnt_S}(String_an_Stelle{cnt_S}(cnt_Anzahl_Stellen-1)+1:String_an_Stelle{cnt_S}(cnt_Anzahl_Stellen)-1);
                    end
                    Strings{cnt_S}{end} = String{cnt_S}(String_an_Stelle{cnt_S}(end)+1 : length(String{cnt_S}));
                    
                    % leere Ergebnisse (z.B. wenn das Trennzeichen am Anfang und/oder Ende auftritt oder
                    % Trennzeichen direkt nacheinander auftreten), werden gelöscht.
                    Strings{cnt_S}(cellfun(@isempty,Strings{1})) = [];
                else
                    %disp('Trennzeichen nicht gefunden.')
                    Strings{cnt_S}={String{cnt_S}};
                end
            end
            
        end
        
end
if numel(Strings) == 1,
    % Ausgabe nicht als Untercell:
    Strings = Strings{1};
end

