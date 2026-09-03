function prob = recovery_probability(x, a0, c0)
% 恢复概率函数
%
% 函数形式:
%   prob = 2 * (1 - c0) * x / a0 + c0,                           if 0 <= x < a0 / 2
%   prob = -2 * (1 - c0) * x / a0 + 2 - c0,                      if a0 / 2 <= x < a0
%   prob = (2 * (1 - c0) * x + c0 - a0 * (2 - c0)) / (1 - a0),   if a0 <= x < (1 + a0) / 2
%   prob = (-2 * (1 - c0) * x + 2 - a0 * c0 - c0) / (1 - a0),    if (1 + a0) / 2 <= x <= 1
%   最后裁剪到 [0, 1]
%
% @param x       输入值，通常为 info_count / degree (局部感染比例)
% @param a0      参数，必须 大于0 小于1
% @param c0      M形的最小值点，必须 大于0 小于等于1
% @return        裁剪到 [0, 1] 的概率值

if (a0 <= 0) || (a0 >= 1)
    error('a0 必须在(0, 1)之间, a0 = %g 非法', a0);
end
if (c0 <= 0) || (c0 > 1)
    error('c0 必须在(0, 1]之间, c0 = %g 非法', c0);
end

% 第一个区间：[0, a0 / 2)
mask1 = (0 <= x) & (x < a0 / 2);
% 第二个区间：[a0 / 2, a0)
mask2 = (a0 / 2 <= x) & (x < a0);
% 第三个区间：[a0, (1 + a0) / 2)
mask3 = (a0 <= x) & (x < (1 + a0) / 2);
% 第四个区间：[(1 + a0) / 2, 1]
mask4 = ((1 + a0) / 2 <= x) & (x <= 1);

prob = zeros(size(x));
prob(mask1) = 2 * (1 - c0) * x(mask1) / a0 + c0;
prob(mask2) = -2 * (1 - c0) * x(mask2) / a0 + 2 - c0;
prob(mask3) = (2 * (1 - c0) * x(mask3) + c0 - a0 * (2 - c0)) / (1 - a0);
prob(mask4) = (-2 * (1 - c0) * x(mask4) + 2 - a0 * c0 - c0) / (1 - a0);

% 裁剪到 [0, 1]
prob(prob < 0) = 0;
prob(prob > 1) = 1;

if(abs(prob) < 1e-6)
    error("Recovery probability must be in (0, 1], but got prob = 0. This may indicate that the input x is out of the expected range or that the parameters a0 and c0 are not set correctly.");
end
end
