% ========================================================================
% m60_energy_makeSummary.m
% ========================================================================
function summary = m60_energy_makeSummary(caseSpec, wall, strategyName, hourly, hyd, flowProfile, cfg)
% Aggregate transient quantities into heating-season performance results.
%% m60_energy_makeSummary

if isfield(hourly, 'isOfficial')
    officialMask = logical(hourly.isOfficial(:));
    hourly = m90_util_subsetHourlyByMask(hourly, officialMask);
    hyd = m90_util_subsetHourlyByMask(hyd, officialMask);
    if isfield(flowProfile, 'stage') && numel(flowProfile.stage) == numel(officialMask)
        flowProfile.stage = flowProfile.stage(officialMask);
    end
end

dt_h = cfg.sim.timeStep_s/3600;
kWh = @(W) sum(W(:))*dt_h/1000;
posKWh = @(W) sum(max(W(:),0))*dt_h/1000;
negKWh = @(W) sum(min(W(:),0))*dt_h/1000;
absKWh = @(W) sum(abs(W(:)))*dt_h/1000;

summary = m60_energy_emptySummaryRow();
summary.caseName = string(caseSpec.caseName);
summary.wallType = string(caseSpec.wallType);
summary.wallTypeCN = string(caseSpec.wallTypeCN);
summary.strategy = string(strategyName);
summary.season = string(caseSpec.season);
summary.wallAzimuth_deg = cfg.wall.azimuth_deg;
summary.wallTilt_deg = cfg.wall.tilt_deg;
summary.wallOrientationCN = string(cfg.wall.orientationCN);
summary.wallOrientationTag = string(cfg.wall.orientationTag);
summary.Tin_C = caseSpec.Tin_C;
summary.waterSupply_C = caseSpec.supplyWater_C;
summary.innerInsulation_mm = caseSpec.innerInsulation_mm;
summary.outerInsulation_mm = caseSpec.outerInsulation_mm;
summary.referenceInsulation_mm = caseSpec.referenceInsulation_mm;
summary.pipeCenterDepth_mm = wall.pipeCenterDepth_m*1000;
summary.wallThickness_mm = wall.thickness_m*1000;
summary.wallArea_m2 = wall.area_m2;
summary.pipeActive = caseSpec.hasPipe;
summary.hasPipeGeometryFlag = caseSpec.hasPipe;
summary.pipeTotalLength_m = wall.pipeTotalLength_m;

summary.mDot_mean_kg_s = mean(hourly.mDot_kg_s,'omitnan');
summary.mDot_max_kg_s = max(hourly.mDot_kg_s,[],'omitnan');
summary.flow_mean_m3_h = mean(hourly.flow_m3_h,'omitnan');
summary.velocity_mean_m_s = mean(hourly.velocity_m_s,'omitnan');
summary.velocity_max_m_s = max(hourly.velocity_m_s,[],'omitnan');
if isfield(hourly,'pressureCalcVelocity_m_s')
    summary.pressureCalcVelocity_mean_m_s = mean(hourly.pressureCalcVelocity_m_s,'omitnan');
    summary.pressureCalcVelocity_max_m_s = max(hourly.pressureCalcVelocity_m_s,[],'omitnan');
else
    summary.pressureCalcVelocity_mean_m_s = summary.velocity_mean_m_s;
    summary.pressureCalcVelocity_max_m_s = summary.velocity_max_m_s;
end
if isfield(hourly,'branchDesignHeadFlag')
    summary.branchDesignHeadHours_h = sum(hourly.branchDesignHeadFlag > 0)*dt_h;
    summary.branchDesignHeadFlag = any(hourly.branchDesignHeadFlag > 0);
else
    summary.branchDesignHeadHours_h = 0;
    summary.branchDesignHeadFlag = false;
end
if isfield(hourly,'parallelCircuitCount')
    summary.parallelCircuitCount_mean = mean(hourly.parallelCircuitCount,'omitnan');
    summary.parallelCircuitCount_max = max(hourly.parallelCircuitCount,[],'omitnan');
else
    summary.parallelCircuitCount_mean = cfg.pipe.parallelCircuitCount;
    summary.parallelCircuitCount_max = cfg.pipe.parallelCircuitCount;
end
if isfield(hourly,'velocityLimitedFlag')
    summary.velocityLimitedHours_h = sum(hourly.velocityLimitedFlag > 0)*dt_h;
    summary.velocityLimitedFlag = any(hourly.velocityLimitedFlag > 0);
else
    summary.velocityLimitedHours_h = 0;
    summary.velocityLimitedFlag = false;
end
summary.pipeFlowActiveFlag = caseSpec.hasPipe && summary.mDot_max_kg_s > 0;
summary.velocityBelow025Flag = summary.velocity_mean_m_s < cfg.pipe.minRunningVelocity_m_s - 1.0e-9 && caseSpec.hasPipe;
summary.velocityAbove080Flag = summary.velocity_max_m_s > cfg.pipe.maxDiagnosticVelocity_m_s;
summary.Re_mean = mean(hourly.Re,'omitnan');
summary.specificPressureDrop_mean_Pa_m = mean(hourly.specificPressureDrop_Pa_m,'omitnan');
summary.head_branch_mean_m = mean(hourly.head_branch_m,'omitnan');
summary.head_common_mean_m = mean(hourly.head_common_m,'omitnan');
summary.head_component_mean_m = mean(hourly.head_component_m,'omitnan');
summary.head_effective_mean_m = mean(hourly.head_effective_m,'omitnan');
summary.head_effective_max_m = max(hourly.head_effective_m,[],'omitnan');
summary.pumpEfficiency = cfg.pump.efficiency;
summary.P_pump_mean_W = mean(hourly.P_pump_W,'omitnan');
summary.P_pump_max_W = max(hourly.P_pump_W,[],'omitnan');
summary.E_pipePump_kWh = sum(hourly.E_pipePump_kWh_step,'omitnan');
if isfield(hourly,'P_pump_Source_W')
    summary.Source_enableFlag = isfield(cfg,'sourceSide') && cfg.sourceSide.enable;
    summary.Source_pipeInnerDiameter_mm = cfg.sourceSide.pipeInnerDiameter_m * 1000;
    summary.Source_pipeLength_m = cfg.sourceSide.pipeLength_m;
    summary.Source_zetaTotal = cfg.sourceSide.zetaTotal;
    summary.Source_accessoryPressureDropDesign_kPa = cfg.sourceSide.accessoryPressureDropDesign_Pa / 1000;
    summary.Source_designVelocity_m_s = cfg.sourceSide.designVelocity_m_s;
    summary.Source_pressureDropMode = string(cfg.sourceSide.pressureDropMode);
    summary.Source_useDesignPressureDropForPumpFlag = cfg.sourceSide.useDesignPressureDropForPump;
    summary.Source_enforceMinVelocityFlag = cfg.sourceSide.enforceMinVelocity;
    summary.Source_flow_mean_m3_h = mean(hourly.Source_flow_m3_h,'omitnan');
    summary.Source_velocity_mean_m_s = mean(hourly.Source_velocity_m_s,'omitnan');
    summary.Source_velocity_min_m_s = min(hourly.Source_velocity_m_s(hourly.Source_flow_m3_h>0),[],'omitnan');
    if isempty(summary.Source_velocity_min_m_s) || ~isfinite(summary.Source_velocity_min_m_s)
        summary.Source_velocity_min_m_s = 0;
    end
    summary.Source_velocity_max_m_s = max(hourly.Source_velocity_m_s,[],'omitnan');
    summary.Source_Re_mean = mean(hourly.Source_Re(hourly.Source_flow_m3_h>0),'omitnan');
    summary.Source_Re_min = min(hourly.Source_Re(hourly.Source_flow_m3_h>0),[],'omitnan');
    if isempty(summary.Source_Re_min) || ~isfinite(summary.Source_Re_min)
        summary.Source_Re_min = 0;
    end
    summary.Source_dp_friction_mean_kPa = mean(hourly.Source_dp_friction_Pa,'omitnan') / 1000;
    summary.Source_dp_local_mean_kPa = mean(hourly.Source_dp_local_Pa,'omitnan') / 1000;
    summary.Source_dp_accessory_mean_kPa = mean(hourly.Source_dp_accessory_Pa,'omitnan') / 1000;
    summary.Source_dp_total_mean_kPa = mean(hourly.Source_dp_total_Pa,'omitnan') / 1000;
    summary.Source_dp_total_max_kPa = max(hourly.Source_dp_total_Pa,[],'omitnan') / 1000;
    summary.Source_dp_design_total_kPa = mean(hourly.Source_dp_design_total_Pa,'omitnan') / 1000;
    summary.Source_head_design_m = mean(hourly.Source_head_design_m,'omitnan');
    summary.Source_dp_forPump_mean_kPa = mean(hourly.Source_dp_forPump_Pa,'omitnan') / 1000;
    summary.Source_head_forPump_mean_m = mean(hourly.Source_head_forPump_m,'omitnan');
    summary.Source_useDesignHeadFlag = any(hourly.Source_useDesignHeadFlag > 0);
    summary.Source_head_mean_m = mean(hourly.Source_head_m,'omitnan');
    summary.Source_head_max_m = max(hourly.Source_head_m,[],'omitnan');
    summary.P_pump_Source_mean_W = mean(hourly.P_pump_Source_W,'omitnan');
    summary.P_pump_Source_max_W = max(hourly.P_pump_Source_W,[],'omitnan');
    summary.E_SourcePump_kWh = sum(hourly.E_SourcePump_kWh_step,'omitnan');
    summary.head_systemWithSource_calc_mean_m = mean(hourly.head_systemWithSource_calc_m,'omitnan');
    summary.head_systemWithSource_calc_max_m = max(hourly.head_systemWithSource_calc_m,[],'omitnan');
    summary.head_systemWithSource_afterSafety_mean_m = mean(hourly.head_systemWithSource_afterSafety_m,'omitnan');
    summary.head_systemWithSource_effective_mean_m = mean(hourly.head_systemWithSource_effective_m,'omitnan');
    summary.head_systemWithSource_effective_max_m = max(hourly.head_systemWithSource_effective_m,[],'omitnan');
    summary.dp_systemWithSource_used_mean_kPa = mean(hourly.dp_systemWithSource_used_Pa,'omitnan') / 1000;
    summary.dp_systemWithSource_used_max_kPa = max(hourly.dp_systemWithSource_used_Pa,[],'omitnan') / 1000;
    summary.E_systemPumpWithSource_hydraulic_kWh = sum(hourly.E_systemPumpWithSource_hydraulic_kWh_step,'omitnan');
    summary.E_systemPumpWithSource_kWh = sum(hourly.E_systemPumpWithSource_kWh_step,'omitnan');
    summary.pumpMinimumElectricPower_W = cfg.pump.minimumElectricPower_W;
    summary.pumpMinimumPowerActiveHours_h = sum(hourly.pumpMinimumPowerActiveFlag > 0) * dt_h;
    summary.P_pump_systemWithSource_hydraulic_mean_W = mean(hourly.P_pump_systemWithSource_hydraulic_W,'omitnan');
    summary.P_pump_systemWithSource_mean_W = mean(hourly.P_pump_systemWithSource_W,'omitnan');
    summary.P_pump_systemWithSource_max_W = max(hourly.P_pump_systemWithSource_W,[],'omitnan');
    summary.Source_hoursBelowRecommendedVelocity_h = sum(hourly.Source_belowRecommendedVelocityFlag > 0) * dt_h;
    operatingSourceHours_h = sum(hourly.Source_flow_m3_h > 0) * dt_h;
    summary.Source_ratioBelowRecommendedVelocity_percent = 100 * summary.Source_hoursBelowRecommendedVelocity_h / max(operatingSourceHours_h, eps);
    summary.Source_hoursAboveMaxVelocity_h = sum(hourly.Source_aboveMaxVelocityFlag > 0) * dt_h;
else
    summary.Source_enableFlag = false;
    summary.Source_pressureDropMode = "none";
    summary.Source_useDesignPressureDropForPumpFlag = false;
    summary.Source_useDesignHeadFlag = false;
    summary.E_SourcePump_kWh = 0;
    summary.head_systemWithSource_calc_mean_m = summary.head_effective_mean_m;
    summary.head_systemWithSource_calc_max_m = summary.head_effective_max_m;
    summary.head_systemWithSource_afterSafety_mean_m = summary.head_effective_mean_m;
    summary.head_systemWithSource_effective_mean_m = summary.head_effective_mean_m;
    summary.head_systemWithSource_effective_max_m = summary.head_effective_max_m;
    summary.dp_systemWithSource_used_mean_kPa = NaN;
    summary.dp_systemWithSource_used_max_kPa = NaN;
    summary.E_systemPumpWithSource_hydraulic_kWh = summary.E_pipePump_kWh;
    summary.E_systemPumpWithSource_kWh = summary.E_pipePump_kWh;
    summary.pumpMinimumElectricPower_W = cfg.pump.minimumElectricPower_W;
    summary.pumpMinimumPowerActiveHours_h = 0;
end

if isfield(flowProfile,'rawDesignMDot_kg_s')
    summary.S1_rawDesignMDot_kg_s = flowProfile.rawDesignMDot_kg_s;
else
    summary.S1_rawDesignMDot_kg_s = NaN;
end
if isfield(flowProfile,'rawDesignVelocity_m_s')
    summary.S1_rawDesignVelocity_m_s = flowProfile.rawDesignVelocity_m_s;
else
    summary.S1_rawDesignVelocity_m_s = NaN;
end
if isfield(flowProfile,'designMDot_kg_s')
    summary.S1_finalDesignMDot_kg_s = flowProfile.designMDot_kg_s;
else
    summary.S1_finalDesignMDot_kg_s = NaN;
end
if isfield(flowProfile,'designVelocity_m_s')
    summary.S1_finalDesignVelocity_m_s = flowProfile.designVelocity_m_s;
else
    summary.S1_finalDesignVelocity_m_s = NaN;
end
if isfield(flowProfile,'minVelocityAppliedFlag')
    summary.S1_minVelocityAppliedFlag = flowProfile.minVelocityAppliedFlag;
else
    summary.S1_minVelocityAppliedFlag = false;
end
if isfield(flowProfile,'maxVelocityLimitedFlag')
    summary.S1_maxVelocityLimitedFlag = flowProfile.maxVelocityLimitedFlag;
else
    summary.S1_maxVelocityLimitedFlag = false;
end
if isfield(flowProfile,'parallelCircuitCount')
    summary.S1_finalParallelCircuitCount = flowProfile.parallelCircuitCount;
else
    summary.S1_finalParallelCircuitCount = NaN;
end
if isfield(flowProfile,'zeroDesignLoadFlag')
    summary.S1_zeroDesignLoadFlag = flowProfile.zeroDesignLoadFlag;
else
    summary.S1_zeroDesignLoadFlag = false;
end

summary.Q_pipe_signed_kWh = kWh(hourly.Q_pipeToWall_W);
summary.Q_pipe_effective_signed_kWh = kWh(hourly.Q_pipeEffective_W);
summary.Q_pipe_ineffective_signed_kWh = kWh(hourly.Q_pipeIneffective_W);
summary.Q_pipe_effective_abs_kWh = absKWh(hourly.Q_pipeEffective_W);
summary.Q_pipe_ineffective_abs_kWh = absKWh(hourly.Q_pipeIneffective_W);
summary.Q_pipe_max_W = max(hourly.Q_pipeToWall_W,[],'omitnan');
summary.Q_pipe_min_W = min(hourly.Q_pipeToWall_W,[],'omitnan');
summary.Q_pipe_absMax_W = max(abs(hourly.Q_pipeToWall_W),[],'omitnan');
qEffAbs = summary.Q_pipe_effective_abs_kWh;
qIneffAbs = summary.Q_pipe_ineffective_abs_kWh;
summary.pipeEffectiveRatio_percent = 100*qEffAbs/max(qEffAbs+qIneffAbs, eps);
summary.pipeIneffectiveRatio_percent = 100*qIneffAbs/max(qEffAbs+qIneffAbs, eps);
summary.pipeEffectiveHours_h = sum(abs(hourly.Q_pipeEffective_W) >= cfg.pipe.zeroHeatThreshold_W)*dt_h;
summary.pipeIneffectiveHours_h = sum(abs(hourly.Q_pipeIneffective_W) >= cfg.pipe.zeroHeatThreshold_W)*dt_h;
summary.pipeZeroHeatHours_h = sum(abs(hourly.Q_pipeToWall_W) < cfg.pipe.zeroHeatThreshold_W)*dt_h;

summary.Q_innerToIndoor_signed_kWh = kWh(hourly.Q_innerToIndoor_W);
summary.Q_innerToIndoor_positive_kWh = posKWh(hourly.Q_innerToIndoor_W);
summary.Q_innerToIndoor_negative_kWh = negKWh(hourly.Q_innerToIndoor_W);
summary.Q_innerToIndoor_max_W = max(hourly.Q_innerToIndoor_W,[],'omitnan');
summary.Q_innerToIndoor_min_W = min(hourly.Q_innerToIndoor_W,[],'omitnan');
summary.Q_innerToIndoor_absMax_W = max(abs(hourly.Q_innerToIndoor_W),[],'omitnan');
summary.Q_outerToWall_signed_kWh = kWh(hourly.Q_outerToWall_W);
summary.Q_outerToWall_positive_kWh = posKWh(hourly.Q_outerToWall_W);
summary.Q_outerToWall_negative_kWh = negKWh(hourly.Q_outerToWall_W);
summary.Q_outerToWall_max_W = max(hourly.Q_outerToWall_W,[],'omitnan');
summary.Q_outerToWall_min_W = min(hourly.Q_outerToWall_W,[],'omitnan');
summary.Q_outerToWall_absMax_W = max(abs(hourly.Q_outerToWall_W),[],'omitnan');
summary.Q_wallLoad_signed_kWh = kWh(hourly.Q_wallLoadSigned_W);
summary.Q_wallLoad_positive_kWh = posKWh(hourly.Q_wallLoadSigned_W);
summary.Q_wallLoad_negative_kWh = negKWh(hourly.Q_wallLoadSigned_W);
summary.COP_ref_mean = mean(hourly.COP_ref,'omitnan');
summary.COP_ref_min = min(hourly.COP_ref,[],'omitnan');
summary.COP_ref_max = max(hourly.COP_ref,[],'omitnan');
posMaskCOP = hourly.Q_wallLoadSigned_W > cfg.pipe.zeroHeatThreshold_W;
negMaskCOP = hourly.Q_wallLoadSigned_W < -cfg.pipe.zeroHeatThreshold_W;
summary.COP_ref_wallLoadPositive_mean = mean(hourly.COP_ref(posMaskCOP),'omitnan');
summary.COP_ref_wallLoadNegative_mean = mean(hourly.COP_ref(negMaskCOP),'omitnan');
summary.COP_ref_seasonal = summary.Q_wallLoad_positive_kWh / max(sum(max(hourly.E_wallHVAC_signed_kWh_step,0),'omitnan'), eps);
summary.E_wallHVAC_signed_kWh = sum(hourly.E_wallHVAC_signed_kWh_step,'omitnan');
summary.E_wallHVAC_positive_kWh = sum(max(hourly.E_wallHVAC_signed_kWh_step,0),'omitnan');
summary.E_wallHVAC_negative_kWh = sum(min(hourly.E_wallHVAC_signed_kWh_step,0),'omitnan');
summary.E_totalEquivalent_signed_kWh = summary.E_wallHVAC_signed_kWh + summary.E_pipePump_kWh;
summary.E_totalEquivalent_withSource_signed_kWh = summary.E_wallHVAC_signed_kWh + summary.E_systemPumpWithSource_kWh;
summary.SPF_pipeEffective_byPump = summary.Q_pipe_effective_abs_kWh / max(summary.E_pipePump_kWh, eps);
summary.SPF_pipeEffective_bySystemPumpWithSource = summary.Q_pipe_effective_abs_kWh / max(summary.E_systemPumpWithSource_kWh, eps);
summary.SPF_totalEquivalent_positive = summary.Q_wallLoad_positive_kWh / max(summary.E_wallHVAC_positive_kWh + summary.E_pipePump_kWh, eps);
summary.SPF_totalEquivalent_positive_withSource = summary.Q_wallLoad_positive_kWh / max(summary.E_wallHVAC_positive_kWh + summary.E_systemPumpWithSource_kWh, eps);
summary.wallEnergyBalanceResidual_kWh = kWh(hourly.Q_wallEnergyResidual_W);
summary.wallEnergyBalanceResidualAbs_kWh = absKWh(hourly.Q_wallEnergyResidual_W);
refAbs = absKWh(hourly.Q_pipeToWall_W) + absKWh(hourly.Q_outerToWall_W) + absKWh(hourly.Q_innerToIndoor_W) + absKWh(hourly.Q_wallStorage_W);
summary.wallEnergyBalanceResidualRatio_percent = 100*summary.wallEnergyBalanceResidualAbs_kWh / max(refAbs, eps);

if strcmp(strategyName, 'S2') && isfield(flowProfile, 'stage')
    summary.S2_stageCollapsedFlag = flowProfile.stageCollapsedFlag;
    summary.stage1Hours_h = sum(flowProfile.stage==1)*dt_h;
    summary.stage2Hours_h = sum(flowProfile.stage==2)*dt_h;
    summary.stage3Hours_h = sum(flowProfile.stage==3)*dt_h;
    if isfield(flowProfile,'stageFlow_m3_h')
        summary.stage1Flow_m3_h = flowProfile.stageFlow_m3_h(1);
        summary.stage2Flow_m3_h = flowProfile.stageFlow_m3_h(2);
        summary.stage3Flow_m3_h = flowProfile.stageFlow_m3_h(3);
    end
else
    summary.S2_stageCollapsedFlag = false;
    summary.stage1Hours_h = NaN;
    summary.stage2Hours_h = NaN;
    summary.stage3Hours_h = NaN;
    summary.stage1Flow_m3_h = NaN;
    summary.stage2Flow_m3_h = NaN;
    summary.stage3Flow_m3_h = NaN;
end
end
