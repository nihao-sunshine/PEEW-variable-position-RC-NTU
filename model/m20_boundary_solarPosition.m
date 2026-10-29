% ========================================================================
% m20_boundary_solarPosition.m
% ========================================================================
function [alt_deg, az_deg] = m20_boundary_solarPosition(time, lat_deg, lon_deg, tz)
% Calculate local solar altitude and azimuth.
doy = day(time, 'dayofyear');
hourLocal = hour(time) + minute(time)./60 + second(time)./3600;

B = 2*pi*(doy - 81)./364;
EoT_min = 9.87.*sin(2.*B) - 7.53.*cos(B) - 1.5.*sin(B);
LSTM_deg = 15 .* tz;
TC_min = 4 .* (lon_deg - LSTM_deg) + EoT_min;
LST_hour = hourLocal + TC_min./60;
HRA_deg = 15 .* (LST_hour - 12);

dec_deg = 23.45 .* sind(360 .* (284 + doy) ./ 365);
alt_deg = asind(sind(lat_deg).*sind(dec_deg) + cosd(lat_deg).*cosd(dec_deg).*cosd(HRA_deg));
az_deg = mod(atan2d(sind(HRA_deg), cosd(HRA_deg).*sind(lat_deg) - tand(dec_deg).*cosd(lat_deg)) + 180, 360);

alt_deg(alt_deg < -90) = -90;
alt_deg(alt_deg > 90) = 90;
end
