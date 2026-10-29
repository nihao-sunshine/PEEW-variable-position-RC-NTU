% ========================================================================
% m50_hyd_calcEquivalentSourceHydraulicOneStep.m
% ========================================================================
function sourceHyd = m50_hyd_calcEquivalentSourceHydraulicOneStep(cfg, wp, flow_m3_s)
% Evaluate equivalent source-side friction, minor and accessory pressure losses.
D_m = cfg.sourceSide.pipeInnerDiameter_m;
L_m = cfg.sourceSide.pipeLength_m;
eps_m = cfg.sourceSide.roughness_m;
rho = wp.rho;
mu = wp.mu;
area_m2 = pi * D_m^2 / 4.0;

velocityRaw_m_s = flow_m3_s / max(area_m2, eps);
if cfg.sourceSide.enforceMinVelocity
    velocity_m_s = max(velocityRaw_m_s, cfg.sourceSide.recommendedVelocity_m_s);
else
    velocity_m_s = max(velocityRaw_m_s, 0.0);
end
flowUsed_m3_s = velocity_m_s * area_m2;

[dpFriction_Pa, dpLocal_Pa, dpAccessory_Pa, dpTotal_Pa, head_m, Re, lambda] = ...
    localCalcSourcePressure(cfg, rho, mu, D_m, L_m, eps_m, velocity_m_s, flowUsed_m3_s, true);
pumpPower_W = dpTotal_Pa * flowUsed_m3_s / max(cfg.pump.efficiency, eps);

velocityDesign_m_s = cfg.sourceSide.designVelocity_m_s;
flowDesign_m3_s = velocityDesign_m_s * area_m2;
[dpFrictionDesign_Pa, dpLocalDesign_Pa, dpAccessoryDesign_Pa, dpDesignTotal_Pa, headDesign_m, ReDesign, lambdaDesign] = ...
    localCalcSourcePressure(cfg, rho, mu, D_m, L_m, eps_m, velocityDesign_m_s, flowDesign_m3_s, false);

useDesignHead = isfield(cfg.sourceSide,'useDesignPressureDropForPump') && cfg.sourceSide.useDesignPressureDropForPump;
if isfield(cfg.sourceSide,'pressureDropMode') && strcmpi(cfg.sourceSide.pressureDropMode,'actual_flow')
    useDesignHead = false;
end
if useDesignHead
    dpForPump_Pa = dpDesignTotal_Pa;
    headForPump_m = headDesign_m;
else
    dpForPump_Pa = dpTotal_Pa;
    headForPump_m = head_m;
end

sourceHyd.flow_m3_s = flowUsed_m3_s;
sourceHyd.flow_m3_h = flowUsed_m3_s * 3600.0;
sourceHyd.velocity_raw_m_s = velocityRaw_m_s;
sourceHyd.velocity_m_s = velocity_m_s;
sourceHyd.Re = Re;
sourceHyd.lambda = lambda;
sourceHyd.dpFriction_Pa = dpFriction_Pa;
sourceHyd.dpLocal_Pa = dpLocal_Pa;
sourceHyd.dpAccessory_Pa = dpAccessory_Pa;
sourceHyd.dpTotal_Pa = dpTotal_Pa;
sourceHyd.head_m = head_m;
sourceHyd.pumpPower_W = pumpPower_W;

sourceHyd.designVelocity_m_s = velocityDesign_m_s;
sourceHyd.designFlow_m3_s = flowDesign_m3_s;
sourceHyd.designFlow_m3_h = flowDesign_m3_s * 3600.0;
sourceHyd.ReDesign = ReDesign;
sourceHyd.lambdaDesign = lambdaDesign;
sourceHyd.dpFrictionDesign_Pa = dpFrictionDesign_Pa;
sourceHyd.dpLocalDesign_Pa = dpLocalDesign_Pa;
sourceHyd.dpAccessoryDesign_Pa = dpAccessoryDesign_Pa;
sourceHyd.dpDesignTotal_Pa = dpDesignTotal_Pa;
sourceHyd.headDesign_m = headDesign_m;

sourceHyd.dpForPump_Pa = dpForPump_Pa;
sourceHyd.headForPump_m = headForPump_m;
sourceHyd.useDesignHeadFlag = double(useDesignHead);
sourceHyd.belowRecommendedVelocityFlag = flowUsed_m3_s > 0 && velocity_m_s < cfg.sourceSide.recommendedVelocity_m_s;
sourceHyd.aboveMaxVelocityFlag = flowUsed_m3_s > 0 && velocity_m_s > cfg.sourceSide.maxVelocity_m_s;
end

function [dpFriction_Pa, dpLocal_Pa, dpAccessory_Pa, dpTotal_Pa, head_m, Re, lambda] = localCalcSourcePressure(cfg, rho, mu, D_m, L_m, eps_m, velocity_m_s, flow_m3_s, scaleAccessoryByFlow)
Re = rho * velocity_m_s * D_m / max(mu, eps);
if Re <= 0
    lambda = 0.0;
elseif Re < 2300
    lambda = 64.0 / Re;
else
    lambda = 0.25 / (log10(eps_m/(3.7*D_m) + 5.74/(Re^0.9)))^2;
end
qDyn_Pa = rho * velocity_m_s^2 / 2.0;
dpFriction_Pa = lambda * L_m / D_m * qDyn_Pa;
dpLocal_Pa = cfg.sourceSide.zetaTotal * qDyn_Pa;
designFlow_m3_s = cfg.sourceSide.designVelocity_m_s * (pi * D_m^2 / 4.0);
if scaleAccessoryByFlow && cfg.sourceSide.scaleAccessoryPressureDropByFlow
    flowRatio = flow_m3_s / max(designFlow_m3_s, eps);
    dpAccessory_Pa = cfg.sourceSide.accessoryPressureDropDesign_Pa * flowRatio^2;
else
    dpAccessory_Pa = cfg.sourceSide.accessoryPressureDropDesign_Pa;
end
dpTotal_Pa = dpFriction_Pa + dpLocal_Pa + dpAccessory_Pa;
head_m = dpTotal_Pa / max(rho * 9.80665, eps);
end
