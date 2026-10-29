function C = peew_read_cases(root)
% Load paper case matrix without allowing readtable to misclassify mixed
% numeric/text orientation lists (e.g. Taiyuan: 0|90|180|270).
path = fullfile(root,'inputs','paper_cases.csv');
assert(isfile(path),'Case input file not found: %s',path);
opts = detectImportOptions(path,'FileType','text','TextType','string');
textFields = {'city','weather_file','heating_start', ...
              'heating_end_exclusive','orientations_deg'};
assert(all(ismember(textFields,opts.VariableNames)), ...
    'Missing one or more required columns in paper_cases.csv.');
opts = setvartype(opts,textFields,'string');
numericFields = {'insulation_mm','latitude_deg','longitude_deg'};
assert(all(ismember(numericFields,opts.VariableNames)), ...
    'Missing numeric city parameter columns in paper_cases.csv.');
opts = setvartype(opts,numericFields,'double');
C = readtable(path,opts);
assert(height(C)>0,'No city cases found.');
for k=1:height(C)
    city = string(C.city(k));
    az = peew_parse_orientations(C.orientations_deg(k));
    assert(~isempty(az),'Empty orientations for city %s.',city);
    assert(isfinite(C.insulation_mm(k)) && C.insulation_mm(k)>0, ...
        'Invalid insulation_mm for city %s.',city);
    assert(isfinite(C.latitude_deg(k)) && isfinite(C.longitude_deg(k)), ...
        'Invalid coordinates for city %s.',city);
    assert(~isnat(datetime(C.heating_start(k),'InputFormat','yyyy-MM-dd')) && ...
           ~isnat(datetime(C.heating_end_exclusive(k),'InputFormat','yyyy-MM-dd')), ...
        'Invalid heating date for city %s.',city);
end
end
