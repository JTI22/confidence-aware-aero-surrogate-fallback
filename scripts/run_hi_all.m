% ---- Run the 15.5 to 18 deg sweep for Mach 0.1 to 0.4 ----
machs = [0.1 0.2 0.3 0.4];
for m = machs
    tag     = sprintf('%02d', round(m*10));
    cmdFile = ['run_hi_m' tag '.txt'];
    outFile = ['run1/hi_m' tag '.txt'];

    if exist(outFile, 'file')
        error('%s already exists. Stopping so XFOIL does not append to it.', outFile);
    end

    cmds = {'NACA 0012','PANE','OPER','VISC 1000000', sprintf('MACH %g', m), ...
            'ITER 200','PACC', outFile, '', 'ASEQ 15.5 18 0.5', '', 'QUIT'};
    fid = fopen(cmdFile, 'w');
    fprintf(fid, '%s\n', cmds{:});
    fclose(fid);

    system(['xfoil < ' cmdFile ' > xfoil_log_hi_m' tag '.txt']);

    T = readmatrix(outFile, 'NumHeaderLines', 12);
    fprintf('Mach %.1f: %d rows written (expected 6)\n', m, size(T,1));
end