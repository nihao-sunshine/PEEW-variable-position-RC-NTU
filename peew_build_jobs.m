function [jobs,Tsups] = peew_build_jobs(cfg,mode)
% Deterministic (supply water temperature, location) task construction.
Tsups = cfg.case.heatingSupply_C(:)';
dins=cfg.case.A_innerIns_mm(:)';
if strcmpi(mode,'smoke')
    Tsups=15;
    totalIns=cfg.case.A_totalIns_mm;
    dins=unique([0 5*floor(totalIns/10) 5*floor(totalIns/5)]);
end
nLoc=1+numel(dins);
template=struct('Tsup',NaN,'delta',NaN,'kind','','locationType','');
jobs=repmat(template,numel(Tsups)*nLoc,1);
j=0;
for it=1:numel(Tsups)
    j=j+1; jobs(j)=struct('Tsup',Tsups(it),'delta',NaN, ...
         'kind','B_conventionalPEEW','locationType','middle');
    for ii=1:numel(dins)
        j=j+1; jobs(j)=struct('Tsup',Tsups(it),'delta',dins(ii), ...
             'kind','A_positionOptimizedPEEW','locationType','variable');
    end
end
end
