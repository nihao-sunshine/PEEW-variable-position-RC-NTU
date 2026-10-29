% ========================================================================
% m20_boundary_loadWeather.m
% ========================================================================
function weather = m20_boundary_loadWeather(cfg)
% Load and interpolate the supplied meteorological time series.
if ~isfile(cfg.path.weatherFile)
    error('Weather file not found: %s', cfg.path.weatherFile);
end
S = load(cfg.path.weatherFile);
fn = fieldnames(S);
raw = [];
for i = 1:numel(fn)
    v = S.(fn{i});
    if isnumeric(v) && size(v,2) >= 12
        raw = v; break;
    end
end
if isempty(raw)
    error('Weather MAT file must contain a numeric matrix with at least 12 columns.');
end

timeRaw = datetime(raw(:,1),1,1,0,0,0) + days(raw(:,2)-1) + hours(raw(:,3));
startAll = min([cfg.season.heating.start cfg.season.cooling.start]);
endAll = max([cfg.season.heating.end cfg.season.cooling.end]);
timeSim = (startAll:seconds(cfg.sim.timeStep_s):endAll-seconds(cfg.sim.timeStep_s))';
raw_s = seconds(timeRaw - timeRaw(1));
sim_s = seconds(timeSim - timeRaw(1));
weather = struct();
weather.time = timeSim;
weather.Tout_C = interp1(raw_s, raw(:,5), sim_s, 'linear', 'extrap');
weather.RH_percent = interp1(raw_s, raw(:,6), sim_s, 'linear', 'extrap');
weather.windSpeed_m_s = interp1(raw_s, raw(:,7), sim_s, 'linear', 'extrap');
weather.DNI_W_m2 = max(interp1(raw_s, raw(:,8), sim_s, 'linear', 'extrap'), 0);
weather.DHI_W_m2 = max(interp1(raw_s, raw(:,9), sim_s, 'linear', 'extrap'), 0);
weather.I_vertical_W_m2 = m20_boundary_calcVerticalIrradiance(timeSim, weather.DNI_W_m2, weather.DHI_W_m2, cfg);
end
