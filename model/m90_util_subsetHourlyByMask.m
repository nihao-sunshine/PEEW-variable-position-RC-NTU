% ========================================================================
% m90_util_subsetHourlyByMask.m
% ========================================================================
function out = m90_util_subsetHourlyByMask(in, mask)
% Select official-season samples while excluding the initialization interval.
%% m90_util_subsetHourlyByMask

out = in;
fields = fieldnames(in);
nMask = numel(mask);
for iField = 1:numel(fields)
    fieldName = fields{iField};
    value = in.(fieldName);
    if isnumeric(value) || islogical(value) || isdatetime(value) || isduration(value) || isstring(value)
        if size(value,1) == nMask
            out.(fieldName) = value(mask,:);
        elseif isvector(value) && numel(value) == nMask
            out.(fieldName) = value(mask);
        end
    end
end
end
