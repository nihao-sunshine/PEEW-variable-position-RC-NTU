% ========================================================================
% m40_flow_makeFixedVelocityFlowProfile.m
% ========================================================================
function fp = m40_flow_makeFixedVelocityFlowProfile(caseSpec, wall, weather, waterTable, cfg, velocity_m_s, strategyName)
% Generate a fixed-velocity pipe flow profile.
n = numel(weather.time);
wp = m50_hyd_getWaterProps(caseSpec.supplyWater_C, waterTable);
Apipe = pi * cfg.pipe.innerDiameter_m^2 / 4;
Vdot = Apipe * velocity_m_s * cfg.pipe.parallelCircuitCount;
mDot = wp.rho * Vdot;
fp = struct();
fp.strategy = strategyName;
fp.mDot_kg_s = mDot * ones(n,1);
fp.velocity_m_s = velocity_m_s * ones(n,1);
fp.stage = ones(n,1);
fp.designFlow_m3_s = Vdot;
fp.designMDot_kg_s = mDot;
fp.designVelocity_m_s = velocity_m_s;
fp.stageRatios = 1;
fp.stageCollapsedFlag = false;
end
