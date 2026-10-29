% ========================================================================
% m30_wall_solveWallTransientGivenFlowProfile.m
% ========================================================================
function sim = m30_wall_solveWallTransientGivenFlowProfile(caseSpec, wall, weather, waterTable, cfg, flowProfile, strategyName)
% Solve coupled transient wall and pipe heat transfer for a prescribed flow profile.

t = weather.time(:);
nStep = numel(t);
N = wall.nNode;
dt = cfg.sim.timeStep_s;
A_wall = wall.area_m2;

Tnodes = zeros(nStep, N);
Tinner = zeros(nStep,1);
Touter = zeros(nStep,1);
TpipeNode = nan(nStep,1);
Tret = nan(nStep,1);
TwaterMean = nan(nStep,1);
Qpipe_W = zeros(nStep,1);
Qinner_W = zeros(nStep,1);
Qouter_W = zeros(nStep,1);
QouterConv_W = zeros(nStep,1);
QouterLW_W = zeros(nStep,1);
QouterSolar_W = zeros(nStep,1);
Qstorage_W = zeros(nStep,1);
Qbalance_W = zeros(nStep,1);
hInConv = zeros(nStep,1);
hInRad = zeros(nStep,1);
hInEq = zeros(nStep,1);
hOutConv = zeros(nStep,1);
hOutRad = zeros(nStep,1);
hOutEq = zeros(nStep,1);
TeqOut_C = zeros(nStep,1);
Tsky_C = zeros(nStep,1);
TradOut_C = zeros(nStep,1);
wallLoad_W = zeros(nStep,1);
COP_ref = weather.COP_ref(:);
E_wallHVAC_kWh_step = zeros(nStep,1);
E_pipePump_kWh_step = zeros(nStep,1);
E_total_kWh_step = zeros(nStep,1);
QpipeEff_W = zeros(nStep,1);
QpipeIneff_W = zeros(nStep,1);

mDot = flowProfile.mDot_kg_s(:);
velocity = flowProfile.velocity_m_s(:);
pumpStage = flowProfile.stage(:);
Tsup = caseSpec.supplyWater_C * ones(nStep,1);
if ~caseSpec.hasPipe
    Tsup(:) = NaN;
end

hyd = m50_hyd_calcHydraulicTimeSeries(caseSpec, wall, waterTable, cfg, mDot, Tsup, strategyName, flowProfile.designFlow_m3_s);
if caseSpec.hasPipe && isfield(hyd, 'mDot_limited_kg_s')
    mDot = hyd.mDot_limited_kg_s(:);
end
E_pipePump_kWh_step = hyd.P_pump_W .* dt / 3600 / 1000;

Told = m30_wall_initialTemperature(caseSpec, wall, weather, flowProfile, waterTable, cfg);

for kStep = 1:nStep
    Tin = weather.Tin_C(kStep);
    Tout = weather.Tout_C(kStep);
    DNI = weather.DNI_W_m2(kStep);
    DHI = weather.DHI_W_m2(kStep);
    wind = weather.windSpeed_m_s(kStep);
    Ivert = weather.I_vertical_W_m2(kStep);
    Tguess = Told;

    for iter = 1:cfg.sim.maxInnerIteration
        [TinSurf_guess, ToutSurf_guess] = m30_wall_calcSurfaceTemperaturesFromCenters(Tguess, Tin, Tout, wall, 3.0, 15.0, Tout);
        [hci, hri, hi] = m20_boundary_calcIndoorHTC(TinSurf_guess, Tin, cfg);
        outB = m20_boundary_calcOutdoorBoundary(ToutSurf_guess, Tout, wind, Ivert, cfg);
        [A, b, pipeInfo] = m30_wall_assembleImplicitSystem(Told, wall, Tin, hi, outB.TeqOut_C, outB.hEq, ...
            mDot(kStep), caseSpec.supplyWater_C, waterTable, cfg, dt);
        Tnew = A \ b;
        if max(abs(Tnew - Tguess)) < cfg.sim.tolerance_K
            Tguess = Tnew;
            break;
        end
        Tguess = Tnew;
    end

    Tnew = Tguess;
    [TinSurf, ToutSurf] = m30_wall_calcSurfaceTemperaturesFromCenters(Tnew, Tin, Tout, wall, hi, outB.hEq, outB.TeqOut_C);
    [hci, hri, hi] = m20_boundary_calcIndoorHTC(TinSurf, Tin, cfg);
    outB = m20_boundary_calcOutdoorBoundary(ToutSurf, Tout, wind, Ivert, cfg);
    [TinSurf, ToutSurf] = m30_wall_calcSurfaceTemperaturesFromCenters(Tnew, Tin, Tout, wall, hi, outB.hEq, outB.TeqOut_C);
    [~, ~, pipeInfo] = m30_wall_assembleImplicitSystem(Told, wall, Tin, hi, outB.TeqOut_C, outB.hEq, ...
        mDot(kStep), caseSpec.supplyWater_C, waterTable, cfg, dt);

    q_inner_to_indoor = hi * (TinSurf - Tin);
    q_outer_to_wall = outB.hEq * (outB.TeqOut_C - ToutSurf);
    q_outer_conv = outB.hConv * (Tout - ToutSurf);
    q_outer_lw = outB.hRad * (outB.TradOut_C - ToutSurf);
    q_outer_solar = cfg.material.outerSolarAbsorptance * Ivert;

    if caseSpec.hasPipe && mDot(kStep) > 0
        q_pipe_to_wall = pipeInfo.H_area_W_m2K * (caseSpec.supplyWater_C - Tnew(wall.pipeNodeIndex));
        wpNow = m50_hyd_getWaterProps(caseSpec.supplyWater_C, waterTable);
        Tret(kStep) = caseSpec.supplyWater_C - q_pipe_to_wall * A_wall / (mDot(kStep) * wpNow.cp);
        TwaterMean(kStep) = 0.5*(caseSpec.supplyWater_C + Tret(kStep));
        TpipeNode(kStep) = Tnew(wall.pipeNodeIndex);
    else
        q_pipe_to_wall = 0;
        Tret(kStep) = NaN;
        TwaterMean(kStep) = NaN;
        TpipeNode(kStep) = NaN;
    end

    q_storage = sum(wall.C_J_m2K .* (Tnew - Told)) / dt;
    q_balance = q_pipe_to_wall + q_outer_to_wall - q_inner_to_indoor - q_storage;

    Tnodes(kStep,:) = Tnew(:)';
    Tinner(kStep) = TinSurf;
    Touter(kStep) = ToutSurf;
    Qpipe_W(kStep) = q_pipe_to_wall * A_wall;
    Qinner_W(kStep) = q_inner_to_indoor * A_wall;
    Qouter_W(kStep) = q_outer_to_wall * A_wall;
    QouterConv_W(kStep) = q_outer_conv * A_wall;
    QouterLW_W(kStep) = q_outer_lw * A_wall;
    QouterSolar_W(kStep) = q_outer_solar * A_wall;
    Qstorage_W(kStep) = q_storage * A_wall;
    Qbalance_W(kStep) = q_balance * A_wall;
    hInConv(kStep) = hci;
    hInRad(kStep) = hri;
    hInEq(kStep) = hi;
    hOutConv(kStep) = outB.hConv;
    hOutRad(kStep) = outB.hRad;
    hOutEq(kStep) = outB.hEq;
    TeqOut_C(kStep) = outB.TeqOut_C;
    Tsky_C(kStep) = outB.Tsky_C;
    TradOut_C(kStep) = outB.TradOut_C;

    wallLoad_W(kStep) = m60_energy_calcSignedWallLoad(Qinner_W(kStep), caseSpec.season);
    E_wallHVAC_kWh_step(kStep) = wallLoad_W(kStep) / COP_ref(kStep) * dt / 3600 / 1000;
    E_total_kWh_step(kStep) = E_wallHVAC_kWh_step(kStep) + E_pipePump_kWh_step(kStep);

    [QpipeEff_W(kStep), QpipeIneff_W(kStep)] = m60_energy_pipeEffectiveIneffective(Qpipe_W(kStep), caseSpec.season, cfg.pipe.zeroHeatThreshold_W);

    Told = Tnew;
end

hourly = struct();
hourly.time = t;
if isfield(weather, 'isOfficial')
    hourly.isOfficial = logical(weather.isOfficial(:));
else
    hourly.isOfficial = true(numel(t),1);
end
hourly.Tout_C = weather.Tout_C(:);
hourly.RH_percent = weather.RH_percent(:);
hourly.windSpeed_m_s = weather.windSpeed_m_s(:);
hourly.DNI_W_m2 = weather.DNI_W_m2(:);
hourly.DHI_W_m2 = weather.DHI_W_m2(:);
hourly.I_vertical_W_m2 = weather.I_vertical_W_m2(:);
if isfield(weather, 'solarAltitude_deg'), hourly.solarAltitude_deg = weather.solarAltitude_deg(:); end
if isfield(weather, 'solarAzimuth_deg'), hourly.solarAzimuth_deg = weather.solarAzimuth_deg(:); end
if isfield(weather, 'solarCosIncidence'), hourly.solarCosIncidence = weather.solarCosIncidence(:); end
if isfield(weather, 'solarSunUpFlag'), hourly.solarSunUpFlag = weather.solarSunUpFlag(:); end
if isfield(weather, 'I_beam_vertical_W_m2'), hourly.I_beam_vertical_W_m2 = weather.I_beam_vertical_W_m2(:); end
if isfield(weather, 'I_diffuse_vertical_W_m2'), hourly.I_diffuse_vertical_W_m2 = weather.I_diffuse_vertical_W_m2(:); end
if isfield(weather, 'I_ground_vertical_W_m2'), hourly.I_ground_vertical_W_m2 = weather.I_ground_vertical_W_m2(:); end
if isfield(weather, 'GHI_reconstructed_W_m2'), hourly.GHI_reconstructed_W_m2 = weather.GHI_reconstructed_W_m2(:); end
hourly.TeqOut_ref_C = weather.TeqOut_ref_C(:);
hourly.Tin_C = weather.Tin_C(:);
hourly.COP_ref = COP_ref;
hourly.TeqOut_C = TeqOut_C;
hourly.Tsky_C = Tsky_C;
hourly.TradOut_C = TradOut_C;
hourly.hInConv_W_m2K = hInConv;
hourly.hInRad_W_m2K = hInRad;
hourly.hInEq_W_m2K = hInEq;
hourly.hOutConv_W_m2K = hOutConv;
hourly.hOutRad_W_m2K = hOutRad;
hourly.hOutEq_W_m2K = hOutEq;
hourly.T_innerSurface_C = Tinner;
hourly.T_outerSurface_C = Touter;
hourly.T_pipeNode_C = TpipeNode;
hourly.T_supply_C = Tsup;
hourly.T_return_C = Tret;
hourly.T_waterMean_C = TwaterMean;
hourly.mDot_kg_s = mDot;
hourly.flow_m3_h = hyd.flow_m3_h;
hourly.velocity_m_s = hyd.velocity_m_s;
hourly.pressureCalcVelocity_m_s = hyd.pressureCalcVelocity_m_s;
hourly.branchDesignHeadFlag = hyd.branchDesignHeadFlag;
hourly.parallelCircuitCount = hyd.parallelCircuitCount;
hourly.velocityLimitedFlag = hyd.velocityLimitedFlag;
hourly.Re = hyd.Re_branch;
hourly.specificPressureDrop_Pa_m = hyd.specificPressureDrop_branch_Pa_m;
hourly.pumpStage = pumpStage;
hourly.head_branch_m = hyd.head_branch_m;
hourly.head_common_m = hyd.head_common_m;
hourly.head_component_m = hyd.head_component_m;
hourly.head_effective_m = hyd.head_effective_m;
hourly.P_pump_W = hyd.P_pump_W;
hourly.E_pipePump_kWh_step = E_pipePump_kWh_step;
hourly.Source_flow_m3_h = hyd.Source_flow_m3_h;
hourly.Source_velocity_m_s = hyd.Source_velocity_m_s;
hourly.Source_Re = hyd.Source_Re;
hourly.Source_dp_friction_Pa = hyd.Source_dp_friction_Pa;
hourly.Source_dp_local_Pa = hyd.Source_dp_local_Pa;
hourly.Source_dp_accessory_Pa = hyd.Source_dp_accessory_Pa;
hourly.Source_dp_total_Pa = hyd.Source_dp_total_Pa;
hourly.Source_head_m = hyd.Source_head_m;
hourly.Source_dp_design_total_Pa = hyd.Source_dp_design_total_Pa;
hourly.Source_head_design_m = hyd.Source_head_design_m;
hourly.Source_dp_forPump_Pa = hyd.Source_dp_forPump_Pa;
hourly.Source_head_forPump_m = hyd.Source_head_forPump_m;
hourly.Source_useDesignHeadFlag = hyd.Source_useDesignHeadFlag;
hourly.P_pump_Source_W = hyd.Source_P_pump_W;
hourly.head_systemWithSource_calc_m = hyd.head_systemWithSource_calc_m;
hourly.head_systemWithSource_afterSafety_m = hyd.head_systemWithSource_afterSafety_m;
hourly.head_systemWithSource_effective_m = hyd.head_systemWithSource_effective_m;
hourly.dp_systemWithSource_used_Pa = hyd.dp_systemWithSource_used_Pa;
hourly.P_pump_systemWithSource_hydraulic_W = hyd.P_pump_systemWithSource_hydraulic_W;
hourly.P_pump_systemWithSource_W = hyd.P_pump_systemWithSource_W;
hourly.pumpMinimumPowerActiveFlag = hyd.pumpMinimumPowerActiveFlag;
hourly.Source_belowRecommendedVelocityFlag = hyd.Source_belowRecommendedVelocityFlag;
hourly.Source_aboveMaxVelocityFlag = hyd.Source_aboveMaxVelocityFlag;
hourly.E_SourcePump_kWh_step = hyd.Source_P_pump_W .* dt / 3600 / 1000;
hourly.E_systemPumpWithSource_hydraulic_kWh_step = hyd.P_pump_systemWithSource_hydraulic_W .* dt / 3600 / 1000;
hourly.E_systemPumpWithSource_kWh_step = hyd.P_pump_systemWithSource_W .* dt / 3600 / 1000;
hourly.Q_pipeToWall_W = Qpipe_W;
hourly.Q_pipeEffective_W = QpipeEff_W;
hourly.Q_pipeIneffective_W = QpipeIneff_W;
hourly.Q_innerToIndoor_W = Qinner_W;
hourly.Q_outerToWall_W = Qouter_W;
hourly.Q_outerConv_W = QouterConv_W;
hourly.Q_outerLW_W = QouterLW_W;
hourly.Q_outerSolar_W = QouterSolar_W;
hourly.Q_wallLoadSigned_W = wallLoad_W;
hourly.E_wallHVAC_signed_kWh_step = E_wallHVAC_kWh_step;
hourly.E_totalEquivalent_signed_kWh_step = E_total_kWh_step;
hourly.Q_wallStorage_W = Qstorage_W;
hourly.Q_wallEnergyResidual_W = Qbalance_W;
hourly.T_nodes_C = Tnodes;

summary = m60_energy_makeSummary(caseSpec, wall, strategyName, hourly, hyd, flowProfile, cfg);

sim = struct();
sim.caseSpec = caseSpec;
sim.strategy = strategyName;
sim.hourly = hourly;
sim.summary = summary;
sim.flowProfile = flowProfile;
sim.hydraulic = hyd;
end

% ======================================================================= %
