% ---- Builds the flight GP (rules: docs/flight_gp_rules.md) ----
% Saves gp_flight.mat, used by gp_predict_flight.m and aircraft_6dof_cl.slx.
data = readtable('naca0012_data.csv');
X = [data.Alpha, data.Mach];
Y = [data.CL, data.CD, data.CM];
sn = 1e-3;

P = @(Z) [ones(size(Z,1),1), Z(:,1), Z(:,2), Z(:,1).^2, Z(:,1).*Z(:,2), Z(:,2).^2];

% ---- 1. Choose kernel settings by log marginal likelihood (all rows) ----
muX = mean(X);  sdX = std(X);
muY = mean(Y);  sdY = std(Y);
Xs = (X - muX) ./ sdX;
Ys = (Y - muY) ./ sdY;
coef = P(Xs) \ Ys;
R = Ys - P(Xs) * coef;
n = size(Xs, 1);

best = -Inf;  hp = [NaN NaN NaN];
for lsA = [0.1 0.2 0.4 0.8 1.6]
  for lsM = [0.2 0.4 0.8 1.6 3.2]
    for sfc = [0.03 0.1 0.3 1]
      K = ardKern(Xs, Xs, sfc, [lsA lsM]) + sn^2 * eye(n);
      [L, p] = chol(K, 'lower');
      if p > 0, continue; end
      a = L' \ (L \ R);
      lml = -0.5 * sum(sum(R .* a)) - size(R,2) * sum(log(diag(L))) - 0.5 * n * size(R,2) * log(2*pi);
      if lml > best
        best = lml;  hp = [lsA lsM sfc];
      end
    end
  end
end
ls = hp(1:2);  sf = hp(3);
fprintf('Chosen settings: ls_alpha = %.2f, ls_mach = %.2f, sf = %.2f\n', ls(1), ls(2), sf);

% ---- 2. Threshold: train on Alpha <= 12, predict 12 to 15 ----
z = X(:,1) <= 12;
[Yd, sdd] = fitPredict(X(z,:), Y(z,:), X(~z,:), P, sf, ls, sn);
bad = abs(Yd(:,1) - Y(~z,1)) > 0.1;
if ~any(bad), error('No development point had CL error above 0.1.'); end
thr = 0.5 * min(sdd(bad));
fprintf('Development points with CL error > 0.1: %d of %d\n', sum(bad), numel(bad));
fprintf('Flight threshold = %.5f\n', thr);

% ---- 3. Final flight GP on all rows ----
K = ardKern(Xs, Xs, sf, ls) + sn^2 * eye(n);
W = K \ R;
Kinv = inv(K);
save('gp_flight.mat', 'Xs', 'coef', 'W', 'Kinv', 'muX', 'sdX', 'muY', 'sdY', 'sf', 'ls', 'thr');
disp('saved gp_flight.mat')

% ---- Local functions ----
function Kab = ardKern(A, B, sf, ls)
  A = A ./ ls;  B = B ./ ls;
  sq = sum(A.^2, 2) + sum(B.^2, 2)' - 2 * (A * B');
  Kab = sf^2 * exp(-0.5 * max(sq, 0));
end

function [Yp, sd] = fitPredict(Xa, Ya, Xb, P, sf, ls, sn)
  muX = mean(Xa);  sdX = std(Xa);
  muY = mean(Ya);  sdY = std(Ya);
  Xs = (Xa - muX) ./ sdX;  Ys = (Ya - muY) ./ sdY;
  coef = P(Xs) \ Ys;
  R = Ys - P(Xs) * coef;
  K = ardKern(Xs, Xs, sf, ls) + sn^2 * eye(size(Xs,1));
  Q = (Xb - muX) ./ sdX;
  Ks = ardKern(Q, Xs, sf, ls);
  Yp = (P(Q) * coef + Ks * (K \ R)) .* sdY + muY;
  sd = sqrt(max(sf^2 - sum(Ks' .* (K \ Ks'), 1)', 1e-12));
end