clc; clear;

%% Generator Parameters
ng = 3; % number of generators

a = [0.01, 0.02, 0.015];
b = [20, 25, 18];
c = [100, 120, 150];

alpha = [0.001, 0.002, 0.0015];
beta  = [0.1, 0.12, 0.08];
gamma = [1, 1.2, 1.1];

Pmin = [50, 30, 20];
Pmax = [200, 150, 100];

Pload = 300;

weights = linspace(0, 1, 20);  % Varying weights for cost vs emission

FuelCosts = zeros(size(weights));
Emissions = zeros(size(weights));

options = optimoptions('fmincon','Display','none');

for k = 1:length(weights)
    w = weights(k);  % Weight for cost

    % Weighted objective function
    costFcn = @(P) w * sum(a(:).*P(:).^2 + b(:).*P(:) + c(:)) + ...
                  (1 - w) * sum(alpha(:).*P(:).^2 + beta(:).*P(:) + gamma(:));

    % Equality constraint: power balance
    Aeq = ones(1, ng);
    beq = Pload;

    lb = Pmin;
    ub = Pmax;
    P0 = (Pload/ng) * ones(ng, 1);  % Initial guess

    [Popt, ~] = fmincon(costFcn, P0, [], [], Aeq, beq, lb, ub, [], options);

    % Compute separate fuel cost and emission
    FuelCosts(k) = sum(a(:).*Popt.^2 + b(:).*Popt + c(:));
    Emissions(k) = sum(alpha(:).*Popt.^2 + beta(:).*Popt + gamma(:));
end

%% Plot Pareto Frontier
figure;
plot(Emissions, FuelCosts, 'b-o','LineWidth',2);
xlabel('Total Emission');
ylabel('Total Fuel Cost');
title('Pareto Frontier: Emission vs Fuel Cost');
grid on;