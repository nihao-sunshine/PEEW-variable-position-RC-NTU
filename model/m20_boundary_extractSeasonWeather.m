% ========================================================================
% m20_boundary_extractSeasonWeather.m
% ========================================================================
function seasonWeather = m20_boundary_extractSeasonWeather(weatherAll, season, cfg)
% Extract the heating-season weather sequence and the initialization interval.
%% m20_boundary_extractSeasonWeather

if strcmp(season,'heating')
    tOfficialStart = cfg.season.heating.start;
    tOfficialEnd = cfg.season.heating.end;
else
    tOfficialStart = cfg.season.cooling.start;
    tOfficialEnd = cfg.season.cooling.end;
end

warmupStep = round(cfg.sim.warmupDays * 24 * 3600 / cfg.sim.timeStep_s);
officialIdx = weatherAll.time >= tOfficialStart & weatherAll.time < tOfficialEnd;
officialPos = find(officialIdx);
if isempty(officialPos)
    error('m20_boundary_extractSeasonWeather:NoOfficialData', 'No weather data available for the official %s season.', season);
end

firstOfficial = officialPos(1);
preStartPos = max(1, firstOfficial - warmupStep);
prePos = preStartPos:firstOfficial-1;
needFallback = numel(prePos) < warmupStep;

if needFallback
    nMissing = warmupStep - numel(prePos);
    fallbackPos = officialPos(1:min(nMissing, numel(officialPos)));
    prePos = [fallbackPos(:); prePos(:)];
    prePos = prePos(end-warmupStep+1:end);
else
    prePos = prePos(:);
end

allPos = [prePos(:); officialPos(:)];
isOfficial = [false(numel(prePos),1); true(numel(officialPos),1)];
fields = fieldnames(weatherAll);
for iField = 1:numel(fields)
    fieldName = fields{iField};
    value = weatherAll.(fieldName);
    if numel(value) == numel(weatherAll.time)
        seasonWeather.(fieldName) = value(allPos);
    else
        seasonWeather.(fieldName) = value;
    end
end
seasonWeather.isOfficial = isOfficial;
seasonWeather.warmupStep = warmupStep;
seasonWeather.officialStart = tOfficialStart;
seasonWeather.officialEnd = tOfficialEnd;
end
