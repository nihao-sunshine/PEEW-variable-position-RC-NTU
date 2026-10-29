clearvars; clc;
root=fileparts(mfilename('fullpath'));
cd(root);
addpath(root,fullfile(root,'model'),fullfile(root,'tests'));
workers=60;
C=peew_read_cases(root);
fprintf('Loaded %d city rows from paper_cases.csv.\n',height(C));
pool=gcp('nocreate');
if ~isempty(pool) && pool.NumWorkers~=workers,delete(pool);end
results=run_reproduction('paper','full','parallel',workers);
fprintf('All selected cases completed. See results folder.\n');
disp(results.recommendations);
