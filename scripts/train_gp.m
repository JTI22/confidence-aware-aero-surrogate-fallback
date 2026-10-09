% Load the dataset
data = readtable('naca0012_data.csv');
head(data)

% Inputs: Alpha and Mach
X = [data.Alpha, data.Mach];

% Outputs: CL, CD, CM — train on all three
y_CL = data.CL;
y_CD = data.CD;
y_CM = data.CM;

n = size(X, 1);

% --- Kernel settings ---
lengthScale = 5;
sigma_f = 1;
sigma_n = 0.01;

% Manual squared-distance function (replaces pdist2)
sqdist = @(X1, X2) sum(X1.^2, 2) + sum(X2.^2, 2)' - 2*(X1 * X2');

% Kernel function: squared exponential
kernel = @(X1, X2) sigma_f^2 * exp(-sqdist(X1, X2) / (2*lengthScale^2));

% --- Build the training kernel matrix (same for all 3 outputs) ---
K = kernel(X, X) + sigma_n^2 * eye(n);

% Precompute K \ y for each output (used in prediction formula)
alpha_CL = K \ y_CL;
alpha_CD = K \ y_CD;
alpha_CM = K \ y_CM;

% --- Test points: safe, borderline, and out-of-range ---
testPoints = [2, 0.2;     % safe, well inside training range
              14, 0.4;    % borderline, near edge of training range
              25, 0.6];   % far outside training range

labels = ["Safe", "Borderline", "Out-of-range"];

for i = 1:size(testPoints, 1)
    Xtest = testPoints(i, :);
    K_star = kernel(Xtest, X);
    K_star_star = kernel(Xtest, Xtest);

    % Predictions for each output
    pred_CL = K_star * alpha_CL;
    pred_CD = K_star * alpha_CD;
    pred_CM = K_star * alpha_CM;

    % Uncertainty is the SAME for all 3 outputs (depends only on X, not y)
    v = K \ K_star';
    predictedVar = K_star_star - K_star * v;
    predictedSD = sqrt(predictedVar);

    fprintf('\n[%s] Alpha=%.1f, Mach=%.1f\n', labels(i), Xtest(1), Xtest(2));
    fprintf('  Predicted CL: %.4f\n', pred_CL);
    fprintf('  Predicted CD: %.4f\n', pred_CD);
    fprintf('  Predicted CM: %.4f\n', pred_CM);
    fprintf('  Uncertainty (std dev): %.4f\n', predictedSD);
end