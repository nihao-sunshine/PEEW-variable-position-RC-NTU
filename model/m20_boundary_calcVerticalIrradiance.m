% ========================================================================
% m20_boundary_calcVerticalIrradiance.m
% ========================================================================
function [Ivert, comp] = m20_boundary_calcVerticalIrradiance(time, DNI, DHI, cfg)
% Project direct and diffuse solar irradiance onto the vertical facade.
[alt_deg, az_deg] = m20_boundary_solarPosition(time, cfg.site.latitude_deg, cfg.site.longitude_deg, cfg.site.timeZone_hours);
DNI = max(DNI(:), 0);
DHI = max(DHI(:), 0);
rho_g = max(min(cfg.solar.groundReflectance, 1), 0);

alt_rad = deg2rad(alt_deg(:));
azs_rad = deg2rad(az_deg(:));
beta_rad = deg2rad(cfg.wall.tilt_deg);
azp_rad = deg2rad(cfg.wall.azimuth_deg);
cosTheta = sin(alt_rad).*cos(beta_rad) + cos(alt_rad).*sin(beta_rad).*cos(azs_rad - azp_rad);
cosTheta = max(cosTheta, 0);
sunUp = alt_deg(:) > 0;

I_dir = DNI .* cosTheta .* sunUp;
GHI = max(DNI .* sin(alt_rad), 0) + DHI;
I_dif = DHI .* (1 + cos(beta_rad)) ./ 2;
I_ref = rho_g .* GHI .* (1 - cos(beta_rad)) ./ 2;
Ivert = max(I_dir + I_dif + I_ref, 0);

comp = struct();
comp.I_dir_Wm2 = I_dir;
comp.I_dif_Wm2 = I_dif;
comp.I_ref_Wm2 = I_ref;
comp.GHI_Wm2 = GHI;
end
