function test_export_schema()
% Ensure the public table excludes raw fraction fields while retaining IEU.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(root);
expected={'city','azimuth_deg','Qin_kWh','QpPlus_kWh','DeltaQin_kWh', ...
    'Eeq_kWh','IEU','recommended'};
a=fullfile(root,'results','all_cases.csv');
if isfile(a)
    T=readtable(a);
    assert(all(ismember(expected,T.Properties.VariableNames)));
    assert(~ismember('etaE_fraction',T.Properties.VariableNames));
    assert(~ismember('etaEff_fraction',T.Properties.VariableNames));
    fprintf('Public CSV export schema verified.\n');
else
    fprintf('No previous public case CSV exists; export check will be available after a run.\n');
end
end
