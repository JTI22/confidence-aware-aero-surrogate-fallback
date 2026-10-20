function [y, sd, thr] = gp_predict_flight(alpha, mach)
% Flight GP: returns y = [CL CD CM], sd = uncertainty, thr = locked flight threshold
persistent S
if isempty(S)
    S = load('gp_flight.mat');
end

x  = ([alpha, mach] - S.muX) ./ S.sdX;
p  = [1, x(1), x(2), x(1)^2, x(1)*x(2), x(2)^2];

d  = (S.Xs - x) ./ S.ls;
ks = S.sf^2 * exp(-0.5 * sum(d.^2, 2));

ys = p * S.coef + ks' * S.W;
y  = ys .* S.sdY + S.muY;

v  = S.sf^2 - ks' * S.Kinv * ks;
sd = sqrt(max(v, 1e-12));
thr = S.thr;
end