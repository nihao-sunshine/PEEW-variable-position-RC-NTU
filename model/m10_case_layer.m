% ========================================================================
% m10_case_layer.m
% ========================================================================
function layer = m10_case_layer(name, mat, thickness_m)
% Represent a wall material layer and its thickness.
layer = struct('name',name,'mat',mat,'thickness_m',thickness_m);
end
