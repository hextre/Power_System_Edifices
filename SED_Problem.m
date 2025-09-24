% Stochastic Economic Dispatch in MATLAB
clc; clear;

%% Problem Parameters
ng = 3; % number of generators
ns = 100; % number of scenarios

% Generator cost coefficients: C(P) = a*P^2 + b*P + c
a = [0.01, 0.02, 0.015];
b = [20, 25, 18];
c = [100, 120, 150];

% Generation limits
Pmin = [50, 30, 20];
Pmax = [200, 150, 100];

% Nominal Load
Pload_nom = 300;

% Demand uncertainty (normally distributed variation)
mu = 0;          % mean deviation
sigma = 20;      % standard deviation

% Preallocate
Pgen = zeros(ng, ns);
Cost = zeros(1, ns);

%% Solve SED for each scenario
options = optimoptions('fmincon','Display','none');

for s = 1:ns
    % Sample demand for this scenario
    dP = sigma * randn();  % deviation
    Pload = Pload_nom + dP;
    
    % Objective function: total cost
    costFcn = @(P) sum(a(:).*P(:).^2 + b(:).*P(:) + c(:));
    
    % Equality constraint: power balance
    Aeq = ones(1, ng);
    beq = Pload;
    
    % Bounds
    lb = Pmin;
    ub = Pmax;
    
    % Initial guess
    P0 = (Pload/ng)*ones(ng, 1);
    
    % Solve using fmincon
    [Popt, fval] = fmincon(costFcn, P0, [], [], Aeq, beq, lb, ub, [], options);

    % Store results
    Pgen(:, s) = Popt;
    Cost(s) = fval;
end

%% Compute Expected Cost and Average Generation
ExpectedCost = mean(Cost);
AverageGen = mean(Pgen, 2);

%% Display Results
disp('--- Stochastic Economic Dispatch Results ---');
fprintf('Expected Total Cost: %.2f\n', ExpectedCost);
for i = 1:ng
    fprintf('Average Generation of G%d: %.2f MW\n', i, AverageGen(i));
end