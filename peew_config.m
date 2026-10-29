function cfg = peew_config(root, cityRow, azimuth)
% Minimal physical settings. Most values are preserved from the supplied research code.
% NOTE: Source-side hydraulic settings are the original code implementation.
cfg = struct();
cfg.path.weatherFile = fullfile(root, 'inputs', 'weather', char(cityRow.weather_file));
cfg.path.waterFile = fullfile(root, 'inputs', 'water', 'WX20260408.mat');
cfg.season.heating.start = datetime(char(cityRow.heating_start), 'InputFormat','yyyy-MM-dd');
cfg.season.heating.end = datetime(char(cityRow.heating_end_exclusive),'InputFormat','yyyy-MM-dd');
% Legacy weather module requires cooling date fields even for heating-only runs.
cfg.season.cooling.start = cfg.season.heating.start;
cfg.season.cooling.end = cfg.season.heating.end;
cfg.case.heatingTin_C = 18;
cfg.case.heatingSupply_C = [5 7.5 10 12.5 15 17.5];
cfg.case.A_totalIns_mm = cityRow.insulation_mm;
cfg.case.A_innerIns_mm = 0:5:(5*floor(cityRow.insulation_mm/5));
cfg.case.B_outerIns_mm = cityRow.insulation_mm;
cfg.case.C_referenceIns_mm = cityRow.insulation_mm;
cfg.wall.azimuth_deg = azimuth;
cfg.site.latitude_deg = cityRow.latitude_deg;
cfg.site.longitude_deg = cityRow.longitude_deg;
cfg.sim.timeStep_s = 1200;
cfg.sim.warmupDays = 7;
cfg.sim.maxInnerIteration = 30;
cfg.sim.tolerance_K = 1.0e-4;
cfg.wall.height_m = 3.0;
cfg.wall.width_m = 5.0;
cfg.wall.area_m2 = cfg.wall.height_m * cfg.wall.width_m;
cfg.wall.tilt_deg = 90.0;
cfg.material.inner_plaster.k = 0.93;
cfg.material.inner_plaster.rho = 1800;
cfg.material.inner_plaster.cp = 837;
cfg.material.outer_plaster = cfg.material.inner_plaster;
cfg.material.brick.k = 0.81;
cfg.material.brick.rho = 1800;
cfg.material.brick.cp = 1050;
cfg.material.concrete.k = 1.51;
cfg.material.concrete.rho = 2400;
cfg.material.concrete.cp = 920;
cfg.material.insulation.k = 0.065;
cfg.material.insulation.rho = 250;
cfg.material.insulation.cp = 670; % J/(kg K)
cfg.material.pipe.k = 0.40;
% Documented material properties from the uploaded MATLAB source.
% The current 1D solver uses pipe conductivity but not pipe density/heat capacity.
cfg.material.pipe.rho = 950;
cfg.material.pipe.cp = 2300;
cfg.material.innerSurfaceEmissivity = 0.90;
cfg.material.outerSurfaceEmissivity = 0.90;
cfg.material.indoorRadiantEnvironmentEmissivity = 0.90;
cfg.material.outerSolarAbsorptance = 0.60;
cfg.pipe.innerDiameter_m = 0.012;
cfg.pipe.outerDiameter_m = 0.016;
cfg.pipe.pipeWallConductivity_W_mK = cfg.material.pipe.k;
cfg.pipe.spacing_m = 0.20;
cfg.pipe.parallelCircuitCount = 1;
cfg.pipe.fixedVelocity_m_s = 0.25;
cfg.pipe.minRunningVelocity_m_s = 0.25;
cfg.pipe.maxRunningVelocity_m_s = 0.50;
cfg.pipe.maxParallelCircuitCount = 3;
cfg.pipe.useMaxVelocityForBranchedPressureDrop = true;
cfg.pipe.maxDiagnosticVelocity_m_s = cfg.pipe.maxRunningVelocity_m_s;
cfg.pipe.designDeltaT_K = 5.0;
cfg.pipe.zeroHeatThreshold_W = 1.0;
cfg.pipe.NuLaminar = 3.66;
cfg.pump.efficiency = 0.45;
cfg.pump.minHead_m = 2.0;
cfg.pump.safetyFactor = 1.10;
cfg.pump.localLengthRatio = 0.30;
cfg.pump.commonEquivalentLength_m = 30.0;
cfg.pump.commonInnerDiameter_m = 0.020;
cfg.pump.componentPressureDropRef_kPa = 5.0;
cfg.pump.componentFlowRefMode = 'design_flow';
% The source-side circuit is a hydraulic equivalent, independent of heat-source type.
% Only the internal diameter and equivalent flow length are needed for its pipe resistance.
cfg.sourceSide.enable = true;
cfg.sourceSide.pipeInnerDiameter_m = 0.020;           % 20 mm (exact hydraulic diameter)
cfg.sourceSide.pipeLength_m = 200.0;                 % 200 m equivalent total flow length
cfg.sourceSide.roughness_m = 1.5e-6;                % m
cfg.sourceSide.designVelocity_m_s = 0.50;          % m/s, design pressure-loss basis
cfg.sourceSide.enforceMinVelocity = false;
cfg.sourceSide.recommendedVelocity_m_s = 0.50;
cfg.sourceSide.maxVelocity_m_s = 1.20;
cfg.sourceSide.zetaBends = 2.0;                   % equivalent bend/local resistance
cfg.sourceSide.zetaConnections = 4.0;             % equivalent connection/local resistance
cfg.sourceSide.zetaAllowance = 2.0;               % equivalent additional local resistance
cfg.sourceSide.zetaTotal = cfg.sourceSide.zetaBends + ...
    cfg.sourceSide.zetaConnections + cfg.sourceSide.zetaAllowance;
cfg.sourceSide.accessoryPressureDropDesign_Pa = 10000.0;  % 10 kPa
cfg.sourceSide.scaleAccessoryPressureDropByFlow = true;
cfg.sourceSide.pressureDropMode = 'design_head';
cfg.sourceSide.useDesignPressureDropForPump = true;
cfg.sourceSide.includeInSystemPump = true;
cfg.pump.enableMinimumElectricPower = true;
cfg.pump.minimumElectricPower_W = 4;
cfg.site.timeZone_hours = 8;
cfg.solar.groundReflectance = 0.20;
cfg.outdoorConvection.minWindSpeed_m_s = 0.10;
cfg.energy.refTerminal.heatingSupply_C = 45;
cfg.energy.refTerminal.heatingReturn_C = 40;
cfg.energy.refTerminal.coolingSupply_C = 7;
cfg.energy.refTerminal.coolingReturn_C = 12;
cfg.energy.refASHP.heatingRatedCOP = 3.0;
cfg.energy.refASHP.coolingRatedCOP = 3.0;
cfg.energy.refASHP.heatingRatedOutdoor_C = 7.0;
cfg.energy.refASHP.coolingRatedOutdoor_C = 35.0;
cfg.energy.refASHP.deltaT_evap_K = 5.0;
cfg.energy.refASHP.deltaT_cond_K = 5.0;
cfg.energy.refASHP.COP_min = 1.2;
cfg.energy.refASHP.COP_max = 8.0;
switch azimuth
    case 0, ori = 'North';
    case 90, ori = 'East';
    case 180, ori = 'South';
    case 270, ori = 'West';
    otherwise, error('Orientation must be 0/90/180/270');
end
cfg.wall.orientationTag = sprintf('az%03d',azimuth);
cfg.wall.orientationCN = ori;
end
