% ========================================================================
% m50_hyd_getWaterProps.m
% ========================================================================
function wp = m50_hyd_getWaterProps(T_C, water)
% Interpolate the water properties at a specified temperature.
Tq = min(max(T_C, min(water.T_C)), max(water.T_C));
wp.mu = interp1(water.T_C, water.mu_Pa_s, Tq, 'linear');
wp.rho = interp1(water.T_C, water.rho_kg_m3, Tq, 'linear');
wp.Pr = interp1(water.T_C, water.Pr, Tq, 'linear');
wp.k = interp1(water.T_C, water.k_W_mK, Tq, 'linear');
wp.cp = interp1(water.T_C, water.cp_J_kgK, Tq, 'linear');
end
