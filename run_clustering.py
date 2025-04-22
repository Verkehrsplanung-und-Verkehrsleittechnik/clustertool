import modules
from pathlib import Path


## @brief Hauptprogramm: Führt die Clusterung mit voreingestellten Parametern durch.
if __name__ == "__main__":
    file_path = Path.cwd() / "data"  # Beispiel-Pfad zur Eingabedatei

    # Daten laden
    data = modules.data_handler.load_and_prepare_data(file_path / "Ganglinien2008.csv")
    data_attributes = modules.data_handler.load_and_prepare_data(file_path / "Eigenschaft_Wetter.mat")

    # Cluster-Objekt erstellen
    clusterer = modules.clustering.Clusterung(data, attr_data=data_attributes,
                                              method="average", distance_function="SQV Counts", cutoff=0.8,
                                              kmeans_preset="random")

    # Clusterung durchführen
    clusterer.perform_clustering()
    clusterer.plots_results()
    fig_weekdays = clusterer.plot_properties("Wochentag")
    fig_dendrogram = clusterer.plot_dendrogramm()
    # series_info = clusterer.get_info()

    fig_distances = clusterer.plot_distances()
    fig_silhouette = clusterer.plot_silhouette()
    # fig_calendar = clusterer.plot_calendar_cluster()
    #
    # modules.data_handler.save_clusterung_to_json(clusterer, file_path / "Test.json")
    #
    fig_series, dict_properties_fig = clusterer.plots_results()

    a=1




