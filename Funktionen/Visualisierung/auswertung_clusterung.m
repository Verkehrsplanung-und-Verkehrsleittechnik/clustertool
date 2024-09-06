%%
close all
clearvars -except input_table namen_rmq

%% Cluster laden
clusterung = 'Moers_2018_GEH_8_avLinkage';
load(fullfile('Output Clusterung', clusterung + ".mat"));

%% Analyse Cluster
cluster_ind = unique(Clusterung.ClusterIndizes);
cluster_size = zeros(size(cluster_ind));

cluster_data = table();
cluster_data.Idx = cluster_ind;
cluster_data.Anzahl = cluster_size;
cluster_data.Maximum_global = cluster_size;
cluster_data.Spitzenstunde_global = cluster_size;
cluster_data.GEH_max = cluster_size;
cluster_data.Summe_GEH = cluster_size;
cluster_data.mean_GEH = cluster_data.Summe_GEH ./ cluster_data.Anzahl;
cluster_data.Summe_q = cluster_size;
cluster_data.avg_q = cluster_size;
cluster_data.max_q = cluster_size;

cluster_75_perzentil = zeros(size(Clusterung.ClusterLinien));

for k=1:length(namen_rmq)
    col = namen_rmq{k};
    cluster_data.(col) = zeros(length(cluster_ind), 2);
end

% Umrechnung Index zu Stunde
indeces_Stunden = 1:length(Clusterung.ClusterLinien);
Stunden = mod(indeces_Stunden, 24);
Stunden = circshift(Stunden,[0,1]);

for k=1:length(cluster_ind)
    cluster_data.Anzahl(k) = nnz(Clusterung.ClusterIndizes == cluster_ind(k));
    cluster = Clusterung.ClusterLinien(k, :);
    [maximum, index] = max(cluster);
    cluster_data.Maximum_global(k) = maximum;
    
    % Umrechnung Index zu Stunde
    Stunde = Stunden(1,index);
    cluster_data.Spitzenstunde_global(k) = Stunde;
    
    % Kenngrößen Cluster        
    cluster_data.Summe_q(k) = sum(cluster, 'omitnan');
    cluster_data.avg_q(k) = mean(cluster, 'omitnan');
    cluster_data.max_q(k) = max(cluster, [], 'omitnan');
    
    [GEH_Kalendertag, max_GEH_Tag, Summe_GEH] = Kenngroessen_cluster(k, Clusterung);
    cluster_data.Summe_GEH(k) = Summe_GEH;
    cluster_data.GEH_max(k) = max(max_GEH_Tag);
    cluster_75_perzentil(k, :) = get_perzentil(k, Clusterung, 75);

    
        
    % lokale Werte
    for l=1:length(namen_rmq)
        range = (l*24 - 24 + 1) : (l*24);        
        values_rmq = cluster(1,range);
        
        % lokales Maximum
        [maximum_lok, index_lok] = max(values_rmq);
              
        if isnan(maximum_lok)
            % debug
            %                 figure();
            %                 plot(values_rmq);
            disp(namen_rmq(l))
            disp(range)
            maximum_lok = 0;
        end
        
         cluster_data{k, namen_rmq(l)} = [maximum_lok, index_lok-1];
        
    end
    close all

    
end
cluster_data.mean_GEH = cluster_data.Summe_GEH ./ cluster_data.Anzahl;
%% 
%cluster_data = sortrows(cluster_data,'Maximum_global', 'descend');

cluster_data(cluster_data.Anzahl <= 1, :) = [];

figure, scatter(cluster_data.Anzahl, cluster_data.GEH_max,'filled' ), shg
xlabel("Anzahl Tage in Cluster");
ylabel("max(GEH Netzganglinie - Cluster)");
title("Durch Clusterrepräsentation entstehende Abweichungen");

%% Einstellungen Export PP Plot
set(gca,'FontSize',14)
x0=10;
y0=10;
width=1200;
height=500;
set(gcf,'units','points','position',[x0,y0,width,height])

% Abweichungen -> Idee Netzganglinie aus Perzentilen

% Vergleich perzentil original
% perzentil < original???
% in Funktion sind Perzentilwerte > Clusterung

%% identifiziere repräsentatives Cluster
x1 = cluster_data.Summe_q ./ max(cluster_data.Summe_q) * 100 ;
x2 = cluster_data.Maximum_global ./ max(cluster_data.Maximum_global) * 100 ;
%x3 = cluster_data.avg_q ./ max(cluster_data.avg_q) * 100 ; % durch Summe
%berücksichtigt (n ist gleich für alle cluster)
x4 = cluster_data.Anzahl ./ max(cluster_data.Anzahl);
% Term für Fehler durch Cluster?
% Gewichtung Funktion RMQ (HFB, Zu, Ab)

ges = 1 * x1 + 1 * x2  + 1 * x4;
[w_max, idx] = max(ges);

important_cluster = table2array(cluster_data(idx, 1));

%%
% Init table
auswertung_rmqs = table(namen_rmq, 'VariableNames', {'Namen'}, 'RowNames', namen_rmq);
auswertung_rmqs.Anz_Werte = zeros(length(namen_rmq), 1);

%% 50 Stunde
for k=1:length(namen_rmq)
    rmq = namen_rmq{k};
    
    % Zählwerte des RMQ
    tmp = input_table(strcmp(input_table.Name, rmq), :);
    auswertung_rmqs{rmq, 'Anz_Werte'} = nnz(tmp.qKfz_skaliert);
    [wert, uhrzeit, datum] = n_te_Stunde(50, tmp);
    auswertung_rmqs.q_50te_Stunde(k) = wert;
    auswertung_rmqs.h_50_Stunde(k) = uhrzeit;
    auswertung_rmqs.d_50_Stunde(k) = datum;
    
end

%% lokales Maximum Cluster
for k=1:length(namen_rmq)
    rmq = namen_rmq{k};
    range = (k*24 - 24 + 1) : (k*24);
    
    tmp = table2array(cluster_data(cluster_data.Idx == important_cluster, rmq));    
    values_rmq = input_table(strcmp(input_table.Name, rmq), :);
    
    auswertung_rmqs.q_max_cluster(k) = tmp(1,1);
    auswertung_rmqs.h_max_cluster(k) = tmp(1,2);
    try
        auswertung_rmqs.n_max_cluster(k) = get_n(tmp(1,1), values_rmq);
    catch
        auswertung_rmqs.n_max_cluster(k) = NaN;
    end
    
    perzentil = cluster_75_perzentil(important_cluster, range);
    auswertung_rmqs.q_max_cluster_p75(k) = perzentil(tmp(1,2)+1);
    
    try
        auswertung_rmqs.n_max_cluster_p75(k) = get_n(perzentil(tmp(1,2)+1), values_rmq);
    catch
        auswertung_rmqs.n_max_cluster_p75(k) = NaN;
    end
end

%% Wert Spitzenstunde Cluster
Spitzenstunde = table2array(cluster_data(cluster_data.Idx== important_cluster, 'Spitzenstunde_global')); 

for k=1:length(namen_rmq)
    rmq = namen_rmq{k};      
    range = (k*24 - 24 + 1) : (k*24);
    values_rmq = Clusterung.ClusterLinien(important_cluster,range);
    tmp = input_table(strcmp(input_table.Name, rmq), :);
    
    auswertung_rmqs.q_spitzenstunde_cluster(k) = values_rmq(1, Spitzenstunde + 1 );   
    try
        auswertung_rmqs.n_Spitzenstunde(k) = get_n(values_rmq(1, Spitzenstunde + 1 ), tmp);
    catch
        auswertung_rmqs.n_max_cluster(k) = NaN;     
        
    end
    perzentil = cluster_75_perzentil(important_cluster, range);
    auswertung_rmqs.q_spitzenstunde_cluster_p75(k) = perzentil(Spitzenstunde+1);
    try
        auswertung_rmqs.n_Spitzenstunde_p75(k) = get_n(perzentil(Spitzenstunde+1), tmp);
    catch
        auswertung_rmqs.n_max_cluster_p75(k) = NaN;
    end
end

%% Werte ausgewähltes Cluster
auswertung_rmqs.clusterdata = zeros(length(namen_rmq), 24);
for k=1:length(namen_rmq)
    rmq = namen_rmq{k};
    range = (k*24 - 24 + 1) : (k*24);
    
    tmp = Clusterung.ClusterLinien(important_cluster, range);    
    
    auswertung_rmqs.clusterdata(k, :) = tmp;

end

%% Perzentil des Clusters
auswertung_rmqs.perzentil = zeros(length(namen_rmq), 24);
for k=1:length(namen_rmq)
    rmq = namen_rmq{k};
    range = (k*24 - 24 + 1) : (k*24);
    
    perzentil = cluster_75_perzentil(important_cluster, range);
    auswertung_rmqs.perzentil(k, :) = perzentil;
end

%% save results
save(clusterung + "_Clusterindex_" + important_cluster, "cluster_data", "auswertung_rmqs")

%% Plots
%% q
figure()
bar([auswertung_rmqs.q_50te_Stunde, auswertung_rmqs.q_max_cluster, auswertung_rmqs.q_spitzenstunde_cluster], 'grouped')
x = 1:length(namen_rmq);
set(gca, 'XTick',x,  'XTickLabel', strrep(namen_rmq, "_", " "), 'XTickLabelRotation',90)
set(gca,'FontSize',14)
ylabel("Verkehrsstärke [Kfz/h]")
legend(["50. Stunde", "q_{max} Cluster", "q_{Spitzenstunde} Cluster"], 'Location', 'best')
title(strrep(clusterung, "_", " ") + ", Clusterindex: " + important_cluster)
y0=10;
width=1200;
height=500;
set(gcf,'units','points','position',[x0,y0,width,height])
savefig(clusterung + "_Clusterindex_" + important_cluster + ".fig")
saveas(gcf, clusterung + "_Clusterindex_" + important_cluster + ".jpg")

%% q & Perzentil
figure()
bar([auswertung_rmqs.q_50te_Stunde, auswertung_rmqs.q_max_cluster_p75, auswertung_rmqs.q_max_cluster, auswertung_rmqs.q_spitzenstunde_cluster_p75, auswertung_rmqs.q_spitzenstunde_cluster], 'grouped')
x = 1:length(namen_rmq);
set(gca, 'XTick',x,  'XTickLabel', strrep(namen_rmq, "_", " "), 'XTickLabelRotation',90)
set(gca,'FontSize',14)
ylabel("Verkehrsstärke [Kfz/h]")
legend(["50. Stunde", "q_{max} Perzentil","q_{max}", "q_{Spitzenstunde} Perzentil", "q_{Spitzenstunde}"], 'Location', 'best')
title(strrep(clusterung, "_", " ") + ", Clusterindex: " + important_cluster)
y0=10;
width=1200;
height=500;
set(gcf,'units','points','position',[x0,y0,width,height])
savefig(clusterung + "_Clusterindex_" + important_cluster + " p75.fig")
saveas(gcf, clusterung + "_Clusterindex_" + important_cluster + " mit p75.jpg")

%% entsprechender n-ter STunde
figure()
plot(auswertung_rmqs.n_max_cluster, ".-"), hold on
plot(auswertung_rmqs.n_Spitzenstunde, ".-")
yline(50, 'k')
x = 1:length(namen_rmq);
set(gca, 'XTick',x,  'XTickLabel', strrep(namen_rmq, "_", " "), 'XTickLabelRotation',90)
ylabel("entsprechende n. Stunde")
legend(["q_{max} Cluster", "q_{Spitzenstunde} Cluster", '50. Stunde'], 'Location', 'best')
title(strrep(clusterung, "_", " ") + ", Clusterindex: " + important_cluster + " , n. Stunde")
set(gca,'FontSize',14)
y0=10;
width=1200;
height=500;
set(gcf,'units','points','position',[x0,y0,width,height])
savefig(clusterung + "_Clusterindex_" + important_cluster + " , n. Stunde.fig")
saveas(gcf, clusterung + "_Clusterindex_" + important_cluster + " , n. Stunde.fig")

%% entsprechender n-ter STunde Perzentil
figure()
plot(auswertung_rmqs.n_max_cluster_p75, ".-"), hold on
plot(auswertung_rmqs.n_max_cluster),
plot(auswertung_rmqs.n_Spitzenstunde_p75, ".-")
plot(auswertung_rmqs.n_Spitzenstunde),
yline(50, 'r', 'LineWidth', 2), hold on
x = 1:length(namen_rmq);
set(gca, 'XTick',x,  'XTickLabel', strrep(namen_rmq, "_", " "), 'XTickLabelRotation',90)
set(gca,'FontSize',14)
ylabel("entsprechende n. Stunde")
legend(["q_{max} Perzentil","q_{max}", "q_{Spitzenstunde} Perzentil", "q_{Spitzenstunde}"], 'Location', 'best')
title(strrep(clusterung, "_", " ") + ", Clusterindex: " + important_cluster + " , n. Stunde")
y0=10;
width=1200;
height=500;
set(gcf,'units','points','position',[x0,y0,width,height])
savefig(clusterung + "_Clusterindex_" + important_cluster + " , n. Stunde p75.fig")
saveas(gcf, clusterung + "_Clusterindex_" + important_cluster + " , n. Stunde p75.jpg")

%% ausgewähltes Cluster
%% Plot Netzganglinie
figure
plot(Clusterung.ClusterLinien(important_cluster, :), 'LineWidth',7, 'Color', [0.0627450980392157,0.474509803921569,0.0627450980392157]), hold on
shg

for k=1:length(namen_rmq)
    rmq = namen_rmq{k};      
    range = (k*24 - 24 + 1) : (k*24);
    xline(range(1) + Spitzenstunde, '--', 'LineWidth', 1.5)
    xline(range(auswertung_rmqs{rmq, 'h_max_cluster'} + 1), 'r-.', 'LineWidth', 1.5)
    
end

xlim([0, inf])
ylim([0, inf])
set(gca,'FontSize',14)
ylabel('Verkehrsstärke [Kfz/h]', 'FontSize', 18)
xlabel('Zählintervallnummer der Natzganglinie (24h * Anzahl RMQs)', 'FontSize', 18)
title("globale Spitzenstunde: " + num2str(Spitzenstunde -1) + '-' + num2str(Spitzenstunde) + ' Uhr', 'FontSize', 20) 

x0=10;
y0=10;
width=1200;
height=500;
set(gcf,'units','points','position',[x0,y0,width,height])

%% Dauerlinien
%plot_dauerlinien(namen_rmq, input_table)

%% Plausibilisierung / Test
for k=1:height(input_table)
    name = input_table.Name(k);
    name = name{1,1};

    datum =  input_table.Datum(k);
    datum = datum{1,1};
    
    h = input_table.Uhrzeit(k);
    h = h{1,1};
    h = str2num(h(1:2));
    
    r = find(strcmp(namen_rmq, name));
    
    if ~isempty(r)
        range = (r*24 - 24 + 1) : (r*24);
        datum_mat = datenum(datum, 'dd.mm.yyyy');
        
        wert_original = input_table.qKfz_skaliert(k);
        %wert_original = wert_original{1,1};
        
        mat_data = Clusterung.ClusterData;
        wert_netzganglinie = mat_data(mat_data(:,1) == datum_mat, 2:end);
        if isempty(wert_netzganglinie)
            continue
        end
        
        wert_rmq = wert_netzganglinie(range);
        
        if wert_rmq(h + 1) ~= wert_original && ~(isnan( wert_rmq(h + 1)) && isnan( wert_original))
            if wert_original == 0 && isnan(wert_rmq(h + 1))
                continue
            end
            errordlg(' :( ')
            error('Inkonsistenz nach Datentransformation')
        end
    end
end

%% Funktionen
function [wert, uhrzeit, datum] = n_te_Stunde(n, table_rmq_data)
% ersetze NaN mit 0
table_rmq_data.qKfz_skaliert(isnan(table_rmq_data.qKfz_skaliert)) = 0;
table_rmq_data = sortrows(table_rmq_data, "qKfz_skaliert", "descend");

wert = table_rmq_data.qKfz_skaliert(n);
uhrzeit = table_rmq_data.Uhrzeit(n);
uhrzeit = str2num(uhrzeit{1,1}(1:2));
datum = table_rmq_data.Datum(n);
end

function n = get_n(q, table_rmq_data)
    % ersetze NaN mit 0
    table_rmq_data.qKfz_skaliert(isnan(table_rmq_data.qKfz_skaliert)) = 0;
    table_rmq_data = sortrows(table_rmq_data, "qKfz_skaliert", "descend");
    n = find(table_rmq_data.qKfz_skaliert < q, 1);
    if n == []
        n = NaN;
    end
end

function [] = plot_dauerlinien(rmqs, data)
% ersetze NaN mit 0
data.qKfz_skaliert(isnan(data.qKfz_skaliert)) = 0;
    for k=1:length(rmqs)
        tmp = data(strcmp(data.Name, rmqs(k)), :);
        tmp = sortrows(tmp, "qKfz_skaliert", "descend");
        figure()
        semilogx(1:length(tmp.qKfz_skaliert), tmp.qKfz_skaliert)
        title(strrep(rmqs(k), "_" , " "))
        ylabel("Verkehrsstärke [Kfz/h]")
        savefig("Dauerlinie_" + rmqs(k) + ".fig")
        saveas(gcf, "Dauerlinie_" + rmqs(k) + ".jpg")
        close
    end
end

function [GEH_Kalendertag, max_GEH_Tag, Summe_GEH] = Kenngroessen_cluster(clusterindex, Clusterung)
    
    % Import der Netzganglinien, die durch das Cluster repräsentiert werden
    values_clustered = Clusterung.ClusterLinien(clusterindex, :);
    cluster_data = Clusterung.ClusterData(Clusterung.ClusterIndizes == clusterindex, 2:end);
    
    % Check Import
    dim = size(cluster_data);
    if dim(1) ~= Clusterung.ClusterEigenschaften.AnzahlTage(clusterindex)
        errordlg("Azahl Tage im Cluster ist falsch")
    end
        
   [GEH_Kalendertag, max_GEH_Tag, Summe_GEH] = GEH_mod(values_clustered, cluster_data);
end

function [GEH_Kalendertag, max_GEH_Tag, Summe_GEH]=GEH_mod(Vec,Mat)
    % entspricht GEH.m mit erweiterten Rückgabewerten
    
    % GEH(Vec, Mat) ist identisch zu ctranspose(GEH(Mat, Vec)) !!!
    % Da die einzelnen Zeilen von Vec in einer for-Schleife abgearbeitet werden, ist es besser, wenn Vec, weniger Zeilen hat als Mat.
    % Ist dies nicht der Fall (d.h. size(Vec,1) > size(Mat,1)), werden die beiden Variablen vertauscht und am Ende das Ergebnis transponiert.
    % So arbeitet die Funktion in diesem Fall schneller.
    if size(Vec,1) > size(Mat,1),
        flag_tauschen = true;
        Mat2 = Mat;
        Mat = Vec; Vec = Mat2;
    else
        flag_tauschen = false;
    end

    % um ein Divide-By-Zero zu vermeiden, wird ein kleines bisschen d.h. 1e-308 dazugezählt
    Vec=Vec+1e-308;
    
    [GEH_Kalendertag, max_GEH_Tag, Summe_GEH]= GEHFcn(Vec, Mat);
                            
    % alle die keinen GEH bekommen haben, bekommen den doppelten Max-Wert
    GEH_Kalendertag(isnan(GEH_Kalendertag))=2*max(max(GEH_Kalendertag)); 

    if flag_tauschen,
        % Wenn die Eingänge getauscht wurden, muss das Ergebnis transponiert werden.
        GEH_Kalendertag = GEH_Kalendertag';
    end
end

function [mean_GEH, max_GEH_y, sum_GEH] = GEHFcn(VecFcn, Mat)
    % Start(Fehl)wert setzen
    allGEHis=-ones(size(Mat));

    % Bestimmen wo beide Objekte Zahlen enthalten
    NoNaNs=bsxfun(@and,~isnan(VecFcn),~isnan(Mat));

    % Das Vergleichsobjekt(Vec) auf die Größe aller Objekte(Mat) hochskalieren
    VecFcn=repmat(VecFcn,size(Mat,1),1);

    % den GEH zwischen allen Wertepaaren, die nicht NaN sind berechnen
    allGEHis(NoNaNs)=(2*((VecFcn(NoNaNs)-Mat(NoNaNs)).^2)./(VecFcn(NoNaNs)+Mat(NoNaNs))).^0.5;
    
    % GEH für NaN temporär auf 0 setzen
    allGEHis(~NoNaNs) = 0;

    % den Mittelwert aller Nicht-NaNs berechnen und dabei den -1 Start(Fehl)wert rausrechnen
    mean_GEH =(sum(allGEHis,2)+sum(~NoNaNs,2))./(size(Mat,2)-sum(~NoNaNs,2));
    max_GEH_y = max(allGEHis, [], 2);
    sum_GEH = sum(sum(allGEHis));
end

function vec_perzentil = get_perzentil(clusterindex, Clusterung, p)    
    % Import der Netzganglinien, die durch das Cluster repräsentiert werden
    values_clustered = Clusterung.ClusterLinien(clusterindex, :);
    cluster_data = Clusterung.ClusterData(Clusterung.ClusterIndizes == clusterindex, 2:end);
    
    % Check Import
    dim = size(cluster_data);
    if dim(1) ~= Clusterung.ClusterEigenschaften.AnzahlTage(clusterindex)
        errordlg("Azahl Tage im Cluster ist falsch")
    end
        
    vec_perzentil = prctile(cluster_data, p, 1);
    % Achtung: Perzentilwerte bei prctile() sind interpoliert in
    % wertespanne, also keine realen Zählwerte
    
    if sum(isnan(vec_perzentil)) > 0
        x = find(isnan(vec_perzentil));
        debug = cluster_data(:, x);
    end
end

