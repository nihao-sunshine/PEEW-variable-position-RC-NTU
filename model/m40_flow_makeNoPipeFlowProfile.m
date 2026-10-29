% ========================================================================
% m40_flow_makeNoPipeFlowProfile.m
% ========================================================================
function fp = m40_flow_makeNoPipeFlowProfile(n)
% Generate the zero-flow profile for the conventional reference wall.
fp = struct();
fp.strategy = 'Reference';
fp.mDot_kg_s = zeros(n,1);
fp.velocity_m_s = zeros(n,1);
fp.stage = zeros(n,1);
fp.designFlow_m3_s = 0;
fp.designMDot_kg_s = 0;
fp.designVelocity_m_s = 0;
fp.stageRatios = [];
fp.stageCollapsedFlag = false;
end
