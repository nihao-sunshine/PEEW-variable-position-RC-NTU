clearvars; clc;
root=fileparts(mfilename('fullpath'));
cd(root);
addpath(root,fullfile(root,'model'),fullfile(root,'tests'));
C=peew_read_cases(root);
for i=1:height(C)
    az=peew_parse_orientations(C.orientations_deg(i));
    fprintf('%s: delta_ins = %g mm, heating = %s through %s (exclusive), azimuths = %s\n',...
        char(C.city(i)),C.insulation_mm(i),char(C.heating_start(i)), ...
        char(C.heating_end_exclusive(i)),mat2str(az));
end
test_ieu;
test_source_side;
test_case_config;
test_parallel_tasks;
test_csv_orientation;
test_export_schema;
assert(isequal(peew_parse_orientations("0|90|180|270"),[0 90 180 270]));
fprintf('ALL INPUT TESTS PASSED.\n');
