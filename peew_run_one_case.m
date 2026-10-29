function row = peew_run_one_case(job,city,az,Tin,insMm,cfg,W,water,cw)
% One completely independent physical simulation, safe for PARFOR.
% No files are written here. Returned row has 15 fixed fields.
spec=peew_make_case(job.kind,city,Tin,job.Tsup,insMm,job.delta,cfg.sim.timeStep_s/3600);
wall=m10_case_buildWallModel(spec,cfg);
f0=m40_flow_makeFixedVelocityFlowProfile(spec,wall,W,water,cfg,cfg.pipe.fixedVelocity_m_s,'V025');
pre=m30_wall_solveWallTransientGivenFlowProfile(spec,wall,W,water,cfg,f0,'V025');
Qdesign=m40_flow_calcDesignPipeHeatFromV025(pre.hourly,'heating',cfg);
clear pre;
f1=m40_flow_makeS1FlowProfile(spec,wall,W,water,cfg,Qdesign);
sim=m30_wall_solveWallTransientGivenFlowProfile(spec,wall,W,water,cfg,f1,'S1');
m=peew_metrics(sim,cw);
row={city,az,Tin,job.Tsup,job.locationType,job.delta, ...
     m.Qin_kWh,m.QpPlus_kWh,m.QpMinus_kWh,m.EHP_signed_kWh, ...
     m.Epump_kWh,m.Eeq_kWh,m.DeltaQin_kWh,m.etaE,m.etaEff};
end
