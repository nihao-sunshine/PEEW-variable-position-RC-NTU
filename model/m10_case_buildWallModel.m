% ========================================================================
% m10_case_buildWallModel.m
% ========================================================================
function wall = m10_case_buildWallModel(caseSpec, cfg)
% Construct a layer-resolved finite-volume wall network for the specified pipe location.
maxDx = 0.010;
layers = struct('name', {}, 'mat', {}, 'thickness_m', {});
pipeCenterDepth_m = NaN;

switch caseSpec.wallType
    case 'A_positionOptimizedPEEW'
        inIns = caseSpec.innerInsulation_mm / 1000;
        outIns = caseSpec.outerInsulation_mm / 1000;
        layers(end+1) = m10_case_layer('inner_plaster','inner_plaster',0.020); %#ok<AGROW>
        layers(end+1) = m10_case_layer('brick','brick',0.240); %#ok<AGROW>
        if inIns > 0, layers(end+1) = m10_case_layer('inner_insulation','insulation',inIns); end %#ok<AGROW>
        layers(end+1) = m10_case_layer('concrete_with_pipe','concrete',0.040); %#ok<AGROW>
        if outIns > 0, layers(end+1) = m10_case_layer('outer_insulation','insulation',outIns); end %#ok<AGROW>
        layers(end+1) = m10_case_layer('outer_plaster','outer_plaster',0.020); %#ok<AGROW>
        pipeCenterDepth_m = 0.020 + 0.240 + inIns + 0.020;
    case 'B_conventionalPEEW'
        layers(end+1) = m10_case_layer('inner_plaster','inner_plaster',0.020); %#ok<AGROW>
        layers(end+1) = m10_case_layer('brick_inner','brick',0.120); %#ok<AGROW>
        layers(end+1) = m10_case_layer('concrete_with_pipe','concrete',0.040); %#ok<AGROW>
        layers(end+1) = m10_case_layer('brick_outer','brick',0.120); %#ok<AGROW>
        layers(end+1) = m10_case_layer('outer_insulation','insulation',caseSpec.outerInsulation_mm/1000); %#ok<AGROW>
        layers(end+1) = m10_case_layer('outer_plaster','outer_plaster',0.020); %#ok<AGROW>
        pipeCenterDepth_m = 0.020 + 0.120 + 0.020;
    case 'C_referenceNoPipe'
        layers(end+1) = m10_case_layer('inner_plaster','inner_plaster',0.020); %#ok<AGROW>
        layers(end+1) = m10_case_layer('brick','brick',0.240); %#ok<AGROW>
        layers(end+1) = m10_case_layer('concrete_no_pipe','concrete',0.040); %#ok<AGROW>
        layers(end+1) = m10_case_layer('insulation','insulation',caseSpec.referenceInsulation_mm/1000); %#ok<AGROW>
        layers(end+1) = m10_case_layer('outer_plaster','outer_plaster',0.020); %#ok<AGROW>
    otherwise
        error('Unknown wallType: %s', caseSpec.wallType);
end

xCenters = [];
dx = [];
k = [];
rho = [];
cp = [];
matNames = {};
cellLayerNames = {};
x0 = 0;
for L = 1:numel(layers)
    th = layers(L).thickness_m;
    if th <= 0, continue; end
    nCell = max(1, ceil(th / maxDx));
    dxi = th / nCell;
    mat = cfg.material.(layers(L).mat);
    for j = 1:nCell
        dx(end+1,1) = dxi; %#ok<AGROW>
        xCenters(end+1,1) = x0 + (j-0.5)*dxi; %#ok<AGROW>
        k(end+1,1) = mat.k; %#ok<AGROW>
        rho(end+1,1) = mat.rho; %#ok<AGROW>
        cp(end+1,1) = mat.cp; %#ok<AGROW>
        matNames{end+1,1} = layers(L).mat; %#ok<AGROW>
        cellLayerNames{end+1,1} = layers(L).name; %#ok<AGROW>
    end
    x0 = x0 + th;
end

wall = m10_case_emptyWallModel();
wall.layers = layers;
wall.x_m = xCenters;
wall.dx_m = dx;
wall.k_W_mK = k;
wall.rho_kg_m3 = rho;
wall.cp_J_kgK = cp;
wall.C_J_m2K = rho .* cp .* dx;
wall.nNode = numel(dx);
wall.thickness_m = sum(dx);
wall.area_m2 = cfg.wall.area_m2;
wall.height_m = cfg.wall.height_m;
wall.width_m = cfg.wall.width_m;
wall.matNames = matNames;
wall.cellLayerNames = cellLayerNames;
wall.hasPipe = caseSpec.hasPipe;
wall.pipeCenterDepth_m = pipeCenterDepth_m;
if caseSpec.hasPipe
    [~, idx] = min(abs(xCenters - pipeCenterDepth_m));
    wall.pipeNodeIndex = idx;
    wall.pipeTotalLength_m = m10_case_calcSerpentinePipeLength(cfg.wall.width_m, cfg.wall.height_m, cfg.pipe.spacing_m);
    wall.pipeLengthPerArea_m_m2 = wall.pipeTotalLength_m / wall.area_m2;
else
    wall.pipeNodeIndex = NaN;
    wall.pipeTotalLength_m = 0;
    wall.pipeLengthPerArea_m_m2 = 0;
end
wall.description = m10_case_wallDescription(caseSpec);
end

% ======================================================================= %
