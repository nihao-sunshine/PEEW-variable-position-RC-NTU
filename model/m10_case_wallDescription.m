% ========================================================================
% m10_case_wallDescription.m
% ========================================================================
function desc = m10_case_wallDescription(caseSpec)
% Build a readable description of each wall configuration.
switch caseSpec.wallType
    case 'A_positionOptimizedPEEW'
        desc = sprintf('20mm inner plaster + 240mm brick + %gmm insulation + 40mm concrete with pipe + %gmm insulation + 20mm outer plaster', caseSpec.innerInsulation_mm, caseSpec.outerInsulation_mm);
    case 'B_conventionalPEEW'
        desc = sprintf('20mm inner plaster + 120mm brick + 40mm concrete with pipe + 120mm brick + %gmm insulation + 20mm outer plaster', caseSpec.outerInsulation_mm);
    case 'C_referenceNoPipe'
        desc = sprintf('20mm inner plaster + 240mm brick + 40mm concrete without pipe + %gmm insulation + 20mm outer plaster', caseSpec.referenceInsulation_mm);
    otherwise
        desc = '';
end
end
