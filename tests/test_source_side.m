function test_source_side()
% Checks geometry and preservation of original hydraulic losses.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(root); addpath(fullfile(root,'model'));
C=readtable(fullfile(root,'inputs','paper_cases.csv'),'TextType','string');
cfg=peew_config(root,C(1,:),0);
wp=struct('rho',998.2,'mu',0.001);
D=cfg.sourceSide.pipeInnerDiameter_m;L=cfg.sourceSide.pipeLength_m;
A=pi*D^2/4;V=cfg.sourceSide.designVelocity_m_s;
h=m50_hyd_calcEquivalentSourceHydraulicOneStep(cfg,wp,V*A);
assert(abs(D-0.020)<1e-12 && L==200);
assert(cfg.sourceSide.zetaTotal==8 && cfg.sourceSide.accessoryPressureDropDesign_Pa==10000);
assert(abs(h.dpLocalDesign_Pa-8*wp.rho*V^2/2)<1e-8);
assert(abs(h.dpAccessoryDesign_Pa-10000)<1e-8);
assert(abs(h.dpDesignTotal_Pa-(h.dpFrictionDesign_Pa+h.dpLocalDesign_Pa+10000))<1e-8);
assert(abs(h.dpForPump_Pa-h.dpDesignTotal_Pa)<1e-8);
fprintf('Source-side equivalent hydraulic input checks passed.\n');
end
