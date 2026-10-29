% ========================================================================
% m50_hyd_specificPressureDropByFormula.m
% ========================================================================
function [Pd, Re, flag] = m50_hyd_specificPressureDropByFormula(rho, mu, d, v)
% Evaluate pipe pressure loss and Reynolds number.
if v <= 0
    Pd = 0; Re = 0; flag = "no_flow"; return;
end
Re = rho*v*d/mu;
if Re < 2300
    Pd = 32*mu*v/(d^2);
    flag = "laminar";
else
    Pd = 0.158 * rho^0.75 * mu^0.25 * d^(-1.25) * v^1.75;
    flag = "transition_or_turbulent_blasius";
end
end

% ======================================================================= %
