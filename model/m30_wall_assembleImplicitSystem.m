% ========================================================================
% m30_wall_assembleImplicitSystem.m
% ========================================================================
function [A, b, pipeInfo] = m30_wall_assembleImplicitSystem(Told, wall, Tin_C, hIn, TeqOut_C, hOut, mDot, Tsupply_C, waterTable, cfg, dt)
% Assemble the implicit nodal energy-balance system.
N = wall.nNode;
Cdt = wall.C_J_m2K / dt;
A = sparse(N,N);
b = zeros(N,1);

G_in = 1 / (1/hIn + wall.dx_m(1)/(2*wall.k_W_mK(1)));
G_out = 1 / (1/hOut + wall.dx_m(end)/(2*wall.k_W_mK(end)));

G = zeros(N-1,1);
for i = 1:N-1
    R = wall.dx_m(i)/(2*wall.k_W_mK(i)) + wall.dx_m(i+1)/(2*wall.k_W_mK(i+1));
    G(i) = 1 / R;
end

pipeInfo = m30_wall_pipeCouplingInfo(wall, cfg, waterTable, Tsupply_C, mDot);

for i = 1:N
    diagVal = Cdt(i);
    rhs = Cdt(i) * Told(i);
    if i == 1
        diagVal = diagVal + G_in;
        rhs = rhs + G_in * Tin_C;
    else
        diagVal = diagVal + G(i-1);
        A(i,i-1) = A(i,i-1) - G(i-1);
    end
    if i == N
        diagVal = diagVal + G_out;
        rhs = rhs + G_out * TeqOut_C;
    else
        diagVal = diagVal + G(i);
        A(i,i+1) = A(i,i+1) - G(i);
    end
    if wall.hasPipe && i == wall.pipeNodeIndex && mDot > 0
        diagVal = diagVal + pipeInfo.H_area_W_m2K;
        rhs = rhs + pipeInfo.H_area_W_m2K * Tsupply_C;
    end
    A(i,i) = A(i,i) + diagVal;
    b(i) = rhs;
end

if wall.hasPipe && mDot > 0
    TnodeOldApprox = Told(wall.pipeNodeIndex);
    pipeInfo.qPipe_W_m2 = pipeInfo.H_area_W_m2K * (Tsupply_C - TnodeOldApprox);
end
end
