% ---- Final scoring on the new high-angle test set (run ONCE) ----
data = readtable('naca0012_data.csv');
X = [data.Alpha, data.Mach];  Y = [data.CL, data.CD, data.CM];
hi = readtable('naca0012_hi_test.csv');
Xhi = [hi.Alpha, hi.Mach];    Yhi = [hi.CL, hi.CD, hi.CM];

sf = 0.1;  ls = 0.4;  sn = 1e-3;  tolCL = 0.1;
muX = mean(X);  sdX = std(X);          % fixed scaling used everywhere

% --- Threshold from the development rows (train <= 12, predict 12 to 15) ---
z = X(:,1) <= 12;
[Yd, sdd] = gp_fit_predict2(X(z,:), Y(z,:), X(~z,:), sf, ls, sn, muX, sdX);
bad = abs(Yd(:,1) - Y(~z,1)) > tolCL;
if ~any(bad), error('No development point exceeded the tolerance.'); end
thr = 0.5 * min(sdd(bad));
fprintf('Threshold (half of smallest uncertainty with CL error > %.1f) = %.5f\n\n', tolCL, thr);

% --- The single test ---
[Yp, sd] = gp_fit_predict2(X, Y, Xhi, sf, ls, sn, muX, sdX);
err = abs(Yp - Yhi);
gate = sd <= thr;

fprintf('Alpha  Mach   unc     CL_err   trusted\n');
for i = 1:size(Xhi,1)
    fprintf('%5.1f  %.1f  %.4f  %7.4f   %d\n', Xhi(i,1), Xhi(i,2), sd(i), err(i,1), gate(i));
end
fprintf('\nNo gate: worst error  CL %.4f  CD %.4f  CM %.4f\n', max(err));
fprintf('Gate trusted %d of %d points\n', sum(gate), numel(gate));
if any(gate)
    fprintf('Among trusted: worst error  CL %.4f  CD %.4f  CM %.4f\n', max(err(gate,:)));
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