% ---- Tune GP settings using ONLY the training zone (Alpha <= 12) ----
data = readtable('naca0012_data.csv');
X = [data.Alpha, data.Mach];
Y = [data.CL, data.CD, data.CM];

zone = X(:,1) <= 12;               % test rows (Alpha > 12) are never used here
X = X(zone,:);  Y = Y(zone,:);

% Mini extrapolation test inside the training zone
trMask = X(:,1) <= 9;              % learn from up to 9 deg
vaMask = ~trMask;                  % validate on 9 to 12 deg
Xtr = X(trMask,:);  Ytr = Y(trMask,:);
Xva = X(vaMask,:);  Yva = Y(vaMask,:);
fprintf('Train part: %d rows, validation part: %d rows\n', size(Xtr,1), size(Xva,1));

% Standardize using the training part only
muX = mean(Xtr);  sdX = std(Xtr);
muY = mean(Ytr);  sdY = std(Ytr);
Xtr_s = (Xtr - muX) ./ sdX;   Xva_s = (Xva - muX) ./ sdX;
Ytr_s = (Ytr - muY) ./ sdY;   Yva_s = (Yva - muY) ./ sdY;

sigma_f = 1;
sqdist = @(X1, X2) sum(X1.^2, 2) + sum(X2.^2, 2)' - 2*(X1 * X2');

lengthScales = [0.2 0.4 0.7 1 1.5];
sigma_ns     = [1e-5 1e-3];

fprintf('\nErrors are in "fractions of each output''s spread" (lower = better)\n');
fprintf('miss/claimed = typical real error divided by the uncertainty the GP claimed (1 = honest, 100 = 100x overconfident)\n\n');

for sn = sigma_ns
    for ls = lengthScales
        kernel = @(X1, X2) sigma_f^2 * exp(-sqdist(X1, X2) / (2*ls^2));
        K  = kernel(Xtr_s, Xtr_s) + sn^2 * eye(size(Xtr_s,1));
        A  = K \ Ytr_s;
        Ks = kernel(Xva_s, Xtr_s);
        Yp = Ks * A;

        V  = K \ Ks';
        sd = sqrt(max(sigma_f^2 - sum(Ks' .* V, 1)', 1e-12));

        err   = abs(Yp - Yva_s);
        rmse  = sqrt(mean((Yp - Yva_s).^2));
        ratio = median(err ./ sd);

        fprintf('ls=%.1f sn=%g | RMSE CL %.4f CD %.4f CM %.4f | miss/claimed CL %.1f CD %.1f CM %.1f\n', ...
            ls, sn, rmse, ratio);
    end
end