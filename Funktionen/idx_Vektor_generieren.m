function idx_Vektor = idx_Vektor_generieren(welcher_Vektor, Haeufigkeit, max_Wert)
% Erzeugt 2 typische idx_Vektoren:
% welcher_Vektor
%   1: Vektor der Form: [1,1,1,1,               2,2,2,2,                3,3,3,3, ...,           max_Wert, max_Wert, max_Wert, max_Wert] bei Hauefigkeit = 4;
%   2: Vektor der Form: [1,2,3,...,max_Wert,    1,2,3,...,max_Wert,     1,2,3,...,max_Wert,     1,2,3,...,max_Wert                    ] bei Hauefigkeit = 4;
%
%   Änhlich dazu: Werte_wie_haeufig_setzen
%             15.10.2013 JL
%
% % Beispiel #1 [1 1 1, 2 2 2, 3 3 3, 4 4 4] )
% welcher_Vektor = 1; 
% Haeufigkeit = 3;
% max_Wert = 4;
% idx_Vektor = idx_Vektor_generieren(welcher_Vektor, Haeufigkeit, max_Wert)
%
% % Beispiel #2 [1 2 3 4 5, 1 2 3 4 5] )
% welcher_Vektor = 2; 
% Haeufigkeit = 2;
% max_Wert = 5;
% idx_Vektor = idx_Vektor_generieren(welcher_Vektor, Haeufigkeit, max_Wert)

switch welcher_Vektor
    
    case 1
        %   1: Vektor der Form: [1,1,1,1,               2,2,2,2,                max_Wert, max_Wert, max_Wert, max_Wert] bei Hauefigkeit = 3;
        idx_Vektor = ceil( (1 : max_Wert*Haeufigkeit) / Haeufigkeit);
        
    case 2
        %  2: Vektor der Form: [1,2,3,...,max_Wert,    1,2,3,...,max_Wert,     1,2,3,...,max_Wert                    ] bei Hauefigkeit = 3;
        idx_Vektor =  rem( (0 : (max_Wert*Haeufigkeit - 1) ), max_Wert) + 1;
        
end

end