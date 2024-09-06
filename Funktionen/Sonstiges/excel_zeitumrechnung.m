function [ Zeit_AUS ] = excel_zeitumrechnung( Zeit_IN, welche_Richtung )
%Rechnet die Zeit zwischen Excel-Zeit und Matlab-Zeiten um.
%
% welche_Richtung
%   1: von Excel-Zeit in Matlab-Zeit
%   2: von Matlab-Zeit in Excel-Zeit
%

% Excel hält 1900 fälschlicherweise für ein Schaltjahr. 
% Tag 60 von Excel ist in Excel der 29.02.1900
%   => excel_zeitumrechnung( 60 ) ergibt => 694020 => datestr(694020) => 28-Feb-1900
if nargin < 2 || isempty(welche_Richtung),
    if Zeit_IN > 600000, % datestr(600000) => 28-Sep-1642
        welche_Richtung = 2;
    else
        welche_Richtung = 1;
    end
end

Zeit_AUS = nan(size(Zeit_IN));

switch welche_Richtung,
    case 1,
        %Excel hält 1900 fälschlicherweise für ein Schaltjahr. 
        idx_Zeit_nach_1900 = Zeit_IN > 59;
        Zeit_AUS( idx_Zeit_nach_1900) = Zeit_IN( idx_Zeit_nach_1900) + 693960;
        Zeit_AUS(~idx_Zeit_nach_1900) = Zeit_IN(~idx_Zeit_nach_1900) + 693961;
        
    case 2,
        %Excel hält 1900 fälschlicherweise für ein Schaltjahr. 
        idx_Zeit_nach_1900 = Zeit_IN > 694020; % datestr(694020) => 28-Feb-1900
        Zeit_AUS( idx_Zeit_nach_1900) = Zeit_IN( idx_Zeit_nach_1900) - 693960;
        Zeit_AUS(~idx_Zeit_nach_1900) = Zeit_IN(~idx_Zeit_nach_1900) - 693961;        
end




