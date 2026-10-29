function test_ieu()
addpath(fileparts(fileparts(mfilename('fullpath'))));
% Signed heat-load credit: electricity is not clipped to zero.
wallLoad_W=[100;-50]; COP=[2;2]; dt_h=1;
EHP=sum(wallLoad_W./COP*dt_h/1000);
assert(abs(EHP-0.025)<1e-12);
% Feasibility excludes zero or negative positive-pipe-heat denominators.
z=peew_ieu([0.10;-0.2;0.2],[5;5;0],[2;0;2],0.5,0.95);
assert(nnz(z.feasible)==1 && z.feasible(1));
assert(isnan(z.IEU(2)) && isnan(z.IEU(3)));
assert(z.recommended(1));
% No eligible configuration produces no recommendation, not NaN/Inf weights.
z=peew_ieu([-1;-2],[0;-5],[0;0],0.5,0.95);
assert(~any(z.recommended) && all(isnan(z.IEU)));
fprintf('IEU/postprocessing unit tests passed.\n');
end
