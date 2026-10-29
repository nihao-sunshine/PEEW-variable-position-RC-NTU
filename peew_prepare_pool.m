function [useParallel,workerCount] = peew_prepare_pool(execution,maxWorkers)
% Start or reuse a LOCAL PROCESS pool; never creates more than maxWorkers.
% 'parallel': fail clearly without Parallel Computing Toolbox.
% 'auto': try parallel, otherwise print a warning and use serial.
useParallel=false; workerCount=1;
if strcmpi(execution,'serial'), return; end
hasToolbox=license('test','Distrib_Computing_Toolbox') && exist('parpool','file')==2;
if ~hasToolbox
    if strcmpi(execution,'parallel')
        error('Parallel Computing Toolbox is required for execution=parallel.');
    else
        warning('Parallel Computing Toolbox unavailable; using serial mode.');
        return;
    end
end
try
    pool=gcp('nocreate');
    if isempty(pool)
        pc=parcluster('local');
        requested=min(maxWorkers,pc.NumWorkers);
        assert(requested>=1,'Local parallel profile supports no workers.');
        pool=parpool(pc,requested);
    else
        if pool.NumWorkers > maxWorkers
            warning('Existing parallel pool has %d workers, above requested cap %d. Reusing it.', ...
                    pool.NumWorkers,maxWorkers);
        end
    end
    workerCount=pool.NumWorkers;
    useParallel=true;
catch ME
    if strcmpi(execution,'parallel')
        rethrow(ME);
    else
        warning('Parallel pool could not be started (%s). Using serial mode.',ME.message);
    end
end
end
