% ========================================================================
% m50_hyd_calcHydraulicTimeSeries.m
% ========================================================================
function hyd = m50_hyd_calcHydraulicTimeSeries(caseSpec, wall, waterTable, cfg, mDot_kg_s, Tsupply_C, strategyName, designFlow_m3_s)
% Compute time-varying wall-side and source-side hydraulic power and electricity.
n = numel(mDot_kg_s);
fields = {'flow_m3_h','velocity_m_s','pressureCalcVelocity_m_s','branchDesignHeadFlag','Re_branch','specificPressureDrop_branch_Pa_m', ...
    'head_branch_m','head_common_m','head_component_m','head_system_m','head_afterSafety_m', ...
    'head_effective_m','P_pump_W','parallelCircuitCount','velocityLimitedFlag','mDot_limited_kg_s', ...
    'Source_flow_m3_h','Source_velocity_m_s','Source_Re','Source_lambda','Source_dp_friction_Pa','Source_dp_local_Pa', ...
    'Source_dp_accessory_Pa','Source_dp_total_Pa','Source_head_m','Source_P_pump_W','Source_dp_design_total_Pa','Source_head_design_m', ...
    'Source_dp_forPump_Pa','Source_head_forPump_m','Source_useDesignHeadFlag','P_pump_systemWithSource_hydraulic_W','P_pump_systemWithSource_W', ...
    'head_systemWithSource_calc_m','head_systemWithSource_afterSafety_m','head_systemWithSource_effective_m','dp_systemWithSource_used_Pa', ...
    'pumpMinimumPowerActiveFlag','Source_belowRecommendedVelocityFlag','Source_aboveMaxVelocityFlag'};
for f = 1:numel(fields)
    hyd.(fields{f}) = zeros(n,1);
end
hyd.frictionFlag = strings(n,1);
if ~caseSpec.hasPipe
    return;
end

for k = 1:n
    mDot = mDot_kg_s(k);
    if mDot <= 0
        hyd.frictionFlag(k) = "no_flow";
        continue;
    end
    Tref = Tsupply_C(min(k,numel(Tsupply_C)));
    wp = m50_hyd_getWaterProps(Tref, waterTable);
    VdotRaw = mDot / wp.rho;
    [nCircuit, vBranch, velocityLimitedFlag, Vdot] = m50_hyd_selectCircuitCount(VdotRaw, cfg);
    mDot = Vdot * wp.rho;
    VdotBranch = Vdot / nCircuit;
    Di = cfg.pipe.innerDiameter_m;
    Abranch = pi*Di^2/4;
    branchDesignHeadFlag = false;
    vPressure = vBranch;
    if isfield(cfg.pipe,'useMaxVelocityForBranchedPressureDrop') && cfg.pipe.useMaxVelocityForBranchedPressureDrop
        if nCircuit > max(1,round(cfg.pipe.parallelCircuitCount)) || velocityLimitedFlag
            vPressure = cfg.pipe.maxRunningVelocity_m_s;
            branchDesignHeadFlag = true;
        end
    end
    [PdBranch, ReBranch, flag] = m50_hyd_specificPressureDropByFormula(wp.rho, wp.mu, Di, vPressure);
    Lbranch = wall.pipeTotalLength_m / nCircuit;
    LbranchTotal = Lbranch * (1 + cfg.pump.localLengthRatio);
    dpBranch = PdBranch * LbranchTotal;
    headBranch = dpBranch / (wp.rho * 9.80665);

    Dcom = cfg.pump.commonInnerDiameter_m;
    Acom = pi*Dcom^2/4;
    vCom = Vdot / Acom;
    PdCom = m50_hyd_specificPressureDropByFormula(wp.rho, wp.mu, Dcom, vCom);
    dpCommon = PdCom * cfg.pump.commonEquivalentLength_m;
    headCommon = dpCommon / (wp.rho * 9.80665);

    if strcmpi(cfg.pump.componentFlowRefMode, 'design_flow') && designFlow_m3_s > 0
        flowRef = designFlow_m3_s;
    else
        flowRef = max(Vdot, eps);
    end
    dpComp = cfg.pump.componentPressureDropRef_kPa*1000 * (Vdot/max(flowRef,eps))^2;
    headComp = dpComp / (wp.rho * 9.80665);

    headSystem = headBranch + headCommon + headComp;
    headAfterSafety = cfg.pump.safetyFactor * headSystem;
    headEff = max(headAfterSafety, cfg.pump.minHead_m);
    Ppump = wp.rho * 9.80665 * Vdot * headEff / cfg.pump.efficiency;

    hyd.flow_m3_h(k) = Vdot * 3600;
    hyd.velocity_m_s(k) = vBranch;
    hyd.pressureCalcVelocity_m_s(k) = vPressure;
    hyd.branchDesignHeadFlag(k) = double(branchDesignHeadFlag);
    hyd.parallelCircuitCount(k) = nCircuit;
    hyd.velocityLimitedFlag(k) = double(velocityLimitedFlag);
    hyd.mDot_limited_kg_s(k) = mDot;
    hyd.Re_branch(k) = ReBranch;
    hyd.specificPressureDrop_branch_Pa_m(k) = PdBranch;
    hyd.head_branch_m(k) = headBranch;
    hyd.head_common_m(k) = headCommon;
    hyd.head_component_m(k) = headComp;
    hyd.head_system_m(k) = headSystem;
    hyd.head_afterSafety_m(k) = headAfterSafety;
    hyd.head_effective_m(k) = headEff;
    hyd.P_pump_W(k) = Ppump;

    if isfield(cfg, 'sourceSide') && cfg.sourceSide.enable && cfg.sourceSide.includeInSystemPump
        sourceHyd = m50_hyd_calcEquivalentSourceHydraulicOneStep(cfg, wp, Vdot);
        hyd.Source_flow_m3_h(k) = sourceHyd.flow_m3_h;
        hyd.Source_velocity_m_s(k) = sourceHyd.velocity_m_s;
        hyd.Source_Re(k) = sourceHyd.Re;
        hyd.Source_lambda(k) = sourceHyd.lambda;
        hyd.Source_dp_friction_Pa(k) = sourceHyd.dpFriction_Pa;
        hyd.Source_dp_local_Pa(k) = sourceHyd.dpLocal_Pa;
        hyd.Source_dp_accessory_Pa(k) = sourceHyd.dpAccessory_Pa;
        hyd.Source_dp_total_Pa(k) = sourceHyd.dpTotal_Pa;
        hyd.Source_head_m(k) = sourceHyd.head_m;
        hyd.Source_P_pump_W(k) = sourceHyd.pumpPower_W;
        hyd.Source_dp_design_total_Pa(k) = sourceHyd.dpDesignTotal_Pa;
        hyd.Source_head_design_m(k) = sourceHyd.headDesign_m;
        hyd.Source_dp_forPump_Pa(k) = sourceHyd.dpForPump_Pa;
        hyd.Source_head_forPump_m(k) = sourceHyd.headForPump_m;
        hyd.Source_useDesignHeadFlag(k) = sourceHyd.useDesignHeadFlag;
        headSystemWithSourceCalc = headSystem + sourceHyd.headForPump_m;
        headSystemWithSourceAfterSafety = cfg.pump.safetyFactor * headSystemWithSourceCalc;
        headSystemWithSourceEff = max(headSystemWithSourceAfterSafety, cfg.pump.minHead_m);
        dpSystemWithSourceUsed = headSystemWithSourceEff * wp.rho * 9.80665;
        PpumpSystemHydraulic = dpSystemWithSourceUsed * Vdot / max(cfg.pump.efficiency, eps);
        PpumpSystemFinal = PpumpSystemHydraulic;
        minPowerActive = false;
        if isfield(cfg.pump,'enableMinimumElectricPower') && cfg.pump.enableMinimumElectricPower && Vdot > 0
            if PpumpSystemFinal < cfg.pump.minimumElectricPower_W
                PpumpSystemFinal = cfg.pump.minimumElectricPower_W;
                minPowerActive = true;
            end
        end
        hyd.head_systemWithSource_calc_m(k) = headSystemWithSourceCalc;
        hyd.head_systemWithSource_afterSafety_m(k) = headSystemWithSourceAfterSafety;
        hyd.head_systemWithSource_effective_m(k) = headSystemWithSourceEff;
        hyd.dp_systemWithSource_used_Pa(k) = dpSystemWithSourceUsed;
        hyd.P_pump_systemWithSource_hydraulic_W(k) = PpumpSystemHydraulic;
        hyd.P_pump_systemWithSource_W(k) = PpumpSystemFinal;
        hyd.pumpMinimumPowerActiveFlag(k) = double(minPowerActive);
        hyd.Source_belowRecommendedVelocityFlag(k) = double(sourceHyd.belowRecommendedVelocityFlag);
        hyd.Source_aboveMaxVelocityFlag(k) = double(sourceHyd.aboveMaxVelocityFlag);
    else
        hyd.head_systemWithSource_calc_m(k) = headSystem;
        hyd.head_systemWithSource_afterSafety_m(k) = headAfterSafety;
        hyd.head_systemWithSource_effective_m(k) = headEff;
        hyd.dp_systemWithSource_used_Pa(k) = headEff * wp.rho * 9.80665;
        hyd.P_pump_systemWithSource_hydraulic_W(k) = hyd.P_pump_W(k);
        hyd.P_pump_systemWithSource_W(k) = hyd.P_pump_W(k);
    end

    hyd.frictionFlag(k) = flag;
end
end
