% ========================================================================
% m50_hyd_selectCircuitCount.m
% ========================================================================
function [nCircuit, vBranch_m_s, velocityLimitedFlag, VdotLimited_m3_s] = m50_hyd_selectCircuitCount(VdotTotal_m3_s, cfg)
% Determine the number of parallel wall-side circuits under velocity constraints.
Di = cfg.pipe.innerDiameter_m;
Apipe = pi * Di^2 / 4;
minCircuit = max(1, round(cfg.pipe.parallelCircuitCount));
maxCircuit = max(minCircuit, round(cfg.pipe.maxParallelCircuitCount));
vMax = cfg.pipe.maxRunningVelocity_m_s;
velocityLimitedFlag = false;
VdotLimited_m3_s = VdotTotal_m3_s;

if VdotTotal_m3_s <= 0 || ~isfinite(VdotTotal_m3_s)
    nCircuit = minCircuit;
    vBranch_m_s = 0;
    return;
end

nNeed = ceil(VdotTotal_m3_s / max(Apipe * vMax, eps));
nCircuit = min(max(nNeed, minCircuit), maxCircuit);
vBranch_m_s = VdotTotal_m3_s / (Apipe * nCircuit);

if vBranch_m_s > vMax * (1 + 1.0e-9)
    VdotLimited_m3_s = Apipe * vMax * nCircuit;
    vBranch_m_s = vMax;
    velocityLimitedFlag = true;
end
end
