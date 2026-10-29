% ========================================================================
% m20_boundary_calcIndoorHTC.m
% ========================================================================
function [hc, hr, h] = m20_boundary_calcIndoorHTC(Tsurface_C, Tin_C, cfg)
% Calculate equivalent indoor convective and radiative heat-transfer coefficients.
dT = abs(Tsurface_C - Tin_C);
hc = 1.31 * max(dT, 1e-6)^(1/3);
hc = max(hc, 0.1);
sigma = 5.670374419e-8;
TsK = Tsurface_C + 273.15;
TrK = Tin_C + 273.15;
es = cfg.material.innerSurfaceEmissivity;
er = cfg.material.indoorRadiantEnvironmentEmissivity;
hr = sigma*(TsK^2 + TrK^2)*(TsK + TrK) / (1/es + 1/er - 1);
h = hc + hr;
end
