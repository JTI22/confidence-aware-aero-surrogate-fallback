% ---- Trim: steady level flight at 30 m/s ----
% Uses the lookup table (the reference model). Run before the closed-loop model.
rho  = 1.225;   % air density, kg/m3
S    = 0.15;    % wing area, m2
mass = 5;       % kg
g    = 9.81;    % m/s2
V0   = 30;      % trim airspeed, m/s
mach0 = V0 / 340;

q = 0.5 * rho * V0^2 * S;
W = mass * g;

% Lift plus the vertical part of thrust must equal weight (thrust cancels drag)
alpha0 = fzero(@(a) trimResidual(a, mach0, q, W), [0 10]);   % degrees

y  = lookup_predict(alpha0, mach0);
D  = q * y(2);
T0 = D / cosd(alpha0);                 % thrust along the body x axis, N

theta0 = alpha0 * pi / 180;            % level flight: pitch = angle of attack (rad)
u0 = V0 * cosd(alpha0);                % starting body velocity, m/s
w0 = V0 * sind(alpha0);

fprintf('Trim angle of attack: %.3f deg\n', alpha0);
fprintf('CL = %.4f, CD = %.5f\n', y(1), y(2));
fprintf('Lift = %.2f N, Drag = %.3f N, Weight = %.2f N\n', q*y(1), D, W);
fprintf('Thrust T0 = %.3f N\n', T0);
fprintf('Start velocity [u0 0 w0] = [%.3f 0 %.3f] m/s, pitch theta0 = %.4f rad\n', u0, w0, theta0);

function r = trimResidual(a, mach, q, W)
    y = lookup_predict(a, mach);
    r = q * (y(1) + y(2) * tand(a)) - W;
end