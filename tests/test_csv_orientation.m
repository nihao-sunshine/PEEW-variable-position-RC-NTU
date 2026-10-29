function test_csv_orientation()
root=fileparts(fileparts(mfilename('fullpath')));
addpath(root);
C=peew_read_cases(root);
idx=strcmpi(C.city,'Taiyuan');
assert(sum(idx)==1,'Expected one Taiyuan case row.');
az=peew_parse_orientations(C.orientations_deg(idx));
assert(isequal(az,[0 90 180 270]),'Taiyuan four-orientation parsing failed.');
expected={'Hailar','Harbin','Shenyang','Taiyuan','Beijing'};
assert(isequal(sort(string(C.city)),sort(string(expected(:)))));
for k=1:height(C)
    assert(isstring(C.heating_start),'Heating dates should be imported as string.');
    assert(isstring(C.orientations_deg),'Orientation field should be imported as string.');
    peew_parse_orientations(C.orientations_deg(k));
end
fprintf('CSV orientation import and parsing tests passed.\n');
end
