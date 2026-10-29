% ========================================================================
% m30_wall_pipeCouplingInfo.m
% ========================================================================
function pipeInfo = m30_wall_pipeCouplingInfo(wall, cfg, waterTable, Tsupply_C, mDot)
% Evaluate water-to-wall pipe heat transfer and NTU coupling quantities.
pipeInfo = struct();
pipeInfo.UA_total_W_K = 0;
pipeInfo.H_area_W_m2K = 0;
pipeInfo.NTU = 0;
pipeInfo.Treturn_C = NaN;
pipeInfo.qPipe_W_m2 = 0;
if ~wall.hasPipe || mDot <= 0 || ~isfinite(Tsupply_C)
    return;
end
wp = m50_hyd_getWaterProps(Tsupply_C, waterTable);
Di = cfg.pipe.innerDiameter_m;
Do = cfg.pipe.outerDiameter_m;
Acs = pi * Di^2 / 4;
VdotRaw = mDot / wp.rho;
[nCircuit, v, velocityLimitedFlag, VdotLimited] = m50_hyd_selectCircuitCount(VdotRaw, cfg);
mDot = VdotLimited * wp.rho;
Re = wp.rho * max(v,0) * Di / wp.mu;
if Re < 2300
    Nu = cfg.pipe.NuLaminar;
else
    Nu = 0.023 * Re^0.8 * wp.Pr^0.4;
end
hWater = Nu * wp.k / Di;
Rconv = 1 / (hWater*pi*Di);
Rpipe = log(Do/Di) / (2*pi*cfg.pipe.pipeWallConductivity_W_mK);
s = cfg.pipe.spacing_m;
kConc = cfg.material.concrete.k;
Rspread = log(max(s/(pi*Do), 1.01)) / (2*pi*kConc);
Rtotal_per_m = Rconv + Rpipe + Rspread;
UA_per_m = 1 / Rtotal_per_m;
UA_total = UA_per_m * wall.pipeTotalLength_m;
NTU = UA_total / max(mDot * wp.cp, eps);
H_total = mDot * wp.cp * (1 - exp(-NTU));
pipeInfo.UA_total_W_K = UA_total;
pipeInfo.H_area_W_m2K = H_total / wall.area_m2;
pipeInfo.NTU = NTU;
pipeInfo.Re_pipe = Re;
pipeInfo.hWater_W_m2K = hWater;
pipeInfo.parallelCircuitCount = nCircuit;
pipeInfo.velocity_m_s = v;
pipeInfo.velocityLimitedFlag = velocityLimitedFlag;
end
