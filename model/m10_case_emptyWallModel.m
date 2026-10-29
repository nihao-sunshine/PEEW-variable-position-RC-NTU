% ========================================================================
% m10_case_emptyWallModel.m
% ========================================================================
function w = m10_case_emptyWallModel()
% Initialize a zero-valued wall-model structure.
w = struct('layers',[],'x_m',[],'dx_m',[],'k_W_mK',[],'rho_kg_m3',[],'cp_J_kgK',[], ...
    'C_J_m2K',[],'nNode',0,'thickness_m',NaN,'area_m2',NaN,'height_m',NaN,'width_m',NaN, ...
    'matNames',[],'cellLayerNames',[],'hasPipe',false,'pipeCenterDepth_m',NaN,'pipeNodeIndex',NaN, ...
    'pipeTotalLength_m',0,'pipeLengthPerArea_m_m2',0,'description','');
end
