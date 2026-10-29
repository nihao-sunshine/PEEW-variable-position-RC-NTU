% ========================================================================
% m20_boundary_calcOutdoorBoundary.m
% ========================================================================
function outB = m20_boundary_calcOutdoorBoundary(Tsurface_C, Tout_C, wind_m_s, Ivert_W_m2, cfg)
% Calculate the outdoor equivalent temperature and surface conductance.
wind = max(wind_m_s, cfg.outdoorConvection.minWindSpeed_m_s);
hc = 5.7 + 3.8*wind;
Tsky_K = 0.0552 * (Tout_C + 273.15)^1.5;
Tsky_C = Tsky_K - 273.15;
Trad_K = (0.5*Tsky_K^4 + 0.5*(Tout_C+273.15)^4)^(0.25);
Trad_C = Trad_K - 273.15;
sigma = 5.670374419e-8;
TsK = Tsurface_C + 273.15;
hr = cfg.material.outerSurfaceEmissivity * sigma * (TsK^2 + Trad_K^2) * (TsK + Trad_K);
hEq = hc + hr;
Teq = (hc*Tout_C + hr*Trad_C + cfg.material.outerSolarAbsorptance*Ivert_W_m2) / hEq;
outB = struct('hConv',hc,'hRad',hr,'hEq',hEq,'Tsky_C',Tsky_C,'TradOut_C',Trad_C,'TeqOut_C',Teq);
end
