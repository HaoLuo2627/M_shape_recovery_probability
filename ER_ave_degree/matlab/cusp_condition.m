function prob = cusp_condition(x, alpha0, beta0)
% Cusp条件函数
%
% 函数形式:
%   prob = 1 - x / alpha0,                                if 0 <= x <= alpha0
%   prob = 0,                                            if alpha0 < x <= beta0
%   prob = (x - beta0) / (1 - beta0),                       if beta0 < x <= 1
%   最后裁剪到 [0, 1]
%
% @param x       输入值，通常为 info_count / degree (局部感染比例)
% @param alpha0  第一个区间分界点，必须 大于0 小于1
% @param beta0   第二个区间分界点，必须 大于0 小于1
% @return        裁剪到 [0, 1] 的概率值
eps = 1e-16;  % 防止除以零的极小值

if (alpha0 <= 0) || (alpha0 >= 1)
    error('alpha0 必须在(0, 1)之间, alpha0 = %g 非法', alpha0);
end
if (beta0 <= 0) || (beta0 >= 1)
    error('beta0 必须在(0, 1)之间, beta0 = %g 非法', beta0);
end
if alpha0 >= beta0
    error('alpha0 必须小于 beta0, alpha0 = %g, beta0 = %g 非法', alpha0, beta0);
end

% 第一个区间：[0, alpha0]
mask1 = (0 <= x) & (x <= alpha0);
% 第二个区间：(alpha0, beta0]
mask2 = (alpha0 < x) & (x <= beta0);
% 第三个区间：(beta0, 1]
mask3 = (beta0 < x) & (x <= 1);

prob = zeros(size(x));
prob(mask1) = 1 - x(mask1) ./ alpha0;
prob(mask2) = 0;
prob(mask3) = (x(mask3) - beta0) ./ (1 - beta0 + eps);

% 裁剪到 [0, 1]
prob(prob < 0) = 0;
prob(prob > 1) = 1;
end
