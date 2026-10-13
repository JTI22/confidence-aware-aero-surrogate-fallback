function [y, sd] = gp_predict(alpha, mach)
% Returns y = [CL CD CM] and sd = uncertainty
persistent S
if isempty(S)
    S = load('gp_final.mat');
end

x  = ([alpha, mach] - S.muX) ./ S.sdX;
p  = [1, x(1), x(2), x(1)^2, x(1)*x(2), x(2)^2];

sq = sum(S.Xs.^2, 2) + sum(x.^2) - 2*(S.Xs * x');
ks = S.sf^2 * exp(-sq / (2*S.ls^2));

ys = p * S.coef + ks' * S.W;
y  = ys .* S.sdY + S.muY;

v  = S.sf^2 - ks' * S.Kinv * ks;
sd = sqrt(max(v, 1e-12));
end