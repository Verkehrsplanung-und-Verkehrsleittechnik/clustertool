function [HANDLES_mit_Tag] = get_handles_mit_best_tag( tag_string, handle_axis )
% Gibt von einer bestimmten Achse (handle_axis), alle plots mit einem
% bestimmten 'Tag' (tag_string) zurück
%
% [HANDLES_mit_Tag] = get_handles_mit_best_tag( tag_string, handle_axis )
%
%
if nargin==0 || ~ischar(tag_string), error('Es muss mindestens einen Eingang geben (tag_string).'), end
if nargin<=1 || isempty(handle_axis), handle_axis=gca; end

Kinder_Lageplot = get(handle_axis,'Children');

% Wenn es keine Kinder gibt => leer zurück.
if isempty(Kinder_Lageplot),
    HANDLES_mit_Tag = [];
    return
end

% suche nach bestimmten Tag 
if length(Kinder_Lageplot)==1,
    zeilen_mit_Tag = strfind(get(Kinder_Lageplot,'Tag'),tag_string);
else
    zeilen_mit_Tag = cellfun(@any,(strfind(get(Kinder_Lageplot,'Tag'),tag_string)));
end

%Rückgabe:
HANDLES_mit_Tag=Kinder_Lageplot(zeilen_mit_Tag);

%disp([num2str(length(find(zeilen_mit_Tag==true))),32,'Plots mit dem Tag: ''',tag_string,'''',32,'gelöscht.'])

