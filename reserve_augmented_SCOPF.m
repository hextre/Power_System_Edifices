
% Reserve-Augmented DC SCOPF (Simplified)
clc; clear;

%% System Parameters
n = 3;  % number of generators (G1, G2, G3)
demand = 400;  % total system demand (MW)

Pmax = [200; 150; 200];   % Max generation limits
Pmin = [50;  40;  30];    % Min generation limits

cost_gen = [20; 25; 30];         % Generation cost ($/MWh)
cost_spin = [3; 2.5; 4];         % Spinning reserve cost
cost_nspin = [1.5; 1; 2];        % Non-spinning reserve cost

R_sys_spin = 80;      % Total spinning reserve requirement (MW)
R_sys_nspin = 40;     % Total non-spinning reserve requirement (MW)

%% Optimization using quadprog (linear objective here)
H = zeros(3*3);  % 3 variables per generator: P, Rspin, Rnspin
f = [cost_gen; cost_spin; cost_nspin];

% Variables: [P1; P2; P3; Rspin1; Rspin2; Rspin3; Rnspin1; Rnspin2; Rnspin3]

% Equality constraint: Power balance
Aeq = [ones(1, n), zeros(1, 2*n)];
beq = demand;

% Inequality constraints:
% - Generator bounds: Pmin <= P <= Pmax
% - P + Rspin <= Pmax (spinning reserve feasibility)
% - Rnspin <= Pmax (non-spin reserve limit)
A = [
    eye(n), zeros(n, 2*n);              % P <= Pmax
    -eye(n), zeros(n, 2*n);             % -P <= -Pmin
    eye(n), eye(n), zeros(n);           % P + Rspin <= Pmax
    zeros(n), zeros(n), eye(n);         % Rnspin <= Pmax
   -zeros(1,n), -ones(1,n), -ones(1,n); % -sum(Rspin+Rnspin) <= -Rtot
];
b = [
    Pmax;
   -Pmin;
    Pmax;
    Pmax;
   - (R_sys_spin + R_sys_nspin);
];

% Add reserve requirement as inequality:
A_res = [
    zeros(1,n), ones(1,n), zeros(1,n);   % sum(Rspin) >= R_sys_spin
    zeros(1,n), zeros(1,n), ones(1,n)    % sum(Rnspin) >= R_sys_nspin
];
b_res = [
    R_sys_spin;
    R_sys_nspin
];

% Flip signs to convert >= to <=
A = [A; -A_res];
b = [b; -b_res];

%% Run Optimization
options = optimoptions('linprog','Display','iter');
[x,fval,exitflag] = linprog(f, A, b, Aeq, beq, zeros(3*n,1), [], options);

%% Results
P = x(1:n);
Rspin = x(n+1:2*n);
Rnspin = x(2*n+1:end);

disp('--- Optimal Dispatch and Reserve Allocation ---');
disp(table((1:n)', P, Rspin, Rnspin, ...
    'VariableNames', {'Gen','P_MW','R_spin','R_nspin'}));
fprintf('Total Cost: $%.2f\n', fval);
