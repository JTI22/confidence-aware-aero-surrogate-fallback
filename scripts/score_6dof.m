% ---- Score the three 6DOF runs against the locked limits (run ONCE) ----
mdl = 'aircraft_6dof_gp';
load_system(mdl);

set_param([mdl '/Constant2'], 'Value', '25');   % alpha = 25 deg

% Turn on data logging for the three Scopes
scopes = {'Scope', 'Scope1', 'Scope2'};
for k = 1:numel(scopes)
    set_param([mdl '/' scopes{k}], 'DataLogging', 'on', ...
        'DataLoggingVariableName', ['log_' scopes{k}], ...
        'DataLoggingSaveFormat', 'Structure with time');
end

tq = (0:0.1:10)';
alt = zeros(numel(tq), 3);
spd = zeros(numel(tq), 3);
pitchMax = zeros(1, 3);

for m = 1:3
    set_param([mdl '/Constant'], 'Value', num2str(m));   % mode
    out = sim(mdl);

    pos = out.get('log_Scope');     % X_e (position)
    vel = out.get('log_Scope2');    % V_e (velocity)
    ang = out.get('log_Scope1');    % roll, pitch, yaw (rad)

    [t1, i1] = unique(pos.time);
    alt(:, m) = -interp1(t1, pos.signals.values(i1, 3), tq);   % up = positive

    [t2, i2] = unique(vel.time);
    v = vel.signals.values(i2, :);
    spd(:, m) = interp1(t2, sqrt(sum(v.^2, 2)), tq);

    pitchMax(m) = max(abs(ang.signals.values(:, 2))) * 180/pi;
end

names = ["Run 1 lookup only", "Run 2 GP no guard", "Run 3 GP + fallback"];
fprintf('\nLimits: pitch <= 30 deg, altitude within 10 m of Run 1, airspeed within 20%% of Run 1\n');
fprintf('(Limit 2, angle of attack, is not scored: alpha is fixed at 25 deg in all runs.)\n\n');

for m = 1:3
    altDiff = max(abs(alt(:, m) - alt(:, 1)));
    spdDiff = max(abs(spd(:, m) - spd(:, 1)) ./ spd(:, 1)) * 100;
    p1 = pitchMax(m) <= 30;
    p3 = altDiff <= 10;
    p4 = spdDiff <= 20;
    fprintf('%s\n', names(m));
    fprintf('  Max pitch: %.2f deg           -> %s\n', pitchMax(m), passfail(p1));
    fprintf('  Max altitude diff: %.1f m     -> %s\n', altDiff, passfail(p3));
    fprintf('  Max airspeed diff: %.1f %%     -> %s\n\n', spdDiff, passfail(p4));
end

set_param([mdl '/Constant'], 'Value', '3');   % leave the model in mode 3

function s = passfail(ok)
    if ok, s = 'PASS'; else, s = 'FAIL'; end
end