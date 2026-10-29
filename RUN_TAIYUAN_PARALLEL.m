clearvars; clc;
root=fileparts(mfilename('fullpath'));
cd(root);
addpath(root,fullfile(root,'model'),fullfile(root,'tests'));
workers=60;
changePoolSize=true;
C=peew_read_cases(root);
assert(any(strcmpi(C.city,'Taiyuan')),'Taiyuan not present in cases CSV');
fprintf('Taiyuan orientations: %s\n',char(C.orientations_deg(strcmpi(C.city,'Taiyuan'))));
if changePoolSize
    pool=gcp('nocreate');
    if ~isempty(pool) && pool.NumWorkers~=workers
        delete(pool);
    end
end
results=run_reproduction('Taiyuan','full','parallel',workers);
fprintf('Taiyuan completed. See results folder for all outputs.\n');
