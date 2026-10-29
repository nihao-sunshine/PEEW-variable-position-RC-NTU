% ========================================================================
% m60_energy_calcReferenceCOP.m
% ========================================================================
function COP = m60_energy_calcReferenceCOP(Tout_C, Tin_C, season, cfg)
% Estimate the reference heat-pump coefficient of performance.
Tout_C = Tout_C(:);
if strcmp(season, 'heating')
    Tw = 0.5*(cfg.energy.refTerminal.heatingSupply_C + cfg.energy.refTerminal.heatingReturn_C);
    Tevap = Tout_C - cfg.energy.refASHP.deltaT_evap_K;
    Tcond = Tw + cfg.energy.refASHP.deltaT_cond_K;
    TevapRated = cfg.energy.refASHP.heatingRatedOutdoor_C - cfg.energy.refASHP.deltaT_evap_K;
    TcondRated = Tw + cfg.energy.refASHP.deltaT_cond_K;
    carnotRated = (TcondRated+273.15) / ((TcondRated+273.15) - (TevapRated+273.15));
    eta = cfg.energy.refASHP.heatingRatedCOP / carnotRated;
    COP = eta * (Tcond+273.15) ./ ((Tcond+273.15) - (Tevap+273.15));
else
    Tw = 0.5*(cfg.energy.refTerminal.coolingSupply_C + cfg.energy.refTerminal.coolingReturn_C);
    Tevap = Tw - cfg.energy.refASHP.deltaT_evap_K;
    Tcond = Tout_C + cfg.energy.refASHP.deltaT_cond_K;
    TevapRated = Tw - cfg.energy.refASHP.deltaT_evap_K;
    TcondRated = cfg.energy.refASHP.coolingRatedOutdoor_C + cfg.energy.refASHP.deltaT_cond_K;
    carnotRated = (TevapRated+273.15) / ((TcondRated+273.15) - (TevapRated+273.15));
    eta = cfg.energy.refASHP.coolingRatedCOP / carnotRated;
    COP = eta * (Tevap+273.15) ./ ((Tcond+273.15) - (Tevap+273.15));
end
COP = min(max(COP, cfg.energy.refASHP.COP_min), cfg.energy.refASHP.COP_max);
end

% ======================================================================= %
