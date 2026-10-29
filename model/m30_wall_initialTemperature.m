% ========================================================================
% m30_wall_initialTemperature.m
% ========================================================================
function T0 = m30_wall_initialTemperature(caseSpec, wall, weather, flowProfile, waterTable, cfg)
% Initialize the wall temperature profile before transient integration.
Tin = weather.Tin_C(1);
Tout = weather.Tout_C(1);
T0 = linspace(Tin, Tout, wall.nNode)';
if wall.hasPipe && isfinite(caseSpec.supplyWater_C)
    idx = wall.pipeNodeIndex;
    T0(idx) = 0.7*T0(idx) + 0.3*caseSpec.supplyWater_C;
end
end

% ======================================================================= %
