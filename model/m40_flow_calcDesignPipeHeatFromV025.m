% ========================================================================
% m40_flow_calcDesignPipeHeatFromV025.m
% ========================================================================
function Qdesign_W = m40_flow_calcDesignPipeHeatFromV025(hourly, season, cfg)
% Extract the positive pipe heat rate used to determine design flow.
%% m40_flow_calcDesignPipeHeatFromV025

if isfield(hourly, 'isOfficial')
    mask = logical(hourly.isOfficial(:));
else
    mask = true(numel(hourly.Q_pipeToWall_W),1);
end
Q = hourly.Q_pipeToWall_W(mask);
if strcmp(season, 'heating')
    QeffAbs = max(Q, 0);
else
    QeffAbs = max(-Q, 0);
end
Qdesign_W = max(QeffAbs);
if isempty(Qdesign_W) || ~isfinite(Qdesign_W) || Qdesign_W < cfg.pipe.zeroHeatThreshold_W
    Qdesign_W = 0;
end
end
