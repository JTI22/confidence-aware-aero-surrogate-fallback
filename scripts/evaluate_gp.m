% Load the dataset
data = readtable('naca0012_data.csv');

% Inputs and outputs
X = [data.Alpha, data.Mach];
Y = [data.CL, data.CD, data.CM];

n = size(X, 1);

% Fixed seed so anyone can reproduce your exact split
rng(1);

% Shuffle row numbers 1..n, then take the first 80% for training
idx = randperm(n);
nTrain = round(0.8 * n);

trainIdx = idx(1:nTrain);
testIdx  = idx(nTrain+1:end);

Xtrain = X(trainIdx, :);
Ytrain = Y(trainIdx, :);
Xtest  = X(testIdx, :);
Ytest  = Y(testIdx, :);

fprintf('Total rows: %d\n', n);
fprintf('Training rows: %d\n', size(Xtrain, 1));
fprintf('Test rows: %d\n', size(Xtest, 1));


% ---- GP settings (same as train_gp.m for now) ----
lengthScale = 5;
sigma_f = 1;
sigma_n = 0.0001;

sqdist = @(X1, X2) sum(X1.^2, 2) + sum(X2.^2, 2)' - 2*(X1 * X2');
kernel = @(X1, X2) sigma_f^2 * exp(-sqdist(X1, X2) / (2*lengthScale^2));

% ---- Train on TRAINING rows only ----
nTr = size(Xtrain, 1);
K = kernel(Xtrain, Xtrain) + sigma_n^2 * eye(nTr);
A = K \ Ytrain;          % one solve gives weights for CL, CD, CM together

% ---- Predict on the 40 held-out TEST rows ----
K_star = kernel(Xtest, Xtrain);
Ypred = K_star * A;

% ---- Error metrics ----
err = Ypred - Ytest;
RMSE = sqrt(mean(err.^2));
MAE  = mean(abs(err));

names = ["CL", "CD", "CM"];
fprintf('\nGP results on held-out test set (40 points):\n');
for j = 1:3
    fprintf('  %s: RMSE = %.5f, MAE = %.5f\n', names(j), RMSE(j), MAE(j));
end

% ---- Simple baseline: quadratic curve fit in Alpha and Mach ----
poly = @(X) [ones(size(X,1),1), X(:,1), X(:,2), X(:,1).^2, X(:,1).*X(:,2), X(:,2).^2];

coef  = poly(Xtrain) \ Ytrain;     % learn the curve from the 161 training rows
Ypoly = poly(Xtest) * coef;        % predict the 40 hidden rows

errP   = Ypoly - Ytest;
RMSE_P = sqrt(mean(errP.^2));
MAE_P  = mean(abs(errP));

fprintf('\nPolynomial baseline on held-out test set (40 points):\n');
for j = 1:3
    fprintf('  %s: RMSE = %.5f, MAE = %.5f\n', names(j), RMSE_P(j), MAE_P(j));
end

% ---- Uncertainty vs actual error on the 40 test points ----
V = K \ K_star';                                  % reuses K and K_star from the GP block
predVar = sigma_f^2 - sum(K_star' .* V, 1)';      % GP variance for each test point
predSD  = sqrt(max(predVar, 1e-12));              % std dev (max() avoids tiny negative rounding)

absErr = abs(Ypred - Ytest);                      % real error for CL, CD, CM

figure;
loglog(predSD, absErr(:,1), 'o'); hold on;
loglog(predSD, absErr(:,2), 's');
loglog(predSD, absErr(:,3), '^');
xlabel('GP uncertainty (std dev)');
ylabel('Actual absolute error');
legend('CL', 'CD', 'CM', 'Location', 'northwest');
title('Does higher GP uncertainty mean higher error?');
grid on;

% One number for the trend: closer to +1 means "more uncertain = more wrong"
for j = 1:3
    c = corrcoef(log10(predSD), log10(absErr(:,j) + 1e-12));
    fprintf('%s: correlation = %.2f\n', names(j), c(1,2));
end