function m = peew_metrics(sim, cw)
% Postprocess the unchanged RC--NTU solver. Physical units: kWh.
% Solver Q_innerToIndoor > 0 means wall-to-room heat. Paper Qin>0 means loss.
m.Qin_kWh = -sim.summary.Q_innerToIndoor_signed_kWh;
m.EHP_signed_kWh = sim.summary.E_wallHVAC_signed_kWh;
if sim.caseSpec.hasPipe
    isOfficial = logical(sim.hourly.isOfficial(:));
    dt_h = sim.caseSpec.dtHoursForExport;
    m.QpPlus_kWh = sum(max(sim.hourly.Q_pipeToWall_W(isOfficial),0)) * dt_h / 1000;
    m.QpMinus_kWh = sum(min(sim.hourly.Q_pipeToWall_W(isOfficial),0)) * dt_h / 1000;
    % Keep the originally implemented source-Source system-pump accounting.
    m.Epump_kWh = sim.summary.E_systemPumpWithSource_kWh;
    m.Eeq_kWh = m.EHP_signed_kWh + m.Epump_kWh;
else
    m.QpPlus_kWh = 0; m.QpMinus_kWh = 0;
    m.Epump_kWh = 0;
    m.Eeq_kWh = m.EHP_signed_kWh;
end
m.DeltaQin_kWh = NaN; m.etaE = NaN; m.etaEff = NaN;
if nargin >= 2 && ~isempty(cw)
    m.DeltaQin_kWh = cw.Qin_kWh - m.Qin_kWh;
    if isfinite(cw.Eeq_kWh) && cw.Eeq_kWh > 0
        m.etaE = (cw.Eeq_kWh - m.Eeq_kWh) / cw.Eeq_kWh;
    end
    if isfinite(m.QpPlus_kWh) && m.QpPlus_kWh > 0
        m.etaEff = m.DeltaQin_kWh / m.QpPlus_kWh;
    end
end
end
