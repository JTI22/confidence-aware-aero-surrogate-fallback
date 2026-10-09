% ---- Extrapolation test: train on low angles, test on high angles ----
data = readtable('naca0012_data.csv');
X = [data.Alpha, data.Mach];
Y = [data.CL, data.CD, data.CM];

trainMask = X(:,1) <= 12;      % angles up to 12 degrees: model sees these
testMask  = X(:,1) >  12;      % angles above 12 degrees: model never sees these

Xtrain = X(trainMask,:);  Ytrain = Y(trainMask,:);
Xtest  = X(testMask,:);   Ytest  = Y(testMask,:);

fprintf('Training rows: %d\n', size(Xtrain,1));
fprintf('Test rows (high angle): %d\n', size(Xtest,1));

% ---- GP (same settings as before, sigma_n = 0.0001) ----
lengthScale = 5;  sigma_f = 1;  sigma_n = 0.0001;
sqdist = @(X1, X2) sum(X1.^2, 2) + sum(X2.^2, 2)' - 2*(X1 * X2');
kernel = @(X1, X2) sigma_f^2 * exp(-sqdist(X1, X2) / (2*lengthScale^2));

K = kernel(Xtrain, Xtrain) + sigma_n^2 * eye(size(Xtrain,1));
A = K \ Ytrain;
K_star = kernel(Xtest, Xtrain);
Ypred = K_star * A;

V = K \ K_star';
predVar = sigma_f^2 - sum(K_star' .* V, 1)';
predSD  = sqrt(max(predVar, 1e-12));

absErr = abs(Ypred - Ytest);
names = ["CL", "CD", "CM"];

fprintf('\nGP on HIGH-ANGLE test set:\n');
for j = 1:3
    fprintf('  %s: RMSE = %.5f\n', names(j), sqrt(mean((Ypred(:,j)-Ytest(:,j)).^2)));
    c = corrcoef(log10(predSD), log10(absErr(:,j) + 1e-12));
    fprintf('  %s: correlation (uncertainty vs error) = %.2f\n', names(j), c(1,2));
end

% ---- Plot: do uncertainty and error both climb with angle? ----
figure;
subplot(2,1,1);
semilogy(Xtest(:,1), predSD, 'o'); grid on;
xlabel('Alpha (deg)'); ylabel('GP uncertainty (std dev)');
title('Uncertainty vs angle (unseen angles)');

subplot(2,1,2);
semilogy(Xtest(:,1), absErr(:,1), 'o'); hold on;
semilogy(Xtest(:,1), absErr(:,2), 's');
semilogy(Xtest(:,1), absErr(:,3), '^'); grid on;
xlabel('Alpha (deg)'); ylabel('Actual absolute error');
legend('CL','CD','CM','Location','northwest');
title('Actual error vs angle (unseen angles)');

% ---- Preview of the safety gate: trust only points with low uncertainty ----
thresholds = [1e-3, 3e-3, 1e-2];
for t = thresholds
    trusted = predSD < t;
    fprintf('Threshold %g: trusted %d of %d points, worst CL error among trusted = %g\n', ...
        t, sum(trusted), numel(trusted), max(absErr(trusted,1)));
end