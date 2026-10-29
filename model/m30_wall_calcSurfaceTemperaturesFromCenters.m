% ========================================================================
% m30_wall_calcSurfaceTemperaturesFromCenters.m
% ========================================================================
function [Tsi, Tso] = m30_wall_calcSurfaceTemperaturesFromCenters(Tc, Tin_C, Tout_C, wall, hIn, hOut, TeqOut_C)
% Derive wall surface temperatures from adjacent control-volume temperatures.
if nargin < 5 || ~isfinite(hIn) || hIn <= 0, hIn = 3.0; end
if nargin < 6 || ~isfinite(hOut) || hOut <= 0, hOut = 15.0; end
if nargin < 7 || ~isfinite(TeqOut_C), TeqOut_C = Tout_C; end
GcondIn = wall.k_W_mK(1) / (wall.dx_m(1)/2);
Tsi = (hIn*Tin_C + GcondIn*Tc(1)) / (hIn + GcondIn);
GcondOut = wall.k_W_mK(end) / (wall.dx_m(end)/2);
Tso = (hOut*TeqOut_C + GcondOut*Tc(end)) / (hOut + GcondOut);
end
