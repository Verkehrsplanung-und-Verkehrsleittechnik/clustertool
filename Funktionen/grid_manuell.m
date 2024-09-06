function [ handle_grid ] = grid_manuell( ES )
%[ handle_grid ] = grid_manuell( ES )
%   Zeichnet ein Grid für so dass man ein handle für das Grid hat und man
%   das Grid über uistack positionieren kann.
%   Vor allem bei nicht transparenten Flächen sehr hilfreich.
%
% Eingänge:
%   - ES
%       Standard_ES.Linienart       = ':';
%       Standard_ES.Linienstaerke   = 0.5;
%       Standard_ES.axis_handle     = gca;
%       Standard_ES.Farbe           = [0,0,0];
%       Standard_ES.DisplayName1    = 'Grid';
%       Standard_ES.Tag1            = 'Grid';
%       Standard_ES.flag_x_Achse    = true;
%       Standard_ES.flag_y_Achse    = true;
%       Standard_ES.xPos = get(Standard_ES.axis_handle, 'XTick');
%       Standard_ES.yPos = get(Standard_ES.axis_handle, 'YTick');



if nargin < 1 || ~isstruct(ES) || isempty(ES), ES = struct();  end

% Nicht vorhandene Felder von "ES_Standard" zu "ES" hinzufügen.
ES_Standard = Standardeinstellungen(ES);
ES = Struct_nicht_vorhandene_Felder_uebernehmen(ES, ES_Standard);

% Falls ein Grid vorhanden ist, wird dieses ausgeschaltet: 
grid(ES.axis_handle, 'off')

% Dimension des Plots auswählen:
Achsen = [get(ES.axis_handle,'XLim'), get(ES.axis_handle,'YLim')];

% Achsenbeschriftung auslesen:
xTicks = [ES.xPos; ES.xPos];
AchsenY = bsxfun(@times,ones(size(xTicks,1),size(xTicks,2)),Achsen(3:4)');

yTicks = [ES.yPos; ES.yPos];
AchsenX = bsxfun(@times,ones(size(yTicks,1),size(yTicks,2)),Achsen(1:2)');

% line kann nur auf die Current Axes angewandt werden:
set(0,'CurrentFigure', get(ES.axis_handle,'Parent'));
set(get(ES.axis_handle,'Parent'), 'CurrentAxes', ES.axis_handle);


if ES.flag_x_Achse && ES.flag_y_Achse,
    plotX = [xTicks, AchsenX];  plotY = [AchsenY, yTicks];
elseif ES.flag_x_Achse,
    plotX = xTicks;             plotY = AchsenY;
elseif ES.flag_y_Achse
    plotX = AchsenX;            plotY = yTicks;
else % keine Achse ausgewählt:
    plotX = [];                 plotY = [];
end



handle_grid = line( plotX, plotY, ...
    'Color', ES.Farbe, ...
    'LineWidth', ES.Linienstaerke, ...
    'LineStyle', ES.Linienart, ...
    'DisplayName', ES.DisplayName1, ...
    'Tag', ES.Tag1 ...
    );


% Die Linien sollen nicht in der Legende vorkommen (werden dann auch nicht im Plot Browser angezeigt).
switch length(handle_grid),
    case 0,
        % nicht passiert
    case 1,
        set(get(get(handle_grid,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
    otherwise
        Annotation_grid = cell2mat(get(handle_grid,'Annotation'));
        LegendInformation_grid = cell2mat(get(Annotation_grid,'LegendInformation'));
        set(LegendInformation_grid,'IconDisplayStyle','off');
end

end % MAIN function 

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ``_____`_```````````_```````_`_``````````````````````````````
% `|`____(_)_`__``___|`|_`___|`|`|_```_`_`__```__`_``___`_`__``
% `|``_|`|`|`'_`\/`__|`__/`_`\`|`|`|`|`|`'_`\`/`_``|/`_`\`'_`\`
% `|`|___|`|`|`|`\__`\`|_``__/`|`|`|_|`|`|`|`|`(_|`|``__/`|`|`|
% `|_____|_|_|`|_|___/\__\___|_|_|\__,_|_|`|_|\__,`|\___|_|`|_|
% ````````````````````````````````````````````|___/````````````
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Standard_ES = Standardeinstellungen(ES)

Standard_ES.Linienart       = ':';
Standard_ES.Linienstaerke   = 0.5;
if isfield(ES, 'axis_handle'), % Das wird hier noch benötigt !!!
    Standard_ES.axis_handle = ES.axis_handle;
else
    Standard_ES.axis_handle = gca;
end
Standard_ES.Farbe           = [0,0,0];
Standard_ES.DisplayName1    = 'Grid';
Standard_ES.Tag1            = 'Grid';
Standard_ES.flag_x_Achse    = true;
Standard_ES.flag_y_Achse    = true;


%% Falls ES.axis_handle mit eingeht ist Standard_ES.axis_handle == ES.axis_handle !!!!
Standard_ES.xPos = get(Standard_ES.axis_handle, 'XTick');
Standard_ES.yPos = get(Standard_ES.axis_handle, 'YTick');


end % function 
