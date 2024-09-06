function Lohmiller_Standard_plot_Format( varargin )
% Lohmiller_Standard_plot_Format gibt dem aktuellen plot eine gewisse Standardformatierung
%
% Folgende Einstellungen können vorgenommen werden:
%   ES_LSpF.text_xlabel_str = 'Text x-Achse';   % Ist das Feld nicht vorhanden bleibt die bisherige Beschriftung erhalten
%   ES_LSpF.text_ylabel_str = 'Text y-Achse';   % Ist das Feld nicht vorhanden bleibt die bisherige Beschriftung erhalten
%   ES_LSpF.text_title_str  = 'Text Titel';     % Ist das Feld nicht vorhanden bleibt die bisherige Beschriftung erhalten
%   ES_LSpF.flag_x_datetick = false; % Soll datetick angewand werden?
%   ES_LSpF.datetick_format = 'ddd dd.mm.';
%   ES_LSpF.font_size       = 14;
%   ES_LSpF.handle_axes     = gca;
%   ES_LSpF.flag_keeplimits = true; % Sollen die Achsenausdehnungen erhalten bleiben
%   Lohmiller_Standard_plot_Format( ES_LSpF )

%            datetick('x',format, 'keeplimits', 'keepticks');

%% Für die alte Version:
if nargin >= 1,
    if ~isstruct(varargin{1}),
        Variablen_Reihenfolge_alte_Version = {'text_xlabel_str', 'text_ylabel_str', 'text_title_str', 'flag_x_datetick', 'datetick_format', 'font_size', 'handle_axes', 'flag_keeplimits'};
        for cnt_Input = 1 : nargin,
            ES_Input.(Variablen_Reihenfolge_alte_Version{cnt_Input}) = varargin{cnt_Input};
        end
    else
        ES_Input = varargin{1};
    end
    % Font Size darf nicht leer bleiben:
    if isfield(ES_Input, 'font_size') && isempty(ES_Input.font_size), ES_Input.font_size = 14; end
else
    ES_Input = struct();
end

%% Verfügbare Einstellungen:
% siehe Funktion Standardeinstellungen

%% Nicht vorhandene Felder von "ES_Standard" zu "ES" hinzufügen.
Standard_ES = Standardeinstellungen;
ES = Struct_nicht_vorhandene_Felder_uebernehmen(ES_Input, Standard_ES);

Anzahl_h_Axes = length(ES.handle_axes);
for cnt_A = 1 : Anzahl_h_Axes,
    akt_Axes = ES.handle_axes(cnt_A);
    
    %% Wenn Felder mit Texten nicht eingehen, werden sie so gelassen wie sie sind:
    if ~isfield(ES_Input, 'text_xlabel_str') || ~ischar(ES.text_xlabel_str), 
        xText = get(get(akt_Axes, 'Xlabel'), 'String'); 
    else
        xText = ES.text_xlabel_str;
    end
    if ~isfield(ES_Input, 'text_ylabel_str') || ~ischar(ES.text_ylabel_str), 
        yText = get(get(akt_Axes, 'Ylabel'), 'String');
    else
        yText = ES.text_ylabel_str;
    end
    if ~isfield(ES_Input, 'text_title_str')  || ~ischar(ES.text_title_str),  
        title_text  = get(get(akt_Axes, 'Title'), 'String');  
    else
        title_text = ES.text_title_str;
    end
    if isempty(ES.handle_axes), ES.handle_axes = gca; end
    
    
    hold(akt_Axes, 'on');
    grid(akt_Axes, 'on');
    
    if ES.flag_x_datetick == true,
        if isempty(ES.datetick_format),
            if ES.flag_keeplimits,
                datetickzoom(akt_Axes, 'x', 'keeplimits');
            else
                datetickzoom(akt_Axes, 'x');
            end
        else
            if ES.flag_keeplimits,
                datetickzoom(akt_Axes, 'x', ES.datetick_format, 'keeplimits'),
            else
                datetickzoom(akt_Axes, 'x', ES.datetick_format),
            end
        end
    end
    
    
    
    xlabel(akt_Axes,  xText,        'FontSize', ES.font_size) %,'FontWeight','Bold')
    ylabel(akt_Axes,  yText,        'FontSize', ES.font_size) %,'FontWeight','Bold')
    title(akt_Axes,   title_text,   'FontSize', ES.font_size)
    
    set(akt_Axes,'FontSize',ES.font_size) %,'FontWeight','Bold')
    set(akt_Axes,'XMinorTick','on')
    set(akt_Axes,'YMinorTick','on')
    
    % Falls manuelle Beschriftungen gesetzt wurden: (siehe XTicks_selber_setzten)
    h_manuelle_Beschriftung = get_handles_mit_best_tag('manuelle x-Beschriftung', akt_Axes);
    if any(h_manuelle_Beschriftung),
        set(h_manuelle_Beschriftung, 'FontSize', ES.font_size)
    end
    
end

end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ``_____`_```````````_```````_`_``````````````````````````````
% `|`____(_)_`__``___|`|_`___|`|`|_```_`_`__```__`_``___`_`__``
% `|``_|`|`|`'_`\/`__|`__/`_`\`|`|`|`|`|`'_`\`/`_``|/`_`\`'_`\`
% `|`|___|`|`|`|`\__`\`|_``__/`|`|`|_|`|`|`|`|`(_|`|``__/`|`|`|
% `|_____|_|_|`|_|___/\__\___|_|_|\__,_|_|`|_|\__,`|\___|_|`|_|
% ````````````````````````````````````````````|___/````````````
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Standard_ES = Standardeinstellungen

Standard_ES.text_xlabel_str = [];
Standard_ES.text_ylabel_str = [];
Standard_ES.text_title_str  = [];
Standard_ES.flag_x_datetick = false;
Standard_ES.datetick_format = [];
Standard_ES.font_size       = 14;
Standard_ES.handle_axes     = gca;
Standard_ES.flag_keeplimits = true;


end % function


% Function datetickzoom
function datetickzoom(varargin)
%DATETICKZOOM Date formatted tick labels, automatically updated when zoomed or panned.
%   Arguments are completely identical to does of DATETICK. The argument
%   DATEFORM is reset once zoomed or panned.
%
%   See also datetick, datestr, datenum

if nargin==2 && isstruct(varargin{2}) && isfield(varargin{2},'Axes') && isscalar(varargin{2}.Axes)
    datetickdata = getappdata(varargin{2}.Axes,'datetickdata');
    if isstruct(datetickdata) && isfield(datetickdata,'axh') && datetickdata.axh==varargin{2}.Axes
        axh = datetickdata.axh;
        ax = datetickdata.ax;
        dateform = datetickdata.dateform;
        keep_ticks = datetickdata.keep_ticks;
        if keep_ticks
            set(axh,[ax,'TickMode'],'auto')
            if ~isempty(dateform)
                datetick(axh,ax,dateform,'keeplimits','keepticks')
            else
                datetick(axh,ax,'keeplimits','keepticks')
            end
        else
            if ~isempty(dateform)
                datetick(axh,ax,dateform,'keeplimits')
            else
                datetick(axh,ax,'keeplimits')
            end
        end
    end
else
    [axh,ax,dateform,keep_ticks] = parseinputs(varargin);
    datetickdata = [];
    datetickdata.axh = axh;
    datetickdata.ax = ax;
    datetickdata.dateform = dateform;
    datetickdata.keep_ticks = keep_ticks;
    
    setappdata(axh,'datetickdata',datetickdata);
    set(zoom(axh),'ActionPostCallback',@datetickzoom)
    set(pan(get(axh,'parent')),'ActionPostCallback',@datetickzoom)
    datetick(varargin{:})
end

end % Main function
function [axh,ax,dateform,keep_ticks] = parseinputs(v)
%Parse Inputs

% Defaults;
nin = length(v);
dateform = [];
keep_ticks = 0;

% check to see if an axes was specified
if nin > 0 & ishandle(v{1}) & isequal(get(v{1},'type'),'axes') %#ok ishandle return is not scalar
    % use the axes passed in
    axh = v{1};
    v(1)=[];
    nin=nin-1;
else
    % use gca
    axh = gca;
end
% Look for 'keepticks'
for i=nin:-1:max(1,nin-1),
    if strcmpi(v{i},'keepticks'),
        keep_ticks = 1;
        v(i) = [];
        nin = nin-1;
    end
end

if nin==0,
    ax = 'x';
else
    ax = v{1};
end
if nin > 1
    % The dateform (Date Format) value should be a scalar or string constant
    % check this out
    dateform = v{2};
    if (isnumeric(dateform) && length(dateform) ~= 1) && ~ischar(dateform)
        error('The Date Format value should be a scalar or string');
    end
end
end % function

