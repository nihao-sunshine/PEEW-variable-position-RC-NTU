% ========================================================================
% m60_energy_pipeEffectiveIneffective.m
% ========================================================================
function [Qeff, Qineff] = m60_energy_pipeEffectiveIneffective(Qpipe, season, epsW)
% Partition pipe heat transfer according to the heating-season sign convention.
if abs(Qpipe) < epsW
    Qeff = 0; Qineff = 0; return;
end
if strcmp(season, 'heating')
    if Qpipe > 0
        Qeff = Qpipe; Qineff = 0;
    else
        Qeff = 0; Qineff = Qpipe;
    end
else
    if Qpipe < 0
        Qeff = Qpipe; Qineff = 0;
    else
        Qeff = 0; Qineff = Qpipe;
    end
end
end

% ======================================================================= %
