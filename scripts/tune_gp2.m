% ---- GP on top of a quadratic trend, tuned on the training zone only ----
data = readtable('naca0012_data.csv');
X = [data.Alpha, data.Mach];
Y = [data.CL, data.CD, data.CM];

zone = X(:,1) <= 12;
X = X(zone,:);  Y = Y(zone,:);

trMask = X(:,1) <= 9;
vaMask = ~trMask;
Xtr = X(trMask,:);  Ytr = Y(trMask,:);
Xva = X(vaMask,:);  Yva = Y(vaMask,:);

muX = mean(Xtr);  sdX = std(Xtr);
muY = mean(Ytr);  sdY = std(Ytr);
Xtr_s = (Xtr - muX) ./ sdX;   Xva_s = (Xva - muX) ./ sdX;
Ytr_s = (Ytr - muY) ./ sdY;   Yva_s = (Yva - muY) ./ sdY;

% Quadratic trend learned from the training part only
poly = @(X) [ones(size(X,1),1), X(:,1), X(:,2), X(:,1).^2, X(:,1).*X(:,2), X(:,2).^2];
coef     = poly(Xtr_s) \ Ytr_s;
trend_tr = poly(Xtr_s) * coef;
trend_va = poly(Xva_s) * coef;
R = Ytr_s - trend_tr;              % what the curve missed

rmse_poly = sqrt(mean((trend_va - Yva_s).^2));
fprintf('Curve only (no GP): RMSE CL %.4f CD %.4f CM %.4f\n\n', rmse_poly);

sqdist = @(X1, X2) sum(X1.^2, 2) + sum(X2.^2, 2)' - 2*(X1 * X2');
sn = 1e-3;

for sf = [0.1 1]
    for ls = [0.4 0.7 1 1.5]
        kernel = @(X1, X2) sf^2 * exp(-sqdist(X1, X2) / (2*ls^2));
        K  = kernel(Xtr_s, Xtr_s) + sn^2 * eye(size(Xtr_s,1));
        Ks = kernel(Xva_s, Xtr_s);
        Yp = trend_va + Ks * (K \ R);

        V  = K \ Ks';
        sd = sqrt(max(sf^2 - sum(Ks' .* V, 1)', 1e-12));

        err   = abs(Yp - Yva_s);
        rmse  = sqrt(mean((Yp - Yva_s).^2));
        ratio = median(err ./ sd);
        fprintf('sf=%.1f ls=%.1f | RMSE CL %.4f CD %.4f CM %.4f | miss/claimed CL %.1f CD %.1f CM %.1f\n', ...
            sf, ls, rmse, ratio);
    end
end