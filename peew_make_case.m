function c = peew_make_case(kind, city, Tin, Tsup, insulation, din, dt_h)
% Only three physical wall configurations used in the paper.
c = struct();
c.wallType=kind;
c.wallTypeCN=kind;
c.hasPipe=~strcmp(kind,'C_referenceNoPipe');
c.season='heating'; c.Tin_C=Tin; c.supplyWater_C=Tsup;
c.innerInsulation_mm=NaN; c.outerInsulation_mm=NaN;
c.referenceInsulation_mm=NaN; c.dtHoursForExport=dt_h;
if strcmp(kind,'A_positionOptimizedPEEW')
    c.innerInsulation_mm=din; c.outerInsulation_mm=insulation-din;
elseif strcmp(kind,'B_conventionalPEEW')
    c.outerInsulation_mm=insulation;
elseif strcmp(kind,'C_referenceNoPipe')
    c.referenceInsulation_mm=insulation; c.outerInsulation_mm=insulation;
    c.supplyWater_C=NaN;
else
    error('Unknown wall type: %s',kind);
end
c.caseName=sprintf('%s_%s_Tin%g_Tsup%g_din%g',city,kind,Tin,Tsup,din);
end
