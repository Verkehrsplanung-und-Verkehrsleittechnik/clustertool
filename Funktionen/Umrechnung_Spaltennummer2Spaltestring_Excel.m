function Spalte_str=Umrechnung_Spaltennummer2Spaltestring_Excel(Spalte_num)
%Rechnet die Spaltennummer in die entsprechende Spalte in Excel um:
for cnt=1:length(Spalte_num),
    if Spalte_num(cnt)<=26,
        %Einstellige Spaltenbezeichnung:
        Spalte_str{cnt}=char(64+Spalte_num(cnt));
    else
        if Spalte_num(cnt)<=702,
            %Zweistellige Spaltenbezeichnung:
            erstesZeichen=floor((Spalte_num(cnt)-1)/26);
            zweitesZeichen=Spalte_num(cnt)-erstesZeichen*26;
            Spalte_str{cnt}=strcat(char(64+erstesZeichen),char(64+zweitesZeichen));
        else
            if Spalte_num(cnt)<=16384,
                %Dreistellige Spaltenbezeichnung:
                erstesZeichen=floor((Spalte_num(cnt)-27)/676);
                zweitesZeichen=floor(((Spalte_num(cnt)-27-erstesZeichen*676)/26))+1;
                drittesZeichen=Spalte_num(cnt)-erstesZeichen*676-(zweitesZeichen)*26;
                Spalte_str{cnt}=strcat(char(64+erstesZeichen),char(64+zweitesZeichen),char(64+drittesZeichen));
            else
                error('Zahl zu groß. Maximale Zahl 16384')
            end
        end
    end
end

    
    
    