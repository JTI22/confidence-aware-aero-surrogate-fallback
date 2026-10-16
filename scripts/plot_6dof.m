% ---- Plot altitude and airspeed for the three 6DOF runs (alpha = 25 deg) ----
% Same settings as score_6dof.m. This script only draws the figure.
mdl = 'aircraft_6dof_gp';
load_system(mdl);

set_param([mdl '/Constant2'], 'Value', '25');   % alpha = 25 deg

scopes = {'Scope', 'Scope1', 'Scope2'};
for k = 1:numel(scopes)
    set_param([mdl '/' scopes{k}], 'DataLogging', 'on', ...
        'DataLoggingVariableName', ['log_' scopes{k}], ...
        'DataLoggingSaveFormat', 'Structure with time');
end

tq  = (0:0.1:10)';
alt = zeros(numel(tq), 3);
spd = zeros(numel(tq), 3);

for m = 1:3
    set_param([mdl '/Constant'], 'Value', num2str(m));   % mode
    out = sim(mdl);

    pos = out.get('log_Scope');     % X_e (position)
    vel = out.get('log_Scope2');    % V_e (velocity)

    [t1, i1] = unique(pos.time);
    alt(:, m) = -interp1(t1, pos.signals.values(i1, 3), tq);

    [t2, i2] = unique(vel.time);
    v = vel.signals.values(i2, :);
    spd(:, m) = interp1(t2, sqrt(sum(v.^2, 2)), tq);
end

set_param([mdl '/Constant'], 'Value', '3');   % leave the model in mode 3

names = {'Run 1: lookup only (reference)', 'Run 2: GP, no guard', 'Run 3: GP + fallback'};
styles = {'-', '-', '--'};
cols = {[0 0.45 0.74], [0.85 0.33 0.1], [0.47 0.67 0.19]};

figure('Position', [100 100 900 600]);

subplot(2,1,1); hold on;
for m = 1:3
    plot(tq, alt(:, m), styles{m}, 'Color', cols{m}, 'LineWidth', 2);
end
grid on;
ylabel('Altitude gain (m)');
title('6DOF test at alpha = 25 deg (outside the training data)');
legend(names, 'Location', 'northwest');

subplot(2,1,2); hold on;
for m = 1:3
    plot(tq, spd(:, m), styles{m}, 'Color', cols{m}, 'LineWidth', 2);
end
grid on;
xlabel('Time (s)');
ylabel('Total speed (m/s)');

saveas(gcf, 'sixdof_comparison.png');
disp('saved sixdof_comparison.png')