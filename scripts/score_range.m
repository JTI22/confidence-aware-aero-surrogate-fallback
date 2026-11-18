% ---- Range rule test (rules: docs/range_rule_rules.md) ----
% Test A (gust) and Test B (trim runaway) in five modes:
% 0 truth, 1 lookup only, 2 GP only, 3 GP + gate, 4 range rule. Run ONCE.
mdl = 'aircraft_6dof_cl';
load_system(mdl);
if exist('range_test_output.txt', 'file'), delete('range_test_output.txt'); end
diary('range_test_output.txt');

scopes = {'Scope', 'Scope1', 'Scope2'};
for k = 1:numel(scopes)
    set_param([mdl '/' scopes{k}], 'DataLogging', 'on', ...
        'DataLoggingVariableName', ['log_' scopes{k}], ...
        'DataLoggingSaveFormat', 'Structure with time');
end

%         name         fault settings          run time  fixed step
tests = { 'A_gust',    '[10 2 0.5 0 0 1]',    20,       0.005;
          'B_runaway', '[0 0 1 0.065 5 30]',  90,       0.01 };
modeNames = {'0 truth', '1 lookup only', '2 GP only', '3 GP + gate', '4 range rule'};
nM = numel(modeNames);

% Earlier results for modes 0-3 (docs/fault_test_output.txt):
% [max pitch (deg), max altitude diff (m), peak alpha (deg), time above 15 deg (s)]
ref = struct( ...
    'A_gust',    [  8.6  0.00  18.16  0.15;   8.4  2.39  18.06  0.15;   8.3  2.85  17.89  0.15;   8.4  2.28  18.04  0.15], ...
    'B_runaway', [ 25.1  0.00  16.94 58.67;  25.8 10.49  18.12 58.97; 179.8 62.59 162.82 34.75;  26.1 10.47  18.14 58.92]);
fmt = {'%.1f', '%.2f', '%.2f', '%.2f'};

for k = 1:size(tests,1)
    tname = tests{k,1};  tEnd = tests{k,3};
    set_param([mdl '/fault_const'], 'Value', tests{k,2});
    set_param(mdl, 'SolverType', 'Fixed-step', 'Solver', 'ode4', ...
        'FixedStep', num2str(tests{k,4}), 'StopTime', num2str(tEnd));

    tq = (0:0.05:tEnd)';
    alt = zeros(numel(tq), nM); spd = alt; pit = alt; alp = alt; gat = alt;

    for m = 0:nM-1
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

    pMax  = max(abs(pit));
    aDiff = max(abs(alt - alt(:,1)));
    sDiff = max(abs(spd - spd(:,1)) ./ spd(:,1)) * 100;
    aPeak = max(alp);
    tHigh = trapz(tq, double(alp > 15));
    refuse     = trapz(tq, double(gat < 0.5));
    refuseHigh = trapz(tq, double(gat < 0.5 & alp > 15));

    fprintf('\n===== Test %s (%d s), compared with the truth run =====\n', tname, tEnd);

    % Repeat check: modes 0-3 must match the earlier run
    R = ref.(tname);
    now4 = [pMax(1:4)' aDiff(1:4)' aPeak(1:4)' tHigh(1:4)'];
    ok = true;
    for m = 1:4
        for j = 1:4
            a = sprintf(fmt{j}, now4(m,j));  b = sprintf(fmt{j}, R(m,j));
            if ~strcmp(a, b)
                ok = false;
                fprintf('REPEAT CHECK: mode %d, value %d is %s, earlier %s\n', m-1, j, a, b);
            end
        end
    end
    if ok
        fprintf('Repeat check: modes 0-3 match docs/fault_test_output.txt\n');
        nShow = nM;
    else
        fprintf('Repeat check FAILED. Mode 4 is not reported (docs/range_rule_rules.md).\n');
        nShow = 4;
    end

    fprintf('Limits: pitch within +-30 deg, altitude within 10 m of truth, airspeed within 20%% of truth\n');
    if aPeak(1) > 18
        fprintf('VALIDITY: the truth run went above 18 deg (max %.2f). Truth is outside its data there.\n', aPeak(1));
    end
    for c = 1:nShow
        fprintf('Mode %s\n', modeNames{c});
        fprintf('  Max pitch %.1f deg -> %s | Max altitude diff %.2f m -> %s | Max speed diff %.1f %% -> %s\n', ...
            pMax(c), pf(pMax(c) <= 30), aDiff(c), pf(aDiff(c) <= 10), sDiff(c), pf(sDiff(c) <= 20));
        fprintf('  Peak alpha %.2f deg, time above 15 deg %.2f s\n', aPeak(c), tHigh(c));
    end
    fprintf('Gate (mode 3) refused the GP for %.2f s (%.2f s while alpha > 15 deg)\n', refuse(4), refuseHigh(4));
    if ok
        fprintf('Range rule (mode 4) refused the GP for %.2f s (%.2f s while alpha > 15 deg)\n', refuse(5), refuseHigh(5));
        fprintf('Refusal time, mode 4 minus mode 3: %.2f s\n', refuse(5) - refuse(4));
    end

    % ---- Plot ----
    figure('Position', [100 100 900 800]);
    lbl = {'Altitude (m)', 'Total speed (m/s)', 'Angle of attack (deg)', 'Pitch (deg)'};
    dat = {alt, spd, alp, pit};
    sty = {'k-', 'b-', 'r-', 'g--', 'm:'};
    for p = 1:4
        subplot(4,1,p); hold on;
        for c = 1:nShow
            plot(tq, dat{p}(:,c), sty{c}, 'LineWidth', 1.5);
        end
        if p == 3, yline(15, ':', '15 deg (edge of training data)'); end
        grid on; ylabel(lbl{p});
        if p == 1, title(['Range rule test ' strrep(tname, '_', ' ')]); legend(modeNames(1:nShow), 'Location', 'best'); end
    end
    xlabel('Time (s)');
    saveas(gcf, ['range_' tname '.png']);
    fprintf('saved range_%s.png\n', tname);
end

diary off;

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