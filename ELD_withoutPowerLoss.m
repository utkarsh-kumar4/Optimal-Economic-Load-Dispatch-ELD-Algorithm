% -------------------- An iterative function for the Economic Load Dispatch (assuming "ZERO POWER LOSS") with generator limits --------------------

function [P_optimal, lambda_value, feasibility, total_cost] = ELD_withoutPowerLosses(a, b, c, P_minimum, P_maximum, P_demand)
    % Inputs :-
    % a, b, c       : vectors of quadratic cost coefficients for the generators [Ci(Pi) = (ai*Pi) * x^2 + (bi*Pi) * x + c]
    % P_minimum     : vector of minimum power limits
    % P_maximum     : vector of maximum power limits
    % P_demand      : total load demand

    % Outputs :-
    % P_optimal     : vector of optimal power allocation
    % lambda_value  : lagrangian multiplier obtained
    % feasibility   : boolean (true if feasible, false if demand can't be met)
    % total_cost    : total cost of operation



    % Initialization of variables
    generators = length(a);                  % given number of generators
    free_generators = true(generators, 1);   % generators whose power can be adjusted during the iteration
    P_optimal = zeros(generators, 1);        % generators who have achieved their optimal operating power
    iteration_limit = 10;                    % maximum number of iterations to avoid infinite loop
    iteration_index = 0;
    feasibility = true;



    % ---------------------------------------- Iteration begins to search for the most optimal solution ----------------------------------------
    while (iteration_index < iteration_limit)
        iteration_index = iteration_index + 1;

        % Calculate total fixed power from generators at their limits
        P_fixed = sum(P_optimal(~free_generators));
        % Remaining power to allocate among free generators
        P_demand_remaining = P_demand - P_fixed;

        % Check for feasibility
        if (P_demand_remaining < 0)
            % Load is already oversupplied by fixed generators -> INFEASIBLE
            feasibility = false;

            % Call warning function
            warning('Infeasible: Demand cannot be met.');
            % Call warning function

            break;
        end

        % Extracting the respective a, b, P_minimum and P_maximum for the free_generators [since we'll be using only these to solve]
        a_free = a(free_generators);
        b_free = b(free_generators);
        P_minimum_free = P_minimum(free_generators);
        P_maximum_free = P_maximum(free_generators);

        % Solving for lambda for the free_generators
        numerator = P_demand_remaining + sum(b_free ./ (2 * a_free));
        denominator = sum(1 ./ (2 * a_free));
        lambda = numerator / denominator;

        % Calculating the power outputs for free_generators
        P_free = (lambda - b_free) ./ (2 * a_free);

        % Check for limit violations (if any)
        violated_minimum = P_free < P_minimum_free;
        violated_maximum = P_free > P_maximum_free;
        if ((~any(violated_minimum)) && (~any(violated_maximum)))
            % If no violations occur, assign to P_optimal and exit the loop
            P_optimal(free_generators) = P_free;
            lambda_value = lambda;
            break;
        end

        % If any violation occurs, update P_optimal of the free_generators to their respective P_minimum or P_maximum limits
        if (any(violated_minimum))
            index_P_minimum_violation = find(free_generators);                              % Indices of the free_generators = 1
            index_P_minimum_violation = index_P_minimum_violation(violated_minimum);        % Indices where violated_minimum = 1
            P_optimal(index_P_minimum_violation) = P_minimum(index_P_minimum_violation);    % Update P_optimal at those indices to their respective P_minimum
            free_generators(index_P_minimum_violation) = false;                             % Now, the respective free_generators are fixed
        end

        if (any(violated_maximum))
            index_P_maximum_violation = find(free_generators);                              % Indices of the free_generators = 1
            index_P_maximum_violation = index_P_maximum_violation(violated_maximum);        % Indices where violated_maximum = 1
            P_optimal(index_P_maximum_violation) = P_maximum(index_P_maximum_violation);    % Update P_optimal at those indices to their respective P_maximum
            free_generators(index_P_maximum_violation) = false;                             % Now, the respective free_generators are fixed
        end
    end
    % ------------------------------------------------------------ Iteration ends ------------------------------------------------------------


    % Iteration ends, but no optimal solution is obtained
    if (iteration_index == iteration_limit)
        warning('Maximum iterations reached, solution may not be optimal.');
    end

    % Calculating the total cost of operation
    total_cost = sum(a .* P_optimal.^2 + b .* P_optimal + c);
end

% Testing the function with sample data
a = [0.02; 0.015; 0.025; 0.01];        % Quadratic cost coefficients
b = [20; 25; 18; 30];                  % Linear cost coefficients
c = [100; 120; 80; 150];                  % Constant cost coefficients
P_minimum = [50; 50; 40; 60];       % Minimum power limits
P_maximum = [200; 250; 300; 150];      % Maximum power limits
P_demand = 1000;                 % Power demand

% Calling the function
[P_optimal, lambda_value, feasibility, total_cost] = ELD_withoutPowerLosses(a, b, c, P_minimum, P_maximum, P_demand);

% Displaying the results
fprintf('Power distribution for the given %s generating stations:\n', string(length(a)));
for P_optimal_index = 1:length(P_optimal)
    fprintf('Generating Station %d: %.2f MW\n', P_optimal_index, P_optimal(P_optimal_index));
end
fprintf('Feasibility status: %s\n', string(feasibility));
fprintf('Total cost of operation: %.2f Rs./hr\n', total_cost);
