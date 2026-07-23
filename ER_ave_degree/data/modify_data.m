function [new_mean_value, square_variance, X_A] = modify_data(original_data, total_count, coefficient)
%MODIFY_DATA 删除小规模传播样本后计算均值、总体标准差和相对方差。

if size(original_data, 1) ~= total_count
    error('total_count=%d 与数据行数=%d 不一致', total_count, size(original_data, 1));
end

original_mean_value = sum(original_data, 1) / total_count;
mean_matrix = repmat(original_mean_value, total_count, 1);
original_data(original_data < mean_matrix * coefficient) = 0;

logical_pattern = original_data ~= 0;
sample_count = sum(logical_pattern, 1);

new_mean_value = sum(original_data, 1) ./ sample_count;

mean_matrix_averaged = repmat(new_mean_value, total_count, 1);
variance_matrix = (original_data - mean_matrix_averaged).^2;
variance_matrix(~logical_pattern) = 0;

variance_value = sum(variance_matrix, 1) ./ sample_count;
square_variance = sqrt(variance_value);

mean_A_square = new_mean_value.^2;
X_A = variance_value ./ mean_A_square;
end
