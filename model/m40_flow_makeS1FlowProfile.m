% ========================================================================
% m40_flow_makeS1FlowProfile.m
% ========================================================================
function fp = m40_flow_makeS1FlowProfile(caseSpec, wall, weather, waterTable, cfg, Qdesign_W) %#ok<INUSD>
% Calculate the operating flow profile subject to wall-side velocity constraints.
n = numel(weather.time);
wp = m50_hyd_getWaterProps(caseSpec.supplyWater_C, waterTable);
Apipe = pi * cfg.pipe.innerDiameter_m^2 / 4;
minVelocity = cfg.pipe.minRunningVelocity_m_s;
VdotMin = Apipe * minVelocity * cfg.pipe.parallelCircuitCount;
VdotMax = Apipe * cfg.pipe.maxRunningVelocity_m_s * cfg.pipe.maxParallelCircuitCount;
mDotMin = wp.rho * VdotMin;

if Qdesign_W <= 0
    mDotRaw = 0;
    VdotRaw = 0;
    velocityRaw = 0;
else
    mDotRaw = Qdesign_W / (wp.cp * cfg.pipe.designDeltaT_K);
    VdotRaw = mDotRaw / wp.rho;
    velocityRaw = VdotRaw / (Apipe * cfg.pipe.parallelCircuitCount);
end

if velocityRaw < minVelocity
    VdotFinal = VdotMin;
    minVelocityAppliedFlag = true;
else
    VdotFinal = VdotRaw;
    minVelocityAppliedFlag = false;
end
maxVelocityLimitedFlag = VdotFinal > VdotMax;
VdotFinal = min(VdotFinal, VdotMax);
mDotFinal = wp.rho * VdotFinal;
[nCircuitFinal, velocityFinal] = m50_hyd_selectCircuitCount(VdotFinal, cfg);

fp = struct();
fp.strategy = 'S1';
fp.mDot_kg_s = mDotFinal * ones(n,1);
fp.velocity_m_s = velocityFinal * ones(n,1);
fp.stage = ones(n,1);
fp.designFlow_m3_s = VdotFinal;
fp.designMDot_kg_s = mDotFinal;
fp.designVelocity_m_s = velocityFinal;
fp.rawDesignFlow_m3_s = VdotRaw;
fp.rawDesignMDot_kg_s = mDotRaw;
fp.rawDesignVelocity_m_s = velocityRaw;
fp.minRunningVelocity_m_s = minVelocity;
fp.minVelocityAppliedFlag = minVelocityAppliedFlag;
fp.maxVelocityLimitedFlag = maxVelocityLimitedFlag;
fp.parallelCircuitCount = nCircuitFinal;
fp.zeroDesignLoadFlag = Qdesign_W <= 0;
fp.stageRatios = 1;
fp.stageCollapsedFlag = false;
end
