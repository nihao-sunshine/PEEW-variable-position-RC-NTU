function results = run_reproduction(selection, mode, execution, maxWorkers)
% Reproduce the heating-season PEEW paper cases.
%
% Examples:
%   run_reproduction('Hailar','smoke');                  % serial small case
%   run_reproduction('Taiyuan','full','parallel',32);    % 32 local workers
%   run_reproduction('paper','full','parallel',60);      % all Table 5/6 cases
%   run_reproduction('paper','full','serial');           % no Parallel Toolbox
%
% Parallelism is across independent (Tsup, pipe-location) cases. All
% workers only return in-memory metrics; the client writes CSV files once.
% Results are assembled in a fixed, reproducible task order.
%
% 'smoke' runs a reduced set of locations and MUST NOT be compared to tables.
if nargin < 1 || isempty(selection), selection = 'Hailar'; end
if nargin < 2 || isempty(mode), mode = 'smoke'; end
if nargin < 3 || isempty(execution)
    if strcmpi(mode,'full'), execution='auto'; else, execution='serial'; end
end
if nargin < 4 || isempty(maxWorkers), maxWorkers = 60; end
selection = char(selection); mode = char(mode); execution = char(execution);
assert(ismember(lower(mode),{'smoke','full'}), 'mode must be smoke or full');
assert(ismember(lower(execution),{'auto','parallel','serial'}), ...
       'execution must be auto, parallel or serial');
assert(isscalar(maxWorkers) && isfinite(maxWorkers) && maxWorkers >= 1, ...
       'maxWorkers must be a positive number');
maxWorkers = floor(maxWorkers);

root = fileparts(mfilename('fullpath'));
addpath(root,fullfile(root,'model'));
C = peew_read_cases(root);
if ~strcmpi(selection,'paper')
    C=C(strcmpi(C.city,selection),:);
    assert(height(C)==1,'City not listed in inputs/paper_cases.csv');
end
% Validate ALL selected city orientations before starting a potentially costly pool.
for k = 1:height(C)
    peew_parse_orientations(C.orientations_deg(k));
end
% Initialize or reuse one process-based local pool, not one pool per city.
[useParallel, poolSize] = peew_prepare_pool(execution,maxWorkers);
if useParallel
    fprintf('Parallel computation enabled: %d workers (parfor).\n',poolSize);
else
    fprintf('Serial computation enabled.\n');
end

outRows = cell(0,18);
recRows = cell(0,7);
cwRows = cell(0,6);
for ic = 1:height(C)
    r = C(ic,:);
    city = char(r.city);
    insMm = double(r.insulation_mm);
    azList = peew_parse_orientations(r.orientations_deg);
    for az = azList(:)'
        cfg=peew_config(root,r,az);
        Tin=cfg.case.heatingTin_C;
        assert(isfile(cfg.path.weatherFile),'Missing weather MAT: %s',cfg.path.weatherFile);
        W=m20_boundary_loadWeather(cfg);
        water=m50_hyd_loadWaterTable(cfg);
        W=m20_boundary_extractSeasonWeather(W,'heating',cfg);
        W.Tin_C=Tin*ones(numel(W.time),1);
        W.COP_ref=m60_energy_calcReferenceCOP(W.Tout_C,Tin,'heating',cfg);
        W.TeqOut_ref_C=m20_boundary_calcReferenceOutdoorEquivalentTemperature(W,cfg);
        % Each (city, orientation) has a shared no-pipe CW baseline.
        ref=peew_make_case('C_referenceNoPipe',city,Tin,NaN,insMm,NaN,cfg.sim.timeStep_s/3600);
        wall=m10_case_buildWallModel(ref,cfg);
        flow=m40_flow_makeNoPipeFlowProfile(numel(W.time));
        sim=m30_wall_solveWallTransientGivenFlowProfile(ref,wall,W,water,cfg,flow,'Reference');
        cw=peew_metrics(sim,[]); clear sim;
        cwRows(end+1,:) = {city,az,cw.Qin_kWh,cw.EHP_signed_kWh,cw.Epump_kWh,cw.Eeq_kWh}; %#ok<AGROW>

        % Construct every independent supply-temperature/pipe-location task.
        [jobs, Tsups] = peew_build_jobs(cfg,mode);
        jobResults=cell(numel(jobs),1);
        fprintf('Starting %s az=%d: %d pipe cases (reference CW completed).\n', ...
                city,az,numel(jobs));
        if useParallel
            % Each worker owns its own solver variables; no concurrent writes.
            parfor j = 1:numel(jobs)
                jobResults{j} = peew_run_one_case(jobs(j),city,az,Tin,insMm,cfg,W,water,cw);
            end
        else
            for j = 1:numel(jobs)
                jobResults{j} = peew_run_one_case(jobs(j),city,az,Tin,insMm,cfg,W,water,cw);
            end
        end

        % IEU is calculated ONLY after all physical results are collected.
        % Loop order and row ordering are identical in serial and parallel.
        for iT = 1:numel(Tsups)
            ids=find([jobs.Tsup]==Tsups(iT));
            locDin=[jobs(ids).delta]';
            local=vertcat(jobResults{ids});
            etaE=cell2mat(local(:,14));
            dQ=cell2mat(local(:,13));
            qp=cell2mat(local(:,8));
            z=peew_ieu(etaE,dQ,qp,0.5,0.95);
            labels=strings(numel(locDin),1);
            for ii=1:numel(locDin)
                if isnan(locDin(ii)), labels(ii)="Middle";
                else, labels(ii)=string(locDin(ii)); end
            end
            for k=1:numel(locDin)
                outRows(end+1,:)=[local(k,:),{z.feasible(k),z.IEU(k),z.recommended(k)}]; %#ok<AGROW>
            end
            selected=labels(z.recommended);
            if isempty(selected)
                best='none'; range='none'; points='none';
            else
                best=char(labels(z.bestIndex));
                points=char(strjoin(selected,'|'));
                selectedDin=locDin(z.recommended & ~isnan(locDin));
                if any(z.recommended & isnan(locDin))
                    if isempty(selectedDin), range='Middle';
                    else, range=sprintf('Middle to %g',max(selectedDin)); end
                elseif numel(selectedDin)==1, range=sprintf('%g',selectedDin);
                else, range=sprintf('%g-%g',min(selectedDin),max(selectedDin)); end
            end
            recRows(end+1,:)={city,az,Tsups(iT),best,range,points,strcmpi(mode,'smoke')}; %#ok<AGROW>
            fprintf('%s az=%d Tsup=%g : %s\n',city,az,Tsups(iT),range);
        end
    end
end
allCasesInternal=cell2table(outRows,'VariableNames',{'city','azimuth_deg','Tin_C','Tsup_C','location_type','delta_in_mm','Qin_kWh','QpPlus_kWh','QpMinus_kWh','EHP_signed_kWh','Epump_kWh','Eeq_kWh','DeltaQin_kWh','etaE_internal','etaEff_internal','feasible','IEU','recommended'});
% Retain both efficiency indices only for in-memory IEU/audit calculations.
% Their fractional values are not directly exported to the case CSV or results object.
allCases=removevars(allCasesInternal,{'etaE_internal','etaEff_internal'});
rec=cell2table(recRows,'VariableNames',{'city','azimuth_deg','Tsup_C','maxIEU_location','near_optimal_range','selected_locations','smoke_only'});
cwTable=cell2table(cwRows,'VariableNames',{'city','azimuth_deg','Qin_kWh','EHP_signed_kWh','Epump_kWh','Eeq_kWh'});
out=fullfile(root,'results'); if ~exist(out,'dir'),mkdir(out);end
writetable(allCases,fullfile(out,'all_cases.csv'));
writetable(rec,fullfile(out,'recommended_locations.csv'));
writetable(cwTable,fullfile(out,'reference_CW.csv'));
results=struct('cases',allCases,'recommendations',rec,'referenceCW',cwTable);
% Keep a dated copy. Subsequent runs will still update results/*.csv, but
% previously completed run outputs remain available for comparisons.
runTag=sprintf('%s_%s_%s',lower(selection),lower(mode), ...
    char(datetime('now','Format','yyyyMMdd_HHmmss_SSS')));
archiveDir=fullfile(out,'run_archive',runTag);
mkdir(archiveDir);
copyfile(fullfile(out,'all_cases.csv'),fullfile(archiveDir,'all_cases.csv'));
copyfile(fullfile(out,'recommended_locations.csv'),fullfile(archiveDir,'recommended_locations.csv'));
copyfile(fullfile(out,'reference_CW.csv'),fullfile(archiveDir,'reference_CW.csv'));
fprintf('Run outputs archived at: %s\n',archiveDir);
results.archiveDir=archiveDir;
end
