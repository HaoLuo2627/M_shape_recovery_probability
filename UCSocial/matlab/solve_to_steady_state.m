function [elapsed_time, steady_state] = solve_to_steady_state(odefun, initial_state)
%SOLVE_TO_STEADY_STATE 分段积分，直到无穷范数意义下导数充分小。

chunk_time = 100;
max_time = 5000;
steady_tolerance = 1e-7;
options = odeset('RelTol', 1e-7, 'AbsTol', 1e-9);

state = initial_state(:);
elapsed_time = 0;

while elapsed_time < max_time
    next_time = min(elapsed_time + chunk_time, max_time);
    try
        [~, solution] = ode45(odefun, [elapsed_time, next_time], state, options);
        if any(~isfinite(solution(:)))
            warning('steady_state:ode45NonFinite', ...
                'ode45 在区间 [%g, %g] 产生 NaN 或 Inf，改用 ode23。', ...
                elapsed_time, next_time);
            [~, solution] = ode23(odefun, [elapsed_time, next_time], state, options);
        end
        if any(~isfinite(solution(:)))
            warning('steady_state:ode23NonFinite', ...
                'ode23 在区间 [%g, %g] 产生 NaN 或 Inf，改用 ode113。', ...
                elapsed_time, next_time);
            [~, solution] = ode113(odefun, [elapsed_time, next_time], state, options);
        end
    catch ode45_error
        warning('steady_state:ode45Failed', ...
            'ode45 和 ode23 均失败，改用 ode113: %s', ode45_error.message);
        [~, solution] = ode113(odefun, [elapsed_time, next_time], state, options);
    end

    state = solution(end, :)';
    elapsed_time = next_time;
    if any(~isfinite(state))
        warning('ODE 在 t=%g 产生 NaN 或 Inf。', elapsed_time);
    end

    derivative = odefun(elapsed_time, state);
    if norm(derivative, inf) <= steady_tolerance
        steady_state = state';
        return;
    end
end

steady_state = state';
warning('ODE 在最大时间 t=%g 前未收敛；最终 ||dy/dt||_inf=%g。', ...
    max_time, norm(odefun(elapsed_time, state), inf));
end
