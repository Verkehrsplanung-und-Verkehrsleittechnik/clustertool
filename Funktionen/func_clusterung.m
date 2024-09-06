
function [clusterobject] = func_clusterung(Import_Datei, param)

%% Import Daten

% Importieren der Clusterdaten
MyDisp('Clusterung wird angelegt')
[Daten, ~] = Daten_Importieren(Import_Datei);

% Initialisieren
struct_Eigenschaften = struct();
zusatz = [];

% Importieren der zusätzlichen Eigenschaften
if ~isempty(Eigenschaften_Datei)    
[Daten_Eigenschaften, ~] = Eigenschaften_Importieren(Dateiname);
struct_Eigenschaften.Bezeichnung_Eigenschaft = Daten_Eigenschaften;
end
%% Clusterung


% Erstellen einer Instanz des Typs Clusterung
clusterobject = class_Clusterung(Daten, param, struct_Eigenschaften, zusatz);

% Clustern
clusterobject.Clustern()

% ToDo SAve

%% Visualisierung
if visuallize
    figure
    axEigenschaften = subplot(1,1,1);
    % Balkendiagramm Cluster/Anzahl Tage mit eingefärbter Eigenschaft
    clusterobject.DrawEigenschaft(axEigenschaften, 'Wochentag')
    % Diagramm Cluster
    figure
    axMainLines = subplot(2,1,1);
    axSingleLines = subplot(2,1,2);
    clusterobject.DrawCluster(axMainLines, clusterobject.KalenderClusterung.TagTypen.Nr(2:end), [], true, false);
    % Diagramm einzelner Tagesobjekte
    clusterobject.DrawCluster(axSingleLines, clusterobject.KalenderClusterung.TagTypen.Nr(2:end), [], false, true);

    % Legends der Clusterlinien-Axes löschen (diese sind i.A. zu viele)
    legend(axMainLines,'off')
    legend(axSingleLines,'off')
    % Achsenlabels ggfs. wieder aktivieren
    set(axEigenschaften,'XTickMode','auto','XTickLabelMode','auto')
    set(axMainLines,'XTick',[],'YTickMode','auto','YTickLabelMode','auto')
    set(axSingleLines,'XTickMode','auto','XTickLabelMode','auto','YTickMode','auto','YTickLabelMode','auto')
end

end