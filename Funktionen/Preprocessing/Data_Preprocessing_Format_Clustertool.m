function [] = Data_Preprocessing_Format_Clustertool(name_input, namen_rmq, spalte_q, flag_check)
%Aufbereitung Format Clustertool
%   Lädt Daten und exportiert die gewünschten RMQs als Netzganglinie
%   Annahme: Starttag startet bei Stunde 0, Endtag bei 23
%   Falls Zeitstempel fehlen, werden diese hinzugefügt (Zählwert NaN)


input_table = readtable(fullfile('Rohdaten', name_input));
input_table.Datum_mat = datetime(input_table.Datum, 'InputFormat', 'dd.MM.yyyy') + duration(input_table.Uhrzeit);

% Kanvertierung in timetable
input_table = table2timetable(input_table, 'RowTimes', 'Datum_mat');

%% Preallocation

time_start = min(input_table.Datum_mat);
time_ende = max(input_table.Datum_mat);
Diff = diff([time_start, time_ende]);
Anz_Reihen = ceil(days(Diff));

% 
dates = [time_start:time_ende]';
zeitstempel = (time_start:hours:time_ende)';
dates.Format = 'dd.MM.yyyy';
column = zeros(Anz_Reihen,24);

data_netzganglinie = table(dates, 'VariableNames', {'Datum'});

for k=1:length(namen_rmq)
    % Setze Spaltennamen zu Namen des RMQs. Jede Spalte bekommt Einträge vom
    % Typ 1 x 24 array/table
    data_netzganglinie = addvars(data_netzganglinie, column, 'NewVariableNames', namen_rmq{k});
end

% Umwandlung in timetable
data_netzganglinie = table2timetable(data_netzganglinie, 'RowTimes', 'Datum');


%% Zuordnen der Werte in der Netzganglinie
for k=1:length(namen_rmq)
   rmq = namen_rmq{k};
   data = input_table(strcmp(input_table.Name, rmq),spalte_q );
   data = sortrows(data, 'Datum_mat'); 
   
   % Falls kein Datensatz für eine STudne existiert, wird dieser eingefügt
   data = retime(data, zeitstempel);
   
   if height(data) < Anz_Reihen*24
       % Sollte nicht passieren
       errordlg('Achtung. Daten sind unvollständig. Fall ist nicht implementiert.')
       error('Achtung. Daten sind unvollständig. Fall ist nicht implementiert.')

   end 
   
   mat = reshape(data{:, spalte_q}, 24, [])';
   
   % Ersetze 0 mit NaN
   % Annahme: innerhalb einer Stunde mindestens ein Kfz bei funktioneirendem Detektor
   mat(mat == 0) = NaN;
   data_netzganglinie{:, rmq} = mat;
   
end

%% Validierung
if flag_check
    % Vergleiche jeden Eintrag der Input Tabelle mit dem entsprechenden in der Netzganglinie -> sehr langsam
    for k=1:height(input_table)

        % Infos des Datensatzes
        name = input_table.Name{k};
        datum =  input_table.Datum{k};
        h = input_table.Uhrzeit{k};
        h = str2num(h(1:2));

        % Index RMQ
        r = find(strcmp(namen_rmq, name));

        if ~isempty(r)
            %datum_mat = datenum(datum, 'dd.mm.yyyy');

            wert_original = input_table{k, spalte_q};
            %wert_original = wert_original{1,1};

            wert_rmq = data_netzganglinie{datum, name};

            if isempty(wert_rmq)
                continue
            end

            if wert_rmq(h + 1) ~= wert_original && ~(isnan( wert_rmq(h + 1)) && isnan( wert_original))
                if wert_original == 0 && isnan(wert_rmq(h + 1))
                    continue
                end
                errordlg(' :( ')
                error('Inkonsistenz nach Datentransformation')
            end
        end

    end
end


%% Speichern
% Umwandeln in table um Datumsspalte zu berücksichtigen
data_netzganglinie = timetable2table(data_netzganglinie);

plot_netzganglinie(128, namen_rmq, data_netzganglinie)
save( fullfile('Input Clusterung', replace(name_input, [".xlsx", ".csv"], ".mat")), "data_netzganglinie")

end % end main

function [] = plot_netzganglinie(index, namen_rmq, data_netzganglinie)
%% Plot Netzganglinie
single_netzganglinie = table2array(data_netzganglinie(index,2:end));


figure
plot(single_netzganglinie, 'LineWidth',3), hold on
shg

for k=1:length(namen_rmq) 
    range = (k*24 - 24 + 1) : (k*24);
    xline(range(end), '--', 'LineWidth', 2)    
end

xlim([0, inf])
ylim([0, inf])
set(gca,'FontSize',14)
ylabel('Verkehrsstärke [Kfz/h]', 'FontSize', 18)
xlabel('Zählintervallnummer der Natzganglinie (24h * Anzahl RMQs)', 'FontSize', 18)

x0=10;
y0=10;
width=1200;
height=500;
set(gcf,'units','points','position',[x0,y0,width,height])
end

