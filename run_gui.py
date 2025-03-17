import wx
from gui_clustering import ClusterGUI  # Importiere die GUI-Klasse

if __name__ == "__main__":
    app = wx.App(False)  # Erstelle eine wxPython-App
    frame = ClusterGUI()  # Erstelle das GUI-Fenster
    app.MainLoop()  # Starte die Event-Schleife
