% ========================================================================
% m60_energy_calcSignedWallLoad.m
% ========================================================================
function wallLoad_W = m60_energy_calcSignedWallLoad(QinnerToIndoor_W, season)
% Convert signed inner-surface heat transfer to signed wall heating load.
if strcmp(season, 'heating')
    wallLoad_W = -QinnerToIndoor_W;
else
    wallLoad_W = QinnerToIndoor_W;
end
end
