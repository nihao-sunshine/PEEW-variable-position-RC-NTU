% ========================================================================
% m10_case_calcSerpentinePipeLength.m
% ========================================================================
function L = m10_case_calcSerpentinePipeLength(width_m, height_m, spacing_m)
% Calculate the embedded serpentine pipe length from wall dimensions and spacing.
nRuns = max(1, floor(height_m/spacing_m) + 1);
L = nRuns*width_m + max(nRuns-1,0)*spacing_m;
end
