function [fh] = plot_clusterung_scalar_values(clusterobject, rmq,knoten_id, tageszeit, jahr, q_b, param)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
        
        % Settings
        font_size = 24;
        font_name ="Arial";
        
        legend_size = 18;
        axis_font_size = 18;

        fh = figure();
        fh.WindowState = 'maximized';
        set(groot, 'DefaultTextInterpreter', 'none')
        %set(groot, 'DefaultAxisFontSize', 24)
        sgtitle({join(['RMQ: ', rmq,', Anlage: ', knoten_id ,...
                        ', Jahr: ', num2str(jahr), ', Spitzenstunde: ', ...
                        tageszeit]),...
                        join(['Clusterung: ', param.Methode, ', Abstandsmass: ',...
                        param.Distanzfunktion," " ,num2str(param.CutOff)])},...
                 "FontSize", font_size, 'FontName', font_name)
        axEigenschaften = subplot(2,2,[1,3]);
        % Balkendiagramm Cluster/Anzahl Tage mit eingefärbter Eigenschaft
        clusterobject.DrawEigenschaft(axEigenschaften, 'Wochentag')

        % Diagramm Cluster
        farben = clusterobject.KalenderClusterung.TagTypen.color(2:end, :);
        farben_tag = [arrayfun(@(x) farben(x,1) ,clusterobject.ClusterIndizes), ...
                        arrayfun(@(x) farben(x,2) ,clusterobject.ClusterIndizes),...
                        arrayfun(@(x) farben(x,3) ,clusterobject.ClusterIndizes)];

         
        Anzahl_im_Cluster = hist(clusterobject.ClusterIndizes, clusterobject.ClusterIndexLookup(:,1));
        liniendicke = max(75 * Anzahl_im_Cluster / max(Anzahl_im_Cluster), 20);
        anz_cluster = size(clusterobject.ClusterLinien,1);

        axMainLines = subplot(2,2,2);
        scatter(ones(anz_cluster, 1), clusterobject.ClusterLinien, liniendicke, farben, 'filled');
        ylabel("q [Fzg/h]")

        text(ones(anz_cluster, 1)+ 0.2, clusterobject.ClusterLinien, "ClusterNr " + string(clusterobject.ClusterIndexLookup(:,1)),...
            'FontSize', legend_size, 'FontName', font_name);
%         xlim([0.8, 1.5])
        axMainLines.XAxis.Visible = 'off'; % remove x-axis

        axSingleLines = subplot(2,2,4); 
        % Diagramm alle
        scatter(datetime(clusterobject.ClusterData(:,1), 'ConvertFrom','datenum'),...
                clusterobject.ClusterData(:,2), 25, ...
                farben_tag, 'filled'), hold on
            
        % added Linie mit Bemessungsverkehrsstärke
        hline = refline(axMainLines, [0, q_b]);
        hline.Color = 'black';
        hline.DisplayName = "Bemessungsverkehrsstärke";
        plot(axSingleLines, q_b * ones(size(clusterobject.ClusterData(:,1))), 'black', 'DisplayName', 'Bemessungsverkehrsstärke')
        ylabel("q [Fzg/h]")
        
        x_lim = get(axMainLines, 'XLim'); 
        text(axMainLines,x_lim(1), q_b + 100, "Bemessungsverkehrsstärke", 'FontSize', axis_font_size - 2, 'FontName', font_name);
        x_lim = get(axSingleLines, 'XLim'); 
        text(axSingleLines,x_lim(1), q_b + 100, "Bemessungsverkehrsstärke", 'FontSize', axis_font_size - 2, 'FontName', font_name);
        
        % Formatierung
        set(axEigenschaften, 'FontSize', axis_font_size, 'FontName', font_name)
        set(axMainLines, 'FontSize', axis_font_size, 'FontName', font_name)
        set(axSingleLines, 'FontSize', axis_font_size, 'FontName', font_name)
        set(axSingleLines, 'Position', [.1 .1 .4 .4]);
                
end

