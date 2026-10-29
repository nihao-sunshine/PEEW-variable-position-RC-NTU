function azList = peew_parse_orientations(value)
% Strict parsing of 0|90|180|270 without using readtable's type inference.
raw = strtrim(string(value));
assert(isscalar(raw) && ~ismissing(raw) && strlength(raw)>0, ...
    'Orientation field is empty.');
parts = split(raw,'|');
assert(all(strlength(strtrim(parts))>0), ...
    'Invalid empty orientation in: %s',char(raw));
azList = str2double(strtrim(parts));
assert(all(isfinite(azList)) && all(ismember(azList,[0 90 180 270])), ...
    'Orientations must be separated by | and take values 0/90/180/270. Original value: %s',char(raw));
assert(numel(unique(azList))==numel(azList), ...
    'Duplicated orientations in: %s',char(raw));
azList = azList(:)';
end
