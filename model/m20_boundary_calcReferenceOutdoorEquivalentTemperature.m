% ========================================================================
% m20_boundary_calcReferenceOutdoorEquivalentTemperature.m
% ========================================================================
function Teq = m20_boundary_calcReferenceOutdoorEquivalentTemperature(weather, cfg)
% Evaluate the reference-wall outdoor equivalent temperature.
n = numel(weather.Tout_C);
Teq = zeros(n,1);
for i = 1:n
    Tout = weather.Tout_C(i);
    Ivert = weather.I_vertical_W_m2(i);
    hConv = 5.7 + 3.8*max(weather.windSpeed_m_s(i), cfg.outdoorConvection.minWindSpeed_m_s);
    TskyK = 0.0552*(Tout+273.15)^1.5;
    TradK = (0.5*TskyK^4 + 0.5*(Tout+273.15)^4)^0.25;
    TsRefK = Tout + 273.15;
    hRad = cfg.material.outerSurfaceEmissivity * 5.670374419e-8 * (TsRefK^2 + TradK^2)*(TsRefK + TradK);
    Teq(i) = (hConv*Tout + hRad*(TradK-273.15) + cfg.material.outerSolarAbsorptance*Ivert) / (hConv+hRad);
end
end
