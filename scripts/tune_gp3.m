% ---- Same validation split, but CD modeled in log space ----
data = readtable('naca0012_data.csv');
X  = [data.Alpha, data.Mach];
CD = data.CD;

zone = X(:,1) <= 12;
X = X(zone,:);  CD = CD(zone);

trMask = X(:,1) <= 9;
vaMask = ~trMask;
Xtr = X(trMask,:);  CDtr = CD(trMask);
Xva = X(vaMask,:);  CDva = CD(vaMask);

muX = mean(Xtr);  sdX = std(Xtr);
Xtr_s = (Xtr - muX) ./ sdX;   Xva_s = (Xva - muX) ./ sdX;

% Work in log space
Ltr = log(CDtr);
muL = mean(Ltr);  sdL = std(Ltr);
Ltr_s = (Ltr - muL) / sdL;

poly = @(X) [ones(size(X,1),1), X(:,1), X(:,2), X(:,1).^2, X(:,1).*X(:,2), X(:,2).^2];
coef     = poly(Xtr_s) \ Ltr_s;
trend_tr = poly(Xtr_s) * coef;
trend_va = poly(Xva_s) * coef;
R = Ltr_s - trend_tr;

% Error is reported in the SAME units as before (fractions of CD's spread),
% so it can be compared with the earlier CD numbers (best was 0.96)
spreadCD = std(CDtr);

cd_curve = exp(trend_va * sdL + muL);
fprintf('Curve only (log space): CD RMSE %.4f\n\n', sqrt(mean((cd_curve - CDva).^2)) / spreadCD);

sqdist = @(X1, X2) sum(X1.^2, 2) + sum(X2.^2, 2)' - 2*(X1 * X2');
sn = 1e-3;

for sf = [0.1 1]
    for ls = [0.4 0.7 1 1.5]
        kernel = @(X1, X2) sf^2 * exp(-sqdist(X1, X2) / (2*ls^2));
        K  = kernel(Xtr_s, Xtr_s) + sn^2 * eye(size(Xtr_s,1));
        Ks = kernel(Xva_s, Xtr_s);

        yp_log = (trend_va + Ks * (K \ R)) * sdL + muL;
        cd_pred = exp(yp_log);

        V  = K \ Ks';
        sd = sqrt(max(sf^2 - sum(Ks' .* V, 1)', 1e-12)) * sdL;   % uncertainty in log units

        rmse  = sqrt(mean((cd_pred - CDva).^2)) / spreadCD;
        ratio = median(abs(yp_log - log(CDva)) ./ sd);
        fprintf('sf=%.1f ls=%.1f | CD RMSE %.4f | miss/claimed (log space) %.1f\n', sf, ls, rmse, ratio);
    end
end