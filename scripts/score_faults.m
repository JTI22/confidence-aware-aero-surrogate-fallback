% ---- Fault tests: gust and slow trim runaway (rules: docs/fault_test_rules.md) ----
% Runs each test once in four modes: 0 truth, 1 lookup, 2 GP only, 3 GP + gate. Run ONCE.
% Solver: fixed-step ode4 (the variable-step solver stalled near the gust and near stall).
mdl = 'aircraft_6dof_cl';
load_system(mdl);

% Record the three Scopes (Scope = position, Scope1 = angles, Scope2 = velocity)
scopes = {'Scope', 'Scope1', 'Scope2'};
for k = 1:numel(scopes)
    set_param([mdl '/' scopes{k}], 'DataLogging', 'on', ...
        'DataLoggingVariableName', ['log_' scopes{k}], ...
        'DataLoggingSaveFormat', 'Structure with time');
end

%         name         fault settings          run time  fixed step
tests = { 'A_gust',    '[10 2 0.5 0 0 1]',    20,       0.005;
          'B_runaway', '[0 0 1 0.065 5 30]',  90,       0.01 };
modeNames = {'0 truth', '1 lookup only', '2 GP only', '3 GP + gate'};

for k = 1:size(tests,1)
    tname = tests{k,1};  tEnd = tests{k,3};
    set_param([mdl '/fault_const'], 'Value', tests{k,2});
    set_param(mdl, 'SolverType', 'Fixed-step', 'Solver', 'ode4', ...
        'FixedStep', num2str(tests{k,4}), 'StopTime', num2str(tEnd));

    tq = (0:0.05:tEnd)';
    alt = zeros(numel(tq),4); spd = alt; pit = alt; alp = alt; gat = alt;

    for m = 0:3
        set_param([mdl '/mode_const'], 'Value', num2str(m));
        tic;
        out = sim(mdl);
        pos = out.get('log_Scope');  ang = out.get('log_Scope1');  vel = out.get('log_Scope2');
        al  = out.get('alpha_log');  gt  = out.get('gate_log');
        alt(:,m+1) = -resample1(pos.time, pos.signals.values(:,3), tq);
        v = vel.signals.values;
        spd(:,m+1) = resample1(vel.time, sqrt(sum(v.^2, 2)), tq);
        pit(:,m+1) = resample1(ang.time, ang.signals.values(:,2), tq) * 180/pi;
        alp(:,m+1) = resample1(al.time, al.signals.values(:), tq);
        gat(:,m+1) = resample1(gt.time, gt.signals.values(:), tq);
        fprintf('%s, mode %d finished (%.0f s)\n', tname, m, toc);
    end

    fprintf('\n===== Test %s (%d s), compared with the truth run =====\n', tname, tEnd);
    fprintf('Limits: pitch within +-30 deg, altitude within 10 m of truth, airspeed within 20%% of truth\n');
    if max(alp(:,1)) > 18
        fprintf('VALIDITY: the truth run went above 18 deg (max %.2f). Truth is outside its data there.\n', max(alp(:,1)));
    end
    for m = 0:3
        c = m + 1;
        pMax  = max(abs(pit(:,c)));
        aDiff = max(abs(alt(:,c) - alt(:,1)));
        sDiff = max(abs(spd(:,c) - spd(:,1)) ./ spd(:,1)) * 100;
        tHigh = trapz(tq, double(alp(:,c) > 15));
        fprintf('Mode %s\n', modeNames{c});
        fprintf('  Max pitch %.1f deg -> %s | Max altitude diff %.2f m -> %s | Max speed diff %.1f %% -> %s\n', ...
            pMax, pf(pMax <= 30), aDiff, pf(aDiff <= 10), sDiff, pf(sDiff <= 20));
        fprintf('  Peak alpha %.2f deg, time above 15 deg %.2f s\n', max(alp(:,c)), tHigh);
        if m == 3
            fprintf('  Gate refused the GP for %.2f s in total (%.2f s while alpha > 15 deg)\n', ...
                trapz(tq, double(gat(:,c) < 0.5)), trapz(tq, double(gat(:,c) < 0.5 & alp(:,c) > 15)));
        end
    end

    % ---- Plot ----
    figure('Position', [100 100 900 800]);
    lbl = {'Altitude (m)', 'Total speed (m/s)', 'Angle of attack (deg)', 'Pitch (deg)'};
    dat = {alt, spd, alp, pit};
    sty = {'k-', 'b-', 'r-', 'g--'};
    for p = 1:4
        subplot(4,1,p); hold on;
        for c = 1:4
            plot(tq, dat{p}(:,c), sty{c}, 'LineWidth', 1.5);
        end
        if p == 3, yline(15, ':', '15 deg (edge of training data)'); end
        grid on; ylabel(lbl{p});
        if p == 1, title(['Fault test ' strrep(tname, '_', ' ')]); legend(modeNames, 'Location', 'best'); end
    end
    xlabel('Time (s)');
    saveas(gcf, ['fault_' tname '.png']);
    fprintf('saved fault_%s.png\n', tname);
end

% Leave the model in normal flight with the automatic solver
set_param([mdl '/mode_const'], 'Value', '3');
set_param([mdl '/fault_const'], 'Value', '[0 0 1 0 0 1]');
set_param(mdl, 'SolverType', 'Variable-step', 'Solver', 'VariableStepAuto', 'StopTime', '10');

function y = resample1(t, x, tq)
    [t, i] = unique(t);
    y = interp1(t, x(i), tq, 'linear', 'extrap');
end

function s = pf(ok)
    if ok, s = 'PASS'; else, s = 'FAIL'; end
end