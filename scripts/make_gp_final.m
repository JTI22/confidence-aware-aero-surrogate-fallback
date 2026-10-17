% Builds gp_final.mat (final settings). Run once before gp_predict or the Simulink models.
data = readtable('naca0012_data.csv');
X = [data.Alpha, data.Mach];
Y = [data.CL, data.CD, data.CM];

sf = 0.1;  ls = 0.4;  sn = 1e-3;
muX = mean(X);  sdX = std(X);
muY = mean(Y);  sdY = std(Y);

Xs = (X - muX) ./ sdX;
Ys = (Y - muY) ./ sdY;

P  = @(X) [ones(size(X,1),1), X(:,1), X(:,2), X(:,1).^2, X(:,1).*X(:,2), X(:,2).^2];
sq = @(A,B) sum(A.^2,2) + sum(B.^2,2)' - 2*(A*B');
kern = @(A,B) sf^2 * exp(-sq(A,B)/(2*ls^2));

coef = P(Xs) \ Ys;
R = Ys - P(Xs)*coef;
K = kern(Xs,Xs) + sn^2*eye(size(Xs,1));
W = K \ R;
Kinv = inv(K);

save('gp_final.mat','Xs','coef','W','Kinv','muX','sdX','muY','sdY','sf','ls');
disp('saved gp_final.mat')