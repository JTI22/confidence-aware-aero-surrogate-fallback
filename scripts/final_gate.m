% ---- Choose gate threshold on validation, then test ONCE ----
data = readtable('naca0012_data.csv');
X = [data.Alpha, data.Mach];
Y = [data.CL, data.CD, data.CM];

sf = 0.1;  ls = 0.4;  sn = 1e-3;
tolCL = 0.1;                       % fixed before looking at results

% ===== Part A: choose threshold using the training zone only =====
zone = X(:,1) <= 12;
Xz = X(zone,:);  Yz = Y(zone,:);
tr = Xz(:,1) <= 9;  va = ~tr;

[Yp_va, sd_va] = gp_fit_predict(Xz(tr,:), Yz(tr,:), Xz(va,:), sf, ls, sn);
err_va = abs(Yp_va - Yz(va,:));

thr = NaN;
for c = sort(unique(sd_va))'
    trusted = sd_va <= c;
    if max(err_va(trusted,1)) <= tolCL
        thr = c;                   % keep the largest cutoff that still meets the tolerance
    end
end
if isnan(thr)
    error('No threshold met the tolerance on validation.');
end
t = sd_va <= thr;
fprintf('Chosen threshold (uncertainty cutoff) = %.5f\n', thr);
fprintf('Validation: trusted %d of %d points. Worst error among trusted: CL %.4f CD %.5f CM %.5f\n\n', ...
    sum(t), numel(t), max(err_va(t,1)), max(err_va(t,2)), max(err_va(t,3)));

% ===== Part B: the single test run (Alpha > 12) =====
Xte = X(~zone,:);  Yte = Y(~zone,:);
[Yp_te, sd_te] = gp_fit_predict(Xz, Yz, Xte, sf, ls, sn);
err_te = abs(Yp_te - Yte);

gate = sd_te <= thr;
n = sum(gate);
fprintf('TEST (30 unseen points)\n');
fprintf('No gate:  worst error CL %.4f CD %.5f CM %.5f\n', max(err_te(:,1)), max(err_te(:,2)), max(err_te(:,3)));

if n > 0
    fprintf('GP gate:  trusted %d of %d | worst error CL %.4f CD %.5f CM %.5f\n', n, numel(gate), ...
        max(err_te(gate,1)), max(err_te(gate,2)), max(err_te(gate,3)));
    [~, ord] = sort(Xte(:,1));     % simple angle rule: trust the n lowest angles
    rc = ord(1:n);
    fprintf('Angle rule (same count): trusted %d | worst error CL %.4f CD %.5f CM %.5f\n', n, ...
        max(err_te(rc,1)), max(err_te(rc,2)), max(err_te(rc,3)));
else
    fprintf('GP gate trusted 0 points.\n');
end

% ---- helper function (must stay at the bottom of the file) ----
function [Yp, sd] = gp_fit_predict(Xa, Ya, Xb, sf, ls, sn)
    muX = mean(Xa);  sdX = std(Xa);
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