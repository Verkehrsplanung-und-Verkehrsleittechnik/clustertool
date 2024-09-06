function Mittelwert = mean_ohne_nan(X, DIM)
% Gleiche Funktion wie "mean", nur dass die NaN Werte nicht berücksichtigt werden.
if nargin == 1,
    if size(X,1) == 1 && size(X,2) > 1,
        DIM = 2; 
    else
        DIM = 1;
    end
end

if DIM == 1, % Mittelwert pro Spalte
    Mittelwert = zeros(1, size(X, 2)); % vordimensionieren
    for cnt_Spalte = 1 : size(X, 2),
        idx_nan = isnan(X(:, cnt_Spalte));
        Mittelwert(1, cnt_Spalte) = mean( X(~idx_nan, cnt_Spalte) );
    end
else % Mittelwert pro Zeile
    Mittelwert = zeros(size(X, 1), 1); % vordimensionieren
    for cnt_Zeile = 1 : size(X, 1),
        idx_nan = isnan(X(cnt_Zeile, :));
        Mittelwert(cnt_Zeile, 1) = mean( X(cnt_Zeile, ~idx_nan) );
    end    
end

end % function