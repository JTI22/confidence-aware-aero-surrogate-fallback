% ---- Detector test: GP gate vs range rule ----
% Rules: docs/detector_test_rules.md (locked 17 Oct 2026). Run ONCE.
data = readtable('naca0012_data.csv');
hi   = readtable('naca0012_hi_test.csv');
X  = [data.Alpha, data.Mach];   Y  = [data.CL, data.CD, data.CM];
Xh = [hi.Alpha, hi.Mach];       Yh = [hi.CL, hi.CD, hi.CM];

tol   = [0.1 0.01 0.02];        % CL, CD, CM
names = {'CL', 'CD', 'CM'};

% ---- Data split ----
aGrid = -5:2:15;   mGrid = [0 0.2 0.4];
isTr = ismember(round(X(:,1)*10), round(aGrid*10)) & ismember(round(X(:,2)*10), round(mGrid*10));
isVa = abs(X(:,2) - 0.1) < 1e-9;
isTe = ~isTr & ~isVa;
fprintf('Rows: training %d, validation %d, interior test %d, extrapolation test %d\n', ...
        sum(isTr), sum(isVa), sum(isTe), size(Xh,1));

Xtr = X(isTr,:);  Ytr = Y(isTr,:);

% ---- Scaling from training rows only ----
muX = mean(Xtr);  sdX = std(Xtr);
muY = mean(Ytr);  sdY = std(Ytr);
Xs = (Xtr - muX) ./ sdX;
Ys = (Ytr - muY) ./ sdY;

P = @(Z) [ones(size(Z,1),1), Z(:,1), Z(:,2), Z(:,1).^2, Z(:,1).*Z(:,2), Z(:,2).^2];
coef = P(Xs) \ Ys;
R = Ys - P(Xs) * coef;
n = size(Xs, 1);
sn = 1e-3;

% ---- Kernel settings by log marginal likelihood (training rows only) ----
lsAlist = [0.1 0.2 0.4 0.8 1.6];
lsMlist = [0.2 0.4 0.8 1.6 3.2];
sfList  = [0.03 0.1 0.3 1];
best = -Inf;  hp = [NaN NaN NaN];
for lsA = lsAlist
  for lsM = lsMlist
    for sf = sfList
      K = ardKern(Xs, Xs, sf, [lsA lsM]) + sn^2 * eye(n);
      [L, p] = chol(K, 'lower');
      if p > 0, continue; end
      a = L' \ (L \ R);
      lml = -0.5 * sum(sum(R .* a)) - size(R,2) * sum(log(diag(L))) - 0.5 * n * size(R,2) * log(2*pi);
      if lml > best
        best = lml;  hp = [lsA lsM sf];
      end
    end
  end
end
fprintf('Chosen settings: ls_alpha = %.2f, ls_mach = %.2f, sf = %.2f (log marginal likelihood %.1f)\n', ...
        hp(1), hp(2), hp(3), best);

ls = hp(1:2);  sf = hp(3);
K = ardKern(Xs, Xs, sf, ls) + sn^2 * eye(n);
predict = @(Xq) gpPredict(Xq, Xs, R, K, coef, P, muX, sdX, muY, sdY, sf, ls);

% ---- Threshold from validation only, then frozen ----
[Yv, sv] = predict(X(isVa,:));
errV = abs(Yv - Y(isVa,:));
badV = errV(:,1) > tol(1);
if any(badV)
  thr = 0.5 * min(sv(badV));
  fprintf('Threshold = 0.5 x smallest uncertainty of %d bad validation points = %.5f\n', sum(badV), thr);
else
  thr = max(sv);
  fprintf('No bad validation point. Threshold = largest validation uncertainty = %.5f\n', thr);
end

% ---- Test sets ----
[Yi, si] = predict(X(isTe,:));   errI = abs(Yi - Y(isTe,:));
[Ye, se] = predict(Xh);          errE = abs(Ye - Yh);

inRange = @(Z) Z(:,1) >= -5-1e-9 & Z(:,1) <= 15+1e-9 & Z(:,2) >= -1e-9 & Z(:,2) <= 0.4+1e-9;

sets = {'Interior', X(isTe,:), errI, si;
        'Extrapolation', Xh, errE, se;
        'Combined', [X(isTe,:); Xh], [errI; errE], [si; se]};

for s = 1:size(sets,1)
  Xq = sets{s,2};  E = sets{s,3};  U = sets{s,4};
  acc = {inRange(Xq), U <= thr};
  meth = {'Range rule', 'GP gate'};
  fprintf('\n===== %s test (%d points) =====\n', sets{s,1}, size(Xq,1));
  fprintf('%-11s %-3s  bad_accepted  good_refused  worst_accepted_err  coverage\n', 'Method', '');
  for m = 1:2
    A = acc{m};
    for c = 1:3
      bad = E(:,c) > tol(c);
      if any(A), w = max(E(A,c)); else, w = NaN; end
      fprintf('%-11s %-3s  %12d  %12d  %18.4f  %3d/%d\n', meth{m}, names{c}, ...
              sum(bad & A), sum(~bad & ~A), w, sum(A), numel(A));
    end
  end
end

% ---- Save every point for the record ----
fid = fopen('detector_test_points.csv', 'w');
fprintf(fid, 'set,Alpha,Mach,unc,err_CL,err_CD,err_CM,range_accept,gp_accept\n');
for s = 1:2
  Xq = sets{s,2};  E = sets{s,3};  U = sets{s,4};  ra = inRange(Xq);
  for i = 1:size(Xq,1)
    fprintf(fid, '%s,%.2f,%.2f,%.6f,%.5f,%.5f,%.5f,%d,%d\n', sets{s,1}, Xq(i,1), Xq(i,2), ...
            U(i), E(i,1), E(i,2), E(i,3), ra(i), U(i) <= thr);
  end
end
fclose(fid);
disp('saved detector_test_points.csv')

% ---- Local functions ----
function Kab = ardKern(A, B, sf, ls)
  A = A ./ ls;  B = B ./ ls;
  sq = sum(A.^2, 2) + sum(B.^2, 2)' - 2 * (A * B');
  Kab = sf^2 * exp(-0.5 * max(sq, 0));
end

function [Yp, sd] = gpPredict(Xq, Xs, R, K, coef, P, muX, sdX, muY, sdY, sf, ls)
  Q  = (Xq - muX) ./ sdX;
  Ks = ardKern(Q, Xs, sf, ls);
  Yp = (P(Q) * coef + Ks * (K \ R)) .* sdY + muY;
  V  = K \ Ks';
  sd = sqrt(max(sf^2 - sum(Ks' .* V, 1)', 1e-12));
end