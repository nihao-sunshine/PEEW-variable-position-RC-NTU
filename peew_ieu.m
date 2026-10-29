function z = peew_ieu(etaE, dQin, qpPlus, weightE, beta)
% Feasibility first, then normalization within the feasible set only.
% Undefined or nonpositive normalization denominators produce NO recommendation.
if nargin < 4, weightE = 0.5; end
if nargin < 5, beta = 0.95; end
assert(weightE>=0 && weightE<=1 && beta>0 && beta<=1);
etaE=etaE(:); dQin=dQin(:); qpPlus=qpPlus(:);
n = numel(etaE); assert(numel(dQin)==n && numel(qpPlus)==n);
z.feasible = isfinite(etaE) & (etaE>0) & isfinite(dQin) & (dQin>0) & ...
    isfinite(qpPlus) & (qpPlus>0);
z.etaEff = nan(n,1); goodQ = isfinite(qpPlus) & qpPlus>0 & isfinite(dQin);
z.etaEff(goodQ)=dQin(goodQ)./qpPlus(goodQ);
z.feasible = z.feasible & isfinite(z.etaEff) & z.etaEff>0;
z.IEU = nan(n,1); z.recommended=false(n,1); z.bestIndex=NaN;
z.maxEtaE=NaN; z.maxEtaEff=NaN; z.maxIEU=NaN;
if ~any(z.feasible), return; end
z.maxEtaE = max(etaE(z.feasible)); z.maxEtaEff = max(z.etaEff(z.feasible));
if ~(isfinite(z.maxEtaE) && z.maxEtaE>0 && isfinite(z.maxEtaEff) && z.maxEtaEff>0), return; end
z.IEU(z.feasible)= weightE*etaE(z.feasible)./z.maxEtaE + ...
    (1-weightE)*z.etaEff(z.feasible)./z.maxEtaEff;
[z.maxIEU, ix] = max(z.IEU(z.feasible));
fIdx=find(z.feasible); z.bestIndex=fIdx(ix);
z.recommended = z.feasible & (z.IEU >= beta*z.maxIEU);
end
