function test_parallel_tasks()
root=fileparts(fileparts(mfilename('fullpath')));
addpath(root);
C=peew_read_cases(root);
assert(height(C)==5);
expected=[168,144,126,102,102]; % 6*(1+27/23/20/16/16)
for i=1:height(C)
    cfg=peew_config(root,C(i,:),0);
    [jobs,ts]=peew_build_jobs(cfg,'full');
    assert(numel(ts)==6);
    assert(numel(jobs)==expected(i));
    assert(all(isnan([jobs(1:1+numel(cfg.case.A_innerIns_mm):end).delta])));
    assert(sum(isnan([jobs.delta]))==6);
    assert(all(ismember([jobs.Tsup],ts)));
end
fprintf('Parallel task enumeration tests passed.\n');
end
