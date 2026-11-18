function y = truth_predict(alpha, mach)
% Truth reference: interpolates ALL XFOIL data, including the near-stall points
% (15.5 to 18 deg) that neither the GP nor the lookup was trained on.
persistent FL FD FM
if isempty(FL)
    d1 = readtable('naca0012_data.csv');
    d2 = readtable('naca0012_hi_test.csv');
    A = [d1.Alpha; d2.Alpha];
    M = [d1.Mach;  d2.Mach];
    FL = scatteredInterpolant(A, M, [d1.CL; d2.CL], 'linear', 'nearest');
    FD = scatteredInterpolant(A, M, [d1.CD; d2.CD], 'linear', 'nearest');
    FM = scatteredInterpolant(A, M, [d1.CM; d2.CM], 'linear', 'nearest');
end
y = [FL(alpha, mach), FD(alpha, mach), FM(alpha, mach)];
end