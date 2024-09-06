function Gespeicherte_Einstellungen = Lade_gespeicherte_Einstellungen(Dateiname_gespeicherte_ES)

if exist(Dateiname_gespeicherte_ES, 'file'),
    Gespeicherte_Einstellungen = load(Dateiname_gespeicherte_ES);
end

if ~exist('Gespeicherte_Einstellungen', 'var') || ~isstruct(Gespeicherte_Einstellungen),
    Gespeicherte_Einstellungen = struct();
end

Standard_ES_Zusatz.flag_Protokollfenster_anzeigen       = true;
Standard_ES_Zusatz.flag_ProtokollDatei_fuehren          = true;
Standard_ES_Zusatz.flag_Wochentage_als_Eigenschaft      = true;
Standard_ES_Zusatz.flag_Ferien_als_Eigenschaft          = true;
Standard_ES_Zusatz.flag_Feiertage_als_Eigenschaft       = true;
Standard_ES_Zusatz.flag_Jahreszeiten_als_Eigenschaft    = false;
Standard_ES_Zusatz.Bundesland                           = 'BY';
% Felder (Einstellungen), welche noch nicht vorhanden sind werden übernommen:
Gespeicherte_Einstellungen = Struct_nicht_vorhandene_Felder_uebernehmen(Gespeicherte_Einstellungen, Standard_ES_Zusatz);


end







