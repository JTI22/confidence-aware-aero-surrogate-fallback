% ---- Interior-patch test (run ONCE) ----
data = readtable('naca0012_data.csv');
X = [data.Alpha, data.Mach];  Y = [data.CL, data.CD, data.CM];

sf = 0.1;  ls = 0.4;  sn = 1e-3;  tolCL = 0.1;
muX = mean(X);  sdX = std(X);

% --- Threshold, same rule as score_hi.m ---
z = X(:,1) <= 12;
[Yd, sdd] = gp_fit_predict2(X(z,:), Y(z,:), X(~z,:), sf, ls, sn, muX, sdX);
bad = abs(Yd(:,1) - Y(~z,1)) > tolCL;
thr = 0.5 * min(sdd(bad));
fprintf('Threshold = %.5f\n', thr);

% --- The hole ---
hole = X(:,1) >= 4 & X(:,1) <= 10 & X(:,2) >= 0.2-1e-9 & X(:,2) <= 0.3+1e-9;
fprintf('Hole rows: %d, training rows: %d\n\n', sum(hole), sum(~hole));

[Yp, sd] = gp_fit_predict2(X(~hole,:), Y(~hole,:), X(hole,:), sf, ls, sn, muX, sdX);
Xh = X(hole,:);  err = abs(Yp - Y(hole,:));
gate = sd <= thr;

fprintf('Alpha  Mach   unc     CL_err   GP_trusted\n');
for i = 1:size(Xh,1)
    fprintf('%5.1f  %.1f  %.4f  %7.4f   %d\n', Xh(i,1), Xh(i,2), sd(i), err(i,1), gate(i));
end

% Range check: every hole point is inside Alpha -5..15 and Mach 0..0.4
inRange = Xh(:,1) >= -5 & Xh(:,1) <= 15 & Xh(:,2) >= 0 & Xh(:,2) <= 0.4;
badPts = err(:,1) > tolCL;
fprintf('\nRange check trusts %d of %d points; worst CL error %.4f\n', sum(inRange), numel(inRange), max(err(inRange,1)));
fprintf('Points with CL error > %.1f: %d\n', tolCL, sum(badPts));
fprintf('  of those, refused by GP gate: %d\n', sum(badPts & ~gate));
fprintf('GP gate trusts %d of %d points\n', sum(gate), numel(gate));
if any(gate)
    fprintf('Among GP-trusted: worst error CL %.4f  CD %.4f  CM %.4f\n', max(err(gate,:)));
    fprintf('PASS (CL <= %.1f)? %d\n', tolCL, max(err(gate,1)) <= tolCL);
end

function [Yp, sd] = gp_fit_predict2(Xa, Ya, Xb, sf, ls, sn, muX, sdX)
    muY = mean(Ya);  sdY = std(Ya);
    Xa_s = (Xa - muX) ./ sdX;  Xb_s = (Xb - muX) ./ sdX;
    Ya_s = (Ya - muY) ./ sdY;
    P = @(X) [ones(size(X,1),1), X(:,1), X(:,2), X(:,1).^2, X(:,1).*X(:,2), X(:,2).^2];
    sq = @(A, B) sum(A.^2, 2) + sum(B.^2, 2)' - 2*(A * B');
    kern = @(A, B) sf^2 * exp(-sq(A, B) / (2*ls^2));
    coef = P(Xa_s) \ Ya_s;
    R = Ya_s - P(Xa_s) * coef;
    K  = kern(Xa_s, Xa_s) + sn^2 * eye(size(Xa_s,1));
    Ks = kern(Xb_s, Xa_s);
    Yp = (P(Xb_s) * coef + Ks * (K \ R)) .* sdY + muY;
    V  = K \ Ks';
    sd = sqrt(max(sf^2 - sum(Ks' .* V, 1)', 1e-12));
end