% ========================================================================
% m50_hyd_loadWaterTable.m
% ========================================================================
function water = m50_hyd_loadWaterTable(cfg)
% Read the temperature-dependent water-property table.
if ~isfile(cfg.path.waterFile)
    error('Water property file not found: %s', cfg.path.waterFile);
end
S = load(cfg.path.waterFile);
fn = fieldnames(S);
raw = [];
for i = 1:numel(fn)
    v = S.(fn{i});
    if isnumeric(v) && size(v,2) >= 6
        raw = v; break;
    end
end
if isempty(raw)
    error('Water-property MAT file must contain a numeric matrix with at least 6 columns.');
end
water.T_C = raw(:,1);
water.mu_Pa_s = raw(:,2);
water.rho_kg_m3 = raw(:,3);
water.Pr = raw(:,4);
water.k_W_mK = raw(:,5);
water.cp_J_kgK = raw(:,6)*1000;
end
