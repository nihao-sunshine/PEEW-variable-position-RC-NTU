function test_case_config()
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'model'));addpath(root);
C=peew_read_cases(root);
assert(height(C)==5);
for k=1:height(C)
    cfg=peew_config(root,C(k,:),0);
    assert(abs(cfg.material.insulation.cp-670)<eps); % manuscript-aligned expanded-perlite cp
    assert(cfg.material.pipe.rho == 950 && cfg.material.pipe.cp == 2300);
    assert(abs(cfg.sourceSide.pipeInnerDiameter_m-0.020)<1e-12);
    assert(abs(cfg.sourceSide.pipeLength_m-200)<1e-12);
    assert(cfg.sourceSide.zetaTotal == 8);
    assert(cfg.sourceSide.designVelocity_m_s == 0.50);
    assert(cfg.sourceSide.accessoryPressureDropDesign_Pa == 10000);
    assert(cfg.sim.timeStep_s==1200 && cfg.sim.warmupDays==7);
    assert(isfile(cfg.path.weatherFile) && isfile(cfg.path.waterFile));
    s=peew_make_case('A_positionOptimizedPEEW',char(C.city(k)),18,15,C.insulation_mm(k),0,1/3);
    w=m10_case_buildWallModel(s,cfg);
    assert(w.hasPipe && w.nNode>1 && abs(w.area_m2-15)<eps);
end
fprintf('Input, dependency and wall-construction checks passed.\n');
end
