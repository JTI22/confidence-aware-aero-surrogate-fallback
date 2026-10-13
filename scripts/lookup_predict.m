function y = lookup_predict(alpha, mach)
% Trusted fallback: interpolate the XFOIL table, hold the edge value outside it
persistent FL FD FM
if isempty(FL)
    d  = readtable('naca0012_data.csv');
    FL = scatteredInterpolant(d.Alpha, d.Mach, d.CL, 'linear', 'nearest');
    FD = scatteredInterpolant(d.Alpha, d.Mach, d.CD, 'linear', 'nearest');
    FM = scatteredInterpolant(d.Alpha, d.Mach, d.CM, 'linear', 'nearest');
end
y = [FL(alpha, mach), FD(alpha, mach), FM(alpha, mach)];
end