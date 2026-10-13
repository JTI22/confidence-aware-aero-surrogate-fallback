% ---- Hole test (rules in docs/hole_test_rules.md). Run ONCE. ----
data = readtable('naca0012_data.csv');
X = [data.Alpha, data.Mach];
Y = [data.CL, data.CD, data.CM];

sf = 0.1;  ls = 0.4;  sn = 1e-3;  tolCL = 0.1;
thr  = 0.00879;                       % locked threshold, not retuned
muX = mean(X);  sdX = std(X);         % fixed input scaling from all rows

hole = X(:,1) >= 10 & X(:,1) <= 14;   % rows removed from training
fprintf('Hole rows: %d, training rows: %d\n\n', sum(hole), sum(~hole));

[Yp, sd] = gp_fit_predict2(X(~hole,:), Y(~hole,:), X(hole,:), sf, ls, sn, muX, sdX);
Xh  = X(hole,:);
err = abs(Yp - Y(hole,:));
gate = sd <= thr;

fprintf('Alpha  Mach   unc     CL_err   GP_trusted\n');
for i = 1:size(Xh,1)
    fprintf('%5.1f  %.1f  %.4f  %7.4f   %d\n', Xh(i,1), Xh(i,2), sd(i), err(i,1), gate(i));
end

bad = err(:,1) > tolCL;
fprintf('\nRange rule trusts all %d points; worst CL error %.4f\n', numel(bad), max(err(:,1)));
fprintf('Points with CL error > %.1f: %d (range rule lets all of them through)\n', tolCL, sum(bad));
fprintf('  of those, refused by GP gate: %d\n', sum(bad & ~gate));
fprintf('GP gate trusts %d of %d points, refuses %d\n', sum(gate), numel(gate), sum(~gate));
fprintf('  of the refused, actually within %.1f: %d\n', tolCL, sum(~gate & ~bad));
if any(gate)
    fprintf('Among GP-trusted: worst error CL %.4f  CD %.4f  CM %.4f\n', max(err(gate,:)));
    fprintf('PASS (every trusted CL error <= %.1f)? %d\n', tolCL, max(err(gate,1)) <= tolCL);
else
    fprintf('GP gate refused everything.\n');
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